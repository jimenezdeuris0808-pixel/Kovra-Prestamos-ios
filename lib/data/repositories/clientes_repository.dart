import 'package:dio/dio.dart';
import '../../domain/models/cliente.dart';
import '../../domain/models/pago_historial_item.dart';

/// Repositorio de clientes: búsqueda, detalle y creación.
class ClientesRepository {
  ClientesRepository(this._dio);

  final Dio _dio;

  Future<List<Cliente>> buscar(String query) async {
    final response = await _dio.get(
      '/clientes',
      queryParameters: {'query': query},
    );
    _ensureOk(response);
    final data = response.data;
    final list = (data is List) ? data : (data['results'] as List? ?? []);
    return list
        .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cliente> obtenerDetalle(int id) async {
    final response = await _dio.get('/clientes/$id');
    _ensureOk(response);
    return Cliente.fromJson(response.data as Map<String, dynamic>);
  }

  /// Contadores de cabecera de la pantalla "Clientes" (`GET /clientes/resumen`).
  Future<ClientesResumen> obtenerResumen() async {
    final response = await _dio.get('/clientes/resumen');
    _ensureOk(response);
    return ClientesResumen.fromJson(response.data as Map<String, dynamic>);
  }

  /// Listado de clientes con préstamo activo embebido (`GET /clientes/cartera`),
  /// mismo criterio de búsqueda opcional que [buscar].
  Future<List<ClienteCarteraItem>> obtenerCartera({String? query}) async {
    final response = await _dio.get(
      '/clientes/cartera',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    _ensureOk(response);
    final data = response.data;
    final list = (data is List) ? data : (data['items'] as List? ?? []);
    return list
        .map((e) => ClienteCarteraItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Historial completo de pagos del cliente (`GET /clientes/{id}/pagos`),
  /// más reciente primero -- para reenviar/reimprimir el recibo de un cobro
  /// pasado desde la pantalla de detalle del cliente.
  Future<List<PagoHistorialItem>> obtenerHistorialPagos(int clienteId) async {
    final response = await _dio.get('/clientes/$clienteId/pagos');
    _ensureOk(response);
    final data = response.data;
    final list = (data is List) ? data : const [];
    return list
        .map((e) => PagoHistorialItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cliente> crear({
    required String cedula,
    required String nombre,
    required String apellido,
    String? telefono,
    String? email,
    String? direccion,
  }) async {
    final response = await _dio.post(
      '/clientes',
      data: {
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (email != null && email.isNotEmpty) 'email': email,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      },
    );
    _ensureOk(response, expectedCodes: const [200, 201]);
    return Cliente.fromJson(response.data as Map<String, dynamic>);
  }

  void _ensureOk(Response response, {List<int> expectedCodes = const [200]}) {
    if (response.statusCode == null || !expectedCodes.contains(response.statusCode)) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ?? 'Ocurrió un error al procesar la solicitud.')
          : 'Ocurrió un error al procesar la solicitud.';
      throw ClientesException(detail);
    }
  }
}

class ClientesException implements Exception {
  ClientesException(this.message);
  final String message;

  @override
  String toString() => message;
}
