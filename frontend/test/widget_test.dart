import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gastos_claros/features/dashboard/dashboard_screen.dart';
import 'package:gastos_claros/shared/models/balance_response.dart';
import 'package:gastos_claros/shared/providers/app_providers.dart';
import 'package:gastos_claros/shared/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gastos_claros/shared/widgets/currency_widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  testWidgets('shows a friendly empty state when there are no records',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balanceProvider.overrideWith((ref) async => BalanceResponse.empty),
          ingresosHistoryProvider.overrideWith((ref) async => []),
          gastosHistoryProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SaldoDisplay), findsOneWidget);
    expect(find.byType(BottomAppBar), findsNothing);
    expect(tester.getTopLeft(find.byKey(const ValueKey('dashboard-top-nav'))).dy, 0);
    expect(find.text('Aún no hay registros'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-top-nav')),
        matching: find.text('Gastos'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay registros'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the add balance sheet from the center button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWith(
            (ref) => ApiService(
              client: MockClient((_) async => http.Response('{}', 200)),
            ),
          ),
          balanceProvider.overrideWith((ref) async => BalanceResponse.empty),
          ingresosHistoryProvider.overrideWith((ref) async => []),
          gastosHistoryProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-add-fab')));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué deseas agregar?'), findsOneWidget);
    await tester.tap(find.text('Registrar un ingreso o pago recibido'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar Saldo'), findsNWidgets(2));
    expect(find.text('Descripción *'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar Saldo'));
    await tester.pumpAndSettle();

    expect(find.text('Descripción *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
