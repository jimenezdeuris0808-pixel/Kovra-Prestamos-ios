import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/factura.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/cuota_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/estado_prestamo_badge.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/quick_detail_tile.dart';
import '../../pagos/screens/registrar_pago_screen.dart';
import '../providers/prestamos_providers.dart';

/// Pantalla "Detalle Préstamo": cabecera con estado, grilla de "detalles
/// rápidos", aviso de saldo pendiente, lista de cuotas y acceso directo a
/// cobrar la próxima cuota pagable.
class DetallePrestamoScreen extends ConsumerWidget {
  const DetallePrestamoScreen({super.key, required this.prestamoId});

  final int prestamoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamoAsync = ref.watch(prestamoDetalleProvider(prestamoId));

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Detalle del Préstamo')),
      body: prestamoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(prestamoDetalleProvider(prestamoId)),
        ),
        data: (prestamo) => _DetallePrestamoBody(prestamo: prestamo),
      ),
    );
  }
}

class _DetallePrestamoBody extends ConsumerWidget {
  const _DetallePrestamoBody({required this.prestamo});

  final Prestamo prestamo;

  Future<void> _abrirPago(BuildContext context, WidgetRef ref, Factura factura) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistrarPagoScreen(
          factura: factura,
          prestamoId: prestamo.id,
          montoPrestamo: prestamo.monto,
          tasaInteres: prestamo.tasaInteres,
        ),
      ),
    );

    if (resultado == true) {
      ref.invalidate(prestamoDetalleProvider(prestamo.id));
    }
  }

  Factura? get _proximaCuotaPagable {
    for (final f in prestamo.facturas) {
      if (f.esPagable) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esPendiente = prestamo.estado == EstadoPrestamo.pendiente;
    final proximaCuota = esPendiente ? null : _proximaCuotaPagable;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Cabecera(prestamo: prestamo)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _DetallesRapidos(prestamo: prestamo),
              ),
            ),
            if (esPendiente)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
                      AppSpacing.lg),
                  child: _BannerPendienteAprobacion(),
                ),
              )
            else ...[
              if (prestamo.saldoPendiente > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: _BannerPendiente(monto: prestamo.saldoPendiente),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xl, AppSpacing.lg,
                      AppSpacing.sm),
                  child: Text(
                    'Cuotas (${prestamo.facturas.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              if (prestamo.facturas.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Este préstamo no tiene cuotas registradas.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                      AppSpacing.lg, proximaCuota != null ? 96 : AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: prestamo.facturas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final factura = prestamo.facturas[index];
                      return CuotaCard(
                        factura: factura,
                        onTap: factura.esPagable
                            ? () => _abrirPago(context, ref, factura)
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
        if (proximaCuota != null)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: PrimaryButton(
              backgroundColor: AppColors.success,
              icon: Icons.payments_outlined,
              label: 'Cobrar cuota #${proximaCuota.numeroCuota} · '
                  '${Formatters.currency(proximaCuota.totalConMora)}',
              onPressed: () => _abrirPago(context, ref, proximaCuota),
            ),
          ),
      ],
    );
  }
}

class _BannerPendienteAprobacion extends StatelessWidget {
  const _BannerPendienteAprobacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: ClayDecoration.surface(
        color: AppColors.warning.withOpacity(0.14),
        radius: AppRadii.md,
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_outlined,
              color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendiente de aprobación',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Este préstamo aún no ha sido aprobado. Las cuotas se '
                  'generarán automáticamente al aprobarlo desde '
                  '"Solicitudes Pendientes".',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      crossAxisAlignment: CrossAxisAlignment.start,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.white.withOpacity(0.16),
        child: Text(
          _iniciales(prestamo.clienteNombre),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      title: prestamo.clienteNombre ?? 'Préstamo #${prestamo.id}',
      titleStyle: const TextStyle(
        color: AppColors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      titleMaxLines: 1,
      titleOverflow: TextOverflow.ellipsis,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Préstamo #${prestamo.id}',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.75),
                fontSize: 12.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                EstadoPrestamoBadge(estado: prestamo.estado),
                if (prestamo.puntuacion != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accentLighter),
                        const SizedBox(width: 4),
                        Text(
                          '${prestamo.puntuacion}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '?';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final primera = partes.first.substring(0, 1);
    final segunda = partes.length > 1 ? partes[1].substring(0, 1) : '';
    return (primera + segunda).toUpperCase();
  }
}

class _DetallesRapidos extends StatelessWidget {
  const _DetallesRapidos({required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETALLES RÁPIDOS',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: QuickDetailTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Capital',
                value: Formatters.currency(prestamo.monto),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickDetailTile(
                icon: Icons.event_repeat_outlined,
                label: 'Cuota',
                value: Formatters.currency(prestamo.cuota),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: QuickDetailTile(
                icon: Icons.trending_down_outlined,
                label: 'Saldo restante',
                value: Formatters.currency(prestamo.saldoPendiente),
                valueColor: prestamo.saldoPendiente > 0
                    ? AppColors.accent
                    : AppColors.successStrong,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickDetailTile(
                icon: Icons.warning_amber_outlined,
                label: 'Mora total',
                value: Formatters.currency(prestamo.moraTotal),
                valueColor: prestamo.moraTotal > 0
                    ? AppColors.dangerStrong
                    : AppColors.successStrong,
              ),
            ),
          ],
        ),
        if (prestamo.tipoAmortizacion != null ||
            prestamo.frecuenciaTasa != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: QuickDetailTile(
                  icon: Icons.calculate_outlined,
                  label: 'Amortización',
                  value: prestamo.tipoAmortizacion ?? '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickDetailTile(
                  icon: Icons.repeat_outlined,
                  label: 'Frecuencia',
                  value: prestamo.frecuenciaTasa?.toUpperCase() ?? '—',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerPendiente extends StatelessWidget {
  const _BannerPendiente({required this.monto});

  final double monto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: ClayDecoration.surface(
        color: AppColors.danger.withOpacity(0.1),
        radius: AppRadii.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pendiente a pagar',
                  style: TextStyle(
                    color: AppColors.dangerStrong,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  Formatters.currency(monto),
                  style: const TextStyle(
                    color: AppColors.dangerStrong,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
