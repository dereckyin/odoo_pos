import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

import 'escpos_service.dart';
import 'print_job_queue.dart';
import 'printer_prefs.dart';
import 'printer_samples.dart';
import 'raw_printer_driver.dart';
import 'tspl_service.dart';

export 'printer_prefs.dart';

PaperSize paperSizeFromMm(int mm) => mm <= 58 ? PaperSize.mm58 : PaperSize.mm80;

class PrinterPrefsController extends StateNotifier<PrinterPreferences> {
  PrinterPrefsController({required this.storageKey, PrinterPreferences? defaults})
      : super(defaults ?? PrinterPreferences()) {
    _load();
  }

  final String storageKey;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return;
    state = PrinterPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(PrinterPreferences p) async {
    state = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(p.toJson()));
  }
}

final printerPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>(
        (_) => PrinterPrefsController(storageKey: 'pos.printer.prefs'));

final kitchenPrinterPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>((_) {
  return PrinterPrefsController(
    storageKey: 'pos.printer.kitchen.prefs',
    defaults: PrinterPreferences(host: '192.168.1.110', enabled: false),
  );
});

final labelPrinterPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>((_) {
  return PrinterPrefsController(
    storageKey: 'pos.printer.label.prefs',
    defaults: PrinterPreferences(
      host: '192.168.1.120',
      enabled: false,
      kind: PrinterKind.tspl,
      labelWidthMm: 40,
      labelHeightMm: 30,
    ),
  );
});

final rawPrinterDriverProvider = Provider<RawPrinterDriver>((ref) {
  final driver = RawPrinterDriver();
  ref.onDispose(() {
    unawaited(driver.disconnectBluetooth());
  });
  return driver;
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService(
    ref: ref,
    driver: ref.watch(rawPrinterDriverProvider),
    queue: ref.watch(printJobQueueProvider),
    logger: AppLogger.named('printer'),
  );
});

final kitchenPrinterServiceProvider = Provider<KitchenPrinterService>((ref) {
  return KitchenPrinterService(
    ref: ref,
    driver: ref.watch(rawPrinterDriverProvider),
    queue: ref.watch(printJobQueueProvider),
    logger: AppLogger.named('kitchen-printer'),
  );
});

final labelPrinterServiceProvider = Provider<LabelPrinterService>((ref) {
  return LabelPrinterService(
    ref: ref,
    driver: ref.watch(rawPrinterDriverProvider),
    queue: ref.watch(printJobQueueProvider),
    logger: AppLogger.named('label-printer'),
  );
});

class PrinterService {
  PrinterService({
    required this.ref,
    required this.driver,
    required this.queue,
    required this.logger,
  });

  final Ref ref;
  final RawPrinterDriver driver;
  final PrintJobQueue queue;
  final AppLogger logger;

  EscPosReceiptBuilder _receiptBuilder(PrinterPreferences prefs) =>
      EscPosReceiptBuilder(
        paperWidth: paperSizeFromMm(prefs.paperWidth),
        charset: prefs.escposCharset,
      );

  EscPosConfirmationBuilder _confirmationBuilder(PrinterPreferences prefs) =>
      EscPosConfirmationBuilder(
        paperWidth: paperSizeFromMm(prefs.paperWidth),
        charset: prefs.escposCharset,
      );

  EscPosInvoiceBuilder _invoiceBuilder(PrinterPreferences prefs) =>
      EscPosInvoiceBuilder(
        paperWidth: paperSizeFromMm(prefs.paperWidth),
        charset: prefs.escposCharset,
      );

  EscPosTableQrBuilder _tableQrBuilder(PrinterPreferences prefs) =>
      EscPosTableQrBuilder(
        paperWidth: paperSizeFromMm(prefs.paperWidth),
        charset: prefs.escposCharset,
      );

  Future<void> _send(
    String label,
    PrinterPreferences prefs,
    Uint8List bytes, {
    String? hostOverride,
  }) {
    if (!prefs.enabled && hostOverride == null) return Future.value();
    return queue.run(label, () async {
      await driver.printBytes(prefs, bytes, hostOverride: hostOverride);
    });
  }

  Future<void> printReceipt(
    dom.Order order, {
    dom.Invoice? invoice,
    String? hostOverride,
    String? orderNo,
    String? tableLabel,
  }) async {
    final prefs = ref.read(printerPrefsProvider);
    final bytes = Uint8List.fromList(
      await _receiptBuilder(prefs).build(
        order,
        invoice: invoice,
        orderNo: orderNo,
        tableLabel: tableLabel,
      ),
    );
    await _send('收據', prefs, bytes, hostOverride: hostOverride);
  }

  Future<void> printConfirmation(OrderConfirmation order, {String? hostOverride}) async {
    final prefs = ref.read(printerPrefsProvider);
    final bytes = Uint8List.fromList(await _confirmationBuilder(prefs).build(order));
    await _send('確認單', prefs, bytes, hostOverride: hostOverride);
  }

  Future<void> printInvoiceProof({
    required String storeName,
    String? storeTaxId,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String randomCode,
    required Money total,
    String? buyerTaxId,
    String? barcode,
    String? qrLeft,
    String? qrRight,
    String? hostOverride,
  }) async {
    final prefs = ref.read(printerPrefsProvider);
    final bytes = Uint8List.fromList(
      await _invoiceBuilder(prefs).build(
        storeName: storeName,
        storeTaxId: storeTaxId,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        randomCode: randomCode,
        total: total,
        buyerTaxId: buyerTaxId,
        barcode: barcode,
        qrLeft: qrLeft,
        qrRight: qrRight,
      ),
    );
    await _send('發票證明聯', prefs, bytes, hostOverride: hostOverride);
  }

  Future<void> printTableQr({
    required String storeName,
    required String tableLabel,
    required String orderUrl,
    DateTime? expiresAt,
    String? hostOverride,
  }) async {
    final prefs = ref.read(printerPrefsProvider);
    final bytes = Uint8List.fromList(
      await _tableQrBuilder(prefs).build(
        storeName: storeName,
        tableLabel: tableLabel,
        orderUrl: orderUrl,
        expiresAt: expiresAt,
      ),
    );
    await _send('點餐 QR', prefs, bytes, hostOverride: hostOverride);
  }

  Future<void> printTestReceipt(PrinterPreferences prefs) async {
    final bytes = Uint8List.fromList(
      await _receiptBuilder(prefs).build(PrinterSamples.sampleReceiptOrder(), storeName: '點餐趣 測試列印'),
    );
    await driver.printBytes(prefs, bytes);
  }
}

class KitchenPrinterService {
  KitchenPrinterService({
    required this.ref,
    required this.driver,
    required this.queue,
    required this.logger,
  });

  final Ref ref;
  final RawPrinterDriver driver;
  final PrintJobQueue queue;
  final AppLogger logger;

  EscPosKitchenBuilder _kitchenBuilder(PrinterPreferences prefs) =>
      EscPosKitchenBuilder(
        paperWidth: paperSizeFromMm(prefs.paperWidth),
        charset: prefs.escposCharset,
      );

  Future<bool> printTicket(KitchenTicket ticket) async {
    final prefs = ref.read(kitchenPrinterPrefsProvider);
    if (!prefs.enabled) return true;
    final bytes = Uint8List.fromList(await _kitchenBuilder(prefs).build(ticket));
    await queue.run('廚房單', () async {
      await driver.printBytes(prefs, bytes);
    });
    return true;
  }

  Future<void> printTestTicket(PrinterPreferences prefs) async {
    final bytes = Uint8List.fromList(
      await _kitchenBuilder(prefs).build(PrinterSamples.sampleKitchenTicket()),
    );
    await driver.printBytes(prefs, bytes);
  }
}

class LabelPrinterService {
  LabelPrinterService({
    required this.ref,
    required this.driver,
    required this.queue,
    required this.logger,
  });

  final Ref ref;
  final RawPrinterDriver driver;
  final PrintJobQueue queue;
  final AppLogger logger;

  TsplLabelBuilder _builder(PrinterPreferences prefs) => TsplLabelBuilder(
        labelWidthMm: prefs.labelWidthMm,
        labelHeightMm: prefs.labelHeightMm,
        gapMm: prefs.gapMm,
      );

  Future<void> printLabel(DrinkLabel label, {String? hostOverride}) async {
    final prefs = ref.read(labelPrinterPrefsProvider);
    if (!prefs.enabled && hostOverride == null) return;
    final bytes = await _builder(prefs).build(label);
    await queue.run('標籤', () async {
      await driver.printBytes(prefs, bytes, hostOverride: hostOverride);
    });
  }

  Future<void> printLabels(List<DrinkLabel> labels, {String? hostOverride}) async {
    for (final label in labels) {
      await printLabel(label, hostOverride: hostOverride);
    }
  }

  Future<void> printTestLabel(PrinterPreferences prefs) async {
    final bytes = await _builder(prefs).build(
      DrinkLabel(
        productName: '測試飲料',
        tableLabel: 'A1',
        orderRef: '1234',
        placedAt: DateTime.now(),
        cupIndex: 1,
        cupTotal: 1,
        optionsLabel: '半糖 / 少冰',
      ),
    );
    await driver.printBytes(prefs, bytes);
  }
}
