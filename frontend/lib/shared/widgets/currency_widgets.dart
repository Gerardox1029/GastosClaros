import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gastos_claros/core/theme.dart';

/// Formatea un monto en soles peruanos (S/.).
String formatMonto(double monto, {bool showSign = false}) {
  final formatter = NumberFormat('#,##0.00', 'es_PE');
  final formatted = formatter.format(monto.abs());
  if (monto < 0) return '-S/. $formatted';
  return showSign ? '+S/. $formatted' : 'S/. $formatted';
}

/// Formatea una fecha en formato dd/MM/yyyy.
String formatFecha(DateTime fecha) {
  return DateFormat('dd/MM/yyyy', 'es_PE').format(fecha);
}

/// Formatea una fecha con hora: dd/MM/yyyy HH:mm.
String formatFechaHora(DateTime fecha) {
  return DateFormat('dd/MM/yyyy HH:mm', 'es_PE').format(fecha);
}

/// Widget que muestra un monto con color semántico (verde/rojo).
class MontoText extends StatelessWidget {
  final double monto;
  final bool isIngreso;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;

  const MontoText({
    super.key,
    required this.monto,
    this.isIngreso = true,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMonto(isIngreso ? monto : -monto, showSign: showSign),
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: isIngreso ? AppColors.successGreen : AppColors.dangerRed,
      ),
    );
  }
}

/// Widget para el saldo principal con animación de número.
class SaldoDisplay extends StatelessWidget {
  final double saldo;

  const SaldoDisplay({super.key, required this.saldo});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMonto(saldo, showSign: saldo < 0),
      style: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteText,
        letterSpacing: -1,
      ),
    );
  }
}
