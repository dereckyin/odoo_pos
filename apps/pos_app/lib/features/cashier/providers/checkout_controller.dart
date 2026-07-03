import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/sync/sync_models.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../data/sync/sync_queue_dao.dart';
import 'cart_controller.dart';

class CheckoutResult {
  CheckoutResult({
    required this.order,
    this.invoiceId,
    this.invoiceJson,
    this.invoiceIssuedOnline = false,
  });
  final Order order;
  final String? invoiceId;
  final Map<String, dynamic>? invoiceJson;
  final bool invoiceIssuedOnline;
}

class CheckoutController {
  CheckoutController(this._ref);
  final Ref _ref;

  Future<CheckoutResult> finalize({
    required List<Payment> payments,
    InvoiceCarrier? carrier,
    String? taxId,
    String? companyName,
    String? donationCode,
    String invoiceGateway = 'ezpay',
    int taxType = 1,
    int pointsRedeemed = 0,
    int pointsDiscountCents = 0,
    int couponDiscountCents = 0,
    String? couponCode,
    String? note,
  }) async {
    final cart = _ref.read(cartControllerProvider);
    final session = _ref.read(authStateProvider).session;
    if (session == null) {
      throw const AuthError('not logged in');
    }
    final storeId = session.storeId;
    final terminalId = session.terminalId;
    if (storeId == null || terminalId == null) {
      throw const ValidationError('缺少門市或終端資訊，請使用收銀登入');
    }
    if (cart.isEmpty) {
      throw const ValidationError('cart is empty');
    }
    final db = _ref.read(databaseProvider);
    final dao = SyncQueueDao(db);
    final now = DateTime.now();
    final sourceGuestOrderId = _ref.read(pendingGuestOrderIdProvider);
    final guestOrder = _ref.read(importedGuestOrderProvider);
    final tableLabel = guestOrder?.displayTitle;
    final primaryPaymentMethod = payments.isNotEmpty ? payments.first.method.code : null;
    final order = Order.fromCart(
      cart: cart,
      storeId: storeId,
      terminalId: terminalId,
      cashierId: session.userId,
      payments: payments,
      now: now,
      invoiceCarrier: carrier?.code,
      note: note ?? cart.note,
    );

    String? invoiceId;
    Map<String, dynamic>? invoiceIssuePayload;

    await db.transaction(() async {
      // Persist order locally first
      await db.into(db.orders).insert(OrdersCompanion.insert(
            id: order.id,
            storeId: order.storeId,
            terminalId: order.terminalId,
            cashierId: order.cashierId,
            memberId: d.Value(order.memberId),
            status: const d.Value('paid'),
            subtotalCents: d.Value(order.subtotal.cents),
            discountCents: d.Value(order.discount.cents),
            taxCents: d.Value(order.tax.cents),
            totalCents: d.Value(order.total.cents),
            invoiceCarrier: d.Value(carrier?.code),
            tableLabel: d.Value(tableLabel),
            sourceGuestOrderId: d.Value(sourceGuestOrderId),
            primaryPaymentMethod: d.Value(primaryPaymentMethod),
            createdAt: now,
          ));
      for (final l in order.lines) {
        final optionsJson = l.selectedOptions.isEmpty
            ? null
            : jsonEncode(l.selectedOptions.map((o) => o.toJson()).toList());
        await db.into(db.orderLines).insert(OrderLinesCompanion.insert(
              id: l.id,
              orderId: order.id,
              productId: l.productId,
              productName: l.productName,
              sku: l.sku,
              qty: l.qty.toDouble(),
              unitPriceCents: l.unitPrice.cents,
              lineDiscountCents: d.Value(l.lineDiscount.cents),
              lineTotalCents: l.lineTotal.cents,
              taxRate: d.Value(l.taxRate),
              note: d.Value(l.note),
              optionsJson: d.Value(optionsJson),
            ));
        final productRow = await (db.select(db.products)..where((t) => t.id.equals(l.productId)))
            .getSingleOrNull();
        final tracksInventory = productRow == null ||
            productRow.productKind == 'consignment_book' ||
            productRow.trackInventory;
        if (tracksInventory) {
          await db.into(db.inventoryMovements).insert(InventoryMovementsCompanion.insert(
                id: newUuid(),
                storeId: order.storeId,
                productId: l.productId,
                qtyDelta: -l.qty.toDouble(),
                reason: 'sale',
                refType: const d.Value('order'),
                refId: d.Value(order.id),
                terminalId: d.Value(order.terminalId),
                userId: d.Value(order.cashierId),
                createdAt: now,
              ));
        }
      }
      for (final p in payments) {
        await db.into(db.payments).insert(PaymentsCompanion.insert(
              id: p.id,
              orderId: order.id,
              method: p.method.code,
              amountCents: p.amount.cents,
              status: d.Value(p.status.name),
              gatewayRef: d.Value(p.gatewayRef),
              gatewayResponseJson: d.Value(p.gatewayResponse == null ? null : jsonEncode(p.gatewayResponse)),
              tenderedCents: d.Value(p.tendered?.cents),
              changeDueCents: d.Value(p.changeDue?.cents),
              createdAt: now,
            ));
      }

      // Enqueue order upload
      await dao.enqueue(
        SyncOpKind.uploadOrder,
        _orderToPayload(
          order,
          now,
          sourceGuestOrderId: sourceGuestOrderId,
          pointsRedeemed: pointsRedeemed,
          couponCode: couponCode,
          extraDiscountCents:
              (pointsDiscountCents > 0 ? pointsDiscountCents : pointsRedeemed) +
                  couponDiscountCents,
        ),
      );

      // Invoice row (issue queued below if online attempt fails)
      if (taxType > 0) {
        invoiceId = newUuid();
        invoiceIssuePayload = {
          'order_id': order.id,
          'tax_type': taxType,
          'carrier_type': carrier?.type.name,
          'carrier_code': carrier?.code,
          'tax_id': taxId,
          'company_name': companyName,
          'donation_code': donationCode,
          'gateway': invoiceGateway,
        };
        await db.into(db.invoices).insert(InvoicesCompanion.insert(
              id: invoiceId!,
              orderId: order.id,
              status: const d.Value('pending'),
              totalCents: order.total.cents,
              taxCents: order.tax.cents,
              taxType: d.Value(taxType),
              carrierType: d.Value(carrier?.type.name),
              carrierCode: d.Value(carrier?.code),
              taxId: d.Value(taxId),
              companyName: d.Value(companyName),
              donationCode: d.Value(donationCode),
              gateway: d.Value(invoiceGateway),
              createdAt: now,
            ));
      }
    });

    Map<String, dynamic>? issuedInvoiceJson;
    var issuedOnline = false;
    if (taxType > 0 && invoiceId != null && invoiceIssuePayload != null) {
      issuedInvoiceJson = await _tryIssueInvoiceOnline(
        orderPayload: _orderToPayload(
          order,
          now,
          sourceGuestOrderId: sourceGuestOrderId,
          pointsRedeemed: pointsRedeemed,
          couponCode: couponCode,
          extraDiscountCents:
              (pointsDiscountCents > 0 ? pointsDiscountCents : pointsRedeemed) +
                  couponDiscountCents,
        ),
        invoiceId: invoiceId!,
        invoicePayload: invoiceIssuePayload!,
      );
      issuedOnline = issuedInvoiceJson != null;
      if (!issuedOnline) {
        await SyncQueueDao(db).enqueue(SyncOpKind.issueInvoice, invoiceIssuePayload!);
      }
    }

    _ref.read(cartControllerProvider.notifier).clear();
    unawaited(_ref.read(syncWorkerProvider).flush());
    unawaited(_ref.read(deltaPullerProvider).pullAll());
    return CheckoutResult(
      order: order,
      invoiceId: invoiceId,
      invoiceJson: issuedInvoiceJson,
      invoiceIssuedOnline: issuedOnline,
    );
  }

  Future<Map<String, dynamic>?> _tryIssueInvoiceOnline({
    required Map<String, dynamic> orderPayload,
    required String invoiceId,
    required Map<String, dynamic> invoicePayload,
  }) async {
    try {
      final api = _ref.read(posApiProvider);
      await api.uploadOrder(orderPayload);
      final res = await api.issueInvoice(invoicePayload);
      if (res['status'] != 'issued') return null;
      final db = _ref.read(databaseProvider);
      await (db.update(db.invoices)..where((t) => t.id.equals(invoiceId))).write(
        InvoicesCompanion(
          status: const d.Value('issued'),
          invoiceNumber: d.Value(res['invoice_number'] as String?),
          invoiceDate: d.Value(
            res['invoice_date'] != null
                ? DateTime.parse(res['invoice_date'] as String)
                : null,
          ),
          randomCode: d.Value(res['random_code'] as String?),
          barcode: d.Value(res['barcode'] as String?),
          qrLeft: d.Value(res['qr_left'] as String?),
          qrRight: d.Value(res['qr_right'] as String?),
        ),
      );
      final orderId = res['order_id'] as String?;
      final number = res['invoice_number'] as String?;
      if (orderId != null && number != null) {
        await (db.update(db.orders)..where((t) => t.id.equals(orderId)))
            .write(OrdersCompanion(invoiceNumber: d.Value(number)));
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _orderToPayload(
    Order o,
    DateTime clientCreatedAt, {
    String? sourceGuestOrderId,
    int pointsRedeemed = 0,
    String? couponCode,
    int extraDiscountCents = 0,
  }) {
    return {
      'id': o.id,
      'store_id': o.storeId,
      'terminal_id': o.terminalId,
      'cashier_id': o.cashierId,
      'member_id': o.memberId,
      'status': 'paid',
      'subtotal_cents': o.subtotal.cents,
      'discount_cents': o.discount.cents + extraDiscountCents,
      'tax_cents': o.tax.cents,
      'total_cents': o.total.cents - extraDiscountCents,
      'points_redeemed': pointsRedeemed,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      'invoice_carrier': o.invoiceCarrier,
      'note': o.note,
      if (sourceGuestOrderId != null) 'source_guest_order_id': sourceGuestOrderId,
      'client_created_at': clientCreatedAt.toUtc().toIso8601String(),
      'lines': o.lines
          .map((l) => {
                'id': l.id,
                'product_id': l.productId,
                'product_name': l.productName,
                'sku': l.sku,
                'qty': l.qty,
                'unit_price_cents': l.unitPrice.cents,
                'line_discount_cents': l.lineDiscount.cents,
                'line_total_cents': l.lineTotal.cents,
                'tax_rate': l.taxRate,
                'note': l.note,
                if (l.selectedOptions.isNotEmpty)
                  'options_json': l.selectedOptions.map((o) => o.toJson()).toList(),
              })
          .toList(),
      'payments': o.payments
          .map((p) => {
                'id': p.id,
                'method': p.method.code,
                'amount_cents': p.amount.cents,
                'status': p.status.name,
                'gateway_ref': p.gatewayRef,
                'gateway_response': p.gatewayResponse,
                'tendered_cents': p.tendered?.cents,
                'change_due_cents': p.changeDue?.cents,
              })
          .toList(),
    };
  }
}

final checkoutControllerProvider = Provider<CheckoutController>((ref) => CheckoutController(ref));
