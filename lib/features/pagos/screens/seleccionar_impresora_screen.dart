import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/printing/receipt_printer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/primary_button.dart';

/// Lista las impresoras Bluetooth YA emparejadas desde los ajustes del
/// sistema y deja elegir una para imprimir recibos. Emparejar una impresora
/// nueva (buscarla, poner el PIN, etc.) se hace desde los ajustes de
/// Bluetooth del propio celular -- fuera del alcance de esta pantalla, que
/// solo consume lo que el sistema operativo ya conoce.
///
/// Devuelve la MAC elegida via `Navigator.pop(mac)`, o `null` si el usuario
/// cancela.
class SeleccionarImpresoraScreen extends ConsumerStatefulWidget {
  const SeleccionarImpresoraScreen({super.key});

  @override
  ConsumerState<SeleccionarImpresoraScreen> createState() =>
      _SeleccionarImpresoraScreenState();
}

class _SeleccionarImpresoraScreenState
    extends ConsumerState<SeleccionarImpresoraScreen> {
  late Future<_EstadoImpresoras> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_EstadoImpresoras> _cargar() async {
    final service = ref.read(receiptPrinterServiceProvider);
    final habilitado = await service.bluetoothHabilitado();
    if (!habilitado) {
      return const _EstadoImpresoras(bluetoothHabilitado: false, impresoras: []);
    }
    final impresoras = await service.listarImpresorasEmparejadas();
    return _EstadoImpresoras(bluetoothHabilitado: true, impresoras: impresoras);
  }

  void _recargar() {
    setState(() => _futuro = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: const Text('Elegir impresora'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: FutureBuilder<_EstadoImpresoras>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _recargar,
            );
          }

          final estado = snapshot.data!;
          if (!estado.bluetoothHabilitado) {
            return const EmptyState(
              icon: Icons.bluetooth_disabled,
              title: 'Bluetooth apagado',
              message:
                  'Activa el Bluetooth del celular y vuelve a intentarlo.',
            );
          }
          if (estado.impresoras.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EmptyState(
                    icon: Icons.print_disabled_outlined,
                    title: 'No hay impresoras emparejadas',
                    message:
                        'Empareja tu impresora térmica desde los ajustes de '
                        'Bluetooth del celular y luego vuelve a esta pantalla.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Volver a buscar',
                    icon: Icons.refresh,
                    onPressed: _recargar,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: estado.impresoras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final impresora = estado.impresoras[index];
              return Container(
                decoration: ClayDecoration.surface(radius: AppRadii.md),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () => Navigator.of(context).pop(impresora.mac),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          const Icon(Icons.print_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  impresora.nombre.isEmpty
                                      ? 'Impresora sin nombre'
                                      : impresora.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  impresora.mac,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EstadoImpresoras {
  const _EstadoImpresoras({
    required this.bluetoothHabilitado,
    required this.impresoras,
  });

  final bool bluetoothHabilitado;
  final List<ImpresoraBluetooth> impresoras;
}
