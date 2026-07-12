import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/severidad_mora.dart';
import '../../domain/models/factura.dart';
import 'estado_factura_badge.dart';

/// Tarjeta reutilizable para mostrar una cuota/factura (detalle de
/// préstamo). El color de la barra lateral refleja la severidad de mora.
class CuotaCard extends StatelessWidget {
  const CuotaCard({
    super.key,
    required this.factura,
    this.onTap,
    this.mostrarCliente = false,
  });

  final Factura factura;
  final VoidCallback? onTap;
  final bool mostrarCliente;

  @override
  Widget build(BuildContext context) {
    final colorSeveridad = factura.estado == EstadoFactura.pagada
        ? AppColors.success
        : infoSeveridad(severidadDe(factura)).color;

    return Container(
      decoration: ClayDecoration.surface(radius: AppRadii.md),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorSeveridad,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mostrarCliente && factura.clienteNombre != null)
                        Text(
                          factura.clienteNombre!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        'Cuota #${factura.numeroCuota}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: mostrarCliente ? 12 : 14,
                          fontWeight:
                              mostrarCliente ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vence: ${Formatters.date(factura.fechaVencimiento)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (factura.mora > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Mora: ${Formatters.currency(factura.mora)}',
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(factura.montoCuota),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    EstadoFacturaBadge(estado: factura.estado),
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
