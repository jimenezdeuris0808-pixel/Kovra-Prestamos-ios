import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Sombras clay exactas, ver `DESIGN_SYSTEM_CLAY.md`, sección
/// "4. Sombra clay (`BoxShadow` para Flutter)".
class ClayShadows {
  ClayShadows._();

  /// Estado "raised" (default): tarjetas, botones no presionados, header.
  static final List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.shadowDark.withOpacity(0.35),
      offset: const Offset(6, 6),
      blurRadius: 16,
    ),
    BoxShadow(
      color: AppColors.shadowLight.withOpacity(0.85),
      offset: const Offset(-6, -6),
      blurRadius: 16,
    ),
  ];

  /// Estado "pressed / inset": botones activos, tab seleccionado, input con
  /// foco. Se combina con `AppColors.surfaceClayPressed` como fondo.
  static final List<BoxShadow> inset = [
    BoxShadow(
      color: AppColors.shadowDark.withOpacity(0.20),
      offset: const Offset(1, 1),
      blurRadius: 3,
    ),
  ];
}

/// Helper para construir `BoxDecoration`s con el efecto clay estándar.
class ClayDecoration {
  ClayDecoration._();

  static BoxDecoration surface({
    Color? color,
    double radius = AppRadii.lg,
    bool pressed = false,
  }) {
    return BoxDecoration(
      color: color ??
          (pressed ? AppColors.surfaceClayPressed : AppColors.surfaceClay),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: pressed ? ClayShadows.inset : ClayShadows.raised,
    );
  }
}
