import 'package:flutter/material.dart';

/// Paleta de color corporativa de Kovra.
class AppColors {
  AppColors._();

  // Primarios
  static const Color primary = Color(0xFF154D86);
  static const Color primaryDark = Color(0xFF0E3B70);
  static const Color primaryDarker = Color(0xFF1F62A8);

  // Acentos
  static const Color accent = Color(0xFF2C78C5);
  static const Color accentLight = Color(0xFF5CA2E7);
  static const Color accentLighter = Color(0xFF7DA9D9);

  // Texto
  static const Color textOnPrimary = Colors.white;

  // Semánticos
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Escala de severidad de mora (al día -> alto riesgo), para clasificar
  // cuotas atrasadas más allá del simple "pagada/atrasada".
  static const Color severityMild = Color(0xFFF6C453);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityLoss = Color(0xFF1F2937);

  // Neutros
  static const Color neutralLight = Color(0xFFEEF0F2);
  static const Color neutralGray = Color(0xFF64748B);
  static const Color background = Color(0xFFF7F8FA);
  static const Color white = Color(0xFFFFFFFF);

  // Clay — fondo y superficies (ver DESIGN_SYSTEM_CLAY.md)
  static const Color backgroundClay = Color(0xFFE7EDF6);
  static const Color surfaceClay = Color(0xFFF2F6FB);
  static const Color surfaceClayPressed = Color(0xFFDCE4F0);

  // Clay — sombras
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFA9B7CE);

  // Clay — texto (reemplazan neutralGray para texto sobre backgroundClay)
  static const Color textPrimary = Color(0xFF1B2430);
  static const Color textSecondary = Color(0xFF4B5768);

  // Clay — variantes "Strong" de semánticos, aptas como color de texto
  static const Color successStrong = Color(0xFF166534);
  static const Color dangerStrong = Color(0xFFB91C1C);
}
