import 'package:pos_core/pos_core.dart';
import '../entities/payment.dart';

class PaymentRequest {
  const PaymentRequest({
    required this.orderId,
    required this.amount,
    required this.method,
    this.tendered,
    this.metadata,
  });

  final String orderId;
  final Money amount;
  final PaymentMethod method;
  final Money? tendered;
  final Map<String, dynamic>? metadata;
}

class PaymentResult {
  const PaymentResult({
    required this.payment,
    this.redirectUrl,
    this.qrPayload,
    this.deepLink,
  });
  final Payment payment;
  final String? redirectUrl;
  final String? qrPayload;
  final String? deepLink;
}

class RefundRequest {
  const RefundRequest({
    required this.paymentId,
    required this.amount,
    this.reason,
  });
  final String paymentId;
  final Money amount;
  final String? reason;
}

abstract interface class PaymentGateway {
  String get name;
  PaymentMethod get method;
  Future<Result<PaymentResult>> charge(PaymentRequest req);
  Future<Result<PaymentResult>> confirm(String paymentId);
  Future<Result<PaymentResult>> refund(RefundRequest req);
}
