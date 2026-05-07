import 'package:pos_core/pos_core.dart';
import '../entities/inventory.dart';

abstract interface class InventoryRepository {
  Future<Result<InventoryLevel?>> level(String storeId, String productId);
  Future<Result<List<InventoryLevel>>> levelsByStore(String storeId);
  Stream<List<InventoryLevel>> watchByStore(String storeId);
  Stream<List<InventoryLevel>> watchBelowSafety(String storeId);

  Future<Result<InventoryMovement>> recordMovement(InventoryMovement m);

  Future<Result<TransferOrder>> saveTransfer(TransferOrder t);
  Future<Result<TransferOrder>> updateTransferStatus(String id, TransferStatus status);

  Future<Result<StocktakeOrder>> saveStocktake(StocktakeOrder s);

  Future<Result<int>> applyLevelsDelta(List<InventoryLevel> levels);
}
