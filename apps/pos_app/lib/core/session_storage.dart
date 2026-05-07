import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_domain/pos_domain.dart';

class SessionStorage {
  SessionStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _kSession = 'pos.session';
  static const _kTerminal = 'pos.terminal_credentials';

  Future<void> save(Session s) async {
    final json = {
      'userId': s.userId,
      'username': s.username,
      'displayName': s.displayName,
      'role': s.role,
      'storeId': s.storeId,
      'terminalId': s.terminalId,
      'accessToken': s.accessToken,
      'refreshToken': s.refreshToken,
      'expiresAt': s.expiresAt.toIso8601String(),
    };
    await _storage.write(key: _kSession, value: jsonEncode(json));
  }

  Future<Session?> load() async {
    final s = await _storage.read(key: _kSession);
    if (s == null) return null;
    final j = jsonDecode(s) as Map<String, dynamic>;
    return Session(
      userId: j['userId'] as String,
      username: j['username'] as String,
      displayName: j['displayName'] as String,
      role: j['role'] as String,
      storeId: j['storeId'] as String,
      terminalId: j['terminalId'] as String,
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
      expiresAt: DateTime.parse(j['expiresAt'] as String),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _kSession);
  }

  Future<void> saveTerminalCreds(String storeCode, String terminalCode, String apiKey) async {
    await _storage.write(
      key: _kTerminal,
      value: jsonEncode({'storeCode': storeCode, 'terminalCode': terminalCode, 'apiKey': apiKey}),
    );
  }

  Future<Map<String, dynamic>?> loadTerminalCreds() async {
    final s = await _storage.read(key: _kTerminal);
    if (s == null) return null;
    return (jsonDecode(s) as Map).cast<String, dynamic>();
  }
}
