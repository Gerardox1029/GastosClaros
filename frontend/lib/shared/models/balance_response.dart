/// Modelo de respuesta del endpoint /api/balance.
/// Soporta valores int y double desde JSON (Netlify puede devolver 0 como int).
class BalanceResponse {
  final double saldo;
  final double totalIngresos;
  final double totalGastos;
  final String filtro;

  const BalanceResponse({
    required this.saldo,
    required this.totalIngresos,
    required this.totalGastos,
    required this.filtro,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      saldo: _toDouble(json['saldo']),
      totalIngresos: _toDouble(json['total_ingresos']),
      totalGastos: _toDouble(json['total_gastos']),
      filtro: (json['filtro'] as String?) ?? '1M',
    );
  }

  /// Convierte de forma segura un valor JSON a double.
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Balance vacío por defecto.
  static const empty = BalanceResponse(
    saldo: 0,
    totalIngresos: 0,
    totalGastos: 0,
    filtro: '1M',
  );

  @override
  String toString() =>
      'BalanceResponse(saldo: $saldo, ingresos: $totalIngresos, gastos: $totalGastos)';
}
