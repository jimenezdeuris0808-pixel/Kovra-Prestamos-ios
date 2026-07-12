import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';
import '../../domain/models/cliente.dart';
import 'puntuacion_badge.dart';

/// Tarjeta reutilizable para mostrar un cliente en listas (búsqueda, etc.).
class ClienteCard extends StatelessWidget {
  const ClienteCard({super.key, required this.cliente, this.onTap});

  final Cliente cliente;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    cliente.nombre.isNotEmpty
                        ? cliente.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cédula: ${cliente.cedula}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (cliente.telefono != null &&
                          cliente.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cliente.telefono!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PuntuacionBadge(puntuacion: cliente.puntuacion),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
