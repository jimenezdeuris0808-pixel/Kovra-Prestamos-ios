import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Callback invocado cuando la API responde 401 (sesión inválida/expirada).
/// Se usa para forzar logout automático y volver a la pantalla de Login.
typedef OnUnauthorized = Future<void> Function();

/// Interceptor que:
/// 1. Agrega el header `Authorization: Bearer <token>` a cada request
///    (excepto login, que no requiere token).
/// 2. Detecta respuestas 401 y dispara [onUnauthorized] para hacer logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    required OnUnauthorized onUnauthorized,
  })  : _storage = storage,
        _onUnauthorized = onUnauthorized;

  final SecureStorageService _storage;
  final OnUnauthorized _onUnauthorized;

  static const _loginPath = '/auth/login';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains(_loginPath)) {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isLogin = err.requestOptions.path.contains(_loginPath);
    if (err.response?.statusCode == 401 && !isLogin) {
      await _storage.clearSession();
      await _onUnauthorized();
    }
    handler.next(err);
  }
}
