class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.color,
    this.icon,
    this.hideFromPublicOrdering = false,
    this.hideFromPosBrowse = false,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final String? color;
  final String? icon;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
}
