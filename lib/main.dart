import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers/core_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const ProviderScope(child: KovraApp()));
}

class KovraApp extends ConsumerWidget {
  const KovraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kovra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootRouter(),
      routes: {
        '/home': (context) => const HomeShell(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminHomeScreen(),
      },
    );
  }
}

/// Enruta según el estado de sesión: si hay sesión activa muestra el
/// HomeShell, de lo contrario Login.
///
/// Antes, además de este `if` reactivo, un `ref.listen` intentaba TAMBIÉN
/// forzar el logout automático (401) con
/// `Navigator.pushNamedAndRemoveUntil('/login', ...)` sobre el
/// `rootNavigator` -- pero ese navigator es el mismo que contiene a
/// `_RootRouter`, así que esa llamada reemplazaba la ruta que lo alberga
/// (destruyéndolo) exactamente al mismo tiempo que este `build()` ya
/// reconstruía y devolvía `LoginScreen()` por su cuenta. Las dos rutas en
/// pugna dejaban la app atascada en la pantalla anterior (reportado: tras
/// una sesión expirada -- token inválido por rotación del secreto JWT en el
/// backend -- la app quedaba pegada en el error "El token expiró" sin poder
/// volver al login). Basta con el `if` de abajo: al ser reactivo a
/// `sessionControllerProvider`, ya muestra `LoginScreen` solo apenas la
/// sesión se invalida, sin necesidad de ninguna navegación imperativa.
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(sessionControllerProvider);

    if (!isAuthenticated) {
      return const LoginScreen();
    }

    final roleAsync = ref.watch(currentRoleProvider);
    final role = roleAsync.valueOrNull;
    return role == 'kovra_admin' ? const AdminHomeScreen() : const HomeShell();
  }
}
