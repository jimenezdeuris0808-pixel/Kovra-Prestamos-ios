import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// Configuración del base URL de la API Kovra según la plataforma de
/// ejecución. Ajustable manualmente si se corre contra otro host/puerto.
class ApiConfig {
  ApiConfig._();

  /// URL de producción (HTTPS) de Kovra_API una vez desplegado.
  ///
  /// Despliegue FUSIONADO: Kovra_API ya NO se despliega como app Fly.io
  /// separada (ver Kovra_API/Dockerfile y Kovra_API/fly.toml, obsoletos).
  /// Corre como segundo proceso dentro de la MISMA Machine que la app web
  /// Kovra (app = "kovra-banco-movil"), para poder compartir el volumen
  /// `kovra_data` (los volúmenes de Fly.io son single-attach). Ver
  /// `Kovra Prestamos Web/Dockerfile.fusionado`, `entrypoint.sh` y
  /// `fly.toml.fusionado`.
  ///
  /// El servicio web sigue en el puerto público estándar (443, sin
  /// especificarlo en la URL). El backend FastAPI queda expuesto en su
  /// propio puerto público 8000 de la misma app (ver el segundo bloque
  /// `[[services]]` de `fly.toml.fusionado`), por eso el puerto va explícito
  /// acá. Esta URL solo será válida una vez que el usuario active el
  /// despliegue fusionado (renombrando los archivos `.fusionado` y
  /// corriendo `flyctl deploy`, ver DEPLOY_FUSIONADO.md) -- hasta entonces
  /// no hay backend real respondiendo ahí.
  static const String productionBaseUrl = 'https://kovra-banco-movil.fly.dev:8000';

  /// Base URL para el emulador Android (10.0.2.2 apunta al localhost del host).
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Base URL para iOS simulator / macOS / desktop (localhost real).
  static const String _defaultBaseUrl = 'http://localhost:8000';

  /// Override manual SOLO para desarrollo (debug/profile), para probar
  /// contra un backend corriendo en la IP LAN de tu máquina de desarrollo
  /// (necesario cuando se prueba desde un dispositivo físico en la misma
  /// WiFi, ya que 10.0.2.2/localhost no son alcanzables desde ahí).
  ///
  /// NUNCA se hardcodea acá: se pasa por --dart-define al correr/compilar,
  /// y `kReleaseMode` garantiza que se ignore por completo en builds de
  /// release (flutter build apk/ipa/appbundle), así que no hay riesgo de
  /// publicar accidentalmente una IP privada en producción.
  ///
  /// Uso (reemplaza la IP por la de tu PC en la red local):
  ///   flutter run --dart-define=LAN_OVERRIDE_URL=http://192.168.1.10:8000
  static const String _lanOverrideUrl = String.fromEnvironment('LAN_OVERRIDE_URL');

  static String get baseUrl {
    // Builds de release: siempre el backend de producción, sin excepción.
    if (kReleaseMode) {
      return productionBaseUrl;
    }
    // Debug/profile: override manual de LAN si se pasó por --dart-define.
    if (_lanOverrideUrl.isNotEmpty) {
      return _lanOverrideUrl;
    }
    // Debug/profile sin override: detección automática por plataforma.
    if (!kIsWeb && Platform.isAndroid) {
      return _androidEmulatorBaseUrl;
    }
    return _defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
