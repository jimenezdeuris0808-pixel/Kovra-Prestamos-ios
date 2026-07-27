import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/admin_notificacion.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../providers/admin_notificaciones_providers.dart';

/// Listado de notificaciones del panel de administrador (hoy solo
/// "cuenta nueva creada"). Sin canal externo (email/WhatsApp): la
/// notificación vive únicamente dentro de la app, se marca leída al tocarla.
class AdminNotificacionesScreen extends ConsumerWidget {
  const AdminNotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(adminNotificacionesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: notificacionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminNotificacionesProvider),
        ),
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              message: 'No hay notificaciones todavía.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminNotificacionesProvider);
              await ref.read(adminNotificacionesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: notificaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _NotificacionTile(notificacion: notificaciones[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificacionTile extends ConsumerWidget {
  const _NotificacionTile({required this.notificacion});

  final AdminNotificacion notificacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = Formatters.parseDate(notificacion.creadoEn);

    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: notificacion.leida
              ? null
              : () => ref
                  .read(adminNotificacionesControllerProvider.notifier)
                  .marcarLeida(notificacion.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.business_outlined,
                  color: notificacion.leida
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.mensaje,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              notificacion.leida ? FontWeight.w500 : FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(fecha),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notificacion.leida)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
