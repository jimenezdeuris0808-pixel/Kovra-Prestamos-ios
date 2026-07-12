import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración del base URL de la API Kovra según la plataforma de
/// ejecución. Ajustable manualmente si se corre contra otro host/puerto.
class ApiConfig {
  ApiConfig._();

  /// Base URL para el emulador Android (10.0.2.2 apunta al localhost del host).
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Base URL para iOS simulator / macOS / desktop (localhost real).
  static const String _defaultBaseUrl = 'http://localhost:8000';

  /// Override manual opcional. Si se define, tiene prioridad sobre la
  /// detección automática por plataforma (útil para dispositivo físico
  /// apuntando a la IP LAN del backend, ej. 'http://192.168.1.10:8000').
  static const String? overrideBaseUrl = 'http://10.0.0.26:8010';

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return _androidEmulatorBaseUrl;
    }
    return _defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
