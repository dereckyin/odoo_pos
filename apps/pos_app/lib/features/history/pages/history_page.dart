import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';

final historyProvider = StreamProvider.autoDispose((ref) {
  final db = ref.read(databaseProvider);
  return (db.select(db.orders)
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
        ..limit(100))
      .watch();
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('MM/dd HH:mm');
    final asyncList = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('訂單記錄')),
      body: asyncList.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: '尚無訂單');
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = rows[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: o.syncedAt == null
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    o.syncedAt == null ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
                    size: 18,
                  ),
                ),
                title: Text('訂單 ${o.id.substring(0, 8)}'),
                subtitle: Text('${df.format(o.createdAt)}・${o.status}'),
                trailing: MoneyText(Money(o.totalCents)),
                onTap: () => context.push('/refund/${o.id}'),
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
