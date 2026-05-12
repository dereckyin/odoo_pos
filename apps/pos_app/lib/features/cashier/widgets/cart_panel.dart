import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../providers/cart_controller.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, required this.onCheckout, required this.onMember});
  final VoidCallback onCheckout;
  final VoidCallback onMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _MemberBar(member: cart.member, onTap: onMember, onClear: () => controller.setMember(null)),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(icon: Icons.shopping_cart_outlined, title: '購物車是空的', subtitle: '點選左側商品加入購物車')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final line = cart.lines[i];
                      return Dismissible(
                        key: ValueKey(line.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete_outline, color: scheme.onError),
                        ),
                        onDismissed: (_) => controller.removeLine(line.id),
                        child: _CartLineTile(line: line),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          _Totals(cart: cart),
          Padding(
            padding: const EdgeInsets.all(16),
            child: BigButton(
              icon: Icons.point_of_sale,
              label: '結帳 ${cart.total.format()}',
              onPressed: cart.isEmpty ? null : onCheckout,
              minHeight: 72,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBar extends StatelessWidget {
  const _MemberBar({this.member, required this.onTap, required this.onClear});
  final Member? member;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.person_outline),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                member == null
                    ? '點擊綁定會員（手機 / QR）'
                    : '${member!.name}・${member!.phone}・${member!.points}點${member!.level == null ? '' : '・${member!.level!.name}'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          if (member != null)
            IconButton(icon: const Icon(Icons.close), onPressed: onClear),
        ],
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);
    return ListTile(
      title: Text(line.product.name),
      subtitle: Row(
        children: [
          MoneyText(line.unitPrice, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          QuantityStepper(
            value: line.qty,
            onChanged: (v) {
              if (v <= 0) {
                controller.removeLine(line.id);
              } else {
                controller.updateQty(line.id, v);
              }
            },
            min: 0,
            allowDecimal: line.product.isWeighted,
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MoneyText(line.net,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (!line.discountAmount.isZero)
            Text('-${line.discountAmount.format()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      onLongPress: () => _showLineMenu(context, ref, line),
    );
  }

  void _showLineMenu(BuildContext context, WidgetRef ref, CartLine line) async {
    final controller = ref.read(cartControllerProvider.notifier);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.percent), title: const Text('單行 9 折'), onTap: () => Navigator.pop(context, 'pct10')),
          ListTile(leading: const Icon(Icons.discount_outlined), title: const Text('單行折 10 元'), onTap: () => Navigator.pop(context, 'amount10')),
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('刪除此商品'), onTap: () => Navigator.pop(context, 'remove')),
        ]),
      ),
    );
    if (picked == 'pct10') controller.setLineDiscount(line.id, const Discount(type: DiscountType.percentage, value: 10, label: '9 折'));
    if (picked == 'amount10') controller.setLineDiscount(line.id, const Discount(type: DiscountType.amount, value: 10, label: '折 10'));
    if (picked == 'remove') controller.removeLine(line.id);
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.cart});
  final dynamic cart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(context, '小計', cart.subtotal),
          if (!cart.orderLevelDiscountAmount.isZero) _row(context, '優惠/折扣', cart.orderLevelDiscountAmount.negate),
          _row(context, '稅(內含)', cart.tax),
          const Divider(),
          _row(context, '應付', cart.total, big: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext c, String k, dynamic v, {bool big = false}) {
    final theme = Theme.of(c).textTheme;
    final style = big ? theme.titleLarge?.copyWith(fontWeight: FontWeight.w700) : theme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(k, style: style)),
          MoneyText(v, style: style),
        ],
      ),
    );
  }
}
