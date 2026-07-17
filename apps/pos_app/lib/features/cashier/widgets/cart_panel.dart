import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/roles.dart';
import '../../../data/printer/print_orchestrator.dart';
import '../../../data/printer/printer_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/manager_pin_dialog.dart';
import '../../kds/providers/guest_orders_controller.dart';
import '../providers/cart_controller.dart';
import '../../../data/printer/print_helpers.dart';
import '../../../data/printer/printer_providers.dart';
import '../utils/kitchen_ticket_builder.dart';
import 'option_picker_sheet.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key, required this.onCheckout, required this.onMember});
  final VoidCallback onCheckout;
  final VoidCallback onMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final pendingTableOrders = ref.watch(guestOrdersControllerProvider).ofStatus('submitted').length;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          _MarketplaceOrderBar(),
          _MemberBar(member: cart.member, onTap: onMember, onClear: () => controller.setMember(null)),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? _EmptyCartHint(pendingTableOrders: pendingTableOrders)
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
            child: Column(
              children: [
                if (!cart.isEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final guest = ref.read(importedGuestOrderProvider);
                              await ref.read(printOrchestratorProvider).printCartConfirmation(
                                    cart,
                                    tableLabel: guest?.displayTitle,
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('列印失敗：$e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('印確認單'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final guest = ref.read(importedGuestOrderProvider);
                              await ref.read(printOrchestratorProvider).reprintCartLabels(
                                    cart,
                                    tableLabel: guest?.displayTitle,
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.label_outline),
                          label: const Text('補印標籤'),
                        ),
                      ),
                    ],
                  ),
                if (!cart.isEmpty) const SizedBox(height: 8),
                BigButton(
                  icon: Icons.point_of_sale,
                  label: '結帳 ${cart.total.format()}',
                  onPressed: cart.isEmpty ? null : onCheckout,
                  minHeight: 72,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceOrderBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MarketplaceOrderBar> createState() => _MarketplaceOrderBarState();
}

class _MarketplaceOrderBarState extends ConsumerState<_MarketplaceOrderBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final guest = ref.watch(importedGuestOrderProvider);
    if (guest == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMarketplace = guest.isMarketplace;

    return Material(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isMarketplace ? Icons.storefront_outlined : Icons.table_restaurant_outlined,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.guestOrderSource(guest.displayTitle),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (isMarketplace && guest.paymentLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (guest.isOnlinePaid ? Colors.green : Colors.orange).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      guest.paymentLabel,
                      style: TextStyle(
                        color: guest.isOnlinePaid ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (isMarketplace) ...[
              const SizedBox(height: 6),
              if ((guest.customerName ?? '').isNotEmpty || (guest.customerPhone ?? '').isNotEmpty)
                Text(
                  '${guest.customerName ?? ''} ${guest.customerPhone ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Row(
                children: [
                  Chip(
                    label: Text(guest.fulfillmentLabel),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (guest.isDelivery && guest.isDelivered)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Chip(
                        label: Text('已送達'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              if (guest.isDelivery && (guest.deliveryAddress ?? '').isNotEmpty)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          guest.deliveryAddress!,
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                    ],
                  ),
                ),
              if (_expanded && (guest.deliveryNote ?? '').isNotEmpty)
                Text(
                  '外送備註：${guest.deliveryNote}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(printOrchestratorProvider).printGuestConfirmation(guest);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已列印確認單')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('列印失敗：$e'), backgroundColor: scheme.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('確認單'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(printOrchestratorProvider).reprintGuestLabels(guest);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已補印標籤')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e'), backgroundColor: scheme.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.label_outline, size: 18),
                    label: const Text('標籤'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(kitchenPrinterServiceProvider).printTicket(
                              kitchenTicketFromGuestOrder(guest),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.reprintKitchenTicket)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('列印失敗：$e'),
                              backgroundColor: scheme.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(l10n.reprintKitchenTicket),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartHint extends StatelessWidget {
  const _EmptyCartHint({required this.pendingTableOrders});
  final int pendingTableOrders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.cartEmptyTitle,
              subtitle: l10n.cartEmptySubtitle,
            ),
            if (pendingTableOrders > 0) ...[
              const SizedBox(height: 16),
              Text(
                '有 $pendingTableOrders 筆桌邊訂單待接單',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '請點右上角桌邊訂單圖示',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.product.bookAuthor != null && line.product.bookAuthor!.isNotEmpty)
            Text(
              line.product.bookAuthor!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          if (line.product.isConsignmentBook)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in const [
                      (label: '7折', pctOff: 30),
                      (label: '4折', pctOff: 60),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(preset.label),
                          onPressed: () => controller.setLineDiscount(
                            line.id,
                            Discount(
                              type: DiscountType.percentage,
                              value: preset.pctOff,
                              label: preset.label,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (line.selectedOptions.isNotEmpty)
            Text(
              line.selectedOptions.displayLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          if (line.note != null && line.note!.isNotEmpty)
            Text(
              line.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Row(
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
      onTap: line.product.hasOptions
          ? () async {
              final options = await OptionPickerSheet.show(
                context,
                product: line.product,
                initialSelections: line.selectedOptions,
              );
              if (options != null) {
                await controller.updateLineOptions(line.id, options);
              }
            }
          : null,
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
    if (picked == 'remove') {
      controller.removeLine(line.id);
      return;
    }
    if (picked == 'pct10' || picked == 'amount10') {
      final session = ref.read(authStateProvider).session;
      // Discounts by a cashier require a store manager's PIN authorisation.
      if (session != null && !isStoreAdminRole(session.role)) {
        if (!context.mounted) return;
        final approval = await requestManagerApproval(
          context,
          ref,
          action: 'discount',
          title: '折扣需店長授權',
        );
        if (approval == null) return;
      }
      if (picked == 'pct10') {
        controller.setLineDiscount(line.id, const Discount(type: DiscountType.percentage, value: 10, label: '9 折'));
      } else {
        controller.setLineDiscount(line.id, const Discount(type: DiscountType.amount, value: 10, label: '折 10'));
      }
    }
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
