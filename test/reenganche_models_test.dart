// Tests de contrato: verifican que los modelos Dart del flujo de
// reenganche (`POST /prestamos`, `POST /prestamos/{id}/aprobar`,
// `GET /prestamos/{id}`) parsean exactamente los nombres de campo
// documentados en Kovra_API/NOTES_REENGANCHE.md, secciones 2, 4 y 5. Si
// alguien cambia un nombre de campo en el backend o en el modelo Dart sin
// actualizar el otro lado, estos tests deben fallar.
import 'package:flutter_test/flutter_test.dart';
import 'package:kovra_mobile/domain/models/prestamo.dart';

void main() {
  group('PrestamoCreado.fromJson (POST /prestamos)', () {
    test('reenganche: parsea es_reenganche/prestamo_origen_id/motivo_reenganche', () {
      final json = {
        'id': 88,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'monto': 25000.0,
        'tasa_interes': 5.0,
        'plazo_meses': 12,
        'cuota': 2291.67,
        'estado': 'pendiente',
        'fecha_solicitud': '2026-07-09',
        'fecha_inicio_prestamo': '2026-07-09',
        'fecha_inicio_pago': '2026-08-09',
        'tipo_prestamo': 'Simple - insoluto',
        'frecuencia_tasa': 'mensual',
        'es_reenganche': true,
        'prestamo_origen_id': 87,
        'motivo_reenganche':
            'Cliente al día, solicita ampliar monto para nuevo negocio.',
      };

      final creado = PrestamoCreado.fromJson(json);

      expect(creado.esReenganche, isTrue);
      expect(creado.prestamoOrigenId, 87);
      expect(
        creado.motivoReenganche,
        'Cliente al día, solicita ampliar monto para nuevo negocio.',
      );
    });

    test('normal (sin reenganche): es_reenganche false y campos de origen null', () {
      final json = {
        'id': 89,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'monto': 5000.0,
        'tasa_interes': 5.0,
        'plazo_meses': 3,
        'cuota': 1750.0,
        'estado': 'pendiente',
        'fecha_solicitud': '2026-07-09',
        'fecha_inicio_prestamo': '2026-07-09',
        'fecha_inicio_pago': '2026-08-09',
        'tipo_prestamo': 'Simple - insoluto',
        'frecuencia_tasa': 'mensual',
        'es_reenganche': false,
        'prestamo_origen_id': null,
        'motivo_reenganche': null,
      };

      final creado = PrestamoCreado.fromJson(json);

      expect(creado.esReenganche, isFalse);
      expect(creado.prestamoOrigenId, isNull);
      expect(creado.motivoReenganche, isNull);
    });
  });

  group('PrestamoAprobado.fromJson (POST /prestamos/{id}/aprobar)', () {
    test('reenganche: parsea facturas_saldadas_prestamo_anterior', () {
      final json = {
        'id': 88,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'estado': 'aprobado',
        'fecha_aprobacion': '2026-07-09',
        'cuota': 2291.67,
        'cantidad_facturas_generadas': 12,
        'puntuacion_cliente': 80,
        'es_reenganche': true,
        'prestamo_origen_id': 87,
        'facturas_saldadas_prestamo_anterior': 5,
      };

      final aprobado = PrestamoAprobado.fromJson(json);

      expect(aprobado.esReenganche, isTrue);
      expect(aprobado.prestamoOrigenId, 87);
      expect(aprobado.facturasSaldadasPrestamoAnterior, 5);
    });

    test('idempotencia: si el préstamo viejo ya estaba pagado, el valor es 0 (no null)', () {
      final json = {
        'id': 90,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'estado': 'aprobado',
        'fecha_aprobacion': '2026-07-09',
        'cuota': 2291.67,
        'cantidad_facturas_generadas': 12,
        'puntuacion_cliente': 80,
        'es_reenganche': true,
        'prestamo_origen_id': 87,
        'facturas_saldadas_prestamo_anterior': 0,
      };

      final aprobado = PrestamoAprobado.fromJson(json);

      expect(aprobado.facturasSaldadasPrestamoAnterior, 0);
      expect(aprobado.facturasSaldadasPrestamoAnterior, isNot(isNull));
    });

    test('normal (sin reenganche): facturas_saldadas_prestamo_anterior llega null', () {
      final json = {
        'id': 91,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'estado': 'aprobado',
        'fecha_aprobacion': '2026-07-09',
        'cuota': 1000.0,
        'cantidad_facturas_generadas': 3,
        'puntuacion_cliente': 80,
        'es_reenganche': false,
        'prestamo_origen_id': null,
        'facturas_saldadas_prestamo_anterior': null,
      };

      final aprobado = PrestamoAprobado.fromJson(json);

      expect(aprobado.esReenganche, isFalse);
      expect(aprobado.facturasSaldadasPrestamoAnterior, isNull);
    });
  });

  group('Prestamo.fromJson (GET /prestamos/{id})', () {
    test('préstamo viejo ya reenganchado: reenganchado_por_prestamo_id apunta al nuevo', () {
      final json = {
        'id': 87,
        'monto': 20000.0,
        'tasa_interes': 5.0,
        'plazo_meses': 12,
        'estado': 'pagado',
        'cuota': 1833.33,
        'facturas': <Map<String, dynamic>>[],
        'prestamo_origen_id': null,
        'motivo_reenganche': null,
        'reenganchado_por_prestamo_id': 88,
      };

      final prestamo = Prestamo.fromJson(json);

      expect(prestamo.reenganchadoPorPrestamoId, 88);
      expect(prestamo.prestamoOrigenId, isNull);
    });

    test('préstamo nuevo de reenganche: trae prestamo_origen_id y motivo_reenganche propios', () {
      final json = {
        'id': 88,
        'monto': 25000.0,
        'tasa_interes': 5.0,
        'plazo_meses': 12,
        'estado': 'aprobado',
        'cuota': 2291.67,
        'facturas': <Map<String, dynamic>>[],
        'prestamo_origen_id': 87,
        'motivo_reenganche': 'Motivo de prueba',
        'reenganchado_por_prestamo_id': null,
      };

      final prestamo = Prestamo.fromJson(json);

      expect(prestamo.prestamoOrigenId, 87);
      expect(prestamo.motivoReenganche, 'Motivo de prueba');
      expect(prestamo.reenganchadoPorPrestamoId, isNull);
    });

    test('préstamo normal sin ningún vínculo de reenganche: los 3 campos llegan null', () {
      final json = {
        'id': 200,
        'monto': 5000.0,
        'tasa_interes': 5.0,
        'plazo_meses': 3,
        'estado': 'aprobado',
        'cuota': 1750.0,
        'facturas': <Map<String, dynamic>>[],
        'prestamo_origen_id': null,
        'motivo_reenganche': null,
        'reenganchado_por_prestamo_id': null,
      };

      final prestamo = Prestamo.fromJson(json);

      expect(prestamo.prestamoOrigenId, isNull);
      expect(prestamo.motivoReenganche, isNull);
      expect(prestamo.reenganchadoPorPrestamoId, isNull);
    });
  });
}
