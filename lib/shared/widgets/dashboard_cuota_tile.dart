import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/clay_decoration.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/severidad_mora.dart';
import '../../domain/models/factura.dart';
import 'status_badge.dart';

/// Tarjeta de cuota para el dashboard: más densa en información que
/// [CuotaCard] (avatar de iniciales, severidad de mora por color, días de
/// atraso) porque aquí es donde el cobrador decide a quién visitar primero.
class DashboardCuotaTile extends StatelessWidget {
  const DashboardCuotaTile({
    super.key,
    required this.factura,
    required this.onTap,
  });

  final Factura factura;
  final VoidCallback onTap;

  String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '?';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final primera = partes.first.substring(0, 1);
    final segunda = partes.length > 1 ? partes[1].substring(0, 1) : '';
    return (primera + segunda).toUpperCase();
  }

  /// Color de texto legible para el avatar de iniciales: los semánticos
  /// base (`success`/`danger`) no tienen contraste suficiente como texto
  /// sobre superficies claras (ver `DESIGN_SYSTEM_CLAY.md`, secciones 1 y
  /// 6). Las severidades de mora (`severityMild`/`High`/`Loss`) no tienen
  /// variante "Strong" definida en el sistema de diseño, así que caen a
  /// `textPrimary`.
  Color _textColorFor(Color color) {
    if (color == AppColors.success) return AppColors.successStrong;
    if (color == AppColors.danger) return AppColors.dangerStrong;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final severidad = severidadDe(factura);
    final info = infoSeveridad(severidad);
    final dias = diasVencida(factura);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 54,
                  decoration: BoxDecoration(
                    color: info.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: info.color.withOpacity(0.14),
                  child: Text(
                    _iniciales(factura.clienteNombre),
                    style: TextStyle(
                      color: _textColorFor(info.color),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factura.clienteNombre ?? 'Cliente',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cuota #${factura.numeroCuota} · Vence ${Formatters.date(factura.fechaVencimiento)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(
                        label:
                            dias > 0 ? '${info.label} · $dias d' : info.label,
                        color: info.color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(factura.totalConMora),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (factura.mora > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '+${Formatters.currency(factura.mora)} mora',
                        style: const TextStyle(
                          color: AppColors.dangerStrong,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Icon(Icons.chevron_right,
                        color: AppColors.textSecondary.withOpacity(0.6)),
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
