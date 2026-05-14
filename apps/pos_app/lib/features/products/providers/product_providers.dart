import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../config/env.dart';
import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class ProductRepositoryImpl {
  ProductRepositoryImpl(this._db);
  final AppDatabase _db;

  /// Rows for the POS product grid: "全部" excludes [Product.hideFromPosBrowse] and
  /// products in categories with [Category.hideFromPosBrowse]. A specific [categoryId]
  /// lists every active product in that category (e.g. 書籍／桌遊).
  Future<List<ProductRow>> _browseProductRows({String? categoryId, int limit = 50}) async {
    if (categoryId != null) {
      return (_db.select(_db.products)
            ..where((p) =>
                p.deletedAt.isNull() & p.isActive.equals(true) & p.categoryId.equals(categoryId))
            ..orderBy([(p) => OrderingTerm(expression: p.name)])
            ..limit(limit))
          .get();
    }
    final q = _db.select(_db.products).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ])
      ..where(_db.products.deletedAt.isNull() &
          _db.products.isActive.equals(true) &
          _db.products.hideFromPosBrowse.equals(false) &
          (_db.products.categoryId.isNull() |
              _db.categories.id.isNull() |
              _db.categories.deletedAt.isNotNull() |
              _db.categories.hideFromPosBrowse.equals(false)))
      ..orderBy([OrderingTerm(expression: _db.products.name)])
      ..limit(limit);
    final joined = await q.get();
    return joined.map((r) => r.readTable(_db.products)).toList();
  }

  Future<List<Product>> search(String query, {String? categoryId, int limit = 50}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final rows = await _browseProductRows(categoryId: categoryId, limit: limit);
      return _hydrate(rows);
    }
    final like = '%$trimmed%';
    // Find barcode first (exact)
    final byBarcode = await (_db.select(_db.productBarcodes)..where((b) => b.barcode.equals(trimmed))).get();
    final productIds = byBarcode.map((e) => e.productId).toSet();

    final stmt = _db.select(_db.products)
      ..where((p) =>
          p.deletedAt.isNull() &
          p.isActive.equals(true) &
          (p.name.like(like) | p.sku.like(like) | p.id.isIn(productIds)));
    if (categoryId != null) {
      stmt.where((p) => p.categoryId.equals(categoryId));
    }
    stmt
      ..orderBy([(p) => OrderingTerm(expression: p.name)])
      ..limit(limit);
    final rows = await stmt.get();
    return _hydrate(rows);
  }

  Future<Product?> findByBarcode(String barcode) async {
    final bc = await (_db.select(_db.productBarcodes)..where((b) => b.barcode.equals(barcode))).getSingleOrNull();
    if (bc == null) return null;
    final p = await (_db.select(_db.products)..where((p) => p.id.equals(bc.productId))).getSingleOrNull();
    if (p == null) return null;
    return (await _hydrate([p])).first;
  }

  Future<Product?> findById(String id) async {
    final p = await (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (p == null) return null;
    return (await _hydrate([p])).first;
  }

  Stream<List<Product>> watchFiltered({
    String query = '',
    String? categoryId,
    int limit = 50,
  }) {
    final trimmed = query.trim();
    return _db.select(_db.products).watch().asyncMap((_) async {
      if (trimmed.isEmpty) {
        final rows = await _browseProductRows(categoryId: categoryId, limit: limit);
        return _hydrate(rows);
      }
      return search(trimmed, categoryId: categoryId, limit: limit);
    });
  }

  Future<List<Product>> _hydrate(List<ProductRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final barcodes =
        await (_db.select(_db.productBarcodes)..where((b) => b.productId.isIn(ids))).get();
    final byProduct = <String, List<String>>{};
    for (final b in barcodes) {
      byProduct.putIfAbsent(b.productId, () => []).add(b.barcode);
    }
    return rows
        .map((r) => Product(
              id: r.id,
              sku: r.sku,
              name: r.name,
              price: Money(r.priceCents),
              barcodes: byProduct[r.id] ?? const [],
              categoryId: r.categoryId,
              imageUrl: _resolveImageUrl(r.imageUrl),
              taxRate: r.taxRate,
              isWeighted: r.isWeighted,
              unit: r.unit,
              cost: r.costCents == null ? null : Money(r.costCents!),
              isActive: r.isActive,
              updatedAt: r.updatedAt,
              hideFromPublicOrdering: r.hideFromPublicOrdering,
              hideFromPosBrowse: r.hideFromPosBrowse,
            ))
        .toList(growable: false);
  }

  static String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${Env.apiBaseUrl}$url';
  }
}

final productRepositoryProvider = Provider<ProductRepositoryImpl>(
  (ref) => ProductRepositoryImpl(ref.read(databaseProvider)),
);

final productListProvider = StreamProvider.autoDispose
    .family<List<Product>, ({String query, String? categoryId})>((ref, args) {
  return ref
      .read(productRepositoryProvider)
      .watchFiltered(query: args.query, categoryId: args.categoryId);
});

final productSearchProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String query, String? categoryId})>((ref, args) {
  return ref.read(productRepositoryProvider).search(args.query, categoryId: args.categoryId);
});

class CategoryRepositoryImpl {
  CategoryRepositoryImpl(this._db);
  final AppDatabase _db;

  Future<List<Category>> all() async {
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .get();
    return rows
        .map((r) => Category(
              id: r.id,
              name: r.name,
              parentId: r.parentId,
              sortOrder: r.sortOrder,
              color: r.color,
              icon: r.icon,
              hideFromPublicOrdering: r.hideFromPublicOrdering,
              hideFromPosBrowse: r.hideFromPosBrowse,
            ))
        .toList(growable: false);
  }

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .watch()
        .map((rows) => rows
            .map((r) => Category(
                  id: r.id,
                  name: r.name,
                  parentId: r.parentId,
                  sortOrder: r.sortOrder,
                  color: r.color,
                  icon: r.icon,
                  hideFromPublicOrdering: r.hideFromPublicOrdering,
                  hideFromPosBrowse: r.hideFromPosBrowse,
                ))
            .toList(growable: false));
  }
}

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>(
  (ref) => CategoryRepositoryImpl(ref.read(databaseProvider)),
);

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).watchAll();
});
