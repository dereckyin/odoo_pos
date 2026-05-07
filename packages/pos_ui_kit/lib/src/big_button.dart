import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.foreground,
    this.minHeight = 64,
    this.expanded = true,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foreground;
  final double minHeight;
  final bool expanded;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final btn = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color ?? scheme.primary,
        foregroundColor: foreground ?? scheme.onPrimary,
        minimumSize: Size.fromHeight(minHeight),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
    final wrapped = expanded ? SizedBox(width: double.infinity, child: btn) : btn;
    return tooltip != null ? Tooltip(message: tooltip!, child: wrapped) : wrapped;
  }
}
