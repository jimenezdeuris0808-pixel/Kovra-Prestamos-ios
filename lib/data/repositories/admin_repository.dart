import 'package:dio/dio.dart';
import '../../domain/models/tenant_admin.dart';

/// Resultado de un login exitoso contra `POST /admin/auth/login`.
class AdminLoginResult {
  const AdminLoginResult({required this.token, required this.username});

  final String token;
  final String username;

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) {
    return AdminLoginResult(
      token: json['access_token'] as String,
      username: json['username']?.toString() ?? '',
    );
  }
}

/// Repositorio de administración: login de administrador y gestión de
/// tenants (`GET /admin/tenants`, vigencia y estado).
class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<AdminLoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/admin/auth/login',
      data: {'username': username, 'password': password},
    );
    _ensureOk(response);
    return AdminLoginResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TenantAdmin>> listarTenants() async {
    final response = await _dio.get('/admin/tenants');
    _ensureOk(response);
    final data = response.data;
    final list = (data is List) ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => TenantAdmin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TenantAdmin> actualizarVigencia(
    int id,
    String? fechaExpiracion,
  ) async {
    final response = await _dio.patch(
      '/admin/tenants/$id/vigencia',
      data: {'fecha_expiracion': fechaExpiracion},
    );
    _ensureOk(response);
    return TenantAdmin.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantAdmin> actualizarEstado(int id, String estado) async {
    final response = await _dio.patch(
      '/admin/tenants/$id/estado',
      data: {'estado': estado},
    );
    _ensureOk(response);
    return TenantAdmin.fromJson(response.data as Map<String, dynamic>);
  }

  void _ensureOk(Response response, {List<int> expectedCodes = const [200]}) {
    if (response.statusCode == null || !expectedCodes.contains(response.statusCode)) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ?? 'Ocurrió un error al procesar la solicitud.')
          : 'Ocurrió un error al procesar la solicitud.';
      throw AdminException(detail);
    }
  }
}

class AdminException implements Exception {
  AdminException(this.message);
  final String message;

  @override
  String toString() => message;
}
