import '../../core/utils/formatters.dart';
import 'factura.dart';

/// Pago registrado hoy (`cobradas_hoy` de `GET /dashboard/cobros_hoy`,
/// NOTES_CARTERA_CLIENTES_COBROS.md sección 4.3). A diferencia de
/// `atrasadas`, esta lista **no** filtra por estado del préstamo (un pago
/// que cierra un préstamo hoy sigue apareciendo aquí).
class CuotaCobradaHoy {
  const CuotaCobradaHoy({
    required this.pagoId,
    required this.facturaId,
    required this.prestamoId,
    required this.clienteId,
    required this.clienteNombre,
    required this.monto,
    this.fechaPago,
    this.fechaVencimiento,
    required this.metodo,
  });

  final int pagoId;
  final int facturaId;
  final int prestamoId;
  final int clienteId;
  final String clienteNombre;
  final double monto;
  final DateTime? fechaPago;
  final DateTime? fechaVencimiento;
  final String metodo;

  factory CuotaCobradaHoy.fromJson(Map<String, dynamic> json) {
    return CuotaCobradaHoy(
      pagoId: json['pago_id'] as int? ?? 0,
      facturaId: json['factura_id'] as int? ?? 0,
      prestamoId: json['prestamo_id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      fechaPago: Formatters.parseDate(json['fecha_pago']?.toString()),
      fechaVencimiento:
          Formatters.parseDate(json['fecha_vencimiento']?.toString()),
      metodo: json['metodo']?.toString() ?? '',
    );
  }
}

/// Respuesta de `GET /dashboard/cobros_hoy`: cuotas atrasadas (mismo modelo
/// `Factura` que usa `GET /dashboard/resumen` para su lista de atrasadas) y
/// pagos cobrados hoy.
class DashboardCobrosHoy {
  const DashboardCobrosHoy({
    required this.atrasadas,
    required this.cobradasHoy,
    required this.totalPendiente,
    required this.totalCobradoHoy,
  });

  final List<Factura> atrasadas;
  final List<CuotaCobradaHoy> cobradasHoy;
  final double totalPendiente;
  final double totalCobradoHoy;

  factory DashboardCobrosHoy.fromJson(Map<String, dynamic> json) {
    final rawAtrasadas = json['atrasadas'] as List? ?? const [];
    final rawCobradas = json['cobradas_hoy'] as List? ?? const [];
    return DashboardCobrosHoy(
      atrasadas: rawAtrasadas
          .map((e) => Factura.fromJson(e as Map<String, dynamic>))
          .toList(),
      cobradasHoy: rawCobradas
          .map((e) => CuotaCobradaHoy.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPendiente: (json['total_pendiente'] as num?)?.toDouble() ?? 0,
      totalCobradoHoy: (json['total_cobrado_hoy'] as num?)?.toDouble() ?? 0,
    );
  }
}
