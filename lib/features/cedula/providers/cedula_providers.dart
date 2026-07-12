import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../domain/models/cedula_info.dart';

/// Consulta puntual (no cacheada como family autoDispose keepAlive) de
/// autocompletado por cédula, usada en el formulario de Registrar Cliente.
class CedulaLookupController extends StateNotifier<AsyncValue<CedulaInfo?>> {
  CedulaLookupController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> buscar(String numero) async {
    if (numero.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(cedulaRepositoryProvider);
      final info = await repo.buscar(numero.trim());
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final cedulaLookupControllerProvider = StateNotifierProvider.autoDispose<
    CedulaLookupController, AsyncValue<CedulaInfo?>>((ref) {
  return CedulaLookupController(ref);
});
