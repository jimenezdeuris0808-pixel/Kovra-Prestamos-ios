import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/admin_notificacion.dart';

/// Listado completo de notificaciones (`GET /admin/notificaciones`) para la
/// pantalla de notificaciones del panel de administrador.
final adminNotificacionesProvider =
    FutureProvider.autoDispose<List<AdminNotificacion>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.listarNotificaciones();
});

/// Cantidad de notificaciones sin leer, para el badge del ícono de campana
/// en la pantalla principal de administrador.
final adminNotificacionesNoLeidasProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final noLeidas = await repo.listarNotificaciones(soloNoLeidas: true);
  return noLeidas.length;
});

/// Controller para marcar notificaciones como leídas. Tras cada acción
/// invalida los providers de arriba para refrescar el badge y la lista.
class AdminNotificacionesController extends StateNotifier<AsyncValue<void>> {
  AdminNotificacionesController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> marcarLeida(int id) async {
    try {
      await _ref.read(adminRepositoryProvider).marcarNotificacionLeida(id);
      _ref.invalidate(adminNotificacionesProvider);
      _ref.invalidate(adminNotificacionesNoLeidasProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminNotificacionesControllerProvider = StateNotifierProvider.autoDispose<
    AdminNotificacionesController, AsyncValue<void>>((ref) {
  return AdminNotificacionesController(ref);
});
