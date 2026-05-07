import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import 'sync_models.dart';

class SyncQueueDao {
  SyncQueueDao(this.db);
  final AppDatabase db;

  Future<void> enqueue(SyncOpKind op, Map<String, dynamic> payload) async {
    final id = newUuid();
    final now = DateTime.now();
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          id: id,
          op: op.code,
          payloadJson: jsonEncode(payload),
          nextRetryAt: now,
          createdAt: now,
        ));
  }

  Future<List<SyncQueueRow>> dueEntries({int limit = 50}) async {
    final now = DateTime.now();
    return (db.select(db.syncQueue)
          ..where((t) => t.nextRetryAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> pendingCount() async {
    final row = await db.customSelect('SELECT COUNT(*) AS c FROM sync_queue').getSingle();
    return row.read<int>('c');
  }

  Future<void> markRetry(String id, int retries, String? error) async {
    final next = DateTime.now().add(RetryPolicy.nextBackoff(retries));
    await (db.update(db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(retries: Value(retries), nextRetryAt: Value(next), lastError: Value(error)),
    );
  }

  Future<void> remove(String id) async {
    await (db.delete(db.syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Stream<int> watchPending() => db
      .customSelect('SELECT COUNT(*) AS c FROM sync_queue', readsFrom: {db.syncQueue})
      .watchSingle()
      .map((r) => r.read<int>('c'));
}
