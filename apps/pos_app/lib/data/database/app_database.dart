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
  int get schemaVersion => 5;

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
            await m.addColumn(orders, orders.orderNo);
            await m.addColumn(orders, orders.tableLabel);
            await m.addColumn(orders, orders.primaryPaymentMethod);
            await m.addColumn(orders, orders.sourceGuestOrderId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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
