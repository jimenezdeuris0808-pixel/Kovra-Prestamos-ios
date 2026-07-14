import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/clay_decoration.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/pago.dart';
import '../../../domain/models/tenant_branding.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// Pantalla "Recibo de Pago": comprobante en pantalla (nombre de la empresa
/// del tenant, folio, desglose y código de barras decorativo), botones
/// Compartir e Imprimir.
///
/// El nombre de la empresa viene de `currentNombreEmpresaProvider` (sesión
/// del tenant logueado) -- NUNCA hardcodear "Kovra" acá: cada tenant tiene
/// su propia empresa y ve sus propios recibos con su propio nombre.
class ReciboPagoScreen extends ConsumerWidget {
  ReciboPagoScreen({super.key, required this.resultado});

  final PagoResultado resultado;

  /// Ancla el `RepaintBoundary` de [_ReciboCard] para poder capturarlo como
  /// imagen al compartir/imprimir. Campo de instancia (no `const`) porque un
  /// `GlobalKey` debe mantenerse estable mientras viva esta pantalla.
  final GlobalKey _reciboKey = GlobalKey();

  /// Renderiza el recibo (el `RepaintBoundary` marcado con [_reciboKey]) a
  /// PNG en memoria. `pixelRatio: 3` para que se vea nítido al compartirlo a
  /// tamaño completo en WhatsApp/galería, no solo del tamaño de pantalla.
  Future<Uint8List> _capturarReciboComoImagen() async {
    final boundary = _reciboKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Comparte el recibo como imagen.
  ///
  /// Antes usaba `XFile.fromData` (bytes en memoria, sin archivo real en
  /// disco) -- en iOS el share sheet nativo de `share_plus` no siempre
  /// resuelve ese tipo de `XFile` correctamente, y como la excepción no se
  /// capturaba, el botón "no hacía nada" en vez de mostrar un error. Ahora
  /// se escribe la imagen a un archivo temporal real (`path_provider`) y se
  /// comparte por ruta, que es el flujo soportado de forma consistente en
  /// iOS y Android. Cualquier falla se muestra al usuario en vez de
  /// quedar silenciosa.
  Future<void> _compartir(BuildContext context, String nombreEmpresa) async {
    try {
      final bytes = await _capturarReciboComoImagen();
      final folio = resultado.folio ?? 'recibo';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/recibo_$folio.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'Comprobante de pago $nombreEmpresa',
        text: 'Comprobante de pago $nombreEmpresa — Folio $folio',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el recibo. Intenta de nuevo.'),
          ),
        );
      }
    }
  }

  Future<void> _imprimir(BuildContext context, String nombreEmpresa) async {
    // Nota: la impresión real requiere integración con un servicio de
    // impresión térmica/PDF (ej. paquete `printing`), fuera del alcance de
    // este MVP. Por ahora reutilizamos el flujo de compartir (imagen del
    // recibo) como acción equivalente para enviar el comprobante a una
    // impresora vía sistema.
    await _compartir(context, nombreEmpresa);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una impresora desde el diálogo del sistema.')),
      );
    }
  }

  /// Vuelve a `HomeShell` cerrando todas las pantallas apiladas encima de
  /// la ruta raíz (`_RootRouter`, ver `main.dart`).
  ///
  /// Antes usaba `pushNamedAndRemoveUntil('/home', ...)`, que reemplazaba
  /// la ruta raíz por una construida a mano con `HomeShell()` -- eso
  /// destruía `_RootRouter` (junto con su `ref.listen` de logout automático
  /// por sesión expirada), dejando la app sin ese listener por el resto de
  /// la sesión, y en ciertos encadenamientos de rutas producía pantalla en
  /// negro. `_RootRouter` ya nunca se reemplaza (ver el fix equivalente en
  /// `login_screen.dart`/`signup_screen.dart`), así que la ruta más al
  /// fondo del stack SIEMPRE es `_RootRouter`, que muestra `HomeShell`
  /// automáticamente (es reactivo a `sessionControllerProvider`) apenas se
  /// vuelve a ella.
  void _volverAlInicio(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombreEmpresa =
        ref.watch(currentNombreEmpresaProvider).valueOrNull ?? 'Kovra';
    final logo = ref.watch(currentLogoProvider).valueOrNull;
    final telefono = ref.watch(currentTelefonoEmpresaProvider).valueOrNull;
    final rncCedula = ref.watch(currentRncEmpresaProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.backgroundClay,
      appBar: AppBar(
        title: const Text('Recibo de Pago'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _volverAlInicio(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Pago registrado con éxito',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              if (resultado.prestamoEstado == 'pagado') ...[
                const SizedBox(height: AppSpacing.md),
                _AvisoExcedente(
                  icon: Icons.verified_outlined,
                  texto: resultado.cuotasAdicionalesSaldadas > 0
                      ? 'El excedente saldó ${resultado.cuotasAdicionalesSaldadas} '
                          'cuota(s) adicional(es) y el préstamo quedó pagado '
                          'por completo.'
                      : 'El préstamo quedó pagado por completo.',
                ),
              ] else if (resultado.cuotasAdicionalesSaldadas > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _AvisoExcedente(
                  icon: Icons.trending_up_outlined,
                  texto: 'El excedente saldó ${resultado.cuotasAdicionalesSaldadas} '
                      'cuota(s) adicional(es) de este préstamo.',
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              RepaintBoundary(
                key: _reciboKey,
                child: _ReciboCard(
                  resultado: resultado,
                  nombreEmpresa: nombreEmpresa,
                  logo: logo,
                  telefono: telefono,
                  rncCedula: rncCedula,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Imprimir',
                      icon: Icons.print_outlined,
                      onPressed: () => _imprimir(context, nombreEmpresa),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Compartir',
                      icon: Icons.share_outlined,
                      onPressed: () => _compartir(context, nombreEmpresa),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => _volverAlInicio(context),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de que el excedente cobrado saldó cuotas adicionales y/o cerró el
/// préstamo por completo (ver `cuotas_adicionales_saldadas`/`prestamo_estado`
/// en `PagoResultado`, `Kovra_API/app/routers/pagos_router.py`).
class _AvisoExcedente extends StatelessWidget {
  const _AvisoExcedente({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.successStrong, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.successStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciboCard extends StatelessWidget {
  const _ReciboCard({
    required this.resultado,
    required this.nombreEmpresa,
    this.logo,
    this.telefono,
    this.rncCedula,
  });

  final PagoResultado resultado;
  final String nombreEmpresa;

  /// Logo real que el tenant cargó al crear su empresa (`GET /auth/logo`).
  /// Si es `null` (tenant sin logo configurado, o no se pudo descargar),
  /// se muestra el nombre en texto como fallback -- nunca un logo fijo de
  /// otra empresa.
  final TenantLogo? logo;

  /// Teléfono/RNC-cédula de "Mi Empresa" -- `null` si el tenant no los
  /// configuró todavía, en cuyo caso simplemente no se muestran.
  final String? telefono;
  final String? rncCedula;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration.surface(
        color: AppColors.white,
        radius: AppRadii.lg,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.lg),
            child: Column(
              children: [
                if (logo != null) ...[
                  SizedBox(
                    height: 64,
                    child: logo!.esSvg
                        ? SvgPicture.memory(
                            Uint8List.fromList(logo!.bytes),
                            height: 64,
                          )
                        : Image.memory(
                            Uint8List.fromList(logo!.bytes),
                            height: 64,
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
                // El nombre de la empresa SIEMPRE se muestra, tenga logo o
                // no -- antes el logo lo reemplazaba por completo, dejando
                // el recibo sin el nombre de la empresa en texto.
                Text(
                  nombreEmpresa,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gestión de préstamos y cobranza',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                if (telefono != null && telefono!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Tel: ${telefono!.trim()}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (rncCedula != null && rncCedula!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'RNC/Cédula: ${rncCedula!.trim()}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const _DashedDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 4),
            child: Column(
              children: [
                _Fila(label: 'Folio', value: resultado.folio ?? '-'),
                _Fila(
                  label: 'Fecha',
                  value: Formatters.dateTime(resultado.fecha),
                ),
                _Fila(
                  label: 'Cliente',
                  value: resultado.clienteNombre ?? '-',
                ),
                _Fila(
                  label: 'Método de pago',
                  value: resultado.metodo?.label ?? '-',
                ),
                if (resultado.referencia != null &&
                    resultado.referencia!.isNotEmpty)
                  _Fila(
                    label: 'Referencia',
                    value: resultado.referencia!,
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Divider(height: AppSpacing.xxl),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, 4),
            child: Column(
              children: [
                _Fila(
                  label: 'Monto pagado',
                  value: Formatters.currency(
                    resultado.montoTransaccion ?? resultado.montoPagado,
                  ),
                  destacado: true,
                ),
                _Fila(
                  label: 'Mora cubierta',
                  value: Formatters.currency(resultado.mora),
                ),
                _Fila(
                  label: 'Estado de la cuota',
                  value: resultado.estadoFactura,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _CodigoBarras(seed: resultado.folio ?? resultado.clienteNombre ?? 'KOVRA'),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.label,
    required this.value,
    this.destacado = false,
  });

  final String label;
  final String value;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: destacado ? 16 : 14,
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
              color: destacado ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea punteada que simula el corte perforado de un recibo térmico.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                child: Container(
                  width: dashWidth,
                  height: 1,
                  color: AppColors.neutralLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Código de barras puramente decorativo (no escaneable): las alturas de
/// las barras se derivan de [seed] para que cada recibo se vea distinto
/// pero reproducible, reforzando la sensación de comprobante impreso.
class _CodigoBarras extends StatelessWidget {
  const _CodigoBarras({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final codes = seed.codeUnits.isEmpty ? [75, 79, 86, 82, 65] : seed.codeUnits;
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(36, (i) {
              final c = codes[i % codes.length];
              final width = 1.0 + (c % 3);
              final tall = c % 5 != 0;
              return Container(
                width: width,
                height: tall ? 46 : 30,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: AppColors.primaryDark,
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (seed).toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}
