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
    this.fechaExpiracion,
    this.avisoVigencia,
    this.aplicaMora = true,
  });

  final String nombreEmpresa;
  final String? nombreComercial;
  final bool tieneLogo;

  /// Teléfono y RNC/cédula de la empresa ("Mi Empresa" en el móvil) --
  /// aparecen en la cabecera del recibo de pago junto al nombre/logo.
  final String? telefono;
  final String? rncCedula;

  /// Fecha de expiración de la vigencia del tenant (`null` = indefinida).
  final String? fechaExpiracion;

  /// Mensaje de aviso de pago cuando faltan pocos días para vencer o ya
  /// venció (dentro del período de gracia) -- `null` si no aplica todavía.
  /// Ver `Kovra_API/app/business.py::mensaje_aviso_vigencia`.
  final String? avisoVigencia;

  /// Interruptor de "Mi Empresa": si es `false`, el backend nunca calcula
  /// mora por atraso para NINGÚN préstamo de este tenant (ver
  /// `Kovra_API/app/business.py::calcular_mora_factura`). Default `true`
  /// para no cambiar el comportamiento de tenants existentes.
  final bool aplicaMora;

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
      fechaExpiracion: json['fecha_expiracion'] as String?,
      avisoVigencia: json['aviso_vigencia'] as String?,
      aplicaMora: json['aplica_mora'] as bool? ?? true,
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
