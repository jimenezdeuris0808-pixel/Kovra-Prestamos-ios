import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../domain/models/pago.dart';
import '../providers/core_providers.dart';
import '../storage/secure_storage_service.dart';
import '../utils/formatters.dart';

/// Impresora Bluetooth emparejada, tal como la reporta el sistema operativo
/// (nombre visible + dirección MAC, usada para conectar).
class ImpresoraBluetooth {
  const ImpresoraBluetooth({required this.nombre, required this.mac});

  final String nombre;
  final String mac;
}

/// Impresión de recibos en impresoras térmicas ESC/POS conectadas por
/// Bluetooth (Android e iOS). Usa `print_bluetooth_thermal` para el
/// transporte (listar emparejadas, conectar, enviar bytes) y
/// `esc_pos_utils_plus` (puro Dart, sin código nativo) para generar el
/// comando ESC/POS del recibo.
class ReceiptPrinterService {
  ReceiptPrinterService(this._storage);

  final SecureStorageService _storage;

  Future<bool> bluetoothHabilitado() => PrintBluetoothThermal.bluetoothEnabled;

  /// Impresoras YA emparejadas desde los ajustes de Bluetooth del sistema.
  /// Emparejar una impresora nueva se hace fuera de la app (ajustes del
  /// sistema operativo): esta lista solo muestra lo que el SO ya conoce.
  Future<List<ImpresoraBluetooth>> listarImpresorasEmparejadas() async {
    final dispositivos = await PrintBluetoothThermal.pairedBluetooths;
    return dispositivos
        .map((d) => ImpresoraBluetooth(nombre: d.name, mac: d.macAdress))
        .toList();
  }

  Future<String?> leerImpresoraGuardada() => _storage.readPrinterMac();

  Future<void> guardarImpresora(String mac) => _storage.savePrinterMac(mac);

  Future<void> olvidarImpresoraGuardada() => _storage.clearPrinterMac();

  /// Conecta (si hace falta) a [macAddress] e imprime el recibo. Devuelve
  /// `null` si todo salió bien, o un mensaje corto y legible para mostrar
  /// al usuario si algo falló (Bluetooth apagado, impresora fuera de
  /// alcance/apagada, etc.) -- nunca lanza una excepción sin capturar.
  Future<String?> imprimirRecibo({
    required String macAddress,
    required PagoResultado resultado,
    required String nombreEmpresa,
  }) async {
    try {
      if (!await bluetoothHabilitado()) {
        return 'Activa el Bluetooth del celular para poder imprimir.';
      }

      final yaConectado = await PrintBluetoothThermal.connectionStatus;
      if (!yaConectado) {
        final conectado = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
        if (!conectado) {
          return 'No se pudo conectar a la impresora.';
        }
      }

      final bytes = await _generarBytesRecibo(resultado, nombreEmpresa);
      final impreso = await PrintBluetoothThermal.writeBytes(bytes);
      if (!impreso) {
        return 'La impresora no respondió al enviar el recibo.';
      }
      await guardarImpresora(macAddress);
      return null;
    } catch (e) {
      return 'Error al imprimir: $e';
    }
  }

  Future<List<int>> _generarBytesRecibo(
    PagoResultado resultado,
    String nombreEmpresa,
  ) async {
    final profile = await CapabilityProfile.load();
    // mm58: la mayoría de las impresoras térmicas portátiles de bolsillo
    // usadas en cobranza de campo son de rollo de 58mm, no 80mm de mostrador.
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      _sanitizar(nombreEmpresa),
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      'Gestion de prestamos y cobranza',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    bytes.addAll(_fila(generator, 'Folio', resultado.folio ?? '-'));
    bytes.addAll(_fila(generator, 'Fecha', Formatters.dateTime(resultado.fecha)));
    bytes.addAll(_fila(generator, 'Cliente', resultado.clienteNombre ?? '-'));
    bytes.addAll(_fila(generator, 'Metodo de pago', resultado.metodo?.label ?? '-'));
    if (resultado.referencia != null && resultado.referencia!.isNotEmpty) {
      bytes.addAll(_fila(generator, 'Referencia', resultado.referencia!));
    }
    bytes.addAll(generator.hr());

    bytes.addAll(_fila(
      generator,
      'Monto pagado',
      Formatters.currency(resultado.montoTransaccion ?? resultado.montoPagado),
      destacado: true,
    ));
    bytes.addAll(_fila(generator, 'Mora cubierta', Formatters.currency(resultado.mora)));
    bytes.addAll(_fila(generator, 'Estado de la cuota', resultado.estadoFactura));

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text(
      _sanitizar(resultado.folio ?? ''),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.cut());
    return bytes;
  }

  /// Reemplaza caracteres Unicode que el códec del generador ESC/POS no
  /// sabe codificar (ej. el espacio angosto U+202F que el locale español
  /// de `intl` mete entre la hora y "p. m." -- bug reportado en
  /// dispositivo real: "Invalid argument (string): Contains invalid
  /// characters"). Cualquier caracter fuera del rango Latin-1 (0-255, lo
  /// que soportan las tablas de codepage típicas de estas impresoras) se
  /// reemplaza por un espacio o "?" en vez de reventar la impresión
  /// completa por un solo caracter raro en un nombre o fecha.
  String _sanitizar(String texto) {
    return texto
        .replaceAll(' ', ' ')
        .replaceAll(' ', ' ')
        .runes
        .map((r) => r <= 0xFF ? String.fromCharCode(r) : '?')
        .join();
  }

  List<int> _fila(Generator generator, String label, String value, {bool destacado = false}) {
    return generator.row([
      PosColumn(
        text: _sanitizar(label),
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: _sanitizar(value),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: destacado),
      ),
    ]);
  }
}

final receiptPrinterServiceProvider = Provider<ReceiptPrinterService>((ref) {
  return ReceiptPrinterService(ref.watch(secureStorageProvider));
});
