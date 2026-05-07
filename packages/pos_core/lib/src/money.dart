import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Money value object stored as integer cents (TWD has no decimals, but we
/// keep the abstraction in cents for future locales).
class Money implements Comparable<Money> {
  const Money(this.cents, {this.currency = 'TWD'});

  factory Money.zero({String currency = 'TWD'}) => Money(0, currency: currency);

  factory Money.fromMajor(num amount, {String currency = 'TWD'}) =>
      Money((Decimal.parse(amount.toString()) * Decimal.fromInt(_minorUnits(currency))).toBigInt().toInt(), currency: currency);

  factory Money.fromDecimal(Decimal amount, {String currency = 'TWD'}) =>
      Money((amount * Decimal.fromInt(_minorUnits(currency))).toBigInt().toInt(), currency: currency);

  final int cents;
  final String currency;

  static int _minorUnits(String currency) => switch (currency) {
        'JPY' || 'TWD' => 1,
        _ => 100,
      };

  int get minorUnits => _minorUnits(currency);

  Decimal get major => (Decimal.fromInt(cents) / Decimal.fromInt(minorUnits)).toDecimal(scaleOnInfinitePrecision: 4);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(cents - other.cents, currency: currency);
  }

  Money operator *(num factor) =>
      Money((Decimal.fromInt(cents) * Decimal.parse(factor.toString())).round().toBigInt().toInt(), currency: currency);

  Money operator /(num divisor) =>
      Money((Decimal.fromInt(cents) / Decimal.parse(divisor.toString())).toDecimal(scaleOnInfinitePrecision: 0).round().toBigInt().toInt(), currency: currency);

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return cents < other.cents;
  }

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return cents > other.cents;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return cents <= other.cents;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return cents >= other.cents;
  }

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;
  Money get abs => Money(cents.abs(), currency: currency);
  Money get negate => Money(-cents, currency: currency);

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
  }

  String format({String locale = 'zh_TW', bool withSymbol = true}) {
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: withSymbol ? _symbol(currency) : '',
      decimalDigits: minorUnits == 1 ? 0 : 2,
    );
    return fmt.format(major.toDouble());
  }

  static String _symbol(String currency) => switch (currency) {
        'TWD' => 'NT\$',
        'USD' => '\$',
        'JPY' => '¥',
        _ => '$currency ',
      };

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return cents.compareTo(other.cents);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money && other.cents == cents && other.currency == currency);

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => '${major.toString()} $currency';

  Map<String, dynamic> toJson() => {'cents': cents, 'currency': currency};

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money((json['cents'] as num).toInt(), currency: json['currency'] as String? ?? 'TWD');
}
