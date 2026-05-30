import 'package:intl/intl.dart';

import '../../data/database/app_database.dart';

/// Human-readable labels for local [OrderRow] list tiles (訂單記錄 / 退款).
class OrderListDisplay {
  const OrderListDisplay({
    required this.title,
    required this.subtitle,
    this.detail,
  });

  final String title;
  final String subtitle;
  final String? detail;

  factory OrderListDisplay.fromRow(OrderRow row) {
    final title = row.tableLabel != null && row.tableLabel!.isNotEmpty
        ? '桌 ${row.tableLabel}'
        : '櫃台';

    final parts = <String>[
      DateFormat('yyyy/MM/dd HH:mm').format(row.createdAt.toLocal()),
      orderStatusLabel(row.status),
    ];
    if (row.primaryPaymentMethod != null && row.primaryPaymentMethod!.isNotEmpty) {
      parts.add(paymentMethodLabel(row.primaryPaymentMethod!));
    }
    parts.add(row.syncedAt == null ? '未上傳' : '已上傳');

    final detailParts = <String>[];
    if (row.orderNo != null && row.orderNo!.isNotEmpty) {
      detailParts.add('單號 ${row.orderNo}');
    }
    if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
      detailParts.add('發票 ${row.invoiceNumber}');
    }

    return OrderListDisplay(
      title: title,
      subtitle: parts.join(' · '),
      detail: detailParts.isEmpty ? null : detailParts.join(' · '),
    );
  }

  /// Receipt / print reference when [orderNo] may not exist yet.
  static String receiptOrderRef({
    required DateTime createdAt,
    String? orderNo,
    String? tableLabel,
  }) {
    if (orderNo != null && orderNo.isNotEmpty) return orderNo;
    return DateFormat('yyyy/MM/dd HH:mm').format(createdAt.toLocal());
  }

  static String orderStatusLabel(String status) => switch (status) {
        'paid' => '已付款',
        'partially_refunded' => '部分退款',
        'refunded' => '已退款',
        'voided' => '作廢',
        'draft' => '草稿',
        _ => status,
      };

  static String paymentMethodLabel(String code) => switch (code) {
        'cash' => '現金',
        'credit_card' => '信用卡',
        'line_pay' => 'LINE Pay',
        'jko_pay' => '街口',
        'easy_wallet' => '悠遊付',
        _ => code,
      };
}

/// Group key for history list section headers.
enum OrderHistoryDayGroup { today, yesterday, earlier }

OrderHistoryDayGroup dayGroupFor(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final orderDay = DateTime(local.year, local.month, local.day);
  final diff = today.difference(orderDay).inDays;
  if (diff == 0) return OrderHistoryDayGroup.today;
  if (diff == 1) return OrderHistoryDayGroup.yesterday;
  return OrderHistoryDayGroup.earlier;
}

String dayGroupLabel(OrderHistoryDayGroup g) => switch (g) {
      OrderHistoryDayGroup.today => '今天',
      OrderHistoryDayGroup.yesterday => '昨天',
      OrderHistoryDayGroup.earlier => '更早',
    };
