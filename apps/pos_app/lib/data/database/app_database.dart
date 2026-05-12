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
  KvMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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
