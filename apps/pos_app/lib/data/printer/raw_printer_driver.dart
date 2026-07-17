import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

import 'escpos_service.dart';
import 'printer_prefs.dart';

/// Whether this platform can use Bluetooth printers via the POS printer plugin.
bool get bluetoothPrintingSupported => Platform.isAndroid || Platform.isIOS;

/// Sends raw ESC/POS or TSPL bytes over network TCP or Bluetooth.
class RawPrinterDriver {
  RawPrinterDriver({TcpPrinterDriver? tcp}) : _tcp = tcp ?? TcpPrinterDriver();

  final TcpPrinterDriver _tcp;
  final PrinterManager _manager = PrinterManager.instance;

  Future<void> printBytes(
    PrinterPreferences prefs,
    Uint8List bytes, {
    String? hostOverride,
    int? portOverride,
  }) async {
    // Explicit host override always means network (e.g. remote print workstation).
    final useNetwork = hostOverride != null ||
        prefs.connectionType == PrinterConnectionType.network;

    if (useNetwork) {
      await _tcp.printRaw(
        hostOverride ?? prefs.host,
        bytes,
        port: portOverride ?? prefs.port,
      );
      return;
    }

    await _printBluetooth(prefs, bytes);
  }

  Future<void> _printBluetooth(PrinterPreferences prefs, Uint8List bytes) async {
    if (!bluetoothPrintingSupported) {
      throw StateError('此平台不支援藍牙印表機（請改用網路印表機）');
    }
    final address = prefs.bluetoothAddress?.trim() ?? '';
    if (address.isEmpty) {
      throw StateError('尚未選擇藍牙印表機');
    }

    final connected = await _manager.connect(
      type: PrinterType.bluetooth,
      model: BluetoothPrinterInput(
        name: prefs.bluetoothName ?? address,
        address: address,
        isBle: prefs.bluetoothIsBle,
        autoConnect: false,
      ),
    );
    if (!connected) {
      throw StateError('無法連線藍牙印表機（$address）');
    }

    try {
      final ok = await _manager.send(type: PrinterType.bluetooth, bytes: bytes);
      if (!ok) {
        throw StateError('藍牙印表機傳送失敗');
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      try {
        await _manager.disconnect(type: PrinterType.bluetooth, delayMs: 200);
      } catch (_) {}
    }
  }
}

/// Scans for nearby / paired Bluetooth printers.
class BluetoothPrinterScanner {
  StreamSubscription<PrinterDevice>? _sub;

  /// Collects devices for [timeout], then cancels discovery.
  Future<List<PrinterDevice>> scan({
    bool isBle = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!bluetoothPrintingSupported) {
      throw StateError('此平台不支援藍牙掃描');
    }

    final byAddress = <String, PrinterDevice>{};
    final completer = Completer<List<PrinterDevice>>();

    await stop();
    _sub = PrinterManager.instance
        .discovery(type: PrinterType.bluetooth, isBle: isBle)
        .listen(
      (device) {
        final key = device.address ?? device.name;
        if (key.isEmpty) return;
        byAddress[key] = device;
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      },
    );

    Future<void>.delayed(timeout).then((_) async {
      await stop();
      if (!completer.isCompleted) {
        completer.complete(byAddress.values.toList());
      }
    });

    return completer.future;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
