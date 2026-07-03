import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../api/pos_api.dart';
import 'escpos_service.dart';
import 'printer_providers.dart';
import 'tspl_service.dart';

const _workstationKey = 'pos.print.workstation.enabled';

class PrintWorkstationController extends StateNotifier<bool> {
  PrintWorkstationController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_workstationKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_workstationKey, enabled);
  }
}

final printWorkstationEnabledProvider =
    StateNotifierProvider<PrintWorkstationController, bool>((ref) {
  return PrintWorkstationController();
});

/// Polls server print jobs and dispatches to local TCP printers.
class RemotePrintJobWorker {
  RemotePrintJobWorker({
    required this.api,
    required this.ref,
    required this.logger,
  });

  final PosApi api;
  final Ref ref;
  final AppLogger logger;

  Timer? _timer;
  bool _busy = false;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final jobs = await api.pollPrintJobs();
      for (final job in jobs) {
        final id = job['id'] as String;
        try {
          await _dispatch(job);
          await api.completePrintJob(id);
        } catch (e, st) {
          logger.warn('remote print job $id failed', e, st);
          await api.failPrintJob(id, error: e.toString());
        }
      }
    } catch (e, st) {
      logger.warn('print job poll failed', e, st);
    } finally {
      _busy = false;
    }
  }

  Future<void> _dispatch(Map<String, dynamic> job) async {
    final docType = job['doc_type'] as String;
    final payload = (job['payload'] as Map).cast<String, dynamic>();

    switch (docType) {
      case 'kitchen_ticket':
        await ref.read(kitchenPrinterServiceProvider).printTicket(_kitchenFromJson(payload));
      case 'confirmation':
        await ref.read(printerServiceProvider).printConfirmation(_confirmationFromJson(payload));
      case 'receipt':
        final order = _orderFromJson(payload);
        final invoice = _invoiceFromJson(payload['invoice'] as Map<String, dynamic>?);
        await ref.read(printerServiceProvider).printReceipt(
              order,
              invoice: invoice,
              orderNo: payload['order_no'] as String?,
              tableLabel: payload['table_label'] as String?,
            );
      case 'invoice_proof':
        await ref.read(printerServiceProvider).printInvoiceProof(
              storeName: payload['store_name'] as String? ?? '點餐趣',
              storeTaxId: payload['store_tax_id'] as String?,
              invoiceNumber: payload['invoice_number'] as String,
              invoiceDate: DateTime.parse(payload['invoice_date'] as String),
              randomCode: payload['random_code'] as String? ?? '0000',
              total: Money((payload['total_cents'] as num).toInt()),
              buyerTaxId: payload['buyer_tax_id'] as String?,
              barcode: payload['barcode'] as String?,
              qrLeft: payload['qr_left'] as String?,
              qrRight: payload['qr_right'] as String?,
            );
      case 'qr_slip':
        await ref.read(printerServiceProvider).printTableQr(
              storeName: payload['store_name'] as String? ?? '點餐趣',
              tableLabel: payload['table_label'] as String,
              orderUrl: payload['order_url'] as String,
              expiresAt: payload['expires_at'] != null
                  ? DateTime.parse(payload['expires_at'] as String)
                  : null,
            );
      case 'label':
        final labels = (payload['labels'] as List)
            .map((e) => _drinkLabelFromJson((e as Map).cast<String, dynamic>()))
            .toList();
        await ref.read(labelPrinterServiceProvider).printLabels(labels);
      default:
        throw StateError('unknown doc_type: $docType');
    }
  }
}

KitchenTicket _kitchenFromJson(Map<String, dynamic> j) => KitchenTicket(
      guestOrderId: j['guest_order_id'] as String? ?? '',
      tableLabel: j['table_label'] as String? ?? '',
      placedAt: DateTime.parse(j['placed_at'] as String),
      partySize: (j['party_size'] as num?)?.toInt(),
      note: j['note'] as String?,
      lines: (j['lines'] as List)
          .map(
            (ln) => KitchenTicketLine(
              name: (ln as Map)['name'] as String,
              qty: (ln)['qty'] as num,
              note: ln['note'] as String?,
              optionsLabel: ln['options_label'] as String?,
            ),
          )
          .toList(),
    );

OrderConfirmation _confirmationFromJson(Map<String, dynamic> j) => OrderConfirmation(
      tableLabel: j['table_label'] as String? ?? '',
      placedAt: DateTime.parse(j['placed_at'] as String),
      orderRef: j['order_ref'] as String?,
      note: j['note'] as String?,
      estimatedTotal: Money((j['estimated_total_cents'] as num).toInt()),
      lines: (j['lines'] as List)
          .map(
            (ln) => OrderConfirmationLine(
              name: (ln as Map)['name'] as String,
              qty: ln['qty'] as num,
              lineTotal: Money((ln['line_total_cents'] as num).toInt()),
              optionsLabel: ln['options_label'] as String?,
              note: ln['note'] as String?,
            ),
          )
          .toList(),
    );

DrinkLabel _drinkLabelFromJson(Map<String, dynamic> j) => DrinkLabel(
      productName: j['product_name'] as String,
      tableLabel: j['table_label'] as String? ?? '',
      orderRef: j['order_ref'] as String? ?? '',
      placedAt: DateTime.parse(j['placed_at'] as String),
      cupIndex: (j['cup_index'] as num?)?.toInt() ?? 1,
      cupTotal: (j['cup_total'] as num?)?.toInt() ?? 1,
      optionsLabel: j['options_label'] as String? ?? '',
      note: j['note'] as String?,
    );

dom.Order _orderFromJson(Map<String, dynamic> j) {
  final orderJson = (j['order'] as Map?)?.cast<String, dynamic>() ?? j;
  final lines = (orderJson['lines'] as List).map((ln) {
    final m = (ln as Map).cast<String, dynamic>();
    final optionsRaw = m['options_json'];
    final options = <dom.SelectedOption>[];
    if (optionsRaw is List) {
      for (final o in optionsRaw) {
        options.add(dom.SelectedOption.fromJson((o as Map).cast<String, dynamic>()));
      }
    }
    return dom.OrderLine(
      id: m['id'] as String,
      productId: m['product_id'] as String,
      productName: m['product_name'] as String,
      sku: m['sku'] as String? ?? '',
      qty: (m['qty'] as num).toDouble(),
      unitPrice: Money((m['unit_price_cents'] as num).toInt()),
      lineDiscount: Money((m['line_discount_cents'] as num?)?.toInt() ?? 0),
      lineTotal: Money((m['line_total_cents'] as num).toInt()),
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0.05,
      note: m['note'] as String?,
      selectedOptions: options,
    );
  }).toList();

  final payments = (orderJson['payments'] as List? ?? []).map((p) {
    final m = (p as Map).cast<String, dynamic>();
    return dom.Payment(
      id: m['id'] as String,
      method: dom.PaymentMethodX.fromCode(m['method'] as String),
      amount: Money((m['amount_cents'] as num).toInt()),
      status: dom.PaymentStatus.values.byName(m['status'] as String? ?? 'captured'),
      tendered: m['tendered_cents'] != null ? Money((m['tendered_cents'] as num).toInt()) : null,
      changeDue: m['change_due_cents'] != null ? Money((m['change_due_cents'] as num).toInt()) : null,
    );
  }).toList();

  return dom.Order(
    id: orderJson['id'] as String,
    storeId: orderJson['store_id'] as String,
    terminalId: orderJson['terminal_id'] as String? ?? '',
    cashierId: orderJson['cashier_id'] as String? ?? '',
    memberId: orderJson['member_id'] as String?,
    status: dom.OrderStatus.paid,
    subtotal: Money((orderJson['subtotal_cents'] as num).toInt()),
    discount: Money((orderJson['discount_cents'] as num?)?.toInt() ?? 0),
    tax: Money((orderJson['tax_cents'] as num?)?.toInt() ?? 0),
    total: Money((orderJson['total_cents'] as num).toInt()),
    note: orderJson['note'] as String?,
    createdAt: DateTime.parse(orderJson['client_created_at'] as String? ?? orderJson['created_at'] as String),
    lines: lines,
    payments: payments,
  );
}

dom.Invoice? _invoiceFromJson(Map<String, dynamic>? j) {
  if (j == null || j['status'] != 'issued') return null;
  return dom.Invoice(
    id: j['id'] as String,
    orderId: j['order_id'] as String,
    status: dom.InvoiceStatus.issued,
    totalAmount: Money((j['total_cents'] as num).toInt()),
    tax: Money((j['tax_cents'] as num?)?.toInt() ?? 0),
    taxType: (j['tax_type'] as num?)?.toInt() ?? 1,
    invoiceNumber: j['invoice_number'] as String?,
    invoiceDate: j['invoice_date'] != null ? DateTime.parse(j['invoice_date'] as String) : null,
    taxId: j['tax_id'] as String?,
    randomCode: j['random_code'] as String?,
    barcode: j['barcode'] as String?,
    qrLeft: j['qr_left'] as String?,
    qrRight: j['qr_right'] as String?,
  );
}

final remotePrintJobWorkerProvider = Provider<RemotePrintJobWorker>((ref) {
  final worker = RemotePrintJobWorker(
    api: ref.read(posApiProvider),
    ref: ref,
    logger: ref.read(loggerProvider),
  );
  ref.onDispose(worker.stop);
  return worker;
});

final printWorkstationLifecycleProvider = Provider<void>((ref) {
  ref.listen<bool>(printWorkstationEnabledProvider, (prev, enabled) {
    final worker = ref.read(remotePrintJobWorkerProvider);
    if (enabled) {
      worker.start();
    } else {
      worker.stop();
    }
  }, fireImmediately: true);

  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (!next.isLoggedIn) {
      ref.read(remotePrintJobWorkerProvider).stop();
      return;
    }
    if (ref.read(printWorkstationEnabledProvider)) {
      ref.read(remotePrintJobWorkerProvider).start();
    }
  });
});
