import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/vigencia_banner.dart';
import '../cobros/screens/cobros_hoy_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../prestamos/screens/prestamos_cartera_screen.dart';
import 'screens/modulos_screen.dart';

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Shell principal tras login: barra de navegación flotante de 4 tabs
/// (Inicio / Prestamos / Cobrar / Modulos).
///
/// Cuando la cuenta está bloqueada por vigencia vencida
/// ([cuentaBloqueadaProvider], reflejo de `TenantBranding.cuentaBloqueada`),
/// las 4 pantallas reales dejan de mostrarse -- todas dependen de endpoints
/// que el backend ya rechaza con 403 (ver
/// `Kovra_API/app/auth.py::get_current_token_vigente`), así que en vez de
/// dejar que cada una muestre su propio error por separado, se reemplaza el
/// contenido por un aviso único y cada ícono del nav muestra un candado.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    PrestamosCarteraScreen(),
    CobrosHoyScreen(),
    ModulosScreen(),
  ];

  static const _items = [
    _NavItem(label: 'Inicio', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(label: 'Prestamos', icon: Icons.payments_outlined, activeIcon: Icons.payments),
    _NavItem(label: 'Cobrar', icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale),
    _NavItem(label: 'Modulos', icon: Icons.apps_outlined, activeIcon: Icons.apps),
  ];

  void _onTapBloqueado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tu cuenta está bloqueada por falta de pago. Contacta a tu '
          'suplidor de servicio Kovra para reactivarla.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = ref.watch(cuentaBloqueadaProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      extendBody: true,
      body: Column(
        children: [
          // Solo el banner necesita su propio SafeArea -- cada pantalla de
          // _screens ya trae su propio Scaffold/SafeArea interno.
          const SafeArea(bottom: false, child: VigenciaBanner()),
          Expanded(
            child: bloqueado
                ? const _CuentaBloqueadaView()
                : IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingPillNavBar(
        items: _items,
        currentIndex: _currentIndex,
        bloqueado: bloqueado,
        onTap: bloqueado
            ? (_) => _onTapBloqueado()
            : (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Reemplaza el contenido de las 4 tabs mientras la cuenta esté bloqueada:
/// todas dependen de endpoints que el backend ya rechaza, así que no tiene
/// sentido mostrar 4 pantallas rotas por separado.
class _CuentaBloqueadaView extends StatelessWidget {
  const _CuentaBloqueadaView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'Cuenta bloqueada',
          message:
              'Tu servicio Kovra está vencido. Ningún módulo estará '
              'disponible hasta que se reactive el pago. Contacta a tu '
              'suplidor de servicio Kovra.',
        ),
      ),
    );
  }
}

class _FloatingPillNavBar extends StatelessWidget {
  const _FloatingPillNavBar({
    required this.items,
    required this.currentIndex,
    required this.bloqueado,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final bool bloqueado;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: ClayDecoration.surface(
          color: AppColors.surfaceClay,
          radius: AppRadii.pill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(child: _buildItem(context, i)),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = items[index];
    final selected = !bloqueado && index == currentIndex;
    final color = bloqueado
        ? AppColors.textSecondary.withOpacity(0.5)
        : (selected ? AppColors.primary : AppColors.textSecondary);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceClayPressed : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: color,
                ),
                if (bloqueado)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundClay,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
