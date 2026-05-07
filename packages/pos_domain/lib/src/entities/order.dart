import 'package:pos_core/pos_core.dart';
import 'cart.dart';
import 'payment.dart';

enum OrderStatus { draft, paid, voided, refunded, partiallyRefunded }

class OrderLine {
  const OrderLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitPrice,
    required this.lineDiscount,
    required this.lineTotal,
    this.taxRate = 0.05,
    this.note,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final num qty;
  final Money unitPrice;
  final Money lineDiscount;
  final Money lineTotal;
  final double taxRate;
  final String? note;
}

class Order {
  const Order({
    required this.id,
    required this.storeId,
    required this.terminalId,
    required this.cashierId,
    required this.lines,
    required this.payments,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.memberId,
    this.invoiceNumber,
    this.invoiceCarrier,
    this.note,
    this.syncedAt,
    this.refundedAmount,
  });

  final String id;
  final String storeId;
  final String terminalId;
  final String cashierId;
  final String? memberId;
  final List<OrderLine> lines;
  final List<Payment> payments;

  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money total;

  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;

  final String? invoiceNumber;
  final String? invoiceCarrier;
  final String? note;
  final Money? refundedAmount;

  bool get isSynced => syncedAt != null;
  bool get isRefundable => status == OrderStatus.paid || status == OrderStatus.partiallyRefunded;

  Order copyWith({
    OrderStatus? status,
    DateTime? syncedAt,
    String? invoiceNumber,
    Money? refundedAmount,
    List<Payment>? payments,
  }) =>
      Order(
        id: id,
        storeId: storeId,
        terminalId: terminalId,
        cashierId: cashierId,
        memberId: memberId,
        lines: lines,
        payments: payments ?? this.payments,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        status: status ?? this.status,
        createdAt: createdAt,
        syncedAt: syncedAt ?? this.syncedAt,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        invoiceCarrier: invoiceCarrier,
        note: note,
        refundedAmount: refundedAmount ?? this.refundedAmount,
      );

  /// Convert a [Cart] + payment plan into a finalized Order.
  factory Order.fromCart({
    required Cart cart,
    required String storeId,
    required String terminalId,
    required String cashierId,
    required List<Payment> payments,
    required DateTime now,
    String? invoiceCarrier,
    String? note,
  }) {
    final lines = cart.lines
        .map((l) => OrderLine(
              id: l.id,
              productId: l.product.id,
              productName: l.product.name,
              sku: l.product.sku,
              qty: l.qty,
              unitPrice: l.unitPrice,
              lineDiscount: l.discountAmount,
              lineTotal: l.net,
              taxRate: l.product.taxRate,
            ))
        .toList(growable: false);

    return Order(
      id: cart.id,
      storeId: storeId,
      terminalId: terminalId,
      cashierId: cashierId,
      memberId: cart.member?.id,
      lines: lines,
      payments: payments,
      subtotal: cart.subtotal,
      discount: cart.orderLevelDiscountAmount,
      tax: cart.tax,
      total: cart.total,
      status: OrderStatus.paid,
      createdAt: now,
      invoiceCarrier: invoiceCarrier,
      note: note,
    );
  }
}
