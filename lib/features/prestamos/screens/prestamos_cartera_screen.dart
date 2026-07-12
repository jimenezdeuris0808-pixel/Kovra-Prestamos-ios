import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/categoria_severidad.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/prestamo_cartera.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/severity_filter_bar.dart';
import '../providers/prestamos_providers.dart';
import 'detalle_prestamo_screen.dart';

/// Pantalla "Préstamos" del bottom nav: cartera de préstamos en gestión
/// (`pendiente`/`aprobado`/`en_acuerdo`/`incobrable`, ver
/// `Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md`, sección 1). Cabecera con
/// totales de cobro, buscador client-side y filtro por severidad.
class PrestamosCarteraScreen extends ConsumerStatefulWidget {
  const PrestamosCarteraScreen({super.key, this.initialCategoria});

  /// Filtro de severidad ya aplicado al entrar (ej. al llegar desde un tile
  /// del dashboard tocado por el usuario, como "A tiempo" o "Atrasado").
  final CategoriaSeveridad? initialCategoria;

  @override
  ConsumerState<PrestamosCarteraScreen> createState() =>
      _PrestamosCarteraScreenState();
}

class _PrestamosCarteraScreenState
    extends ConsumerState<PrestamosCarteraScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late CategoriaSeveridad? _filtroCategoria = widget.initialCategoria;

  static const _categorias = [
    CategoriaSeveridad.pendiente,
    CategoriaSeveridad.aTiempo,
    CategoriaSeveridad.atrasado,
    CategoriaSeveridad.vencido,
    CategoriaSeveridad.enAcuerdo,
    CategoriaSeveridad.incobrable,
    CategoriaSeveridad.abonado,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirPrestamo(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetallePrestamoScreen(prestamoId: id)),
    );
  }

  List<PrestamoCarteraItem> _filtrar(List<PrestamoCarteraItem> items) {
    var resultado = items;
    if (_filtroCategoria != null) {
      resultado = resultado
          .where((item) =>
              categoriaSeveridadFromString(item.categoriaSeveridad) ==
              _filtroCategoria)
          .toList();
    }
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado
          .where((item) => item.clienteNombre.toLowerCase().contains(query))
          .toList();
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final carteraAsync = ref.watch(prestamosCarteraProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      body: SafeArea(
        child: carteraAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(prestamosCarteraProvider),
          ),
          data: (cartera) {
            final itemsFiltrados = _filtrar(cartera.items);

            final conteoPorCategoria = <CategoriaSeveridad, int>{};
            for (final item in cartera.items) {
              final categoria =
                  categoriaSeveridadFromString(item.categoriaSeveridad);
              conteoPorCategoria[categoria] =
                  (conteoPorCategoria[categoria] ?? 0) + 1;
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(prestamosCarteraProvider);
                await ref.read(prestamosCarteraProvider.future);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CarteraHeader(totales: cartera.totales),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                    child: _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() => _query = ''),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SeverityFilterBar<CategoriaSeveridad>(
                    niveles: _categorias,
                    labelOf: (c) => infoCategoriaSeveridad(c).label,
                    colorOf: (c) => infoCategoriaSeveridad(c).background,
                    textColorOf: (c) => infoCategoriaSeveridad(c).textColor,
                    counts: conteoPorCategoria,
                    selected: _filtroCategoria,
                    onSelected: (c) =>
                        setState(() => _filtroCategoria = c),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: itemsFiltrados.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: EmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              message: cartera.items.isEmpty
                                  ? 'No hay préstamos en cartera.'
                                  : 'Ningún préstamo coincide con la búsqueda\no el filtro seleccionado.',
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xs,
                                AppSpacing.lg,
                                AppSpacing.lg),
                            itemCount: itemsFiltrados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = itemsFiltrados[index];
                              return _PrestamoCarteraTile(
                                item: item,
                                onTap: () => _abrirPrestamo(item.id),
                              );
                            },
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

/// Cabecera "TOTAL {..}" / "COBRADO {..} ({%})" con barra de progreso
/// lineal, mismo gradiente que [GradientHeader].
class _CarteraHeader extends StatelessWidget {
  const _CarteraHeader({required this.totales});

  final CarteraTotales totales;

  @override
  Widget build(BuildContext context) {
    final progreso = totales.totalFinanciado > 0
        ? (totales.porcentajeCobrado / 100).clamp(0.0, 1.0)
        : 0.0;

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
      title: 'Préstamos',
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Cartera activa en gestión',
          style: TextStyle(
            color: AppColors.white.withOpacity(0.75),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    label: 'TOTAL',
                    value: Formatters.currency(totales.totalFinanciado),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _HeaderStat(
                    label: 'COBRADO',
                    value:
                        '${Formatters.currency(totales.totalCobrado)} (${totales.porcentajeCobrado.toStringAsFixed(0)}%)',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: AppColors.white.withOpacity(0.18),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.accentLight),
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
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
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
      ],
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

/// Tarjeta de un préstamo en cartera: cliente, frecuencia, atraso, montos y
/// chip de severidad.
class _PrestamoCarteraTile extends StatelessWidget {
  const _PrestamoCarteraTile({required this.item, required this.onTap});

  final PrestamoCarteraItem item;
  final VoidCallback onTap;

  String get _lineaAtraso {
    if (item.diasAtraso > 0) {
      return '${item.diasAtraso} días de atraso';
    }
    if (item.proximaCuotaFecha != null) {
      return 'Próxima cuota: ${Formatters.date(item.proximaCuotaFecha)}';
    }
    return 'Ningún pago';
  }

  @override
  Widget build(BuildContext context) {
    final categoria = categoriaSeveridadFromString(item.categoriaSeveridad);
    final info = infoCategoriaSeveridad(categoria);

    return ClayCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clienteNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.frecuencia} · $_lineaAtraso',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _CategoriaBadge(info: info),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(item.restante),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'de ${Formatters.currency(item.capital)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(Icons.chevron_right,
                    color: AppColors.textSecondary.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de severidad con fondo tenue y color de texto explícito (no se
/// reusa `StatusBadge` porque los pares fondo/texto "seguro" de las 7
/// categorías están fijados por diseño en
/// `NOTES_CARTERA_CLIENTES_COBROS.md`, sección 6, y no todos calzan con el
/// mapeo automático `success`/`danger`/`warning` de ese widget).
class _CategoriaBadge extends StatelessWidget {
  const _CategoriaBadge({required this.info});

  final CategoriaSeveridadInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
