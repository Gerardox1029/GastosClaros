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

  /// Headers que no fuerzan preflight CORS para peticiones GET.
  Map<String, String> get _readHeaders => {
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
          .get(uri, headers: _readHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw ApiException(
              'Respuesta inesperada del servidor (balance): ${response.body}');
        }
        return BalanceResponse.fromJson(decoded);
      } else {
        throw ApiException(
          'Error al obtener saldo (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Sin conexión al obtener saldo. Verifica tu internet.');
    }
  }

  // ──────────────────────────────────────────────
  // GET /api/history/:type
  // ──────────────────────────────────────────────

  /// Obtiene el historial reciente de [type] (ingresos o gastos).
  /// Retorna lista vacía si no hay registros — nunca lanza por lista nula.
  Future<List<Registro>> getHistory({
    required String type,
    int limit = 3,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.history(type)}?limit=$limit');
      final response = await _client
          .get(uri, headers: _readHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return [];

        // FIX: 'data' puede ser null o ausente — retornar lista vacía en ambos casos
        final rawData = decoded['data'];
        if (rawData == null) return [];
        if (rawData is! List) return [];

        return rawData
            .whereType<Map<String, dynamic>>()
            .map((item) => Registro.fromJson(item))
            .toList();
      } else if (response.statusCode == 404) {
        // 404 es válido: simplemente no hay registros todavía
        return [];
      } else {
        throw ApiException(
          'Error al obtener historial (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Sin conexión al obtener historial. Verifica tu internet.');
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
    String? receiptKey,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.manualEntry);
      final body = jsonEncode({
        'monto': monto,
        'nombre': nombre ?? '',
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'type': type,
        if (receiptKey != null) 'receiptKey': receiptKey,
      });

      final response = await _client
          .post(uri, headers: _jsonHeaders, body: body)
          .timeout(ApiConfig.requestTimeout);

      // Aceptar 200 Y 201 — algunos deployments de Netlify devuelven 200
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return (decoded['id'] as String?) ?? '';
        }
        return '';
      } else {
        String errorMsg = 'Error al guardar registro';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMsg = (errorData['error'] as String?) ?? errorMsg;
        } catch (_) {}
        throw ApiException(errorMsg, statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Sin conexión al guardar registro. Verifica tu internet.');
    }
  }

  // ──────────────────────────────────────────────
  // POST /api/upload-yape
  // ──────────────────────────────────────────────

  /// Envía capturas Yape en base64 para extracción IA.
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
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return [];

        final rawResults = decoded['results'];
        if (rawResults == null || rawResults is! List) return [];

        return rawResults
            .whereType<Map<String, dynamic>>()
            .map((item) => YapeExtractionResult.fromJson(item))
            .toList();
      } else {
        throw ApiException(
          'Error al procesar capturas Yape (${response.statusCode})',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Sin conexión al subir capturas. Verifica tu internet.');
    }
  }

  Future<void> modifyRecord({required String id, required String type,
    Map<String, dynamic>? values, bool delete = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/record');
    final body = jsonEncode({'id': id, 'type': type, ...?values});
    final response = await (delete
        ? _client.delete(uri, headers: _jsonHeaders, body: body)
        : _client.patch(uri, headers: _jsonHeaders, body: body))
      .timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException('No se pudo ${delete ? 'eliminar' : 'actualizar'} el registro.');
    }
  }

  Future<String> askAssistant({required String message, required String period,
    required List<Map<String, String>> history}) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/financial-assistant'), headers: _jsonHeaders,
      body: jsonEncode({'message': message, 'period': period, 'history': history}),
    ).timeout(ApiConfig.uploadTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ApiException(data['error'] as String? ?? 'No se pudo consultar al asistente.');
    }
    return data['answer'] as String;
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
  String toString() => message;
}
