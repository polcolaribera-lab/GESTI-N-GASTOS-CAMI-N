import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_clara/main.dart';

import 'fake_auth_service.dart';

void main() {
  testWidgets('muestra el panel principal y su navegación', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedIn()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ruta Clara'), findsOneWidget);
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

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedIn()),
    );
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

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedIn()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar este gasto?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('muestra acceso y registro cuando no hay sesión', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedOut()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('¿Has olvidado la contraseña?'), findsOneWidget);
  });

  testWidgets('permite iniciar sesión con Google', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedOut()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsNothing);
  });

  testWidgets('cierra la sesión desde Mi negocio', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedIn()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi negocio'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Cerrar sesión'),
      500,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tendrás que volver a introducir tu correo y contraseña para entrar.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('elimina la cuenta desde Mi negocio', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      RutaClaraApp(authService: FakeAuthService.signedIn()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi negocio'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, 'Eliminar mi cuenta'),
      500,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar mi cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Eliminar definitivamente'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
}
