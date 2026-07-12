// Tests de contrato: verifican que el modelo Dart de `GET /prestamos/buscar`
// cross-tenant ("Datapréstamo") parsea exactamente los nombres de campo que
// devuelve Kovra_API/app/routers/prestamos_router.py::buscar_prestamos,
// incluida la puntuación de pago global consolidada por cédula.
import 'package:flutter_test/flutter_test.dart';
import 'package:kovra_mobile/domain/models/prestamo_busqueda_cross_tenant.dart';

void main() {
  group('PrestamoBusquedaItem.fromJson (GET /prestamos/buscar cross-tenant)', () {
    test('parsea todos los campos del contrato con los nombres exactos', () {
      final json = {
        'empresa': 'Financiera Ejemplo',
        'es_mi_empresa': false,
        'id': 55,
        'cliente_id': 12,
        'cliente_nombre': 'Juan Pérez',
        'cedula': '001-1234567-8',
        'telefono': '809-555-0000',
        'email': 'juan@example.com',
        'frecuencia': 'mensual',
        'estado': 'aprobado',
        'categoria_severidad': 'vencido',
        'capital': 25000.0,
        'restante': 18500.0,
        'monto_pagado_acumulado': 8000.0,
        'dias_atraso': 45,
        'puntuacion_global': 62,
        'cuotas_vencidas_totales_cliente': 3,
      };

      final item = PrestamoBusquedaItem.fromJson(json);

      expect(item.empresa, 'Financiera Ejemplo');
      expect(item.esMiEmpresa, isFalse);
      expect(item.id, 55);
      expect(item.clienteId, 12);
      expect(item.clienteNombre, 'Juan Pérez');
      expect(item.cedula, '001-1234567-8');
      expect(item.telefono, '809-555-0000');
      expect(item.email, 'juan@example.com');
      expect(item.frecuencia, 'mensual');
      expect(item.estado, 'aprobado');
      expect(item.categoriaSeveridad, 'vencido');
      expect(item.capital, 25000.0);
      expect(item.restante, 18500.0);
      expect(item.montoPagadoAcumulado, 8000.0);
      expect(item.diasAtraso, 45);
      expect(item.puntuacionGlobal, 62);
      expect(item.cuotasVencidasTotalesCliente, 3);
    });

    test('telefono/email null no revienta el parseo', () {
      final item = PrestamoBusquedaItem.fromJson({
        'empresa': 'Mi Empresa',
        'es_mi_empresa': true,
        'id': 1,
        'cliente_id': 1,
        'cliente_nombre': 'X',
        'cedula': '001-0000000-1',
        'telefono': null,
        'email': null,
        'frecuencia': 'mensual',
        'estado': 'pendiente',
        'categoria_severidad': 'pendiente',
        'capital': 100.0,
        'restante': 100.0,
        'monto_pagado_acumulado': 0.0,
        'dias_atraso': 0,
        'puntuacion_global': 50,
        'cuotas_vencidas_totales_cliente': 0,
      });
      expect(item.telefono, isNull);
      expect(item.email, isNull);
      expect(item.esMiEmpresa, isTrue);
    });

    test(
        'BusquedaPrestamoCrossTenantOut: la misma cédula en dos empresas '
        'comparte puntuacion_global', () {
      final out = BusquedaPrestamoCrossTenantOut.fromJson({
        'items': [
          {
            'empresa': 'Empresa A',
            'es_mi_empresa': true,
            'id': 1,
            'cliente_id': 1,
            'cliente_nombre': 'Ana Ruiz',
            'cedula': '001-1111111-1',
            'telefono': null,
            'email': null,
            'frecuencia': 'mensual',
            'estado': 'aprobado',
            'categoria_severidad': 'a_tiempo',
            'capital': 1000.0,
            'restante': 500.0,
            'monto_pagado_acumulado': 500.0,
            'dias_atraso': 0,
            'puntuacion_global': 45,
            'cuotas_vencidas_totales_cliente': 2,
          },
          {
            'empresa': 'Empresa B',
            'es_mi_empresa': false,
            'id': 2,
            'cliente_id': 9,
            'cliente_nombre': 'Ana Ruiz',
            'cedula': '001-1111111-1',
            'telefono': '809-555-1111',
            'email': null,
            'frecuencia': 'mensual',
            'estado': 'aprobado',
            'categoria_severidad': 'atrasado',
            'capital': 2000.0,
            'restante': 1800.0,
            'monto_pagado_acumulado': 200.0,
            'dias_atraso': 10,
            'puntuacion_global': 45,
            'cuotas_vencidas_totales_cliente': 2,
          },
        ],
      });

      expect(out.items, hasLength(2));
      expect(out.items[0].puntuacionGlobal, out.items[1].puntuacionGlobal);
      expect(out.items[0].esMiEmpresa, isTrue);
      expect(out.items[1].esMiEmpresa, isFalse);
      expect(out.items[1].empresa, 'Empresa B');
    });
  });
}
