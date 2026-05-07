import 'package:pos_core/pos_core.dart';

class RefundLine {
  const RefundLine({
    required this.orderLineId,
    required this.qty,
    required this.amount,
  });

  final String orderLineId;
  final num qty;
  final Money amount;
}

class Refund {
  const Refund({
    required this.id,
    required this.orderId,
    required this.lines,
    required this.totalAmount,
    required this.method,
    required this.createdAt,
    required this.userId,
    this.gatewayRef,
    this.reason,
  });

  final String id;
  final String orderId;
  final List<RefundLine> lines;
  final Money totalAmount;
  final String method;
  final DateTime createdAt;
  final String userId;
  final String? gatewayRef;
  final String? reason;

  bool get isFullRefund => lines.isEmpty;
}
