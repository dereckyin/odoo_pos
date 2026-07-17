import 'dart:convert';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// ESC/POS CJK encoding. Taiwan thermal printers usually need [big5];
/// mainland clones usually need [gbk] (what esc_pos_utils_plus defaults to).
enum EscPosCharset {
  big5,
  gbk,
}

extension EscPosCharsetX on EscPosCharset {
  String get label => switch (this) {
        EscPosCharset.big5 => '繁中 Big5（台灣）',
        EscPosCharset.gbk => '簡中 GBK（中國）',
      };

  /// Platform charset name for [CharsetConverter].
  String get converterName => switch (this) {
        EscPosCharset.big5 => 'Big5',
        EscPosCharset.gbk => 'GBK',
      };

  /// ESC/POS `FS C n` — Kanji character code system (common Chinese clones).
  /// n=0 → GBK/GB2312, n=1 → Big5.
  int get fsCodeSystem => switch (this) {
        EscPosCharset.big5 => 0x01,
        EscPosCharset.gbk => 0x00,
      };
}

/// Active charset for the current receipt build (set via [escBeginJob]).
EscPosCharset escActiveCharset = EscPosCharset.big5;

const _fs = 0x1C;
const _kanjiOn = <int>[_fs, 0x26]; // FS &
const _kanjiOff = <int>[_fs, 0x2E]; // FS .
List<int> _fsCodeSystem(EscPosCharset cs) => <int>[_fs, 0x43, cs.fsCodeSystem];

bool escNeedsChinese(String text) => text.codeUnits.any((c) => c > 255);

/// Call once at the start of each ESC/POS job.
List<int> escBeginJob(EscPosCharset charset) {
  escActiveCharset = charset;
  return <int>[
    ..._fsCodeSystem(charset),
    ..._kanjiOff,
  ];
}

Future<Uint8List> _encodeCjk(String text, EscPosCharset charset) async {
  try {
    return await CharsetConverter.encode(charset.converterName, text);
  } catch (_) {
    // Fallback names some Android/Windows builds expose.
    final alt = charset == EscPosCharset.big5 ? 'x-Windows-950' : 'GB2312';
    try {
      return await CharsetConverter.encode(alt, text);
    } catch (_) {
      // Last resort: keep package GBK path so we still print something.
      return Uint8List.fromList(gbk_bytes.encode(text));
    }
  }
}

List<List<dynamic>> _lexemes(String text) {
  if (text.isEmpty) return [<String>[], <bool>[]];
  final lexemes = <String>[];
  final isChinese = <bool>[];
  var start = 0;
  var end = 0;
  var cur = escNeedsChinese(text[0]);
  for (var i = 1; i < text.length; i++) {
    final next = escNeedsChinese(text[i]);
    if (next == cur) {
      end = i;
    } else {
      lexemes.add(text.substring(start, end + 1));
      isChinese.add(cur);
      start = i;
      end = i;
      cur = next;
    }
  }
  lexemes.add(text.substring(start, end + 1));
  isChinese.add(cur);
  return [lexemes, isChinese];
}

/// Print one line with correct CJK encoding (Big5/GBK) + Kanji mode toggles.
Future<List<int>> escText(
  Generator gen,
  String text, {
  PosStyles styles = const PosStyles(),
  int linesAfter = 0,
  EscPosCharset? charset,
}) async {
  final cs = charset ?? escActiveCharset;
  if (!escNeedsChinese(text)) {
    return gen.text(text, styles: styles, linesAfter: linesAfter);
  }

  final bytes = <int>[];
  final parts = _lexemes(text);
  final lexemes = parts[0] as List<String>;
  final flags = parts[1] as List<bool>;

  // Apply line styles once (alignment/size/bold) with Kanji off first.
  bytes.addAll(gen.setStyles(styles, isKanji: false));

  for (var i = 0; i < lexemes.length; i++) {
    final lex = lexemes[i];
    if (flags[i]) {
      bytes.addAll(_kanjiOn);
      bytes.addAll(gen.setStyles(styles, isKanji: true));
      bytes.addAll(await _encodeCjk(lex, cs));
      bytes.addAll(_kanjiOff);
    } else {
      bytes.addAll(gen.setStyles(styles, isKanji: false));
      bytes.addAll(latin1.encode(lex));
    }
  }

  bytes.addAll(gen.emptyLines(linesAfter + 1));
  return bytes;
}

/// Two-column label/value line (replaces [Generator.row] + GBK [PosColumn]).
Future<List<int>> escRow2(
  Generator gen, {
  required String left,
  required String right,
  int leftWidth = 16,
  int rightWidth = 16,
  PosStyles leftStyles = const PosStyles(),
  PosStyles rightStyles = const PosStyles(align: PosAlign.right),
  EscPosCharset? charset,
}) async {
  // Keep layout simple and encoding-correct: left then right on one line
  // via absolute positioning is fragile with CJK widths; print as "left  right".
  final pad = (leftWidth + rightWidth).clamp(8, 48);
  final gap = ' ';
  // Approximate visual width: CJK ≈ 2 cols.
  int visualLen(String s) {
    var n = 0;
    for (final c in s.runes) {
      n += c > 255 ? 2 : 1;
    }
    return n;
  }

  final leftVis = visualLen(left);
  final rightVis = visualLen(right);
  var spaces = pad - leftVis - rightVis;
  if (spaces < 1) spaces = 1;

  // Prefer right alignment of the value by padding between.
  final line = '$left${gap * spaces}$right';
  // Use left styles for the whole line; bold on left is rare for our receipts.
  final styles = leftStyles.bold || rightStyles.bold
      ? leftStyles.copyWith(bold: leftStyles.bold || rightStyles.bold)
      : leftStyles;
  return escText(gen, line, styles: styles, charset: charset);
}
