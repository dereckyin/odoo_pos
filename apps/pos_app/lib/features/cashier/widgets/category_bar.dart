import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../products/providers/product_providers.dart';

/// Horizontal category navigator with breadcrumb drill-down (up to 3 levels).
class CategoryBar extends ConsumerStatefulWidget {
  const CategoryBar({super.key, required this.selectedId, required this.onSelected});
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  ConsumerState<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends ConsumerState<CategoryBar> {
  /// Drill-down path from root to current parent (exclusive of pending chip tap).
  List<String> _path = const [];

  @override
  void didUpdateWidget(CategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId == null && oldWidget.selectedId != null) {
      _path = const [];
    }
  }

  void _selectAll() {
    setState(() => _path = const []);
    widget.onSelected(null);
  }

  void _selectCategory(Category c, CategoryTree tree) {
    setState(() {
      _path = tree.pathTo(c.id).map((x) => x.id).toList();
    });
    widget.onSelected(c.id);
  }

  void _breadcrumbTo(int index) {
    final tree = ref.read(categoryTreeProvider);
    if (index < 0) {
      _selectAll();
      return;
    }
    final id = _path[index];
    final cat = tree.get(id);
    if (cat != null) _selectCategory(cat, tree);
  }

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoriesProvider);
    return asyncCats.when(
      data: (cats) {
        final tree = CategoryTree(cats);
        final parentId = _path.isEmpty ? null : _path.last;
        final chips = (_path.isEmpty ? tree.roots : tree.childrenOf(parentId))
            .where((c) => _path.isEmpty ? !c.hideFromPosBrowse : true)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _BreadcrumbChip(
                    label: '全部',
                    selected: widget.selectedId == null,
                    onTap: _selectAll,
                  ),
                  for (var i = 0; i < _path.length; i++) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right, size: 18),
                    ),
                    _BreadcrumbChip(
                      label: tree.get(_path[i])?.name ?? '',
                      selected: widget.selectedId == _path[i],
                      onTap: () => _breadcrumbTo(i),
                    ),
                  ],
                ],
              ),
            ),
            if (chips.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = chips[i];
                    final selected = widget.selectedId == c.id;
                    return ChoiceChip(
                      label: Text(c.name),
                      selected: selected,
                      onSelected: (_) => _selectCategory(c, tree),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    );
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: SizedBox(height: 4, width: 120, child: LinearProgressIndicator())),
      ),
      error: (e, _) => SizedBox(height: 56, child: Center(child: Text('讀取分類失敗: $e'))),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      onPressed: onTap,
      backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : null,
    );
  }
}
