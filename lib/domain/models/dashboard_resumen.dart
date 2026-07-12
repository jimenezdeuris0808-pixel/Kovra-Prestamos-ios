import 'factura.dart';

/// Respuesta de `GET /dashboard/resumen`: cuotas del día y cuotas atrasadas
/// del tenant del cobrador autenticado.
class DashboardResumen {
  const DashboardResumen({
    required this.cuotasHoy,
    required this.cuotasAtrasadas,
  });

  final List<Factura> cuotasHoy;
  final List<Factura> cuotasAtrasadas;

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    List<Factura> parseList(dynamic raw) {
      if (raw == null) return const [];
      return (raw as List)
          .map((e) => Factura.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DashboardResumen(
      cuotasHoy: parseList(json['cuotas_hoy'] ?? json['hoy']),
      cuotasAtrasadas: parseList(json['cuotas_atrasadas'] ?? json['atrasadas']),
    );
  }
}

/// Respuesta de `GET /dashboard/resumen_general`: snapshot ejecutivo de
/// cartera (solo escalares/contadores), consumido por la sección de
/// resumen denso del dashboard. Contrato fijado en
/// `Kovra_API/NOTES_DASHBOARD_RESUMEN.md`, sección 3.
///
/// Las 7 categorías (`pendiente`..`abonado`) son mutuamente excluyentes
/// entre sí, pero su suma **no** es igual a [prestamosActivos]: son dos
/// recortes distintos de la cartera (ver NOTES_DASHBOARD_RESUMEN.md,
/// sección 1.4-1.10). No sumarlas ni compararlas entre sí en la UI.
class DashboardResumenGeneral {
  const DashboardResumenGeneral({
    required this.totalClientes,
    required this.clientesActivos,
    required this.prestamosActivos,
    required this.pendiente,
    required this.aTiempo,
    required this.atrasado,
    required this.vencido,
    required this.enAcuerdo,
    required this.incobrable,
    required this.abonado,
    required this.montoCobradoHoy,
  });

  final int totalClientes;
  final int clientesActivos;
  final int prestamosActivos;
  final int pendiente;
  final int aTiempo;
  final int atrasado;
  final int vencido;
  final int enAcuerdo;
  final int incobrable;
  final int abonado;
  final double montoCobradoHoy;

  factory DashboardResumenGeneral.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic raw) => (raw as num?)?.toInt() ?? 0;
    double asDouble(dynamic raw) => (raw as num?)?.toDouble() ?? 0;

    return DashboardResumenGeneral(
      totalClientes: asInt(json['total_clientes']),
      clientesActivos: asInt(json['clientes_activos']),
      prestamosActivos: asInt(json['prestamos_activos']),
      pendiente: asInt(json['pendiente']),
      aTiempo: asInt(json['a_tiempo']),
      atrasado: asInt(json['atrasado']),
      vencido: asInt(json['vencido']),
      enAcuerdo: asInt(json['en_acuerdo']),
      incobrable: asInt(json['incobrable']),
      abonado: asInt(json['abonado']),
      montoCobradoHoy: asDouble(json['monto_cobrado_hoy']),
    );
  }
}
