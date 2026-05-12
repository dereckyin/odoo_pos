import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../providers/promotion_providers.dart';
import '../../sync/widgets/master_data_sync_button.dart';

class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(activePromotionsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('行銷活動'),
        actions: const [MasterDataSyncButton()],
      ),
      body: asyncList.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.campaign_outlined, title: '尚無進行中的活動');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(p.name),
                  subtitle: Text(_describe(p)),
                  trailing: p.startsAt == null
                      ? null
                      : Text('${_d(p.startsAt!)}\n→ ${p.endsAt == null ? '∞' : _d(p.endsAt!)}',
                          textAlign: TextAlign.right, style: Theme.of(context).textTheme.labelSmall),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('錯誤: $e')),
      ),
    );
  }

  static String _d(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _describe(Promotion p) {
    switch (p.strategy) {
      case PromotionStrategy.thresholdAmountOff:
        return '滿 ${p.config['threshold_amount']} 折 ${p.config['off_amount']}';
      case PromotionStrategy.thresholdPercentOff:
        return '滿 ${p.config['threshold_amount']} 折 ${p.config['off_pct']}%';
      case PromotionStrategy.nthItemDiscount:
        return '第 ${p.config['nth']} 件 ${p.config['nth_discount_pct']}% off';
      case PromotionStrategy.buyXGetY:
        return '買 ${p.config['buy_n']} 送 ${p.config['get_n']}';
      case PromotionStrategy.bundlePrice:
        return '組合價: ${p.config['bundle_price']}';
      case PromotionStrategy.memberLevelDiscount:
        return '會員等級折扣';
      case PromotionStrategy.manualDiscount:
        return '手動折扣';
    }
  }
}
