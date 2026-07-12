import '../../core/utils/formatters.dart';
import 'factura.dart';

/// Estados posibles de un préstamo.
enum EstadoPrestamo {
  aprobado,
  enAcuerdo,
  pendiente,
  finalizado,
  rechazado,
  incobrable,
  desconocido,
}

EstadoPrestamo estadoPrestamoFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'aprobado':
      return EstadoPrestamo.aprobado;
    case 'en_acuerdo':
    case 'en acuerdo':
      return EstadoPrestamo.enAcuerdo;
    case 'pendiente':
      return EstadoPrestamo.pendiente;
    case 'finalizado':
    case 'pagado':
      return EstadoPrestamo.finalizado;
    case 'rechazado':
      return EstadoPrestamo.rechazado;
    case 'incobrable':
      return EstadoPrestamo.incobrable;
    default:
      return EstadoPrestamo.desconocido;
  }
}

/// Detalle de préstamo, tal como lo devuelve `GET /prestamos/{id}`.
class Prestamo {
  const Prestamo({
    required this.id,
    required this.monto,
    required this.tasaInteres,
    required this.plazo,
    required this.estado,
    required this.cuota,
    this.puntuacion,
    this.facturas = const [],
    this.clienteNombre,
    this.prestamoOrigenId,
    this.motivoReenganche,
    this.reenganchadoPorPrestamoId,
    this.tipoAmortizacion,
    this.frecuenciaTasa,
  });

  final int id;
  final double monto;
  final double tasaInteres;
  final int plazo;
  final EstadoPrestamo estado;
  final double cuota;
  final int? puntuacion;
  final List<Factura> facturas;
  final String? clienteNombre;

  /// Id del préstamo que este reemplaza (no nulo si este préstamo es un
  /// reenganche). NOTES_REENGANCHE.md, sección 5.
  final int? prestamoOrigenId;

  /// Tipo de amortización elegido ("Simple - insoluto", "Francés",
  /// "Alemán"). Ver NOTES_AMORTIZACION_FRECUENCIA.md.
  final String? tipoAmortizacion;

  /// Frecuencia de pago elegida ("diario", "semanal", "quincenal",
  /// "mensual", "anual"). Ver NOTES_AMORTIZACION_FRECUENCIA.md.
  final String? frecuenciaTasa;

  /// Motivo del reenganche, tal como lo ingresó el asesor al crearlo.
  final String? motivoReenganche;

  /// Id del préstamo que reenganchó a este (si este préstamo, ya viejo, fue
  /// reemplazado por otro). `null` si nadie lo reenganchó.
  final int? reenganchadoPorPrestamoId;

  double get saldoPendiente {
    final total = facturas.fold<double>(
      0,
      (acc, f) => acc + f.montoPendiente,
    );
    return total;
  }

  double get moraTotal {
    return facturas.fold<double>(0, (acc, f) => acc + f.mora);
  }

  factory Prestamo.fromJson(Map<String, dynamic> json, {int? id}) {
    return Prestamo(
      id: json['id'] as int? ?? id ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      tasaInteres: (json['tasa_interes'] as num?)?.toDouble() ?? 0,
      plazo: json['plazo_meses'] as int? ?? 0,
      estado: estadoPrestamoFromString(json['estado']?.toString()),
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      puntuacion: json['puntuacion'] is int
          ? json['puntuacion'] as int
          : int.tryParse(json['puntuacion']?.toString() ?? ''),
      facturas: json['facturas'] != null
          ? (json['facturas'] as List)
              .map((e) => Factura.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      clienteNombre: json['cliente_nombre']?.toString(),
      prestamoOrigenId: json['prestamo_origen_id'] as int?,
      motivoReenganche: json['motivo_reenganche']?.toString(),
      reenganchadoPorPrestamoId: json['reenganchado_por_prestamo_id'] as int?,
      tipoAmortizacion: json['tipo_prestamo']?.toString(),
      frecuenciaTasa: json['frecuencia_tasa']?.toString(),
    );
  }
}

/// Ítem de listado de solicitudes, tal como lo devuelve
/// `GET /prestamos?estado=...` (NOTES_PRESTAMOS.md, sección 5.2). No incluye
/// `facturas` ni `puntuacion` (esos campos no vienen en este endpoint).
class SolicitudPrestamo {
  const SolicitudPrestamo({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.monto,
    required this.tasaInteres,
    required this.plazoMeses,
    required this.cuota,
    required this.estado,
    this.fechaSolicitud,
    this.fechaInicioPago,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final double monto;
  final double tasaInteres;
  final int plazoMeses;
  final double cuota;
  final EstadoPrestamo estado;
  final DateTime? fechaSolicitud;
  final DateTime? fechaInicioPago;

  factory SolicitudPrestamo.fromJson(Map<String, dynamic> json) {
    return SolicitudPrestamo(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      tasaInteres: (json['tasa_interes'] as num?)?.toDouble() ?? 0,
      plazoMeses: json['plazo_meses'] as int? ?? 0,
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      estado: estadoPrestamoFromString(json['estado']?.toString()),
      fechaSolicitud:
          Formatters.parseDate(json['fecha_solicitud']?.toString()),
      fechaInicioPago:
          Formatters.parseDate(json['fecha_inicio_pago']?.toString()),
    );
  }
}

/// Respuesta de `POST /prestamos` (NOTES_PRESTAMOS.md, sección 5.1).
class PrestamoCreado {
  const PrestamoCreado({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.monto,
    required this.tasaInteres,
    required this.plazoMeses,
    required this.cuota,
    required this.estado,
    this.fechaSolicitud,
    this.fechaInicioPrestamo,
    this.fechaInicioPago,
    this.tipoPrestamo,
    this.frecuenciaTasa,
    this.esReenganche = false,
    this.prestamoOrigenId,
    this.motivoReenganche,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final double monto;
  final double tasaInteres;
  final int plazoMeses;
  final double cuota;
  final EstadoPrestamo estado;
  final DateTime? fechaSolicitud;
  final DateTime? fechaInicioPrestamo;
  final DateTime? fechaInicioPago;
  final String? tipoPrestamo;
  final String? frecuenciaTasa;

  /// `true` si esta solicitud reemplaza a un préstamo activo anterior
  /// (NOTES_REENGANCHE.md, sección 2).
  final bool esReenganche;
  final int? prestamoOrigenId;
  final String? motivoReenganche;

  factory PrestamoCreado.fromJson(Map<String, dynamic> json) {
    return PrestamoCreado(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      tasaInteres: (json['tasa_interes'] as num?)?.toDouble() ?? 0,
      plazoMeses: json['plazo_meses'] as int? ?? 0,
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      estado: estadoPrestamoFromString(json['estado']?.toString()),
      fechaSolicitud:
          Formatters.parseDate(json['fecha_solicitud']?.toString()),
      fechaInicioPrestamo:
          Formatters.parseDate(json['fecha_inicio_prestamo']?.toString()),
      fechaInicioPago:
          Formatters.parseDate(json['fecha_inicio_pago']?.toString()),
      tipoPrestamo: json['tipo_prestamo']?.toString(),
      frecuenciaTasa: json['frecuencia_tasa']?.toString(),
      esReenganche: json['es_reenganche'] as bool? ?? false,
      prestamoOrigenId: json['prestamo_origen_id'] as int?,
      motivoReenganche: json['motivo_reenganche']?.toString(),
    );
  }
}

/// Respuesta de `POST /prestamos/{id}/aprobar` (NOTES_PRESTAMOS.md,
/// sección 5.3).
class PrestamoAprobado {
  const PrestamoAprobado({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.estado,
    required this.cuota,
    required this.cantidadFacturasGeneradas,
    required this.puntuacionCliente,
    this.fechaAprobacion,
    this.esReenganche = false,
    this.prestamoOrigenId,
    this.facturasSaldadasPrestamoAnterior,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final EstadoPrestamo estado;
  final double cuota;
  final int cantidadFacturasGeneradas;
  final int puntuacionCliente;
  final DateTime? fechaAprobacion;

  /// `true` si al aprobar este préstamo se saldó un préstamo anterior
  /// (NOTES_REENGANCHE.md, sección 4).
  final bool esReenganche;
  final int? prestamoOrigenId;

  /// Cantidad de facturas del préstamo anterior marcadas como pagadas al
  /// aprobar este reenganche. `null` cuando `esReenganche` es `false`.
  final int? facturasSaldadasPrestamoAnterior;

  factory PrestamoAprobado.fromJson(Map<String, dynamic> json) {
    return PrestamoAprobado(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      estado: estadoPrestamoFromString(json['estado']?.toString()),
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      cantidadFacturasGeneradas:
          json['cantidad_facturas_generadas'] as int? ?? 0,
      puntuacionCliente: json['puntuacion_cliente'] as int? ?? 0,
      fechaAprobacion:
          Formatters.parseDate(json['fecha_aprobacion']?.toString()),
      esReenganche: json['es_reenganche'] as bool? ?? false,
      prestamoOrigenId: json['prestamo_origen_id'] as int?,
      facturasSaldadasPrestamoAnterior:
          json['facturas_saldadas_prestamo_anterior'] as int?,
    );
  }
}

/// Respuesta de `POST /prestamos/{id}/rechazar` (NOTES_PRESTAMOS.md,
/// sección 5.4).
class PrestamoRechazado {
  const PrestamoRechazado({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.estado,
    required this.puntuacionClienteAnterior,
    required this.puntuacionClienteNueva,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final EstadoPrestamo estado;
  final int puntuacionClienteAnterior;
  final int puntuacionClienteNueva;

  factory PrestamoRechazado.fromJson(Map<String, dynamic> json) {
    return PrestamoRechazado(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      estado: estadoPrestamoFromString(json['estado']?.toString()),
      puntuacionClienteAnterior:
          json['puntuacion_cliente_anterior'] as int? ?? 0,
      puntuacionClienteNueva: json['puntuacion_cliente_nueva'] as int? ?? 0,
    );
  }
}
