import 'package:dio/dio.dart';
import '../../domain/models/cobros_hoy.dart';
import '../../domain/models/cobros_mes.dart';
import '../../domain/models/dashboard_resumen.dart';

/// Repositorio de dashboard: `GET /dashboard/resumen`,
/// `GET /dashboard/resumen_general` y `GET /dashboard/cobros_hoy`.
class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardResumen> obtenerResumen() async {
    final response = await _dio.get('/dashboard/resumen');
    if (response.statusCode != 200) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ?? 'No se pudo cargar el dashboard.')
          : 'No se pudo cargar el dashboard.';
      throw DashboardException(detail);
    }
    return DashboardResumen.fromJson(response.data as Map<String, dynamic>);
  }

  /// Snapshot ejecutivo de cartera para la sección de resumen denso del
  /// dashboard. Ver `Kovra_API/NOTES_DASHBOARD_RESUMEN.md`, sección 3.
  Future<DashboardResumenGeneral> obtenerResumenGeneral() async {
    final response = await _dio.get('/dashboard/resumen_general');
    if (response.statusCode != 200) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ??
              'No se pudo cargar el resumen de cartera.')
          : 'No se pudo cargar el resumen de cartera.';
      throw DashboardException(detail);
    }
    return DashboardResumenGeneral.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// `GET /dashboard/cobros_hoy` — cuotas atrasadas y pagos cobrados hoy,
  /// para la pantalla "Cobrar" del bottom nav. Ver
  /// `Kovra_API/NOTES_CARTERA_CLIENTES_COBROS.md`, sección 4.
  Future<DashboardCobrosHoy> obtenerCobrosHoy() async {
    final response = await _dio.get('/dashboard/cobros_hoy');
    if (response.statusCode != 200) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ??
              'No se pudo cargar los cobros de hoy.')
          : 'No se pudo cargar los cobros de hoy.';
      throw DashboardException(detail);
    }
    return DashboardCobrosHoy.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /dashboard/cobros_mes` — capital/interés/mora cobrados en el mes
  /// calendario en curso, para la tarjeta "Cobros del mes" del Inicio.
  Future<CobrosMes> obtenerCobrosMes() async {
    final response = await _dio.get('/dashboard/cobros_mes');
    if (response.statusCode != 200) {
      final data = response.data;
      final detail = (data is Map)
          ? (data['detail']?.toString() ??
              'No se pudo cargar los cobros del mes.')
          : 'No se pudo cargar los cobros del mes.';
      throw DashboardException(detail);
    }
    return CobrosMes.fromJson(response.data as Map<String, dynamic>);
  }
}

class DashboardException implements Exception {
  DashboardException(this.message);
  final String message;

  @override
  String toString() => message;
}
