/// Resultado de la extracción IA de una captura Yape.
class YapeExtractionResult {
  final String nombre;
  final double monto;
  final String descripcion;
  final DateTime fecha;
  final bool saved;
  final String? id;
  final String? error;
  final int captureIndex;

  const YapeExtractionResult({
    required this.nombre,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.saved,
    this.id,
    this.error,
    required this.captureIndex,
  });

  factory YapeExtractionResult.fromJson(Map<String, dynamic> json) {
    return YapeExtractionResult(
      nombre: json['nombre'] as String? ?? '',
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'] as String? ?? '',
      fecha: DateTime.parse(json['fecha'] as String),
      saved: json['saved'] as bool? ?? false,
      id: json['id'] as String?,
      error: json['error'] as String?,
      captureIndex: json['captureIndex'] as int? ?? 0,
    );
  }
}
