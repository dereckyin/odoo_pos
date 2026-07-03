import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'escpos_service.dart';

/// Label layout for drink cup stickers (40×30 mm default).
class DrinkLabel {
  DrinkLabel({
    required this.productName,
    required this.tableLabel,
    required this.orderRef,
    required this.placedAt,
    required this.cupIndex,
    required this.cupTotal,
    this.optionsLabel = '',
    this.note,
  });

  final String productName;
  final String tableLabel;
  final String orderRef;
  final DateTime placedAt;
  final int cupIndex;
  final int cupTotal;
  final String optionsLabel;
  final String? note;
}

/// Builds TSPL commands with rasterised Chinese text (BITMAP) for TSC/Godex
/// label printers over TCP port 9100.
class TsplLabelBuilder {
  TsplLabelBuilder({
    this.labelWidthMm = 40,
    this.labelHeightMm = 30,
    this.gapMm = 2,
    this.dpi = 203,
  });

  final int labelWidthMm;
  final int labelHeightMm;
  final double gapMm;
  final int dpi;

  int get _widthDots => (labelWidthMm * dpi / 25.4).round();
  int get _heightDots => (labelHeightMm * dpi / 25.4).round();

  Future<Uint8List> build(DrinkLabel label) async {
    final lines = <String>[
      label.productName,
      if (label.optionsLabel.isNotEmpty) label.optionsLabel,
      if (label.note != null && label.note!.isNotEmpty) '備註 ${label.note}',
      '桌 ${label.tableLabel}  #${label.orderRef}',
      '${label.cupIndex}/${label.cupTotal}  ${_hhmm(label.placedAt)}',
    ];
    final bitmap = await _renderLines(lines);
    final widthBytes = (bitmap.width + 7) ~/ 8;
    final sb = StringBuffer()
      ..writeln('SIZE ${labelWidthMm} mm, ${labelHeightMm} mm')
      ..writeln('GAP ${gapMm} mm, 0 mm')
      ..writeln('DIRECTION 1')
      ..writeln('CLS')
      ..writeln('BITMAP 0,0,$widthBytes,${bitmap.height},0,');
    final header = sb.toString();
    final out = Uint8List(header.length + bitmap.bytes.length + 16);
    out.setAll(0, header.codeUnits);
    out.setAll(header.length, bitmap.bytes);
    final tail = '\r\nPRINT 1,1\r\n';
    out.setAll(header.length + bitmap.bytes.length, tail.codeUnits);
    return out;
  }

  String _hhmm(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  Future<_MonoBitmap> _renderLines(List<String> lines) async {
    final width = _widthDots;
    final height = _heightDots;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = Colors.white);

    var y = 4.0;
    final lineHeight = (height / (lines.length + 0.5)).clamp(14.0, 28.0);
    for (var i = 0; i < lines.length; i++) {
      final isTitle = i == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: TextStyle(
            color: Colors.black,
            fontSize: isTitle ? lineHeight * 0.85 : lineHeight * 0.7,
            fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: width - 8.0);
      tp.paint(canvas, Offset(4, y));
      y += lineHeight;
      if (y >= height - 4) break;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (rgba == null) throw StateError('failed to rasterise label');
    return _rgbaToMono(rgba.buffer.asUint8List(), width, height);
  }

  _MonoBitmap _rgbaToMono(Uint8List rgba, int width, int height) {
    final widthBytes = (width + 7) ~/ 8;
    final out = Uint8List(widthBytes * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final lum = (rgba[i] + rgba[i + 1] + rgba[i + 2]) / 3;
        if (lum < 200) {
          final byteIndex = y * widthBytes + x ~/ 8;
          out[byteIndex] |= 0x80 >> (x % 8);
        }
      }
    }
    return _MonoBitmap(width: width, height: height, bytes: out);
  }
}

class _MonoBitmap {
  _MonoBitmap({required this.width, required this.height, required this.bytes});
  final int width;
  final int height;
  final Uint8List bytes;
}

class TsplPrinterDriver {
  TsplPrinterDriver({TcpPrinterDriver? tcp}) : _tcp = tcp ?? TcpPrinterDriver();
  final TcpPrinterDriver _tcp;

  Future<void> printRaw(String host, Uint8List bytes, {int port = 9100}) =>
      _tcp.printRaw(host, bytes, port: port);
}
