import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';
import 'package:test/test.dart';

Product _p(String id, {String? cat, num price = 100}) => Product(
      id: id,
      sku: 'SKU-$id',
      name: 'Product $id',
      price: Money.fromMajor(price),
      categoryId: cat,
    );

CartLine _line(String id, Product p, num qty) =>
    CartLine(id: id, product: p, qty: qty);

void main() {
  group('PromotionEngine', () {
    final clock = FakeClock(DateTime(2026, 1, 1, 12));
    final engine = PromotionEngine(clock: clock);

    test('threshold amount off', () {
      final p1 = _p('A', price: 600);
      final cart = Cart(lines: [_line('l1', p1, 1)]);
      final promo = Promotion(
        id: 'pr1',
        name: '滿 500 折 100',
        strategy: PromotionStrategy.thresholdAmountOff,
        config: const {'threshold_amount': 500, 'off_amount': 100},
      );
      final r = engine.evaluate(cart: cart, promotions: [promo]);
      expect(r.totalDiscount.major.toDouble(), 100);
      expect(r.cart.total.major.toDouble(), closeTo(525.0, 0.01)); // 500 + 5% tax
    });

    test('nth item discount: 第二件 8 折', () {
      final p1 = _p('A', price: 200);
      final cart = Cart(lines: [_line('l1', p1, 4)]);
      final promo = Promotion(
        id: 'pr2',
        name: '第二件 8 折',
        strategy: PromotionStrategy.nthItemDiscount,
        config: const {'nth': 2, 'nth_discount_pct': 20}, // 20% off on each 2nd item
      );
      final r = engine.evaluate(cart: cart, promotions: [promo]);
      // 4 items: 2 pairs => 2 items at 20% off = 200 * 0.2 * 2 = 80
      expect(r.totalDiscount.major.toDouble(), 80);
    });

    test('buy X get Y free', () {
      final p1 = _p('A', price: 100);
      final cart = Cart(lines: [_line('l1', p1, 6)]);
      final promo = Promotion(
        id: 'pr3',
        name: '買二送一',
        strategy: PromotionStrategy.buyXGetY,
        config: const {'buy_n': 2, 'get_n': 1, 'get_discount_pct': 100},
      );
      final r = engine.evaluate(cart: cart, promotions: [promo]);
      // groups=2 (every 3 items 1 free) => 2 free units * 100
      expect(r.totalDiscount.major.toDouble(), 200);
    });

    test('member level auto-discount', () {
      final p1 = _p('A', price: 1000);
      final goldLevel = const MemberLevel(id: 'gold', name: '金卡', discountRate: 0.9);
      final member = const Member(id: 'm1', phone: '0900', name: 'Alice', level: null)
          .copyWith(level: goldLevel);
      final cart = Cart(lines: [_line('l1', p1, 1)], member: member);
      final r = engine.evaluate(cart: cart, promotions: const []);
      expect(r.totalDiscount.major.toDouble(), 100); // 10% off
    });
  });
}
