import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/models/deuda_credito.dart';

/// Búsqueda cross-tenant por cédula (`GET /credito/buscar`).
final creditoBusquedaProvider =
    FutureProvider.autoDispose.family<List<DeudaCredito>, String>(
        (ref, cedula) async {
  final repo = ref.watch(creditoRepositoryProvider);
  try {
    return await repo.buscarPorCedula(cedula);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

class AgregarClienteCreditoState {
  const AgregarClienteCreditoState({this.processingCedula, this.errorMessage});

  final String? processingCedula;
  final String? errorMessage;

  bool isProcessing(String cedula) => processingCedula == cedula;
}

/// "Agregar a mi cuenta": crea el cliente de otra empresa en la mía,
/// reusando `POST /clientes` (mismos datos que expone Data Crédito).
class AgregarClienteCreditoController
    extends StateNotifier<AgregarClienteCreditoState> {
  AgregarClienteCreditoController(this._ref)
      : super(const AgregarClienteCreditoState());

  final Ref _ref;

  Future<bool> agregar(DeudaCredito deuda) async {
    state = AgregarClienteCreditoState(processingCedula: deuda.cedula);
    try {
      final repo = _ref.read(clientesRepositoryProvider);
      await repo.crear(
        cedula: deuda.cedula,
        nombre: deuda.nombre,
        apellido: deuda.apellido,
        telefono: deuda.telefono,
        email: deuda.email,
        direccion: deuda.direccion,
      );
      state = const AgregarClienteCreditoState();
      return true;
    } catch (e) {
      state = AgregarClienteCreditoState(
        errorMessage: extractErrorMessage(e),
      );
      return false;
    }
  }
}

final agregarClienteCreditoControllerProvider = StateNotifierProvider
    .autoDispose<AgregarClienteCreditoController, AgregarClienteCreditoState>(
        (ref) {
  return AgregarClienteCreditoController(ref);
});
