import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// Banner no bloqueante con el aviso de pago cuando al tenant le quedan
/// pocos días de servicio o ya venció (dentro del período de gracia). No
/// impide seguir usando la app -- se puede cerrar y solo vuelve a aparecer
/// si se reabre la pantalla (no persiste el cierre entre sesiones).
class VigenciaBanner extends ConsumerStatefulWidget {
  const VigenciaBanner({super.key});

  @override
  ConsumerState<VigenciaBanner> createState() => _VigenciaBannerState();
}

class _VigenciaBannerState extends ConsumerState<VigenciaBanner> {
  bool _cerrado = false;

  @override
  Widget build(BuildContext context) {
    if (_cerrado) return const SizedBox.shrink();

    final avisoAsync = ref.watch(avisoVigenciaProvider);
    final aviso = avisoAsync.valueOrNull;
    if (aviso == null || aviso.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                aviso,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _cerrado = true),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
