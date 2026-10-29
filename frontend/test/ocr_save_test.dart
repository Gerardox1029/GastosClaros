import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gastos_claros/shared/models/yape_extraction_result.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/services/api_service.dart';
import 'package:gastos_claros/shared/widgets/add_entry_modal.dart';

class CompletedUpload extends UploadYapeNotifier {
  CompletedUpload(super.api);
  void complete(List<YapeExtractionResult> results) {
    state = UploadYapeState(results: results);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_PE'));
  testWidgets('OCR without date or description still fills amount and name', (tester) async {
    final api = ApiService(client: MockClient((_) async => http.Response('{"data":[]}', 200)));
    final upload = CompletedUpload(api);
    await tester.pumpWidget(ProviderScope(overrides: [
      apiServiceProvider.overrideWith((ref) => api),
      uploadYapeProvider.overrideWith((ref) => upload),
    ], child: const MaterialApp(home: Scaffold(body: AddEntryModal(type: 'ingreso')))));
    await tester.pumpAndSettle();
    upload.complete([YapeExtractionResult.fromJson({
      'nombre': 'Mayra Ram*', 'monto': 70, 'descripcion': '',
      'fecha': null, 'extracted': true, 'saved': false, 'captureIndex': 1,
    })]);
    await tester.pumpAndSettle();
    expect(find.text('70.00'), findsOneWidget);
    expect(find.text('Mayra Ram*'), findsNWidgets(2));
    expect(find.text('No se reconoció la fecha. Revisa la fecha del formulario antes de guardar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OCR fills the form without saving and double tap sends one save', (tester) async {
    final pending = Completer<http.Response>();
    final requests = <http.Request>[];
    final api = ApiService(client: MockClient((request) {
      requests.add(request);
      return pending.future;
    }));
    final upload = CompletedUpload(api);
    await tester.pumpWidget(ProviderScope(overrides: [
      apiServiceProvider.overrideWith((ref) => api),
      uploadYapeProvider.overrideWith((ref) => upload),
    ], child: const MaterialApp(home: Scaffold(body: AddEntryModal(type: 'ingreso')))));
    await tester.pumpAndSettle();
    upload.complete([YapeExtractionResult(nombre: 'Persona Prue*', monto: 75,
      descripcion: 'Mensaje de prueba', fecha: DateTime.utc(2026, 10, 15, 16, 21),
      extracted: true, saved: false, receiptKey: List.filled(64, 'a').join(), captureIndex: 1)]);
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expect(find.text('75.00'), findsOneWidget);
    expect(find.text('Persona Prue*'), findsNWidgets(2));
    expect(find.text('El saldo cambia solo al guardar.'), findsOneWidget);
    final save = find.text('Guardar Saldo');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    expect(requests, hasLength(1));
    final body = jsonDecode(requests.single.body);
    expect(body['receiptKey'], List.filled(64, 'a').join());
    expect(body['fecha'], '2026-10-15T16:21:00.000Z');
    expect(requests.single.method, 'POST');
    pending.complete(http.Response('{"success":true,"id":"0123456789abcdef01234567"}', 201));
    await tester.pumpAndSettle();
  });
}
