import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import '../order_list_display.dart';

final historyProvider = StreamProvider.autoDispose((ref) {
  final db = ref.read(databaseProvider);
  return (db.select(db.orders)
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
        ..limit(100))
      .watch();
});

sealed class _HistoryListEntry {
  const _HistoryListEntry();
}

class _HistorySectionHeader extends _HistoryListEntry {
  const _HistorySectionHeader(this.group);
  final OrderHistoryDayGroup group;
}

class _HistoryOrderTile extends _HistoryListEntry {
  const _HistoryOrderTile(this.row);
  final OrderRow row;
}

List<_HistoryListEntry> _buildEntries(List<OrderRow> rows) {
  if (rows.isEmpty) return const [];
  final out = <_HistoryListEntry>[];
  OrderHistoryDayGroup? lastGroup;
  for (final o in rows) {
    final g = dayGroupFor(o.createdAt);
    if (g != lastGroup) {
      out.add(_HistorySectionHeader(g));
      lastGroup = g;
    }
    out.add(_HistoryOrderTile(o));
  }
  return out;
}

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('訂單記錄')),
      body: asyncList.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: '尚無訂單');
          }
          final entries = _buildEntries(rows);
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              if (e is _HistorySectionHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dayGroupLabel(e.group),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                );
              }
              final o = (e as _HistoryOrderTile).row;
              final display = OrderListDisplay.fromRow(o);
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: o.syncedAt == null
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        o.syncedAt == null ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
                        size: 18,
                      ),
                    ),
                    title: Text(display.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(display.subtitle),
                        if (display.detail != null)
                          Text(
                            display.detail!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    trailing: MoneyText(Money(o.totalCents)),
                    onTap: () => context.push('/refund/${o.id}'),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('錯誤: $e')),
      ),
    );
  }
}
