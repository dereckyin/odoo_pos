import 'package:pos_core/pos_core.dart';
import '../entities/invoice.dart';
import '../entities/order.dart';

class IssueInvoiceRequest {
  const IssueInvoiceRequest({
    required this.order,
    required this.taxType,
    this.carrier,
    this.taxId,
    this.companyName,
    this.donationCode,
    this.email,
  });

  final Order order;
  final int taxType;
  final InvoiceCarrier? carrier;
  final String? taxId;
  final String? companyName;
  final String? donationCode;
  final String? email;
}

class VoidInvoiceRequest {
  const VoidInvoiceRequest({required this.invoice, this.reason});
  final Invoice invoice;
  final String? reason;
}

class AllowanceRequest {
  const AllowanceRequest({
    required this.invoice,
    required this.amount,
    required this.reason,
  });
  final Invoice invoice;
  final Money amount;
  final String reason;
}

abstract interface class InvoiceGateway {
  String get name;
  Future<Result<Invoice>> issue(IssueInvoiceRequest req);
  Future<Result<Invoice>> voidInvoice(VoidInvoiceRequest req);
  Future<Result<Invoice>> allowance(AllowanceRequest req);
}
