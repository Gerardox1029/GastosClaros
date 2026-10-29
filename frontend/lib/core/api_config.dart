import 'package:flutter/foundation.dart';

/// Configuración de la API backend (Netlify Functions).
class ApiConfig {
  ApiConfig._();

  // ─── URLs ──────────────────────────────────────────────────────────────────

  /// URL de producción (Netlify). Actualizar con la URL real del deploy.
  static const String _prodUrl = 'https://gastosclaross.netlify.app/api';

  /// Web usa el mismo origen; la app nativa conserva la URL remota.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? '/api' : _prodUrl,
  );

  // ─── Endpoints ─────────────────────────────────────────────────────────────

  static const String balance = '$baseUrl/balance';
  static String history(String type) => '$baseUrl/history/$type';
  static const String uploadYape = '$baseUrl/upload-yape';
  static const String manualEntry = '$baseUrl/manual-entry';

  // ─── Timeouts ──────────────────────────────────────────────────────────────

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout  = Duration(seconds: 90);
}
