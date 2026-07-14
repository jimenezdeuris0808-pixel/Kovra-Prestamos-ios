import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/cliente.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/estado_prestamo_badge.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/puntuacion_badge.dart';
import '../../../shared/widgets/quick_detail_tile.dart';
import '../../prestamos/screens/detalle_prestamo_screen.dart';
import '../../prestamos/screens/solicitar_prestamo_screen.dart';
import '../providers/clientes_providers.dart';
import 'historial_pagos_screen.dart';

/// Pantalla "Detalle Cliente": cabecera con avatar y puntuación, grilla de
/// datos rápidos, lista de préstamos.
class DetalleClienteScreen extends ConsumerWidget {
  const DetalleClienteScreen({super.key, required this.clienteId});

  final int clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteAsync = ref.watch(clienteDetalleProvider(clienteId));

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Detalle del Cliente')),
      body: clienteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(clienteDetalleProvider(clienteId)),
        ),
        data: (cliente) => _DetalleClienteBody(cliente: cliente),
      ),
    );
  }
}

class _DetalleClienteBody extends ConsumerWidget {
  const _DetalleClienteBody({required this.cliente});

  final Cliente cliente;

  void _solicitarPrestamo(
    BuildContext context,
    WidgetRef ref, {
    int? prestamoOrigenId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SolicitarPrestamoScreen(
          clienteId: cliente.id,
          prestamoOrigenId: prestamoOrigenId,
        ),
      ),
    );
    // Al volver (incluso si la solicitud reemplazó la pantalla por el
    // Detalle del Préstamo), refresca el detalle del cliente para reflejar
    // la nueva solicitud en la lista de préstamos.
    ref.invalidate(clienteDetalleProvider(cliente.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamos = cliente.prestamos ?? const [];
    final prestamosActivos = prestamos
        .where((p) =>
            p.estado == EstadoPrestamo.aprobado ||
            p.estado == EstadoPrestamo.enAcuerdo)
        .length;
    // Primero de la lista porque ya viene ordenada desc por `id` desde
    // `GET /clientes/{id}` (NOTES_REENGANCHE.md, sección 6.1). Incluye
    // `enAcuerdo` a diferencia de la lógica anterior (bug corregido).
    final prestamoActivo = prestamos.firstWhereOrNull(
      (p) =>
          p.estado == EstadoPrestamo.pendiente ||
          p.estado == EstadoPrestamo.aprobado ||
          p.estado == EstadoPrestamo.enAcuerdo,
    );
    final capitalTotal =
        prestamos.fold<double>(0, (acc, p) => acc + p.monto);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Cabecera(cliente: cliente)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATOS RÁPIDOS',
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
                        icon: Icons.folder_copy_outlined,
                        label: 'Préstamos',
                        value: '${prestamos.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickDetailTile(
                        icon: Icons.bolt_outlined,
                        label: 'Activos',
                        value: '$prestamosActivos',
                        valueColor: prestamosActivos > 0
                            ? AppColors.successStrong
                            : AppColors.neutralGray,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickDetailTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Capital total',
                        value: Formatters.currency(capitalTotal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistorialPagosScreen(
                          clienteId: cliente.id,
                          clienteNombre: cliente.nombreCompleto,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Historial de pagos'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Préstamos (${prestamos.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                if (prestamoActivo == null)
                  TextButton.icon(
                    onPressed: () => _solicitarPrestamo(context, ref),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Solicitar préstamo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                else if (prestamoActivo.estado == EstadoPrestamo.pendiente)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Solicitud pendiente de aprobación',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () => _solicitarPrestamo(
                      context,
                      ref,
                      prestamoOrigenId: prestamoActivo.id,
                    ),
                    icon: const Icon(Icons.autorenew, size: 18),
                    label: const Text('Reenganchar préstamo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (prestamos.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'Este cliente no tiene préstamos registrados.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            sliver: SliverList.separated(
              itemCount: prestamos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final prestamo = prestamos[index];
                return _PrestamoTile(prestamo: prestamo);
              },
            ),
          ),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.cliente});

  final Cliente cliente;

  String get _iniciales {
    final nombre = cliente.nombreCompleto.trim();
    if (nombre.isEmpty) return '?';
    final partes = nombre.split(RegExp(r'\s+'));
    final primera = partes.first.substring(0, 1);
    final segunda = partes.length > 1 ? partes[1].substring(0, 1) : '';
    return (primera + segunda).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      crossAxisAlignment: CrossAxisAlignment.start,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.white.withOpacity(0.16),
        child: Text(
          _iniciales,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      title: cliente.nombreCompleto,
      titleStyle: const TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Cédula: ${cliente.cedula}',
              style: TextStyle(
                  color: AppColors.white.withOpacity(0.78), fontSize: 13),
            ),
          ),
          if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.call_outlined,
                      size: 13, color: AppColors.white.withOpacity(0.78)),
                  const SizedBox(width: 4),
                  Text(
                    cliente.telefono!,
                    style: TextStyle(
                        color: AppColors.white.withOpacity(0.78),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.white.withOpacity(0.78)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cliente.direccion!,
                      style: TextStyle(
                          color: AppColors.white.withOpacity(0.78),
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: PuntuacionBadge(puntuacion: cliente.puntuacion),
          ),
        ],
      ),
    );
  }
}

class _PrestamoTile extends StatelessWidget {
  const _PrestamoTile({required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DetallePrestamoScreen(prestamoId: prestamo.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Préstamo #${prestamo.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.currency(prestamo.monto)} · cuota ${Formatters.currency(prestamo.cuota)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                      if (prestamo.moraTotal > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Mora: ${Formatters.currency(prestamo.moraTotal)}',
                          style: const TextStyle(
                            color: AppColors.dangerStrong,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                EstadoPrestamoBadge(estado: prestamo.estado),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
