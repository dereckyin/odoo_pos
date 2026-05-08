import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/api/dto.dart';
import '../../kds/providers/guest_orders_controller.dart';
import '../providers/cart_controller.dart';

/// Cashier-facing list of QR-scanned table orders. Cashier picks one whose
/// status is ``ready`` (kitchen marked done) and imports it into the cart;
/// they then complete payment using the existing checkout flow.
class TableOrdersPage extends ConsumerStatefulWidget {
  const TableOrdersPage({super.key});

  @override
  ConsumerState<TableOrdersPage> createState() => _TableOrdersPageState();
}

class _TableOrdersPageState extends ConsumerState<TableOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guestOrdersControllerProvider.notifier).startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(guestOrdersControllerProvider);

    final groups = <String, List<GuestOrderDto>>{
      'ready': snapshot.ofStatus('ready'),
      'accepted': snapshot.ofStatus('accepted'),
      'submitted': snapshot.ofStatus('submitted'),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('桌邊訂單'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(guestOrdersControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _StatusChip(status: entry.key),
                  const SizedBox(width: 8),
                  Text('（${entry.value.length} 筆）'),
                ],
              ),
            ),
            if (entry.value.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('（無）'),
              )
            else
              ...entry.value.map((o) => _GuestOrderTile(order: o, onImport: _import)),
          ],
        ],
      ),
    );
  }

  Future<void> _import(GuestOrderDto order) async {
    final cart = ref.read(cartControllerProvider);
    if (cart.lines.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('購物車已有商品'),
          content: const Text('匯入此桌邊訂單將會清空目前購物車，是否繼續？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('清空並匯入')),
          ],
        ),
      );
      if (ok != true) return;
      ref.read(cartControllerProvider.notifier).clear();
    }

    try {
      await ref.read(cartControllerProvider.notifier).importGuestOrder(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('已匯入桌 ${order.tableLabel ?? '?'} 訂單，請進行結帳'),
      ));
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('匯入失敗：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _GuestOrderTile extends StatelessWidget {
  const _GuestOrderTile({required this.order, required this.onImport});
  final GuestOrderDto order;
  final Future<void> Function(GuestOrderDto) onImport;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    final estimated = (order.estimatedSubtotalCents / 100).toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '桌 ${order.tableLabel ?? '?'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                _StatusChip(status: order.status),
                const Spacer(),
                Text(df.format(order.createdAt.toLocal())),
              ],
            ),
            const SizedBox(height: 6),
            Text('估計金額：\$$estimated'),
            const SizedBox(height: 8),
            ...order.lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${l.productName} × ${_fmtQty(l.qty)}')),
                    Text(
                      '\$${(l.lineTotalCents / 100).toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => onImport(order),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('匯入購物車'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtQty(num q) => q == q.toInt() ? q.toInt().toString() : q.toStringAsFixed(2);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'submitted' => ('已送出', Colors.orange),
      'accepted' => ('烹調中', Colors.blue),
      'ready' => ('待結帳', Colors.green),
      'merged' => ('已結帳', Colors.grey),
      'cancelled' => ('已取消', Colors.red),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}
