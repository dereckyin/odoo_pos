import '../entities/cart.dart';

/// In-memory cart repository (POS draft carts).
abstract interface class CartRepository {
  Cart current();
  void replace(Cart cart);
  void clear();
  Stream<Cart> watch();
}
