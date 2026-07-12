import 'package:dio/dio.dart';
import '../../domain/models/deuda_credito.dart';

/// Repositorio de "Data Crédito" (buró de crédito interno cross-tenant).
class CreditoRepository {
  CreditoRepository(this._dio);

  final Dio _dio;

  Future<List<DeudaCredito>> buscarPorCedula(String cedula) async {
    final response = await _dio.get(
      '/credito/buscar',
      queryParameters: {'cedula': cedula},
    );
    if (response.statusCode != 200) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ?? 'No se pudo consultar la cédula.')
          : 'No se pudo consultar la cédula.';
      throw CreditoException(detail);
    }
    final data = response.data;
    final list = (data is List) ? data : const [];
    return list
        .map((e) => DeudaCredito.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class CreditoException implements Exception {
  CreditoException(this.message);
  final String message;

  @override
  String toString() => message;
}
