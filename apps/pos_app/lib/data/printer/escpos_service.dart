import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;

/// Lightweight ESC/POS abstraction. Concrete connection (TCP / USB / BT) is
/// resolved by [PrinterConnection].
class EscPosReceiptBuilder {
  EscPosReceiptBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build(dom.Order order,
      {dom.Invoice? invoice, String storeName = '點餐趣 Demo'}) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];

    bytes.addAll(gen.text(storeName,
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));

    final df = DateFormat('yyyy/MM/dd HH:mm:ss');
    bytes.addAll(gen.row([
      PosColumn(text: '訂單', width: 4, styles: const PosStyles()),
      PosColumn(text: order.id.substring(0, 8), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: '時間', width: 4),
      PosColumn(text: df.format(order.createdAt), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: '收銀', width: 4),
      PosColumn(text: order.cashierId.substring(0, 8), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));

    for (final line in order.lines) {
      final optionLabel = line.selectedOptions.displayLabel;
      bytes.addAll(gen.text(
        optionLabel.isEmpty ? line.productName : '${line.productName} / $optionLabel',
      ));
      if (line.note != null && line.note!.isNotEmpty) {
        bytes.addAll(gen.text('  備註: ${line.note}'));
      }
      bytes.addAll(gen.row([
        PosColumn(
          text: '  ${line.qty} x ${_money(line.unitPrice)}',
          width: 8,
        ),
        PosColumn(
          text: _money(line.lineTotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(gen.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(_kv(gen, '小計', order.subtotal));
    if (!order.discount.isZero) {
      bytes.addAll(_kv(gen, '折扣', order.discount.negate));
    }
    bytes.addAll(_kv(gen, '稅(內含) 5%', order.tax));
    bytes.addAll(gen.row([
      PosColumn(text: '合計', width: 4, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: _money(order.total),
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]));

    bytes.addAll(gen.feed(1));
    for (final pay in order.payments) {
      bytes.addAll(gen.row([
        PosColumn(text: pay.method.label, width: 4),
        PosColumn(text: _money(pay.amount), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    if (invoice != null && invoice.invoiceNumber != null) {
      bytes.addAll(gen.feed(1));
      bytes.addAll(gen.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(gen.text('發票號碼: ${invoice.invoiceNumber}', styles: const PosStyles(align: PosAlign.center, bold: true)));
      if (invoice.invoiceDate != null) {
        bytes.addAll(gen.text('發票日期: ${df.format(invoice.invoiceDate!)}',
            styles: const PosStyles(align: PosAlign.center)));
      }
      if (invoice.carrier?.code != null) {
        bytes.addAll(gen.text('載具: ${invoice.carrier!.code}',
            styles: const PosStyles(align: PosAlign.center)));
      }
    }

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.text('謝謝惠顧 歡迎再來', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  List<int> _kv(Generator gen, String k, Money v) => gen.row([
        PosColumn(text: k, width: 4),
        PosColumn(text: _money(v), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

  String _money(Money m) => m.format(withSymbol: true);
}

/// Builds the kitchen-side ESC/POS ticket for a [KitchenTicket] (one
/// guest order). Intentionally omits prices: the kitchen only needs the
/// table label, item names, quantities and notes.
class KitchenTicket {
  KitchenTicket({
    required this.guestOrderId,
    required this.tableLabel,
    required this.placedAt,
    required this.lines,
    this.partySize,
    this.note,
  });

  final String guestOrderId;
  final String tableLabel;
  final DateTime placedAt;
  final int? partySize;
  final String? note;
  final List<KitchenTicketLine> lines;
}

class KitchenTicketLine {
  KitchenTicketLine({required this.name, required this.qty, this.note});
  final String name;
  final num qty;
  final String? note;
}

class EscPosKitchenBuilder {
  EscPosKitchenBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build(KitchenTicket ticket) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];

    bytes.addAll(gen.text(
      '*** 廚房製作單 ***',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(gen.text(
      '桌號 ${ticket.tableLabel}',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    ));
    final df = DateFormat('HH:mm:ss');
    bytes.addAll(gen.text(
      '時間: ${df.format(ticket.placedAt.toLocal())}'
      '${ticket.partySize != null ? '   ${ticket.partySize}人' : ''}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.text(
      '單號: ${ticket.guestOrderId.substring(0, 8)}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.text('=' * 32, styles: const PosStyles(align: PosAlign.center)));

    for (final ln in ticket.lines) {
      final qty = ln.qty is int ? ln.qty.toString() : ln.qty.toString();
      bytes.addAll(gen.text(
        '${ln.name}  x $qty',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ));
      if (ln.note != null && ln.note!.isNotEmpty) {
        bytes.addAll(gen.text(
          '  → ${ln.note}',
          styles: const PosStyles(),
        ));
      }
      bytes.addAll(gen.feed(1));
    }

    if (ticket.note != null && ticket.note!.isNotEmpty) {
      bytes.addAll(gen.text('-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(gen.text(
        '備註: ${ticket.note}',
        styles: const PosStyles(bold: true),
      ));
    }

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}

/// Sends raw ESC/POS bytes to a TCP printer (e.g. RJ-45 thermal printers
/// listening on port 9100).
class TcpPrinterDriver {
  Future<void> printRaw(String host, Uint8List bytes, {int port = 9100, Duration timeout = const Duration(seconds: 5)}) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.add(bytes);
      await socket.flush();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } finally {
      await socket.close();
    }
  }
}
