import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';

/// Tarjeta de estadística compacta para el encabezado del dashboard
/// (ej. "Cuotas hoy", "Cobrado", "Atrasadas").
class DashboardStatTile extends StatelessWidget {
  const DashboardStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: foreground.withOpacity(0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
