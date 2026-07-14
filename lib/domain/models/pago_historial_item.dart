import 'pago.dart';

/// Un pago ya registrado (`GET /clientes/{id}/pagos`), con todo lo
/// necesario para reconstruir su recibo -- para reenviar o reimprimir el
/// comprobante de un cobro pasado, no solo el del pago recién hecho.
class PagoHistorialItem {
  const PagoHistorialItem({
    required this.id,
    required this.facturaId,
    required this.prestamoId,
    required this.numeroCuota,
    required this.clienteNombre,
    required this.fechaPago,
    required this.monto,
    required this.metodo,
    this.referencia,
    required this.montoCapital,
    required this.montoInteres,
    required this.moraCubierta,
    required this.estadoFactura,
  });

  final int id;
  final int facturaId;
  final int prestamoId;
  final int numeroCuota;
  final String clienteNombre;
  final DateTime fechaPago;
  final double monto;
  final String metodo;
  final String? referencia;
  final double montoCapital;
  final double montoInteres;
  final double moraCubierta;
  final String estadoFactura;

  factory PagoHistorialItem.fromJson(Map<String, dynamic> json) {
    return PagoHistorialItem(
      id: json['id'] as int? ?? 0,
      facturaId: json['factura_id'] as int? ?? 0,
      prestamoId: json['prestamo_id'] as int? ?? 0,
      numeroCuota: json['numero_cuota'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      fechaPago: DateTime.tryParse(json['fecha_pago']?.toString() ?? '') ??
          DateTime.now(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodo: json['metodo']?.toString() ?? '',
      referencia: json['referencia']?.toString(),
      montoCapital: (json['monto_capital'] as num?)?.toDouble() ?? 0,
      montoInteres: (json['monto_interes'] as num?)?.toDouble() ?? 0,
      moraCubierta: (json['mora_cubierta'] as num?)?.toDouble() ?? 0,
      estadoFactura: json['estado_factura']?.toString() ?? '',
    );
  }

  /// Convierte este pago histórico al mismo modelo [PagoResultado] que usa
  /// `ReciboPagoScreen` para el recibo del pago recién hecho -- así se
  /// reutiliza exactamente la misma pantalla/UI de recibo para reenviar o
  /// reimprimir un cobro pasado, en vez de duplicar el diseño del recibo.
  PagoResultado toPagoResultado() {
    final metodoEnum = MetodoPago.values.firstWhere(
      (m) => m.apiValue == metodo,
      orElse: () => MetodoPago.efectivo,
    );
    return PagoResultado(
      estadoFactura: estadoFactura,
      montoPagado: monto,
      mora: moraCubierta,
      montoTransaccion: monto,
      metodo: metodoEnum,
      referencia: referencia,
      folio: 'PG-$facturaId-$id',
      fecha: fechaPago,
      clienteNombre: clienteNombre,
    );
  }
}
