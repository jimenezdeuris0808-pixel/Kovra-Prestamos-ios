import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/pago.dart';
import '../../../domain/models/pago_historial_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../pagos/screens/recibo_pago_screen.dart';
import '../providers/clientes_providers.dart';

/// Pantalla "Historial de Pagos": todos los cobros ya registrados de un
/// cliente (todos sus préstamos), más reciente primero. Cada uno se puede
/// abrir para reenviar o reimprimir su recibo -- a diferencia del recibo
/// que aparece justo después de registrar un pago (que solo vive en la
/// memoria de esa pantalla), este permite volver a un cobro de hace
/// semanas o meses.
class HistorialPagosScreen extends ConsumerWidget {
  const HistorialPagosScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  final int clienteId;
  final String clienteNombre;

  void _abrirRecibo(BuildContext context, PagoHistorialItem pago) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReciboPagoScreen(resultado: pago.toPagoResultado()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialPagosClienteProvider(clienteId));

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientHeader(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              title: 'Historial de Pagos',
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  clienteNombre,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: historialAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(
                    historialPagosClienteProvider(clienteId),
                  ),
                ),
                data: (pagos) {
                  if (pagos.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'Este cliente todavía no tiene pagos registrados.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: pagos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pago = pagos[index];
                      return _PagoTile(
                        pago: pago,
                        onTap: () => _abrirRecibo(context, pago),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile({required this.pago, required this.onTap});

  final PagoHistorialItem pago;
  final VoidCallback onTap;

  String get _metodoLabel {
    final metodo = MetodoPago.values
        .where((m) => m.apiValue == pago.metodo)
        .toList();
    return metodo.isNotEmpty ? metodo.first.label : pago.metodo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuota ${pago.numeroCuota} · Préstamo #${pago.prestamoId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Formatters.date(pago.fechaPago)} · $_metodoLabel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(pago.monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
