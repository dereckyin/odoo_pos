import 'package:dio/dio.dart';

import 'dto.dart';

/// Hand-rolled API surface (no retrofit codegen) so `flutter run` works
/// without first invoking build_runner.
class PosApi {
  PosApi(this._dio);
  final Dio _dio;

  // ---- Auth ----
  Future<SessionDto> login({
    required String tenantCode,
    required String storeCode,
    required String terminalCode,
    required String terminalApiKey,
    required String username,
    required String password,
  }) async {
    final r = await _dio.post('/auth/login', data: {
      'tenant_code': tenantCode,
      'store_code': storeCode,
      'terminal_code': terminalCode,
      'terminal_api_key': terminalApiKey,
      'username': username,
      'password': password,
    });
    return SessionDto.fromJson(_asMap(r.data));
  }

  Future<SessionDto> refresh(String refreshToken) async {
    final r = await _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    return SessionDto.fromJson(_asMap(r.data));
  }

  /// Register a new terminal or rotate an existing one's API key.
  /// Now requires an admin-level JWT (server-side enforced) — the caller
  /// must supply ``adminToken`` (e.g. from a prior /auth/admin-login call).
  Future<Map<String, dynamic>> registerTerminal({
    required String storeCode,
    required String terminalCode,
    required String adminToken,
  }) async {
    final r = await _dio.post(
      '/auth/terminals/register',
      data: {'store_code': storeCode, 'terminal_code': terminalCode},
      options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
    );
    return _asMap(r.data);
  }

  /// Browser-style login used by the terminal-register flow to obtain an
  /// admin JWT before calling [registerTerminal].
  Future<SessionDto> adminLogin({
    required String tenantCode,
    required String username,
    required String password,
  }) async {
    final r = await _dio.post('/auth/admin-login', data: {
      'tenant_code': tenantCode,
      'username': username,
      'password': password,
    });
    return SessionDto.fromJson(_asMap(r.data));
  }

  Future<void> heartbeat(String terminalId) async {
    await _dio.post('/auth/terminals/heartbeat', data: {'terminal_id': terminalId});
  }

  // ---- Sync ----
  Future<DeltaPage<ProductDto>> syncProducts(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/products', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), ProductDto.fromJson);
  }

  Future<DeltaPage<CategoryDto>> syncCategories(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/categories', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), CategoryDto.fromJson);
  }

  Future<DeltaPage<MemberDto>> syncMembers(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/members', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), MemberDto.fromJson);
  }

  Future<DeltaPage<MemberLevelDto>> syncMemberLevels(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/member-levels', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), MemberLevelDto.fromJson);
  }

  Future<DeltaPage<CouponDto>> syncCoupons(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/coupons', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), CouponDto.fromJson);
  }

  Future<DeltaPage<PromotionDto>> syncPromotions(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/promotions', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), PromotionDto.fromJson);
  }

  Future<DeltaPage<InventoryLevelDto>> syncInventory(
    DateTime since, {
    String? storeId,
    int limit = 1000,
  }) async {
    final r = await _dio.get('/sync/inventory-levels', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
      if (storeId != null) 'store_id': storeId,
    });
    return DeltaPage.fromJson(_asMap(r.data), InventoryLevelDto.fromJson);
  }

  Future<DeltaPage<OptionGroupDto>> syncOptionGroups(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/option-groups', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), OptionGroupDto.fromJson);
  }

  Future<DeltaPage<ProductOptionLinkDto>> syncProductOptionLinks(
    DateTime since, {
    int limit = 1000,
  }) async {
    final r = await _dio.get('/sync/product-option-links', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), ProductOptionLinkDto.fromJson);
  }

  Future<DeltaPage<ProductOptionOverrideDto>> syncProductOptionOverrides(
    DateTime since, {
    int limit = 1000,
  }) async {
    final r = await _dio.get('/sync/product-option-overrides', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), ProductOptionOverrideDto.fromJson);
  }

  // ---- Orders / Refunds ----
  Future<Map<String, dynamic>> uploadOrder(Map<String, dynamic> payload) async {
    final r = await _dio.post('/orders', data: payload);
    return _asMap(r.data);
  }

  Future<Map<String, dynamic>> refundOrder(String orderId, Map<String, dynamic> payload) async {
    final r = await _dio.post('/orders/$orderId/refund', data: payload);
    return _asMap(r.data);
  }

  Future<List<Map<String, dynamic>>> recentOrders({String? memberId, String? terminalId, int limit = 20}) async {
    final r = await _dio.get('/orders', queryParameters: {
      if (memberId != null) 'member_id': memberId,
      if (terminalId != null) 'terminal_id': terminalId,
      'limit': limit,
    });
    return (r.data as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  // ---- Inventory / Movements ----
  Future<void> postMovement(Map<String, dynamic> payload) async {
    await _dio.post('/inventory/movements', data: payload);
  }

  Future<void> postMovementsBatch(List<Map<String, dynamic>> payload) async {
    await _dio.post('/inventory/movements/batch', data: payload);
  }

  // ---- Member ----
  Future<MemberDto?> findMemberByPhone(String phone) async {
    try {
      final r = await _dio.get('/members/by-phone/$phone');
      return MemberDto.fromJson(_asMap(r.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<MemberDto?> findMemberByQr(String qr) async {
    try {
      final r = await _dio.get('/members/by-qr/$qr');
      return MemberDto.fromJson(_asMap(r.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<MemberDto> createMember(Map<String, dynamic> payload) async {
    final r = await _dio.post('/members', data: payload);
    return MemberDto.fromJson(_asMap(r.data));
  }

  // ---- Payment / Invoice ----
  Future<Map<String, dynamic>> charge(Map<String, dynamic> payload) async {
    final r = await _dio.post('/payments/charge', data: payload);
    return _asMap(r.data);
  }

  Future<Map<String, dynamic>> issueInvoice(Map<String, dynamic> payload) async {
    final r = await _dio.post('/invoices/issue', data: payload);
    return _asMap(r.data);
  }

  Future<Map<String, dynamic>> voidInvoice(Map<String, dynamic> payload) async {
    final r = await _dio.post('/invoices/void', data: payload);
    return _asMap(r.data);
  }

  // ---- Guest orders (QR table-side ordering) ----
  Future<List<GuestOrderDto>> listGuestOrders({
    String? storeId,
    String statusIn = 'submitted,accepted,ready',
    int limit = 100,
  }) async {
    final r = await _dio.get('/guest-orders', queryParameters: {
      if (storeId != null) 'store_id': storeId,
      'status_in': statusIn,
      'limit': limit,
    });
    return (r.data as List)
        .map((e) => GuestOrderDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<GuestOrderDto> acceptGuestOrder(String id) async {
    final r = await _dio.post('/guest-orders/$id/accept');
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  Future<GuestOrderDto> markGuestOrderReady(String id) async {
    final r = await _dio.post('/guest-orders/$id/ready');
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  Future<GuestOrderDto> cancelGuestOrder(String id, {String? reason}) async {
    final r = await _dio.post('/guest-orders/$id/cancel', data: {
      if (reason != null) 'reason': reason,
    });
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  Future<GuestOrderDto> mergeGuestOrder(String id, String orderId) async {
    final r = await _dio.post('/guest-orders/$id/merge', data: {'order_id': orderId});
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  Future<GuestOrderDto> completeGuestOrder(String id) async {
    final r = await _dio.post('/guest-orders/$id/complete');
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  Future<GuestOrderDto> deliverGuestOrder(String id) async {
    final r = await _dio.post('/guest-orders/$id/deliver');
    return GuestOrderDto.fromJson(_asMap(r.data));
  }

  // ---- Consignment books ----
  Future<ConsignmentPosConfigDto> fetchConsignmentPosConfig() async {
    final r = await _dio.get('/books/pos-config');
    return ConsignmentPosConfigDto.fromJson(_asMap(r.data));
  }

  Future<BookLookupDto> lookupBook(String barcode) async {
    final r = await _dio.get('/books/lookup', queryParameters: {'barcode': barcode});
    return BookLookupDto.fromJson(_asMap(r.data));
  }

  Future<BookProductDto> receiveBook({required String barcode, required double qty, String? storeId}) async {
    final r = await _dio.post('/books/receive', data: {
      'barcode': barcode,
      'qty': qty,
      if (storeId != null) 'store_id': storeId,
    });
    return BookProductDto.fromJson(_asMap(r.data));
  }

  Future<List<BookProductDto>> searchBooks(String q) async {
    final r = await _dio.get('/books/search', queryParameters: {'q': q});
    final list = r.data as List;
    return list.map((e) => BookProductDto.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<DeltaPage<BookDetailDto>> syncBookDetails(DateTime since, {int limit = 500}) async {
    final r = await _dio.get('/sync/book-details', queryParameters: {
      'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return DeltaPage.fromJson(_asMap(r.data), BookDetailDto.fromJson);
  }

  Future<LoyaltySettingsDto> getLoyaltySettings() async {
    final r = await _dio.get('/members/loyalty/settings');
    return LoyaltySettingsDto.fromJson(_asMap(r.data));
  }

  Future<CouponPreviewDto> previewCoupon({
    required String code,
    required int orderTotalCents,
    String? memberId,
  }) async {
    final r = await _dio.post('/coupons/preview', data: {
      'code': code,
      'order_total_cents': orderTotalCents,
      if (memberId != null) 'member_id': memberId,
    });
    return CouponPreviewDto.fromJson(_asMap(r.data));
  }

  // helpers
  Map<String, dynamic> _asMap(dynamic data) => (data as Map).cast<String, dynamic>();
}
