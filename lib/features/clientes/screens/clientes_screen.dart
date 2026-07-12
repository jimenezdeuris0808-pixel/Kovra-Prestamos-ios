import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/cliente.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../providers/clientes_providers.dart';
import 'detalle_cliente_screen.dart';
import 'registrar_cliente_screen.dart';

/// Pantalla "Clientes": cabecera con los 4 contadores de
/// `GET /clientes/resumen`, buscador inline sobre `GET /clientes/cartera`
/// (con debounce, filtrado server-side vía `query`) y listado de clientes
/// con su préstamo activo embebido (NOTES_CARTERA_CLIENTES_COBROS.md,
/// secciones 2 y 3).
class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref.read(clientesCarteraQueryProvider.notifier).state = value.trim();
    });
    setState(() {}); // refresca el ícono "clear" del campo de búsqueda
  }

  Future<void> _refrescar() async {
    ref.invalidate(clientesResumenProvider);
    ref.invalidate(clientesCarteraProvider);
    await Future.wait([
      ref.read(clientesResumenProvider.future),
      ref.read(clientesCarteraProvider.future),
    ]);
  }

  void _nuevoCliente() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrarClienteScreen()),
    );
  }

  void _abrirDetalle(int clienteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleClienteScreen(clienteId: clienteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carteraAsync = ref.watch(clientesCarteraProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoCliente,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Nuevo cliente'),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _ResumenSection(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  onClear: () {
                    _searchController.clear();
                    _onQueryChanged('');
                  },
                ),
              ),
              _CarteraBody(
                async: carteraAsync,
                onTap: _abrirDetalle,
              ),
              // Espacio para que el FAB no tape el último ítem de la lista.
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
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
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar por cédula o nombre...',
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
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

/// Cabecera de los 4 contadores de `GET /clientes/resumen`. Se resuelve de
/// forma independiente del listado de cartera, así que tiene su propio
/// estado de carga/error y no bloquea el resto de la pantalla si falla.
class _ResumenSection extends ConsumerWidget {
  const _ResumenSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(clientesResumenProvider);

    return resumenAsync.when(
      loading: () => Container(
        height: 132,
        alignment: Alignment.center,
        decoration: ClayDecoration.surface(radius: AppRadii.lg),
        child: const CircularProgressIndicator(),
      ),
      error: (error, _) => ClayCard(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.dangerStrong),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'No se pudo cargar el resumen de clientes.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(clientesResumenProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (resumen) => _ResumenGrid(resumen: resumen),
    );
  }
}

class _ResumenGrid extends StatelessWidget {
  const _ResumenGrid({required this.resumen});

  final ClientesResumen resumen;

  @override
  Widget build(BuildContext context) {
    final tiles = <_ResumenTileData>[
      _ResumenTileData(
        icon: Icons.people_alt_outlined,
        label: 'Total clientes',
        value: resumen.totalClientes,
        baseColor: AppColors.primary,
      ),
      _ResumenTileData(
        icon: Icons.check_circle_outline,
        label: 'Con préstamo activo',
        value: resumen.clientesConPrestamoActivo,
        baseColor: AppColors.success,
      ),
      _ResumenTileData(
        icon: Icons.person_off_outlined,
        label: 'Sin préstamo activo',
        value: resumen.clientesSinPrestamoActivo,
        baseColor: AppColors.neutralGray,
      ),
      _ResumenTileData(
        icon: Icons.contact_phone_outlined,
        label: 'Con contacto',
        value: resumen.clientesConContacto,
        baseColor: AppColors.accent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: tileWidth, child: _ResumenTile(data: tile)),
          ],
        );
      },
    );
  }
}

class _ResumenTileData {
  const _ResumenTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.baseColor,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color baseColor;
}

class _ResumenTile extends StatelessWidget {
  const _ResumenTile({required this.data});

  final _ResumenTileData data;

  /// Variante segura de [data.baseColor] como color de texto (ver
  /// `DESIGN_SYSTEM_CLAY.md`, secciones 1 y 6).
  Color get _textColor {
    if (data.baseColor == AppColors.success) return AppColors.successStrong;
    if (data.baseColor == AppColors.danger) return AppColors.dangerStrong;
    if (data.baseColor == AppColors.warning) return AppColors.textPrimary;
    return data.baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: data.baseColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: data.baseColor.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.baseColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 18, color: data.baseColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.value}',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
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
        ],
      ),
    );
  }
}

/// Cuerpo de la lista de clientes (`GET /clientes/cartera`): carga, error,
/// vacío o listado.
class _CarteraBody extends StatelessWidget {
  const _CarteraBody({required this.async, required this.onTap});

  final AsyncValue<List<ClienteCarteraItem>> async;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorState(message: error.toString()),
      data: (clientes) {
        if (clientes.isEmpty) {
          return const EmptyState(
            icon: Icons.person_search_outlined,
            message: 'No se encontraron clientes con ese criterio.',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
          itemCount: clientes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            return _ClienteTile(
              cliente: cliente,
              onTap: () => onTap(cliente.id),
            );
          },
        );
      },
    );
  }
}

class _ClienteTile extends StatelessWidget {
  const _ClienteTile({required this.cliente, required this.onTap});

  final ClienteCarteraItem cliente;
  final VoidCallback onTap;

  String get _iniciales {
    final n = cliente.nombre.isNotEmpty ? cliente.nombre[0] : '';
    final a = cliente.apellido.isNotEmpty ? cliente.apellido[0] : '';
    final iniciales = '$n$a'.toUpperCase();
    return iniciales.isEmpty ? '?' : iniciales;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: ClayCard(
        radius: AppRadii.md,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                _iniciales,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID ${cliente.id} · ${cliente.cedula}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (cliente.tienePrestamoActivo)
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${cliente.cuotasPagadas ?? 0}/${cliente.cuotasTotales ?? 0} cuotas',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Formatters.currency(cliente.montoPendiente),
                          style: const TextStyle(
                            color: AppColors.dangerStrong,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Sin préstamo activo',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutralGray),
          ],
        ),
      ),
    );
  }
}
