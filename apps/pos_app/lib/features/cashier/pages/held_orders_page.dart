import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/cart_controller.dart';
import '../providers/held_cart_repository.dart';
import '../widgets/order_detail_conflict_dialog.dart';

class HeldOrdersPage extends ConsumerWidget {
  const HeldOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final held = ref.watch(heldCartSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.heldOrdersTitle)),
      body: held.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.heldOrdersEmpty));
          }
          final df = DateFormat('MM/dd HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final h = items[i];
              return Card(
                child: ListTile(
                  title: Text(h.label),
                  subtitle: Text(
                    '${df.format(h.createdAt)} · ${h.lineCount} 品項 · \$${(h.totalCents / 100).toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _delete(context, ref, h.id),
                        child: Text(l10n.deleteHeld),
                      ),
                      FilledButton(
                        onPressed: () => _restore(context, ref, h.id),
                        child: Text(l10n.restoreHeld),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(cartControllerProvider.notifier).deleteHeld(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已刪除掛單')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.read(cartControllerProvider);
    if (!cart.isEmpty) {
      final action = await showOrderDetailConflictDialog(
        context,
        title: l10n.orderDetailHasItems,
        message: '還原掛單將取代目前點單明細，是否繼續？',
        parkLabel: '取消',
        replaceLabel: l10n.restoreHeld,
        showParkOption: false,
      );
      if (action != OrderDetailConflictAction.replace) return;
      ref.read(cartControllerProvider.notifier).clear();
    }

    try {
      final skipped = await ref.read(cartControllerProvider.notifier).restoreHeld(id);
      if (!context.mounted) return;
      context.pop();
      if (skipped.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('部分商品已下架，已略過 ${skipped.length} 項')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }
}
