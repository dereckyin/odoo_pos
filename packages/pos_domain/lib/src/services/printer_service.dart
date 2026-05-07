import 'dart:typed_data';
import 'package:pos_core/pos_core.dart';

import '../entities/order.dart';
import '../entities/invoice.dart';

enum PrinterConnection { network, usb, bluetooth }

class PrinterConfig {
  const PrinterConfig({
    required this.connection,
    required this.identifier,
    this.port = 9100,
    this.paperWidth = 80,
    this.encoding = 'GBK',
    this.cutAfterPrint = true,
    this.openCashDrawer = true,
  });

  /// Network: ip address; USB: serial; BT: address
  final String identifier;
  final PrinterConnection connection;
  final int port;
  /// 58 or 80 mm
  final int paperWidth;
  final String encoding;
  final bool cutAfterPrint;
  final bool openCashDrawer;
}

abstract interface class PrinterService {
  Future<Result<void>> printReceipt(Order order, {Invoice? invoice, PrinterConfig? overrideConfig});
  Future<Result<void>> printRaw(Uint8List bytes, {PrinterConfig? overrideConfig});
  Future<Result<void>> openDrawer({PrinterConfig? overrideConfig});
  Future<Result<List<PrinterConfig>>> discover();
}
