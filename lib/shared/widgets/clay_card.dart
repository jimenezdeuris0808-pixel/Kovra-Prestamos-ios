import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';

/// Tarjeta con el efecto clay estándar de Kovra (superficie + sombra doble).
///
/// Reemplazo directo de `Card`/`Container` con sombra manual: envuelve
/// [child] en un `Container` con [ClayDecoration.surface].
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.color,
    this.radius = AppRadii.lg,
    this.pressed = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
  });

  final Widget child;
  final Color? color;
  final double radius;
  final bool pressed;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: ClayDecoration.surface(
        color: color,
        radius: radius,
        pressed: pressed,
      ),
      child: child,
    );
  }
}
