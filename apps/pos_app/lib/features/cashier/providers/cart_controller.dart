import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../../products/providers/product_providers.dart';
import '../../promotions/providers/promotion_providers.dart';

/// Holds the guest_order id currently "imported" into the cashier's cart
/// (when they pulled a QR-scanned table-side order in for checkout). Stamped
/// onto the paid Order via ``source_guest_order_id`` so the backend can
/// auto-merge it. Reset whenever the cart is cleared.
final pendingGuestOrderIdProvider = StateProvider<String?>((ref) => null);

/// In-memory cart state. Persists in memory only; if the app is killed mid
/// transaction we lose the draft (intentional for POS — the operator should
/// not be confused by a stale cart on next login).
class CartController extends StateNotifier<Cart> {
  CartController(this._ref) : super(Cart());
  final Ref _ref;

  Future<void> addProduct(Product p, {num qty = 1, Money? unitPrice}) async {
    final existing = state.lines.firstWhereOrNull((l) => l.product.id == p.id);
    if (existing != null) {
      final updated = existing.copyWith(qty: existing.qty + qty);
      state = state.copyWith(lines: [
        for (final l in state.lines) l.id == existing.id ? updated : l,
      ]);
    } else {
      state = state.copyWith(lines: [
        ...state.lines,
        unitPrice == null
            ? CartLine(id: newUuid(), product: p, qty: qty)
            : CartLine.custom(id: newUuid(), product: p, qty: qty, unitPrice: unitPrice),
      ]);
    }
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
  }

  /// Pull a guest (table-side) order into the active cart so the cashier
  /// can finalise payment. Snapshots line prices to the values quoted to
  /// the customer when they submitted via QR — the cart can still apply
  /// discounts/promotions on top.
  Future<void> importGuestOrder(GuestOrderDto guestOrder) async {
    if (state.lines.isNotEmpty) {
      throw const ValidationError('cart not empty; clear first');
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
      ));
    }
    state = state.copyWith(lines: lines, note: guestOrder.customerNote);
    _ref.read(pendingGuestOrderIdProvider.notifier).state = guestOrder.id;
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
    final result = engine.evaluate(cart: state, promotions: promotions);
    state = result.cart;
  }

  Future<bool> scanBarcode(String code) async {
    final repo = _ref.read(productRepositoryProvider);
    final p = await repo.findByBarcode(code);
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
