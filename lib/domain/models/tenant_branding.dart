/// Nombre/logo de la empresa (tenant) de la sesión actual, tal como lo
/// devuelve `GET /auth/me`. Se re-consulta cada vez que la app abre (no solo
/// al loguearse) para que una sesión guardada de antes de este cambio se
/// autocorrija sola.
class TenantBranding {
  const TenantBranding({
    required this.nombreEmpresa,
    this.nombreComercial,
    this.tieneLogo = false,
    this.telefono,
    this.rncCedula,
  });

  final String nombreEmpresa;
  final String? nombreComercial;
  final bool tieneLogo;

  /// Teléfono y RNC/cédula de la empresa ("Mi Empresa" en el móvil) --
  /// aparecen en la cabecera del recibo de pago junto al nombre/logo.
  final String? telefono;
  final String? rncCedula;

  String get nombreParaMostrar =>
      (nombreComercial != null && nombreComercial!.trim().isNotEmpty)
          ? nombreComercial!
          : nombreEmpresa;

  factory TenantBranding.fromJson(Map<String, dynamic> json) {
    return TenantBranding(
      nombreEmpresa: json['nombre_empresa'] as String? ?? 'Kovra',
      nombreComercial: json['nombre_comercial'] as String?,
      tieneLogo: json['tiene_logo'] as bool? ?? false,
      telefono: json['telefono'] as String?,
      rncCedula: json['rnc_cedula'] as String?,
    );
  }
}

/// Bytes + tipo de contenido del logo del tenant (`GET /auth/logo`), para
/// decidir si renderizarlo como SVG o como imagen raster.
class TenantLogo {
  const TenantLogo({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;

  bool get esSvg => contentType.contains('svg');
}
