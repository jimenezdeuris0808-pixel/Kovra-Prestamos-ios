import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/cobros_hoy.dart';
import '../../../domain/models/factura.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/dashboard_cuota_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/pill_tabs.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../prestamos/screens/detalle_prestamo_screen.dart';

/// Pantalla "Cobrar" del bottom nav: cuotas atrasadas y pagos cobrados hoy
/// (`GET /dashboard/cobros_hoy`, ver
/// `Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md`, sección 4). Toggle
/// "Atrasados"/"Cobrados" + buscador client-side sobre la lista visible.
class CobrosHoyScreen extends ConsumerStatefulWidget {
  const CobrosHoyScreen({super.key});

  @override
  ConsumerState<CobrosHoyScreen> createState() => _CobrosHoyScreenState();
}

class _CobrosHoyScreenState extends ConsumerState<CobrosHoyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _abrirPrestamo(int? prestamoId) {
    if (prestamoId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetallePrestamoScreen(prestamoId: prestamoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cobrosAsync = ref.watch(dashboardCobrosHoyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      body: SafeArea(
        child: cobrosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardCobrosHoyProvider),
          ),
          data: (cobros) {
            final mostrandoAtrasados = _tabController.index == 0;
            final query = _query.trim().toLowerCase();

            final atrasadasFiltradas = query.isEmpty
                ? cobros.atrasadas
                : cobros.atrasadas
                    .where((f) =>
                        (f.clienteNombre ?? '').toLowerCase().contains(query))
                    .toList();
            final cobradasFiltradas = query.isEmpty
                ? cobros.cobradasHoy
                : cobros.cobradasHoy
                    .where((c) =>
                        c.clienteNombre.toLowerCase().contains(query))
                    .toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardCobrosHoyProvider);
                await ref.read(dashboardCobrosHoyProvider.future);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CobrosHeader(
                    totalPendiente: cobros.totalPendiente,
                    totalCobradoHoy: cobros.totalCobradoHoy,
                  ),
                  PillTabs(
                    controller: _tabController,
                    labels: const ['Atrasados', 'Cobrados'],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() => _query = ''),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: mostrandoAtrasados
                        ? _AtrasadasList(
                            facturas: atrasadasFiltradas,
                            hayOriginal: cobros.atrasadas.isNotEmpty,
                            onTap: (f) => _abrirPrestamo(f.prestamoId),
                          )
                        : _CobradasList(
                            cobradas: cobradasFiltradas,
                            hayOriginal: cobros.cobradasHoy.isNotEmpty,
                            onTap: (c) => _abrirPrestamo(c.prestamoId),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CobrosHeader extends StatelessWidget {
  const _CobrosHeader({
    required this.totalPendiente,
    required this.totalCobradoHoy,
  });

  final double totalPendiente;
  final double totalCobradoHoy;

  @override
  Widget build(BuildContext context) {
    final hoy = Formatters.date(DateTime.now());

    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          : null,
      title: 'Cobrar',
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          hoy,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.75),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _HeaderStat(
                icon: Icons.hourglass_bottom_outlined,
                label: 'Pendiente',
                value: Formatters.currency(totalPendiente),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _HeaderStat(
                icon: Icons.check_circle_outline,
                label: 'Cobrado',
                value: Formatters.currency(totalCobradoHoy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.75),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.sm),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            borderSide: BorderSide.none,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Tab "Atrasados": reusa `DashboardCuotaTile`, mismo modelo `Factura` que
/// `DashboardScreen` usa para su lista de atrasadas.
class _AtrasadasList extends StatelessWidget {
  const _AtrasadasList({
    required this.facturas,
    required this.hayOriginal,
    required this.onTap,
  });

  final List<Factura> facturas;
  final bool hayOriginal;
  final void Function(Factura) onTap;

  @override
  Widget build(BuildContext context) {
    if (facturas.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptyState(
          icon: Icons.event_available_outlined,
          message: hayOriginal
              ? 'Ningún cliente atrasado coincide con la búsqueda.'
              : 'No hay cuotas atrasadas. ¡Buen trabajo!',
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      itemCount: facturas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final factura = facturas[index];
        return DashboardCuotaTile(
          factura: factura,
          onTap: () => onTap(factura),
        );
      },
    );
  }
}

/// Tab "Cobrados": pagos registrados hoy.
class _CobradasList extends StatelessWidget {
  const _CobradasList({
    required this.cobradas,
    required this.hayOriginal,
    required this.onTap,
  });

  final List<CuotaCobradaHoy> cobradas;
  final bool hayOriginal;
  final void Function(CuotaCobradaHoy) onTap;

  @override
  Widget build(BuildContext context) {
    if (cobradas.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptyState(
          icon: Icons.payments_outlined,
          message: hayOriginal
              ? 'Ningún cobro coincide con la búsqueda.'
              : 'Aún no se ha registrado ningún cobro hoy.',
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      itemCount: cobradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cobro = cobradas[index];
        return _CobradaTile(cobro: cobro, onTap: () => onTap(cobro));
      },
    );
  }
}

class _CobradaTile extends StatelessWidget {
  const _CobradaTile({required this.cobro, required this.onTap});

  final CuotaCobradaHoy cobro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.successStrong, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cobro.clienteNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // `fecha_pago` viene solo con fecha (sin hora) en el
                    // contrato de `GET /dashboard/cobros_hoy`, ver
                    // NOTES_CARTERA_CLIENTES_COBROS.md sección 4.3.
                    '${_metodoLabel(cobro.metodo)} · ${Formatters.date(cobro.fechaPago)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.currency(cobro.monto),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.successStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metodoLabel(String metodo) {
    if (metodo.isEmpty) return 'Pago';
    return metodo[0].toUpperCase() + metodo.substring(1);
  }
}
