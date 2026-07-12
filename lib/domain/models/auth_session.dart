/// Resultado de un login exitoso contra `POST /auth/login`.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.tenantSlug,
    required this.nombreEmpresa,
    this.nombreComercial,
  });

  final String token;
  final String role;
  final String tenantSlug;

  /// Nombre real de la empresa (tenant) del usuario logueado — usar para
  /// cualquier branding visible tras el login (recibos, cabeceras), nunca
  /// un nombre fijo tipo "Kovra".
  final String nombreEmpresa;
  final String? nombreComercial;

  /// Nombre a mostrar: preferí el comercial si existe, si no el legal.
  String get nombreParaMostrar =>
      (nombreComercial != null && nombreComercial!.trim().isNotEmpty)
          ? nombreComercial!
          : nombreEmpresa;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['access_token'] as String,
      role: json['role'] as String? ?? '',
      tenantSlug: json['tenant_db_path'] as String? ?? '',
      nombreEmpresa: json['nombre_empresa'] as String? ?? 'Kovra',
      nombreComercial: json['nombre_comercial'] as String?,
    );
  }
}
