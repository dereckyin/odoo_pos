import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.step = 1,
    this.allowDecimal = false,
  });

  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num? max;
  final num step;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn(IconData icon, VoidCallback? onPressed) => SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filledTonal(
            onPressed: onPressed,
            icon: Icon(icon),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        );

    final canDecrement = value > min;
    final canIncrement = max == null || value < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, canDecrement ? () => onChanged((value - step).clamp(min, max ?? double.infinity)) : null),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          child: Text(
            allowDecimal ? value.toStringAsFixed(2) : value.toInt().toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        btn(Icons.add, canIncrement ? () => onChanged(value + step) : null),
      ],
    );
  }
}
