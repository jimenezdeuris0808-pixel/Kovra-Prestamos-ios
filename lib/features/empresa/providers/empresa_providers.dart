import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/tenant_branding.dart';

/// Branding completo (nombre/logo/teléfono/RNC) de la empresa actual, para
/// prellenar el formulario de "Mi Empresa" (`GET /auth/me`).
final empresaBrandingProvider =
    FutureProvider.autoDispose<TenantBranding>((ref) async {
  return ref.read(authRepositoryProvider).obtenerBranding();
});

class MiEmpresaState {
  const MiEmpresaState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  MiEmpresaState copyWith({bool? isLoading, String? errorMessage}) {
    return MiEmpresaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controlador de "Mi Empresa": guardar nombre/teléfono/RNC y subir logo.
class MiEmpresaController extends StateNotifier<MiEmpresaState> {
  MiEmpresaController(this._ref) : super(const MiEmpresaState());

  final Ref _ref;

  Future<bool> guardar({
    required String? nombreComercial,
    required String? telefono,
    required String? rncCedula,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.actualizarBranding(
        nombreComercial: nombreComercial,
        telefono: telefono,
        rncCedula: rncCedula,
      );
      _invalidarBrandingGlobal();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo guardar. Intenta de nuevo.',
      );
      return false;
    }
  }

  Future<bool> subirLogo(Uint8List bytes, String filename) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.subirLogo(bytes, filename);
      _invalidarBrandingGlobal();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo subir el logo. Intenta de nuevo.',
      );
      return false;
    }
  }

  /// El resto de la app (recibos, cabeceras) lee el branding de estos
  /// providers globales -- invalidarlos aquí hace que se refresquen de
  /// inmediato tras guardar, sin esperar a la próxima apertura de la app.
  void _invalidarBrandingGlobal() {
    _ref.invalidate(empresaBrandingProvider);
    _ref.invalidate(currentNombreEmpresaProvider);
    _ref.invalidate(currentLogoProvider);
    _ref.invalidate(currentTelefonoEmpresaProvider);
    _ref.invalidate(currentRncEmpresaProvider);
  }
}

final miEmpresaControllerProvider =
    StateNotifierProvider.autoDispose<MiEmpresaController, MiEmpresaState>(
        (ref) {
  return MiEmpresaController(ref);
});
