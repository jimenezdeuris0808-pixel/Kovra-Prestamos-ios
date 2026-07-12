import 'package:dio/dio.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import '../storage/secure_storage_service.dart';

/// Construye la instancia de [Dio] usada en toda la app, con timeouts,
/// base URL configurable y el interceptor de autenticación instalado.
Dio buildDioClient({
  required SecureStorageService storage,
  required OnUnauthorized onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: 'application/json',
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(storage: storage, onUnauthorized: onUnauthorized),
  );

  return dio;
}

/// Extrae un mensaje de error legible de una excepción de Dio o genérica,
/// para mostrar en la UI (ErrorState, SnackBars, etc.).
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Verifica tu conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar con el servidor.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }
  return error.toString();
}
