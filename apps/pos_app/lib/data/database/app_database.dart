import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../config/env.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Stores,
  Terminals,
  Categories,
  Products,
  BookDetails,
  ProductBarcodes,
  OptionGroups,
  OptionChoices,
  ProductOptionGroups,
  ProductOptionChoiceOverrides,
  MemberLevels,
  Members,
  Coupons,
  PointTransactions,
  Orders,
  OrderLines,
  Payments,
  Refunds,
  RefundLines,
  InventoryLevels,
  InventoryMovements,
  TransferOrders,
  TransferLines,
  Stocktakes,
  StocktakeLines,
  Promotions,
  Invoices,
  SyncQueue,
  HeldCarts,
  KvMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.hideFromPublicOrdering);
            await m.addColumn(categories, categories.hideFromPosBrowse);
            await m.addColumn(products, products.hideFromPublicOrdering);
            await m.addColumn(products, products.hideFromPosBrowse);
          }
          if (from < 3) {
            await m.createTable(optionGroups);
            await m.createTable(optionChoices);
            await m.createTable(productOptionGroups);
            await m.createTable(productOptionChoiceOverrides);
            await m.addColumn(orderLines, orderLines.optionsJson);
          }
          if (from < 4) {
            await m.createTable(heldCarts);
          }
          if (from < 5) {
            await _addColumnIfMissing(m, orders, orders.orderNo);
            await _addColumnIfMissing(m, orders, orders.tableLabel);
            await _addColumnIfMissing(m, orders, orders.primaryPaymentMethod);
            await _addColumnIfMissing(m, orders, orders.sourceGuestOrderId);
          }
          if (from < 6) {
            await _addColumnIfMissing(m, products, products.productKind);
            await m.createTable(bookDetails);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// SQLite has no IF NOT EXISTS for ADD COLUMN; skip when a partial upgrade
  /// already created the column (e.g. app crash mid-migration).
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final tableName = table.actualTableName;
    final columnName = column.name;
    final rows = await customSelect(
      "SELECT 1 AS ok FROM pragma_table_info('$tableName') WHERE name = ?",
      variables: [Variable.withString(columnName)],
      readsFrom: {table},
    ).get();
    if (rows.isEmpty) {
      await m.addColumn(table, column);
    }
  }

  Future<String?> getMeta(String key) async {
    final row = await (select(kvMeta)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) async {
    await into(kvMeta).insertOnConflictUpdate(KvMetaCompanion.insert(key: key, value: Value(value)));
  }

  Future<void> clearMasterData() async {
    await transaction(() async {
      await delete(productOptionChoiceOverrides).go();
      await delete(productOptionGroups).go();
      await delete(optionChoices).go();
      await delete(optionGroups).go();
      await delete(productBarcodes).go();
      await delete(bookDetails).go();
      await delete(products).go();
      await delete(categories).go();
      await delete(memberLevels).go();
      await delete(members).go();
      await delete(promotions).go();
      await delete(inventoryLevels).go();
      await (delete(kvMeta)..where((t) => t.key.like('sync.since.%'))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, Env.localDbFile));
    return NativeDatabase.createInBackground(file);
  });
}
