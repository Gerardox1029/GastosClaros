/// Configuración de la API backend.
class ApiConfig {
  ApiConfig._();

  /// URL base del backend (Netlify Functions).
  /// En desarrollo: http://localhost:8888/api
  /// En producción: https://tu-sitio.netlify.app/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8888/api',
  );

  /// Endpoints
  static const String balance = '$baseUrl/balance';
  static String history(String type) => '$baseUrl/history/$type';
  static const String uploadYape = '$baseUrl/upload-yape';
  static const String manualEntry = '$baseUrl/manual-entry';

  /// Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
