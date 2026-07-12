import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../../domain/models/tenant_branding.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cedula_repository.dart';
import '../../data/repositories/clientes_repository.dart';
import '../../data/repositories/credito_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/pagos_repository.dart';
import '../../data/repositories/prestamos_repository.dart';

/// Notifica a la app que la sesión fue invalidada (401) o que el usuario
/// cerró sesión manualmente, para que el router vuelva a Login.
class SessionController extends StateNotifier<bool> {
  SessionController(this._ref) : super(false) {
    _bootstrap();
  }

  final Ref _ref;
  SecureStorageService get _storage => _ref.read(secureStorageProvider);

  Future<void> _bootstrap() async {
    state = await _storage.hasSession();
    if (state) {
      await _refrescarBranding();
    }
  }

  /// Vuelve a pedir nombre/logo de empresa con el token ya emitido (`GET
  /// /auth/me`) y actualiza el storage. Se llama al abrir la app (no solo
  /// al loguearse) para que una sesión guardada de antes de que este campo
  /// existiera se autocorrija sola, en vez de quedar pegada al valor (o la
  /// ausencia de valor) del login original. Si falla (offline, token
  /// vencido) no rompe nada: la app sigue con lo que ya tenía guardado.
  Future<void> _refrescarBranding() async {
    try {
      final branding = await _ref.read(authRepositoryProvider).obtenerBranding();
      await _storage.saveBranding(
        nombreEmpresa: branding.nombreEmpresa,
        nombreComercial: branding.nombreComercial,
      );
    } catch (_) {
      // Silencioso a propósito: ver docstring.
    }
  }

  Future<void> markAuthenticated() async {
    state = true;
    await _refrescarBranding();
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = false;
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final sessionControllerProvider =
    StateNotifierProvider<SessionController, bool>((ref) {
  return SessionController(ref);
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return buildDioClient(
    storage: storage,
    onUnauthorized: () async {
      await ref.read(sessionControllerProvider.notifier).logout();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final clientesRepositoryProvider = Provider<ClientesRepository>((ref) {
  return ClientesRepository(ref.watch(dioProvider));
});

final prestamosRepositoryProvider = Provider<PrestamosRepository>((ref) {
  return PrestamosRepository(ref.watch(dioProvider));
});

final pagosRepositoryProvider = Provider<PagosRepository>((ref) {
  return PagosRepository(ref.watch(dioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final cedulaRepositoryProvider = Provider<CedulaRepository>((ref) {
  return CedulaRepository(ref.watch(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final creditoRepositoryProvider = Provider<CreditoRepository>((ref) {
  return CreditoRepository(ref.watch(dioProvider));
});

/// Rol de la sesión guardada (`null` si no hay sesión o aún no se ha
/// leído). Observa `sessionControllerProvider` para releerse cada vez que
/// cambia el estado de autenticación.
final currentRoleProvider = FutureProvider<String?>((ref) async {
  ref.watch(sessionControllerProvider);
  final storage = ref.watch(secureStorageProvider);
  return storage.readRole();
});

/// Nombre de la empresa (tenant) de la sesión actual, para branding en
/// pantallas posteriores al login (recibos, cabeceras) — nunca hardcodear
/// "Kovra" ahí, cada tenant tiene su propio nombre.
final currentNombreEmpresaProvider = FutureProvider<String>((ref) async {
  ref.watch(sessionControllerProvider);
  final storage = ref.watch(secureStorageProvider);
  final comercial = await storage.readNombreComercial();
  if (comercial != null && comercial.trim().isNotEmpty) return comercial;
  return (await storage.readNombreEmpresa()) ?? 'Kovra';
});

/// Logo que el tenant cargó al crear su empresa (`GET /auth/logo`), o
/// `null` si no tiene uno configurado. Las pantallas que lo consuman deben
/// tener un fallback (texto con `currentNombreEmpresaProvider`) para cuando
/// da `null` — no todos los tenants van a tener logo cargado.
final currentLogoProvider = FutureProvider<TenantLogo?>((ref) async {
  ref.watch(sessionControllerProvider);
  return ref.read(authRepositoryProvider).obtenerLogo();
});

/// Teléfono y RNC/cédula de "Mi Empresa" (`GET /auth/me`) -- a diferencia
/// de `currentNombreEmpresaProvider`, no se cachean en `SecureStorageService`
/// (son campos nuevos, sin equivalente en la sesión guardada al loguearse),
/// se piden en vivo cada vez, mismo criterio que `currentLogoProvider`.
final currentTelefonoEmpresaProvider = FutureProvider<String?>((ref) async {
  ref.watch(sessionControllerProvider);
  final branding = await ref.read(authRepositoryProvider).obtenerBranding();
  return branding.telefono;
});

final currentRncEmpresaProvider = FutureProvider<String?>((ref) async {
  ref.watch(sessionControllerProvider);
  final branding = await ref.read(authRepositoryProvider).obtenerBranding();
  return branding.rncCedula;
});
