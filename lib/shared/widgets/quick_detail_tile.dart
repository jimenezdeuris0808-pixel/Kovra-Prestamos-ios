import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';

/// Tarjeta de dato rápido para grillas 2x2 ("Detalles rápidos") en Detalle
/// de préstamo / Detalle de cliente.
class QuickDetailTile extends StatelessWidget {
  const QuickDetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.primaryDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, size: 16, color: valueColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
