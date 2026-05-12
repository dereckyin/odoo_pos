import 'dart:convert';

import '../../config/env.dart';
import '../database/app_database.dart';

const masterDataScopeMetaKey = 'sync.scope';

class MasterDataScope {
  const MasterDataScope({
    required this.tenantId,
    required this.storeId,
    required this.apiBaseUrl,
  });

  final String? tenantId;
  final String? storeId;
  final String apiBaseUrl;

  factory MasterDataScope.fromSession({
    required String? tenantId,
    required String? storeId,
    String? apiBaseUrl,
  }) {
    return MasterDataScope(
      tenantId: tenantId,
      storeId: storeId,
      apiBaseUrl: apiBaseUrl ?? Env.apiBaseUrl,
    );
  }

  factory MasterDataScope.fromJson(Map<String, dynamic> json) {
    return MasterDataScope(
      tenantId: json['tenantId'] as String?,
      storeId: json['storeId'] as String?,
      apiBaseUrl: json['apiBaseUrl'] as String? ?? Env.apiBaseUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'storeId': storeId,
        'apiBaseUrl': apiBaseUrl,
      };

  bool differsFrom(MasterDataScope? other) {
    if (other == null) return true;
    return tenantId != other.tenantId ||
        storeId != other.storeId ||
        apiBaseUrl != other.apiBaseUrl;
  }
}

class MasterDataScopeStore {
  MasterDataScopeStore(this._db);

  final AppDatabase _db;

  Future<MasterDataScope?> readScope() async {
    final raw = await _db.getMeta(masterDataScopeMetaKey);
    if (raw == null || raw.isEmpty) return null;
    return MasterDataScope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeScope(MasterDataScope scope) async {
    await _db.setMeta(masterDataScopeMetaKey, jsonEncode(scope.toJson()));
  }

  Future<bool> applySessionScope({
    required String? tenantId,
    required String? storeId,
    String? apiBaseUrl,
  }) async {
    final next = MasterDataScope.fromSession(
      tenantId: tenantId,
      storeId: storeId,
      apiBaseUrl: apiBaseUrl,
    );
    final previous = await readScope();
    if (!next.differsFrom(previous)) return false;

    await _db.clearMasterData();
    await writeScope(next);
    return true;
  }

  Future<void> clearScope() async {
    await (_db.delete(_db.kvMeta)..where((t) => t.key.equals(masterDataScopeMetaKey))).go();
  }
}
