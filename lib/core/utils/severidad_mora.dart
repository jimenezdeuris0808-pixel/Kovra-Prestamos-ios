import 'package:flutter/material.dart';

import '../../domain/models/factura.dart';
import '../theme/app_colors.dart';

/// Nivel de riesgo de una cuota atrasada, calculado a partir de los días
/// transcurridos desde su vencimiento (no viene de la API: se deriva en el
/// cliente para poder segmentar visualmente la lista de cobros).
enum SeveridadMora { alDia, reciente, atrasada, critica, incobrable }

class SeveridadInfo {
  const SeveridadInfo({required this.color, required this.label});

  final Color color;
  final String label;
}

/// Días transcurridos desde el vencimiento de [factura] (0 si aún no vence).
int diasVencida(Factura factura) {
  final vencimiento = factura.fechaVencimiento;
  if (vencimiento == null) return 0;
  final hoy = DateTime.now();
  final dias = DateTime(hoy.year, hoy.month, hoy.day)
      .difference(DateTime(vencimiento.year, vencimiento.month, vencimiento.day))
      .inDays;
  return dias < 0 ? 0 : dias;
}

SeveridadMora severidadDe(Factura factura) {
  if (factura.estado == EstadoFactura.pagada) return SeveridadMora.alDia;
  final dias = diasVencida(factura);
  if (dias <= 0) return SeveridadMora.alDia;
  if (dias <= 3) return SeveridadMora.reciente;
  if (dias <= 7) return SeveridadMora.atrasada;
  if (dias <= 15) return SeveridadMora.critica;
  return SeveridadMora.incobrable;
}

SeveridadInfo infoSeveridad(SeveridadMora severidad) {
  switch (severidad) {
    case SeveridadMora.alDia:
      return const SeveridadInfo(color: AppColors.success, label: 'Al día');
    case SeveridadMora.reciente:
      return const SeveridadInfo(
          color: AppColors.severityMild, label: 'Reciente');
    case SeveridadMora.atrasada:
      return const SeveridadInfo(
          color: AppColors.severityHigh, label: 'Atrasada');
    case SeveridadMora.critica:
      return const SeveridadInfo(color: AppColors.danger, label: 'Crítica');
    case SeveridadMora.incobrable:
      return const SeveridadInfo(
          color: AppColors.severityLoss, label: 'Alto riesgo');
  }
}
