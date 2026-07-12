import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'status_badge.dart';

/// Insignia visual para la puntuación de riesgo/crédito de un cliente.
/// Escala asumida: 0-100 (rojo bajo, ámbar medio, verde alto).
class PuntuacionBadge extends StatelessWidget {
  const PuntuacionBadge({super.key, required this.puntuacion});

  final int? puntuacion;

  Color get _color {
    final p = puntuacion ?? 0;
    if (p >= 70) return AppColors.success;
    if (p >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final valor = puntuacion?.toString() ?? '-';
    return StatusBadge(
      label: 'Puntuación: $valor',
      color: _color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      border: Border.all(color: _color, width: 1),
      icon: Icon(Icons.star_rounded, size: 16, color: _color),
    );
  }
}
