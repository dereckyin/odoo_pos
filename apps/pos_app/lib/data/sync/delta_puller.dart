import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:pos_core/pos_core.dart';

import '../api/pos_api.dart';
import '../database/app_database.dart';

/// Pulls master data changes (products, categories, members, levels, promotions,
/// inventory levels) from the server and upserts them into the local DB.
class DeltaPuller {
  DeltaPuller({required this.db, required this.api, required this.logger});

  final AppDatabase db;
  final PosApi api;
  final AppLogger logger;

  static final DateTime _epoch = DateTime.utc(1970);

  Timer? _ticker;
  StreamSubscription? _connSub;
  bool _started = false;
  String? _storeId;
  DateTime? _lastPullAt;
  Future<DeltaPullResult>? _pullInFlight;

  final _statusCtrl = StreamController<DeltaPullStatus>.broadcast();
  Stream<DeltaPullStatus> get status => _statusCtrl.stream;
  DateTime? get lastPullAt => _lastPullAt;

  void startAfterLogin({String? storeId, Duration interval = const Duration(seconds: 30)}) {
    if (_started && _storeId == storeId) return;
    _storeId = storeId;
    _started = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) => unawaited(pullAll()));
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((event) {
      if (event.any((c) => c != ConnectivityResult.none)) {
        unawaited(pullAll());
      }
    });
    unawaited(pullAll());
  }

  Future<void> stop() async {
    _started = false;
    _ticker?.cancel();
    _ticker = null;
    await _connSub?.cancel();
    _connSub = null;
    await _statusCtrl.close();
  }

  Future<DeltaPullResult> pullAll({
    String? storeId,
    bool forceFullResync = false,
  }) async {
    if (_pullInFlight != null && !forceFullResync) {
      return _pullInFlight!;
    }

    final future = _runPullAll(storeId: storeId, forceFullResync: forceFullResync);
    _pullInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_pullInFlight, future)) {
        _pullInFlight = null;
      }
    }
  }

  Future<DeltaPullResult> _runPullAll({
    required String? storeId,
    required bool forceFullResync,
  }) async {
    final sid = storeId ?? _storeId;
    _emit(DeltaPullState.syncing);
    if (forceFullResync) {
      await db.clearMasterData();
    }

    final failures = <String, String>{};
    // Options must land before the cashier hydrates products (parallel pull used to
    // finish products first while links/groups were still empty).
    await _pull('option_groups', failures, _pullOptionGroups);
    await _pull('product_option_links', failures, _pullProductOptionLinks);
    await _pull('product_option_overrides', failures, _pullProductOptionOverrides);
    await Future.wait([
      _pull('products', failures, _pullProducts),
      _pull('categories', failures, _pullCategories),
      _pull('members', failures, _pullMembers),
      _pull('member_levels', failures, _pullMemberLevels),
      _pull('coupons', failures, _pullCoupons),
      _pull('promotions', failures, _pullPromotions),
      _pull('inventory_levels', failures, () => _pullInventory(storeId: sid)),
    ]);

    final result = DeltaPullResult(failures: failures);
    if (result.isSuccess) {
      _lastPullAt = DateTime.now();
      _emit(DeltaPullState.idle);
    } else {
      _emit(DeltaPullState.error, error: result.summary);
    }
    return result;
  }

  Future<void> _pull(
    String name,
    Map<String, String> failures,
    Future<void> Function() fn,
  ) async {
    try {
      await fn();
    } catch (e, st) {
      logger.warn('delta pull $name failed', e, st);
      failures[name] = e.toString();
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
            hideFromPublicOrdering: Value(p.hideFromPublicOrdering),
            hideFromPosBrowse: Value(p.hideFromPosBrowse),
          ),
          mode: InsertMode.insertOrReplace,
        );
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
      await _pullProducts();
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
            hideFromPublicOrdering: Value(c.hideFromPublicOrdering),
            hideFromPosBrowse: Value(c.hideFromPosBrowse),
          ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('categories', page.nextSince);
  }

  Future<void> _pullOptionGroups() async {
    final since = await _readSince('option_groups');
    final page = await api.syncOptionGroups(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final g in page.items) {
          b.insert(
            db.optionGroups,
            OptionGroupsCompanion(
              id: Value(g.id),
              name: Value(g.name),
              selectionType: Value(g.selectionType),
              isRequired: Value(g.isRequired),
              minSelections: Value(g.minSelections),
              maxSelections: Value(g.maxSelections),
              sortOrder: Value(g.sortOrder),
              updatedAt: Value(g.updatedAt),
              deletedAt: Value(g.deletedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
          b.deleteWhere(db.optionChoices, (t) => t.optionGroupId.equals(g.id));
          for (final c in g.choices) {
            b.insert(
              db.optionChoices,
              OptionChoicesCompanion(
                id: Value(c.id),
                optionGroupId: Value(c.optionGroupId),
                name: Value(c.name),
                priceDeltaCents: Value(c.priceDeltaCents),
                isDefault: Value(c.isDefault),
                sortOrder: Value(c.sortOrder),
                isActive: Value(c.isActive),
                updatedAt: Value(c.updatedAt),
                deletedAt: Value(c.deletedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        }
      });
    }
    await _writeSince('option_groups', page.nextSince);
    if (page.items.length >= 500) {
      await _pullOptionGroups();
    }
  }

  Future<void> _pullProductOptionLinks() async {
    final since = await _readSince('product_option_links');
    final page = await api.syncProductOptionLinks(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final link in page.items) {
          b.insert(
            db.productOptionGroups,
            ProductOptionGroupsCompanion(
              id: Value(link.id),
              productId: Value(link.productId),
              optionGroupId: Value(link.optionGroupId),
              sortOrder: Value(link.sortOrder),
              isRequired: Value(link.isRequired),
              updatedAt: Value(link.updatedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('product_option_links', page.nextSince);
    if (page.items.length >= 1000) {
      await _pullProductOptionLinks();
    }
  }

  Future<void> _pullProductOptionOverrides() async {
    final since = await _readSince('product_option_overrides');
    final page = await api.syncProductOptionOverrides(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final ov in page.items) {
          b.insert(
            db.productOptionChoiceOverrides,
            ProductOptionChoiceOverridesCompanion(
              id: Value(ov.id),
              productId: Value(ov.productId),
              optionChoiceId: Value(ov.optionChoiceId),
              priceDeltaCents: Value(ov.priceDeltaCents),
              isHidden: Value(ov.isHidden),
              updatedAt: Value(ov.updatedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('product_option_overrides', page.nextSince);
    if (page.items.length >= 1000) {
      await _pullProductOptionOverrides();
    }
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

  Future<void> _pullCoupons() async {
    final since = await _readSince('coupons');
    final page = await api.syncCoupons(since);
    if (page.items.isNotEmpty) {
      await db.batch((b) {
        for (final c in page.items) {
          b.insert(
            db.coupons,
            CouponsCompanion(
              id: Value(c.id),
              code: Value(c.code),
              type: Value(c.type),
              value: Value(c.value),
              memberId: Value(c.memberId),
              minSpendCents: Value(c.minSpendCents),
              expiresAt: Value(c.expiresAt),
              usedAt: Value(c.usedAt),
              updatedAt: Value(c.updatedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    }
    await _writeSince('coupons', page.nextSince);
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

class DeltaPullResult {
  const DeltaPullResult({required this.failures});

  final Map<String, String> failures;

  bool get isSuccess => failures.isEmpty;

  String get summary => failures.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}
