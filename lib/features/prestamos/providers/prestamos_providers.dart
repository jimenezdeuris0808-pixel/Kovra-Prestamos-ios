import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/prestamos_repository.dart';
import '../../../domain/models/prestamo.dart';
import '../../../domain/models/prestamo_busqueda_cross_tenant.dart';
import '../../../domain/models/prestamo_cartera.dart';

/// Cartera de préstamos en gestión (`GET /prestamos/cartera`) para la
/// pantalla "Préstamos" del bottom nav.
final prestamosCarteraProvider =
    FutureProvider.autoDispose<PrestamosCarteraOut>((ref) async {
  final repo = ref.watch(prestamosRepositoryProvider);
  try {
    return await repo.obtenerCartera();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Buscador "Datapréstamo" (`GET /prestamos/buscar?q=...`) — cross-tenant,
/// histórico, encuentra también préstamos ya `pagado`/`rechazado`.
final datapresamoBusquedaProvider = FutureProvider.autoDispose
    .family<BusquedaPrestamoCrossTenantOut, String>((ref, query) async {
  final repo = ref.watch(prestamosRepositoryProvider);
  try {
    return await repo.buscar(query);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

final prestamoDetalleProvider =
    FutureProvider.autoDispose.family<Prestamo, int>((ref, id) async {
  final repo = ref.watch(prestamosRepositoryProvider);
  try {
    return await repo.obtenerDetalle(id);
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

/// Listado de solicitudes de préstamo pendientes de aprobación
/// (`GET /prestamos?estado=pendiente`).
final solicitudesPendientesProvider =
    FutureProvider.autoDispose<List<SolicitudPrestamo>>((ref) async {
  final repo = ref.watch(prestamosRepositoryProvider);
  try {
    return await repo.listarPendientes();
  } catch (e) {
    throw extractErrorMessage(e);
  }
});

class SolicitarPrestamoState {
  const SolicitarPrestamoState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  SolicitarPrestamoState copyWith({bool? isLoading, String? errorMessage}) {
    return SolicitarPrestamoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controlador de la pantalla "Solicitar Préstamo" (`POST /prestamos`).
class SolicitarPrestamoController extends StateNotifier<SolicitarPrestamoState> {
  SolicitarPrestamoController(this._ref) : super(const SolicitarPrestamoState());

  final Ref _ref;

  Future<PrestamoCreado?> solicitar({
    required int clienteId,
    required double monto,
    required double tasaInteres,
    required int plazoMeses,
    required String fechaInicioPago,
    int? prestamoOrigenId,
    String? motivoReenganche,
    String? tipoAmortizacion,
    String? frecuenciaTasa,
    String? fechaInicioPrestamo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(prestamosRepositoryProvider);
      final creado = await repo.solicitar(
        clienteId: clienteId,
        monto: monto,
        tasaInteres: tasaInteres,
        plazoMeses: plazoMeses,
        fechaInicioPago: fechaInicioPago,
        prestamoOrigenId: prestamoOrigenId,
        motivoReenganche: motivoReenganche,
        tipoAmortizacion: tipoAmortizacion,
        frecuenciaTasa: frecuenciaTasa,
        fechaInicioPrestamo: fechaInicioPrestamo,
      );
      state = state.copyWith(isLoading: false);
      return creado;
    } on PrestamosException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo enviar la solicitud. Intenta de nuevo.',
      );
      return null;
    }
  }
}

final solicitarPrestamoControllerProvider = StateNotifierProvider.autoDispose<
    SolicitarPrestamoController, SolicitarPrestamoState>((ref) {
  return SolicitarPrestamoController(ref);
});

/// Estado de la pantalla "Solicitudes Pendientes": `processingId` identifica
/// la solicitud que está siendo aprobada/rechazada en este momento (para
/// deshabilitar solo los botones de esa tarjeta, no la lista completa).
class AprobarRechazarPrestamoState {
  const AprobarRechazarPrestamoState({this.processingId, this.errorMessage});

  final int? processingId;
  final String? errorMessage;

  bool isProcessing(int prestamoId) => processingId == prestamoId;
}

/// Controlador de aprobación/rechazo de solicitudes
/// (`POST /prestamos/{id}/aprobar`, `POST /prestamos/{id}/rechazar`).
class AprobarRechazarPrestamoController
    extends StateNotifier<AprobarRechazarPrestamoState> {
  AprobarRechazarPrestamoController(this._ref)
      : super(const AprobarRechazarPrestamoState());

  final Ref _ref;

  Future<PrestamoAprobado?> aprobar(int prestamoId) async {
    state = AprobarRechazarPrestamoState(processingId: prestamoId);
    try {
      final repo = _ref.read(prestamosRepositoryProvider);
      final resultado = await repo.aprobar(prestamoId);
      state = const AprobarRechazarPrestamoState();
      return resultado;
    } on PrestamosException catch (e) {
      state = AprobarRechazarPrestamoState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const AprobarRechazarPrestamoState(
        errorMessage: 'No se pudo aprobar el préstamo. Intenta de nuevo.',
      );
      return null;
    }
  }

  Future<PrestamoRechazado?> rechazar(int prestamoId) async {
    state = AprobarRechazarPrestamoState(processingId: prestamoId);
    try {
      final repo = _ref.read(prestamosRepositoryProvider);
      final resultado = await repo.rechazar(prestamoId);
      state = const AprobarRechazarPrestamoState();
      return resultado;
    } on PrestamosException catch (e) {
      state = AprobarRechazarPrestamoState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = const AprobarRechazarPrestamoState(
        errorMessage: 'No se pudo rechazar el préstamo. Intenta de nuevo.',
      );
      return null;
    }
  }
}

final aprobarRechazarPrestamoControllerProvider = StateNotifierProvider
    .autoDispose<AprobarRechazarPrestamoController,
        AprobarRechazarPrestamoState>((ref) {
  return AprobarRechazarPrestamoController(ref);
});
