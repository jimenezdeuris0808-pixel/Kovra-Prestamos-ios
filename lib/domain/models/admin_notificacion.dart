/// Modelo de notificación tal como la devuelve `GET /admin/notificaciones`.
class AdminNotificacion {
  const AdminNotificacion({
    required this.id,
    required this.tipo,
    this.tenantId,
    required this.mensaje,
    required this.leida,
    required this.creadoEn,
  });

  final int id;
  final String tipo;
  final int? tenantId;
  final String mensaje;
  final bool leida;
  final String creadoEn;

  factory AdminNotificacion.fromJson(Map<String, dynamic> json) {
    return AdminNotificacion(
      id: json['id'] as int,
      tipo: json['tipo']?.toString() ?? '',
      tenantId: json['tenant_id'] as int?,
      mensaje: json['mensaje']?.toString() ?? '',
      leida: json['leida'] as bool? ?? false,
      creadoEn: json['creado_en']?.toString() ?? '',
    );
  }
}
