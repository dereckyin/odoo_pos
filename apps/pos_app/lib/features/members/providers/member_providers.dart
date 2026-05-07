import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_domain/pos_domain.dart';

import '../../../core/providers.dart';
import '../../../data/database/app_database.dart';

class MemberRepositoryImpl {
  MemberRepositoryImpl(this._db);
  final AppDatabase _db;

  Future<Member?> findByPhone(String phone) async {
    final r =
        await (_db.select(_db.members)..where((m) => m.phone.equals(phone) & m.deletedAt.isNull()))
            .getSingleOrNull();
    if (r == null) return null;
    return _withLevel(r);
  }

  Future<Member?> findByQr(String qr) async {
    final r = await (_db.select(_db.members)..where((m) => m.qrCode.equals(qr))).getSingleOrNull();
    if (r == null) return null;
    return _withLevel(r);
  }

  Future<Member?> findById(String id) async {
    final r = await (_db.select(_db.members)..where((m) => m.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    return _withLevel(r);
  }

  Future<List<Member>> search(String query, {int limit = 30}) async {
    final like = '%$query%';
    final stmt = _db.select(_db.members)
      ..where((m) => m.deletedAt.isNull() & (m.phone.like(like) | m.name.like(like)))
      ..orderBy([(m) => OrderingTerm(expression: m.lastVisitAt, mode: OrderingMode.desc)])
      ..limit(limit);
    final rows = await stmt.get();
    return Future.wait(rows.map(_withLevel));
  }

  Future<MemberLevel?> _level(String? id) async {
    if (id == null) return null;
    final r =
        await (_db.select(_db.memberLevels)..where((l) => l.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    return MemberLevel(
      id: r.id,
      name: r.name,
      discountRate: r.discountRate,
      minSpend: r.minSpend,
      minPoints: r.minPoints,
      color: r.color,
    );
  }

  Future<Member> _withLevel(dynamic r) async {
    final lvl = await _level(r.levelId as String?);
    return Member(
      id: r.id as String,
      phone: r.phone as String,
      name: r.name as String,
      email: r.email as String?,
      birthday: r.birthday as DateTime?,
      points: r.points as int,
      totalSpentMajor: (r.totalSpentCents as int) / 1.0,
      level: lvl,
      qrCode: r.qrCode as String?,
      joinedAt: r.joinedAt as DateTime,
      lastVisitAt: r.lastVisitAt as DateTime?,
      note: r.note as String?,
    );
  }
}

final memberRepositoryProvider = Provider<MemberRepositoryImpl>(
  (ref) => MemberRepositoryImpl(ref.read(databaseProvider)),
);

final memberSearchProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, q) => ref.read(memberRepositoryProvider).search(q));
