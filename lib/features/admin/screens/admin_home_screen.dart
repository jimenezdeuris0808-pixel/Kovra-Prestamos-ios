import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/tenant_admin.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/admin_tenants_providers.dart';
import 'admin_tenant_detail_screen.dart';

/// Pantalla principal de administrador: listado de tenants (empresas)
/// con su estado y vigencia.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(adminTenantsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: const Text('Administración'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => _confirmarLogout(context, ref),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: tenantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminTenantsProvider),
        ),
        data: (tenants) {
          if (tenants.isEmpty) {
            return const EmptyState(
              icon: Icons.business_outlined,
              message: 'No hay empresas registradas todavía.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminTenantsProvider);
              await ref.read(adminTenantsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: tenants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _TenantTile(tenant: tenants[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({required this.tenant});

  final TenantAdmin tenant;

  @override
  Widget build(BuildContext context) {
    final fechaExpiracion = Formatters.parseDate(tenant.fechaExpiracion);
    final vigenciaTexto = fechaExpiracion == null
        ? 'Sin vencimiento'
        : 'Vence: ${Formatters.date(fechaExpiracion)}';

    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminTenantDetailScreen(tenant: tenant),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.nombreEmpresa,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vigenciaTexto,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusBadge(
                  label: tenant.activo ? 'Activo' : 'Inactivo',
                  color: tenant.activo ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
