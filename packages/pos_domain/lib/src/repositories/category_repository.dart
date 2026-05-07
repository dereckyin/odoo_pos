import 'package:pos_core/pos_core.dart';
import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<Result<List<Category>>> all();
  Stream<List<Category>> watchAll();
  Future<Result<Category>> upsert(Category cat);
  Future<Result<void>> delete(String id);
  Future<Result<int>> applyServerDelta(List<Category> cats);
}
