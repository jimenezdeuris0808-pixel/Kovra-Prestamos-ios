/// Resultado de `GET /credito/buscar` ("Data Crédito"): deuda activa de
/// una cédula en UNA empresa del sistema (puede haber varios resultados,
/// uno por cada empresa donde tenga deuda). Ver
/// `Kovra_API/app/routers/credito_router.py`.
class DeudaCredito {
  const DeudaCredito({
    required this.empresa,
    required this.esMiEmpresa,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.clienteNombre,
    this.telefono,
    this.email,
    this.direccion,
    required this.saldoPendiente,
    required this.cantidadPrestamos,
    required this.estado,
    this.fechaDesde,
    required this.cuotasVencidas,
  });

  final String empresa;
  final bool esMiEmpresa;
  final String cedula;
  final String nombre;
  final String apellido;
  final String clienteNombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final double saldoPendiente;
  final int cantidadPrestamos;
  final String estado;
  final String? fechaDesde;
  final int cuotasVencidas;

  factory DeudaCredito.fromJson(Map<String, dynamic> json) {
    return DeudaCredito(
      empresa: json['empresa']?.toString() ?? '',
      esMiEmpresa: json['es_mi_empresa'] as bool? ?? false,
      cedula: json['cedula']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      direccion: json['direccion']?.toString(),
      saldoPendiente: (json['saldo_pendiente'] as num?)?.toDouble() ?? 0,
      cantidadPrestamos: json['cantidad_prestamos'] as int? ?? 0,
      estado: json['estado']?.toString() ?? '',
      fechaDesde: json['fecha_desde']?.toString(),
      cuotasVencidas: json['cuotas_vencidas'] as int? ?? 0,
    );
  }
}
