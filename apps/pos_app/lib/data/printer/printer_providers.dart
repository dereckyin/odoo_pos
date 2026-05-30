import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

import 'escpos_service.dart';
import 'printer_samples.dart';

PaperSize paperSizeFromMm(int mm) => mm <= 58 ? PaperSize.mm58 : PaperSize.mm80;

class PrinterPreferences {
  PrinterPreferences({
    this.host = '192.168.1.100',
    this.port = 9100,
    this.paperWidth = 80,
    this.enabled = false,
  });

  final String host;
  final int port;
  final int paperWidth;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'paperWidth': paperWidth,
        'enabled': enabled,
      };

  factory PrinterPreferences.fromJson(Map<String, dynamic> j) => PrinterPreferences(
        host: j['host'] as String? ?? '192.168.1.100',
        port: (j['port'] as num?)?.toInt() ?? 9100,
        paperWidth: (j['paperWidth'] as num?)?.toInt() ?? 80,
        enabled: j['enabled'] as bool? ?? false,
      );

  PrinterPreferences copyWith({String? host, int? port, int? paperWidth, bool? enabled}) =>
      PrinterPreferences(
        host: host ?? this.host,
        port: port ?? this.port,
        paperWidth: paperWidth ?? this.paperWidth,
        enabled: enabled ?? this.enabled,
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

/// Receipt printer (front-of-house, attached to cashier's lane).
final printerPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>(
        (_) => PrinterPrefsController(storageKey: 'pos.printer.prefs'));

/// Kitchen printer (back-of-house). Defaults are different so we don't
/// accidentally overwrite the cashier printer's IP.
final kitchenPrinterPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>((_) {
  return PrinterPrefsController(
    storageKey: 'pos.printer.kitchen.prefs',
    defaults: PrinterPreferences(host: '192.168.1.110', enabled: false),
  );
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService(
    ref: ref,
    driver: TcpPrinterDriver(),
    logger: AppLogger.named('printer'),
  );
});

final kitchenPrinterServiceProvider = Provider<KitchenPrinterService>((ref) {
  return KitchenPrinterService(
    ref: ref,
    driver: TcpPrinterDriver(),
    logger: AppLogger.named('kitchen-printer'),
  );
});

class PrinterService {
  PrinterService({
    required this.ref,
    required this.driver,
    required this.logger,
  });

  final Ref ref;
  final TcpPrinterDriver driver;
  final AppLogger logger;

  EscPosReceiptBuilder _receiptBuilder(PrinterPreferences prefs) =>
      EscPosReceiptBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  Future<void> printReceipt(dom.Order order, {dom.Invoice? invoice, String? hostOverride}) async {
    final prefs = ref.read(printerPrefsProvider);
    if (!prefs.enabled && hostOverride == null) return;
    final bytes = Uint8List.fromList(
      await _receiptBuilder(prefs).build(order, invoice: invoice),
    );
    try {
      await driver.printRaw(hostOverride ?? prefs.host, bytes, port: prefs.port);
    } catch (e, st) {
      logger.warn('print failed', e, st);
      rethrow;
    }
  }

  /// Sends a sample receipt using [host] / [port] (ignores `enabled`; for setup).
  Future<void> printTestReceipt({
    required String host,
    required int port,
    required int paperWidth,
  }) async {
    final prefs = PrinterPreferences(host: host, port: port, paperWidth: paperWidth, enabled: true);
    final bytes = Uint8List.fromList(
      await _receiptBuilder(prefs).build(PrinterSamples.sampleReceiptOrder(), storeName: '點餐趣 測試列印'),
    );
    try {
      await driver.printRaw(host, bytes, port: port);
    } catch (e, st) {
      logger.warn('test receipt print failed', e, st);
      rethrow;
    }
  }
}

/// Sends kitchen tickets to the back-of-house ESC/POS printer.
class KitchenPrinterService {
  KitchenPrinterService({
    required this.ref,
    required this.driver,
    required this.logger,
  });

  final Ref ref;
  final TcpPrinterDriver driver;
  final AppLogger logger;

  EscPosKitchenBuilder _kitchenBuilder(PrinterPreferences prefs) =>
      EscPosKitchenBuilder(paperWidth: paperSizeFromMm(prefs.paperWidth));

  /// Prints [ticket] to the configured kitchen printer. Returns ``true``
  /// when the printer is **disabled** in preferences (silent no-op so the
  /// KDS UI flow still works on dev machines without a kitchen printer
  /// physically attached). Throws on real I/O failure so the caller can
  /// keep the order in `submitted` and surface a retry.
  Future<bool> printTicket(KitchenTicket ticket) async {
    final prefs = ref.read(kitchenPrinterPrefsProvider);
    if (!prefs.enabled) return true; // silently skip
    final bytes = Uint8List.fromList(await _kitchenBuilder(prefs).build(ticket));
    try {
      await driver.printRaw(prefs.host, bytes, port: prefs.port);
      return true;
    } catch (e, st) {
      logger.warn('kitchen print failed', e, st);
      rethrow;
    }
  }

  /// Sends a sample kitchen ticket using [host] / [port] (ignores `enabled`).
  Future<void> printTestTicket({
    required String host,
    required int port,
    required int paperWidth,
  }) async {
    final prefs = PrinterPreferences(host: host, port: port, paperWidth: paperWidth, enabled: true);
    final bytes = Uint8List.fromList(
      await _kitchenBuilder(prefs).build(PrinterSamples.sampleKitchenTicket()),
    );
    try {
      await driver.printRaw(host, bytes, port: port);
    } catch (e, st) {
      logger.warn('test kitchen print failed', e, st);
      rethrow;
    }
  }
}
