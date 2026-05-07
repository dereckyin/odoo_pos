import 'package:flutter_test/flutter_test.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

void main() {
  group('Cart math', () {
    Product p(String id, num price) => Product(
          id: id,
          sku: id,
          name: 'P-$id',
          price: Money.fromMajor(price),
        );

    test('subtotal / tax / total without discount', () {
      final cart = Cart(lines: [
        CartLine(id: 'l1', product: p('A', 100), qty: 2),
        CartLine(id: 'l2', product: p('B', 50), qty: 3),
      ]);
      expect(cart.subtotal.major.toDouble(), 350);
      expect(cart.tax.major.toDouble(), closeTo(17.5, 0.01));
      expect(cart.total.major.toDouble(), closeTo(367.5, 0.01));
    });

    test('order-level percentage discount', () {
      final cart = Cart(
        lines: [CartLine(id: 'l1', product: p('A', 1000), qty: 1)],
        orderDiscount: const Discount(type: DiscountType.percentage, value: 10),
      );
      expect(cart.orderLevelDiscountAmount.major.toDouble(), 100);
      expect(cart.total.major.toDouble(), closeTo(945.0, 0.01)); // (1000-100) + 5% tax
    });

    test('line discount', () {
      final cart = Cart(lines: [
        CartLine(
            id: 'l1',
            product: p('A', 200),
            qty: 2,
            lineDiscount: const Discount(type: DiscountType.amount, value: 50)),
      ]);
      // gross 400, discount 50 -> net 350, tax 17.5
      expect(cart.subtotal.major.toDouble(), 350);
    });
  });
}
