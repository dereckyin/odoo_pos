import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../products/providers/product_providers.dart';
import '../../promotions/providers/promotion_providers.dart';

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
