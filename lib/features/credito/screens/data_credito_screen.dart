import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/deuda_credito.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/credito_providers.dart';

/// "Data Crédito": buró de crédito interno. Consulta si una cédula tiene
/// deudas activas en CUALQUIER empresa registrada en el sistema, no solo
/// en la propia. Puerto literal de `_util_data_credito` en `app_web.py` --
/// expone perfil completo del cliente y nombre de la otra empresa (sin
/// recortar), decisión confirmada con el usuario.
class DataCreditoScreen extends ConsumerStatefulWidget {
  const DataCreditoScreen({super.key});

  @override
  ConsumerState<DataCreditoScreen> createState() => _DataCreditoScreenState();
}

class _DataCreditoScreenState extends ConsumerState<DataCreditoScreen> {
  final _cedulaController = TextEditingController();
  String _cedula = '';

  @override
  void dispose() {
    _cedulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cedula = _cedula.trim();

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
              title: 'Data Crédito',
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Buró interno: deudas activas en cualquier empresa del sistema',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              bottom: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Container(
                  decoration: ClayDecoration.surface(radius: AppRadii.sm),
                  child: TextField(
                    controller: _cedulaController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Ej: 001-1234567-8',
                      prefixIcon:
                          const Icon(Icons.badge_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _cedulaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _cedulaController.clear();
                                setState(() => _cedula = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _cedula = value),
                  ),
                ),
              ),
            ),
            Expanded(
              child: cedula.isEmpty
                  ? const EmptyState(
                      icon: Icons.badge_outlined,
                      message: 'Escribe una cédula para consultar si tiene\n'
                          'deudas activas en otras empresas.',
                    )
                  : _ResultadosCredito(cedula: cedula),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadosCredito extends ConsumerWidget {
  const _ResultadosCredito({required this.cedula});

  final String cedula;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultadoAsync = ref.watch(creditoBusquedaProvider(cedula));

    return resultadoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(creditoBusquedaProvider(cedula)),
      ),
      data: (resultados) {
        if (resultados.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: _AvisoSinDeuda(),
            ),
          );
        }
        final totalAdeudado =
            resultados.fold<double>(0, (acc, r) => acc + r.saldoPendiente);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _AvisoConDeuda(
              cantidadEmpresas: resultados.length,
              totalAdeudado: totalAdeudado,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final r in resultados) ...[
              _DeudaTile(deuda: r),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _AvisoSinDeuda extends StatelessWidget {
  const _AvisoSinDeuda();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.successStrong),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta cédula no registra deudas activas en ninguna empresa del sistema.',
              style: TextStyle(
                color: AppColors.successStrong,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoConDeuda extends StatelessWidget {
  const _AvisoConDeuda({
    required this.cantidadEmpresas,
    required this.totalAdeudado,
  });

  final int cantidadEmpresas;
  final double totalAdeudado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠ Esta cédula tiene deuda activa en $cantidadEmpresas '
            '${cantidadEmpresas == 1 ? 'empresa' : 'empresas'}',
            style: const TextStyle(
              color: AppColors.dangerStrong,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total adeudado en todo el sistema: ${Formatters.currency(totalAdeudado)}',
            style: const TextStyle(
              color: AppColors.dangerStrong,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeudaTile extends ConsumerWidget {
  const _DeudaTile({required this.deuda});

  final DeudaCredito deuda;

  String get _situacion {
    if (deuda.cuotasVencidas > 0) return '🔴 En mora';
    switch (deuda.estado) {
      case 'en_acuerdo':
        return '🔵 En acuerdo de pago';
      case 'incobrable':
        return '🟣 Incobrable';
      case 'abandonado':
        return '⚪ Abandonado';
      default:
        return '🟢 Al día';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agregarState = ref.watch(agregarClienteCreditoControllerProvider);

    return ClayCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deuda.clienteNombre,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'Cédula ${deuda.cedula}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          Text(
            '📞 ${deuda.telefono ?? '—'}  |  ✉ ${deuda.email ?? '—'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          Text(
            '📍 ${deuda.direccion ?? '—'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Dato(
                label: 'Cliente de',
                value: deuda.empresa,
                destacado: true,
              ),
              _Dato(
                label: 'Debe',
                value: Formatters.currency(deuda.saldoPendiente) +
                    (deuda.cantidadPrestamos > 1
                        ? ' (${deuda.cantidadPrestamos} préstamos)'
                        : ''),
                colorValor: AppColors.dangerStrong,
              ),
              _Dato(label: 'Situación', value: _situacion),
              _Dato(label: 'Debe desde', value: deuda.fechaDesde ?? '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (deuda.esMiEmpresa)
            const Text(
              'Ya es cliente tuyo.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Agregar ${deuda.nombre} a mi cuenta',
                isLoading: agregarState.isProcessing(deuda.cedula),
                onPressed: () async {
                  final ok = await ref
                      .read(agregarClienteCreditoControllerProvider.notifier)
                      .agregar(deuda);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '${deuda.clienteNombre} fue agregado a tu cuenta como cliente.'
                              : ref
                                      .read(agregarClienteCreditoControllerProvider)
                                      .errorMessage ??
                                  'No se pudo agregar el cliente.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
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
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorValor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
