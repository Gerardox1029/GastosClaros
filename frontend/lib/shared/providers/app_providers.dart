import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/shared/services/api_service.dart';
import 'package:gastos_claros/shared/models/balance_response.dart';
import 'package:gastos_claros/shared/models/registro.dart';
import 'package:gastos_claros/shared/models/yape_extraction_result.dart';

// ──────────────────────────────────────────────
// API Service Provider (Singleton)
// ──────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ──────────────────────────────────────────────
// Balance Provider
// ──────────────────────────────────────────────

/// Estado del filtro de tiempo seleccionado.
final balanceFilterProvider = StateProvider<String>((ref) => '1M');

/// Provider del saldo actual. Se refresca al cambiar el filtro.
final balanceProvider = FutureProvider<BalanceResponse>((ref) async {
  final filter = ref.watch(balanceFilterProvider);
  final api = ref.read(apiServiceProvider);
  return api.getBalance(filter: filter);
});

// ──────────────────────────────────────────────
// History Providers
// ──────────────────────────────────────────────

/// Provider del historial de ingresos.
final ingresosHistoryLimitProvider = StateProvider<int>((ref) => 3);
final gastosHistoryLimitProvider = StateProvider<int>((ref) => 3);

final ingresosHistoryProvider = FutureProvider<List<Registro>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final limit = ref.watch(ingresosHistoryLimitProvider);
  return api.getHistory(type: 'ingresos', limit: limit);
});

/// Provider del historial de gastos.
final gastosHistoryProvider = FutureProvider<List<Registro>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final limit = ref.watch(gastosHistoryLimitProvider);
  return api.getHistory(type: 'gastos', limit: limit);
});

// ──────────────────────────────────────────────
// Upload Yape Provider
// ──────────────────────────────────────────────

/// Estado del proceso de upload de capturas Yape.
class UploadYapeState {
  final bool isUploading;
  final List<double> progressPerImage;
  final List<YapeExtractionResult>? results;
  final String? error;
  final String? status;

  const UploadYapeState({
    this.isUploading = false,
    this.progressPerImage = const [],
    this.results,
    this.error,
    this.status,
  });

  UploadYapeState copyWith({
    bool? isUploading,
    List<double>? progressPerImage,
    List<YapeExtractionResult>? results,
    String? error,
    String? status,
  }) {
    return UploadYapeState(
      isUploading: isUploading ?? this.isUploading,
      progressPerImage: progressPerImage ?? this.progressPerImage,
      results: results ?? this.results,
      error: error,
      status: status ?? this.status,
    );
  }
}

/// Notifier para manejar el upload de capturas Yape.
class UploadYapeNotifier extends StateNotifier<UploadYapeState> {
  final ApiService _api;

  UploadYapeNotifier(this._api) : super(const UploadYapeState());

  void setError(String message) {
    state = UploadYapeState(
      error: message,
      status: 'No se pudieron procesar las capturas',
    );
  }

  void prepareImages(int imageCount) {
    state = UploadYapeState(
      isUploading: true,
      progressPerImage: List.filled(imageCount, 0),
      status: 'Preparando imágenes...',
    );
  }

  void updatePreparationProgress(int completed, int total) {
    if (!state.isUploading || total == 0) return;
    final progress = List<double>.generate(
      total,
      (index) => index < completed ? 10 : 0,
    );
    state = state.copyWith(
      progressPerImage: progress,
      status: 'Preparando imagen $completed de $total...',
    );
  }

  /// Sube las capturas Yape y extrae datos con IA.
  Future<void> uploadImages({
    required List<String> base64Images,
    required String type,
  }) async {
    // Inicializar progreso
    state = UploadYapeState(
      isUploading: true,
      progressPerImage: List.filled(base64Images.length, 0.0),
      status: 'Extrayendo datos con OCR local...',
    );

    try {
      // Simular progreso incremental mientras se procesa
      _simulateProgress(base64Images.length);

      final results = await _api.uploadYapeScreenshots(
        images: base64Images,
        type: type,
      );

      state = UploadYapeState(
        isUploading: false,
        progressPerImage: List.filled(base64Images.length, 100.0),
        results: results,
        status: 'Procesamiento completado',
      );
    } catch (e) {
      state = UploadYapeState(
        isUploading: false,
        error: e.toString(),
        status: 'No se pudieron procesar las capturas',
      );
    }
  }

  /// Simula progreso visual mientras se espera la respuesta del backend.
  void _simulateProgress(int imageCount) async {
    for (int step = 1; step <= 8; step++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!state.isUploading) return;

      final progress = List<double>.generate(
        imageCount,
        (i) => (step * 12.0).clamp(0, 90),
      );
      state = state.copyWith(progressPerImage: progress);
    }
  }

  /// Limpia los resultados.
  void reset() {
    state = const UploadYapeState();
  }
}

final uploadYapeProvider =
    StateNotifierProvider<UploadYapeNotifier, UploadYapeState>((ref) {
  final api = ref.read(apiServiceProvider);
  return UploadYapeNotifier(api);
});

// ──────────────────────────────────────────────
// Manual Entry Provider
// ──────────────────────────────────────────────

/// Estado del guardado manual.
class ManualEntryState {
  final bool isSaving;
  final String? savedId;
  final bool created;
  final String? error;

  const ManualEntryState({
    this.isSaving = false,
    this.savedId,
    this.created = false,
    this.error,
  });
}

class ManualEntryNotifier extends StateNotifier<ManualEntryState> {
  final ApiService _api;

  ManualEntryNotifier(this._api) : super(const ManualEntryState());

  /// Guarda un registro manual.
  Future<bool> save({
    required double monto,
    String? nombre,
    required String descripcion,
    required DateTime fecha,
    required String type,
    String? receiptKey,
  }) async {
    state = const ManualEntryState(isSaving: true);

    try {
      final result = await _api.saveManualEntry(
        monto: monto,
        nombre: nombre,
        descripcion: descripcion,
        fecha: fecha,
        type: type,
        receiptKey: receiptKey,
      );

      state = ManualEntryState(isSaving: false, savedId: result.id,
        created: result.created);
      return true;
    } catch (e) {
      state = ManualEntryState(isSaving: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ManualEntryState();
  }
}

final manualEntryProvider =
    StateNotifierProvider<ManualEntryNotifier, ManualEntryState>((ref) {
  final api = ref.read(apiServiceProvider);
  return ManualEntryNotifier(api);
});

// ──────────────────────────────────────────────
// Navigation Provider
// ──────────────────────────────────────────────

/// Índice del tab seleccionado en el Bottom Navigation Bar.
final selectedTabProvider = StateProvider<int>((ref) => 0);
