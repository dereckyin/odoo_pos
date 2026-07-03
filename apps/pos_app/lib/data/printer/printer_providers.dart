import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

import 'escpos_service.dart';
import 'print_job_queue.dart';
import 'printer_samples.dart';
import 'tspl_service.dart';

PaperSize paperSizeFromMm(int mm) => mm <= 58 ? PaperSize.mm58 : PaperSize.mm80;

enum PrinterKind { escpos, tspl }

class PrinterPreferences {
  PrinterPreferences({
    this.host = '192.168.1.100',
    this.port = 9100,
    this.paperWidth = 80,
    this.enabled = false,
    this.kind = PrinterKind.escpos,
    this.labelWidthMm = 40,
    this.labelHeightMm = 30,
    this.gapMm = 2.0,
  });

  final String host;
  final int port;
  final int paperWidth;
  final bool enabled;
  final PrinterKind kind;
  final int labelWidthMm;
  final int labelHeightMm;
  final double gapMm;

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'paperWidth': paperWidth,
        'enabled': enabled,
        'kind': kind.name,
        'labelWidthMm': labelWidthMm,
        'labelHeightMm': labelHeightMm,
        'gapMm': gapMm,
      };

  factory PrinterPreferences.fromJson(Map<String, dynamic> j) => PrinterPreferences(
        host: j['host'] as String? ?? '192.168.1.100',
        port: (j['port'] as num?)?.toInt() ?? 9100,
        paperWidth: (j['paperWidth'] as num?)?.toInt() ?? 80,
        enabled: j['enabled'] as bool? ?? false,
        kind: PrinterKind.values.byName(j['kind'] as String? ?? 'escpos'),
        labelWidthMm: (j['labelWidthMm'] as num?)?.toInt() ?? 40,
        labelHeightMm: (j['labelHeightMm'] as num?)?.toInt() ?? 30,
        gapMm: (j['gapMm'] as num?)?.toDouble() ?? 2.0,
      );

  PrinterPreferences copyWith({
    String? host,
    int? port,
    int? paperWidth,
    bool? enabled,
    PrinterKind? kind,
    int? labelWidthMm,
    int? labelHeightMm,
    double? gapMm,
  }) =>
      PrinterPreferences(
        host: host ?? this.host,
        port: port ?? this.port,
        paperWidth: paperWidth ?? this.paperWidth,
        enabled: enabled ?? this.enabled,
        kind: kind ?? this.kind,
        labelWidthMm: labelWidthMm ?? this.labelWidthMm,
        labelHeightMm: labelHeightMm ?? this.labelHeightMm,
        gapMm: gapMm ?? this.gapMm,
      );
}

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

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService(
    ref: ref,
    driver: TcpPrinterDriver(),
    queue: ref.watch(printJobQueueProvider),
    logger: AppLogger.named('printer'),
  );
});

final kitchenPrinterServiceProvider = Provider<KitchenPrinterService>((ref) {
  return KitchenPrinterService(
    ref: ref,
    driver: TcpPrinterDriver(),
    queue: ref.watch(printJobQueueProvider),
    logger: AppLogger.named('kitchen-printer'),
  );
});

final labelPrinterServiceProvider = Provider<LabelPrinterService>((ref) {
  return LabelPrinterService(
    ref: ref,
    driver: TsplPrinterDriver(),
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
  final TcpPrinterDriver driver;
  final PrintJobQueue queue;
  final AppLogger logger;

  EscPosReceiptBuilder _receiptBuilder(PrinterPreferences prefs) =>
      EscPosReceiptBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  EscPosConfirmationBuilder _confirmationBuilder(PrinterPreferences prefs) =>
      EscPosConfirmationBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  EscPosInvoiceBuilder _invoiceBuilder(PrinterPreferences prefs) =>
      EscPosInvoiceBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  EscPosTableQrBuilder _tableQrBuilder(PrinterPreferences prefs) =>
      EscPosTableQrBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  Future<void> _send(String label, PrinterPreferences prefs, Uint8List bytes,
      {String? hostOverride}) {
    if (!prefs.enabled && hostOverride == null) return Future.value();
    return queue.run(label, () async {
      await driver.printRaw(hostOverride ?? prefs.host, bytes, port: prefs.port);
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

  Future<void> printTestReceipt({
    required String host,
    required int port,
    required int paperWidth,
  }) async {
    final prefs = PrinterPreferences(host: host, port: port, paperWidth: paperWidth, enabled: true);
    final bytes = Uint8List.fromList(
      await _receiptBuilder(prefs).build(PrinterSamples.sampleReceiptOrder(), storeName: '點餐趣 測試列印'),
    );
    await driver.printRaw(host, bytes, port: port);
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
  final TcpPrinterDriver driver;
  final PrintJobQueue queue;
  final AppLogger logger;

  EscPosKitchenBuilder _kitchenBuilder(PrinterPreferences prefs) =>
      EscPosKitchenBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  Future<bool> printTicket(KitchenTicket ticket) async {
    final prefs = ref.read(kitchenPrinterPrefsProvider);
    if (!prefs.enabled) return true;
    final bytes = Uint8List.fromList(await _kitchenBuilder(prefs).build(ticket));
    await queue.run('廚房單', () async {
      await driver.printRaw(prefs.host, bytes, port: prefs.port);
    });
    return true;
  }

  Future<void> printTestTicket({
    required String host,
    required int port,
    required int paperWidth,
  }) async {
    final prefs = PrinterPreferences(host: host, port: port, paperWidth: paperWidth, enabled: true);
    final bytes = Uint8List.fromList(
      await _kitchenBuilder(prefs).build(PrinterSamples.sampleKitchenTicket()),
    );
    await driver.printRaw(host, bytes, port: port);
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
  final TsplPrinterDriver driver;
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
      await driver.printRaw(hostOverride ?? prefs.host, bytes, port: prefs.port);
    });
  }

  Future<void> printLabels(List<DrinkLabel> labels, {String? hostOverride}) async {
    for (final label in labels) {
      await printLabel(label, hostOverride: hostOverride);
    }
  }

  Future<void> printTestLabel({
    required String host,
    required int port,
    required int labelWidthMm,
    required int labelHeightMm,
    required double gapMm,
  }) async {
    final prefs = PrinterPreferences(
      host: host,
      port: port,
      enabled: true,
      kind: PrinterKind.tspl,
      labelWidthMm: labelWidthMm,
      labelHeightMm: labelHeightMm,
      gapMm: gapMm,
    );
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
    await driver.printRaw(host, bytes, port: port);
  }
}
