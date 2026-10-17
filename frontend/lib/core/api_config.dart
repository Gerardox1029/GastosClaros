/// Configuración de la API backend (Netlify Functions).
class ApiConfig {
  ApiConfig._();

  // ─── URLs ──────────────────────────────────────────────────────────────────

  /// URL de producción (Netlify). Actualizar con la URL real del deploy.
  static const String _prodUrl = 'https://gastosclaross.netlify.app/api';

  /// URL de desarrollo local (netlify dev).
  static const String _devUrl = 'http://localhost:8888/api';

  /// URL activa — se selecciona con el dart-define en build.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _prodUrl, // producción por defecto en el APK
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
