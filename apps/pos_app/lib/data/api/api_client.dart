import 'package:dio/dio.dart';
import 'package:pos_core/pos_core.dart';

import '../../config/env.dart';

typedef TokenProvider = Future<String?> Function();
typedef OnUnauthorized = Future<void> Function();

bool _isAuthRefreshCall(RequestOptions options) {
  return options.uri.path.endsWith('/auth/refresh');
}

class ApiClient {
  ApiClient._(this.dio);

  final Dio dio;

  factory ApiClient.create({
    required TokenProvider tokenProvider,
    required OnUnauthorized onUnauthorized,
  }) {
    final logger = AppLogger.named('api');
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenProvider();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (Env.enableDebugLogger) {
          logger.debug('→ ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (resp, handler) {
        if (Env.enableDebugLogger) {
          logger.debug('← ${resp.statusCode} ${resp.requestOptions.uri}');
        }
        handler.next(resp);
      },
      onError: (e, handler) async {
        // Never chain refresh-on-401 for /auth/refresh itself (deadlock with
        // single-flight refresh + recursive tryRefresh).
        if (e.response?.statusCode == 401 && !_isAuthRefreshCall(e.requestOptions)) {
          await onUnauthorized();
        }
        logger.warn(
            '✕ ${e.requestOptions.method} ${e.requestOptions.uri} '
            '${e.response?.statusCode ?? e.type}',
            e);
        handler.next(e);
      },
    ));

    return ApiClient._(dio);
  }
}

AppError mapDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return TimeoutError(e.message ?? 'request timed out', cause: e);
  }
  if (e.type == DioExceptionType.connectionError) {
    return const OfflineError();
  }
  final code = e.response?.statusCode;
  final msg = _extractMessage(e.response?.data) ?? e.message ?? 'unknown error';
  if (code == 401) return AuthError(msg, cause: e);
  if (code == 404) return NotFoundError(msg, cause: e);
  if (code == 409) return ConflictError(msg, cause: e);
  if (code == 422) return ValidationError(msg, cause: e);
  return NetworkError(msg, statusCode: code, cause: e);
}

String? _extractMessage(dynamic data) {
  if (data is Map && data['detail'] is String) return data['detail'] as String;
  if (data is Map && data['message'] is String) return data['message'] as String;
  return null;
}
