import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../cedula/providers/cedula_providers.dart';
import '../providers/registrar_cliente_providers.dart';
import 'detalle_cliente_screen.dart';

/// Pantalla "Registrar Cliente Nuevo": campo cédula con autocompletado
/// (GET /cedula/{numero}), campos editables, validaciones, guardar → Detalle
/// Cliente.
class RegistrarClienteScreen extends ConsumerStatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  ConsumerState<RegistrarClienteScreen> createState() =>
      _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState
    extends ConsumerState<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  Timer? _debounce;
  bool _autocompletado = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _onCedulaChanged(String value) {
    _debounce?.cancel();
    final cedula = value.trim();
    if (cedula.length < 6) {
      ref.read(cedulaLookupControllerProvider.notifier).reset();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(cedulaLookupControllerProvider.notifier).buscar(cedula);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final cliente = await ref.read(registrarClienteControllerProvider.notifier).guardar(
          cedula: _cedulaController.text.trim(),
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          direccion: _direccionController.text.trim(),
        );

    if (cliente != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DetalleClienteScreen(clienteId: cliente.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cedulaLookupControllerProvider, (previous, next) {
      next.whenData((info) {
        if (info != null && !_autocompletado) {
          _nombreController.text = info.nombre;
          _apellidoController.text = info.apellido;
          _telefonoController.text = info.telefono ?? '';
          _direccionController.text = info.direccion ?? '';
          _autocompletado = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos autocompletados desde el registro de cédula.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      });
    });

    final registrarState = ref.watch(registrarClienteControllerProvider);
    final cedulaLookup = ref.watch(cedulaLookupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _autocompletado = false;
                  _onCedulaChanged(value);
                },
                decoration: InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  suffixIcon: cedulaLookup.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la cédula del cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _direccionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              if (registrarState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        registrarState.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.dangerStrong, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Guardar cliente',
                isLoading: registrarState.isLoading,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
