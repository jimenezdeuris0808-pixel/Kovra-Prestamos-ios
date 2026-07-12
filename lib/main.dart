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
/// HomeShell, de lo contrario Login. También reacciona a logout automático
/// (401) forzando el retorno a Login desde cualquier pantalla apilada.
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(sessionControllerProvider);

    ref.listen<bool>(sessionControllerProvider, (previous, next) {
      if (previous == true && next == false) {
        final navigator = Navigator.of(context, rootNavigator: true);
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });

    if (!isAuthenticated) {
      return const LoginScreen();
    }

    final roleAsync = ref.watch(currentRoleProvider);
    final role = roleAsync.valueOrNull;
    return role == 'kovra_admin' ? const AdminHomeScreen() : const HomeShell();
  }
}
