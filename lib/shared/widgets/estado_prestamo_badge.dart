import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/prestamo.dart';
import 'status_badge.dart';

/// Insignia visual del estado de un préstamo.
class EstadoPrestamoBadge extends StatelessWidget {
  const EstadoPrestamoBadge({super.key, required this.estado});

  final EstadoPrestamo estado;

  ({Color color, String label}) get _config {
    switch (estado) {
      case EstadoPrestamo.aprobado:
        return (color: AppColors.success, label: 'Aprobado');
      case EstadoPrestamo.enAcuerdo:
        return (color: AppColors.warning, label: 'En acuerdo');
      case EstadoPrestamo.pendiente:
        return (color: AppColors.neutralGray, label: 'Pendiente');
      case EstadoPrestamo.finalizado:
        return (color: AppColors.accent, label: 'Finalizado');
      case EstadoPrestamo.rechazado:
        return (color: AppColors.danger, label: 'Rechazado');
      case EstadoPrestamo.incobrable:
        return (color: AppColors.dangerStrong, label: 'Incobrable');
      case EstadoPrestamo.desconocido:
        return (color: AppColors.neutralGray, label: 'Desconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return StatusBadge(label: config.label, color: config.color);
  }
}
