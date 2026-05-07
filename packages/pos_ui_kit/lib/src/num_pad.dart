import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Touch-friendly number pad with +/-, decimal, clear and submit actions.
class NumPad extends StatelessWidget {
  const NumPad({
    super.key,
    required this.onKey,
    this.onSubmit,
    this.onClear,
    this.allowDecimal = false,
    this.submitLabel = '確認',
    this.compact = false,
  });

  /// Called with the character pressed: '0'..'9', '.', 'BACK'
  final ValueChanged<String> onKey;
  final VoidCallback? onSubmit;
  final VoidCallback? onClear;
  final bool allowDecimal;
  final String submitLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cellHeight = compact ? 48.0 : 64.0;

    Widget cell(String label, {VoidCallback? onTap, IconData? icon, Color? bg, Color? fg}) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: cellHeight,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
            child: icon != null
                ? Icon(icon, size: 24)
                : Text(label, style: theme.textTheme.titleLarge),
          ),
        ),
      );
    }

    final rows = <List<Widget>>[
      [for (final n in ['7', '8', '9']) cell(n, onTap: () => onKey(n))],
      [for (final n in ['4', '5', '6']) cell(n, onTap: () => onKey(n))],
      [for (final n in ['1', '2', '3']) cell(n, onTap: () => onKey(n))],
      [
        cell(allowDecimal ? '.' : 'C',
            onTap: allowDecimal ? () => onKey('.') : (onClear ?? () => onKey('C'))),
        cell('0', onTap: () => onKey('0')),
        cell('', icon: Icons.backspace_outlined, onTap: () => onKey('BACK')),
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(children: [for (final w in row) Expanded(child: w)]),
        if (onSubmit != null)
          Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: double.infinity,
              height: cellHeight,
              child: FilledButton(
                onPressed: onSubmit,
                child: Text(submitLabel),
              ),
            ),
          ),
      ],
    );
  }
}

/// Helper to apply a key event to a string buffer.
class NumPadBuffer {
  NumPadBuffer({this.allowDecimal = false, this.maxLength = 12});
  final bool allowDecimal;
  final int maxLength;
  String _value = '';
  String get value => _value.isEmpty ? '0' : _value;
  num get asNum => num.tryParse(value) ?? 0;

  void apply(String key) {
    switch (key) {
      case 'BACK':
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      case 'C':
        _value = '';
      case '.':
        if (allowDecimal && !_value.contains('.')) {
          _value = _value.isEmpty ? '0.' : '$_value.';
        }
      default:
        if (_value.length < maxLength) _value += key;
    }
  }

  void reset() => _value = '';
  void set(String v) => _value = v;
}
