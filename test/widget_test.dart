import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_clara/main.dart';

void main() {
  testWidgets('muestra el panel principal y su navegación', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RutaClaraApp());
    await tester.pumpAndSettle();

    expect(find.text('RutaClara'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Fiscal'), findsOneWidget);
    expect(find.text('Mi negocio'), findsOneWidget);
    expect(find.text('COSTE IMPUTADO DEL MES'), findsOneWidget);
  });

  testWidgets('abre un gasto existente con sus datos para editarlo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RutaClaraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Editar gasto'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Repostaje'), findsOneWidget);
  });

  testWidgets('pide confirmación antes de eliminar un gasto', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RutaClaraApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar este gasto?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
