import 'package:pos_core/pos_core.dart';
import '../entities/order.dart';
import '../entities/refund.dart';

abstract interface class OrderRepository {
  Future<Result<Order>> save(Order order);
  Future<Result<Order?>> findById(String id);
  Future<Result<List<Order>>> recent({int limit = 20, String? memberId, String? terminalId});
  Stream<List<Order>> watchUnsynced();

  Future<Result<Refund>> saveRefund(Refund refund);
  Future<Result<int>> markSynced(String orderId, DateTime at, {String? canonicalInvoiceNumber});
}
