import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/abono_capital.dart';
import '../../../domain/models/pago.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/prestamos_providers.dart';

/// Pantalla "Abonar a Capital": cobro libre disponible EN CUALQUIER
/// MOMENTO, incluso si el préstamo no tiene ninguna cuota pendiente ahora
/// mismo (a diferencia de "Cobrar cuota", que necesita una factura impaga
/// existente). Útil para un abono parcial al capital sin saldar todo el
/// préstamo (ver [SaldarPrestamoScreen] para eso).
///
/// Para préstamos "Plazo Indefinido", el abono reduce el capital vivo del
/// préstamo y el interés de la próxima cuota se recalcula automáticamente
/// sobre ese capital ya reducido (confirmado como comportamiento esperado:
/// no solo baja el total a saldar, baja el interés periódico real).
class AbonarCapitalScreen extends ConsumerStatefulWidget {
  const AbonarCapitalScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  ConsumerState<AbonarCapitalScreen> createState() =>
      _AbonarCapitalScreenState();
}

class _AbonarCapitalScreenState extends ConsumerState<AbonarCapitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _referenciaController = TextEditingController();
  MetodoPago _metodo = MetodoPago.efectivo;
  AbonoCapitalResultado? _resultado;

  double get _capitalActual =>
      widget.prestamo.capitalPendiente ?? widget.prestamo.monto;

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.parse(_montoController.text.replaceAll(',', '.'));
    FocusScope.of(context).unfocus();

    final resultado = await ref.read(abonoCapitalControllerProvider.notifier).abonar(
          prestamoId: widget.prestamo.id,
          monto: monto,
          metodo: _metodo.apiValue,
          referencia: _metodo.requiereReferencia
              ? _referenciaController.text.trim()
              : null,
        );

    if (resultado != null && mounted) {
      ref.invalidate(dashboardCobrosHoyProvider);
      ref.invalidate(dashboardResumenProvider);
      ref.invalidate(dashboardResumenGeneralProvider);
      ref.invalidate(prestamosCarteraProvider);
      ref.invalidate(prestamoDetalleProvider(widget.prestamo.id));
      setState(() => _resultado = resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(abonoCapitalControllerProvider);

    if (_resultado != null) {
      return _PantallaExito(resultado: _resultado!);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Abonar a Capital')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registra un abono a capital en cualquier momento, '
                      'aunque el préstamo no tenga ninguna cuota pendiente '
                      'todavía.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Capital pendiente actual',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          Formatters.currency(_capitalActual),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto a abonar',
                  prefixText: 'RD\$ ',
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<MetodoPago>(
                value: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: MetodoPago.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _metodo = value);
                },
              ),
              if (_metodo.requiereReferencia) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _referenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Número de referencia',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (value) {
                    if (_metodo.requiereReferencia &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa el número de referencia';
                    }
                    return null;
                  },
                ),
              ],
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
                label: 'Confirmar abono',
                icon: Icons.savings_outlined,
                isLoading: state.isLoading,
                onPressed: _confirmar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantallaExito extends StatelessWidget {
  const _PantallaExito({required this.resultado});

  final AbonoCapitalResultado resultado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: const Text('Abono registrado'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Abono registrado con éxito',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ClayCard(
                child: Column(
                  children: [
                    _Fila(label: 'Monto abonado', value: Formatters.currency(resultado.montoAbonado), destacado: true),
                    _Fila(label: 'Capital antes', value: Formatters.currency(resultado.capitalPendienteAnterior)),
                    _Fila(label: 'Capital pendiente ahora', value: Formatters.currency(resultado.capitalPendienteNuevo)),
                    if (resultado.interesProximaCuota != null)
                      _Fila(
                        label: 'Próxima cuota de interés',
                        value: Formatters.currency(resultado.interesProximaCuota!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Volver al préstamo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.label, required this.value, this.destacado = false});

  final String label;
  final String value;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: destacado ? 16 : 14,
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
              color: destacado ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
