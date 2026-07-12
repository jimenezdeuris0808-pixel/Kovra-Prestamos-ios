/// Resultado de `GET /cedula/{numero}` usado para autocompletar el
/// formulario de registro de cliente nuevo.
class CedulaInfo {
  const CedulaInfo({
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.direccion,
  });

  final String nombre;
  final String apellido;
  final String? telefono;
  final String? direccion;

  factory CedulaInfo.fromJson(Map<String, dynamic> json) {
    return CedulaInfo(
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
    );
  }
}
