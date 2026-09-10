// Prueba de humo end-to-end de Rideglory v2 contra Supabase local.
//
// Corre con:
//   flutter test integration_test/smoke_v2_patrol_test.dart \
//     -d emulator-5554 --flavor dev \
//     --dart-define-from-file=config/dev.json \
//     --dart-define=SUPABASE_URL=http://10.0.2.2:54321
//
// `patrol_cli` instalado (4.5.1) es incompatible con el paquete `patrol`
// fijado en pubspec (4.5.0) — ver salida de `patrol --version` en el informe
// de la corrida. Por eso esta suite usa `integration_test` + `flutter_test`
// estándar en lugar de la sintaxis `patrolTest`.
//
// Nunca apunta a un proyecto Supabase remoto: usa el Supabase local
// (`supabase start`) con los usuarios semilla qa1@gmail.com / qa2@gmail.com,
// contraseña `Test123.`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rideglory/design_system/components/app_switch.dart';
import 'package:rideglory/features/events/presentation/widgets/registration_risk_row.dart';
import 'package:rideglory/main.dart' as app;

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  await tester.pumpAndSettle(Duration(milliseconds: seconds * 200));
}

/// Espera activamente por un texto (útil tras una llamada de red real a
/// Supabase local, donde el tiempo de respuesta no es determinista como en
/// un mock).
Future<void> _waitForText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (find.textContaining(text).evaluate().isNotEmpty) return;
  }
  await tester.pumpAndSettle();
  expect(
    find.textContaining(text),
    findsWidgets,
    reason: 'No apareció "$text" tras ${timeout.inSeconds}s',
  );
}

Future<void> _login(WidgetTester tester, String email, String password) async {
  // Bienvenida -> "Continuar con correo".
  await _waitForText(tester, 'Continuar con correo');
  await tester.tap(find.text('Continuar con correo'), warnIfMissed: true);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  // BUG conocido (ver informe de la corrida): `app_router.dart` compara
  // `state.matchedLocation == AppRoutes.welcomePath` en el `redirect` para
  // decidir `isAtWelcome`. Cualquier subruta de bienvenida (`/welcome/correo`,
  // `/welcome/crear-cuenta`, `/welcome/recuperar`) no matchea exactamente y el
  // usuario no autenticado es redirigido de vuelta a `/welcome` de inmediato,
  // bloqueando el login por correo por completo. Este `pump` adicional no lo
  // arregla: solo evidencia que, tras asentarse, seguimos en Bienvenida.
  await tester.pump(const Duration(seconds: 2));

  final fields = find.byType(TextField);
  expect(
    fields,
    findsNWidgets(2),
    reason:
        'Se esperaban campos correo/clave en EmailAuthPage. Si esto falla '
        'con 0 campos y el dispositivo sigue en Bienvenida, ver el bug '
        'conocido del redirect de app_router.dart documentado arriba de '
        '_login().',
  );
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await _settle(tester);
  await tester.tap(find.text('Iniciar sesión'));
  await _settle(tester, seconds: 6);
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings).hitTestable());
  await _settle(tester);
  await tester.dragUntilVisible(
    find.text('Cerrar sesión'),
    find.byType(Scrollable).first,
    const Offset(0, -200),
  );
  await tester.tap(find.text('Cerrar sesión'));
  await _settle(tester, seconds: 4);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke v2: rider qa1 - mantenimiento, garaje, inscripción', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // --- a. Bienvenida -> login qa1 -> pestaña Mantenimiento -----------
    await _login(tester, 'qa1@gmail.com', 'Test123.');
    await _waitForText(tester, 'Mantenimiento');
    // El mantenimiento sembrado debe verse en el historial/agenda.
    expect(find.byType(ListView), findsWidgets);

    // --- b. Registrar mantenimiento en 3 pasos --------------------------
    // Ubicamos el FAB de mantenimiento por su Semantics label (l10n).
    final maintenanceFab = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label != null &&
          widget.properties.button == true,
    );
    expect(maintenanceFab, findsWidgets);
    await tester.tap(maintenanceFab.first);
    await _settle(tester);

    // Paso 1: tipo de mantenimiento.
    await _waitForText(tester, '¿Qué mantenimiento registras?');
    await tester.tap(find.text('Cambio de aceite y filtro'));
    await _settle(tester);
    await tester.tap(find.text('Siguiente'));
    await _settle(tester);

    // Paso 2: kilometraje mayor al odómetro actual (seed = 8.500).
    final odometerField = find.byType(TextField).first;
    await tester.enterText(odometerField, '9200');
    await _settle(tester);
    await tester.tap(find.text('Siguiente'));
    await _settle(tester);

    // Paso 3: guardar sin datos opcionales.
    await tester.tap(find.text('Guardar'));
    await _settle(tester, seconds: 5);

    // De vuelta en Mantenimiento, el historial debe reflejar el registro.
    await _waitForText(tester, '9.200');

    // --- c. Garaje -> moto del seed -> editar -> fila de documentos SOAT
    await tester.tap(find.text('GARAJE'));
    await _settle(tester);
    await _waitForText(tester, 'La Negra');
    await tester.tap(find.text('La Negra'));
    await _settle(tester);
    await _waitForText(tester, 'SOAT');

    await tester.pageBack();
    await _settle(tester);

    // --- d. Eventos -> Mi Evento -> Inscribirme -> EV4 -> Confirmar -----
    await tester.tap(find.text('EVENTOS'));
    await _settle(tester);
    await _waitForText(tester, 'Mi Evento');
    await tester.tap(find.text('Mi Evento'));
    await _settle(tester);
    await _waitForText(tester, 'Inscribirme');
    await tester.tap(find.text('Inscribirme'));
    await _settle(tester);

    // Aceptar riesgo (switch de EV4) y confirmar.
    final riskSwitch = find.descendant(
      of: find.byType(RegistrationRiskRow),
      matching: find.byType(AppSwitch),
    );
    expect(riskSwitch, findsOneWidget);
    await tester.tap(riskSwitch);
    await _settle(tester);
    await tester.tap(find.text('Confirmar inscripción'));
    await _settle(tester, seconds: 5);

    await _waitForText(tester, 'Inscrito');

    // --- e. Cerrar sesión -> login qa2 -> Mías -> Mi Evento -> inscritos
    await tester.tap(find.text('PERFIL'));
    await _settle(tester);
    await _signOut(tester);

    await _login(tester, 'qa2@gmail.com', 'Test123.');
    await _waitForText(tester, 'Mantenimiento');
    await tester.tap(find.text('EVENTOS'));
    await _settle(tester);
    await tester.tap(find.text('Mías'));
    await _settle(tester);
    await _waitForText(tester, 'Mi Evento');
    await tester.tap(find.text('Mi Evento'));
    await _settle(tester);
    await _waitForText(tester, 'Ver inscritos');
    await tester.tap(find.text('Ver inscritos'));
    await _settle(tester, seconds: 4);
    await _waitForText(tester, 'Llamar');

    // --- f. Perfil -> editar contacto de emergencia -> guardar ----------
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.text('PERFIL'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings).hitTestable());
    await _settle(tester);
    await tester.dragUntilVisible(
      find.text('Contacto de emergencia'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.tap(find.text('Contacto de emergencia'));
    await _settle(tester);

    final contactFields = find.byType(TextField);
    await tester.enterText(contactFields.at(0), 'Contacto QA Smoke');
    await tester.enterText(contactFields.at(1), '3001234567');
    await tester.enterText(contactFields.at(2), 'Hermano/a');
    await _settle(tester);
    await tester.tap(find.text('Guardar'));
    await _settle(tester, seconds: 4);
  });
}
