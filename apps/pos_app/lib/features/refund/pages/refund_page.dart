import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/roles.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables.dart';
import '../../../data/sync/sync_models.dart';
import '../../../data/sync/sync_providers.dart';
import '../../auth/widgets/manager_pin_dialog.dart';
import '../../history/order_list_display.dart';

class RefundPage extends ConsumerStatefulWidget {
  const RefundPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends ConsumerState<RefundPage> {
  final Map<String, num> _refundQty = {}; // orderLineId -> qty to refund
  final _reasonCtl = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final db = ref.read(databaseProvider);
    final order = ref.watch(_orderProvider(widget.orderId));
    final lines = ref.watch(_orderLinesProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('退款')),
      body: order.when(
        data: (o) {
          if (o == null) return const EmptyState(title: '找不到此訂單', icon: Icons.error_outline);
          final display = OrderListDisplay.fromRow(o);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(display.title, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(display.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                          if (display.detail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              display.detail!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    MoneyText(Money(o.totalCents),
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: lines.when(
                    data: (rows) => ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final ln = rows[i];
                        final picked = _refundQty[ln.id] ?? 0;
                        return ListTile(
                          title: Text(ln.productName),
                          subtitle: Text('原數量 ${ln.qty.toStringAsFixed(0)}・單價 ${Money(ln.unitPriceCents).format()}'),
                          trailing: QuantityStepper(
                            value: picked,
                            min: 0,
                            max: ln.qty.toInt(),
                            onChanged: (v) => setState(() => _refundQty[ln.id] = v),
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('錯誤: $e')),
                  ),
                ),
                TextField(
                  controller: _reasonCtl,
                  decoration: const InputDecoration(labelText: '退款原因 (選填)'),
                ),
                const SizedBox(height: 12),
                BigButton(
                  icon: Icons.undo,
                  label: _busy ? '處理中…' : '送出退款',
                  onPressed: _busy ? null : () => _doRefund(db, o),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('錯誤: $e')),
      ),
    );
  }

  Future<void> _doRefund(AppDatabase db, OrderRow o) async {
    final selected = _refundQty.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請選擇要退的商品數量')));
      return;
    }
    final session = ref.read(authStateProvider).session;
    // Cashiers (門市人員) need a store manager to authorise refunds.
    if (session != null && !isStoreAdminRole(session.role)) {
      final approval = await requestManagerApproval(
        context,
        ref,
        action: 'refund',
        title: '退貨需店長授權',
      );
      if (approval == null) return;
    }
    setState(() => _busy = true);
    final now = DateTime.now();
    final refundId = newUuid();
    final lineRows = await (db.select(db.orderLines)..where((t) => t.orderId.equals(o.id))).get();
    final byId = {for (final l in lineRows) l.id: l};
    int totalCents = 0;
    final apiLines = <Map<String, dynamic>>[];
    for (final entry in selected) {
      final orig = byId[entry.key]!;
      final qty = entry.value;
      final unitPrice = orig.unitPriceCents;
      final amount = (unitPrice * qty).toInt();
      totalCents += amount;
      apiLines.add({
        'order_line_id': orig.id,
        'qty': qty,
        'amount_cents': amount,
      });
    }

    await db.transaction(() async {
      await db.into(db.refunds).insert(RefundsCompanion.insert(
            id: refundId,
            orderId: o.id,
            userId: session?.userId ?? 'unknown',
            method: 'cash',
            totalAmountCents: totalCents,
            createdAt: now,
            reason: d.Value(_reasonCtl.text.trim()),
          ));
      for (final entry in selected) {
        await db.into(db.refundLines).insert(RefundLinesCompanion.insert(
              id: newUuid(),
              refundId: refundId,
              orderLineId: entry.key,
              qty: entry.value.toDouble(),
              amountCents: (byId[entry.key]!.unitPriceCents * entry.value).toInt(),
            ));
        // Reverse movement
        final orig = byId[entry.key]!;
        await db.into(db.inventoryMovements).insert(InventoryMovementsCompanion.insert(
              id: newUuid(),
              storeId: o.storeId,
              productId: orig.productId,
              qtyDelta: entry.value.toDouble(),
              reason: 'refund',
              refType: const d.Value('refund'),
              refId: d.Value(refundId),
              terminalId: d.Value(o.terminalId),
              userId: d.Value(session?.userId),
              createdAt: now,
            ));
      }
      await (db.update(db.orders)..where((t) => t.id.equals(o.id))).write(OrdersCompanion(
        refundedCents: d.Value(o.refundedCents + totalCents),
        status: d.Value(o.refundedCents + totalCents >= o.totalCents ? 'refunded' : 'partiallyRefunded'),
      ));
      await ref.read(syncQueueDaoProvider).enqueue(SyncOpKind.uploadRefund, {
        'id': refundId,
        'order_id': o.id,
        'user_id': session?.userId,
        'method': 'cash',
        'reason': _reasonCtl.text.trim(),
        'lines': apiLines,
      });
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('退款 ${Money(totalCents).format()} 已建立')),
    );
    setState(() => _busy = false);
    context.pop();
  }
}

final _orderProvider =
    StreamProvider.autoDispose.family<OrderRow?, String>((ref, id) {
  final db = ref.read(databaseProvider);
  return (db.select(db.orders)..where((t) => t.id.equals(id))).watchSingleOrNull();
});

final _orderLinesProvider =
    StreamProvider.autoDispose.family<List<OrderLineRow>, String>((ref, id) {
  final db = ref.read(databaseProvider);
  return (db.select(db.orderLines)..where((t) => t.orderId.equals(id))).watch();
});
