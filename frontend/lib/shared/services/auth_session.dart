import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gastos_claros/core/api_config.dart';
import 'package:gastos_claros/shared/services/pwa_service.dart';

class AuthSession {
  static String? token;

  static Future<bool> restore() async {
    token = PwaService.savedToken;
    if (token == null) return false;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth-check'),
        headers: {'Authorization': 'Bearer $token'})
        .timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        PwaService.setToken(token!);
        return true;
      }
    } catch (_) {}
    token = null;
    await PwaService.clearToken();
    return false;
  }

  static Future<String?> login(String pin) async {
    try {
      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/auth-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin})).timeout(ApiConfig.requestTimeout);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['token'] is String) {
        token = data['token'] as String;
        PwaService.setToken(token!);
        return null;
      }
      return data['error'] as String? ?? 'No se pudo ingresar.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }

  static Future<void> logout() async {
    await PwaService.clearToken();
    token = null;
  }
}
