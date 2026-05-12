import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

import '../data/api/api_client.dart';
import '../data/api/dto.dart';
import '../data/api/pos_api.dart';
import '../data/database/app_database.dart';
import 'session_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(ref.read(secureStorageProvider)),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class AuthState {
  AuthState({this.session});
  final Session? session;
  bool get isLoggedIn => session != null && !session!.isExpired;
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final controller = ref.read(authStateProvider.notifier);
  return ApiClient.create(
    tokenProvider: () async => ref.read(authStateProvider).session?.accessToken,
    onUnauthorized: () async => controller.tryRefresh(),
  );
});

final posApiProvider = Provider<PosApi>((ref) => PosApi(ref.read(apiClientProvider).dio));

final loggerProvider = Provider<AppLogger>((ref) => AppLogger.named('app'));

final promotionEngineProvider = Provider<PromotionEngine>(
  (ref) => PromotionEngine(clock: ref.read(clockProvider)),
);

const _maxRefreshAttempts = 5;

Duration? _retryAfterDuration(Response? response) {
  final raw = response?.headers.value('retry-after');
  if (raw == null || raw.isEmpty) return null;
  final secs = int.tryParse(raw.trim());
  if (secs == null) return null;
  return Duration(seconds: secs.clamp(1, 120));
}

Duration _backoffAfter429(int attemptIndex) {
  final sec = (1 << attemptIndex).clamp(1, 32);
  return Duration(seconds: sec);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState()) {
    _restore();
  }

  final Ref _ref;
  Future<void>? _refreshInFlight;

  Future<void> _restore() async {
    final s = await _ref.read(sessionStorageProvider).load();
    if (s != null) state = AuthState(session: s);
  }

  Future<void> setSession(Session s) async {
    state = AuthState(session: s);
    await _ref.read(sessionStorageProvider).save(s);
  }

  Future<void> logout() async {
    state = AuthState();
    await _ref.read(sessionStorageProvider).clear();
  }

  Future<void> tryRefresh() async {
    final session = state.session;
    if (session == null) return;

    return _refreshInFlight ??= _runRefresh(session.refreshToken).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _runRefresh(String refreshToken) async {
    try {
      final dto = await _refreshWithRetries(refreshToken);
      await setSession(Session(
        userId: dto.userId,
        username: dto.username,
        displayName: dto.displayName,
        role: dto.role,
        tenantId: dto.tenantId,
        tenantCode: dto.tenantCode,
        storeId: dto.storeId,
        terminalId: dto.terminalId,
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
        expiresAt: dto.expiresAt,
      ));
    } catch (_) {
      await logout();
    }
  }

  Future<SessionDto> _refreshWithRetries(String refreshToken) async {
    DioException? last;
    for (var attempt = 0; attempt < _maxRefreshAttempts; attempt++) {
      try {
        return await _ref.read(posApiProvider).refresh(refreshToken);
      } on DioException catch (e) {
        last = e;
        final code = e.response?.statusCode;
        final retry429 = code == 429 && attempt < _maxRefreshAttempts - 1;
        if (!retry429) rethrow;
        final wait =
            _retryAfterDuration(e.response) ?? _backoffAfter429(attempt);
        await Future<void>.delayed(wait);
      }
    }
    throw last!;
  }
}
