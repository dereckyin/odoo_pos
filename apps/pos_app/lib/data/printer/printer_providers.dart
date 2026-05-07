import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;
import 'package:shared_preferences/shared_preferences.dart';

import 'escpos_service.dart';

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
}

class PrinterPrefsController extends StateNotifier<PrinterPreferences> {
  PrinterPrefsController() : super(PrinterPreferences()) {
    _load();
  }

  static const _kKey = 'pos.printer.prefs';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    state = PrinterPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(PrinterPreferences p) async {
    state = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(p.toJson()));
  }
}

final printerPrefsProvider =
    StateNotifierProvider<PrinterPrefsController, PrinterPreferences>((_) => PrinterPrefsController());

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService(
    ref: ref,
    builder: EscPosReceiptBuilder(),
    driver: TcpPrinterDriver(),
    logger: AppLogger.named('printer'),
  );
});

class PrinterService {
  PrinterService({
    required this.ref,
    required this.builder,
    required this.driver,
    required this.logger,
  });

  final Ref ref;
  final EscPosReceiptBuilder builder;
  final TcpPrinterDriver driver;
  final AppLogger logger;

  Future<void> printReceipt(dom.Order order, {dom.Invoice? invoice, String? hostOverride}) async {
    final prefs = ref.read(printerPrefsProvider);
    if (!prefs.enabled && hostOverride == null) return;
    final bytes = Uint8List.fromList(await builder.build(order, invoice: invoice));
    try {
      await driver.printRaw(hostOverride ?? prefs.host, bytes, port: prefs.port);
    } catch (e, st) {
      logger.warn('print failed', e, st);
      rethrow;
    }
  }
}
