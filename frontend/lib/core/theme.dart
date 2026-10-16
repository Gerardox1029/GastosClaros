import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores de GastosClaros
class AppColors {
  AppColors._();

  // Colores principales
  static const deepPurpleBg = Color(0xFF1E1B2E);
  static const surfacePurple = Color(0xFF2D2845);
  static const accentPurple = Color(0xFFA855F7);
  static const lightPurple = Color(0xFFC084FC);
  static const mutedPurple = Color(0xFF6B5B95);

  // Colores semánticos
  static const successGreen = Color(0xFF22C55E);
  static const dangerRed = Color(0xFFEF4444);
  static const warningAmber = Color(0xFFF59E0B);
  static const whiteText = Color(0xFFF8FAFC);
  static const mutedText = Color(0xFF94A3B8);

  // Gradientes
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurpleBg, surfacePurple],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, Color(0xFF7C3AED)],
  );
}

/// Espaciado
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Bordes redondeados
class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double button = 12;
  static const double input = 12;
  static const double modal = 24;
  static const double captureCard = 12;
}

/// Tema global de la app
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.deepPurpleBg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accentPurple,
    secondary: AppColors.lightPurple,
    surface: AppColors.surfacePurple,
    error: AppColors.dangerRed,
    onPrimary: AppColors.whiteText,
    onSecondary: AppColors.whiteText,
    onSurface: AppColors.whiteText,
    onError: AppColors.whiteText,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteText,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.whiteText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.whiteText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.whiteText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.whiteText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.mutedText,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.whiteText,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedText,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedPurple,
      ),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.deepPurpleBg,
    elevation: 0,
    centerTitle: true,
    foregroundColor: AppColors.whiteText,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfacePurple,
    selectedItemColor: AppColors.accentPurple,
    unselectedItemColor: AppColors.mutedPurple,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfacePurple,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: AppColors.mutedPurple.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
    hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentPurple,
      foregroundColor: AppColors.whiteText,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfacePurple,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  ),
);
