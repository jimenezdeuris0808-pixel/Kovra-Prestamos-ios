import 'prestamo.dart';

/// Modelo de cliente, tal como lo devuelve `GET /clientes` y
/// `GET /clientes/{id}` (este último incluye además la lista de préstamos).
class Cliente {
  const Cliente({
    required this.id,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.direccion,
    this.puntuacion,
    this.prestamos,
  });

  final int id;
  final String cedula;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String? direccion;
  final int? puntuacion;
  final List<Prestamo>? prestamos;

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      cedula: json['cedula']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      puntuacion: json['puntuacion'] is int
          ? json['puntuacion'] as int
          : int.tryParse(json['puntuacion']?.toString() ?? ''),
      prestamos: json['prestamos'] != null
          ? (json['prestamos'] as List)
              .map((e) => Prestamo.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// Contadores de cabecera de la pantalla "Clientes", tal como los devuelve
/// `GET /clientes/resumen` (NOTES_CARTERA_CLIENTES_COBROS.md, sección 2).
class ClientesResumen {
  const ClientesResumen({
    required this.totalClientes,
    required this.clientesConPrestamoActivo,
    required this.clientesSinPrestamoActivo,
    required this.clientesConContacto,
  });

  final int totalClientes;
  final int clientesConPrestamoActivo;
  final int clientesSinPrestamoActivo;
  final int clientesConContacto;

  factory ClientesResumen.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic raw) => (raw as num?)?.toInt() ?? 0;
    return ClientesResumen(
      totalClientes: asInt(json['total_clientes']),
      clientesConPrestamoActivo: asInt(json['clientes_con_prestamo_activo']),
      clientesSinPrestamoActivo: asInt(json['clientes_sin_prestamo_activo']),
      clientesConContacto: asInt(json['clientes_con_contacto']),
    );
  }
}

/// Ítem de listado de `GET /clientes/cartera`: datos base del cliente más el
/// préstamo activo más reciente embebido (si tiene). Los 4 campos de
/// préstamo (`prestamoActivoId`, `cuotasPagadas`, `cuotasTotales`,
/// `montoPendiente`) son `null` en bloque cuando el cliente no tiene
/// préstamo activo (NOTES_CARTERA_CLIENTES_COBROS.md, sección 3.2).
class ClienteCarteraItem {
  const ClienteCarteraItem({
    required this.id,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    this.telefono,
    this.email,
    this.puntuacion,
    this.prestamoActivoId,
    this.cuotasPagadas,
    this.cuotasTotales,
    this.montoPendiente,
  });

  final int id;
  final String cedula;
  final String nombre;
  final String apellido;
  final String? telefono;
  final String? email;
  final int? puntuacion;
  final int? prestamoActivoId;
  final int? cuotasPagadas;
  final int? cuotasTotales;
  final double? montoPendiente;

  String get nombreCompleto => '$nombre $apellido'.trim();

  bool get tienePrestamoActivo => prestamoActivoId != null;

  factory ClienteCarteraItem.fromJson(Map<String, dynamic> json) {
    return ClienteCarteraItem(
      id: json['id'] as int,
      cedula: json['cedula']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      puntuacion: json['puntuacion'] is int
          ? json['puntuacion'] as int
          : int.tryParse(json['puntuacion']?.toString() ?? ''),
      prestamoActivoId: json['prestamo_activo_id'] as int?,
      cuotasPagadas: json['cuotas_pagadas'] as int?,
      cuotasTotales: json['cuotas_totales'] as int?,
      montoPendiente: (json['monto_pendiente'] as num?)?.toDouble(),
    );
  }
}
