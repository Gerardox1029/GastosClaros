import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gastos_claros/shared/models/registro.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/services/api_service.dart';
import 'package:gastos_claros/shared/widgets/add_entry_modal.dart';
import 'package:gastos_claros/shared/widgets/financial_chat.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_PE'));
  final record = Registro(
      id: '0123456789abcdef01234567',
      monto: 25,
      nombre: 'Juan',
      descripcion: 'Almuerzo',
      fecha: DateTime.utc(2026, 10, 16, 19, 30));

  testWidgets(
      'edit form preserves date and updates instead of creating a record',
      (tester) async {
    http.Request? saved;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          apiServiceProvider.overrideWith(
              (ref) => ApiService(client: MockClient((request) async {
                    saved = request;
                    return http.Response('{"success":true}', 200);
                  }))),
        ],
        child: MaterialApp(
            home:
                Scaffold(body: AddEntryModal(type: 'gasto', record: record)))));
    await tester.pumpAndSettle();
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('Subir captura YAPE'), findsNothing);
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(saved?.method, 'PATCH');
    final body = jsonDecode(saved!.body);
    expect(body['id'], record.id);
    expect(body['fecha'], '2026-10-16T19:30:00.000Z');
    expect(body['monto'], 25);
  });

  testWidgets(
      'delete requires confirmation and calls DELETE for the selected record',
      (tester) async {
    http.Request? deleted;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          apiServiceProvider.overrideWith(
              (ref) => ApiService(client: MockClient((request) async {
                    deleted = request;
                    return http.Response('{"success":true}', 200);
                  }))),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: AddEntryModal(type: 'ingreso', record: record)))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eliminar registro'));
    await tester.tap(find.text('Eliminar registro'));
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(deleted?.method, 'DELETE');
    expect(jsonDecode(deleted!.body)['type'], 'ingreso');
  });

  testWidgets('chat sends selected period and displays report', (tester) async {
    Map<String, dynamic>? query;
    await tester.pumpWidget(ProviderScope(overrides: [
      apiServiceProvider
          .overrideWith((ref) => ApiService(client: MockClient((request) async {
                query = jsonDecode(request.body);
                return http.Response(
                    jsonEncode(
                        {'answer': 'Ingresos S/. 100.00; gastos S/. 25.00.'}),
                    200);
              }))),
    ], child: const MaterialApp(home: Scaffold(body: FinancialChat()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar reporte'));
    await tester.pumpAndSettle();
    expect(query?['period'], '1M');
    expect(find.text('Ingresos S/. 100.00; gastos S/. 25.00.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
