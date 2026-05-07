import 'package:pos_core/pos_core.dart';

enum PromotionStrategy {
  /// 第 N 件折扣 (eg. 第二件 8 折)
  nthItemDiscount,
  /// 滿額折 (eg. 滿 1000 折 100)
  thresholdAmountOff,
  /// 滿額折% (eg. 滿 2000 打 9 折)
  thresholdPercentOff,
  /// 買 X 送 Y
  buyXGetY,
  /// 組合價 (multiple specific products at fixed price)
  bundlePrice,
  /// 會員等級折扣 (隱式)
  memberLevelDiscount,
  /// 整單百分比 / 金額折扣 (manual)
  manualDiscount,
}

class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.strategy,
    required this.config,
    this.priority = 0,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.stackable = false,
    this.applicableProductIds = const [],
    this.applicableCategoryIds = const [],
    this.memberLevelIds = const [],
  });

  final String id;
  final String name;
  final PromotionStrategy strategy;

  /// Free-form config (the engine reads required keys per [strategy]).
  final Map<String, dynamic> config;

  /// Higher priority promos are evaluated first.
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;

  /// Whether this promotion can be applied alongside others on the same line.
  final bool stackable;

  final List<String> applicableProductIds;
  final List<String> applicableCategoryIds;
  final List<String> memberLevelIds;

  bool isAvailableAt(DateTime t) {
    if (!isActive) return false;
    if (startsAt != null && t.isBefore(startsAt!)) return false;
    if (endsAt != null && t.isAfter(endsAt!)) return false;
    return true;
  }
}

/// A concrete promotion already applied to one or more cart lines.
class AppliedPromotion {
  const AppliedPromotion({
    required this.promotionId,
    required this.label,
    required this.discountAmount,
    this.appliesToLineIds = const [],
    this.metadata,
  });

  final String promotionId;
  final String label;
  final Money discountAmount;
  final List<String> appliesToLineIds;
  final Map<String, dynamic>? metadata;
}
