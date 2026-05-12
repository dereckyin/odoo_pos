import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:test/test.dart';

Product _p(String id, num price) => Product(
      id: id,
      sku: 'SKU-$id',
      name: 'P-$id',
      price: Money.fromMajor(price),
    );

void main() {
  group('Cart math', () {
    test('subtotal with mixed lines', () {
      final cart = Cart(lines: [
        CartLine(id: 'l1', product: _p('A', 100), qty: 2),
        CartLine(id: 'l2', product: _p('B', 50), qty: 3),
      ]);
      expect(cart.subtotal.major.toDouble(), 350);
      expect(cart.tax.major.toDouble(), closeTo(16.67, 0.5));
      expect(cart.total.major.toDouble(), closeTo(350, 0.5));
    });

    test('order percentage discount applies to tax-inclusive subtotal', () {
      final cart = Cart(
        lines: [CartLine(id: 'l1', product: _p('A', 1000), qty: 1)],
        orderDiscount: const Discount(type: DiscountType.percentage, value: 10),
      );
      expect(cart.orderLevelDiscountAmount.major.toDouble(), 100);
      expect(cart.total.major.toDouble(), closeTo(900.0, 0.01));
    });

    test('combined line + order discount', () {
      final cart = Cart(
        lines: [
          CartLine(
            id: 'l1',
            product: _p('A', 200),
            qty: 2,
            lineDiscount: const Discount(type: DiscountType.amount, value: 50),
          ),
        ],
        orderDiscount: const Discount(type: DiscountType.amount, value: 50),
      );
      expect(cart.subtotal.major.toDouble(), 350);
      expect(cart.total.major.toDouble(), closeTo(300.0, 0.01));
    });
  });

  group('Money', () {
    test('addition and subtraction preserve cents precision', () {
      final a = Money(1234, currency: 'USD');
      final b = Money(789, currency: 'USD');
      expect((a + b).cents, 2023);
      expect((a - b).cents, 445);
    });

    test('formatted output is human readable', () {
      expect(Money.fromMajor(1234).format(), contains('1,234'));
    });
  });
}
