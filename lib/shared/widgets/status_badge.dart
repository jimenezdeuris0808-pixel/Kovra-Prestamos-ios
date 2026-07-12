import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

/// Pill genérico de estado: fondo del [color] al 12% de opacidad, radio
/// pill y texto en un tono legible acorde al [color] base. Base compartida
/// por los badges de estado, puntuación y demás insignias de la app.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.border,
    this.icon,
  });

  final String label;
  final Color color;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;
  final Widget? icon;

  /// Color de texto legible sobre el fondo tenue del badge.
  ///
  /// Los colores semánticos base (`success`/`danger`/`warning`) no tienen
  /// contraste suficiente como texto sobre superficies claras (ver
  /// `DESIGN_SYSTEM_CLAY.md`, secciones 1 y 6): se mapean a sus variantes
  /// "Strong" (o a `textPrimary` en el caso de `warning`, que no tiene
  /// variante Strong propia). El fondo (`color.withOpacity(0.12)`) conserva
  /// siempre el color semántico base sin cambios.
  Color get _textColor {
    if (color == AppColors.success) return AppColors.successStrong;
    if (color == AppColors.danger) return AppColors.dangerStrong;
    if (color == AppColors.warning) return AppColors.textPrimary;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: border,
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                const SizedBox(width: 4),
                text,
              ],
            ),
    );
  }
}
