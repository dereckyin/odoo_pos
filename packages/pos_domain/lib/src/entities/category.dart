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
    this.memberDiscountEligible = true,
    this.pointsEarnEligible = true,
    this.pointsRedeemEligible = true,
    this.depth = 0,
    this.pathLabel = '',
    this.hasChildren = false,
  });

  final String id;
  final String name;
  final String? parentId;
  final int sortOrder;
  final String? color;
  final String? icon;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
  final bool memberDiscountEligible;
  final bool pointsEarnEligible;
  final bool pointsRedeemEligible;
  final int depth;
  final String pathLabel;
  final bool hasChildren;
}
