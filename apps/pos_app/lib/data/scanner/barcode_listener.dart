import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Desktop USB-HID barcode scanners present themselves as keyboards. They
/// type the code very quickly and end with Enter. We listen for that pattern
/// and emit a single string event.
class BarcodeKeyboardListener extends StatefulWidget {
  const BarcodeKeyboardListener({
    super.key,
    required this.child,
    required this.onBarcode,
    this.minLength = 4,
    this.maxInterCharMs = 80,
    this.terminator = LogicalKeyboardKey.enter,
  });

  final Widget child;
  final ValueChanged<String> onBarcode;
  final int minLength;

  /// Max delay between two characters of a barcode burst (ms).
  /// Real scanners stay well under 30ms, humans take 100ms+.
  final int maxInterCharMs;
  final LogicalKeyboardKey terminator;

  @override
  State<BarcodeKeyboardListener> createState() => _BarcodeKeyboardListenerState();
}

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  final _focus = FocusNode(skipTraversal: true, canRequestFocus: true);
  final _buffer = StringBuffer();
  DateTime _lastTs = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final now = DateTime.now();
    final delta = now.difference(_lastTs).inMilliseconds;
    _lastTs = now;

    if (delta > widget.maxInterCharMs * 5 && _buffer.isNotEmpty) {
      _buffer.clear();
    }

    if (event.logicalKey == widget.terminator) {
      final code = _buffer.toString().trim();
      _buffer.clear();
      if (code.length >= widget.minLength) {
        widget.onBarcode(code);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final c = event.character;
    if (c == null || c.isEmpty) return KeyEventResult.ignored;
    final code = c.codeUnitAt(0);
    if (code < 0x20 || code > 0x7E) return KeyEventResult.ignored;
    _buffer.write(c);
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
