import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../demo/book_sale_demo.dart';
import '../../members/providers/member_providers.dart';
import '../../products/providers/product_providers.dart';
import '../../promotions/providers/promotion_providers.dart';
import '../models/held_cart_snapshot.dart';
import 'held_cart_repository.dart';

/// Holds the guest_order id currently "imported" into the cashier's order detail
/// (when they pulled a QR-scanned table-side order in for checkout). Stamped
/// onto the paid Order via ``source_guest_order_id`` so the backend can
/// auto-merge it. Reset whenever the cart is cleared.
final pendingGuestOrderIdProvider = StateProvider<String?>((ref) => null);

/// Full guest order snapshot for kitchen reprint and table label in UI.
final importedGuestOrderProvider = StateProvider<GuestOrderDto?>((ref) => null);

/// In-memory cart state. Active transaction is memory-only; explicit 掛單
/// writes to [HeldCarts] in SQLite.
class CartController extends StateNotifier<Cart> {
  CartController(this._ref) : super(Cart());
  final Ref _ref;

  Future<void> addProduct(Product p, {num qty = 1, Money? unitPrice, List<SelectedOption>? selectedOptions}) async {
    final mergeKey = '${p.id}|${(selectedOptions ?? const []).optionsSignature}';
    final existing = state.lines.firstWhereOrNull((l) => l.mergeKey == mergeKey);
    if (existing != null) {
      final updated = existing.copyWith(qty: existing.qty + qty);
      state = state.copyWith(lines: [
        for (final l in state.lines) l.id == existing.id ? updated : l,
      ]);
    } else {
      state = state.copyWith(lines: [
        ...state.lines,
        unitPrice == null
            ? CartLine(
                id: newUuid(),
                product: p,
                qty: qty,
                selectedOptions: selectedOptions,
              )
            : CartLine.custom(
                id: newUuid(),
                product: p,
                qty: qty,
                unitPrice: unitPrice,
                selectedOptions: selectedOptions,
              ),
      ]);
    }
    await _evaluatePromotions();
  }

  Future<void> addProductWithOptions(Product p, List<SelectedOption> options, {num qty = 1}) async {
    await addProduct(p, qty: qty, selectedOptions: options);
  }

  Future<void> updateLineOptions(String lineId, List<SelectedOption> options) async {
    final line = state.lines.firstWhereOrNull((l) => l.id == lineId);
    if (line == null) return;
    final unitPrice = line.product.price + Money(options.totalPriceDeltaCents);
    final updated = line.copyWith(selectedOptions: options, unitPrice: unitPrice);
    state = state.copyWith(lines: [
      for (final l in state.lines)
        if (l.id == lineId) updated else l,
    ]);
    await _evaluatePromotions();
  }

  Future<void> updateQty(String lineId, num qty) async {
    if (qty <= 0) {
      removeLine(lineId);
      return;
    }
    state = state.copyWith(lines: [
      for (final l in state.lines) l.id == lineId ? l.copyWith(qty: qty) : l,
    ]);
    await _evaluatePromotions();
  }

  void removeLine(String lineId) {
    state = state.copyWith(lines: state.lines.where((l) => l.id != lineId).toList());
    _evaluatePromotions();
  }

  void clear() {
    state = Cart();
    _ref.read(pendingGuestOrderIdProvider.notifier).state = null;
    _ref.read(importedGuestOrderProvider.notifier).state = null;
  }

  /// Park current order detail to local DB (掛單).
  Future<String> park({String? label}) async {
    if (state.isEmpty) {
      throw const ValidationError('order detail is empty');
    }
    final guest = _ref.read(importedGuestOrderProvider);
    final pendingId = _ref.read(pendingGuestOrderIdProvider);
    final snap = HeldCartSnapshot.fromCart(
      state,
      pendingGuestOrderId: pendingId,
      guestOrder: guest,
    );
    final defaultLabel = label ?? '掛單 ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    final id = await _ref.read(heldCartRepositoryProvider).insert(
          label: defaultLabel,
          snapshot: snap,
          pendingGuestOrderId: pendingId,
        );
    clear();
    return id;
  }

  /// Restore a parked order into the active order detail.
  Future<List<String>> restoreHeld(String heldId) async {
    final snap = await _ref.read(heldCartRepositoryProvider).loadSnapshot(heldId);
    final skipped = await _applySnapshot(snap);
    await _ref.read(heldCartRepositoryProvider).delete(heldId);
    return skipped;
  }

  Future<void> deleteHeld(String heldId) async {
    await _ref.read(heldCartRepositoryProvider).delete(heldId);
  }

  Future<List<String>> _applySnapshot(HeldCartSnapshot snap) async {
    final productRepo = _ref.read(productRepositoryProvider);
    final memberRepo = _ref.read(memberRepositoryProvider);
    final lines = <CartLine>[];
    final skipped = <String>[];

    for (final l in snap.lines) {
      final product = await productRepo.findById(l.productId);
      if (product == null) {
        skipped.add(l.productId);
        continue;
      }
      lines.add(CartLine.custom(
        id: newUuid(),
        product: product,
        qty: l.qty,
        unitPrice: Money(l.unitPriceCents),
        note: l.note,
        lineDiscount: l.lineDiscount.toDiscount(),
        selectedOptions: l.selectedOptions
            .map((j) => SelectedOption.fromJson(j))
            .toList(growable: false),
      ));
    }

    Member? member;
    if (snap.memberId != null) {
      member = await memberRepo.findById(snap.memberId!);
    }

    state = Cart(
      lines: lines,
      member: member,
      orderDiscount: snap.orderDiscount.toDiscount(),
      note: snap.orderNote,
    );
    _ref.read(pendingGuestOrderIdProvider.notifier).state = snap.pendingGuestOrderId;
    _ref.read(importedGuestOrderProvider.notifier).state = snap.toGuestOrderDto();
    await _evaluatePromotions();
    return skipped;
  }

  /// Pull a guest (table-side) order into the active order detail so the cashier
  /// can review and finalise payment.
  Future<void> importGuestOrder(GuestOrderDto guestOrder) async {
    if (state.lines.isNotEmpty) {
      throw const ValidationError('order detail not empty; clear first');
    }
    final repo = _ref.read(productRepositoryProvider);
    final lines = <CartLine>[];
    for (final l in guestOrder.lines) {
      final product = await repo.findById(l.productId);
      if (product == null) {
        throw ValidationError('product not found: ${l.productName}');
      }
      lines.add(CartLine.custom(
        id: newUuid(),
        product: product,
        qty: l.qty,
        unitPrice: Money(l.unitPriceCents),
        note: l.note,
        selectedOptions: l.optionsJson
            .map((j) => SelectedOption.fromJson(j))
            .toList(growable: false),
      ));
    }
    state = state.copyWith(lines: lines, note: guestOrder.customerNote);
    _ref.read(pendingGuestOrderIdProvider.notifier).state = guestOrder.id;
    _ref.read(importedGuestOrderProvider.notifier).state = guestOrder;
    await _evaluatePromotions();
  }

  void setLineDiscount(String lineId, Discount d) {
    state = state.copyWith(lines: [
      for (final l in state.lines) l.id == lineId ? l.copyWith(lineDiscount: d) : l,
    ]);
    _evaluatePromotions();
  }

  void setOrderDiscount(Discount d) {
    state = state.copyWith(orderDiscount: d);
    _evaluatePromotions();
  }

  void setMember(Member? m) {
    state = state.copyWith(member: m, memberSentinel: null);
    _evaluatePromotions();
  }

  Future<void> _evaluatePromotions() async {
    final promotions = await _ref.read(promotionsListProvider.future);
    final engine = _ref.read(promotionEngineProvider);
    final result = engine.evaluate(
      cart: state,
      promotions: promotions,
      categoryTree: _ref.read(categoryTreeProvider),
    );
    state = result.cart;
  }

  Future<bool> scanBarcode(String code) async {
    final repo = _ref.read(productRepositoryProvider);
    var p = await repo.findByBarcode(code);
    if (p == null && BookSaleDemo.enabled) {
      await BookSaleDemo.loadBooks();
      final demo = BookSaleDemo.findByBarcode(code);
      if (demo != null) {
        await BookSaleDemo.ensureLocalCatalog(
          _ref.read(databaseProvider),
          books: BookSaleDemo.books,
        );
        p = BookSaleDemo.toProduct(demo);
      }
    }
    if (p == null) return false;
    await addProduct(p);
    return true;
  }
}

extension _ListX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, Cart>((ref) {
  return CartController(ref);
});
