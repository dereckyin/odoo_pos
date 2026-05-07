import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pos_domain/pos_domain.dart';
import 'money_text.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
    this.outOfStock = false,
    this.compact = false,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool outOfStock;
  final bool compact;

  static const _placeholderColors = [
    Color(0xFF42A5F5), Color(0xFF66BB6A), Color(0xFFFF7043),
    Color(0xFFAB47BC), Color(0xFFEF5350), Color(0xFF26C6DA),
    Color(0xFFFFA726), Color(0xFF8D6E63), Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildPlaceholder(theme),
                          errorWidget: (_, __, ___) => _buildPlaceholder(theme),
                        )
                      : _buildPlaceholder(theme),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: MoneyText(
                      product.price,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (outOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('缺貨',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.error)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    final initial = product.name.characters.first;
    final color = _placeholderColors[product.name.hashCode % _placeholderColors.length];
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
