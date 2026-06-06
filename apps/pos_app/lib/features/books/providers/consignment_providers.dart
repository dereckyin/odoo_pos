import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/api/dto.dart';
import '../../../data/database/app_database.dart';

class ConsignmentPosState {
  const ConsignmentPosState({
    this.enabled = false,
    this.bookSharePct = 60,
    this.categoryId,
    this.discountPresets = const [],
  });

  final bool enabled;
  final int bookSharePct;
  final String? categoryId;
  final List<DiscountPresetDto> discountPresets;
}

final consignmentPosConfigProvider =
    StateNotifierProvider<ConsignmentPosNotifier, ConsignmentPosState>((ref) {
  return ConsignmentPosNotifier(ref);
});

class ConsignmentPosNotifier extends StateNotifier<ConsignmentPosState> {
  ConsignmentPosNotifier(this._ref) : super(const ConsignmentPosState());

  final Ref _ref;

  Future<void> refresh() async {
    try {
      final api = _ref.read(posApiProvider);
      final cfg = await api.fetchConsignmentPosConfig();
      state = ConsignmentPosState(
        enabled: cfg.enabled,
        bookSharePct: cfg.bookSharePct,
        categoryId: cfg.categoryId,
        discountPresets: cfg.discountPresets,
      );
      final db = _ref.read(databaseProvider);
      await db.into(db.kvMeta).insertOnConflictUpdate(
            KvMetaCompanion(
              key: const Value('consignment_pos_config'),
              value: Value(jsonEncode({
                'enabled': cfg.enabled,
                'book_share_pct': cfg.bookSharePct,
                'category_id': cfg.categoryId,
                'discount_presets': cfg.discountPresets
                    .map((p) => {'label': p.label, 'pct_off': p.pctOff})
                    .toList(),
              })),
            ),
          );
    } catch (_) {
      await _loadFromKv();
    }
  }

  Future<void> _loadFromKv() async {
    final db = _ref.read(databaseProvider);
    final row = await (db.select(db.kvMeta)..where((k) => k.key.equals('consignment_pos_config')))
        .getSingleOrNull();
    if (row?.value == null) return;
    final j = jsonDecode(row!.value!) as Map<String, dynamic>;
    final presets = (j['discount_presets'] as List?)
            ?.map((e) => DiscountPresetDto.fromJson((e as Map).cast<String, dynamic>()))
            .toList() ??
        const [];
    state = ConsignmentPosState(
      enabled: j['enabled'] as bool? ?? false,
      bookSharePct: (j['book_share_pct'] as num?)?.toInt() ?? 60,
      categoryId: j['category_id'] as String?,
      discountPresets: presets,
    );
  }
}
