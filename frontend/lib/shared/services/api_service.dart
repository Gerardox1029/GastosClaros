import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gastos_claros/core/api_config.dart';
import 'package:gastos_claros/shared/models/balance_response.dart';
import 'package:gastos_claros/shared/models/registro.dart';
import 'package:gastos_claros/shared/models/yape_extraction_result.dart';

/// Servicio centralizado para comunicarse con el backend REST API.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Headers por defecto para requests JSON.
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ──────────────────────────────────────────────
  // GET /api/balance
  // ──────────────────────────────────────────────

  /// Obtiene el saldo actual con filtro de tiempo.
  /// [filter] puede ser: 1D, 7D, 14D, 1M
  Future<BalanceResponse> getBalance({String filter = '1M'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.balance}?filter=$filter');
      final response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return BalanceResponse.fromJson(data);
      } else {
        throw ApiException(
          'Error al obtener saldo',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión al obtener saldo: $e');
    }
  }

  // ──────────────────────────────────────────────
  // GET /api/history/:type
  // ──────────────────────────────────────────────

  /// Obtiene el historial reciente de [type] (ingresos o gastos).
  /// [limit] define cuántos registros traer (default: 3).
  Future<List<Registro>> getHistory({
    required String type,
    int limit = 3,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.history(type)}?limit=$limit');
      final response = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List<dynamic>;
        return items
            .map((item) => Registro.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al obtener historial',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión al obtener historial: $e');
    }
  }

  // ──────────────────────────────────────────────
  // POST /api/manual-entry
  // ──────────────────────────────────────────────

  /// Guarda un registro manual (ingreso o gasto).
  Future<String> saveManualEntry({
    required double monto,
    String? nombre,
    required String descripcion,
    required DateTime fecha,
    required String type,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.manualEntry);
      final body = jsonEncode({
        'monto': monto,
        'nombre': nombre ?? '',
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'type': type,
      });

      final response = await _client
          .post(uri, headers: _jsonHeaders, body: body)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as String;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          errorData['error'] as String? ?? 'Error al guardar registro',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión al guardar registro: $e');
    }
  }

  // ──────────────────────────────────────────────
  // POST /api/upload-yape
  // ──────────────────────────────────────────────

  /// Envía capturas Yape en base64 para extracción IA.
  /// [images] lista de strings base64 de las imágenes.
  /// [type] puede ser "ingreso" o "gasto".
  Future<List<YapeExtractionResult>> uploadYapeScreenshots({
    required List<String> images,
    required String type,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.uploadYape);
      final body = jsonEncode({
        'images': images,
        'type': type,
      });

      final response = await _client
          .post(uri, headers: _jsonHeaders, body: body)
          .timeout(ApiConfig.uploadTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results
            .map((item) =>
                YapeExtractionResult.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al procesar capturas Yape',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión al subir capturas: $e');
    }
  }

  /// Libera recursos del cliente HTTP.
  void dispose() {
    _client.close();
  }
}

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
