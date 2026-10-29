import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/features/auth/auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE');
  runApp(
    const ProviderScope(
      child: GastosClarosApp(),
    ),
  );
}

class GastosClarosApp extends StatelessWidget {
  const GastosClarosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastosClaros',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthGate(),
      locale: const Locale('es', '419'),
    );
  }
}
