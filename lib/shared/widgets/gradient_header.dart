import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

/// Cabecera con gradiente compartida por las pantallas principales
/// (Dashboard, Detalle Préstamo, Detalle Cliente): mismo fondo
/// `LinearGradient([AppColors.primary, AppColors.primaryDarker])` y mismo
/// `BorderRadius.vertical(bottom: Radius.circular(28))`.
///
/// El contenido varía por pantalla, así que se compone con slots:
/// - [leading]: widget opcional a la izquierda del título (ej. avatar).
/// - [title]: texto principal, siempre presente.
/// - [subtitle]: widget opcional debajo del título, dentro de la misma
///   columna (ej. fecha, badges, líneas de datos adicionales). Cada pantalla
///   controla su propio espaciado interno (con `Padding`/`SizedBox`) ya que
///   el contenido y separación varían entre casos de uso.
/// - [trailing]: widget opcional a la derecha (ej. botón de logout).
/// - [bottom]: widget opcional debajo de toda la fila (leading/título/
///   trailing), a todo el ancho (ej. fila de estadísticas del dashboard).
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    this.leading,
    required this.title,
    this.titleStyle = const TextStyle(
      color: AppColors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
    this.titleMaxLines,
    this.titleOverflow,
    this.subtitle,
    this.trailing,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget? leading;
  final String title;
  final TextStyle titleStyle;
  final int? titleMaxLines;
  final TextOverflow? titleOverflow;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDarker],
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle,
                      maxLines: titleMaxLines,
                      overflow: titleOverflow,
                    ),
                    if (subtitle != null) subtitle!,
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
