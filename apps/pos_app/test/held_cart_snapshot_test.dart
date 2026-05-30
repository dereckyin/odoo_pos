import 'package:flutter_test/flutter_test.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import 'package:pos_app/features/cashier/models/held_cart_snapshot.dart';

void main() {
  test('HeldCartSnapshot round-trip preserves lines and discounts', () {
    final cart = Cart(
      lines: [
        CartLine.custom(
          id: 'line-1',
          product: const Product(
            id: 'p1',
            sku: 'SKU1',
            name: '可口可樂',
            price: Money(5000),
          ),
          qty: 2,
          unitPrice: Money(5500),
          lineDiscount: const Discount(type: DiscountType.percentage, value: 10, label: '9折'),
          selectedOptions: [
            const SelectedOption(
              groupId: 'g1',
              groupName: '冰塊',
              choiceId: 'c1',
              choiceName: '少冰',
              priceDeltaCents: 0,
            ),
          ],
        ),
      ],
      orderDiscount: const Discount(type: DiscountType.amount, value: 5, label: '折5'),
      note: '不要吸管',
    );

    final snap = HeldCartSnapshot.fromCart(cart, pendingGuestOrderId: 'guest-1');
    final raw = snap.encode();
    final restored = HeldCartSnapshot.decode(raw);

    expect(restored.lines.length, 1);
    expect(restored.lines.first.productId, 'p1');
    expect(restored.lines.first.qty, 2);
    expect(restored.lines.first.unitPriceCents, 5500);
    expect(restored.lines.first.lineDiscount.type, 'percentage');
    expect(restored.lines.first.selectedOptions.length, 1);
    expect(restored.orderDiscount.type, 'amount');
    expect(restored.orderNote, '不要吸管');
    expect(restored.pendingGuestOrderId, 'guest-1');
  });
}
