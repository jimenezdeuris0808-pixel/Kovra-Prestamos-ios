import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/factura.dart';
import 'status_badge.dart';

/// Insignia visual del estado de una cuota/factura.
class EstadoFacturaBadge extends StatelessWidget {
  const EstadoFacturaBadge({super.key, required this.estado});

  final EstadoFactura estado;

  ({Color color, String label}) get _config {
    switch (estado) {
      case EstadoFactura.pagada:
        return (color: AppColors.success, label: 'Pagada');
      case EstadoFactura.atrasada:
        return (color: AppColors.danger, label: 'Atrasada');
      case EstadoFactura.parcial:
        return (color: AppColors.warning, label: 'Parcial');
      case EstadoFactura.pendiente:
        return (color: AppColors.accent, label: 'Pendiente');
      case EstadoFactura.desconocido:
        return (color: AppColors.neutralGray, label: 'Desconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return StatusBadge(label: config.label, color: config.color);
  }
}
