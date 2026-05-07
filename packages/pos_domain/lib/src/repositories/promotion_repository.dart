import 'package:pos_core/pos_core.dart';
import '../entities/promotion.dart';

abstract interface class PromotionRepository {
  Future<Result<List<Promotion>>> activeAt(DateTime t);
  Stream<List<Promotion>> watchActive();
  Future<Result<Promotion>> upsert(Promotion promo);
  Future<Result<void>> delete(String id);
  Future<Result<int>> applyServerDelta(List<Promotion> promos);
}
