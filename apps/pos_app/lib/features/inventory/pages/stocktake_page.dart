import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../../core/providers.dart';
import '../../../core/user_facing_error.dart';
import '../providers/inventory_providers.dart';

/// Scan/keyboard stocktake (盤點). Counts are sent to the server which records
/// a stocktake and posts the difference as an inventory adjustment.
class StocktakePage extends ConsumerStatefulWidget {
  const StocktakePage({super.key});

  @override
  ConsumerState<StocktakePage> createState() => _StocktakePageState();
}

class _StocktakePageState extends ConsumerState<StocktakePage> {
  final Map<String, double> _counts = {}; // productId -> actual qty
  final _filter = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).session;
    final storeId = session?.storeId;
    final asyncList = storeId == null
        ? const AsyncValue.data(<InventoryRow>[])
        : ref.watch(inventoryListProvider(storeId));
    return Scaffold(
      appBar: AppBar(title: const Text('盤點')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || storeId == null ? null : () => _submit(storeId),
        icon: const Icon(Icons.save),
        label: Text(_busy ? '送出中…' : '送出盤點 (${_counts.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _filter,
              decoration: const InputDecoration(
                labelText: '搜尋商品名稱 / SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: asyncList.when(
              data: (list) {
                final q = _filter.text.trim().toLowerCase();
                final shown = q.isEmpty
                    ? list
                    : list
                        .where((e) =>
                            e.productName.toLowerCase().contains(q) ||
                            e.sku.toLowerCase().contains(q))
                        .toList();
                if (shown.isEmpty) {
                  return const EmptyState(icon: Icons.fact_check_outlined, title: '尚無庫存資料');
                }
                return ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = shown[i];
                    final counted = _counts[r.productId];
                    final diff = counted == null ? null : counted - r.onHand;
                    return ListTile(
                      title: Text(r.productName),
                      subtitle: Text('SKU: ${r.sku}・系統 ${r.onHand.toStringAsFixed(0)}'
                          '${diff != null && diff != 0 ? '・差異 ${diff > 0 ? '+' : ''}${diff.toStringAsFixed(0)}' : ''}'),
                      trailing: SizedBox(
                        width: 110,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: '實際'),
                          onChanged: (v) {
                            final parsed = double.tryParse(v);
                            setState(() {
                              if (parsed == null) {
                                _counts.remove(r.productId);
                              } else {
                                _counts[r.productId] = parsed;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('錯誤: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String storeId) async {
    if (_counts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請至少輸入一筆實際盤點數量')),
      );
      return;
    }
    final list = ref.read(inventoryListProvider(storeId)).value ?? const [];
    final expectedById = {for (final r in list) r.productId: r.onHand};
    setState(() => _busy = true);
    try {
      await ref.read(posApiProvider).createStocktake({
        'id': newUuid(),
        'store_id': storeId,
        'lines': _counts.entries
            .map((e) => {
                  'id': newUuid(),
                  'product_id': e.key,
                  'expected_qty': expectedById[e.key] ?? 0,
                  'actual_qty': e.value,
                })
            .toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('盤點已送出，差異已調整庫存')),
      );
      setState(() => _counts.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatUserFacingError(e, scene: UserErrorScene.general))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
