import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Android classic Bluetooth SPP one-shot print (connect → write → close).
class ClassicBluetoothPrinter {
  ClassicBluetoothPrinter._();

  static const MethodChannel _channel =
      MethodChannel('com.example.pos_app/classic_bt_printer');

  static bool get isSupported => Platform.isAndroid;

  /// Prints raw ESC/POS/TSPL bytes to a bonded classic Bluetooth printer.
  static Future<void> printRaw({
    required String address,
    required Uint8List bytes,
  }) async {
    if (!isSupported) {
      throw StateError('僅 Android 支援經典藍牙直送');
    }
    try {
      await _channel.invokeMethod<bool>('printRaw', <String, dynamic>{
        'address': address,
        'bytes': bytes,
      });
    } on PlatformException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }
}
