import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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

  static const int _btChunkSize = 512;

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

  bool get _isConnected =>
      _btStatus == BTStatus.connected || _manager.currentStatusBT == BTStatus.connected;

  Future<void> _waitUntilConnected({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription<BTStatus> sub;
    Timer? timer;
    sub = _manager.stateBluetooth.listen((status) {
      _btStatus = status;
      if (status == BTStatus.connected && !completer.isCompleted) {
        completer.complete();
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

  Future<void> _hardResetBluetooth() async {
    try {
      await _manager.disconnect(type: PrinterType.bluetooth, delayMs: 200);
    } catch (_) {}
    _connectedAddress = null;
    _btStatus = BTStatus.none;
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _ensureBluetoothConnected(
    PrinterPreferences prefs, {
    bool forceReconnect = false,
  }) async {
    final address = normalizeBluetoothAddress(prefs.bluetoothAddress);
    if (address == null || address.isEmpty) {
      throw StateError('尚未選擇藍牙印表機');
    }

    await ensureBluetoothPrintPermissions(isBle: prefs.bluetoothIsBle);
    _ensureStatusListener();

    // Discovery interferes with RFCOMM connect on many Android stacks.
    try {
      await _manager.bluetoothPrinterConnector.stopScan();
    } catch (_) {}

    final already =
        !forceReconnect &&
        _connectedAddress == address &&
        _connectedIsBle == prefs.bluetoothIsBle &&
        _isConnected;

    if (already) return;

    await _hardResetBluetooth();

    final ok = await _manager.connect(
      type: PrinterType.bluetooth,
      model: BluetoothPrinterInput(
        name: prefs.bluetoothName ?? address,
        address: address,
        isBle: prefs.bluetoothIsBle,
        // autoConnect races with our own reconnect and often leaves state
        // CONNECTING so sendDataByte returns false.
        autoConnect: false,
      ),
    );
    if (!ok && !_isConnected) {
      throw StateError('無法連線藍牙印表機（$address）。請先在系統藍牙設定完成配對後再試');
    }

    await _waitUntilConnected();

    // Short settle only — long idle waits cause some printers to drop SPP.
    await Future<void>.delayed(
      Duration(milliseconds: Platform.isAndroid ? 250 : 200),
    );

    if (!_isConnected) {
      throw StateError('藍牙連線在就緒前已斷開，請關閉附近掃描後重試，或於系統設定重新配對');
    }

    _connectedAddress = address;
    _connectedIsBle = prefs.bluetoothIsBle;
  }

  Future<bool> _sendBluetoothChunks(Uint8List bytes) async {
    if (bytes.isEmpty) return true;

    for (var offset = 0; offset < bytes.length; offset += _btChunkSize) {
      if (!_isConnected) return false;
      final end = math.min(offset + _btChunkSize, bytes.length);
      final chunk = Uint8List.sublistView(bytes, offset, end);
      final ok = await _manager.send(type: PrinterType.bluetooth, bytes: chunk);
      if (!ok) return false;
      if (end < bytes.length) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }
    return true;
  }

  Future<void> _printBluetooth(PrinterPreferences prefs, Uint8List bytes) async {
    if (!bluetoothPrintingSupported) {
      throw StateError('此平台不支援藍牙印表機（請改用網路印表機）');
    }

    Future<bool> attempt({required bool forceReconnect}) async {
      await _ensureBluetoothConnected(prefs, forceReconnect: forceReconnect);
      return _sendBluetoothChunks(bytes);
    }

    var ok = await attempt(forceReconnect: false);
    if (!ok) {
      ok = await attempt(forceReconnect: true);
    }
    if (!ok) {
      throw StateError('藍牙印表機傳送失敗（連線狀態異常，請重新配對後再測）');
    }

    // Let the printer drain the buffer. Do NOT disconnect immediately —
    // closing the socket often cuts the end of the receipt.
    final drainMs = (600 + (bytes.length / 50).round()).clamp(600, 3500);
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
    try {
      await PrinterManager.instance.bluetoothPrinterConnector.stopScan();
    } catch (_) {}
  }
}
