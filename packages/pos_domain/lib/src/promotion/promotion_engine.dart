import 'package:pos_core/pos_core.dart';

import '../entities/cart.dart';
import '../entities/promotion.dart';
import '../entities/member.dart';
import '../entities/category_tree.dart';
import 'promotion_rule.dart';

class PromotionEvaluation {
  const PromotionEvaluation({required this.cart, required this.applied});
  final Cart cart;
  final List<AppliedPromotion> applied;

  Money get totalDiscount => applied.isEmpty
      ? Money.zero()
      : applied.map((e) => e.discountAmount).reduce((a, b) => a + b);
}

/// Pure-Dart promotion engine. Evaluates a set of [Promotion]s against a [Cart]
/// and returns a new cart with `appliedPromotions` populated.
///
/// Rules:
///  - Promotions are sorted by priority desc.
///  - For each promotion, check `applicableProductIds`/`categoryIds`/member level.
///  - Apply each strategy independently; results accumulate unless conflicting.
///  - The engine is *deterministic* given (cart, promotions, now).
class PromotionEngine {
  const PromotionEngine({this.clock = const SystemClock()});
  final Clock clock;

  PromotionEvaluation evaluate({
    required Cart cart,
    required List<Promotion> promotions,
    CategoryTree? categoryTree,
  }) {
    final now = clock.now();
    final active = promotions.where((p) => p.isAvailableAt(now)).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    var workingCart = cart.copyWith(
      lines: cart.lines.map((l) => l.copyWith(appliedPromotions: const [])).toList(),
      appliedPromotions: const [],
    );

    final allApplied = <AppliedPromotion>[];
    for (final promo in active) {
      final result = _applyOne(promo, workingCart, categoryTree);
      if (result == null) continue;
      workingCart = result.cart;
      allApplied.addAll(result.applied);
    }

    // Member-level auto discount (implicit: walks cart subtotal once).
    final memberPromo = _evaluateMemberLevel(workingCart);
    if (memberPromo != null) {
      workingCart = workingCart.copyWith(
        appliedPromotions: [...workingCart.appliedPromotions, memberPromo],
      );
      allApplied.add(memberPromo);
    }

    return PromotionEvaluation(cart: workingCart, applied: allApplied);
  }

  _Step? _applyOne(Promotion p, Cart cart, CategoryTree? categoryTree) {
    switch (p.strategy) {
      case PromotionStrategy.thresholdAmountOff:
        return _applyThresholdAmountOff(p, cart, categoryTree);
      case PromotionStrategy.thresholdPercentOff:
        return _applyThresholdPercentOff(p, cart, categoryTree);
      case PromotionStrategy.nthItemDiscount:
        return _applyNthItemDiscount(p, cart, categoryTree);
      case PromotionStrategy.buyXGetY:
        return _applyBuyXGetY(p, cart, categoryTree);
      case PromotionStrategy.bundlePrice:
        return _applyBundlePrice(p, cart, categoryTree);
      case PromotionStrategy.memberLevelDiscount:
      case PromotionStrategy.manualDiscount:
        return null; // handled out of band
    }
  }

  bool _matchesScope(Promotion p, CartLine line, CategoryTree? categoryTree) {
    if (p.applicableProductIds.isEmpty && p.applicableCategoryIds.isEmpty) {
      return true;
    }
    if (p.applicableProductIds.contains(line.product.id)) return true;
    if (line.product.categoryId != null && p.applicableCategoryIds.isNotEmpty) {
      if (p.applicableCategoryIds.contains(line.product.categoryId)) return true;
      if (categoryTree != null) {
        for (final cid in p.applicableCategoryIds) {
          if (categoryTree.descendantIds(cid).contains(line.product.categoryId)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _memberLevelOk(Promotion p, Member? member) {
    if (p.memberLevelIds.isEmpty) return true;
    final levelId = member?.level?.id;
    return levelId != null && p.memberLevelIds.contains(levelId);
  }

  // ---- strategies ----

  _Step? _applyThresholdAmountOff(Promotion p, Cart cart, CategoryTree? categoryTree) {
    if (!_memberLevelOk(p, cart.member)) return null;
    final threshold = (p.config[PromotionConfigKeys.thresholdAmount] as num).toDouble();
    final off = (p.config[PromotionConfigKeys.offAmount] as num).toDouble();
    final subtotalMajor = cart.subtotal.major.toDouble();
    if (subtotalMajor < threshold) return null;
    final discount = Money.fromMajor(off, currency: cart.subtotal.currency);
    final applied = AppliedPromotion(
      promotionId: p.id,
      label: p.name,
      discountAmount: discount,
    );
    return _Step(
      cart: cart.copyWith(appliedPromotions: [...cart.appliedPromotions, applied]),
      applied: [applied],
    );
  }

  _Step? _applyThresholdPercentOff(Promotion p, Cart cart, CategoryTree? categoryTree) {
    if (!_memberLevelOk(p, cart.member)) return null;
    final threshold = (p.config[PromotionConfigKeys.thresholdAmount] as num).toDouble();
    final pct = (p.config[PromotionConfigKeys.offPct] as num).toDouble();
    final subtotalMajor = cart.subtotal.major.toDouble();
    if (subtotalMajor < threshold) return null;
    final discount = cart.subtotal * (pct / 100);
    final applied = AppliedPromotion(
      promotionId: p.id,
      label: p.name,
      discountAmount: discount,
    );
    return _Step(
      cart: cart.copyWith(appliedPromotions: [...cart.appliedPromotions, applied]),
      applied: [applied],
    );
  }

  _Step? _applyNthItemDiscount(Promotion p, Cart cart, CategoryTree? categoryTree) {
    if (!_memberLevelOk(p, cart.member)) return null;
    final nth = (p.config[PromotionConfigKeys.nth] as num).toInt();
    final pct = (p.config[PromotionConfigKeys.nthDiscountPct] as num).toDouble();
    if (nth < 2) return null;

    final newLines = <CartLine>[];
    final allApplied = <AppliedPromotion>[];

    for (final line in cart.lines) {
      if (!_matchesScope(p, line, categoryTree)) {
        newLines.add(line);
        continue;
      }
      // For each set of `nth` units, the nth-th gets pct off.
      final qtyInt = line.qty.toInt();
      final discountedCount = qtyInt ~/ nth;
      if (discountedCount == 0) {
        newLines.add(line);
        continue;
      }
      final discountPerUnit = line.unitPrice * (pct / 100);
      final lineDiscount = discountPerUnit * discountedCount;
      final applied = AppliedPromotion(
        promotionId: p.id,
        label: p.name,
        discountAmount: lineDiscount,
        appliesToLineIds: [line.id],
      );
      newLines.add(line.copyWith(
        appliedPromotions: [...line.appliedPromotions, applied],
      ));
      allApplied.add(applied);
    }

    if (allApplied.isEmpty) return null;
    return _Step(cart: cart.copyWith(lines: newLines), applied: allApplied);
  }

  _Step? _applyBuyXGetY(Promotion p, Cart cart, CategoryTree? categoryTree) {
    if (!_memberLevelOk(p, cart.member)) return null;
    final buyN = (p.config[PromotionConfigKeys.buyN] as num).toInt();
    final getN = (p.config[PromotionConfigKeys.getN] as num).toInt();
    final getDiscountPct =
        ((p.config[PromotionConfigKeys.getDiscountPct] ?? 100) as num).toDouble();
    if (buyN <= 0 || getN <= 0) return null;

    final newLines = <CartLine>[];
    final allApplied = <AppliedPromotion>[];
    final groupSize = buyN + getN;

    for (final line in cart.lines) {
      if (!_matchesScope(p, line, categoryTree)) {
        newLines.add(line);
        continue;
      }
      final qtyInt = line.qty.toInt();
      final groups = qtyInt ~/ groupSize;
      if (groups == 0) {
        newLines.add(line);
        continue;
      }
      final freeUnits = groups * getN;
      final discount = line.unitPrice * freeUnits * (getDiscountPct / 100);
      final applied = AppliedPromotion(
        promotionId: p.id,
        label: p.name,
        discountAmount: discount,
        appliesToLineIds: [line.id],
        metadata: {'groups': groups, 'freeUnits': freeUnits},
      );
      newLines.add(line.copyWith(appliedPromotions: [...line.appliedPromotions, applied]));
      allApplied.add(applied);
    }

    if (allApplied.isEmpty) return null;
    return _Step(cart: cart.copyWith(lines: newLines), applied: allApplied);
  }

  _Step? _applyBundlePrice(Promotion p, Cart cart, CategoryTree? categoryTree) {
    if (!_memberLevelOk(p, cart.member)) return null;
    final ids = (p.config[PromotionConfigKeys.bundleProductIds] as List?)?.cast<String>() ?? [];
    final bundlePriceMajor = (p.config[PromotionConfigKeys.bundlePrice] as num?)?.toDouble();
    if (ids.isEmpty || bundlePriceMajor == null) return null;

    final byProduct = <String, CartLine>{
      for (final l in cart.lines) l.product.id: l,
    };
    if (!ids.every(byProduct.containsKey)) return null;

    // Number of full bundles available across the listed products
    final perProductQty = ids.map((id) => byProduct[id]!.qty.toInt()).toList();
    final bundles = perProductQty.reduce((a, b) => a < b ? a : b);
    if (bundles == 0) return null;

    final originalPerBundle = ids
        .map((id) => byProduct[id]!.unitPrice)
        .reduce((a, b) => a + b);
    final bundlePrice = Money.fromMajor(bundlePriceMajor, currency: originalPerBundle.currency);
    final perBundleDiscount = originalPerBundle - bundlePrice;
    if (!perBundleDiscount.isPositive) return null;
    final totalDiscount = perBundleDiscount * bundles;

    final applied = AppliedPromotion(
      promotionId: p.id,
      label: p.name,
      discountAmount: totalDiscount,
      appliesToLineIds: ids.map((id) => byProduct[id]!.id).toList(),
      metadata: {'bundles': bundles},
    );
    return _Step(
      cart: cart.copyWith(appliedPromotions: [...cart.appliedPromotions, applied]),
      applied: [applied],
    );
  }

  AppliedPromotion? _evaluateMemberLevel(Cart cart) {
    final level = cart.member?.level;
    if (level == null) return null;
    if (level.discountRate >= 1.0) return null;
    final off = 1.0 - level.discountRate;
    final discount = (cart.subtotal - cart.orderLevelDiscountAmount) * off;
    if (!discount.isPositive) return null;
    return AppliedPromotion(
      promotionId: 'member_level:${level.id}',
      label: '${level.name}會員 ${(level.discountRate * 100).toStringAsFixed(0)}折',
      discountAmount: discount,
    );
  }
}

class _Step {
  _Step({required this.cart, required this.applied});
  final Cart cart;
  final List<AppliedPromotion> applied;
}
