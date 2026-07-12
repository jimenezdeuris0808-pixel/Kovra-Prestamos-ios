// Tests de contrato: verifican que los modelos Dart de
// `GET /prestamos/cartera`, `GET /clientes/resumen`, `GET /clientes/cartera`
// y `GET /dashboard/cobros_hoy` parsean exactamente los nombres de campo
// documentados en Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md. Si alguien
// cambia un nombre de campo en el backend o en el modelo Dart sin
// actualizar el otro lado, estos tests deben fallar.
import 'package:flutter_test/flutter_test.dart';
import 'package:kovra_mobile/domain/models/cliente.dart';
import 'package:kovra_mobile/domain/models/cobros_hoy.dart';
import 'package:kovra_mobile/domain/models/prestamo.dart';
import 'package:kovra_mobile/domain/models/prestamo_cartera.dart';

void main() {
  group('PrestamoCarteraItem.fromJson (GET /prestamos/cartera)', () {
    test('parsea todos los campos del contrato con los nombres exactos', () {
      final json = {
        'id': 101,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'frecuencia': 'mensual',
        'estado': 'aprobado',
        'categoria_severidad': 'vencido',
        'dias_atraso': 45,
        'proxima_cuota_fecha': '2026-06-09',
        'capital': 25000.0,
        'restante': 18500.0,
        'monto_pagado_acumulado': 8000.0,
      };

      final item = PrestamoCarteraItem.fromJson(json);

      expect(item.id, 101);
      expect(item.clienteId, 12);
      expect(item.clienteNombre, 'Juan Pérez');
      expect(item.frecuencia, 'mensual');
      expect(item.estado, 'aprobado');
      expect(item.categoriaSeveridad, 'vencido');
      expect(item.diasAtraso, 45);
      expect(item.proximaCuotaFecha, DateTime(2026, 6, 9));
      expect(item.capital, 25000.0);
      expect(item.restante, 18500.0);
      expect(item.montoPagadoAcumulado, 8000.0);
    });

    test('proxima_cuota_fecha null no revienta el parseo', () {
      final json = {
        'id': 1,
        'cliente_id': 1,
        'cliente_nombre': 'X',
        'frecuencia': 'mensual',
        'estado': 'pendiente',
        'categoria_severidad': 'pendiente',
        'dias_atraso': 0,
        'proxima_cuota_fecha': null,
        'capital': 100.0,
        'restante': 100.0,
        'monto_pagado_acumulado': 0.0,
      };
      final item = PrestamoCarteraItem.fromJson(json);
      expect(item.proximaCuotaFecha, isNull);
    });

    test('totales: porcentaje_cobrado y campos de CarteraTotales', () {
      final totales = CarteraTotales.fromJson({
        'total_financiado': 500000.0,
        'total_cobrado': 210000.0,
        'porcentaje_cobrado': 42.0,
      });
      expect(totales.totalFinanciado, 500000.0);
      expect(totales.totalCobrado, 210000.0);
      expect(totales.porcentajeCobrado, 42.0);
    });

    test('PrestamosCarteraOut combina items + totales', () {
      final out = PrestamosCarteraOut.fromJson({
        'items': [
          {
            'id': 1,
            'cliente_id': 1,
            'cliente_nombre': 'A',
            'frecuencia': 'mensual',
            'estado': 'incobrable',
            'categoria_severidad': 'incobrable',
            'dias_atraso': 0,
            'proxima_cuota_fecha': null,
            'capital': 1.0,
            'restante': 1.0,
            'monto_pagado_acumulado': 0.0,
          },
        ],
        'totales': {
          'total_financiado': 0.0,
          'total_cobrado': 0.0,
          'porcentaje_cobrado': 0.0,
        },
      });
      expect(out.items, hasLength(1));
      expect(out.items.single.estado, 'incobrable');
    });
  });

  group('ClientesResumen.fromJson (GET /clientes/resumen)', () {
    test('parsea los 4 contadores con los nombres exactos del contrato', () {
      final resumen = ClientesResumen.fromJson({
        'total_clientes': 92,
        'clientes_con_prestamo_activo': 74,
        'clientes_sin_prestamo_activo': 18,
        'clientes_con_contacto': 88,
      });
      expect(resumen.totalClientes, 92);
      expect(resumen.clientesConPrestamoActivo, 74);
      expect(resumen.clientesSinPrestamoActivo, 18);
      expect(resumen.clientesConContacto, 88);
    });
  });

  group('ClienteCarteraItem.fromJson (GET /clientes/cartera)', () {
    test(
        'sin prestamo activo: los 4 campos de prestamo llegan null en bloque',
        () {
      final item = ClienteCarteraItem.fromJson({
        'id': 1,
        'cedula': '001-0000000-1',
        'nombre': 'Ana',
        'apellido': 'Ruiz',
        'telefono': null,
        'email': null,
        'puntuacion': 50,
        'prestamo_activo_id': null,
        'cuotas_pagadas': null,
        'cuotas_totales': null,
        'monto_pendiente': null,
      });
      expect(item.tienePrestamoActivo, isFalse);
      expect(item.prestamoActivoId, isNull);
      expect(item.cuotasPagadas, isNull);
      expect(item.cuotasTotales, isNull);
      expect(item.montoPendiente, isNull);
    });

    test('con prestamo activo: campos poblados y cuotasPagadas <= cuotasTotales',
        () {
      final item = ClienteCarteraItem.fromJson({
        'id': 2,
        'cedula': '001-0000000-2',
        'nombre': 'Luis',
        'apellido': 'Gómez',
        'telefono': '809-555-0000',
        'email': 'luis@example.com',
        'puntuacion': 80,
        'prestamo_activo_id': 55,
        'cuotas_pagadas': 3,
        'cuotas_totales': 12,
        'monto_pendiente': 4200.5,
      });
      expect(item.tienePrestamoActivo, isTrue);
      expect(item.prestamoActivoId, 55);
      expect(item.cuotasPagadas, lessThanOrEqualTo(item.cuotasTotales!));
      expect(item.montoPendiente, 4200.5);
    });
  });

  group('DashboardCobrosHoy.fromJson (GET /dashboard/cobros_hoy)', () {
    test('parsea atrasadas y cobradas_hoy con los nombres exactos', () {
      final out = DashboardCobrosHoy.fromJson({
        'atrasadas': [
          {
            'factura_id': 501,
            'prestamo_id': 101,
            'cliente_id': 12,
            'cliente_nombre': 'Juan Pérez',
            'fecha_vencimiento': '2026-06-09',
            'monto_cuota': 3333.33,
            'monto_pagado': 0,
            'mora_calculada': 166.67,
            'pendiente_total': 3500.0,
          },
        ],
        'cobradas_hoy': [
          {
            'pago_id': 900,
            'factura_id': 495,
            'prestamo_id': 98,
            'cliente_id': 7,
            'cliente_nombre': 'María Gómez',
            'monto': 3200.0,
            'fecha_pago': '2026-07-09',
            'fecha_vencimiento': '2026-07-05',
            'metodo': 'efectivo',
          },
        ],
        'total_pendiente': 45200.0,
        'total_cobrado_hoy': 12500.0,
      });

      expect(out.atrasadas, hasLength(1));
      expect(out.atrasadas.single.id, 501); // fallback factura_id -> id
      expect(out.atrasadas.single.mora, 166.67); // fallback mora_calculada
      expect(out.atrasadas.single.prestamoId, 101);

      expect(out.cobradasHoy, hasLength(1));
      final cobro = out.cobradasHoy.single;
      expect(cobro.pagoId, 900);
      expect(cobro.facturaId, 495);
      expect(cobro.prestamoId, 98);
      expect(cobro.clienteId, 7);
      expect(cobro.clienteNombre, 'María Gómez');
      expect(cobro.monto, 3200.0);
      expect(cobro.fechaPago, DateTime(2026, 7, 9));
      expect(cobro.fechaVencimiento, DateTime(2026, 7, 5));
      expect(cobro.metodo, 'efectivo');

      expect(out.totalPendiente, 45200.0);
      expect(out.totalCobradoHoy, 12500.0);
    });

    test('cobradas_hoy vacio no revienta y totales quedan en 0', () {
      final out = DashboardCobrosHoy.fromJson({
        'atrasadas': [],
        'cobradas_hoy': [],
        'total_pendiente': 0.0,
        'total_cobrado_hoy': 0.0,
      });
      expect(out.atrasadas, isEmpty);
      expect(out.cobradasHoy, isEmpty);
      expect(out.totalPendiente, 0.0);
      expect(out.totalCobradoHoy, 0.0);
    });
  });

  group('EstadoPrestamo.incobrable (prestamo.dart)', () {
    test("'incobrable' no cae en desconocido", () {
      expect(estadoPrestamoFromString('incobrable'), EstadoPrestamo.incobrable);
      expect(estadoPrestamoFromString('incobrable'),
          isNot(EstadoPrestamo.desconocido));
    });

    test('un estado realmente desconocido sigue cayendo en desconocido', () {
      expect(estadoPrestamoFromString('estado_inventado'),
          EstadoPrestamo.desconocido);
    });
  });
}
