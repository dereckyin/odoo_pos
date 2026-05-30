import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/api/dto.dart';

void main() {
  test('GuestOrderDto parses marketplace pickup with null table_id', () {
    final order = GuestOrderDto.fromJson({
      'id': 'go-1',
      'store_id': 'store-1',
      'table_id': null,
      'table_label': null,
      'channel': 'marketplace',
      'fulfillment_type': 'pickup',
      'customer_name': '王小明',
      'customer_phone': '0912345678',
      'status': 'submitted',
      'estimated_subtotal_cents': 12000,
      'created_at': '2026-05-30T10:00:00Z',
      'updated_at': '2026-05-30T10:00:00Z',
      'lines': [
        {
          'id': 'line-1',
          'product_id': 'p-1',
          'product_name': '招牌便當',
          'sku': 'MP-1',
          'qty': 1,
          'unit_price_cents': 12000,
          'line_total_cents': 12000,
          'created_at': '2026-05-30T10:00:00Z',
        },
      ],
    });

    expect(order.tableId, isNull);
    expect(order.isMarketplace, isTrue);
    expect(order.displayTitle, '外帶 · 王小明');
  });

  test('GuestOrderDto keeps table QR display title', () {
    final order = GuestOrderDto.fromJson({
      'id': 'go-2',
      'store_id': 'store-1',
      'table_id': 'table-1',
      'table_label': 'A3',
      'channel': 'table_qr',
      'status': 'submitted',
      'estimated_subtotal_cents': 5000,
      'created_at': '2026-05-30T10:00:00Z',
      'updated_at': '2026-05-30T10:00:00Z',
      'lines': [],
    });

    expect(order.displayTitle, '桌 A3');
  });
}
