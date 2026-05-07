import 'package:pos_core/pos_core.dart';
import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<Result<List<Product>>> search(String query, {String? categoryId, int limit = 50, int offset = 0});

  Future<Result<Product?>> findByBarcode(String barcode);
  Future<Result<Product?>> findById(String id);

  Stream<List<Product>> watchAll({String? categoryId});

  Future<Result<Product>> upsert(Product product);
  Future<Result<void>> delete(String id);

  /// Apply a server-pushed delta sync.
  Future<Result<int>> applyServerDelta(List<Product> products);
}
