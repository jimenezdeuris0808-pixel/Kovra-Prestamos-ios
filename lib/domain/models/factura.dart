import '../../core/utils/formatters.dart';

/// Estados posibles de una cuota/factura, según la API.
enum EstadoFactura { pendiente, pagada, atrasada, parcial, desconocido }

EstadoFactura estadoFacturaFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'pagada':
    case 'pagado':
      return EstadoFactura.pagada;
    case 'atrasada':
    case 'atrasado':
    case 'vencida':
      return EstadoFactura.atrasada;
    case 'parcial':
      return EstadoFactura.parcial;
    case 'pendiente':
      return EstadoFactura.pendiente;
    default:
      return EstadoFactura.desconocido;
  }
}

/// Cuota individual de un préstamo (tal como viene en `facturas` dentro de
/// `GET /prestamos/{id}`).
class Factura {
  const Factura({
    required this.id,
    required this.numeroCuota,
    required this.fechaVencimiento,
    required this.montoCuota,
    required this.montoPagado,
    required this.mora,
    required this.estado,
    this.clienteNombre,
    this.prestamoId,
  });

  final int id;
  final int numeroCuota;
  final DateTime? fechaVencimiento;
  final double montoCuota;
  final double montoPagado;
  final double mora;
  final EstadoFactura estado;

  /// Presente solo cuando la factura viene embebida en el resumen del
  /// dashboard, para mostrar el nombre del cliente en la CuotaCard.
  final String? clienteNombre;
  final int? prestamoId;

  double get montoPendiente {
    final restante = montoCuota - montoPagado;
    return restante < 0 ? 0 : restante;
  }

  double get totalConMora => montoPendiente + mora;

  bool get esPagable =>
      estado == EstadoFactura.pendiente ||
      estado == EstadoFactura.atrasada ||
      estado == EstadoFactura.parcial;

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'] as int? ?? json['factura_id'] as int? ?? 0,
      numeroCuota: json['numero_cuota'] as int? ?? 0,
      fechaVencimiento: Formatters.parseDate(
        json['fecha_vencimiento']?.toString(),
      ),
      montoCuota: (json['monto_cuota'] as num?)?.toDouble() ?? 0,
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0,
      mora: (json['mora_calculada'] as num?)?.toDouble() ??
          (json['mora'] as num?)?.toDouble() ??
          0,
      estado: estadoFacturaFromString(json['estado']?.toString()),
      clienteNombre: json['cliente_nombre']?.toString(),
      prestamoId: json['prestamo_id'] as int?,
    );
  }
}
