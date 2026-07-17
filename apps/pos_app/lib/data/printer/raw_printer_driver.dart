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

String? normalizeBluetoothAddress(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  // Accept AA:BB:… or AA-BB-… ; plugin regex allows both.
  final hex = s.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (hex.length != 12) return s.toUpperCase();
  final parts = <String>[];
  for (var i = 0; i < 12; i += 2) {
    parts.add(hex.substring(i, i + 2).toUpperCase());
  }
  return parts.join(':');
}

/// Sends raw ESC/POS or TSPL bytes over network TCP or Bluetooth.
class RawPrinterDriver {
  RawPrinterDriver({TcpPrinterDriver? tcp}) : _tcp = tcp ?? TcpPrinterDriver();

  final TcpPrinterDriver _tcp;
  final PrinterManager _manager = PrinterManager.instance;

  String? _connectedAddress;
  bool _connectedIsBle = false;
  StreamSubscription<BTStatus>? _statusSub;
  BTStatus _btStatus = BTStatus.none;

  Future<void> printBytes(
    PrinterPreferences prefs,
    Uint8List bytes, {
    String? hostOverride,
    int? portOverride,
  }) async {
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

  void _ensureStatusListener() {
    _statusSub ??= _manager.stateBluetooth.listen((status) {
      _btStatus = status;
      if (status == BTStatus.none) {
        _connectedAddress = null;
      }
    });
  }

  Future<void> _waitUntilConnected({Duration timeout = const Duration(seconds: 12)}) async {
    if (_btStatus == BTStatus.connected || _manager.currentStatusBT == BTStatus.connected) {
      return;
    }
    final completer = Completer<void>();
    late StreamSubscription<BTStatus> sub;
    Timer? timer;
    sub = _manager.stateBluetooth.listen((status) {
      _btStatus = status;
      if (status == BTStatus.connected && !completer.isCompleted) {
        completer.complete();
      }
      if (status == BTStatus.none && !completer.isCompleted) {
        // keep waiting until timeout — transient none during connect is possible
      }
    });
    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('等待藍牙連線逾時（請確認印表機已開機，並在系統設定已配對）'),
        );
      }
    });
    try {
      await completer.future;
    } finally {
      await sub.cancel();
      timer.cancel();
    }
  }

  Future<void> _ensureBluetoothConnected(PrinterPreferences prefs) async {
    final address = normalizeBluetoothAddress(prefs.bluetoothAddress);
    if (address == null || address.isEmpty) {
      throw StateError('尚未選擇藍牙印表機');
    }

    await ensureBluetoothPrintPermissions(isBle: prefs.bluetoothIsBle);
    _ensureStatusListener();

    final already =
        _connectedAddress == address &&
        _connectedIsBle == prefs.bluetoothIsBle &&
        (_btStatus == BTStatus.connected || _manager.currentStatusBT == BTStatus.connected);

    if (already) return;

    if (_connectedAddress != null && _connectedAddress != address) {
      try {
        await _manager.disconnect(type: PrinterType.bluetooth, delayMs: 300);
      } catch (_) {}
      _connectedAddress = null;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    final ok = await _manager.connect(
      type: PrinterType.bluetooth,
      model: BluetoothPrinterInput(
        name: prefs.bluetoothName ?? address,
        address: address,
        isBle: prefs.bluetoothIsBle,
        // Keep trying if the socket drops between jobs.
        autoConnect: true,
      ),
    );
    if (!ok && _manager.currentStatusBT != BTStatus.connected) {
      throw StateError('無法連線藍牙印表機（$address）。請先在系統藍牙設定完成配對後再試');
    }

    await _waitUntilConnected();
    // Android classic SPP often needs a short settle time before write.
    if (Platform.isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    _connectedAddress = address;
    _connectedIsBle = prefs.bluetoothIsBle;
  }

  Future<void> _printBluetooth(PrinterPreferences prefs, Uint8List bytes) async {
    if (!bluetoothPrintingSupported) {
      throw StateError('此平台不支援藍牙印表機（請改用網路印表機）');
    }

    await _ensureBluetoothConnected(prefs);

    final ok = await _manager.send(type: PrinterType.bluetooth, bytes: bytes);
    if (!ok) {
      // One reconnect + retry — common after printer sleeps.
      _connectedAddress = null;
      await _ensureBluetoothConnected(prefs);
      final retry = await _manager.send(type: PrinterType.bluetooth, bytes: bytes);
      if (!retry) {
        throw StateError('藍牙印表機傳送失敗（連線狀態異常，請重新配對後再測）');
      }
    }

    // Let the printer drain the buffer. Do NOT disconnect immediately —
    // closing the socket triggers "Bluetooth connection lost" toast and
    // often cuts the end of the receipt.
    final drainMs = (800 + (bytes.length / 40).round()).clamp(800, 4000);
    await Future<void>.delayed(Duration(milliseconds: drainMs));
  }

  /// Explicit disconnect (e.g. when leaving printer settings).
  Future<void> disconnectBluetooth() async {
    try {
      await _manager.disconnect(type: PrinterType.bluetooth, delayMs: 300);
    } catch (_) {}
    _connectedAddress = null;
    _btStatus = BTStatus.none;
  }
}

/// Scans for nearby / paired Bluetooth printers.
class BluetoothPrinterScanner {
  StreamSubscription<PrinterDevice>? _sub;

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
        final key = normalizeBluetoothAddress(device.address) ?? device.name;
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
