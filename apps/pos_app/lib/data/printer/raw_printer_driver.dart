import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:permission_handler/permission_handler.dart';

import 'escpos_service.dart';
import 'printer_prefs.dart';

/// Whether this platform can use Bluetooth printers via the POS printer plugin.
bool get bluetoothPrintingSupported => Platform.isAndroid || Platform.isIOS;

/// Requests runtime permissions required for Bluetooth printer scan/connect.
///
/// The printer plugin also requests these, but on Android 12+ a missing
/// location declaration previously caused a permanent English toast failure.
Future<void> ensureBluetoothPrintPermissions({required bool isBle}) async {
  if (!Platform.isAndroid) return;

  final needed = <Permission>[
    Permission.locationWhenInUse,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ];
  if (isBle) {
    needed.add(Permission.bluetoothAdvertise);
  }

  final statuses = await needed.request();
  final denied = statuses.entries.where((e) => !e.value.isGranted).map((e) => e.key).toList();
  if (denied.isEmpty) return;

  final forever = denied.any((p) => statuses[p]?.isPermanentlyDenied ?? false);
  if (forever) {
    throw StateError('藍牙／定位權限被永久拒絕，請到系統設定開啟後再掃描');
  }
  throw StateError('需要允許藍牙與定位權限才能掃描印表機（請全部允許）');
}

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

    await ensureBluetoothPrintPermissions(isBle: prefs.bluetoothIsBle);

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

    await ensureBluetoothPrintPermissions(isBle: isBle);

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
