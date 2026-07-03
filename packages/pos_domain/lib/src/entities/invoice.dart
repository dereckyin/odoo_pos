import 'package:pos_core/pos_core.dart';

enum InvoiceStatus { pending, issued, voided, allowance, failed }

enum InvoiceCarrierType {
  /// 一般雲端發票（買受人未提供載具）
  none,
  /// 手機條碼 (eg. /ABC1234)
  mobile,
  /// 自然人憑證
  citizenDigital,
  /// 會員載具（廠商自有）
  member,
}

class InvoiceCarrier {
  const InvoiceCarrier({required this.type, this.code});
  final InvoiceCarrierType type;
  final String? code;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.tax,
    required this.taxType,
    this.invoiceNumber,
    this.invoiceDate,
    this.carrier,
    this.taxId,
    this.companyName,
    this.donationCode,
    this.gatewayRef,
    this.lastError,
    this.randomCode,
    this.barcode,
    this.qrLeft,
    this.qrRight,
  });

  final String id;
  final String orderId;
  final InvoiceStatus status;
  final Money totalAmount;
  final Money tax;
  /// 1 應稅, 2 零稅率, 3 免稅
  final int taxType;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final InvoiceCarrier? carrier;
  final String? taxId;
  final String? companyName;
  final String? donationCode;
  final String? gatewayRef;
  final String? lastError;
  final String? randomCode;
  final String? barcode;
  final String? qrLeft;
  final String? qrRight;
}
