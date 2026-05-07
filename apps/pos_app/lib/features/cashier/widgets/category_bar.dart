import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/providers/product_providers.dart';

class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key, required this.selectedId, required this.onSelected});
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(categoriesProvider);
    return SizedBox(
      height: 56,
      child: asyncCats.when(
        data: (cats) {
          final all = [const _Cat(id: null, name: '全部')];
          all.addAll(cats.map((c) => _Cat(id: c.id, name: c.name)));
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = all[i];
              final selected = c.id == selectedId;
              return ChoiceChip(
                label: Text(c.name),
                selected: selected,
                onSelected: (_) => onSelected(c.id),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          );
        },
        loading: () => const Center(child: SizedBox(height: 4, child: LinearProgressIndicator())),
        error: (e, _) => Text('讀取分類失敗: $e'),
      ),
    );
  }
}

class _Cat {
  const _Cat({required this.id, required this.name});
  final String? id;
  final String name;
}
