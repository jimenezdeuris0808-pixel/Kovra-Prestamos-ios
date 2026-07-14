import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/tenant_branding.dart';

/// Repositorio de autenticación: `POST /auth/login`, `GET /auth/me`,
/// `GET /auth/logo`.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    if (response.statusCode == 200 && response.data is Map) {
      return AuthSession.fromJson(response.data as Map<String, dynamic>);
    }

    final detail = (response.data is Map)
        ? (response.data['detail']?.toString() ??
            'Usuario o contraseña incorrectos.')
        : 'Usuario o contraseña incorrectos.';
    throw AuthException(detail);
  }

  /// Auto-registro: crea una empresa (tenant) nueva y aislada con su primer
  /// usuario (admin) e inicia sesión de inmediato. `POST /auth/signup`.
  Future<AuthSession> signup({
    required String username,
    required String email,
    required String password,
    String? nombreEmpresa,
  }) async {
    final response = await _dio.post(
      '/auth/signup',
      data: {
        'username': username,
        'email': email,
        'password': password,
        if (nombreEmpresa != null) 'nombre_empresa': nombreEmpresa,
      },
    );

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return AuthSession.fromJson(response.data as Map<String, dynamic>);
    }

    final detail = (response.data is Map)
        ? (response.data['detail']?.toString() ??
            'No se pudo crear la cuenta.')
        : 'No se pudo crear la cuenta.';
    throw AuthException(detail);
  }

  /// Nombre/logo de la empresa de la sesión YA autenticada (usa el token
  /// actual, no requiere volver a loguearse).
  Future<TenantBranding> obtenerBranding() async {
    final response = await _dio.get('/auth/me');
    return TenantBranding.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza nombre comercial/teléfono/RNC-cédula de "Mi Empresa"
  /// (`PUT /auth/branding`). No toca el logo, ver [subirLogo].
  Future<TenantBranding> actualizarBranding({
    String? nombreComercial,
    String? telefono,
    String? rncCedula,
  }) async {
    final response = await _dio.put(
      '/auth/branding',
      data: {
        'nombre_comercial': nombreComercial,
        'telefono': telefono,
        'rnc_cedula': rncCedula,
      },
    );
    if (response.statusCode == 200 && response.data is Map) {
      return TenantBranding.fromJson(response.data as Map<String, dynamic>);
    }
    final detail = (response.data is Map)
        ? (response.data['detail']?.toString() ??
            'No se pudo actualizar la información de la empresa.')
        : 'No se pudo actualizar la información de la empresa.';
    throw AuthException(detail);
  }

  /// Activa/desactiva el cálculo automático de mora por atraso para TODOS
  /// los préstamos del tenant (`PUT /auth/aplica-mora`, interruptor de "Mi
  /// Empresa"). Endpoint separado de [actualizarBranding] para que guardar
  /// el resto del formulario nunca pueda pisar este valor por accidente.
  Future<TenantBranding> actualizarAplicaMora(bool aplicaMora) async {
    final response = await _dio.put(
      '/auth/aplica-mora',
      data: {'aplica_mora': aplicaMora},
    );
    if (response.statusCode == 200 && response.data is Map) {
      return TenantBranding.fromJson(response.data as Map<String, dynamic>);
    }
    final detail = (response.data is Map)
        ? (response.data['detail']?.toString() ??
            'No se pudo actualizar el ajuste de mora.')
        : 'No se pudo actualizar el ajuste de mora.';
    throw AuthException(detail);
  }

  /// Sube/reemplaza el logo de "Mi Empresa" (`POST /auth/logo`, multipart).
  Future<TenantBranding> subirLogo(Uint8List bytes, String filename) async {
    final response = await _dio.post(
      '/auth/logo',
      data: FormData.fromMap({
        'archivo': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    if (response.statusCode == 200 && response.data is Map) {
      return TenantBranding.fromJson(response.data as Map<String, dynamic>);
    }
    final detail = (response.data is Map)
        ? (response.data['detail']?.toString() ?? 'No se pudo subir el logo.')
        : 'No se pudo subir el logo.';
    throw AuthException(detail);
  }

  /// Bytes del logo del tenant, o `null` si no tiene uno configurado o no
  /// se pudo descargar (no debe romper ninguna pantalla que lo use).
  Future<TenantLogo?> obtenerLogo() async {
    try {
      final response = await _dio.get<List<int>>(
        '/auth/logo',
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final contentType =
          response.headers.value('content-type') ?? 'application/octet-stream';
      return TenantLogo(bytes: response.data!, contentType: contentType);
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
