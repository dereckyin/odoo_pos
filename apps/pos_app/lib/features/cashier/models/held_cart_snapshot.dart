import 'dart:convert';

import 'package:pos_domain/pos_domain.dart';

import '../../../data/api/dto.dart';

/// Serializable cashier cart for 掛單 (park) / 取單 (restore).
class HeldCartSnapshot {
  const HeldCartSnapshot({
    required this.lines,
    this.memberId,
    this.orderDiscount = const _DiscountJson(type: 'none', value: 0),
    this.orderNote,
    this.pendingGuestOrderId,
    this.guestOrder,
  });

  factory HeldCartSnapshot.fromJson(Map<String, dynamic> j) => HeldCartSnapshot(
        lines: (j['lines'] as List)
            .map((e) => _LineJson.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        memberId: j['member_id'] as String?,
        orderDiscount: j['order_discount'] == null
            ? const _DiscountJson(type: 'none', value: 0)
            : _DiscountJson.fromJson((j['order_discount'] as Map).cast<String, dynamic>()),
        orderNote: j['order_note'] as String?,
        pendingGuestOrderId: j['pending_guest_order_id'] as String?,
        guestOrder: j['guest_order'] == null
            ? null
            : _GuestOrderJson.fromJson((j['guest_order'] as Map).cast<String, dynamic>()),
      );

  final List<_LineJson> lines;
  final String? memberId;
  final _DiscountJson orderDiscount;
  final String? orderNote;
  final String? pendingGuestOrderId;
  final _GuestOrderJson? guestOrder;

  Map<String, dynamic> toJson() => {
        'lines': lines.map((l) => l.toJson()).toList(),
        if (memberId != null) 'member_id': memberId,
        'order_discount': orderDiscount.toJson(),
        if (orderNote != null) 'order_note': orderNote,
        if (pendingGuestOrderId != null) 'pending_guest_order_id': pendingGuestOrderId,
        if (guestOrder != null) 'guest_order': guestOrder!.toJson(),
      };

  String encode() => jsonEncode(toJson());

  static HeldCartSnapshot decode(String raw) =>
      HeldCartSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static HeldCartSnapshot fromCart(
    Cart cart, {
    String? pendingGuestOrderId,
    GuestOrderDto? guestOrder,
  }) {
    return HeldCartSnapshot(
      lines: cart.lines
          .map(
            (l) => _LineJson(
              productId: l.product.id,
              qty: l.qty.toDouble(),
              unitPriceCents: l.unitPrice.cents,
              note: l.note,
              selectedOptions: l.selectedOptions.map((o) => o.toJson()).toList(),
              lineDiscount: _DiscountJson.fromDiscount(l.lineDiscount),
            ),
          )
          .toList(),
      memberId: cart.member?.id,
      orderDiscount: _DiscountJson.fromDiscount(cart.orderDiscount),
      orderNote: cart.note,
      pendingGuestOrderId: pendingGuestOrderId,
      guestOrder: guestOrder == null ? null : _GuestOrderJson.fromDto(guestOrder),
    );
  }

  GuestOrderDto? toGuestOrderDto() => guestOrder?.toDto();
}

class _LineJson {
  const _LineJson({
    required this.productId,
    required this.qty,
    required this.unitPriceCents,
    this.note,
    this.selectedOptions = const [],
    this.lineDiscount = const _DiscountJson(type: 'none', value: 0),
  });

  factory _LineJson.fromJson(Map<String, dynamic> j) => _LineJson(
        productId: j['product_id'] as String,
        qty: (j['qty'] as num).toDouble(),
        unitPriceCents: (j['unit_price_cents'] as num).toInt(),
        note: j['note'] as String?,
        selectedOptions: (j['selected_options'] as List?)
                ?.map((e) => (e as Map).cast<String, dynamic>())
                .toList() ??
            const [],
        lineDiscount: j['line_discount'] == null
            ? const _DiscountJson(type: 'none', value: 0)
            : _DiscountJson.fromJson((j['line_discount'] as Map).cast<String, dynamic>()),
      );

  final String productId;
  final double qty;
  final int unitPriceCents;
  final String? note;
  final List<Map<String, dynamic>> selectedOptions;
  final _DiscountJson lineDiscount;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'qty': qty,
        'unit_price_cents': unitPriceCents,
        if (note != null) 'note': note,
        'selected_options': selectedOptions,
        'line_discount': lineDiscount.toJson(),
      };
}

class _DiscountJson {
  const _DiscountJson({
    required this.type,
    required this.value,
    this.label,
    this.promotionId,
  });

  factory _DiscountJson.fromJson(Map<String, dynamic> j) => _DiscountJson(
        type: j['type'] as String? ?? 'none',
        value: (j['value'] as num?) ?? 0,
        label: j['label'] as String?,
        promotionId: j['promotion_id'] as String?,
      );

  factory _DiscountJson.fromDiscount(Discount d) => _DiscountJson(
        type: switch (d.type) {
          DiscountType.percentage => 'percentage',
          DiscountType.amount => 'amount',
          DiscountType.none => 'none',
        },
        value: d.value,
        label: d.label,
        promotionId: d.promotionId,
      );

  final String type;
  final num value;
  final String? label;
  final String? promotionId;

  Discount toDiscount() {
    final dt = switch (type) {
      'percentage' => DiscountType.percentage,
      'amount' => DiscountType.amount,
      _ => DiscountType.none,
    };
    return Discount(type: dt, value: value, label: label, promotionId: promotionId);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        if (label != null) 'label': label,
        if (promotionId != null) 'promotion_id': promotionId,
      };
}

class _GuestOrderJson {
  const _GuestOrderJson({
    required this.id,
    required this.storeId,
    required this.tableId,
    required this.status,
    required this.estimatedSubtotalCents,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
    this.tableLabel,
    this.customerNote,
    this.partySize,
  });

  factory _GuestOrderJson.fromDto(GuestOrderDto o) => _GuestOrderJson(
        id: o.id,
        storeId: o.storeId,
        tableId: o.tableId,
        status: o.status,
        estimatedSubtotalCents: o.estimatedSubtotalCents,
        createdAt: o.createdAt.toUtc().toIso8601String(),
        updatedAt: o.updatedAt.toUtc().toIso8601String(),
        tableLabel: o.tableLabel,
        customerNote: o.customerNote,
        partySize: o.partySize,
        lines: o.lines
            .map(
              (l) => {
                'id': l.id,
                'product_id': l.productId,
                'product_name': l.productName,
                'sku': l.sku,
                'qty': l.qty,
                'unit_price_cents': l.unitPriceCents,
                'line_total_cents': l.lineTotalCents,
                'note': l.note,
                'created_at': l.createdAt.toUtc().toIso8601String(),
                'options_json': l.optionsJson,
              },
            )
            .toList(),
      );

  factory _GuestOrderJson.fromJson(Map<String, dynamic> j) => _GuestOrderJson(
        id: j['id'] as String,
        storeId: j['store_id'] as String,
        tableId: j['table_id'] as String,
        status: j['status'] as String,
        estimatedSubtotalCents: (j['estimated_subtotal_cents'] as num?)?.toInt() ?? 0,
        createdAt: j['created_at'] as String,
        updatedAt: j['updated_at'] as String,
        tableLabel: j['table_label'] as String?,
        customerNote: j['customer_note'] as String?,
        partySize: (j['party_size'] as num?)?.toInt(),
        lines: (j['lines'] as List).cast<Map<String, dynamic>>(),
      );

  final String id, storeId, tableId, status;
  final int estimatedSubtotalCents;
  final String createdAt, updatedAt;
  final String? tableLabel, customerNote;
  final int? partySize;
  final List<Map<String, dynamic>> lines;

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_id': storeId,
        'table_id': tableId,
        'status': status,
        'estimated_subtotal_cents': estimatedSubtotalCents,
        'created_at': createdAt,
        'updated_at': updatedAt,
        if (tableLabel != null) 'table_label': tableLabel,
        if (customerNote != null) 'customer_note': customerNote,
        if (partySize != null) 'party_size': partySize,
        'lines': lines,
      };

  GuestOrderDto toDto() => GuestOrderDto(
        id: id,
        storeId: storeId,
        tableId: tableId,
        status: status,
        estimatedSubtotalCents: estimatedSubtotalCents,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        tableLabel: tableLabel,
        customerNote: customerNote,
        partySize: partySize,
        lines: lines
            .map((l) => GuestOrderLineDto.fromJson(l))
            .toList(),
      );
}
