import 'package:dio/dio.dart';
import '../../domain/models/pago.dart';

/// Repositorio de pagos: `POST /pagos`.
class PagosRepository {
  PagosRepository(this._dio);

  final Dio _dio;

  Future<PagoResultado> registrarPago({
    required int facturaId,
    required double monto,
    required MetodoPago metodo,
    String? referencia,
  }) async {
    final response = await _dio.post(
      '/pagos',
      data: {
        'factura_id': facturaId,
        'monto': monto,
        'metodo': metodo.apiValue,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ?? 'No se pudo registrar el pago.')
          : 'No se pudo registrar el pago.';
      throw PagosException(detail);
    }

    return PagoResultado.fromJson(response.data as Map<String, dynamic>);
  }
}

class PagosException implements Exception {
  PagosException(this.message);
  final String message;

  @override
  String toString() => message;
}
