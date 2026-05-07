import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../providers/product_providers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _q = '';
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final asyncProducts =
        ref.watch(productSearchProvider((query: _q, categoryId: _cat)));
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('商品')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜尋名稱 / SKU / 條碼',
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          cats.maybeWhen(
            data: (list) => SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return ChoiceChip(
                      label: const Text('全部'),
                      selected: _cat == null,
                      onSelected: (_) => setState(() => _cat = null),
                    );
                  }
                  final c = list[i - 1];
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: _cat == c.id,
                    onSelected: (_) => setState(() => _cat = c.id),
                  );
                },
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncProducts.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.inventory_2_outlined, title: '尚無商品');
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: Text('SKU: ${p.sku}・條碼: ${p.barcodes.join(", ")}'),
                      trailing: MoneyText(p.price,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary)),
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
}
