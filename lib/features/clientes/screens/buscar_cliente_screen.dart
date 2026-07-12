import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../shared/widgets/cliente_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../providers/clientes_providers.dart';
import 'detalle_cliente_screen.dart';

/// Pantalla "Buscar Cliente": campo de búsqueda con debounce (mínimo 3
/// caracteres), lista de ClienteCard, estados vacío/sin resultados/carga/error.
class BuscarClienteScreen extends ConsumerStatefulWidget {
  const BuscarClienteScreen({super.key});

  @override
  ConsumerState<BuscarClienteScreen> createState() =>
      _BuscarClienteScreenState();
}

class _BuscarClienteScreenState extends ConsumerState<BuscarClienteScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final state = ref.watch(busquedaClienteControllerProvider);
    final controller = ref.read(busquedaClienteControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Buscar Cliente')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Container(
              decoration: ClayDecoration.surface(radius: AppRadii.sm),
              child: TextField(
                controller: _searchController,
                onChanged: controller.onQueryChanged,
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            controller.onQueryChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(state, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BusquedaClienteState state,
    BusquedaClienteController controller,
  ) {
    switch (state.status) {
      case BusquedaStatus.inicial:
        return const EmptyState(
          icon: Icons.search,
          message: 'Escribe al menos 3 caracteres para buscar por\n'
              'cédula o nombre del cliente.',
        );
      case BusquedaStatus.cargando:
        return const Center(child: CircularProgressIndicator());
      case BusquedaStatus.sinResultados:
        return const EmptyState(
          icon: Icons.person_search_outlined,
          message: 'No se encontraron clientes con ese criterio.',
        );
      case BusquedaStatus.error:
        return ErrorState(
          message: state.errorMessage ?? 'Ocurrió un error al buscar.',
          onRetry: controller.reintentar,
        );
      case BusquedaStatus.exito:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          itemCount: state.resultados.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cliente = state.resultados[index];
            return ClienteCard(
              cliente: cliente,
              onTap: () => _abrirDetalle(cliente.id),
            );
          },
        );
    }
  }
}
