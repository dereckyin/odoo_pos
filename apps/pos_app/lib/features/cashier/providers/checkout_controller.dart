import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables.dart';
import '../../../data/sync/sync_models.dart';
import '../../../data/sync/sync_providers.dart';
import '../../../data/sync/sync_queue_dao.dart';
import 'cart_controller.dart';

class CheckoutResult {
  CheckoutResult({required this.order, required this.invoiceId});
  final Order order;
  final String? invoiceId;
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
    final order = Order.fromCart(
      cart: cart,
      storeId: storeId,
      terminalId: terminalId,
      cashierId: session.userId,
      payments: payments,
      now: now,
      invoiceCarrier: carrier?.code,
    );

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
            createdAt: now,
          ));
      for (final l in order.lines) {
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
            ));
        // movement
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
        _orderToPayload(order, now, sourceGuestOrderId: sourceGuestOrderId),
      );

      // Enqueue invoice issue (always; let server reject if duplicate)
      String? invoiceId;
      if (taxType > 0) {
        invoiceId = newUuid();
        await db.into(db.invoices).insert(InvoicesCompanion.insert(
              id: invoiceId,
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
        await dao.enqueue(SyncOpKind.issueInvoice, {
          'order_id': order.id,
          'tax_type': taxType,
          'carrier_type': carrier?.type.name,
          'carrier_code': carrier?.code,
          'tax_id': taxId,
          'company_name': companyName,
          'donation_code': donationCode,
          'gateway': invoiceGateway,
        });
      }
    });

    _ref.read(cartControllerProvider.notifier).clear();
    unawaited(_ref.read(syncWorkerProvider).flush());
    return CheckoutResult(order: order, invoiceId: null);
  }

  Map<String, dynamic> _orderToPayload(
    Order o,
    DateTime clientCreatedAt, {
    String? sourceGuestOrderId,
  }) {
    return {
      'id': o.id,
      'store_id': o.storeId,
      'terminal_id': o.terminalId,
      'cashier_id': o.cashierId,
      'member_id': o.memberId,
      'status': 'paid',
      'subtotal_cents': o.subtotal.cents,
      'discount_cents': o.discount.cents,
      'tax_cents': o.tax.cents,
      'total_cents': o.total.cents,
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
