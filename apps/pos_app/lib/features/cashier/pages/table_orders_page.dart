import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/api/dto.dart';
import '../../../l10n/app_localizations.dart';
import '../../kds/providers/guest_orders_controller.dart';
import '../providers/cart_controller.dart';
import '../widgets/order_detail_conflict_dialog.dart';

/// Cashier-facing list of QR-scanned table orders (one-person workflow).
///
/// Primary path: ``submitted`` → **接單出餐並帶入** (print + accept + ready +
/// import to order detail). Fallback: ``accepted`` / ``ready`` → **帶入點單明細**.
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
    final l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(guestOrdersControllerProvider);

    final pending = snapshot.ofStatus('submitted');
    final checkoutPending = [
      ...snapshot.ofStatus('accepted'),
      ...snapshot.ofStatus('ready'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('桌邊 / 網路訂單'),
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
          _SectionHeader(label: '待接單', count: pending.length),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('（無）'),
            )
          else
            ...pending.map(
              (o) => _GuestOrderTile(
                order: o,
                fulfillLabel: l10n.fulfillAndImport,
                onFulfillAndImport: _fulfillAndImport,
              ),
            ),
          _SectionHeader(label: '待結帳', count: checkoutPending.length),
          if (checkoutPending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('（無）'),
            )
          else
            ...checkoutPending.map(
              (o) => _GuestOrderTile(
                order: o,
                fulfillLabel: l10n.importToOrderDetail,
                onImport: _importToOrderDetail,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _resolveCartConflict() async {
    final cart = ref.read(cartControllerProvider);
    if (cart.lines.isEmpty) return true;

    final l10n = AppLocalizations.of(context)!;
    final action = await showOrderDetailConflictDialog(
      context,
      title: l10n.orderDetailHasItems,
      message: l10n.importGuestOrderReplaceMessage,
      parkLabel: l10n.parkAndImport,
      replaceLabel: l10n.replaceAndImport,
    );
    switch (action) {
      case OrderDetailConflictAction.parkAndContinue:
        try {
          await ref.read(cartControllerProvider.notifier).park();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
          return false;
        }
        return true;
      case OrderDetailConflictAction.replace:
        ref.read(cartControllerProvider.notifier).clear();
        return true;
      case OrderDetailConflictAction.cancel:
      case null:
        return false;
    }
  }

  Future<bool> _importToCart(GuestOrderDto order) async {
    if (!await _resolveCartConflict()) return false;
    await ref.read(cartControllerProvider.notifier).importGuestOrder(order);
    return true;
  }

  void _goToCashierWithSnack(GuestOrderDto order) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final table = order.displayTitle;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.importedToOrderDetail(table))),
    );
  }

  Future<void> _fulfillAndImport(GuestOrderDto order) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ready = await ref.read(guestOrdersControllerProvider.notifier).acceptAndReady(order);
      if (!await _importToCart(ready)) return;
      _goToCashierWithSnack(ready);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.fulfillFailed}：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _importToOrderDetail(GuestOrderDto order) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      var target = order;
      if (order.status == 'accepted') {
        target = await ref.read(guestOrdersControllerProvider.notifier).markReady(order);
      }
      if (!await _importToCart(target)) return;
      _goToCashierWithSnack(target);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.importOrderDetailFailed}：$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Text('（$count 筆）'),
        ],
      ),
    );
  }
}

class _GuestOrderTile extends StatelessWidget {
  const _GuestOrderTile({
    required this.order,
    required this.fulfillLabel,
    this.onFulfillAndImport,
    this.onImport,
  });
  final GuestOrderDto order;
  final String fulfillLabel;
  final Future<void> Function(GuestOrderDto)? onFulfillAndImport;
  final Future<void> Function(GuestOrderDto)? onImport;

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
                  order.displayTitle,
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
                if (order.status == 'submitted' && onFulfillAndImport != null)
                  FilledButton.icon(
                    onPressed: () => onFulfillAndImport!(order),
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(fulfillLabel),
                  )
                else if (onImport != null)
                  FilledButton.icon(
                    onPressed: () => onImport!(order),
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(fulfillLabel),
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
