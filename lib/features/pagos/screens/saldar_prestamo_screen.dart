import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/factura.dart';
import '../../../domain/models/pago.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../prestamos/providers/prestamos_providers.dart';
import '../providers/pagos_providers.dart';
import 'recibo_pago_screen.dart';

/// Pantalla "Saldar Préstamo": paga de una sola vez TODO el saldo pendiente
/// del préstamo (capital + mora de todas las cuotas no pagadas), sin
/// importar si alguna cuota aún no está en su fecha de vencimiento -- misma
/// idea que el botón "✓ Saldar" que ya existe en Kovra Web
/// (`app_web.py::panel_cobros`), que en la app móvil no tenía equivalente.
///
/// No hace falta un endpoint nuevo: se manda un solo `POST /pagos` contra
/// la cuota impaga más antigua por el monto total pendiente del préstamo, y
/// el backend ya sabe repartir el excedente en cascada sobre las demás
/// cuotas hasta dejarlas todas pagadas (ver
/// `Kovra_API/app/routers/pagos_router.py`, sección "Cascada").
class SaldarPrestamoScreen extends ConsumerStatefulWidget {
  const SaldarPrestamoScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  ConsumerState<SaldarPrestamoScreen> createState() =>
      _SaldarPrestamoScreenState();
}

class _SaldarPrestamoScreenState extends ConsumerState<SaldarPrestamoScreen> {
  final _referenciaController = TextEditingController();
  MetodoPago _metodo = MetodoPago.efectivo;

  /// Cuota impaga más antigua: es la que se manda como `factura_id` en
  /// `POST /pagos` para que la cascada del backend reparta el total sobre
  /// ella y, en orden, sobre todas las demás cuotas pendientes del
  /// préstamo (ver `Kovra_API/app/routers/pagos_router.py`).
  Factura get _facturaObjetivo =>
      widget.prestamo.facturas.firstWhere((f) => f.estado != EstadoFactura.pagada);

  double get _capitalPendiente => widget.prestamo.saldoPendiente;
  double get _moraTotal => widget.prestamo.moraTotal;
  double get _totalAPagar =>
      double.parse((_capitalPendiente + _moraTotal).toStringAsFixed(2));

  @override
  void dispose() {
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_metodo.requiereReferencia && _referenciaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el número de referencia.')),
      );
      return;
    }

    final resultado = await ref.read(registrarPagoControllerProvider.notifier).registrar(
          facturaId: _facturaObjetivo.id,
          monto: _totalAPagar,
          metodo: _metodo,
          referencia: _metodo.requiereReferencia
              ? _referenciaController.text.trim()
              : null,
        );

    if (resultado != null && mounted) {
      // Mismas invalidaciones que un pago normal (ver registrar_pago_screen.dart):
      // saldar cambia el estado del préstamo a "pagado" y afecta todos los
      // resúmenes que dependen de facturas/pagos.
      ref.invalidate(dashboardCobrosHoyProvider);
      ref.invalidate(dashboardResumenProvider);
      ref.invalidate(dashboardResumenGeneralProvider);
      ref.invalidate(prestamosCarteraProvider);
      ref.invalidate(prestamoDetalleProvider(widget.prestamo.id));

      final enriquecido = resultado.copyWith(
        montoTransaccion: _totalAPagar,
        metodo: _metodo,
        referencia: _referenciaController.text.trim(),
        folio: 'SLD-${widget.prestamo.id}-${DateTime.now().millisecondsSinceEpoch % 100000}',
        fecha: DateTime.now(),
        clienteNombre: widget.prestamo.clienteNombre,
      );

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

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Saldar Préstamo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esto paga TODO lo pendiente del préstamo de una sola '
                    'vez, incluidas las cuotas que todavía no están en su '
                    'fecha de vencimiento.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FilaResumen(
                    label: 'Capital pendiente',
                    value: Formatters.currency(_capitalPendiente),
                  ),
                  _FilaResumen(
                    label: 'Mora',
                    value: Formatters.currency(_moraTotal),
                    colorValor: _moraTotal > 0
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
              label: 'Confirmar saldo · ${Formatters.currency(_totalAPagar)}',
              icon: Icons.check_circle_outline,
              isLoading: state.isLoading,
              onPressed: _confirmar,
            ),
          ],
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
