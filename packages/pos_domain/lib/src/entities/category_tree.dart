import 'category.dart';

/// Builds hierarchy helpers from a flat category list synced from the server.
class CategoryTree {
  CategoryTree(this.categories) {
    _byId = {for (final c in categories) c.id: c};
    _children = {};
    for (final c in categories) {
      _children.putIfAbsent(c.parentId, () => []).add(c);
    }
    for (final list in _children.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
  }

  final List<Category> categories;
  late final Map<String, Category> _byId;
  late final Map<String?, List<Category>> _children;

  List<Category> get roots => _children[null] ?? const [];

  Category? get(String id) => _byId[id];

  List<Category> childrenOf(String? parentId) => _children[parentId] ?? const [];

  bool hasChildren(String id) => (_children[id]?.isNotEmpty ?? false);

  /// All category ids in subtree including [categoryId] itself.
  Set<String> descendantIds(String categoryId) {
    final out = <String>{categoryId};
    void walk(String cid) {
      for (final c in _children[cid] ?? const []) {
        out.add(c.id);
        walk(c.id);
      }
    }
    walk(categoryId);
    return out;
  }

  /// Expand a set of selected category ids to include all descendants.
  Set<String> expandWithDescendants(Iterable<String> categoryIds) {
    final out = <String>{};
    for (final id in categoryIds) {
      out.addAll(descendantIds(id));
    }
    return out;
  }

  List<Category> pathTo(String categoryId) {
    final path = <Category>[];
    var cur = _byId[categoryId];
    while (cur != null) {
      path.insert(0, cur);
      cur = cur.parentId == null ? null : _byId[cur.parentId];
    }
    return path;
  }

  String pathLabelFor(String categoryId) =>
      pathTo(categoryId).map((c) => c.name).join(' / ');

  /// True if [categoryId] or any ancestor has hideFromPosBrowse.
  bool isHiddenByAncestor(String? categoryId) {
    var cur = categoryId == null ? null : _byId[categoryId];
    while (cur != null) {
      if (cur.hideFromPosBrowse) return true;
      cur = cur.parentId == null ? null : _byId[cur.parentId];
    }
    return false;
  }

  /// True unless [categoryId] or any ancestor disables member discount.
  bool memberDiscountAllowedForCategory(String? categoryId) =>
      _chainAllows(categoryId, (c) => c.memberDiscountEligible);

  /// True unless [categoryId] or any ancestor disables points earning.
  bool pointsEarnAllowedForCategory(String? categoryId) =>
      _chainAllows(categoryId, (c) => c.pointsEarnEligible);

  /// True unless [categoryId] or any ancestor disables points redemption.
  bool pointsRedeemAllowedForCategory(String? categoryId) =>
      _chainAllows(categoryId, (c) => c.pointsRedeemEligible);

  bool _chainAllows(String? categoryId, bool Function(Category) flag) {
    var cur = categoryId == null ? null : _byId[categoryId];
    while (cur != null) {
      if (!flag(cur)) return false;
      cur = cur.parentId == null ? null : _byId[cur.parentId];
    }
    return true;
  }

  /// True if [categoryId] or any ancestor has hideFromPublicOrdering.
  bool isHiddenFromPublicByAncestor(String? categoryId) {
    var cur = categoryId == null ? null : _byId[categoryId];
    while (cur != null) {
      if (cur.hideFromPublicOrdering) return true;
      cur = cur.parentId == null ? null : _byId[cur.parentId];
    }
    return false;
  }

  static CategoryTree fromFlat(List<Category> flat) => CategoryTree(flat);
}

/// Enrich flat categories with computed depth and path labels.
List<Category> enrichCategories(List<Category> flat) {
  final tree = CategoryTree(flat);
  return flat
      .map((c) {
        final path = tree.pathTo(c.id);
        return Category(
          id: c.id,
          name: c.name,
          parentId: c.parentId,
          sortOrder: c.sortOrder,
          color: c.color,
          icon: c.icon,
          hideFromPublicOrdering: c.hideFromPublicOrdering,
          hideFromPosBrowse: c.hideFromPosBrowse,
          memberDiscountEligible: c.memberDiscountEligible,
          pointsEarnEligible: c.pointsEarnEligible,
          pointsRedeemEligible: c.pointsRedeemEligible,
          depth: path.length - 1,
          pathLabel: path.map((p) => p.name).join(' / '),
          hasChildren: tree.hasChildren(c.id),
        );
      })
      .toList(growable: false);
}
