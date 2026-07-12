import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';

/// Tabs tipo "pill" (N opciones) con el look clay estándar: contenedor con
/// [ClayDecoration.surface] y el pill activo resaltado con sombra inset y
/// color primario. Extraído del patrón original de `DashboardScreen`
/// (tabs "Hoy"/"Atrasadas") para reusarlo en otras pantallas con toggles de
/// 2+ opciones (ej. `CobrosHoyScreen`, "Atrasados"/"Cobrados").
class PillTabs extends StatefulWidget {
  const PillTabs({super.key, required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  State<PillTabs> createState() => _PillTabsState();
}

class _PillTabsState extends State<PillTabs> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: ClayDecoration.surface(radius: AppRadii.pill),
        child: Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.controller.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: widget.controller.index == i
                          ? AppColors.surfaceClayPressed
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      boxShadow: widget.controller.index == i
                          ? ClayShadows.inset
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.labels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: widget.controller.index == i
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
