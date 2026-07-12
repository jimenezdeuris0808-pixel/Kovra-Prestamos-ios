import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/tenant_branding.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../providers/empresa_providers.dart';

/// Pantalla "Mi Empresa": nombre comercial, teléfono, RNC/cédula y logo --
/// estos datos aparecen en la cabecera del recibo de pago al cobrarle a un
/// cliente. Puerto ampliado de la sección "🎨 Mi Empresa (marca)" de
/// `app_web.py` (línea ~5868), que en el legado no tenía teléfono ni RNC.
class MiEmpresaScreen extends ConsumerStatefulWidget {
  const MiEmpresaScreen({super.key});

  @override
  ConsumerState<MiEmpresaScreen> createState() => _MiEmpresaScreenState();
}

class _MiEmpresaScreenState extends ConsumerState<MiEmpresaScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _rncController = TextEditingController();
  bool _prellenado = false;
  Uint8List? _logoNuevoBytes;
  String? _logoNuevoNombre;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _rncController.dispose();
    super.dispose();
  }

  Future<void> _elegirLogo() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _logoNuevoBytes = bytes;
      _logoNuevoNombre = xfile.name;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(miEmpresaControllerProvider.notifier);

    if (_logoNuevoBytes != null && _logoNuevoNombre != null) {
      final okLogo =
          await controller.subirLogo(_logoNuevoBytes!, _logoNuevoNombre!);
      if (!okLogo) return;
    }

    final ok = await controller.guardar(
      nombreComercial: _nombreController.text.trim().isEmpty
          ? null
          : _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      rncCedula: _rncController.text.trim().isEmpty
          ? null
          : _rncController.text.trim(),
    );

    if (ok && mounted) {
      setState(() {
        _logoNuevoBytes = null;
        _logoNuevoNombre = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de la empresa actualizados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandingAsync = ref.watch(empresaBrandingProvider);
    final logoAsync = ref.watch(currentLogoProvider);
    final state = ref.watch(miEmpresaControllerProvider);

    ref.listen(empresaBrandingProvider, (previous, next) {
      final branding = next.valueOrNull;
      if (branding != null && !_prellenado) {
        _prellenado = true;
        _nombreController.text = branding.nombreComercial ?? '';
        _telefonoController.text = branding.telefono ?? '';
        _rncController.text = branding.rncCedula ?? '';
      }
    });

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
              title: 'Mi Empresa',
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Estos datos aparecen en tus recibos de pago',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: brandingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(empresaBrandingProvider),
                ),
                data: (_) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClayCard(
                        child: Column(
                          children: [
                            _LogoPreview(
                              bytesNuevos: _logoNuevoBytes,
                              logoActual: logoAsync.valueOrNull,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SecondaryButton(
                              label: 'Cambiar logo',
                              icon: Icons.image_outlined,
                              onPressed: _elegirLogo,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClayCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre comercial',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _rncController,
                              decoration: const InputDecoration(
                                labelText: 'RNC / Cédula',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.danger, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Guardar cambios',
                        isLoading: state.isLoading,
                        onPressed: _guardar,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.bytesNuevos, required this.logoActual});

  final Uint8List? bytesNuevos;
  final TenantLogo? logoActual;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (bytesNuevos != null) {
      child = Image.memory(bytesNuevos!, height: 80, fit: BoxFit.contain);
    } else if (logoActual != null) {
      child = logoActual!.esSvg
          ? SvgPicture.memory(
              Uint8List.fromList(logoActual!.bytes),
              height: 80,
            )
          : Image.memory(
              Uint8List.fromList(logoActual!.bytes),
              height: 80,
              fit: BoxFit.contain,
            );
    } else {
      child = const Icon(Icons.storefront_outlined,
          size: 56, color: AppColors.textSecondary);
    }
    return SizedBox(height: 90, child: Center(child: child));
  }
}
