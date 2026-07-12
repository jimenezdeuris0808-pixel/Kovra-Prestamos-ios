import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/pagos_repository.dart';
import '../../../domain/models/pago.dart';

class RegistrarPagoState {
  const RegistrarPagoState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  RegistrarPagoState copyWith({bool? isLoading, String? errorMessage}) {
    return RegistrarPagoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RegistrarPagoController extends StateNotifier<RegistrarPagoState> {
  RegistrarPagoController(this._ref) : super(const RegistrarPagoState());

  final Ref _ref;

  Future<PagoResultado?> registrar({
    required int facturaId,
    required double monto,
    required MetodoPago metodo,
    String? referencia,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(pagosRepositoryProvider);
      final resultado = await repo.registrarPago(
        facturaId: facturaId,
        monto: monto,
        metodo: metodo,
        referencia: referencia,
      );
      state = state.copyWith(isLoading: false);
      return resultado;
    } on PagosException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo registrar el pago. Intenta de nuevo.',
      );
      return null;
    }
  }
}

final registrarPagoControllerProvider = StateNotifierProvider.autoDispose<
    RegistrarPagoController, RegistrarPagoState>((ref) {
  return RegistrarPagoController(ref);
});
