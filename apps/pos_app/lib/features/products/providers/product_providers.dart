import 'dart:async';

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
  Future<List<Category>> _loadEnrichedCategories() async {
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull()))
        .get();
    final flat = rows
        .map((r) => Category(
              id: r.id,
              name: r.name,
              parentId: r.parentId,
              sortOrder: r.sortOrder,
              color: r.color,
              icon: r.icon,
              hideFromPublicOrdering: r.hideFromPublicOrdering,
              hideFromPosBrowse: r.hideFromPosBrowse,
              memberDiscountEligible: r.memberDiscountEligible,
              pointsEarnEligible: r.pointsEarnEligible,
              pointsRedeemEligible: r.pointsRedeemEligible,
            ))
        .toList(growable: false);
    return enrichCategories(flat);
  }

  Future<List<ProductRow>> _browseProductRows({String? categoryId, int limit = 50}) async {
    if (categoryId != null) {
      final cats = await _loadEnrichedCategories();
      final tree = CategoryTree(cats);
      final ids = tree.descendantIds(categoryId).toList();
      final rows = await (_db.select(_db.products)
            ..where((p) =>
                p.deletedAt.isNull() &
                p.isActive.equals(true) &
                p.categoryId.isIn(ids))
            ..orderBy([(p) => OrderingTerm(expression: p.name)])
            ..limit(limit))
          .get();
      return rows.where((p) => !tree.isHiddenByAncestor(p.categoryId)).toList();
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
      final cats = await _loadEnrichedCategories();
      final tree = CategoryTree(cats);
      final ids = tree.descendantIds(categoryId).toList();
      stmt.where((p) => p.categoryId.isIn(ids));
    }
    stmt
      ..orderBy([(p) => OrderingTerm(expression: p.name)])
      ..limit(limit);
    final rows = await stmt.get();
    if (categoryId != null) {
      final cats = await _loadEnrichedCategories();
      final tree = CategoryTree(cats);
      final filtered = rows.where((p) => !tree.isHiddenByAncestor(p.categoryId)).toList();
      return _hydrate(filtered);
    }
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

  /// Emits when products or any option-link tables change (options sync does not
  /// touch [Products], so watching products alone leaves [Product.hasOptions] stale).
  Stream<void> _catalogChangeTicks() {
    return Stream<void>.multi((controller) {
      final subs = <StreamSubscription<dynamic>>[];
      void tick(_) {
        if (!controller.isClosed) controller.add(null);
      }
      subs.add(_db.select(_db.products).watch().listen(tick));
      subs.add(_db.select(_db.productOptionGroups).watch().listen(tick));
      subs.add(_db.select(_db.optionGroups).watch().listen(tick));
      subs.add(_db.select(_db.optionChoices).watch().listen(tick));
      subs.add(_db.select(_db.productOptionChoiceOverrides).watch().listen(tick));
      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    });
  }

  Stream<List<Product>> watchFiltered({
    String query = '',
    String? categoryId,
    int limit = 50,
  }) {
    final trimmed = query.trim();
    return _catalogChangeTicks().asyncMap((_) async {
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
    final optionConfigs = await _loadOptionConfigs(ids);
    final bookRows =
        await (_db.select(_db.bookDetails)..where((b) => b.productId.isIn(ids))).get();
    final authorByProduct = {for (final b in bookRows) b.productId: b.author};
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
              productKind: r.productKind,
              memberDiscountEligible: r.memberDiscountEligible,
              pointsEarnEligible: r.pointsEarnEligible,
              pointsRedeemEligible: r.pointsRedeemEligible,
              bookAuthor: authorByProduct[r.id],
              optionConfigs: optionConfigs[r.id] ?? const [],
            ))
        .toList(growable: false);
  }

  Future<List<Product>> searchConsignmentBooks(String query, {int limit = 50}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final like = '%$trimmed%';
    final byBarcode = await (_db.select(_db.productBarcodes)..where((b) => b.barcode.equals(trimmed))).get();
    final productIds = byBarcode.map((e) => e.productId).toSet();

    final stmt = _db.select(_db.products).join([
      innerJoin(_db.bookDetails, _db.bookDetails.productId.equalsExp(_db.products.id)),
    ])
      ..where(_db.products.deletedAt.isNull() &
          _db.products.isActive.equals(true) &
          _db.products.productKind.equals('consignment_book') &
          (_db.products.name.like(like) |
              _db.products.sku.like(like) |
              _db.bookDetails.author.like(like) |
              _db.bookDetails.barcode.like(like) |
              _db.products.id.isIn(productIds)))
      ..orderBy([OrderingTerm(expression: _db.products.name)])
      ..limit(limit);
    final joined = await stmt.get();
    final rows = joined.map((r) => r.readTable(_db.products)).toList();
    return _hydrate(rows);
  }

  Future<Map<String, List<ProductOptionConfig>>> _loadOptionConfigs(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};

    final links = await (_db.select(_db.productOptionGroups)
          ..where((l) => l.productId.isIn(productIds))
          ..orderBy([(l) => OrderingTerm(expression: l.sortOrder)]))
        .get();
    if (links.isEmpty) return {};

    final groupIds = links.map((l) => l.optionGroupId).toSet().toList();
    final groups = await (_db.select(_db.optionGroups)
          ..where((g) => g.id.isIn(groupIds) & g.deletedAt.isNull()))
        .get();
    final groupById = {for (final g in groups) g.id: g};

    final choices = await (_db.select(_db.optionChoices)
          ..where((c) => c.optionGroupId.isIn(groupIds) & c.deletedAt.isNull()))
        .get();
    final choicesByGroup = <String, List<OptionChoiceRow>>{};
    for (final c in choices) {
      choicesByGroup.putIfAbsent(c.optionGroupId, () => []).add(c);
    }

    final overrides = await (_db.select(_db.productOptionChoiceOverrides)
          ..where((o) => o.productId.isIn(productIds)))
        .get();
    final overrideMap = <String, Map<String, ProductOptionChoiceOverrideRow>>{};
    for (final o in overrides) {
      overrideMap.putIfAbsent(o.productId, () => {})[o.optionChoiceId] = o;
    }

    final result = <String, List<ProductOptionConfig>>{};
    for (final link in links) {
      final gRow = groupById[link.optionGroupId];
      if (gRow == null) continue;
      final productOverrides = overrideMap[link.productId] ?? {};
      final visibleChoices = <OptionChoice>[];
      for (final c in choicesByGroup[gRow.id] ?? const []) {
        if (!c.isActive) continue;
        final ov = productOverrides[c.id];
        if (ov?.isHidden == true) continue;
        final price = ov?.priceDeltaCents ?? c.priceDeltaCents;
        visibleChoices.add(OptionChoice(
          id: c.id,
          name: c.name,
          priceDeltaCents: price,
          isDefault: c.isDefault,
          sortOrder: c.sortOrder,
        ));
      }
      visibleChoices.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (visibleChoices.isEmpty) continue;

      final group = OptionGroup(
        id: gRow.id,
        name: gRow.name,
        selectionType: gRow.selectionType,
        isRequired: link.isRequired ?? gRow.isRequired,
        minSelections: gRow.minSelections,
        maxSelections: gRow.maxSelections,
        sortOrder: link.sortOrder,
        choices: visibleChoices,
      );
      result.putIfAbsent(link.productId, () => []).add(
            ProductOptionConfig(
              group: group,
              isRequired: group.isRequired,
              sortOrder: link.sortOrder,
            ),
          );
    }
    for (final configs in result.values) {
      configs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return result;
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
    final flat = rows
        .map((r) => Category(
              id: r.id,
              name: r.name,
              parentId: r.parentId,
              sortOrder: r.sortOrder,
              color: r.color,
              icon: r.icon,
              hideFromPublicOrdering: r.hideFromPublicOrdering,
              hideFromPosBrowse: r.hideFromPosBrowse,
              memberDiscountEligible: r.memberDiscountEligible,
              pointsEarnEligible: r.pointsEarnEligible,
              pointsRedeemEligible: r.pointsRedeemEligible,
            ))
        .toList(growable: false);
    return enrichCategories(flat);
  }

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .watch()
        .asyncMap((rows) async {
          final flat = rows
              .map((r) => Category(
                    id: r.id,
                    name: r.name,
                    parentId: r.parentId,
                    sortOrder: r.sortOrder,
                    color: r.color,
                    icon: r.icon,
                    hideFromPublicOrdering: r.hideFromPublicOrdering,
                    hideFromPosBrowse: r.hideFromPosBrowse,
                    memberDiscountEligible: r.memberDiscountEligible,
                    pointsEarnEligible: r.pointsEarnEligible,
                    pointsRedeemEligible: r.pointsRedeemEligible,
                  ))
              .toList(growable: false);
          return enrichCategories(flat);
        });
  }
}

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>(
  (ref) => CategoryRepositoryImpl(ref.read(databaseProvider)),
);

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).watchAll();
});

final categoryTreeProvider = Provider<CategoryTree>((ref) {
  final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
  return CategoryTree(cats);
});
