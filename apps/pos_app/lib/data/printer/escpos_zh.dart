import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// True when [text] has any non-Latin-1 code unit (CJK, emoji, etc.).
bool escNeedsChinese(String text) => text.codeUnits.any((c) => c > 255);

/// Wrapper around [Generator.text] that auto-enables GBK/Kanji for CJK text.
///
/// Without `containsChinese: true`, esc_pos_utils encodes with Latin-1 and
/// throws: `Invalid argument(s): string: Contains invalid characters.`
List<int> escText(
  Generator gen,
  String text, {
  PosStyles styles = const PosStyles(),
  int linesAfter = 0,
}) {
  return gen.text(
    text,
    styles: styles,
    linesAfter: linesAfter,
    containsChinese: escNeedsChinese(text),
  );
}

/// [PosColumn] that auto-sets [PosColumn.containsChinese] for CJK text.
PosColumn escCol(
  String text, {
  required int width,
  PosStyles styles = const PosStyles(),
}) {
  return PosColumn(
    text: text,
    width: width,
    styles: styles,
    containsChinese: escNeedsChinese(text),
  );
}
