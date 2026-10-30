import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastos_claros/shared/models/balance_response.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/services/api_service.dart';
import 'package:gastos_claros/shared/widgets/currency_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('negative balances and expense amounts display a minus sign', () {
    expect(formatMonto(-7.5), '-S/. 7,50');
    expect(formatMonto(-7.5, showSign: true), '-S/. 7,50');
    expect(formatMonto(7.5, showSign: true), '+S/. 7,50');
  });

  for (final type in ['ingresos', 'gastos']) {
    test('$type history grows from 3 to 8 to 13 records', () async {
      final limits = <int>[];
      final api = ApiService(client: MockClient((request) async {
        final limit = int.parse(request.url.queryParameters['limit']!);
        limits.add(limit);
        return http.Response(
            jsonEncode({
              'data': List.generate(
                  limit,
                  (i) => {
                        '_id': '$i',
                        'monto': 10,
                        'nombre': 'Movimiento $i',
                        'descripcion': 'Prueba',
                        'fecha': '2026-10-29T12:00:00Z',
                        'tipo_registro': 'manual',
                      })
            }),
            200);
      }));
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(api),
      ]);
      addTearDown(container.dispose);
      addTearDown(api.dispose);
      final history =
          type == 'ingresos' ? ingresosHistoryProvider : gastosHistoryProvider;
      final limit = type == 'ingresos'
          ? ingresosHistoryLimitProvider
          : gastosHistoryLimitProvider;
      for (final count in [3, 8, 13]) {
        if (count > 3) container.read(limit.notifier).state += 5;
        final records = await container.read(history.future);
        expect(records.length, count);
        expect(records.first.nombre, 'Movimiento 0');
      }
      expect(limits, [3, 8, 13]);
    });
  }

  group('BalanceResponse.fromJson', () {
    test('parses the production zero-balance response', () {
      final balance = BalanceResponse.fromJson({
        'saldo': 0,
        'total_ingresos': 0,
        'total_gastos': 0,
        'filtro': '1M',
      });

      expect(balance.saldo, 0);
      expect(balance.totalIngresos, 0);
      expect(balance.totalGastos, 0);
      expect(balance.filtro, '1M');
    });
  });

  test('ApiService.getBalance accepts the production zero-balance response',
      () async {
    final service = ApiService(
      client: MockClient(
        (_) async => http.Response(
          '{"saldo":0,"total_ingresos":0,"total_gastos":0,"filtro":"1M"}',
          200,
        ),
      ),
    );

    final balance = await service.getBalance();

    expect(balance.saldo, 0);
    expect(balance.totalIngresos, 0);
    expect(balance.totalGastos, 0);
    expect(balance.filtro, '1M');
    service.dispose();
  });

  test('GET API requests do not send a Content-Type header', () async {
    final requests = <http.Request>[];
    final service = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          request.url.path.endsWith('/balance')
              ? '{"saldo":0,"total_ingresos":0,"total_gastos":0,"filtro":"1M"}'
              : '{"data":[]}',
          200,
        );
      }),
    );

    await service.getBalance();
    await service.getHistory(type: 'ingresos');

    expect(requests, hasLength(2));
    for (final request in requests) {
      expect(request.headers.containsKey('content-type'), isFalse);
    }
    service.dispose();
  });

  test('upload state starts before image preparation completes', () {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            client: MockClient((_) async => http.Response('{}', 200)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(uploadYapeProvider.notifier);
    notifier.prepareImages(2);

    expect(container.read(uploadYapeProvider).isUploading, isTrue);
    expect(
      container.read(uploadYapeProvider).status,
      'Preparando imágenes...',
    );

    notifier.updatePreparationProgress(1, 2);
    expect(container.read(uploadYapeProvider).progressPerImage, [10.0, 0.0]);
  });

  group('ApiService.getHistory', () {
    test('returns an empty list when data is null or missing', () async {
      for (final body in ['{"data":null}', '{}']) {
        final service = ApiService(
          client: MockClient((_) async => http.Response(body, 200)),
        );

        expect(await service.getHistory(type: 'ingresos'), isEmpty);
        service.dispose();
      }
    });

    test('preserves a record whose amount is zero', () async {
      final service = ApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {
                  '_id': 'zero',
                  'monto': 0,
                  'nombre': '',
                  'descripcion': 'Registro en cero',
                  'fecha': '2026-10-15T12:00:00.000Z',
                },
              ],
            }),
            200,
          ),
        ),
      );

      final records = await service.getHistory(type: 'ingresos');

      expect(records, hasLength(1));
      expect(records.single.monto, 0);
      service.dispose();
    });
  });
}
