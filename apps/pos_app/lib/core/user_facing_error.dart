import 'package:dio/dio.dart';
import 'package:pos_core/pos_core.dart';

import '../data/api/api_client.dart';

enum UserErrorScene { login, terminalRegister, general }

/// Short, actionable message for cashiers — never raw Dio stack traces.
String formatUserFacingError(
  Object error, {
  UserErrorScene scene = UserErrorScene.general,
}) {
  if (error is DioException) {
    return _fromAppError(mapDioError(error), scene: scene, httpDetail: _httpDetail(error));
  }
  if (error is AppError) {
    return _fromAppError(error, scene: scene, httpDetail: error.message);
  }
  return '操作失敗，請稍後再試。若問題持續，請聯絡店家管理員。';
}

String? _httpDetail(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] is String) return data['detail'] as String;
  return null;
}

String _fromAppError(
  AppError e, {
  required UserErrorScene scene,
  String? httpDetail,
}) {
  final detail = (httpDetail ?? e.message).toLowerCase();

  if (e is OfflineError || e is TimeoutError) {
    return '無法連線伺服器。\n'
        '請確認 Wi‑Fi／網路正常，並在設定中檢查 API 位址是否正確。';
  }

  if (e is AuthError) {
    if (detail.contains('invalid terminal')) {
      return '終端機金鑰驗證失敗。\n'
          '若曾重新註冊終端，請點登入頁下方「終端機註冊／重新註冊」取得新金鑰後再登入。';
    }
    if (scene == UserErrorScene.terminalRegister) {
      if (detail.contains('insufficient') || detail.contains('permission')) {
        return '管理員權限不足。\n'
            '請使用 tenant_admin 或 store_manager 帳號登入後再註冊終端。';
      }
      return '管理員帳號或密碼錯誤。\n'
          '請確認租戶代號、帳號與密碼後再試。';
    }
    return '帳號或密碼錯誤。\n'
        '請確認收銀員帳號與密碼；多次失敗可能暫時鎖定帳號。';
  }

  if (e is NotFoundError) {
    if (detail.contains('tenant')) {
      return '找不到租戶。\n請確認「租戶代號」是否正確（例如 demo）。';
    }
    if (detail.contains('store')) {
      return '找不到店別。\n請確認「店別代號」是否正確（例如 S001）。';
    }
    return '找不到相關資料，請確認代號是否正確。';
  }

  if (e is ValidationError) {
    return '資料格式不正確，請檢查必填欄位後再試。';
  }

  if (e is ConflictError) {
    return '資料衝突（可能已存在），請換一個代號或聯絡管理員。';
  }

  if (e is NetworkError) {
    final code = e.statusCode;
    if (code == 403) {
      return '目前無法使用（帳號停用或權限不足）。\n請聯絡店家管理員。';
    }
    if (code == 423 || detail.contains('locked')) {
      return '帳號已暫時鎖定。\n請稍後再試或請管理員解除鎖定。';
    }
    if (code != null && code >= 500) {
      return '伺服器暫時無法處理，請稍後再試。';
    }
  }

  return '操作失敗，請稍後再試。若問題持續，請聯絡店家管理員。';
}
