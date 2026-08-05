import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/prestamos_providers.dart';

/// Pantalla "Editar Préstamo": corrige la tasa de interés y/o el capital
/// pendiente de un préstamo ya creado, sin importar si está al día,
/// atrasado o a punto de pagarse -- pensada para arreglar un dato mal
/// ingresado, no para el flujo normal de cobro (para eso están "Cobrar
/// cuota", "Abonar a capital" y "Saldar préstamo").
///
/// Para préstamos "Plazo Indefinido", el interés de la cuota pendiente (si
/// hay una) se recalcula de inmediato con los valores nuevos.
class EditarPrestamoScreen extends ConsumerStatefulWidget {
  const EditarPrestamoScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  ConsumerState<EditarPrestamoScreen> createState() =>
      _EditarPrestamoScreenState();
}

class _EditarPrestamoScreenState extends ConsumerState<EditarPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tasaController;
  late final TextEditingController _capitalController;

  @override
  void initState() {
    super.initState();
    _tasaController =
        TextEditingController(text: widget.prestamo.tasaInteres.toStringAsFixed(2));
    _capitalController = TextEditingController(
      text: (widget.prestamo.capitalPendiente ?? widget.prestamo.monto)
          .toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _tasaController.dispose();
    _capitalController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final tasa = double.parse(_tasaController.text.replaceAll(',', '.'));
    final capital = double.parse(_capitalController.text.replaceAll(',', '.'));

    final resultado = await ref.read(editarPrestamoControllerProvider.notifier).editar(
          prestamoId: widget.prestamo.id,
          tasaInteres: tasa,
          capitalPendiente: capital,
        );

    if (resultado != null && mounted) {
      ref.invalidate(prestamoDetalleProvider(widget.prestamo.id));
      ref.invalidate(prestamosCarteraProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préstamo actualizado.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editarPrestamoControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Editar Préstamo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Corrige el interés o el capital pendiente de este '
                'préstamo. Se puede hacer en cualquier momento, sin '
                'importar si el cliente va a pagar pronto o no.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _tasaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tasa de interés periódica',
                  suffixText: '%',
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa una tasa válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _capitalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Capital pendiente',
                  prefixText: 'RD\$ ',
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.dangerStrong, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Guardar cambios',
                icon: Icons.save_outlined,
                isLoading: state.isLoading,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
