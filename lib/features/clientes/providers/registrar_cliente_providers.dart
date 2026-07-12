import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/clientes_repository.dart';
import '../../../domain/models/cliente.dart';

class RegistrarClienteState {
  const RegistrarClienteState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  RegistrarClienteState copyWith({bool? isLoading, String? errorMessage}) {
    return RegistrarClienteState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RegistrarClienteController extends StateNotifier<RegistrarClienteState> {
  RegistrarClienteController(this._ref) : super(const RegistrarClienteState());

  final Ref _ref;

  Future<Cliente?> guardar({
    required String cedula,
    required String nombre,
    required String apellido,
    String? telefono,
    String? direccion,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(clientesRepositoryProvider);
      final cliente = await repo.crear(
        cedula: cedula,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        direccion: direccion,
      );
      state = state.copyWith(isLoading: false);
      return cliente;
    } on ClientesException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo registrar el cliente. Intenta de nuevo.',
      );
      return null;
    }
  }
}

final registrarClienteControllerProvider = StateNotifierProvider.autoDispose<
    RegistrarClienteController, RegistrarClienteState>((ref) {
  return RegistrarClienteController(ref);
});
