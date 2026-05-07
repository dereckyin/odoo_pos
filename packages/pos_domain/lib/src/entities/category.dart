class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.color,
    this.icon,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final String? color;
  final String? icon;
}
