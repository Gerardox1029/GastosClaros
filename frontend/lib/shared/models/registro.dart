/// Modelo de datos para un registro de ingreso o gasto.
class Registro {
  final String? id;
  final double monto;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final String tipoRegistro;

  const Registro({
    this.id,
    required this.monto,
    this.nombre = '',
    required this.descripcion,
    required this.fecha,
    this.tipoRegistro = 'manual',
  });

  factory Registro.fromJson(Map<String, dynamic> json) {
    return Registro(
      id: json['_id'] as String?,
      monto: (json['monto'] as num).toDouble(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fecha: DateTime.parse(json['fecha'] as String),
      tipoRegistro: json['tipo_registro'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monto': monto,
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
    };
  }

  /// Retorna el nombre truncado a [maxLength] caracteres.
  String get nombreTruncado {
    if (nombre.length <= 10) return nombre;
    return '${nombre.substring(0, 10)}...';
  }

  /// Retorna la descripción truncada a [maxLength] caracteres.
  String get descripcionTruncada {
    if (descripcion.length <= 10) return descripcion;
    return '${descripcion.substring(0, 10)}...';
  }
}
