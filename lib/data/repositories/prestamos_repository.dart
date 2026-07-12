import 'package:dio/dio.dart';
import '../../domain/models/prestamo.dart';
import '../../domain/models/prestamo_busqueda_cross_tenant.dart';
import '../../domain/models/prestamo_cartera.dart';

/// Repositorio de préstamos: detalle (`GET /prestamos/{id}`), cartera
/// (`GET /prestamos/cartera`) y el flujo de solicitud/aprobación/rechazo
/// (NOTES_PRESTAMOS.md, sección 5).
class PrestamosRepository {
  PrestamosRepository(this._dio);

  final Dio _dio;

  Future<Prestamo> obtenerDetalle(int id) async {
    final response = await _dio.get('/prestamos/$id');
    _ensureOk(response);
    return Prestamo.fromJson(response.data as Map<String, dynamic>, id: id);
  }

  /// `GET /prestamos/cartera` — listado de préstamos en gestión
  /// (`pendiente`/`aprobado`/`en_acuerdo`/`incobrable`) con severidad y
  /// totales de cabecera. Ver `Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md`,
  /// sección 1.
  Future<PrestamosCarteraOut> obtenerCartera() async {
    final response = await _dio.get('/prestamos/cartera');
    _ensureOk(response);
    return PrestamosCarteraOut.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /prestamos/buscar?q=...` — buscador puntual ("Datapréstamo") por
  /// cédula/nombre/número, CROSS-TENANT: recorre todas las empresas activas
  /// del sistema, no solo la propia. A diferencia de [obtenerCartera], no
  /// filtra por estado: también encuentra préstamos ya `pagado`/`rechazado`.
  Future<BusquedaPrestamoCrossTenantOut> buscar(String query) async {
    final response = await _dio.get(
      '/prestamos/buscar',
      queryParameters: {'q': query},
    );
    _ensureOk(response);
    return BusquedaPrestamoCrossTenantOut.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /prestamos` — crea la solicitud en estado `pendiente`.
  /// `fechaInicioPago` debe venir en formato ISO `"YYYY-MM-DD"`.
  ///
  /// `prestamoOrigenId` y `motivoReenganche` son opcionales: se incluyen en
  /// el body solo cuando la solicitud es un reenganche
  /// (NOTES_REENGANCHE.md, sección 2).
  Future<PrestamoCreado> solicitar({
    required int clienteId,
    required double monto,
    required double tasaInteres,
    required int plazoMeses,
    required String fechaInicioPago,
    int? prestamoOrigenId,
    String? motivoReenganche,
    String? tipoAmortizacion,
    String? frecuenciaTasa,
    String? fechaInicioPrestamo,
  }) async {
    final response = await _dio.post(
      '/prestamos',
      data: {
        'cliente_id': clienteId,
        'monto': monto,
        'tasa_interes': tasaInteres,
        'plazo_meses': plazoMeses,
        'fecha_inicio_pago': fechaInicioPago,
        if (prestamoOrigenId != null) 'prestamo_origen_id': prestamoOrigenId,
        if (motivoReenganche != null) 'motivo_reenganche': motivoReenganche,
        if (tipoAmortizacion != null) 'tipo_amortizacion': tipoAmortizacion,
        if (frecuenciaTasa != null) 'frecuencia_tasa': frecuenciaTasa,
        if (fechaInicioPrestamo != null)
          'fecha_inicio_prestamo': fechaInicioPrestamo,
      },
    );
    _ensureOk(response, expectedCodes: const [200, 201]);
    return PrestamoCreado.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /prestamos?estado=...` — listado de solicitudes. Por defecto trae
  /// solo las `pendiente` (uso principal: pantalla de aprobación).
  Future<List<SolicitudPrestamo>> listarPendientes({
    String estado = 'pendiente',
  }) async {
    final response = await _dio.get(
      '/prestamos',
      queryParameters: {'estado': estado},
    );
    _ensureOk(response);
    final data = response.data;
    final list = (data is List) ? data : const [];
    return list
        .map((e) => SolicitudPrestamo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /prestamos/{id}/aprobar`.
  Future<PrestamoAprobado> aprobar(int prestamoId) async {
    final response = await _dio.post('/prestamos/$prestamoId/aprobar');
    _ensureOk(response);
    return PrestamoAprobado.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /prestamos/{id}/rechazar`.
  Future<PrestamoRechazado> rechazar(int prestamoId) async {
    final response = await _dio.post('/prestamos/$prestamoId/rechazar');
    _ensureOk(response);
    return PrestamoRechazado.fromJson(response.data as Map<String, dynamic>);
  }

  void _ensureOk(Response response, {List<int> expectedCodes = const [200]}) {
    if (response.statusCode == null ||
        !expectedCodes.contains(response.statusCode)) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ??
              'Ocurrió un error al procesar la solicitud.')
          : 'Ocurrió un error al procesar la solicitud.';
      throw PrestamosException(detail);
    }
  }
}

class PrestamosException implements Exception {
  PrestamosException(this.message);
  final String message;

  @override
  String toString() => message;
}
