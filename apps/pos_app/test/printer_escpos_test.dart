import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/printer/printer_providers.dart';
import 'package:pos_app/data/printer/printer_samples.dart';

void main() {
  group('Printer setup helpers', () {
    test('paperSizeFromMm maps 58 and 80 mm', () {
      expect(paperSizeFromMm(58), PaperSize.mm58);
      expect(paperSizeFromMm(80), PaperSize.mm80);
      expect(paperSizeFromMm(72), PaperSize.mm80);
    });

    test('sample receipt order has lines and payments for test print', () {
      final order = PrinterSamples.sampleReceiptOrder(
        now: DateTime.utc(2026, 5, 29, 12),
      );
      expect(order.lines, hasLength(2));
      expect(order.payments, hasLength(1));
      expect(order.note, contains('測試列印'));
      expect(order.total.cents, 22000);
    });

    test('sample kitchen ticket has table label and lines', () {
      final ticket = PrinterSamples.sampleKitchenTicket(
        now: DateTime.utc(2026, 5, 29, 12),
      );
      expect(ticket.tableLabel, '測試桌');
      expect(ticket.lines, hasLength(2));
      expect(ticket.note, contains('測試列印'));
    });
  });
}
