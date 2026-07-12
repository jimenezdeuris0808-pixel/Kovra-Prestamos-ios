import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_card.dart';
import '../../../shared/widgets/kovra_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/admin_auth_providers.dart';

/// Pantalla de login de administrador: usuario, contraseña (toggle
/// mostrar/ocultar), botón con spinner al cargar, error inline si las
/// credenciales son inválidas.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(adminLoginControllerProvider.notifier).submit(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (ok && mounted) {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminLoginControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KovraLogo(height: 140),
                  const SizedBox(height: 32),
                  AuthCard(
                    title: 'Acceso administrador',
                    fields: [
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                    ],
                    errorMessage: state.errorMessage,
                    submitButton: PrimaryButton(
                      label: 'Ingresar',
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
