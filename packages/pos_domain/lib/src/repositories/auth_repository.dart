import 'package:pos_core/pos_core.dart';

class Session {
  const Session({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tenantId,
    this.tenantCode,
    this.storeId,
    this.terminalId,
  });

  final String userId;
  final String username;
  final String displayName;
  final String role;

  /// Tenant assignment from the JWT. ``null`` only for the platform
  /// super-admin operating cross-tenant.
  final String? tenantId;

  /// Human-readable tenant code (e.g. ``demo``). Useful for the UI to show
  /// "currently signed into <tenant>".
  final String? tenantCode;

  /// Store assignment. ``null`` only when the user is a tenant-wide admin
  /// signing in via the browser admin console.
  final String? storeId;

  /// Terminal assignment for POS sessions. ``null`` for browser logins.
  final String? terminalId;

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

abstract interface class AuthRepository {
  /// Tenant-aware POS login. ``terminalApiKey`` is the secret returned by
  /// ``/auth/terminals/register`` and must be persisted locally on this
  /// physical terminal.
  Future<Result<Session>> login({
    required String tenantCode,
    required String storeCode,
    required String terminalCode,
    required String terminalApiKey,
    required String username,
    required String password,
  });

  Future<Result<Session>> refresh();
  Future<Result<void>> logout();
  Session? currentSession();
  Stream<Session?> watch();
}
