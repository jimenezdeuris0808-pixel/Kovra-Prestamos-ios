import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/tenant_admin.dart';

/// Listado de tenants (`GET /admin/tenants`) para la pantalla principal de
/// administrador.
final adminTenantsProvider =
    FutureProvider.autoDispose<List<TenantAdmin>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listarTenants();
});

/// Controller para las acciones de edición de un tenant (vigencia/estado).
/// Tras cada acción exitosa invalida [adminTenantsProvider] para que el
/// listado se refresque.
class AdminTenantActionsController extends StateNotifier<AsyncValue<void>> {
  AdminTenantActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<TenantAdmin?> actualizarVigencia(
    int id,
    String? fechaExpiracion,
  ) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final tenant = await repo.actualizarVigencia(id, fechaExpiracion);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminTenantsProvider);
      return tenant;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<TenantAdmin?> actualizarEstado(int id, String estado) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(adminRepositoryProvider);
      final tenant = await repo.actualizarEstado(id, estado);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminTenantsProvider);
      return tenant;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final adminTenantActionsControllerProvider = StateNotifierProvider.autoDispose<
    AdminTenantActionsController, AsyncValue<void>>((ref) {
  return AdminTenantActionsController(ref);
});
