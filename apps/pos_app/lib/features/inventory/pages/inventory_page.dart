import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../providers/inventory_providers.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  bool _onlyLow = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).session;
    final storeId = session?.storeId;
    final asyncList =
        storeId == null ? const AsyncValue.data(<InventoryRow>[]) : ref.watch(inventoryListProvider(storeId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('庫存'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: FilterChip(
              label: const Text('僅顯示安全庫存以下'),
              selected: _onlyLow,
              onSelected: (v) => setState(() => _onlyLow = v),
            ),
          ),
        ],
      ),
      body: asyncList.when(
        data: (list) {
          final shown = _onlyLow ? list.where((e) => e.belowSafety).toList() : list;
          if (shown.isEmpty) {
            return const EmptyState(icon: Icons.warehouse_outlined, title: '尚無庫存資料');
          }
          return ListView.separated(
            itemCount: shown.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = shown[i];
              return ListTile(
                title: Text(r.productName),
                subtitle: Text('SKU: ${r.sku}'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${r.onHand.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: r.belowSafety ? Theme.of(context).colorScheme.error : null,
                        )),
                    Text('安全 ${r.safetyStock.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
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
}
