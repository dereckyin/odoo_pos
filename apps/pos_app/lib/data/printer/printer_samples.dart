import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;

import 'escpos_service.dart';

/// Sample payloads for 「測試列印」 in printer settings.
abstract final class PrinterSamples {
  static dom.Order sampleReceiptOrder({DateTime? now}) {
    final t = now ?? DateTime.now();
    const unit = Money(12000);
    const lineTotal = Money(12000);
    return dom.Order(
      id: 'test-receipt-${t.millisecondsSinceEpoch}',
      storeId: 'store-test',
      terminalId: 'terminal-test',
      cashierId: 'cashier-test',
      lines: [
        dom.OrderLine(
          id: 'line-1',
          productId: 'p-demo-1',
          productName: '測試品項 A',
          sku: 'SKU-A',
          qty: 1,
          unitPrice: unit,
          lineDiscount: Money.zero(),
          lineTotal: lineTotal,
        ),
        dom.OrderLine(
          id: 'line-2',
          productId: 'p-demo-2',
          productName: '測試品項 B',
          sku: 'SKU-B',
          qty: 2,
          unitPrice: const Money(5000),
          lineDiscount: Money.zero(),
          lineTotal: const Money(10000),
        ),
      ],
      payments: [
        dom.Payment(
          id: 'pay-1',
          method: dom.PaymentMethod.cash,
          amount: const Money(22000),
          status: dom.PaymentStatus.captured,
          createdAt: t,
        ),
      ],
      subtotal: const Money(22000),
      discount: Money.zero(),
      tax: const Money(1048),
      total: const Money(22000),
      status: dom.OrderStatus.paid,
      createdAt: t,
      note: '【測試列印】',
    );
  }

  static KitchenTicket sampleKitchenTicket({DateTime? now}) {
    final t = now ?? DateTime.now();
    return KitchenTicket(
      guestOrderId: 'test-kitchen-${t.millisecondsSinceEpoch}',
      tableLabel: '測試桌',
      placedAt: t,
      partySize: 2,
      note: '【測試列印】',
      lines: [
        KitchenTicketLine(name: '測試品項 A', qty: 1, note: '少冰'),
        KitchenTicketLine(name: '測試品項 B', qty: 2),
      ],
    );
  }
}
