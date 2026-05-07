import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';

import '../api/pos_api.dart';
import '../database/app_database.dart';

/// Pulls master data changes (products, categories, members, levels, promotions,
/// inventory levels) from the server and upserts them into the local DB.
///
/// Runs automatically on a periodic timer (default 30s) and reacts to
/// connectivity changes, so backend edits (product images, prices, etc.)
/// propagate to the app without restart.
class DeltaPuller {
  DeltaPuller({required this.db, required this.api, required this.logger});

  final AppDatabase db;
  final PosApi api;
  final AppLogger logger;

  static final DateTime _epoch = DateTime.utc(1970);

  Timer? _ticker;
  StreamSubscription? _connSub;
  bool _running = false;
  String? _storeId;
  DateTime? _lastPullAt;

  final _statusCtrl = StreamController<DeltaPullStatus>.broadcast();
  Stream<DeltaPullStatus> get status => _statusCtrl.stream;
  DateTime? get lastPullAt => _lastPullAt;

  /// Start periodic delta pull (every [interval]).
  /// Call once after login; safe to call multiple times.
  void start({String? storeId, Duration interval = const Duration(seconds: 30)}) {
    _storeId = storeId;
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) => pullAll());
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      if (event.any((c) => c != ConnectivityResult.none)) {
        pullAll();
      }
    });
    // Immediate first pull
    pullAll();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _connSub?.cancel();
    _connSub = null;
  }

  Future<void> pullAll({String? storeId}) async {
    if (_running) return;
    _running = true;
    final sid = storeId ?? _storeId;
    _emit(DeltaPullState.syncing);
    try {
      await Future.wait([
        _pull('products', () => _pullProducts()),
        _pull('categories', () => _pullCategories()),
        _pull('members', () => _pullMembers()),
        _pull('member_levels', () => _pullMemberLevels()),
        _pull('promotions', () => _pullPromotions()),
        _pull('inventory_levels', () => _pullInventory(storeId: sid)),
      ]);
      _lastPullAt = DateTime.now();
      _emit(DeltaPullState.idle);
    } catch (e) {
      _emit(DeltaPullState.error, error: e.toString());
    } finally {
      _running = false;
    }
  }

  Future<void> _pull(String name, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      logger.warn('delta pull $name failed', e, st);
    }
  }

  void _emit(DeltaPullState state, {String? error}) {
    if (_statusCtrl.isClosed) return;
    _statusCtrl.add(DeltaPullStatus(state: state, lastPullAt: _lastPullAt, error: error));
  }

  Future<DateTime> _readSince(String key) async {
    final s = await db.getMeta('sync.since.$key');
    return s == null ? _epoch : DateTime.parse(s);
  }

  Future<void> _writeSince(String key, DateTime t) =>
      db.setMeta('sync.since.$key', t.toUtc().toIso8601String());

  Future<void> _pullProducts() async {
    final since = await _readSince('products');
    final page = await api.syncProducts(since);
    if (page.items.isEmpty) {
      await _writeSince('products', page.serverTime);
      return;
    }
    await db.batch((b) {
      for (final p in page.items) {
        b.insert(
          db.products,
          ProductsCompanion(
            id: Value(p.id),
            sku: Value(p.sku),
            name: Value(p.name),
            priceCents: Value(p.priceCents),
            costCents: Value(p.costCents),
            categoryId: Value(p.categoryId),
            imageUrl: Value(p.imageUrl),
            taxRate: Value(p.taxRate),
            isWeighted: Value(p.isWeighted),
            unit: Value(p.unit),
            isActive: Value(p.isActive),
            description: Value(p.description),
            updatedAt: Value(p.updatedAt),
            deletedAt: Value(p.deletedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
        // refresh barcodes
        b.deleteWhere(db.productBarcodes, (t) => t.productId.equals(p.id));
        for (final code in p.barcodes) {
          b.insert(
            db.productBarcodes,
            ProductBarcodesCompanion(productId: Value(p.id), barcode: Value(code)),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
    await _writeSince('products', page.nextSince);
    if (page.items.length >= 500) {
      await _pullProducts(); // continue
    }
  }

  Future<void> _pullCategories() async {
    final since = await _readSince('categories');
    final page = await api.syncCategories(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final c in page.items) {
          b.insert(
            db.categories,
            CategoriesCompanion(
              id: Value(c.id),
              name: Value(c.name),
              parentId: Value(c.parentId),
              sortOrder: Value(c.sortOrder),
              color: Value(c.color),
              icon: Value(c.icon),
              updatedAt: Value(c.updatedAt),
              deletedAt: Value(c.deletedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('categories', page.nextSince);
  }

  Future<void> _pullMembers() async {
    final since = await _readSince('members');
    final page = await api.syncMembers(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final m in page.items) {
          b.insert(
            db.members,
            MembersCompanion(
              id: Value(m.id),
              phone: Value(m.phone),
              name: Value(m.name),
              email: Value(m.email),
              birthday: Value(m.birthday),
              points: Value(m.points),
              totalSpentCents: Value(m.totalSpentCents),
              levelId: Value(m.levelId),
              qrCode: Value(m.qrCode),
              joinedAt: Value(m.joinedAt),
              lastVisitAt: Value(m.lastVisitAt),
              note: Value(m.note),
              updatedAt: Value(m.updatedAt),
              deletedAt: Value(m.deletedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('members', page.nextSince);
  }

  Future<void> _pullMemberLevels() async {
    final since = await _readSince('member_levels');
    final page = await api.syncMemberLevels(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final lvl in page.items) {
          b.insert(
            db.memberLevels,
            MemberLevelsCompanion(
              id: Value(lvl.id),
              name: Value(lvl.name),
              discountRate: Value(lvl.discountRate),
              minSpend: Value(lvl.minSpend),
              minPoints: Value(lvl.minPoints),
              color: Value(lvl.color),
              sortOrder: Value(lvl.sortOrder),
              updatedAt: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('member_levels', page.nextSince);
  }

  Future<void> _pullPromotions() async {
    final since = await _readSince('promotions');
    final page = await api.syncPromotions(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final p in page.items) {
          b.insert(
            db.promotions,
            PromotionsCompanion(
              id: Value(p.id),
              name: Value(p.name),
              strategy: Value(p.strategy),
              configJson: Value(jsonEncode(p.config)),
              priority: Value(p.priority),
              startsAt: Value(p.startsAt),
              endsAt: Value(p.endsAt),
              isActive: Value(p.isActive),
              stackable: Value(p.stackable),
              applicableProductIdsJson: Value(jsonEncode(p.applicableProductIds)),
              applicableCategoryIdsJson: Value(jsonEncode(p.applicableCategoryIds)),
              memberLevelIdsJson: Value(jsonEncode(p.memberLevelIds)),
              description: Value(p.description),
              updatedAt: Value(p.updatedAt),
              deletedAt: Value(p.deletedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('promotions', page.nextSince);
  }

  Future<void> _pullInventory({String? storeId}) async {
    final since = await _readSince('inventory_levels');
    final page = await api.syncInventory(since, storeId: storeId);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final lv in page.items) {
          b.insert(
            db.inventoryLevels,
            InventoryLevelsCompanion(
              id: Value(lv.id),
              storeId: Value(lv.storeId),
              productId: Value(lv.productId),
              onHand: Value(lv.onHand),
              safetyStock: Value(lv.safetyStock),
              reserved: Value(lv.reserved),
              updatedAt: Value(lv.updatedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('inventory_levels', page.nextSince);
  }
}

enum DeltaPullState { idle, syncing, error }

class DeltaPullStatus {
  const DeltaPullStatus({required this.state, this.lastPullAt, this.error});
  final DeltaPullState state;
  final DateTime? lastPullAt;
  final String? error;
}
