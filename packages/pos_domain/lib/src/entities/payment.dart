import 'package:pos_core/pos_core.dart';

enum PaymentMethod { cash, creditCard, linePay, voucher, points, other }

extension PaymentMethodX on PaymentMethod {
  String get code => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.creditCard => 'credit_card',
        PaymentMethod.linePay => 'linepay',
        PaymentMethod.voucher => 'voucher',
        PaymentMethod.points => 'points',
        PaymentMethod.other => 'other',
      };

  String get label => switch (this) {
        PaymentMethod.cash => '現金',
        PaymentMethod.creditCard => '信用卡',
        PaymentMethod.linePay => 'LINE Pay',
        PaymentMethod.voucher => '禮券',
        PaymentMethod.points => '點數',
        PaymentMethod.other => '其他',
      };

  static PaymentMethod fromCode(String code) => switch (code) {
        'cash' => PaymentMethod.cash,
        'credit_card' => PaymentMethod.creditCard,
        'linepay' => PaymentMethod.linePay,
        'voucher' => PaymentMethod.voucher,
        'points' => PaymentMethod.points,
        _ => PaymentMethod.other,
      };
}

enum PaymentStatus { pending, authorized, captured, failed, refunded, voided }

class Payment {
  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    this.gatewayRef,
    this.gatewayResponse,
    this.tendered,
    this.changeDue,
    this.createdAt,
  });

  final String id;
  final PaymentMethod method;
  final Money amount;
  final PaymentStatus status;
  final String? gatewayRef;
  final Map<String, dynamic>? gatewayResponse;

  /// Amount tendered for cash payments (cents).
  final Money? tendered;
  final Money? changeDue;
  final DateTime? createdAt;

  Payment copyWith({
    PaymentStatus? status,
    String? gatewayRef,
    Map<String, dynamic>? gatewayResponse,
    Money? tendered,
    Money? changeDue,
  }) =>
      Payment(
        id: id,
        method: method,
        amount: amount,
        status: status ?? this.status,
        gatewayRef: gatewayRef ?? this.gatewayRef,
        gatewayResponse: gatewayResponse ?? this.gatewayResponse,
        tendered: tendered ?? this.tendered,
        changeDue: changeDue ?? this.changeDue,
        createdAt: createdAt,
      );
}
