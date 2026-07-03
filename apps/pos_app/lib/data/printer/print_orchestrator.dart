import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../config/env.dart';
import '../../core/providers.dart';
import '../api/dto.dart';
import 'print_helpers.dart';
import 'printer_providers.dart';

/// Orchestrates multi-document printing after KDS accept or checkout.
class PrintOrchestrator {
  PrintOrchestrator(this._ref);
  final Ref _ref;

  Future<void> onGuestOrderAccepted(GuestOrderDto order) async {
    final db = _ref.read(databaseProvider);
    final labelIds = await labelProductIdsFromDb(db);
    final kitchen = _ref.read(kitchenPrinterServiceProvider);
    final receipt = _ref.read(printerServiceProvider);
    final labels = _ref.read(labelPrinterServiceProvider);

    await kitchen.printTicket(kitchenTicketFromGuestOrder(order));
    try {
      await receipt.printConfirmation(confirmationFromGuestOrder(order));
    } catch (_) {/* non-fatal */}
    final drinkLabels = drinkLabelsFromGuestOrder(order, labelIds);
    if (drinkLabels.isNotEmpty) {
      try {
        await labels.printLabels(drinkLabels);
      } catch (_) {/* non-fatal */}
    }
  }

  Future<void> printGuestConfirmation(GuestOrderDto order) async {
    await _ref.read(printerServiceProvider).printConfirmation(confirmationFromGuestOrder(order));
  }

  Future<void> reprintGuestLabels(GuestOrderDto order) async {
    final labelIds = await labelProductIdsFromDb(_ref.read(databaseProvider));
    final drinkLabels = drinkLabelsFromGuestOrder(order, labelIds);
    if (drinkLabels.isEmpty) {
      throw StateError('此訂單無需列印標籤的品項');
    }
    await _ref.read(labelPrinterServiceProvider).printLabels(drinkLabels);
  }

  Future<void> reprintCartLabels(Cart cart, {String? tableLabel}) async {
    final labelIds = await labelProductIdsFromDb(_ref.read(databaseProvider));
    final drinkLabels = drinkLabelsFromCart(cart, labelProductIds: labelIds, tableLabel: tableLabel);
    if (drinkLabels.isEmpty) {
      throw StateError('購物車無需列印標籤的品項');
    }
    await _ref.read(labelPrinterServiceProvider).printLabels(drinkLabels);
  }

  Future<void> printCartConfirmation(Cart cart, {String? tableLabel}) async {
    await _ref.read(printerServiceProvider).printConfirmation(
          confirmationFromCart(cart, tableLabel: tableLabel),
        );
  }

  Invoice? _invoiceFromJson(Map<String, dynamic>? json) {
    if (json == null || json['status'] != 'issued') return null;
    return Invoice(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: InvoiceStatus.issued,
      totalAmount: Money((json['total_cents'] as num).toInt()),
      tax: Money((json['tax_cents'] as num).toInt()),
      taxType: (json['tax_type'] as num?)?.toInt() ?? 1,
      invoiceNumber: json['invoice_number'] as String?,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : null,
      taxId: json['tax_id'] as String?,
      randomCode: json['random_code'] as String?,
      barcode: json['barcode'] as String?,
      qrLeft: json['qr_left'] as String?,
      qrRight: json['qr_right'] as String?,
    );
  }

  Future<void> onCheckout({
    required Order order,
    required Cart cart,
    Map<String, dynamic>? invoiceJson,
    String? tableLabel,
    InvoiceCarrier? carrier,
    String? donationCode,
  }) async {
    final receipt = _ref.read(printerServiceProvider);
    final kitchen = _ref.read(kitchenPrinterServiceProvider);
    final labels = _ref.read(labelPrinterServiceProvider);
    final labelIds = await labelProductIdsFromDb(_ref.read(databaseProvider));

    final invoice = _invoiceFromJson(invoiceJson);
    try {
      await receipt.printReceipt(order, invoice: invoice, tableLabel: tableLabel);
    } catch (_) {/* non-fatal */}

    final needsProof = invoice != null &&
        invoice.invoiceNumber != null &&
        carrier == null &&
        (donationCode == null || donationCode.isEmpty);
    if (needsProof) {
      try {
        await receipt.printInvoiceProof(
          storeName: '點餐趣',
          invoiceNumber: invoice.invoiceNumber!,
          invoiceDate: invoice.invoiceDate ?? DateTime.now(),
          randomCode: invoice.randomCode ?? '0000',
          total: invoice.totalAmount,
          buyerTaxId: invoice.taxId,
          barcode: invoice.barcode,
          qrLeft: invoice.qrLeft,
          qrRight: invoice.qrRight,
        );
      } catch (_) {/* non-fatal */}
    }

    try {
      await kitchen.printTicket(kitchenTicketFromCart(cart, tableLabel: tableLabel));
    } catch (_) {/* non-fatal */}

    final drinkLabels = drinkLabelsFromCart(cart, labelProductIds: labelIds, tableLabel: tableLabel);
    if (drinkLabels.isNotEmpty) {
      try {
        await labels.printLabels(drinkLabels);
      } catch (_) {/* non-fatal */}
    }
  }

  Future<void> printTableSessionQr({
    required String tableLabel,
    required String orderUrl,
    DateTime? expiresAt,
    String storeName = '點餐趣',
  }) async {
    await _ref.read(printerServiceProvider).printTableQr(
          storeName: storeName,
          tableLabel: tableLabel,
          orderUrl: orderUrl,
          expiresAt: expiresAt,
        );
  }

  String customerOrderUrl(String sessionToken) =>
      '${Env.customerBaseUrl}/order?t=$sessionToken';
}

final printOrchestratorProvider = Provider<PrintOrchestrator>((ref) => PrintOrchestrator(ref));
