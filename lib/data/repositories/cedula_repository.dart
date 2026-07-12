import 'package:dio/dio.dart';
import '../../domain/models/cedula_info.dart';

/// Repositorio de autocompletado por cédula: `GET /cedula/{numero}`.
class CedulaRepository {
  CedulaRepository(this._dio);

  final Dio _dio;

  /// Devuelve `null` si la cédula no está registrada en el sistema
  /// (el endpoint responde null / 404 en ese caso).
  Future<CedulaInfo?> buscar(String numero) async {
    final response = await _dio.get('/cedula/$numero');

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;

    final data = response.data;
    if (data == null || (data is Map && data.isEmpty)) return null;

    return CedulaInfo.fromJson(data as Map<String, dynamic>);
  }
}
