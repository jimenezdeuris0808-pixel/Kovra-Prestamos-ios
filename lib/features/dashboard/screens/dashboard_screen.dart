import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/categoria_severidad.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/severidad_mora.dart';
import '../../../domain/models/dashboard_resumen.dart';
import '../../../domain/models/factura.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/dashboard_cuota_tile.dart';
import '../../../shared/widgets/dashboard_stat_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/pill_tabs.dart';
import '../../../shared/widgets/severity_filter_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../prestamos/screens/detalle_prestamo_screen.dart';
import '../../prestamos/screens/prestamos_cartera_screen.dart';
import '../providers/dashboard_providers.dart';

/// Dashboard de cobros: resumen del día en un encabezado con estadísticas
/// en vivo, una sección de resumen denso de cartera (clientes, préstamos
/// activos, distribución por categoría y totales) y las cuotas de "Hoy" /
/// "Atrasadas" segmentadas por severidad de mora para priorizar visitas.
///
/// Toda la pantalla es una única página scrolleable (en vez del antiguo
/// `Column` con `Expanded(TabBarView)`): la sección de resumen denso agrega
/// suficiente contenido como para no caber siempre en una sola pantalla sin
/// scroll, así que se prioriza que todo el dashboard se vea de un vistazo
/// deslizando, en vez de reservarle al listado de cuotas un área fija que
/// en pantallas chicas quedaría demasiado angosta. Por eso la lista de
/// cuotas usa `shrinkWrap` y las tabs cambian por tap (ya no por swipe).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  SeveridadMora? _filtroSeveridad;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Sin TabBarView de por medio ya no hay swipe que animar: se reacciona
    // al cambio de índice apenas ocurre (no se espera a que termine la
    // animación interna del controller), para que el tap se sienta
    // inmediato.
    _tabController.addListener(() {
      setState(() => _filtroSeveridad = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrirPrestamo(Factura factura) {
    if (factura.prestamoId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetallePrestamoScreen(prestamoId: factura.prestamoId!),
      ),
    );
  }

  Future<void> _confirmarLogout() async {
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
  Widget build(BuildContext context) {
    final resumenAsync = ref.watch(dashboardResumenProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      body: SafeArea(
        child: resumenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardResumenProvider),
          ),
          data: (resumen) {
            final totalHoy = resumen.cuotasHoy
                .fold<double>(0, (acc, f) => acc + f.montoCuota);
            final cobradoHoy = resumen.cuotasHoy
                .fold<double>(0, (acc, f) => acc + f.montoPagado);
            final totalAtrasado = resumen.cuotasAtrasadas
                .fold<double>(0, (acc, f) => acc + f.totalConMora);

            final conteoSeveridad = <SeveridadMora, int>{};
            for (final f in resumen.cuotasAtrasadas) {
              final s = severidadDe(f);
              conteoSeveridad[s] = (conteoSeveridad[s] ?? 0) + 1;
            }

            final mostrandoHoy = _tabController.index == 0;
            final cuotasAtrasadasFiltradas = _filtroSeveridad == null
                ? resumen.cuotasAtrasadas
                : resumen.cuotasAtrasadas
                    .where((f) => severidadDe(f) == _filtroSeveridad)
                    .toList();
            final cuotasTabActual =
                mostrandoHoy ? resumen.cuotasHoy : cuotasAtrasadasFiltradas;
            final emptyMessage = mostrandoHoy
                ? 'No hay cuotas programadas para hoy.'
                : (_filtroSeveridad == null
                    ? 'No hay cuotas atrasadas. ¡Buen trabajo!'
                    : 'No hay cuotas en este nivel de severidad.');

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardResumenProvider);
                ref.invalidate(dashboardResumenGeneralProvider);
                await Future.wait([
                  ref.read(dashboardResumenProvider.future),
                  ref.read(dashboardResumenGeneralProvider.future),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      totalHoy: totalHoy,
                      cobradoHoy: cobradoHoy,
                      atrasadasCount: resumen.cuotasAtrasadas.length,
                      totalAtrasado: totalAtrasado,
                      onLogout: _confirmarLogout,
                    ),
                    const _ResumenGeneralSection(),
                    const SizedBox(height: AppSpacing.lg),
                    PillTabs(
                      controller: _tabController,
                      labels: const ['Hoy', 'Atrasadas'],
                    ),
                    if (!mostrandoHoy && resumen.cuotasAtrasadas.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      SeverityFilterBar<SeveridadMora>(
                        niveles: const [
                          SeveridadMora.reciente,
                          SeveridadMora.atrasada,
                          SeveridadMora.critica,
                          SeveridadMora.incobrable,
                        ],
                        labelOf: (s) => infoSeveridad(s).label,
                        colorOf: (s) => infoSeveridad(s).color,
                        counts: conteoSeveridad,
                        selected: _filtroSeveridad,
                        onSelected: (s) => setState(() => _filtroSeveridad = s),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _ListaCuotas(
                      cuotas: cuotasTabActual,
                      emptyMessage: emptyMessage,
                      onTap: _abrirPrestamo,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.totalHoy,
    required this.cobradoHoy,
    required this.atrasadasCount,
    required this.totalAtrasado,
    required this.onLogout,
  });

  final double totalHoy;
  final double cobradoHoy;
  final int atrasadasCount;
  final double totalAtrasado;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final hoy = Formatters.date(DateTime.now());

    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 22),
      title: 'Resumen de cobros',
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
      trailing: IconButton(
        onPressed: onLogout,
        tooltip: 'Cerrar sesión',
        icon: const Icon(Icons.logout, color: AppColors.white),
      ),
      bottom: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: DashboardStatTile(
                icon: Icons.event_available_outlined,
                label: 'Cuotas hoy',
                value: Formatters.currency(totalHoy),
                foreground: AppColors.white,
                background: AppColors.white.withOpacity(0.14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DashboardStatTile(
                icon: Icons.check_circle_outline,
                label: 'Cobrado hoy',
                value: Formatters.currency(cobradoHoy),
                foreground: AppColors.white,
                background: AppColors.white.withOpacity(0.14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DashboardStatTile(
                icon: Icons.warning_amber_outlined,
                label: '$atrasadasCount atrasadas',
                value: Formatters.currency(totalAtrasado),
                foreground: AppColors.white,
                background: AppColors.white.withOpacity(0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de resumen denso de cartera: pills de clientes, banner de
/// préstamos activos, grid de 7 categorías y totales del día. Consume
/// `GET /dashboard/resumen_general` de forma independiente del resumen de
/// cuotas (`dashboardResumenProvider`), así que tiene su propio estado de
/// carga/error y no bloquea el resto del dashboard si falla.
class _ResumenGeneralSection extends ConsumerWidget {
  const _ResumenGeneralSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenGeneralAsync = ref.watch(dashboardResumenGeneralProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: resumenGeneralAsync.when(
        loading: () => const _ResumenGeneralSkeleton(),
        error: (error, _) => ClayCard(
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.dangerStrong),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'No se pudo cargar el resumen de cartera.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(dashboardResumenGeneralProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (resumen) => _ResumenGeneralContent(resumen: resumen),
      ),
    );
  }
}

class _ResumenGeneralSkeleton extends StatelessWidget {
  const _ResumenGeneralSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: ClayDecoration.surface(radius: AppRadii.lg),
      child: const CircularProgressIndicator(),
    );
  }
}

class _ResumenGeneralContent extends StatelessWidget {
  const _ResumenGeneralContent({required this.resumen});

  final DashboardResumenGeneral resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientesPillsRow(
          total: resumen.totalClientes,
          activos: resumen.clientesActivos,
        ),
        const SizedBox(height: AppSpacing.md),
        _PrestamosBanner(cantidad: resumen.prestamosActivos),
        const SizedBox(height: AppSpacing.md),
        _CategoriasGrid(resumen: resumen),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TotalCard(
                icon: Icons.savings_outlined,
                label: 'Total cobrado',
                value: Formatters.currency(resumen.montoCobradoHoy),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: _TotalCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Total ventas',
                // Sin campo de API: decisión del equipo, ver
                // NOTES_DASHBOARD_RESUMEN.md sección 2, Decisión D.
                value: 'RD\$0.00',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fila "Clientes {total} / activos {clientes_activos}" bajo el header.
class _ClientesPillsRow extends StatelessWidget {
  const _ClientesPillsRow({required this.total, required this.activos});

  final int total;
  final int activos;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatusBadge(
          label: 'Clientes $total',
          color: AppColors.primary,
          icon: const Icon(Icons.people_alt_outlined,
              size: 13, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusBadge(
          label: 'activos $activos',
          color: AppColors.success,
          icon: const Icon(Icons.bolt_outlined,
              size: 13, color: AppColors.successStrong),
        ),
      ],
    );
  }
}

/// Banner destacado "PRÉSTAMOS {prestamos_activos}": el elemento visual
/// más importante de la sección de resumen denso, mismo gradiente de marca
/// que [GradientHeader].
class _PrestamosBanner extends StatelessWidget {
  const _PrestamosBanner({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDarker],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: ClayShadows.raised,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÉSTAMOS',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cantidad',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'préstamos activos en cartera',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid de las 7 categorías mutuamente excluyentes en que se distribuye la
/// cartera en gestión (ver `NOTES_DASHBOARD_RESUMEN.md`, sección 1.4-1.10).
/// Se arma con `LayoutBuilder` + `Wrap` en vez de `GridView` (evita lidiar
/// con `shrinkWrap`/`childAspectRatio` dentro de un `Column` no expandido):
/// 3 tiles por fila, la última fila queda con 1 tile alineado a la
/// izquierda del mismo ancho que el resto.
class _CategoriasGrid extends StatelessWidget {
  const _CategoriasGrid({required this.resumen});

  final DashboardResumenGeneral resumen;

  @override
  Widget build(BuildContext context) {
    final categorias = <_CategoriaData>[
      _CategoriaData(
        categoria: CategoriaSeveridad.pendiente,
        icon: Icons.hourglass_empty_outlined,
        label: 'Pendiente',
        value: resumen.pendiente,
        baseColor: AppColors.neutralGray,
        textColor: AppColors.textPrimary,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.aTiempo,
        icon: Icons.check_circle_outline,
        label: 'A tiempo',
        value: resumen.aTiempo,
        baseColor: AppColors.success,
        textColor: AppColors.successStrong,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.atrasado,
        icon: Icons.schedule_outlined,
        label: 'Atrasado',
        value: resumen.atrasado,
        baseColor: AppColors.warning,
        textColor: AppColors.textPrimary,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.vencido,
        icon: Icons.error_outline,
        label: 'Vencido',
        value: resumen.vencido,
        baseColor: AppColors.danger,
        textColor: AppColors.dangerStrong,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.enAcuerdo,
        icon: Icons.handshake_outlined,
        label: 'Acuerdo',
        value: resumen.enAcuerdo,
        baseColor: AppColors.accent,
        textColor: AppColors.primaryDark,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.incobrable,
        icon: Icons.block_outlined,
        label: 'Incobrable',
        value: resumen.incobrable,
        baseColor: AppColors.dangerStrong,
        textColor: AppColors.dangerStrong,
      ),
      _CategoriaData(
        categoria: CategoriaSeveridad.abonado,
        icon: Icons.payments_outlined,
        label: 'Abonado',
        value: resumen.abonado,
        baseColor: AppColors.accentLight,
        textColor: AppColors.primaryDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final tileWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final categoria in categorias)
              SizedBox(
                width: tileWidth,
                child: _CategoriaTile(data: categoria),
              ),
          ],
        );
      },
    );
  }
}

class _CategoriaData {
  const _CategoriaData({
    required this.categoria,
    required this.icon,
    required this.label,
    required this.value,
    required this.baseColor,
    required this.textColor,
  });

  /// Categoría de severidad que representa este tile — al tocarlo, navega
  /// a `PrestamosCarteraScreen` con este filtro ya aplicado.
  final CategoriaSeveridad categoria;
  final IconData icon;
  final String label;
  final int value;

  /// Color semántico base: solo se usa como fondo tenue e ícono, nunca
  /// como color de texto (ver `DESIGN_SYSTEM_CLAY.md`, secciones 1 y 6).
  final Color baseColor;

  /// Variante segura para el número (`successStrong`/`dangerStrong`/
  /// `textPrimary`/`primaryDark`, nunca el semántico base directo).
  final Color textColor;
}

/// Tile de categoría, tocable: navega a `PrestamosCarteraScreen` con el
/// filtro de esa categoría ya aplicado. La animación de presión (leve
/// achicamiento + ripple del color propio de la categoría) es la señal
/// estética de que el tile es interactivo, sin agregar chrome extra.
class _CategoriaTile extends StatefulWidget {
  const _CategoriaTile({required this.data});

  final _CategoriaData data;

  @override
  State<_CategoriaTile> createState() => _CategoriaTileState();
}

class _CategoriaTileState extends State<_CategoriaTile> {
  bool _presionado = false;

  void _abrirCartera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PrestamosCarteraScreen(initialCategoria: widget.data.categoria),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return AnimatedScale(
      scale: _presionado ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          splashColor: data.baseColor.withOpacity(0.18),
          highlightColor: data.baseColor.withOpacity(0.10),
          onTap: () => _abrirCartera(context),
          onTapDown: (_) => setState(() => _presionado = true),
          onTapCancel: () => setState(() => _presionado = false),
          onTapUp: (_) => setState(() => _presionado = false),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: data.baseColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: data.baseColor.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: data.baseColor.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, size: 15, color: data.baseColor),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: data.baseColor.withOpacity(0.55),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.value}',
                  style: TextStyle(
                    color: data.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

/// Tarjeta de total inferior ("Total cobrado" / "Total ventas").
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Color semántico base del ícono/acento; el texto del valor usa su
  /// variante de contraste seguro (ver `DESIGN_SYSTEM_CLAY.md`).
  final Color color;

  Color get _textColor {
    if (color == AppColors.success) return AppColors.successStrong;
    if (color == AppColors.danger) return AppColors.dangerStrong;
    if (color == AppColors.warning) return AppColors.textPrimary;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de cuotas de la tab activa. `shrinkWrap` + `NeverScrollableScrollPhysics`
/// porque ahora vive dentro del `SingleChildScrollView` de toda la pantalla
/// (ver comentario de [DashboardScreen]) en vez de tener su propio viewport
/// scrolleable independiente.
class _ListaCuotas extends StatelessWidget {
  const _ListaCuotas({
    required this.cuotas,
    required this.emptyMessage,
    required this.onTap,
  });

  final List<Factura> cuotas;
  final String emptyMessage;
  final void Function(Factura) onTap;

  @override
  Widget build(BuildContext context) {
    if (cuotas.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        message: emptyMessage,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
      itemCount: cuotas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final factura = cuotas[index];
        return DashboardCuotaTile(
          factura: factura,
          onTap: () => onTap(factura),
        );
      },
    );
  }
}
