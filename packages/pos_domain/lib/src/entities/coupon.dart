enum CouponType { percentage, amount, freeItem }

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.memberId,
    this.minSpend = 0,
    this.expiresAt,
    this.usedAt,
    this.applicableProductIds = const [],
    this.applicableCategoryIds = const [],
  });

  final String id;
  final String code;
  final CouponType type;
  final num value;
  final String? memberId;
  final num minSpend;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final List<String> applicableProductIds;
  final List<String> applicableCategoryIds;

  bool get isUsed => usedAt != null;
  bool isExpired(DateTime now) => expiresAt != null && now.isAfter(expiresAt!);
  bool isValid(DateTime now) => !isUsed && !isExpired(now);
}
