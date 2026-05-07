import 'package:pos_core/pos_core.dart';

class Session {
  const Session({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.storeId,
    required this.terminalId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String userId;
  final String username;
  final String displayName;
  final String role;
  final String storeId;
  final String terminalId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

abstract interface class AuthRepository {
  Future<Result<Session>> login(String username, String password, {required String terminalCode});
  Future<Result<Session>> refresh();
  Future<Result<void>> logout();
  Session? currentSession();
  Stream<Session?> watch();
}
