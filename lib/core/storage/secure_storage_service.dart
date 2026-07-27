import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para la sesión del usuario (token JWT,
/// rol y tenant). Usa el keychain/keystore nativo de cada plataforma.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'kovra_auth_token';
  static const _roleKey = 'kovra_auth_role';
  static const _tenantKey = 'kovra_auth_tenant_slug';
  static const _nombreEmpresaKey = 'kovra_auth_nombre_empresa';
  static const _nombreComercialKey = 'kovra_auth_nombre_comercial';

  /// MAC de la impresora térmica Bluetooth elegida por el usuario en este
  /// dispositivo. A propósito NO se borra en [clearSession] -- es una
  /// preferencia del dispositivo/impresora física, no de la sesión del
  /// tenant, así que sobrevive a cerrar sesión y volver a entrar.
  static const _printerMacKey = 'kovra_printer_mac';

  Future<void> saveSession({
    required String token,
    required String role,
    required String tenantSlug,
    required String nombreEmpresa,
    String? nombreComercial,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _tenantKey, value: tenantSlug);
    await _storage.write(key: _nombreEmpresaKey, value: nombreEmpresa);
    if (nombreComercial != null) {
      await _storage.write(key: _nombreComercialKey, value: nombreComercial);
    } else {
      await _storage.delete(key: _nombreComercialKey);
    }
  }

  /// Actualiza solo el nombre de empresa/comercial, sin tocar token/rol
  /// (usado para refrescar el branding de una sesión ya activa, ver
  /// `SessionController._refrescarBranding`).
  Future<void> saveBranding({
    required String nombreEmpresa,
    String? nombreComercial,
  }) async {
    await _storage.write(key: _nombreEmpresaKey, value: nombreEmpresa);
    if (nombreComercial != null) {
      await _storage.write(key: _nombreComercialKey, value: nombreComercial);
    } else {
      await _storage.delete(key: _nombreComercialKey);
    }
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<String?> readTenantSlug() => _storage.read(key: _tenantKey);

  Future<String?> readNombreEmpresa() => _storage.read(key: _nombreEmpresaKey);

  Future<String?> readNombreComercial() =>
      _storage.read(key: _nombreComercialKey);

  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> savePrinterMac(String mac) => _storage.write(key: _printerMacKey, value: mac);

  Future<String?> readPrinterMac() => _storage.read(key: _printerMacKey);

  Future<void> clearPrinterMac() => _storage.delete(key: _printerMacKey);

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _tenantKey);
    await _storage.delete(key: _nombreEmpresaKey);
    await _storage.delete(key: _nombreComercialKey);
  }
}
