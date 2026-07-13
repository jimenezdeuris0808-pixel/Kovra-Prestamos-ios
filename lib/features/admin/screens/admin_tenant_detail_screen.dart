import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/tenant_admin.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../providers/admin_tenants_providers.dart';

/// Detalle de un tenant: permite editar su vigencia (fecha de expiración)
/// y alternar su estado activo/inactivo.
class AdminTenantDetailScreen extends ConsumerStatefulWidget {
  const AdminTenantDetailScreen({super.key, required this.tenant});

  final TenantAdmin tenant;

  @override
  ConsumerState<AdminTenantDetailScreen> createState() =>
      _AdminTenantDetailScreenState();
}

class _AdminTenantDetailScreenState
    extends ConsumerState<AdminTenantDetailScreen> {
  late TenantAdmin _tenant;
  bool _isUpdating = false;

  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
  }

  Future<void> _guardarVigencia(String? fechaExpiracion) async {
    setState(() => _isUpdating = true);
    final controller = ref.read(adminTenantActionsControllerProvider.notifier);
    final actualizado =
        await controller.actualizarVigencia(_tenant.id, fechaExpiracion);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (actualizado != null) {
      setState(() => _tenant = actualizado);
      _mostrarConfirmacion('Vigencia actualizada.');
    } else {
      _mostrarConfirmacion('No se pudo actualizar la vigencia.', esError: true);
    }
  }

  Future<void> _alternarEstado(bool activo) async {
    setState(() => _isUpdating = true);
    final controller = ref.read(adminTenantActionsControllerProvider.notifier);
    final actualizado = await controller.actualizarEstado(
      _tenant.id,
      activo ? 'activo' : 'inactivo',
    );
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (actualizado != null) {
      setState(() => _tenant = actualizado);
      _mostrarConfirmacion(
        activo ? 'Tenant activado.' : 'Tenant desactivado.',
      );
    } else {
      _mostrarConfirmacion('No se pudo actualizar el estado.', esError: true);
    }
  }

  void _mostrarConfirmacion(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _abrirEditorVigencia() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceClay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Editar vigencia',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ChipVigencia(
                      label: '+30 días',
                      onTap: () {
                        Navigator.of(context).pop();
                        _guardarVigencia(_fechaEnDias(30));
                      },
                    ),
                    _ChipVigencia(
                      label: '+90 días',
                      onTap: () {
                        Navigator.of(context).pop();
                        _guardarVigencia(_fechaEnDias(90));
                      },
                    ),
                    _ChipVigencia(
                      label: '+1 año',
                      onTap: () {
                        Navigator.of(context).pop();
                        _guardarVigencia(_fechaEnDias(365));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  label: 'Elegir fecha manual',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _elegirFechaManual();
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _guardarVigencia(null);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerStrong,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Quitar vencimiento'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fechaEnDias(int dias) {
    return _apiDateFormat.format(DateTime.now().add(Duration(days: dias)));
  }

  Future<void> _elegirFechaManual() async {
    final fechaActual = Formatters.parseDate(_tenant.fechaExpiracion);
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
    );

    if (seleccionada != null) {
      await _guardarVigencia(_apiDateFormat.format(seleccionada));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaExpiracion = Formatters.parseDate(_tenant.fechaExpiracion);
    final vigenciaTexto = fechaExpiracion == null
        ? 'Sin vencimiento'
        : Formatters.date(fechaExpiracion);

    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: Text(_tenant.nombreEmpresa),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: ClayDecoration.surface(radius: AppRadii.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Empresa', value: _tenant.nombreEmpresa),
                  if (_tenant.nombreComercial != null &&
                      _tenant.nombreComercial!.isNotEmpty)
                    _InfoRow(
                      label: 'Nombre comercial',
                      value: _tenant.nombreComercial!,
                    ),
                  _InfoRow(label: 'Slug', value: _tenant.slug),
                  _InfoRow(label: 'Vigencia', value: vigenciaTexto),
                  _InfoRow(
                    label: 'Creado',
                    value: Formatters.date(
                      Formatters.parseDate(_tenant.creadoEn),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: ClayDecoration.surface(radius: AppRadii.md),
              child: SwitchListTile(
                title: const Text(
                  'Tenant activo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _tenant.activo
                      ? 'Los cobradores pueden iniciar sesión.'
                      : 'Los cobradores no pueden iniciar sesión.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                value: _tenant.activo,
                activeColor: AppColors.success,
                onChanged: _isUpdating
                    ? null
                    : (value) => _alternarEstado(value),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Editar vigencia',
              icon: Icons.edit_calendar_outlined,
              isLoading: _isUpdating,
              onPressed: _abrirEditorVigencia,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipVigencia extends StatelessWidget {
  const _ChipVigencia({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.accentLighter.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      labelStyle: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
