import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/clay_decoration.dart';

/// Tarjeta compartida por las pantallas de login (usuario y administrador):
/// contenedor blanco con sombra y radio de 20, título, campos de formulario,
/// mensaje de error inline opcional, botón de submit y pie opcional.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.fields,
    this.errorMessage,
    required this.submitButton,
    this.footer,
  });

  /// Título mostrado en la parte superior de la tarjeta.
  final String title;

  /// Campos del formulario (incluye el espaciado interno entre ellos).
  final List<Widget> fields;

  /// Mensaje de error inline, mostrado debajo de los campos si no es null.
  final String? errorMessage;

  /// Botón de envío del formulario.
  final Widget submitButton;

  /// Contenido opcional debajo del botón de submit (ej. link secundario).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: ClayDecoration.surface(
        color: AppColors.surfaceClay,
        radius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 20),
          ...fields,
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.dangerStrong,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          submitButton,
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}
