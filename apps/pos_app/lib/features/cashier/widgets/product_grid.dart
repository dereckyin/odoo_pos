import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:pos_ui_kit/pos_ui_kit.dart';

import '../../products/providers/product_providers.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key, required this.query, required this.categoryId, required this.onTap});
  final String query;
  final String? categoryId;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts =
        ref.watch(productListProvider((query: query, categoryId: categoryId)));
    return asyncProducts.when(
      data: (products) {
        if (products.isEmpty) {
          return const EmptyState(
              icon: Icons.search_off, title: '找不到商品', subtitle: '請改變關鍵字或選擇其他分類');
        }
        return LayoutBuilder(builder: (context, c) {
          final cross = (c.maxWidth / 200).clamp(2, 6).toInt();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              childAspectRatio: 0.85,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(product: products[i], onTap: () => onTap(products[i])),
          );
        });
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('讀取失敗: $e')),
    );
  }
}
