/// Métodos de pago soportados por la API.
enum MetodoPago { efectivo, transferencia, tarjeta, cheque }

extension MetodoPagoX on MetodoPago {
  String get label {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.cheque:
        return 'Cheque';
    }
  }

  /// Valor enviado al backend.
  String get apiValue {
    switch (this) {
      case MetodoPago.efectivo:
        return 'efectivo';
      case MetodoPago.transferencia:
        return 'transferencia';
      case MetodoPago.tarjeta:
        return 'tarjeta';
      case MetodoPago.cheque:
        return 'cheque';
    }
  }

  /// Si el método requiere número de referencia obligatorio.
  bool get requiereReferencia => this != MetodoPago.efectivo;
}

/// Resultado de `POST /pagos`, usado para construir el recibo.
class PagoResultado {
  const PagoResultado({
    required this.estadoFactura,
    required this.montoPagado,
    required this.mora,
    this.reciboUrl,
    this.montoTransaccion,
    this.metodo,
    this.referencia,
    this.folio,
    this.fecha,
    this.clienteNombre,
    this.cuotasAdicionalesSaldadas = 0,
    this.prestamoEstado,
  });

  final String estadoFactura;
  final double montoPagado;
  final double mora;
  final String? reciboUrl;

  /// Cuántas cuotas adicionales (más allá de la pagada directamente) quedaron
  /// saldadas por el excedente de este pago. Ver
  /// `Kovra_API/app/routers/pagos_router.py`.
  final int cuotasAdicionalesSaldadas;

  /// Estado del préstamo tras este pago (`"pagado"` si quedó saldado por
  /// completo).
  final String? prestamoEstado;

  // Campos adicionales usados para renderizar el recibo en pantalla,
  // completados localmente a partir de los datos del formulario.
  final double? montoTransaccion;
  final MetodoPago? metodo;
  final String? referencia;
  final String? folio;
  final DateTime? fecha;
  final String? clienteNombre;

  factory PagoResultado.fromJson(Map<String, dynamic> json) {
    return PagoResultado(
      estadoFactura: json['factura_estado']?.toString() ??
          json['estado_factura']?.toString() ??
          '',
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0,
      mora: (json['mora_cubierta'] as num?)?.toDouble() ??
          (json['mora'] as num?)?.toDouble() ??
          0,
      reciboUrl: json['recibo_url']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      cuotasAdicionalesSaldadas:
          json['cuotas_adicionales_saldadas'] as int? ?? 0,
      prestamoEstado: json['prestamo_estado']?.toString(),
    );
  }

  PagoResultado copyWith({
    double? montoTransaccion,
    MetodoPago? metodo,
    String? referencia,
    String? folio,
    DateTime? fecha,
    String? clienteNombre,
  }) {
    return PagoResultado(
      estadoFactura: estadoFactura,
      montoPagado: montoPagado,
      mora: mora,
      reciboUrl: reciboUrl,
      montoTransaccion: montoTransaccion ?? this.montoTransaccion,
      metodo: metodo ?? this.metodo,
      referencia: referencia ?? this.referencia,
      folio: folio ?? this.folio,
      fecha: fecha ?? this.fecha,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      cuotasAdicionalesSaldadas: cuotasAdicionalesSaldadas,
      prestamoEstado: prestamoEstado,
    );
  }
}
