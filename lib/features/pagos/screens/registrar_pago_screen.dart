import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/factura.dart';
import '../../../domain/models/pago.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../prestamos/providers/prestamos_providers.dart';
import '../providers/pagos_providers.dart';
import 'recibo_pago_screen.dart';

/// Pantalla "Registrar Pago": resumen cuota+mora=total sugerido, campo
/// monto (prellenado, editable), selector método de pago, campo referencia
/// condicional, validaciones, botón confirmar con loading/error, éxito →
/// Recibo.
class RegistrarPagoScreen extends ConsumerStatefulWidget {
  const RegistrarPagoScreen({
    super.key,
    required this.factura,
    required this.prestamoId,
    required this.montoPrestamo,
    required this.tasaInteres,
  });

  final Factura factura;
  final int prestamoId;

  /// Capital total financiado y tasa de interés (%) del préstamo — se
  /// necesitan para calcular cuánto de esta cuota es interés vs. capital
  /// (el backend guarda solo `monto_cuota`, no el desglose por separado;
  /// ver `Kovra_API/app/business.py`, comentario de cabecera).
  final double montoPrestamo;
  final double tasaInteres;

  @override
  ConsumerState<RegistrarPagoScreen> createState() =>
      _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends ConsumerState<RegistrarPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _interesController;
  late final TextEditingController _capitalController;
  final _referenciaController = TextEditingController();

  MetodoPago _metodo = MetodoPago.efectivo;

  double get _mora => widget.factura.mora;

  /// Interés y capital "completos" de la cuota (fórmula "Simple - insoluto"
  /// ya usada al crear el préstamo: `interés = monto * tasa%`, `capital =
  /// monto_cuota - interés`; ver `NOTES_PRESTAMOS.md` sección 1). Si ya
  /// hubo un pago parcial sobre esta factura, se prorratea sobre lo que
  /// queda pendiente para que interés+capital sigan sumando exactamente
  /// `montoPendiente` (nunca más de lo que realmente falta cobrar).
  ({double interes, double capital}) get _desgloseSugerido {
    final factura = widget.factura;
    final interesCompleto =
        double.parse((widget.montoPrestamo * (widget.tasaInteres / 100))
            .toStringAsFixed(2));
    final capitalCompleto =
        (factura.montoCuota - interesCompleto).clamp(0, double.infinity);
    if (factura.montoPagado <= 0 || factura.montoCuota <= 0) {
      return (interes: interesCompleto, capital: capitalCompleto.toDouble());
    }
    final factor = (factura.montoPendiente / factura.montoCuota)
        .clamp(0.0, 1.0);
    final interesProrrateado =
        double.parse((interesCompleto * factor).toStringAsFixed(2));
    final capitalProrrateado =
        (factura.montoPendiente - interesProrrateado).clamp(0, double.infinity);
    return (interes: interesProrrateado, capital: capitalProrrateado.toDouble());
  }

  double get _totalAPagar {
    final interes = double.tryParse(_interesController.text.replaceAll(',', '.')) ?? 0;
    final capital = double.tryParse(_capitalController.text.replaceAll(',', '.')) ?? 0;
    return double.parse((_mora + interes + capital).toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    final sugerido = _desgloseSugerido;
    _interesController =
        TextEditingController(text: sugerido.interes.toStringAsFixed(2));
    _capitalController =
        TextEditingController(text: sugerido.capital.toStringAsFixed(2));
  }

  void _restablecer() {
    final sugerido = _desgloseSugerido;
    setState(() {
      _interesController.text = sugerido.interes.toStringAsFixed(2);
      _capitalController.text = sugerido.capital.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _interesController.dispose();
    _capitalController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = _totalAPagar;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El total a pagar debe ser mayor a cero.')),
      );
      return;
    }
    // Sin tope: el cobrador puede registrar cualquier monto, incluso por
    // encima de lo pendiente de esta cuota (decisión de negocio explícita,
    // ver `Kovra_API/app/routers/pagos_router.py`).
    FocusScope.of(context).unfocus();

    final resultado = await ref.read(registrarPagoControllerProvider.notifier).registrar(
          facturaId: widget.factura.id,
          monto: monto,
          metodo: _metodo,
          referencia: _metodo.requiereReferencia
              ? _referenciaController.text.trim()
              : null,
        );

    if (resultado != null && mounted) {
      // El pago pudo cambiar el estado del préstamo (incluso cerrarlo, si
      // el excedente saldó las cuotas restantes -- ver
      // `Kovra_API/app/routers/pagos_router.py`) y los resúmenes que
      // dependen de facturas/pagos. Estos providers son `autoDispose` y no
      // se refrescan solos: hay que invalidarlos a mano tras cada pago,
      // igual que ya se hace tras aprobar/rechazar un préstamo en
      // `detalle_prestamo_screen.dart` / `solicitudes_pendientes_screen.dart`.
      ref.invalidate(dashboardCobrosHoyProvider);
      ref.invalidate(dashboardResumenProvider);
      ref.invalidate(dashboardResumenGeneralProvider);
      ref.invalidate(prestamosCarteraProvider);
      ref.invalidate(prestamoDetalleProvider(widget.prestamoId));

      final enriquecido = resultado.copyWith(
        montoTransaccion: monto,
        metodo: _metodo,
        referencia: _referenciaController.text.trim(),
        folio: 'PG-${widget.factura.id}-${DateTime.now().millisecondsSinceEpoch % 100000}',
        fecha: DateTime.now(),
        clienteNombre: widget.factura.clienteNombre,
      );

      // Solo `push`, sin esperar el resultado para hacer un pop propio a
      // continuación: `ReciboPagoScreen._volverAlInicio` ya hace
      // `Navigator.popUntil((route) => route.isFirst)`, que cierra ESTA
      // pantalla (y cualquier otra intermedia, ej. `DetallePrestamoScreen`)
      // como parte de la misma operación. Si esta pantalla ADEMÁS intentaba
      // hacer su propio `pop()` en cuanto el recibo se cerraba, competía
      // por el mismo stack del Navigator con el `popUntil` que ya estaba en
      // curso -- esa carrera dejaba la app en pantalla negra al volver al
      // inicio o al cerrar el recibo con la "X" (mismo botón, mismo
      // método). Con un solo `push` sin acción de seguimiento, el
      // `popUntil` del recibo se encarga de cerrar toda la cadena de una
      // vez, sin nadie más disputándole el Navigator.
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReciboPagoScreen(resultado: enriquecido),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrarPagoControllerProvider);
    final factura = widget.factura;

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Registrar Pago')),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cuota #${factura.numeroCuota}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _restablecer,
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Restablecer'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _interesController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Interés',
                              prefixText: 'RD\$ ',
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'));
                              if (parsed == null || parsed < 0) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _capitalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Capital',
                              prefixText: 'RD\$ ',
                            ),
                            validator: (value) {
                              final parsed = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'));
                              if (parsed == null || parsed < 0) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _FilaResumen(
                      label: 'Mora',
                      value: Formatters.currency(factura.mora),
                      colorValor: factura.mora > 0
                          ? AppColors.dangerStrong
                          : AppColors.textPrimary,
                    ),
                    const Divider(height: 20),
                    _FilaResumen(
                      label: 'Total a pagar',
                      value: Formatters.currency(_totalAPagar),
                      destacado: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              DropdownButtonFormField<MetodoPago>(
                value: _metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: MetodoPago.values
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                    )
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
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.dangerStrong, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Confirmar pago',
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

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.label,
    required this.value,
    this.destacado = false,
    this.colorValor,
  });

  final String label;
  final String value;
  final bool destacado;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  destacado ? AppColors.primaryDark : AppColors.textSecondary,
              fontSize: destacado ? 15 : 13,
              fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorValor ??
                  (destacado ? AppColors.primaryDark : AppColors.textPrimary),
              fontSize: destacado ? 17 : 14,
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
