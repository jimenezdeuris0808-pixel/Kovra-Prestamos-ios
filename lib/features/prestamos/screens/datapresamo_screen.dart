import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/prestamo_busqueda_cross_tenant.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/puntuacion_badge.dart';
import '../providers/prestamos_providers.dart';
import 'detalle_prestamo_screen.dart';

/// Pantalla "Datapréstamo": buscador puntual de un préstamo por cédula,
/// nombre o número (`GET /prestamos/buscar`), CROSS-TENANT: también muestra
/// resultados de otras empresas del sistema Kovra, con su contacto y una
/// puntuación de pago global consolidada -- para que cualquier empresa
/// pueda depurar rápidamente a un cliente antes de prestarle. A diferencia
/// de la pantalla "Préstamos" (cartera activa), este buscador es histórico:
/// también encuentra préstamos ya pagados o rechazados. Puerto de
/// `_util_dataprestamo` en `app_web.py`.
class DatapresamoScreen extends ConsumerStatefulWidget {
  const DatapresamoScreen({super.key});

  @override
  ConsumerState<DatapresamoScreen> createState() => _DatapresamoScreenState();
}

class _DatapresamoScreenState extends ConsumerState<DatapresamoScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirPrestamo(PrestamoBusquedaItem item) {
    // El detalle (`GET /prestamos/{id}`) sigue siendo single-tenant: solo
    // tiene sentido navegar ahí cuando el préstamo es de mi propia empresa.
    // Los resultados de otras empresas se quedan con la ficha resumida.
    if (!item.esMiEmpresa) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetallePrestamoScreen(prestamoId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientHeader(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              title: 'Datapréstamo',
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Busca cualquier préstamo, activo o histórico',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              bottom: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Container(
                  decoration: ClayDecoration.surface(radius: AppRadii.sm),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cédula, nombre o número de préstamo (#123)',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_outlined,
                      message: 'Escribe una cédula, nombre o número\n'
                          'de préstamo para buscar.',
                    )
                  : _ResultadosBusqueda(
                      query: query,
                      onTapItem: _abrirPrestamo,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadosBusqueda extends ConsumerWidget {
  const _ResultadosBusqueda({required this.query, required this.onTapItem});

  final String query;
  final ValueChanged<PrestamoBusquedaItem> onTapItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultadoAsync = ref.watch(datapresamoBusquedaProvider(query));

    return resultadoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(datapresamoBusquedaProvider(query)),
      ),
      data: (resultado) {
        if (resultado.items.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_outlined,
            message: 'Ningún préstamo coincide con la búsqueda.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: resultado.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = resultado.items[index];
            return _DatapresamoTile(
              item: item,
              onTap: () => onTapItem(item),
            );
          },
        );
      },
    );
  }
}

/// Ficha compacta de un resultado: empresa dueña del préstamo, cliente,
/// contacto, estado real (no severidad, a diferencia de la cartera -- acá
/// interesa saber si ya está `pagado`/`rechazado`), capital, saldo restante
/// y la puntuación de pago global consolidada de la cédula (misma en todas
/// las tarjetas de un mismo cliente, sin importar la empresa).
class _DatapresamoTile extends StatelessWidget {
  const _DatapresamoTile({required this.item, required this.onTap});

  final PrestamoBusquedaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: item.esMiEmpresa ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.id} · ${item.clienteNombre}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StatusBadgeEstado(estado: item.estado),
                          _EmpresaChip(
                            empresa: item.empresa,
                            esMiEmpresa: item.esMiEmpresa,
                          ),
                        ],
                      ),
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
                  ],
                ),
              ],
            ),
            if (item.telefono != null || item.email != null) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${item.telefono ?? '—'}  |  ✉ ${item.email ?? '—'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
            const SizedBox(height: 8),
            PuntuacionBadge(puntuacion: item.puntuacionGlobal),
          ],
        ),
      ),
    );
  }
}

/// Chip que identifica a qué empresa pertenece este resultado. Destacado en
/// color primario cuando es la empresa propia del usuario que consulta.
class _EmpresaChip extends StatelessWidget {
  const _EmpresaChip({required this.empresa, required this.esMiEmpresa});

  final String empresa;
  final bool esMiEmpresa;

  @override
  Widget build(BuildContext context) {
    final color = esMiEmpresa ? AppColors.primary : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        esMiEmpresa ? 'Mi empresa' : empresa,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Badge simple de `estado` (texto crudo del préstamo: pendiente, aprobado,
/// pagado, rechazado, etc.), distinto de los chips de severidad de la
/// cartera activa -- acá interesa el estado real, no una clasificación de
/// urgencia de cobro.
class StatusBadgeEstado extends StatelessWidget {
  const StatusBadgeEstado({super.key, required this.estado});

  final String estado;

  Color get _color {
    switch (estado) {
      case 'pagado':
        return AppColors.success;
      case 'rechazado':
      case 'incobrable':
        return AppColors.danger;
      case 'pendiente':
        return AppColors.neutralGray;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
