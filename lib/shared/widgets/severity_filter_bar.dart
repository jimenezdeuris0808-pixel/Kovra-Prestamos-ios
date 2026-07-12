import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/clay_decoration.dart';

/// Fila de chips de filtro por severidad, genérica sobre el tipo de nivel
/// [T] (ej. `SeveridadMora` para cuotas atrasadas del dashboard,
/// `CategoriaSeveridad` para la cartera de préstamos). Mismo componente
/// visual para ambos usos, solo cambian los niveles y sus colores/labels.
class SeverityFilterBar<T> extends StatelessWidget {
  const SeverityFilterBar({
    super.key,
    required this.niveles,
    required this.labelOf,
    required this.colorOf,
    this.textColorOf,
    required this.counts,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'Todas',
    this.allColor = AppColors.neutralGray,
  });

  /// Niveles a mostrar, en el orden en que se renderizan los chips.
  final List<T> niveles;
  final String Function(T nivel) labelOf;

  /// Color semántico base de cada nivel: fondo tenue del chip y el punto de
  /// color, nunca el texto directo.
  final Color Function(T nivel) colorOf;

  /// Color de texto legible sobre el fondo tenue. Si no se provee, se
  /// deriva de [colorOf] con el mismo mapeo de contraste seguro que
  /// [StatusBadge] (`success`/`danger`/`warning` -> variantes "Strong").
  final Color Function(T nivel)? textColorOf;

  /// Cantidad de ítems por nivel, para mostrar el número en cada chip.
  final Map<T, int> counts;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String allLabel;
  final Color allColor;

  static Color _defaultTextColor(Color color) {
    if (color == AppColors.success) return AppColors.successStrong;
    if (color == AppColors.danger) return AppColors.dangerStrong;
    if (color == AppColors.warning) return AppColors.textPrimary;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Chip(
            label: allLabel,
            dotColor: allColor,
            textColor: allColor,
            count: null,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final nivel in niveles) ...[
            const SizedBox(width: 8),
            _Chip(
              label: labelOf(nivel),
              dotColor: colorOf(nivel),
              textColor: textColorOf != null
                  ? textColorOf!(nivel)
                  : _defaultTextColor(colorOf(nivel)),
              count: counts[nivel] ?? 0,
              isSelected: selected == nivel,
              onTap: () => onSelected(nivel),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final Color textColor;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: dotColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: dotColor, width: 1.2),
              )
            : ClayDecoration.surface(radius: AppRadii.pill).copyWith(
                border: Border.all(
                  color: AppColors.neutralGray.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              count == null ? label : '$label · $count',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? textColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
