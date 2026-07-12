import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../clientes/screens/clientes_screen.dart';
import '../../credito/screens/data_credito_screen.dart';
import '../../empresa/screens/mi_empresa_screen.dart';
import '../../prestamos/screens/datapresamo_screen.dart';
import '../../prestamos/screens/prestamos_cartera_screen.dart';
import '../../prestamos/screens/solicitudes_pendientes_screen.dart';

class _Modulo {
  const _Modulo({required this.label, required this.icon, required this.builder});

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// Pantalla "Modulos": grilla de accesos rápidos a otras secciones de la
/// app, tab "Modulos" del nuevo bottom nav flotante.
///
/// Préstamos / Clientes / Solicitudes (NOTES_CARTERA_CLIENTES_COBROS.md,
/// sección 5.1), más Datapréstamo (buscador histórico) y Mi Empresa
/// (branding para recibos). Es intencional que "Préstamos" aparezca tanto
/// en el bottom nav como acá: misma pantalla, sin contrato de API distinto.
class ModulosScreen extends StatelessWidget {
  const ModulosScreen({super.key});

  static final _modulos = <_Modulo>[
    _Modulo(
      label: 'Préstamos',
      icon: Icons.payments_outlined,
      builder: (_) => const PrestamosCarteraScreen(),
    ),
    _Modulo(
      label: 'Clientes',
      icon: Icons.people_alt_outlined,
      builder: (_) => const ClientesScreen(),
    ),
    _Modulo(
      label: 'Solicitudes',
      icon: Icons.pending_actions_outlined,
      builder: (_) => const SolicitudesPendientesScreen(),
    ),
    _Modulo(
      label: 'Datapréstamo',
      icon: Icons.search_outlined,
      builder: (_) => const DatapresamoScreen(),
    ),
    _Modulo(
      label: 'Mi Empresa',
      icon: Icons.storefront_outlined,
      builder: (_) => const MiEmpresaScreen(),
    ),
    _Modulo(
      label: 'Data Crédito',
      icon: Icons.fact_check_outlined,
      builder: (_) => const DataCreditoScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Módulos')),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _modulos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (context, index) {
          final modulo = _modulos[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: modulo.builder),
            ),
            child: ClayCard(
              radius: AppRadii.md,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(modulo.icon, size: 32, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    modulo.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
