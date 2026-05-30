import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_core/pos_core.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';
import '../models/held_cart_snapshot.dart';

const kMaxHeldCarts = 20;

class HeldCartSummary {
  const HeldCartSummary({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.lineCount,
    required this.totalCents,
    this.pendingGuestOrderId,
  });

  final String id;
  final String label;
  final DateTime createdAt;
  final int lineCount;
  final int totalCents;
  final String? pendingGuestOrderId;
}

class HeldCartRepository {
  HeldCartRepository(this._db);
  final AppDatabase _db;

  Stream<List<HeldCartSummary>> watchSummaries() {
    return (_db.select(_db.heldCarts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map(_rowsToSummaries);
  }

  Future<List<HeldCartSummary>> listSummaries() async {
    final rows = await (_db.select(_db.heldCarts)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return _rowsToSummaries(rows);
  }

  List<HeldCartSummary> _rowsToSummaries(List<HeldCartRow> rows) {
    return rows.map((r) {
      final snap = HeldCartSnapshot.decode(r.payload);
      var total = 0;
      for (final l in snap.lines) {
        total += (l.unitPriceCents * l.qty).round();
      }
      return HeldCartSummary(
        id: r.id,
        label: r.label,
        createdAt: r.createdAt,
        lineCount: snap.lines.length,
        totalCents: total,
        pendingGuestOrderId: r.pendingGuestOrderId,
      );
    }).toList();
  }

  Future<HeldCartSnapshot> loadSnapshot(String id) async {
    final row = await (_db.select(_db.heldCarts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('held cart not found');
    return HeldCartSnapshot.decode(row.payload);
  }

  Future<String> insert({
    required String label,
    required HeldCartSnapshot snapshot,
    String? pendingGuestOrderId,
  }) async {
    final count = await _db.select(_db.heldCarts).get();
    if (count.length >= kMaxHeldCarts) {
      throw StateError('掛單已達上限（$kMaxHeldCarts 筆）');
    }
    final id = newUuid();
    await _db.into(_db.heldCarts).insert(
          HeldCartsCompanion.insert(
            id: id,
            label: label,
            payload: snapshot.encode(),
            pendingGuestOrderId: Value(pendingGuestOrderId),
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.heldCarts)..where((t) => t.id.equals(id))).go();
  }
}

final heldCartRepositoryProvider = Provider<HeldCartRepository>(
  (ref) => HeldCartRepository(ref.read(databaseProvider)),
);

final heldCartSummariesProvider = StreamProvider<List<HeldCartSummary>>((ref) {
  return ref.read(heldCartRepositoryProvider).watchSummaries();
});
