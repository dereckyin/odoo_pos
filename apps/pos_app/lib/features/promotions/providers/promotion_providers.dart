import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class PromotionRepositoryImpl {
  PromotionRepositoryImpl(this._db);
  final AppDatabase _db;

  Future<List<Promotion>> activeAt(DateTime t) async {
    final rows = await (_db.select(_db.promotions)
          ..where((p) =>
              p.deletedAt.isNull() &
              p.isActive.equals(true) &
              (p.startsAt.isNull() | p.startsAt.isSmallerOrEqualValue(t)) &
              (p.endsAt.isNull() | p.endsAt.isBiggerOrEqualValue(t))))
        .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  Stream<List<Promotion>> watchActive() {
    final t = DateTime.now();
    return (_db.select(_db.promotions)
          ..where((p) =>
              p.deletedAt.isNull() &
              p.isActive.equals(true) &
              (p.startsAt.isNull() | p.startsAt.isSmallerOrEqualValue(t)) &
              (p.endsAt.isNull() | p.endsAt.isBiggerOrEqualValue(t))))
        .watch()
        .map((rows) => rows.map(_toDomain).toList(growable: false));
  }

  Promotion _toDomain(dynamic r) => Promotion(
        id: r.id as String,
        name: r.name as String,
        strategy: PromotionStrategy.values.firstWhere(
          (s) => s.name == r.strategy,
          orElse: () => PromotionStrategy.manualDiscount,
        ),
        config: (jsonDecode(r.configJson as String) as Map).cast<String, dynamic>(),
        priority: r.priority as int,
        startsAt: r.startsAt as DateTime?,
        endsAt: r.endsAt as DateTime?,
        isActive: r.isActive as bool,
        stackable: r.stackable as bool,
        applicableProductIds: ((jsonDecode(r.applicableProductIdsJson as String) as List)).cast<String>(),
        applicableCategoryIds: ((jsonDecode(r.applicableCategoryIdsJson as String) as List)).cast<String>(),
        memberLevelIds: ((jsonDecode(r.memberLevelIdsJson as String) as List)).cast<String>(),
      );
}

final promotionRepositoryProvider = Provider<PromotionRepositoryImpl>(
  (ref) => PromotionRepositoryImpl(ref.read(databaseProvider)),
);

final promotionsListProvider = FutureProvider<List<Promotion>>((ref) async {
  return ref.read(promotionRepositoryProvider).activeAt(DateTime.now());
});

final activePromotionsStreamProvider = StreamProvider<List<Promotion>>((ref) {
  return ref.read(promotionRepositoryProvider).watchActive();
});
