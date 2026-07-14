import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../domain/models/cliente.dart';
import '../../../domain/models/pago_historial_item.dart';

enum BusquedaStatus { inicial, cargando, exito, sinResultados, error }

class BusquedaClienteState {
  const BusquedaClienteState({
    this.status = BusquedaStatus.inicial,
    this.resultados = const [],
    this.errorMessage,
    this.query = '',
  });

  final BusquedaStatus status;
  final List<Cliente> resultados;
  final String? errorMessage;
  final String query;

  BusquedaClienteState copyWith({
    BusquedaStatus? status,
    List<Cliente>? resultados,
    String? errorMessage,
    String? query,
  }) {
    return BusquedaClienteState(
      status: status ?? this.status,
      resultados: resultados ?? this.resultados,
      errorMessage: errorMessage,
      query: query ?? this.query,
    );
  }
}

/// Controlador de la pantalla "Buscar Cliente", con debounce de búsqueda
/// (mínimo 3 caracteres).
class BusquedaClienteController extends StateNotifier<BusquedaClienteState> {
  BusquedaClienteController(this._ref) : super(const BusquedaClienteState());

  final Ref _ref;
  Timer? _debounce;
  int _requestId = 0;

  static const _minChars = 3;
  static const _debounceDuration = Duration(milliseconds: 450);

  void onQueryChanged(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);

    if (query.trim().length < _minChars) {
      state = state.copyWith(status: BusquedaStatus.inicial, resultados: []);
      return;
    }

    _debounce = Timer(_debounceDuration, () => _buscar(query.trim()));
  }

  Future<void> _buscar(String query) async {
    final currentRequest = ++_requestId;
    state = state.copyWith(status: BusquedaStatus.cargando);

    try {
      final repo = _ref.read(clientesRepositoryProvider);
      final resultados = await repo.buscar(query);

      if (currentRequest != _requestId) return; // respuesta obsoleta

      state = state.copyWith(
        status: resultados.isEmpty
            ? BusquedaStatus.sinResultados
            : BusquedaStatus.exito,
        resultados: resultados,
      );
    } catch (e) {
      if (currentRequest != _requestId) return;
      state = state.copyWith(
        status: BusquedaStatus.error,
        errorMessage: extractErrorMessage(e),
      );
    }
  }

  void reintentar() {
    final query = state.query.trim();
    if (query.length >= _minChars) {
      _buscar(query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final busquedaClienteControllerProvider = StateNotifierProvider.autoDispose<
    BusquedaClienteController, BusquedaClienteState>((ref) {
  return BusquedaClienteController(ref);
});

/// Detalle de un cliente por id (incluye sus préstamos).
final clienteDetalleProvider = FutureProvider.autoDispose
    .family<Cliente, int>((ref, id) async {
  final repo = ref.watch(clientesRepositoryProvider);
  try {
    return await repo.obtenerDetalle(id);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Historial de pagos de un cliente (`GET /clientes/{id}/pagos`), más
/// reciente primero -- para reenviar/reimprimir el recibo de un cobro
/// pasado.
final historialPagosClienteProvider = FutureProvider.autoDispose
    .family<List<PagoHistorialItem>, int>((ref, clienteId) async {
  final repo = ref.watch(clientesRepositoryProvider);
  try {
    return await repo.obtenerHistorialPagos(clienteId);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Contadores de cabecera de la pantalla "Clientes" (`GET /clientes/resumen`).
final clientesResumenProvider =
    FutureProvider.autoDispose<ClientesResumen>((ref) async {
  final repo = ref.watch(clientesRepositoryProvider);
  try {
    return await repo.obtenerResumen();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Query de búsqueda actual de la pantalla "Clientes" (`GET /clientes/cartera`).
/// La pantalla actualiza este estado con debounce; [clientesCarteraProvider]
/// lo observa y vuelve a pedir la lista al backend en cada cambio.
final clientesCarteraQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Listado de clientes con préstamo activo embebido (`GET /clientes/cartera`).
final clientesCarteraProvider =
    FutureProvider.autoDispose<List<ClienteCarteraItem>>((ref) async {
  final query = ref.watch(clientesCarteraQueryProvider);
  final repo = ref.watch(clientesRepositoryProvider);
  try {
    return await repo.obtenerCartera(query: query.isEmpty ? null : query);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});
