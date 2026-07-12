import '../../core/utils/formatters.dart';

/// Ítem de `GET /prestamos/cartera` (NOTES_CARTERA_CLIENTES_COBROS.md,
/// sección 1.5-1.6). `estado` y `categoriaSeveridad` son campos distintos
/// con propósitos distintos: `estado` es el estado de negocio del préstamo,
/// `categoriaSeveridad` alimenta el chip de color de severidad (una de 7
/// categorías mutuamente excluyentes, ver `core/utils/categoria_severidad.dart`).
class PrestamoCarteraItem {
  const PrestamoCarteraItem({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.frecuencia,
    required this.estado,
    required this.categoriaSeveridad,
    required this.diasAtraso,
    this.proximaCuotaFecha,
    required this.capital,
    required this.restante,
    required this.montoPagadoAcumulado,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final String frecuencia;
  final String estado;
  final String categoriaSeveridad;
  final int diasAtraso;
  final DateTime? proximaCuotaFecha;
  final double capital;
  final double restante;
  final double montoPagadoAcumulado;

  factory PrestamoCarteraItem.fromJson(Map<String, dynamic> json) {
    return PrestamoCarteraItem(
      id: json['id'] as int? ?? 0,
      clienteId: json['cliente_id'] as int? ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      frecuencia: json['frecuencia']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      categoriaSeveridad: json['categoria_severidad']?.toString() ?? '',
      diasAtraso: json['dias_atraso'] as int? ?? 0,
      proximaCuotaFecha:
          Formatters.parseDate(json['proxima_cuota_fecha']?.toString()),
      capital: (json['capital'] as num?)?.toDouble() ?? 0,
      restante: (json['restante'] as num?)?.toDouble() ?? 0,
      montoPagadoAcumulado:
          (json['monto_pagado_acumulado'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Totales de cabecera de la cartera activa (solo `aprobado`+`en_acuerdo`,
/// ver NOTES sección 1.4 punto 5: "cartera activa ahora", no acumulado
/// histórico).
class CarteraTotales {
  const CarteraTotales({
    required this.totalFinanciado,
    required this.totalCobrado,
    required this.porcentajeCobrado,
  });

  final double totalFinanciado;
  final double totalCobrado;
  final double porcentajeCobrado;

  factory CarteraTotales.fromJson(Map<String, dynamic> json) {
    return CarteraTotales(
      totalFinanciado: (json['total_financiado'] as num?)?.toDouble() ?? 0,
      totalCobrado: (json['total_cobrado'] as num?)?.toDouble() ?? 0,
      porcentajeCobrado: (json['porcentaje_cobrado'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Respuesta completa de `GET /prestamos/cartera`.
class PrestamosCarteraOut {
  const PrestamosCarteraOut({required this.items, required this.totales});

  final List<PrestamoCarteraItem> items;
  final CarteraTotales totales;

  factory PrestamosCarteraOut.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return PrestamosCarteraOut(
      items: rawItems
          .map((e) => PrestamoCarteraItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totales: CarteraTotales.fromJson(
        json['totales'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
