/// Modelo de respuesta del endpoint /api/balance.
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
      saldo: (json['saldo'] as num).toDouble(),
      totalIngresos: (json['total_ingresos'] as num).toDouble(),
      totalGastos: (json['total_gastos'] as num).toDouble(),
      filtro: json['filtro'] as String? ?? '1M',
    );
  }

  /// Balance vacío por defecto.
  static const empty = BalanceResponse(
    saldo: 0,
    totalIngresos: 0,
    totalGastos: 0,
    filtro: '1M',
  );
}
