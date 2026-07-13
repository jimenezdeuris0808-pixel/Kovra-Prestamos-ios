import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';
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
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      extendBody: true,
      body: Column(
        children: [
          // Solo el banner necesita su propio SafeArea -- cada pantalla de
          // _screens ya trae su propio Scaffold/SafeArea interno.
          const SafeArea(bottom: false, child: VigenciaBanner()),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingPillNavBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _FloatingPillNavBar extends StatelessWidget {
  const _FloatingPillNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
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
    final selected = index == currentIndex;
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
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
