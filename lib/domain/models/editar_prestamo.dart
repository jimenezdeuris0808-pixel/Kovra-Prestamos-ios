/// Resultado de `PATCH /prestamos/{id}/editar`.
class EditarPrestamoResultado {
  const EditarPrestamoResultado({
    required this.prestamoId,
    required this.tasaInteres,
    required this.capitalPendiente,
    this.interesProximaCuota,
  });

  final int prestamoId;
  final double tasaInteres;
  final double capitalPendiente;

  /// Nuevo monto de la cuota de interés pendiente, solo si el préstamo es
  /// "Plazo Indefinido" y tenía una cuota sin pagar que se recalculó.
  final double? interesProximaCuota;

  factory EditarPrestamoResultado.fromJson(Map<String, dynamic> json) {
    return EditarPrestamoResultado(
      prestamoId: json['prestamo_id'] as int? ?? 0,
      tasaInteres: (json['tasa_interes'] as num?)?.toDouble() ?? 0,
      capitalPendiente: (json['capital_pendiente'] as num?)?.toDouble() ?? 0,
      interesProximaCuota: (json['interes_proxima_cuota'] as num?)?.toDouble(),
    );
  }
}
