/// Resultado de `POST /prestamos/{id}/abono` (abono libre a capital).
class AbonoCapitalResultado {
  const AbonoCapitalResultado({
    required this.prestamoId,
    required this.pagoId,
    required this.montoAbonado,
    required this.capitalPendienteAnterior,
    required this.capitalPendienteNuevo,
    this.interesProximaCuota,
    required this.fecha,
  });

  final int prestamoId;
  final int pagoId;
  final double montoAbonado;
  final double capitalPendienteAnterior;
  final double capitalPendienteNuevo;

  /// Nuevo monto de la próxima cuota de interés, solo si el préstamo es
  /// "Plazo Indefinido" y tenía una cuota pendiente que se recalculó con
  /// el capital ya reducido. `null` en cualquier otro caso.
  final double? interesProximaCuota;
  final String fecha;

  factory AbonoCapitalResultado.fromJson(Map<String, dynamic> json) {
    return AbonoCapitalResultado(
      prestamoId: json['prestamo_id'] as int? ?? 0,
      pagoId: json['pago_id'] as int? ?? 0,
      montoAbonado: (json['monto_abonado'] as num?)?.toDouble() ?? 0,
      capitalPendienteAnterior:
          (json['capital_pendiente_anterior'] as num?)?.toDouble() ?? 0,
      capitalPendienteNuevo:
          (json['capital_pendiente_nuevo'] as num?)?.toDouble() ?? 0,
      interesProximaCuota:
          (json['interes_proxima_cuota'] as num?)?.toDouble(),
      fecha: json['fecha']?.toString() ?? '',
    );
  }
}
