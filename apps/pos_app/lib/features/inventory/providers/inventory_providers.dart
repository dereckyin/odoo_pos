import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class InventoryRow {
  InventoryRow({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.onHand,
    required this.safetyStock,
  });
  final String productId, productName, sku;
  final double onHand, safetyStock;
  bool get belowSafety => onHand <= safetyStock;
}

final inventoryListProvider = StreamProvider.autoDispose.family<List<InventoryRow>, String>((ref, storeId) {
  final db = ref.read(databaseProvider);

  final query = db.select(db.inventoryLevels).join([
    leftOuterJoin(db.products, db.products.id.equalsExp(db.inventoryLevels.productId)),
  ])
    ..where(db.inventoryLevels.storeId.equals(storeId))
    ..orderBy([OrderingTerm(expression: db.products.name)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      final lv = row.readTable(db.inventoryLevels);
      final p = row.readTableOrNull(db.products);
      return InventoryRow(
        productId: lv.productId,
        productName: p?.name ?? lv.productId,
        sku: p?.sku ?? '',
        onHand: lv.onHand,
        safetyStock: lv.safetyStock,
      );
    }).toList();
  });
});
