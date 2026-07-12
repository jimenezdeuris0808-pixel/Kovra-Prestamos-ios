import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/admin_repository.dart';

/// Estado del formulario de login de administrador.
class AdminLoginState {
  const AdminLoginState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  AdminLoginState copyWith({bool? isLoading, String? errorMessage}) {
    return AdminLoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AdminLoginController extends StateNotifier<AdminLoginState> {
  AdminLoginController(this._ref) : super(const AdminLoginState());

  final Ref _ref;

  Future<bool> submit({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Ingresa usuario y contraseña.',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = _ref.read(adminRepositoryProvider);
      final result = await repo.login(username: username, password: password);

      final storage = _ref.read(secureStorageProvider);
      await storage.saveSession(
        token: result.token,
        role: 'kovra_admin',
        tenantSlug: '',
        // El panel de super-admin no pertenece a ningun tenant especifico
        // (administra todos) -- "Kovra" aca es correcto, es la plataforma.
        nombreEmpresa: 'Kovra',
      );

      await _ref.read(sessionControllerProvider.notifier).markAuthenticated();
      state = state.copyWith(isLoading: false);
      return true;
    } on AdminException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Usuario o contraseña incorrectos.',
      );
      return false;
    }
  }
}

final adminLoginControllerProvider =
    StateNotifierProvider.autoDispose<AdminLoginController, AdminLoginState>(
        (ref) {
  return AdminLoginController(ref);
});
