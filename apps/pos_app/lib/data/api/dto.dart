/// JSON DTOs - hand-rolled to avoid build_runner being a hard requirement on
/// first checkout. They mirror the FastAPI schemas in `apps/api/app/schemas`.

class StoreDto {
  StoreDto({
    required this.id,
    required this.code,
    required this.name,
    required this.updatedAt,
    this.taxId,
    this.address,
    this.phone,
  });

  factory StoreDto.fromJson(Map<String, dynamic> j) => StoreDto(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        taxId: j['tax_id'] as String?,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  final String id, code, name;
  final String? taxId, address, phone;
  final DateTime updatedAt;
}

class TerminalDto {
  TerminalDto({required this.id, required this.storeId, required this.code, this.lastSeenAt});
  factory TerminalDto.fromJson(Map<String, dynamic> j) => TerminalDto(
        id: j['id'] as String,
        storeId: j['store_id'] as String,
        code: j['code'] as String,
        lastSeenAt: j['last_seen_at'] == null ? null : DateTime.parse(j['last_seen_at'] as String),
      );
  final String id, storeId, code;
  final DateTime? lastSeenAt;
}

class SessionDto {
  SessionDto({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tenantId,
    this.tenantCode,
    this.storeId,
    this.terminalId,
    this.mustChangePassword = false,
  });

  factory SessionDto.fromJson(Map<String, dynamic> j) => SessionDto(
        userId: j['user_id'] as String,
        username: j['username'] as String,
        displayName: j['display_name'] as String,
        role: j['role'] as String,
        tenantId: j['tenant_id'] as String?,
        tenantCode: j['tenant_code'] as String?,
        storeId: j['store_id'] as String?,
        terminalId: j['terminal_id'] as String?,
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(((j['expires_at'] as num) * 1000).toInt()),
        mustChangePassword: j['must_change_password'] as bool? ?? false,
      );

  final String userId, username, displayName, role, accessToken, refreshToken;
  final String? tenantId, tenantCode, storeId, terminalId;
  final bool mustChangePassword;
  final DateTime expiresAt;
}

class CategoryDto {
  CategoryDto({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.parentId,
    this.sortOrder = 0,
    this.color,
    this.icon,
    this.deletedAt,
    this.hideFromPublicOrdering = false,
    this.hideFromPosBrowse = false,
  });
  factory CategoryDto.fromJson(Map<String, dynamic> j) => CategoryDto(
        id: j['id'] as String,
        name: j['name'] as String,
        parentId: j['parent_id'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        color: j['color'] as String?,
        icon: j['icon'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
        hideFromPublicOrdering: j['hide_from_public_ordering'] as bool? ?? false,
        hideFromPosBrowse: j['hide_from_pos_browse'] as bool? ?? false,
      );
  final String id, name;
  final String? parentId, color, icon;
  final int sortOrder;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
}

class ProductDto {
  ProductDto({
    required this.id,
    required this.sku,
    required this.name,
    required this.priceCents,
    required this.taxRate,
    required this.isWeighted,
    required this.unit,
    required this.isActive,
    required this.barcodes,
    required this.updatedAt,
    this.costCents,
    this.categoryId,
    this.imageUrl,
    this.description,
    this.deletedAt,
    this.hideFromPublicOrdering = false,
    this.hideFromPosBrowse = false,
  });

  factory ProductDto.fromJson(Map<String, dynamic> j) => ProductDto(
        id: j['id'] as String,
        sku: j['sku'] as String,
        name: j['name'] as String,
        priceCents: (j['price_cents'] as num).toInt(),
        costCents: (j['cost_cents'] as num?)?.toInt(),
        taxRate: (j['tax_rate'] as num?)?.toDouble() ?? 0.05,
        isWeighted: j['is_weighted'] as bool? ?? false,
        unit: j['unit'] as String? ?? '個',
        isActive: j['is_active'] as bool? ?? true,
        categoryId: j['category_id'] as String?,
        imageUrl: j['image_url'] as String?,
        description: j['description'] as String?,
        barcodes: (j['barcodes'] as List?)?.cast<String>() ?? const [],
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
        hideFromPublicOrdering: j['hide_from_public_ordering'] as bool? ?? false,
        hideFromPosBrowse: j['hide_from_pos_browse'] as bool? ?? false,
      );

  final String id, sku, name, unit;
  final int priceCents;
  final int? costCents;
  final double taxRate;
  final bool isWeighted, isActive;
  final String? categoryId, imageUrl, description;
  final List<String> barcodes;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool hideFromPublicOrdering;
  final bool hideFromPosBrowse;
}

class MemberDto {
  MemberDto({
    required this.id,
    required this.phone,
    required this.name,
    required this.points,
    required this.totalSpentCents,
    required this.joinedAt,
    required this.updatedAt,
    this.email,
    this.birthday,
    this.levelId,
    this.qrCode,
    this.lastVisitAt,
    this.note,
    this.deletedAt,
  });
  factory MemberDto.fromJson(Map<String, dynamic> j) => MemberDto(
        id: j['id'] as String,
        phone: j['phone'] as String,
        name: j['name'] as String,
        email: j['email'] as String?,
        birthday: j['birthday'] == null ? null : DateTime.parse(j['birthday'] as String),
        points: (j['points'] as num?)?.toInt() ?? 0,
        totalSpentCents: (j['total_spent_cents'] as num?)?.toInt() ?? 0,
        levelId: j['level_id'] as String?,
        qrCode: j['qr_code'] as String?,
        joinedAt: DateTime.parse(j['joined_at'] as String),
        lastVisitAt: j['last_visit_at'] == null ? null : DateTime.parse(j['last_visit_at'] as String),
        note: j['note'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );
  final String id, phone, name;
  final String? email, levelId, qrCode, note;
  final int points;
  final int totalSpentCents;
  final DateTime? birthday, lastVisitAt, deletedAt;
  final DateTime joinedAt;
  final DateTime updatedAt;
}

class MemberLevelDto {
  MemberLevelDto({
    required this.id,
    required this.name,
    required this.discountRate,
    required this.minSpend,
    required this.minPoints,
    this.color,
    this.sortOrder = 0,
  });
  factory MemberLevelDto.fromJson(Map<String, dynamic> j) => MemberLevelDto(
        id: j['id'] as String,
        name: j['name'] as String,
        discountRate: (j['discount_rate'] as num).toDouble(),
        minSpend: (j['min_spend'] as num?)?.toInt() ?? 0,
        minPoints: (j['min_points'] as num?)?.toInt() ?? 0,
        color: j['color'] as String?,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
  final String id, name;
  final double discountRate;
  final int minSpend, minPoints, sortOrder;
  final String? color;
}

class CouponDto {
  CouponDto({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minSpendCents,
    required this.updatedAt,
    this.memberId,
    this.expiresAt,
    this.usedAt,
  });
  factory CouponDto.fromJson(Map<String, dynamic> j) => CouponDto(
        id: j['id'] as String,
        code: j['code'] as String,
        type: j['type'] as String,
        value: (j['value'] as num).toDouble(),
        memberId: j['member_id'] as String?,
        minSpendCents: (j['min_spend_cents'] as num?)?.toInt() ?? 0,
        expiresAt: j['expires_at'] == null ? null : DateTime.parse(j['expires_at'] as String),
        usedAt: j['used_at'] == null ? null : DateTime.parse(j['used_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
  final String id, code, type;
  final double value;
  final String? memberId;
  final int minSpendCents;
  final DateTime? expiresAt, usedAt;
  final DateTime updatedAt;
}

class PromotionDto {
  PromotionDto({
    required this.id,
    required this.name,
    required this.strategy,
    required this.config,
    required this.isActive,
    required this.priority,
    required this.stackable,
    required this.applicableProductIds,
    required this.applicableCategoryIds,
    required this.memberLevelIds,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
    this.description,
    this.deletedAt,
  });
  factory PromotionDto.fromJson(Map<String, dynamic> j) => PromotionDto(
        id: j['id'] as String,
        name: j['name'] as String,
        strategy: j['strategy'] as String,
        config: (j['config'] as Map).cast<String, dynamic>(),
        priority: (j['priority'] as num?)?.toInt() ?? 0,
        startsAt: j['starts_at'] == null ? null : DateTime.parse(j['starts_at'] as String),
        endsAt: j['ends_at'] == null ? null : DateTime.parse(j['ends_at'] as String),
        isActive: j['is_active'] as bool? ?? true,
        stackable: j['stackable'] as bool? ?? false,
        applicableProductIds: (j['applicable_product_ids'] as List?)?.cast<String>() ?? const [],
        applicableCategoryIds: (j['applicable_category_ids'] as List?)?.cast<String>() ?? const [],
        memberLevelIds: (j['member_level_ids'] as List?)?.cast<String>() ?? const [],
        description: j['description'] as String?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );
  final String id, name, strategy;
  final Map<String, dynamic> config;
  final int priority;
  final DateTime? startsAt, endsAt, deletedAt;
  final bool isActive, stackable;
  final List<String> applicableProductIds, applicableCategoryIds, memberLevelIds;
  final String? description;
  final DateTime updatedAt;
}

class InventoryLevelDto {
  InventoryLevelDto({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.onHand,
    required this.safetyStock,
    required this.reserved,
    required this.updatedAt,
  });
  factory InventoryLevelDto.fromJson(Map<String, dynamic> j) => InventoryLevelDto(
        id: j['id'] as String,
        storeId: j['store_id'] as String,
        productId: j['product_id'] as String,
        onHand: (j['on_hand'] as num).toDouble(),
        safetyStock: (j['safety_stock'] as num).toDouble(),
        reserved: (j['reserved'] as num).toDouble(),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
  final String id, storeId, productId;
  final double onHand, safetyStock, reserved;
  final DateTime updatedAt;
}

class OptionChoiceDto {
  OptionChoiceDto({
    required this.id,
    required this.optionGroupId,
    required this.name,
    required this.priceDeltaCents,
    required this.isDefault,
    required this.sortOrder,
    required this.isActive,
    required this.updatedAt,
    this.deletedAt,
  });

  factory OptionChoiceDto.fromJson(Map<String, dynamic> j) => OptionChoiceDto(
        id: j['id'] as String,
        optionGroupId: j['option_group_id'] as String,
        name: j['name'] as String,
        priceDeltaCents: (j['price_delta_cents'] as num?)?.toInt() ?? 0,
        isDefault: j['is_default'] as bool? ?? false,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] as bool? ?? true,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
      );

  final String id, optionGroupId, name;
  final int priceDeltaCents, sortOrder;
  final bool isDefault, isActive;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class OptionGroupDto {
  OptionGroupDto({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelections,
    required this.sortOrder,
    required this.updatedAt,
    this.maxSelections,
    this.deletedAt,
    this.choices = const [],
  });

  factory OptionGroupDto.fromJson(Map<String, dynamic> j) => OptionGroupDto(
        id: j['id'] as String,
        name: j['name'] as String,
        selectionType: j['selection_type'] as String? ?? 'single',
        isRequired: j['is_required'] as bool? ?? true,
        minSelections: (j['min_selections'] as num?)?.toInt() ?? 0,
        maxSelections: (j['max_selections'] as num?)?.toInt(),
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        deletedAt: j['deleted_at'] == null ? null : DateTime.parse(j['deleted_at'] as String),
        choices: (j['choices'] as List?)
                ?.map((e) => OptionChoiceDto.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );

  final String id, name, selectionType;
  final bool isRequired;
  final int minSelections, sortOrder;
  final int? maxSelections;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<OptionChoiceDto> choices;
}

class ProductOptionLinkDto {
  ProductOptionLinkDto({
    required this.id,
    required this.productId,
    required this.optionGroupId,
    required this.sortOrder,
    required this.updatedAt,
    this.isRequired,
  });

  factory ProductOptionLinkDto.fromJson(Map<String, dynamic> j) => ProductOptionLinkDto(
        id: j['id'] as String,
        productId: j['product_id'] as String,
        optionGroupId: j['option_group_id'] as String,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        isRequired: j['is_required'] as bool?,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  final String id, productId, optionGroupId;
  final int sortOrder;
  final bool? isRequired;
  final DateTime updatedAt;
}

class ProductOptionOverrideDto {
  ProductOptionOverrideDto({
    required this.id,
    required this.productId,
    required this.optionChoiceId,
    required this.isHidden,
    required this.updatedAt,
    this.priceDeltaCents,
  });

  factory ProductOptionOverrideDto.fromJson(Map<String, dynamic> j) =>
      ProductOptionOverrideDto(
        id: j['id'] as String,
        productId: j['product_id'] as String,
        optionChoiceId: j['option_choice_id'] as String,
        priceDeltaCents: (j['price_delta_cents'] as num?)?.toInt(),
        isHidden: j['is_hidden'] as bool? ?? false,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  final String id, productId, optionChoiceId;
  final int? priceDeltaCents;
  final bool isHidden;
  final DateTime updatedAt;
}

class DeltaPage<T> {
  DeltaPage({required this.items, required this.serverTime, required this.nextSince});
  final List<T> items;
  final DateTime serverTime;
  final DateTime nextSince;

  static DeltaPage<T> fromJson<T>(Map<String, dynamic> j, T Function(Map<String, dynamic>) item) =>
      DeltaPage(
        items: (j['items'] as List).map((e) => item((e as Map).cast<String, dynamic>())).toList(),
        serverTime: DateTime.parse(j['server_time'] as String),
        nextSince: DateTime.parse(j['next_since'] as String),
      );
}

/// A line inside a guest (table-side) order.
class GuestOrderLineDto {
  GuestOrderLineDto({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitPriceCents,
    required this.lineTotalCents,
    required this.createdAt,
    this.note,
    this.optionsJson = const [],
  });
  factory GuestOrderLineDto.fromJson(Map<String, dynamic> j) => GuestOrderLineDto(
        id: j['id'] as String,
        productId: j['product_id'] as String,
        productName: j['product_name'] as String,
        sku: j['sku'] as String,
        qty: (j['qty'] as num).toDouble(),
        unitPriceCents: (j['unit_price_cents'] as num).toInt(),
        lineTotalCents: (j['line_total_cents'] as num).toInt(),
        note: j['note'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        optionsJson: (j['options_json'] as List?)
                ?.map((e) => (e as Map).cast<String, dynamic>())
                .toList() ??
            const [],
      );
  final String id, productId, productName, sku;
  final double qty;
  final int unitPriceCents, lineTotalCents;
  final String? note;
  final List<Map<String, dynamic>> optionsJson;
  final DateTime createdAt;
}

/// The customer-facing table-side order pulled from the backend by the KDS
/// and the cashier's "table orders" panel.
class GuestOrderDto {
  GuestOrderDto({
    required this.id,
    required this.storeId,
    required this.status,
    required this.estimatedSubtotalCents,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
    this.tableId,
    this.tableLabel,
    this.channel = 'table_qr',
    this.fulfillmentType,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.customerNote,
    this.partySize,
    this.acceptedAt,
    this.readyAt,
    this.mergedAt,
    this.cancelledAt,
    this.cancelReason,
    this.acceptedByUserId,
    this.mergedOrderId,
  });

  factory GuestOrderDto.fromJson(Map<String, dynamic> j) => GuestOrderDto(
        id: j['id'] as String,
        storeId: j['store_id'] as String,
        tableId: j['table_id'] as String?,
        tableLabel: j['table_label'] as String?,
        channel: j['channel'] as String? ?? 'table_qr',
        fulfillmentType: j['fulfillment_type'] as String?,
        customerName: j['customer_name'] as String?,
        customerPhone: j['customer_phone'] as String?,
        deliveryAddress: j['delivery_address'] as String?,
        status: j['status'] as String,
        customerNote: j['customer_note'] as String?,
        partySize: (j['party_size'] as num?)?.toInt(),
        estimatedSubtotalCents: (j['estimated_subtotal_cents'] as num?)?.toInt() ?? 0,
        acceptedAt: j['accepted_at'] == null ? null : DateTime.parse(j['accepted_at'] as String),
        readyAt: j['ready_at'] == null ? null : DateTime.parse(j['ready_at'] as String),
        mergedAt: j['merged_at'] == null ? null : DateTime.parse(j['merged_at'] as String),
        cancelledAt:
            j['cancelled_at'] == null ? null : DateTime.parse(j['cancelled_at'] as String),
        cancelReason: j['cancel_reason'] as String?,
        acceptedByUserId: j['accepted_by_user_id'] as String?,
        mergedOrderId: j['merged_order_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        lines: (j['lines'] as List)
            .map((e) => GuestOrderLineDto.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  final String id, storeId, status;
  final String? tableId, tableLabel;
  final String channel;
  final String? fulfillmentType;
  final String? customerName, customerPhone, deliveryAddress;
  final String? customerNote, cancelReason, acceptedByUserId, mergedOrderId;
  final int? partySize;
  final int estimatedSubtotalCents;
  final DateTime? acceptedAt, readyAt, mergedAt, cancelledAt;
  final DateTime createdAt, updatedAt;
  final List<GuestOrderLineDto> lines;

  bool get isMarketplace => channel == 'marketplace';

  /// Short label for KDS cards, kitchen tickets, and cashier import snackbars.
  String get displayTitle {
    if (isMarketplace) {
      final ft = switch (fulfillmentType) {
        'pickup' => '外帶',
        'delivery' => '外送',
        'dine_in' => '內用',
        _ => '市集',
      };
      final name = customerName?.trim();
      if (name != null && name.isNotEmpty) return '$ft · $name';
      return ft;
    }
    return '桌 ${tableLabel ?? '?'}';
  }
}
