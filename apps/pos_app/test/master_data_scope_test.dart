import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/database/app_database.dart';
import 'package:pos_app/data/sync/delta_puller.dart';
import 'package:pos_app/data/sync/master_data_scope.dart';

void main() {
  late AppDatabase db;
  late MasterDataScopeStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = MasterDataScopeStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('unchanged scope keeps master data and sync cursors', () async {
    await store.applySessionScope(tenantId: 'tenant-a', storeId: 'store-a');
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: 'p1',
            sku: 'SKU-1',
            name: 'Tea',
            updatedAt: DateTime.utc(2026),
          ),
        );
    await db.setMeta('sync.since.products', DateTime.utc(2026, 1, 2).toIso8601String());

    expect(await store.applySessionScope(tenantId: 'tenant-a', storeId: 'store-a'), isFalse);

    expect(await (db.select(db.products)).get(), hasLength(1));
    expect(await db.getMeta('sync.since.products'), isNotNull);
  });

  test('scope change clears master data and sync cursors', () async {
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: 'p1',
            sku: 'SKU-1',
            name: 'Tea',
            updatedAt: DateTime.utc(2026),
          ),
        );
    await db.setMeta('sync.since.products', DateTime.utc(2026, 1, 2).toIso8601String());
    await store.applySessionScope(tenantId: 'tenant-a', storeId: 'store-a');

    expect(await store.applySessionScope(tenantId: 'tenant-b', storeId: 'store-b'), isTrue);

    expect(await (db.select(db.products)).get(), isEmpty);
    expect(await db.getMeta('sync.since.products'), isNull);
    final scope = await store.readScope();
    expect(scope?.tenantId, 'tenant-b');
    expect(scope?.storeId, 'store-b');
  });

  test('clearMasterData keeps orders and sync queue', () async {
    final now = DateTime.utc(2026, 5, 12);
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: 'p1',
            sku: 'SKU-1',
            name: 'Tea',
            updatedAt: now,
          ),
        );
    await db.into(db.orders).insert(
          OrdersCompanion.insert(
            id: 'o1',
            storeId: 'store-a',
            terminalId: 'terminal-a',
            cashierId: 'cashier-a',
            createdAt: now,
          ),
        );
    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'q1',
            op: 'upload_order',
            payloadJson: '{}',
            nextRetryAt: now,
            createdAt: now,
          ),
        );

    await db.clearMasterData();

    expect(await (db.select(db.products)).get(), isEmpty);
    expect(await (db.select(db.orders)).get(), hasLength(1));
    expect(await (db.select(db.syncQueue)).get(), hasLength(1));
  });

  test('delta pull result reports failures', () {
    const result = DeltaPullResult(failures: {'products': 'offline'});
    expect(result.isSuccess, isFalse);
    expect(result.summary, contains('products'));
  });
}
