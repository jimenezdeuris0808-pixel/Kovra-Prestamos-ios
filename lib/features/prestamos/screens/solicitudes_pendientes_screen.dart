import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/prestamo.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../providers/prestamos_providers.dart';

/// Pantalla "Solicitudes Pendientes": listado de préstamos en estado
/// `pendiente` (`GET /prestamos?estado=pendiente`), con acciones de
/// aprobar/rechazar (`POST /prestamos/{id}/aprobar` y `/rechazar`).
class SolicitudesPendientesScreen extends ConsumerStatefulWidget {
  const SolicitudesPendientesScreen({super.key});

  @override
  ConsumerState<SolicitudesPendientesScreen> createState() =>
      _SolicitudesPendientesScreenState();
}

class _SolicitudesPendientesScreenState
    extends ConsumerState<SolicitudesPendientesScreen> {
  Future<bool> _confirmar({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _aprobar(SolicitudPrestamo solicitud) async {
    final confirmado = await _confirmar(
      title: 'Aprobar préstamo',
      content:
          '¿Aprobar el préstamo de ${solicitud.clienteNombre} por '
          '${Formatters.currency(solicitud.monto)}? Se generarán '
          '${solicitud.plazoMeses} cuotas de ${Formatters.currency(solicitud.cuota)}.',
      confirmLabel: 'Aprobar',
    );
    if (!confirmado) return;

    final resultado = await ref
        .read(aprobarRechazarPrestamoControllerProvider.notifier)
        .aprobar(solicitud.id);

    if (!mounted) return;
    if (resultado != null) {
      ref.invalidate(solicitudesPendientesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Préstamo aprobado. Se generaron '
            '${resultado.cantidadFacturasGeneradas} cuotas.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref
              .read(aprobarRechazarPrestamoControllerProvider)
              .errorMessage ??
          'No se pudo aprobar el préstamo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _rechazar(SolicitudPrestamo solicitud) async {
    final confirmado = await _confirmar(
      title: 'Rechazar préstamo',
      content:
          '¿Rechazar el préstamo de ${solicitud.clienteNombre}? Esta acción '
          'penaliza la puntuación del cliente y no se puede deshacer.',
      confirmLabel: 'Rechazar',
    );
    if (!confirmado) return;

    final resultado = await ref
        .read(aprobarRechazarPrestamoControllerProvider.notifier)
        .rechazar(solicitud.id);

    if (!mounted) return;
    if (resultado != null) {
      ref.invalidate(solicitudesPendientesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Préstamo rechazado. Puntuación del cliente: '
            '${resultado.puntuacionClienteAnterior} → '
            '${resultado.puntuacionClienteNueva}.',
          ),
          backgroundColor: AppColors.neutralGray,
        ),
      );
    } else {
      final error = ref
              .read(aprobarRechazarPrestamoControllerProvider)
              .errorMessage ??
          'No se pudo rechazar el préstamo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesAsync = ref.watch(solicitudesPendientesProvider);
    final accionState = ref.watch(aprobarRechazarPrestamoControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(title: const Text('Solicitudes Pendientes')),
      body: solicitudesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(solicitudesPendientesProvider),
        ),
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(solicitudesPendientesProvider);
                await ref.read(solicitudesPendientesProvider.future);
              },
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.task_alt_outlined,
                    message: 'No hay solicitudes de préstamo pendientes.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(solicitudesPendientesProvider);
              await ref.read(solicitudesPendientesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: solicitudes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final solicitud = solicitudes[index];
                return _SolicitudCard(
                  solicitud: solicitud,
                  isProcessing: accionState.isProcessing(solicitud.id),
                  onAprobar: () => _aprobar(solicitud),
                  onRechazar: () => _rechazar(solicitud),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({
    required this.solicitud,
    required this.isProcessing,
    required this.onAprobar,
    required this.onRechazar,
  });

  final SolicitudPrestamo solicitud;
  final bool isProcessing;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  solicitud.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                Formatters.date(solicitud.fechaSolicitud),
                style: const TextStyle(
                  color: AppColors.neutralGray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  label: 'Monto',
                  value: Formatters.currency(solicitud.monto),
                ),
              ),
              Expanded(
                child: _Dato(
                  label: 'Cuota (${solicitud.plazoMeses} meses)',
                  value: Formatters.currency(solicitud.cuota),
                ),
              ),
              Expanded(
                child: _Dato(
                  label: 'Tasa mensual',
                  value: '${solicitud.tasaInteres}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _AccionButton(
                  label: 'Rechazar',
                  icon: Icons.close_rounded,
                  color: AppColors.danger,
                  outlined: true,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onRechazar,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AccionButton(
                  label: 'Aprobar',
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  outlined: false,
                  isLoading: isProcessing,
                  onPressed: isProcessing ? null : onAprobar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.neutralGray,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Botón de acción local (Aprobar/Rechazar) con soporte de loading.
///
/// No se reutiliza `PrimaryButton`/`SecondaryButton` aquí porque ninguno de
/// los dos expone un parámetro de color hoy (ver `shared/widgets/`), y esos
/// archivos están siendo modificados en paralelo por el rediseño clay. Es un
/// widget privado de esta pantalla, no una abstracción nueva compartida.
class _AccionButton extends StatelessWidget {
  const _AccionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.outlined,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                outlined ? color : AppColors.white,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: child,
    );
  }
}
