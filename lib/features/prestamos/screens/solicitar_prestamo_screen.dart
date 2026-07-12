import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/factura.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/prestamos_providers.dart';
import 'detalle_prestamo_screen.dart';

/// Opciones de amortización/frecuencia soportadas (label visible -> valor
/// crudo enviado al backend). Ver NOTES_AMORTIZACION_FRECUENCIA.md.
const Map<String, String> _opcionesAmortizacion = {
  'Simple | Absoluto': 'Simple - insoluto',
  'Francés': 'Francés',
  'Alemán': 'Alemán',
  'Plazo Indefinido': 'Plazo Indefinido',
};

const Map<String, String> _opcionesFrecuencia = {
  'Diario': 'diario',
  'Semanal': 'semanal',
  'Quincenal': 'quincenal',
  'Mensual': 'mensual',
  'Anual': 'anual',
};

/// Pantalla "Solicitar Préstamo": monto, tasa de interés, plazo en meses y
/// fecha de inicio de pago. Al guardar, crea la solicitud en estado
/// `pendiente` (`POST /prestamos`) y navega al detalle del préstamo recién
/// creado.
///
/// Cuando `prestamoOrigenId` no es `null`, la pantalla opera en modo
/// reenganche: reemplaza el préstamo activo indicado por uno nuevo
/// (NOTES_REENGANCHE.md, sección 6.2).
class SolicitarPrestamoScreen extends ConsumerStatefulWidget {
  const SolicitarPrestamoScreen({
    super.key,
    required this.clienteId,
    this.prestamoOrigenId,
  });

  final int clienteId;

  /// `null` = modo normal. No-`null` = modo reenganche: id del préstamo
  /// activo que esta solicitud reemplazará.
  final int? prestamoOrigenId;

  @override
  ConsumerState<SolicitarPrestamoScreen> createState() =>
      _SolicitarPrestamoScreenState();
}

class _SolicitarPrestamoScreenState
    extends ConsumerState<SolicitarPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _tasaController = TextEditingController();
  final _plazoController = TextEditingController();
  final _motivoReengancheController = TextEditingController();

  late DateTime _fechaInicioPago;
  late DateTime _fechaInicioPrestamo;
  final DateTime _fechaCreacion = DateTime.now();
  String _tipoAmortizacion = 'Simple - insoluto';
  String _frecuenciaTasa = 'mensual';

  bool get _esReenganche => widget.prestamoOrigenId != null;

  /// Plazo Indefinido: el cliente paga solo intereses, sin plazo fijo. El
  /// campo "Plazo" no aplica -- se deshabilita y se fuerza un placeholder
  /// (backend lo guarda pero no lo usa en el cálculo). Mismo criterio UX
  /// que `app_web.py` (deshabilita el campo, no lo oculta).
  bool get _esIndefinido => _tipoAmortizacion == 'Plazo Indefinido';

  @override
  void initState() {
    super.initState();
    _fechaInicioPrestamo = DateTime.now();
    _fechaInicioPago = _sumarUnMes(DateTime.now());
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose();
    _plazoController.dispose();
    _motivoReengancheController.dispose();
    super.dispose();
  }

  DateTime _sumarUnMes(DateTime fecha) {
    return DateTime(fecha.year, fecha.month + 1, fecha.day);
  }

  String _isoDate(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicioPago,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 5, hoy.month, hoy.day),
    );
    if (seleccionada != null) {
      setState(() => _fechaInicioPago = seleccionada);
    }
  }

  /// Fecha de inicio del préstamo (desembolso): a diferencia de "Fecha de
  /// inicio de pago", sí admite fechas pasadas -- sirve para registrar un
  /// préstamo que ya se entregó antes de hoy.
  Future<void> _seleccionarFechaInicioPrestamo() async {
    final hoy = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicioPrestamo,
      firstDate: DateTime(hoy.year - 5, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 5, hoy.month, hoy.day),
    );
    if (seleccionada != null) {
      setState(() => _fechaInicioPrestamo = seleccionada);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final monto = double.parse(_montoController.text.replaceAll(',', '.'));
    final tasa = double.parse(_tasaController.text.replaceAll(',', '.'));
    final plazo = int.parse(_plazoController.text);

    final creado =
        await ref.read(solicitarPrestamoControllerProvider.notifier).solicitar(
              clienteId: widget.clienteId,
              monto: monto,
              tasaInteres: tasa,
              plazoMeses: plazo,
              fechaInicioPago: _isoDate(_fechaInicioPago),
              fechaInicioPrestamo: _isoDate(_fechaInicioPrestamo),
              prestamoOrigenId: widget.prestamoOrigenId,
              motivoReenganche: _esReenganche
                  ? _motivoReengancheController.text.trim()
                  : null,
              tipoAmortizacion: _tipoAmortizacion,
              frecuenciaTasa: _frecuenciaTasa,
            );

    if (creado != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DetallePrestamoScreen(prestamoId: creado.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solicitarPrestamoControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: Text(
          _esReenganche ? 'Reenganchar Préstamo' : 'Solicitar Préstamo',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_esReenganche) ...[
              _ReenganchePrestamoBanner(
                prestamoOrigenId: widget.prestamoOrigenId!,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ClayCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _montoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                      validator: (value) {
                        final texto = value?.trim().replaceAll(',', '.') ?? '';
                        final monto = double.tryParse(texto);
                        if (monto == null || monto <= 0) {
                          return 'Ingresa un monto válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _tasaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tasa de interés periódica (%)',
                        prefixIcon: Icon(Icons.percent_outlined),
                      ),
                      validator: (value) {
                        final texto = value?.trim().replaceAll(',', '.') ?? '';
                        final tasa = double.tryParse(texto);
                        if (tasa == null || tasa < 0) {
                          return 'Ingresa una tasa válida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _plazoController,
                      enabled: !_esIndefinido,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _esIndefinido
                            ? 'Plazo (no aplica — solo intereses)'
                            : 'Plazo (meses)',
                        prefixIcon: const Icon(Icons.event_repeat_outlined),
                      ),
                      validator: (value) {
                        if (_esIndefinido) return null;
                        final plazo = int.tryParse(value?.trim() ?? '');
                        if (plazo == null || plazo <= 0) {
                          return 'Ingresa un plazo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _tipoAmortizacion,
                      decoration: const InputDecoration(
                        labelText: 'Amortización',
                        prefixIcon: Icon(Icons.calculate_outlined),
                      ),
                      items: _opcionesAmortizacion.entries
                          .map((e) => DropdownMenuItem(
                                value: e.value,
                                child: Text(e.key),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          final eraIndefinido = _esIndefinido;
                          _tipoAmortizacion = value;
                          if (_esIndefinido) {
                            _plazoController.text = '1';
                          } else if (eraIndefinido) {
                            _plazoController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _frecuenciaTasa,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                        prefixIcon: Icon(Icons.repeat_outlined),
                      ),
                      items: _opcionesFrecuencia.entries
                          .map((e) => DropdownMenuItem(
                                value: e.value,
                                child: Text(e.key),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frecuenciaTasa = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de creación',
                        prefixIcon: Icon(Icons.event_note_outlined),
                      ),
                      child: Text(Formatters.date(_fechaCreacion)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      onTap: _seleccionarFechaInicioPrestamo,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de inicio del préstamo',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        child: Text(Formatters.date(_fechaInicioPrestamo)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de inicio de pago',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        child: Text(Formatters.date(_fechaInicioPago)),
                      ),
                    ),
                    if (_esReenganche) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _motivoReengancheController,
                        maxLines: 3,
                        minLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Motivo del reenganche',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.edit_note_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa el motivo del reenganche';
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
                                  color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _esReenganche
                          ? 'Enviar reenganche'
                          : 'Enviar solicitud',
                      isLoading: state.isLoading,
                      onPressed: _guardar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de resumen del préstamo que va a ser reemplazado, mostrado arriba
/// del formulario en modo reenganche (NOTES_REENGANCHE.md, sección 6.2).
class _ReenganchePrestamoBanner extends ConsumerWidget {
  const _ReenganchePrestamoBanner({required this.prestamoOrigenId});

  final int prestamoOrigenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamoAsync =
        ref.watch(prestamoDetalleProvider(prestamoOrigenId));

    return ClayCard(
      color: AppColors.accent.withOpacity(0.08),
      child: prestamoAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'No se pudo cargar el préstamo #$prestamoOrigenId: $error',
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ),
        data: (prestamo) {
          final cuotasTotales = prestamo.facturas.length;
          final cuotasPagadas = prestamo.facturas
              .where((f) => f.estado == EstadoFactura.pagada)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.autorenew, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reenganche del préstamo #${prestamo.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _ResumenFila(
                label: 'Capital pendiente',
                value: Formatters.currency(prestamo.saldoPendiente),
              ),
              _ResumenFila(
                label: 'Mora acumulada',
                value: Formatters.currency(prestamo.moraTotal),
                valueColor: prestamo.moraTotal > 0
                    ? AppColors.dangerStrong
                    : null,
              ),
              _ResumenFila(
                label: 'Cuotas',
                value: '$cuotasPagadas/$cuotasTotales',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Este préstamo reemplaza al préstamo #${prestamo.id}. El '
                'saldo pendiente de ese préstamo (capital + mora) se dará '
                'por saldado al aprobarse este reenganche.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResumenFila extends StatelessWidget {
  const _ResumenFila({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
