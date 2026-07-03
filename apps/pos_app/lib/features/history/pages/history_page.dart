import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/roles.dart';
import '../../../core/user_facing_error.dart';
import '../../../data/database/app_database.dart';
import '../../auth/widgets/manager_pin_dialog.dart';
import '../order_list_display.dart';
import '../../../data/printer/printer_providers.dart';
import 'package:pos_domain/pos_domain.dart';

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
                    onLongPress: () => _showOrderActions(context, ref, o),
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

  Future<void> _showOrderActions(BuildContext context, WidgetRef ref, OrderRow o) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('補印收據'),
            onTap: () => Navigator.pop(context, 'receipt'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('補印發票證明聯'),
            onTap: () => Navigator.pop(context, 'invoice'),
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('退款'),
            onTap: () => Navigator.pop(context, 'refund'),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('作廢整筆訂單'),
            onTap: () => Navigator.pop(context, 'void'),
          ),
        ]),
      ),
    );
    if (action == 'refund') {
      if (context.mounted) context.push('/refund/${o.id}');
    } else if (action == 'receipt') {
      await _reprintReceipt(context, ref, o);
    } else if (action == 'invoice') {
      await _reprintInvoice(context, ref, o);
    } else if (action == 'void') {
      await _voidOrder(context, ref, o);
    }
  }

  Future<void> _voidOrder(BuildContext context, WidgetRef ref, OrderRow o) async {
    final session = ref.read(authStateProvider).session;
    final reasonCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('作廢訂單'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('作廢將整筆訂單回補庫存與點數。'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtl,
              decoration: const InputDecoration(labelText: '作廢原因（選填）'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('確認')),
        ],
      ),
    );
    if (confirmed != true) return;

    // Cashiers need a store manager's PIN to void.
    if (session != null && !isStoreAdminRole(session.role)) {
      if (!context.mounted) return;
      final approval = await requestManagerApproval(
        context,
        ref,
        action: 'void',
        title: '作廢需店長授權',
      );
      if (approval == null) return;
    }

    try {
      await ref.read(posApiProvider).createVoidRequest(o.id, reason: reasonCtl.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          session != null && isStoreAdminRole(session.role) ? '訂單已作廢' : '作廢申請已送出',
        )),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatUserFacingError(e, scene: UserErrorScene.general))),
      );
    }
  }

  Future<void> _reprintReceipt(BuildContext context, WidgetRef ref, OrderRow o) async {
    try {
      final db = ref.read(databaseProvider);
      final lines = await (db.select(db.orderLines)..where((t) => t.orderId.equals(o.id))).get();
      final payments = await (db.select(db.payments)..where((t) => t.orderId.equals(o.id))).get();
      final order = Order(
        id: o.id,
        storeId: o.storeId,
        terminalId: o.terminalId,
        cashierId: o.cashierId,
        memberId: o.memberId,
        status: OrderStatus.paid,
        lines: lines
            .map(
              (l) => OrderLine(
                id: l.id,
                productId: l.productId,
                productName: l.productName,
                sku: l.sku,
                qty: l.qty,
                unitPrice: Money(l.unitPriceCents),
                lineDiscount: Money(l.lineDiscountCents),
                lineTotal: Money(l.lineTotalCents),
                taxRate: l.taxRate,
                note: l.note,
              ),
            )
            .toList(),
        payments: payments
            .map(
              (p) => Payment(
                id: p.id,
                method: PaymentMethod.values.firstWhere((m) => m.code == p.method),
                amount: Money(p.amountCents),
                status: PaymentStatus.captured,
                createdAt: p.createdAt,
              ),
            )
            .toList(),
        subtotal: Money(o.subtotalCents),
        discount: Money(o.discountCents),
        tax: Money(o.taxCents),
        total: Money(o.totalCents),
        createdAt: o.createdAt,
      );
      await ref.read(printerServiceProvider).printReceipt(
            order,
            tableLabel: o.tableLabel,
            orderNo: o.orderNo,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已補印收據')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('補印失敗：$e')));
      }
    }
  }

  Future<void> _reprintInvoice(BuildContext context, WidgetRef ref, OrderRow o) async {
    try {
      final db = ref.read(databaseProvider);
      final inv = await (db.select(db.invoices)..where((t) => t.orderId.equals(o.id))).getSingleOrNull();
      if (inv == null || inv.invoiceNumber == null) {
        throw StateError('此訂單尚無已開立發票');
      }
      await ref.read(printerServiceProvider).printInvoiceProof(
            storeName: '點餐趣',
            invoiceNumber: inv.invoiceNumber!,
            invoiceDate: inv.invoiceDate ?? inv.createdAt,
            randomCode: inv.randomCode ?? '0000',
            total: Money(inv.totalCents),
            buyerTaxId: inv.taxId,
            barcode: inv.barcode,
            qrLeft: inv.qrLeft,
            qrRight: inv.qrRight,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已補印發票證明聯')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('補印失敗：$e')));
      }
    }
  }
}
