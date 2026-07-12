import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Las 7 categorías de severidad de un préstamo en cartera
/// (`categoria_severidad` de `GET /prestamos/cartera`), mutuamente
/// excluyentes entre sí. Distinta de [SeveridadMora]: esa se deriva
/// client-side de una cuota puntual, esta viene calculada por el backend
/// para el préstamo completo.
///
/// Mismos colores que `DashboardScreen::_CategoriasGrid` (ver
/// `Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md`, sección 6).
enum CategoriaSeveridad {
  pendiente,
  aTiempo,
  atrasado,
  vencido,
  enAcuerdo,
  incobrable,
  abonado,
}

CategoriaSeveridad categoriaSeveridadFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'pendiente':
      return CategoriaSeveridad.pendiente;
    case 'a_tiempo':
      return CategoriaSeveridad.aTiempo;
    case 'atrasado':
      return CategoriaSeveridad.atrasado;
    case 'vencido':
      return CategoriaSeveridad.vencido;
    case 'en_acuerdo':
      return CategoriaSeveridad.enAcuerdo;
    case 'incobrable':
      return CategoriaSeveridad.incobrable;
    case 'abonado':
      return CategoriaSeveridad.abonado;
    default:
      return CategoriaSeveridad.pendiente;
  }
}

class CategoriaSeveridadInfo {
  const CategoriaSeveridadInfo({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;

  /// Color semántico base: fondo tenue e ícono, nunca texto directo.
  final Color background;

  /// Variante de contraste seguro para texto sobre el fondo tenue (ver
  /// `DESIGN_SYSTEM_CLAY.md`, secciones 1 y 6).
  final Color textColor;
}

CategoriaSeveridadInfo infoCategoriaSeveridad(CategoriaSeveridad categoria) {
  switch (categoria) {
    case CategoriaSeveridad.pendiente:
      return const CategoriaSeveridadInfo(
        label: 'Pendiente',
        background: AppColors.neutralGray,
        textColor: AppColors.textPrimary,
      );
    case CategoriaSeveridad.aTiempo:
      return const CategoriaSeveridadInfo(
        label: 'A tiempo',
        background: AppColors.success,
        textColor: AppColors.successStrong,
      );
    case CategoriaSeveridad.atrasado:
      return const CategoriaSeveridadInfo(
        label: 'Atrasado',
        background: AppColors.warning,
        textColor: AppColors.textPrimary,
      );
    case CategoriaSeveridad.vencido:
      return const CategoriaSeveridadInfo(
        label: 'Vencido',
        background: AppColors.danger,
        textColor: AppColors.dangerStrong,
      );
    case CategoriaSeveridad.enAcuerdo:
      return const CategoriaSeveridadInfo(
        label: 'En acuerdo',
        background: AppColors.accent,
        textColor: AppColors.primaryDark,
      );
    case CategoriaSeveridad.incobrable:
      return const CategoriaSeveridadInfo(
        label: 'Incobrable',
        background: AppColors.dangerStrong,
        textColor: AppColors.dangerStrong,
      );
    case CategoriaSeveridad.abonado:
      return const CategoriaSeveridadInfo(
        label: 'Abonado',
        background: AppColors.accentLight,
        textColor: AppColors.primaryDark,
      );
  }
}
