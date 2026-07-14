/// Ítem de `GET /prestamos/buscar` ("Datapréstamo"), cross-tenant: el mismo
/// buscador de `PrestamoCarteraItem` pero recorriendo TODAS las empresas
/// activas del sistema, no solo la propia. Ver
/// `Kovra_API/app/routers/prestamos_router.py::buscar_prestamos`.
///
/// `puntuacionGlobal` es la puntuación de pago consolidada de la cédula del
/// cliente a través de todas las empresas donde apareció en la búsqueda
/// (`Kovra_API/app/business.py::calcular_puntuacion_global`), no el
/// `puntuacion` aislado por empresa.
class PrestamoBusquedaItem {
  const PrestamoBusquedaItem({
    required this.empresa,
    required this.esMiEmpresa,
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.cedula,
    this.telefono,
    this.email,
    required this.frecuencia,
    required this.estado,
    required this.categoriaSeveridad,
    required this.capital,
    required this.restante,
    required this.montoPagadoAcumulado,
    required this.diasAtraso,
    required this.puntuacionGlobal,
    required this.cuotasVencidasTotalesCliente,
    this.fechaVencPendiente,
  });

  final String empresa;
  final bool esMiEmpresa;
  final int id;
  final int clienteId;
  final String clienteNombre;
  final String cedula;
  final String? telefono;
  final String? email;
  final String frecuencia;
  final String estado;
  final String categoriaSeveridad;
  final double capital;
  final double restante;
  final double montoPagadoAcumulado;
  final int diasAtraso;
  final int puntuacionGlobal;
  final int cuotasVencidasTotalesCliente;

  /// Fecha de vencimiento de la cuota impaga más antigua de este préstamo
  /// (`null` si no tiene ninguna pendiente) -- desde cuándo está pendiente
  /// el monto de [restante].
  final String? fechaVencPendiente;

  factory PrestamoBusquedaItem.fromJson(Map<String, dynamic> json) {
    return PrestamoBusquedaItem(
      empresa: json['empresa']?.toString() ?? '',
      esMiEmpresa: json['es_mi_empresa'] as bool? ?? false,
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      frecuencia: json['frecuencia']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      categoriaSeveridad: json['categoria_severidad']?.toString() ?? '',
      capital: (json['capital'] as num?)?.toDouble() ?? 0,
      restante: (json['restante'] as num?)?.toDouble() ?? 0,
      montoPagadoAcumulado:
          (json['monto_pagado_acumulado'] as num?)?.toDouble() ?? 0,
      diasAtraso: json['dias_atraso'] as int? ?? 0,
      puntuacionGlobal: json['puntuacion_global'] as int? ?? 0,
      cuotasVencidasTotalesCliente:
          json['cuotas_vencidas_totales_cliente'] as int? ?? 0,
      fechaVencPendiente: json['fecha_venc_pendiente']?.toString(),
    );
  }
}

/// Respuesta completa de `GET /prestamos/buscar` (cross-tenant).
class BusquedaPrestamoCrossTenantOut {
  const BusquedaPrestamoCrossTenantOut({required this.items});

  final List<PrestamoBusquedaItem> items;

  factory BusquedaPrestamoCrossTenantOut.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return BusquedaPrestamoCrossTenantOut(
      items: rawItems
          .map((e) => PrestamoBusquedaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
