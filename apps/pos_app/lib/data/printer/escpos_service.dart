import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart' as dom;

import '../../features/history/order_list_display.dart';
import 'escpos_zh.dart';

/// Lightweight ESC/POS abstraction. Concrete connection (TCP / USB / BT) is
/// resolved by [PrinterConnection].
class EscPosReceiptBuilder {
  EscPosReceiptBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build(
    dom.Order order, {
    dom.Invoice? invoice,
    String storeName = '點餐趣 Demo',
    String? orderNo,
    String? tableLabel,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];

    bytes.addAll(escText(gen, storeName,
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(gen.feed(1));
    bytes.addAll(escText(gen, '=' * 32, styles: const PosStyles(align: PosAlign.center)));

    final df = DateFormat('yyyy/MM/dd HH:mm:ss');
    final orderRef = OrderListDisplay.receiptOrderRef(
      createdAt: order.createdAt,
      orderNo: orderNo,
      tableLabel: tableLabel,
    );
    bytes.addAll(gen.row([
      escCol('單號', width: 4),
      escCol(orderRef, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    if (tableLabel != null && tableLabel.isNotEmpty) {
      bytes.addAll(gen.row([
        escCol('桌號', width: 4),
        escCol(tableLabel, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(gen.row([
      escCol('時間', width: 4),
      escCol(df.format(order.createdAt.toLocal()), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      escCol('收銀', width: 4),
      escCol(order.cashierId.substring(0, 8), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));

    for (final line in order.lines) {
      final optionLabel = line.selectedOptions.displayLabel;
      bytes.addAll(escText(
        gen,
        optionLabel.isEmpty ? line.productName : '${line.productName} / $optionLabel',
      ));
      if (line.note != null && line.note!.isNotEmpty) {
        bytes.addAll(escText(gen, '  備註: ${line.note}'));
      }
      bytes.addAll(gen.row([
        escCol('  ${line.qty} x ${_money(line.unitPrice)}', width: 8),
        escCol(_money(line.lineTotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(_kv(gen, '小計', order.subtotal));
    if (!order.discount.isZero) {
      bytes.addAll(_kv(gen, '折扣', order.discount.negate));
    }
    bytes.addAll(_kv(gen, '稅(內含) 5%', order.tax));
    bytes.addAll(gen.row([
      escCol('合計', width: 4, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      escCol(
        _money(order.total),
        width: 8,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]));

    bytes.addAll(gen.feed(1));
    for (final pay in order.payments) {
      bytes.addAll(gen.row([
        escCol(pay.method.label, width: 4),
        escCol(_money(pay.amount), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    if (invoice != null && invoice.invoiceNumber != null) {
      bytes.addAll(gen.feed(1));
      bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(escText(gen, '發票號碼: ${invoice.invoiceNumber}',
          styles: const PosStyles(align: PosAlign.center, bold: true)));
      if (invoice.invoiceDate != null) {
        bytes.addAll(escText(gen, '發票日期: ${df.format(invoice.invoiceDate!)}',
            styles: const PosStyles(align: PosAlign.center)));
      }
      if (invoice.carrier?.code != null) {
        bytes.addAll(escText(gen, '載具: ${invoice.carrier!.code}',
            styles: const PosStyles(align: PosAlign.center)));
      }
    }

    bytes.addAll(gen.feed(2));
    bytes.addAll(escText(gen, '謝謝惠顧 歡迎再來', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }

  List<int> _kv(Generator gen, String k, Money v) => gen.row([
        escCol(k, width: 4),
        escCol(_money(v), width: 8, styles: const PosStyles(align: PosAlign.right)),
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
  KitchenTicketLine({required this.name, required this.qty, this.note, this.optionsLabel});
  final String name;
  final num qty;
  final String? note;
  final String? optionsLabel;
}

class EscPosKitchenBuilder {
  EscPosKitchenBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build(KitchenTicket ticket) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];

    bytes.addAll(escText(
      gen,
      '*** 廚房製作單 ***',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(escText(
      gen,
      '桌號 ${ticket.tableLabel}',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    ));
    final df = DateFormat('HH:mm:ss');
    bytes.addAll(escText(
      gen,
      '時間: ${df.format(ticket.placedAt.toLocal())}'
      '${ticket.partySize != null ? '   ${ticket.partySize}人' : ''}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(escText(
      gen,
      '單號: ${ticket.guestOrderId.substring(0, 8)}',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(escText(gen, '=' * 32, styles: const PosStyles(align: PosAlign.center)));

    for (final ln in ticket.lines) {
      final qty = ln.qty is int ? ln.qty.toString() : ln.qty.toString();
      final nameLine = ln.optionsLabel != null && ln.optionsLabel!.isNotEmpty
          ? '${ln.name} / ${ln.optionsLabel}'
          : ln.name;
      bytes.addAll(escText(
        gen,
        '$nameLine  x $qty',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ));
      if (ln.note != null && ln.note!.isNotEmpty) {
        bytes.addAll(escText(gen, '  → ${ln.note}'));
      }
      bytes.addAll(gen.feed(1));
    }

    if (ticket.note != null && ticket.note!.isNotEmpty) {
      bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(escText(
        gen,
        '備註: ${ticket.note}',
        styles: const PosStyles(bold: true),
      ));
    }

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}

/// Customer-facing order confirmation (not a tax invoice).
class OrderConfirmation {
  OrderConfirmation({
    required this.tableLabel,
    required this.placedAt,
    required this.lines,
    required this.estimatedTotal,
    this.orderRef,
    this.note,
  });

  final String tableLabel;
  final DateTime placedAt;
  final List<OrderConfirmationLine> lines;
  final Money estimatedTotal;
  final String? orderRef;
  final String? note;
}

class OrderConfirmationLine {
  OrderConfirmationLine({
    required this.name,
    required this.qty,
    required this.lineTotal,
    this.optionsLabel,
    this.note,
  });

  final String name;
  final num qty;
  final Money lineTotal;
  final String? optionsLabel;
  final String? note;
}

class EscPosConfirmationBuilder {
  EscPosConfirmationBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build(OrderConfirmation order, {String storeName = '點餐趣'}) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];
    final df = DateFormat('yyyy/MM/dd HH:mm');

    bytes.addAll(escText(gen, storeName,
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2)));
    bytes.addAll(escText(gen, '餐點確認單（非發票）',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(escText(gen, '=' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.row([
      escCol('桌號', width: 4),
      escCol(order.tableLabel, width: 8, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]));
    if (order.orderRef != null) {
      bytes.addAll(gen.row([
        escCol('單號', width: 4),
        escCol(order.orderRef!, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(gen.row([
      escCol('時間', width: 4),
      escCol(df.format(order.placedAt.toLocal()), width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));

    for (final ln in order.lines) {
      final label = ln.optionsLabel != null && ln.optionsLabel!.isNotEmpty
          ? '${ln.name} / ${ln.optionsLabel}'
          : ln.name;
      bytes.addAll(escText(gen, label));
      if (ln.note != null && ln.note!.isNotEmpty) {
        bytes.addAll(escText(gen, '  備註: ${ln.note}'));
      }
      bytes.addAll(gen.row([
        escCol('  ${ln.qty} x', width: 6),
        escCol(ln.lineTotal.format(withSymbol: true), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    bytes.addAll(escText(gen, '-' * 32, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.row([
      escCol('預估合計', width: 6, styles: const PosStyles(bold: true)),
      escCol(
        order.estimatedTotal.format(withSymbol: true),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));
    if (order.note != null && order.note!.isNotEmpty) {
      bytes.addAll(gen.feed(1));
      bytes.addAll(escText(gen, '備註: ${order.note}', styles: const PosStyles(bold: true)));
    }
    bytes.addAll(gen.feed(2));
    bytes.addAll(escText(gen, '請核對品項，結帳時以櫃台金額為準',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}

/// Taiwan e-invoice proof-of-purchase slip (證明聯).
class EscPosInvoiceBuilder {
  EscPosInvoiceBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build({
    required String storeName,
    String? storeTaxId,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required String randomCode,
    required Money total,
    String? buyerTaxId,
    String? barcode,
    String? qrLeft,
    String? qrRight,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];
    final local = invoiceDate.toLocal();
    final rocYear = local.year - 1911;
    final period = local.month.isOdd ? local.month : local.month - 1;
    final periodEnd = period + 1;
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');

    bytes.addAll(escText(gen, '電子發票證明聯',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    bytes.addAll(escText(gen, storeName, styles: const PosStyles(align: PosAlign.center)));
    if (storeTaxId != null && storeTaxId.isNotEmpty) {
      bytes.addAll(escText(gen, '賣方 $storeTaxId', styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(gen.feed(1));
    bytes.addAll(escText(
      gen,
      '$rocYear年${period.toString().padLeft(2, '0')}-${periodEnd.toString().padLeft(2, '0')}月',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(escText(gen, invoiceNumber,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    bytes.addAll(escText(gen, df.format(local), styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(escText(gen, '隨機碼 $randomCode', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(escText(gen, '總計 ${total.format(withSymbol: true)}',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    if (buyerTaxId != null && buyerTaxId.isNotEmpty) {
      bytes.addAll(escText(gen, '買方 $buyerTaxId', styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(gen.feed(1));
    if (barcode != null && barcode.isNotEmpty) {
      bytes.addAll(gen.barcode(Barcode.code128(barcode.split('')), width: 2, height: 60));
    }
    bytes.addAll(gen.feed(1));
    if (qrLeft != null && qrLeft.isNotEmpty) {
      bytes.addAll(gen.qrcode(qrLeft));
    }
    if (qrRight != null && qrRight.isNotEmpty) {
      bytes.addAll(gen.qrcode(qrRight));
    }
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());
    return bytes;
  }
}

/// One-time table ordering QR slip printed when seating a party.
class EscPosTableQrBuilder {
  EscPosTableQrBuilder({this.paperWidth = PaperSize.mm80});
  final PaperSize paperWidth;

  Future<List<int>> build({
    required String storeName,
    required String tableLabel,
    required String orderUrl,
    DateTime? expiresAt,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paperWidth, profile);
    final bytes = <int>[];
    final df = DateFormat('yyyy/MM/dd HH:mm');

    bytes.addAll(escText(gen, storeName,
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2)));
    bytes.addAll(escText(gen, '桌號 $tableLabel',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    bytes.addAll(gen.feed(1));
    bytes.addAll(escText(gen, '掃描 QR 點餐', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.qrcode(orderUrl, align: PosAlign.center));
    bytes.addAll(gen.feed(1));
    bytes.addAll(escText(gen, '請勿分享此 QR', styles: const PosStyles(align: PosAlign.center)));
    if (expiresAt != null) {
      bytes.addAll(escText(gen, '有效至 ${df.format(expiresAt.toLocal())}',
          styles: const PosStyles(align: PosAlign.center)));
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
