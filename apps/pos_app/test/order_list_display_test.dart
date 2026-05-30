import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/data/database/app_database.dart';
import 'package:pos_app/features/history/order_list_display.dart';

OrderRow _row({
  String? tableLabel,
  String? orderNo,
  String? primaryPaymentMethod,
  DateTime? createdAt,
  DateTime? syncedAt,
  String status = 'paid',
}) {
  return OrderRow(
    id: 'order-1',
    storeId: 'store-1',
    terminalId: 'term-1',
    cashierId: 'user-1',
    memberId: null,
    status: status,
    subtotalCents: 10000,
    discountCents: 0,
    taxCents: 476,
    totalCents: 10000,
    refundedCents: 0,
    invoiceNumber: null,
    invoiceCarrier: null,
    note: null,
    orderNo: orderNo,
    tableLabel: tableLabel,
    primaryPaymentMethod: primaryPaymentMethod,
    sourceGuestOrderId: null,
    createdAt: createdAt ?? DateTime(2026, 5, 30, 14, 32),
    syncedAt: syncedAt,
  );
}

void main() {
  test('fromRow uses table label as title for guest orders', () {
    final d = OrderListDisplay.fromRow(_row(tableLabel: '5'));
    expect(d.title, '桌 5');
    expect(d.subtitle, contains('已付款'));
    expect(d.subtitle, contains('未上傳'));
  });

  test('fromRow uses counter title for walk-in orders', () {
    final d = OrderListDisplay.fromRow(_row());
    expect(d.title, '櫃台');
  });

  test('fromRow shows order number in detail when synced', () {
    final d = OrderListDisplay.fromRow(
      _row(
        orderNo: 'S01-20260530-0001',
        syncedAt: DateTime.now(),
        primaryPaymentMethod: 'cash',
      ),
    );
    expect(d.detail, '單號 S01-20260530-0001');
    expect(d.subtitle, contains('現金'));
    expect(d.subtitle, contains('已上傳'));
  });

  test('receiptOrderRef prefers orderNo over datetime', () {
    final ref = OrderListDisplay.receiptOrderRef(
      createdAt: DateTime(2026, 5, 30, 14, 32),
      orderNo: 'S01-20260530-0001',
    );
    expect(ref, 'S01-20260530-0001');
  });

  test('receiptOrderRef falls back to formatted time', () {
    final ref = OrderListDisplay.receiptOrderRef(
      createdAt: DateTime(2026, 5, 30, 14, 32),
    );
    expect(ref, '2026/05/30 14:32');
  });

  test('dayGroupFor classifies today and yesterday', () {
    final now = DateTime.now();
    expect(dayGroupFor(now), OrderHistoryDayGroup.today);
    expect(dayGroupFor(now.subtract(const Duration(days: 1))), OrderHistoryDayGroup.yesterday);
    expect(dayGroupFor(now.subtract(const Duration(days: 3))), OrderHistoryDayGroup.earlier);
  });
}
