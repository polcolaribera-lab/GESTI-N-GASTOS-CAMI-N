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
    expect(find.text('GASTO DEL MES'), findsOneWidget);
  });
}
