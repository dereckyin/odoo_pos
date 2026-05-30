import 'package:pos_core/pos_core.dart';
import 'product.dart';
import 'member.dart';
import 'promotion.dart';
import 'option.dart';

enum DiscountType { none, percentage, amount }

class Discount {
  const Discount({
    required this.type,
    required this.value,
    this.label,
    this.promotionId,
  });

  factory Discount.none() => const Discount(type: DiscountType.none, value: 0);

  final DiscountType type;
  /// percentage: 0..100, amount: 元 (主貨幣單位)
  final num value;
  final String? label;
  final String? promotionId;

  bool get isNone => type == DiscountType.none || value == 0;

  /// Apply the discount to a base [Money]. Returns the *amount to deduct*.
  Money compute(Money base) {
    switch (type) {
      case DiscountType.none:
        return Money.zero(currency: base.currency);
      case DiscountType.percentage:
        return base * (value / 100);
      case DiscountType.amount:
        return Money.fromMajor(value, currency: base.currency);
    }
  }
}

class CartLine {
  CartLine({
    required this.id,
    required this.product,
    required this.qty,
    Discount? lineDiscount,
    this.appliedPromotions = const [],
    this.note,
    List<SelectedOption>? selectedOptions,
    Money? unitPrice,
  })  : selectedOptions = List.unmodifiable(selectedOptions ?? const []),
        lineDiscount = lineDiscount ?? Discount.none(),
        unitPrice = unitPrice ??
            (product.price + Money(selectedOptions?.totalPriceDeltaCents ?? 0));

  /// Constructor that allows custom unit price (eg. price overrides on weighted goods)
  CartLine.custom({
    required this.id,
    required this.product,
    required this.qty,
    required this.unitPrice,
    Discount? lineDiscount,
    this.appliedPromotions = const [],
    this.note,
    List<SelectedOption>? selectedOptions,
  })  : selectedOptions = List.unmodifiable(selectedOptions ?? const []),
        lineDiscount = lineDiscount ?? Discount.none();

  final String id;
  final Product product;
  final num qty;
  final Money unitPrice;
  final Discount lineDiscount;
  final List<AppliedPromotion> appliedPromotions;
  final String? note;
  final List<SelectedOption> selectedOptions;

  String get mergeKey => '${product.id}|${selectedOptions.optionsSignature}';

  Money get gross => unitPrice * qty;
  Money get discountAmount {
    var total = lineDiscount.compute(gross);
    for (final p in appliedPromotions) {
      total = total + p.discountAmount;
    }
    return total;
  }

  Money get net => gross - discountAmount;

  CartLine copyWith({
    num? qty,
    Discount? lineDiscount,
    List<AppliedPromotion>? appliedPromotions,
    Money? unitPrice,
    String? note,
    List<SelectedOption>? selectedOptions,
  }) =>
      CartLine.custom(
        id: id,
        product: product,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        lineDiscount: lineDiscount ?? this.lineDiscount,
        appliedPromotions: appliedPromotions ?? this.appliedPromotions,
        note: note ?? this.note,
        selectedOptions: selectedOptions ?? this.selectedOptions,
      );
}

class Cart {
  Cart({
    String? id,
    List<CartLine>? lines,
    this.member,
    Discount? orderDiscount,
    this.appliedPromotions = const [],
    this.note,
  })  : id = id ?? newUuid(),
        lines = List.unmodifiable(lines ?? const []),
        orderDiscount = orderDiscount ?? Discount.none();

  final String id;
  final List<CartLine> lines;
  final Member? member;
  final Discount orderDiscount;
  final List<AppliedPromotion> appliedPromotions;
  final String? note;

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.fold(0, (sum, l) => sum + (l.qty is int ? l.qty as int : l.qty.ceil()));

  Money get subtotal {
    if (lines.isEmpty) return Money.zero();
    return lines.map((l) => l.net).reduce((a, b) => a + b);
  }

  Money get orderLevelDiscountAmount {
    var total = orderDiscount.compute(subtotal);
    for (final p in appliedPromotions) {
      total = total + p.discountAmount;
    }
    return total;
  }

  /// Taxable amount after discounts. Shelf prices are treated as tax-inclusive.
  Money get _taxableInclusive => subtotal - orderLevelDiscountAmount;

  Money get tax {
    if (lines.isEmpty) return Money.zero();
    final inclusive = _taxableInclusive;
    if (inclusive.isZero || inclusive.isNegative) return Money.zero();
    final rate = lines.first.product.taxRate;
    return inclusive * rate / (1 + rate);
  }

  Money get total => _taxableInclusive;

  Cart copyWith({
    List<CartLine>? lines,
    Member? member,
    Object? memberSentinel = _kSentinel,
    Discount? orderDiscount,
    List<AppliedPromotion>? appliedPromotions,
    String? note,
  }) =>
      Cart(
        id: id,
        lines: lines ?? this.lines,
        member: identical(memberSentinel, _kSentinel) ? (member ?? this.member) : member,
        orderDiscount: orderDiscount ?? this.orderDiscount,
        appliedPromotions: appliedPromotions ?? this.appliedPromotions,
        note: note ?? this.note,
      );
}

const _kSentinel = Object();
