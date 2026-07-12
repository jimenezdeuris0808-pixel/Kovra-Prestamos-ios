/// Modelo de tenant tal como lo devuelve `GET /admin/tenants` y los
/// endpoints `PATCH /admin/tenants/{id}/vigencia` y
/// `PATCH /admin/tenants/{id}/estado`.
class TenantAdmin {
  const TenantAdmin({
    required this.id,
    required this.slug,
    required this.nombreEmpresa,
    this.nombreComercial,
    required this.estado,
    this.fechaExpiracion,
    required this.creadoEn,
  });

  final int id;
  final String slug;
  final String nombreEmpresa;
  final String? nombreComercial;
  final String estado;
  final String? fechaExpiracion;
  final String creadoEn;

  bool get activo => estado == 'activo';

  factory TenantAdmin.fromJson(Map<String, dynamic> json) {
    return TenantAdmin(
      id: json['id'] as int,
      slug: json['slug']?.toString() ?? '',
      nombreEmpresa: json['nombre_empresa']?.toString() ?? '',
      nombreComercial: json['nombre_comercial']?.toString(),
      estado: json['estado']?.toString() ?? '',
      fechaExpiracion: json['fecha_expiracion']?.toString(),
      creadoEn: json['creado_en']?.toString() ?? '',
    );
  }
}
