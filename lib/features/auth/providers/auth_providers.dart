import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/repositories/auth_repository.dart';

/// Estado del formulario de login.
class LoginState {
  const LoginState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  LoginState copyWith({bool? isLoading, String? errorMessage}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._ref) : super(const LoginState());

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
      final repo = _ref.read(authRepositoryProvider);
      final session = await repo.login(username: username, password: password);

      final storage = _ref.read(secureStorageProvider);
      await storage.saveSession(
        token: session.token,
        role: session.role,
        tenantSlug: session.tenantSlug,
        nombreEmpresa: session.nombreEmpresa,
        nombreComercial: session.nombreComercial,
      );

      await _ref.read(sessionControllerProvider.notifier).markAuthenticated();
      // markAuthenticated() dispara la navegación a Inicio (ver
      // _RootRouter en main.dart, que reacciona a sessionControllerProvider
      // y reemplaza LoginScreen por HomeShell) -- eso puede desmontar esta
      // misma pantalla, y con ella este controller (`autoDispose`), ANTES
      // de que este await termine de resolver. Sin este chequeo, el
      // `state = ...` de abajo revienta con "Bad state: Tried to use
      // LoginController after dispose was called", la excepción se
      // propaga sin capturar (ni el catch de abajo puede escribir estado
      // ya destruido) y `_submit()` en login_screen.dart nunca llega a
      // hacer la navegación -- el login "falla" en la UI aunque el
      // backend ya haya autenticado correctamente.
      if (!mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Usuario o contraseña incorrectos.',
      );
      return false;
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref);
});

/// Estado del formulario de "Crear cuenta" (auto-registro).
class SignupState {
  const SignupState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  SignupState copyWith({bool? isLoading, String? errorMessage}) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SignupController extends StateNotifier<SignupState> {
  SignupController(this._ref) : super(const SignupState());

  final Ref _ref;

  Future<bool> submit({
    required String username,
    required String email,
    required String password,
    String? nombreEmpresa,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = _ref.read(authRepositoryProvider);
      final session = await repo.signup(
        username: username,
        email: email,
        password: password,
        nombreEmpresa: nombreEmpresa,
      );

      final storage = _ref.read(secureStorageProvider);
      await storage.saveSession(
        token: session.token,
        role: session.role,
        tenantSlug: session.tenantSlug,
        nombreEmpresa: session.nombreEmpresa,
        nombreComercial: session.nombreComercial,
      );

      await _ref.read(sessionControllerProvider.notifier).markAuthenticated();
      // Mismo riesgo de dispose-durante-await que LoginController.submit
      // (ver comentario ahí) -- markAuthenticated() puede desmontar esta
      // pantalla (y este controller) antes de que el await termine.
      if (!mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo crear la cuenta. Intenta de nuevo.',
      );
      return false;
    }
  }
}

final signupControllerProvider =
    StateNotifierProvider.autoDispose<SignupController, SignupState>((ref) {
  return SignupController(ref);
});
