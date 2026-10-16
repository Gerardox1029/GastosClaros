import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/core/theme.dart';
import 'package:gastos_claros/features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const SplashScreen(),
      locale: const Locale('es', '419'),
    );
  }
}
