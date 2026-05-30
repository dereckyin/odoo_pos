import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/api/dto.dart';

class GuestOrderCard extends StatelessWidget {
  const GuestOrderCard({
    super.key,
    required this.order,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final GuestOrderDto order;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  order.displayTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (order.isMarketplace && order.paymentLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _PaymentChip(label: order.paymentLabel, paid: order.isOnlinePaid),
                ],
                const Spacer(),
                if (order.partySize != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('${order.partySize}人'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Text(
                  df.format(order.createdAt.toLocal()),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            if (order.isMarketplace && (order.customerPhone ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${order.customerName ?? ''} ${order.customerPhone!}'.trim(),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
            if (order.isDelivery && (order.deliveryAddress ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                order.deliveryAddress!,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
            if (order.isDelivery && (order.deliveryNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '外送備註：${order.deliveryNote}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            ...order.lines.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '×${_fmtQty(l.qty)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((l.note ?? '').isNotEmpty)
                            Text(
                              '· ${l.note}',
                              style: TextStyle(color: scheme.error, fontSize: 13),
                            ),
                          if (l.optionsJson.isNotEmpty)
                            Text(
                              l.optionsJson.map((j) => j['choice_name']).join(' · '),
                              style: TextStyle(color: scheme.primary, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if ((order.customerNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: scheme.error, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.customerNote!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (primaryLabel != null || secondaryLabel != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (secondaryLabel != null && onSecondary != null) ...[
                    OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
                    const SizedBox(width: 8),
                  ],
                  if (primaryLabel != null && onPrimary != null)
                    FilledButton(onPressed: onPrimary, child: Text(primaryLabel!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtQty(num q) {
    if (q == q.toInt()) return q.toInt().toString();
    return q.toStringAsFixed(2);
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label, required this.paid});
  final String label;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final color = paid ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
