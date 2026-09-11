// Suite e2e de la rodada en vivo y el SOS de Rideglory v2, contra
// Supabase local.
//
// Corre con:
//   flutter test integration_test/live_ride_patrol_test.dart \
//     -d emulator-5554 --flavor dev \
//     --dart-define-from-file=config/dev.json \
//     --dart-define=SUPABASE_URL=http://10.0.2.2:54321
//
// Sigue el mismo harness que `smoke_v2_patrol_test.dart`: `integration_test`
// + `flutter_test` puro (no `patrolTest`, incompatible con la versión de
// `patrol_cli` instalada — ver cabecera de ese archivo). Un solo
// `testWidgets` recorre los escenarios (a)-(f) en secuencia, igual que la
// suite de humo, porque `Supabase.initialize`/`configureDependencies` no
// soportan un segundo `app.main()` en el mismo proceso.
//
// Nunca apunta a un proyecto Supabase remoto: usa el Supabase local
// (`supabase start`) con los usuarios y la rodada semilla de
// `supabase/seed.sql` — "Rodada en curso" (`started`), organizada por
// qa2@gmail.com, con qa1@gmail.com inscrito y aprobado, y una posición
// inicial de qa2 en `live_positions`. Password `Test123.` para ambos.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rideglory/features/live_ride/presentation/widgets/sos_hold_button.dart';
import 'package:rideglory/main.dart' as app;

// IDs fijos del seed (supabase/seed.sql).
const String _qa1Id = '11111111-1111-1111-1111-111111111111';
const String _liveEventId = '55555555-5555-5555-5555-555555555555';

// Mismo mecanismo de configuración que `AppEnv` (lib/core/config/app_env.dart):
// `--dart-define-from-file` + `--dart-define`, compilados dentro del mismo
// binario que la app bajo prueba.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

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

/// Asegura que un texto NO aparece durante toda la ventana de espera —
/// usado para probar la ausencia de un estado (ej. la vista de "sin
/// permiso de ubicación" no debe montarse nunca al solo abrir LV1/LV1b).
Future<void> _expectNeverAppears(
  WidgetTester tester,
  String text, {
  Duration window = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(window);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.textContaining(text),
      findsNothing,
      reason: '"$text" apareció cuando no debía',
    );
  }
}

Future<void> _login(WidgetTester tester, String email, String password) async {
  await _waitForText(tester, 'Continuar con correo');
  await tester.tap(find.text('Continuar con correo'), warnIfMissed: true);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));

  final fields = find.byType(TextField);
  expect(
    fields,
    findsNWidgets(2),
    reason:
        'Se esperaban campos correo/clave en EmailAuthPage. Si esto falla '
        'con 0 campos y el dispositivo sigue en Bienvenida, revisar el '
        'redirect de app_router.dart.',
  );
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await _settle(tester);
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
  await tester.tap(find.text('Iniciar sesión'), warnIfMissed: true);
  await _settle(tester, seconds: 8);
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

/// D16/D19: consulta directa por REST a la vista `sos_alerts_visible`, con
/// el token de sesión del cliente Supabase de la app que ya está corriendo
/// (nunca un cliente aparte contra un proyecto remoto). Verifica en la
/// base, no en la UI — la UI puede mostrar "pendiente" mientras el
/// servidor ya confirmó, o viceversa.
Future<List<Map<String, dynamic>>> _fetchSosRows() async {
  final session = Supabase.instance.client.auth.currentSession;
  expect(
    session,
    isNotNull,
    reason: 'Se esperaba una sesión activa del cliente Supabase de la app',
  );
  final uri = Uri.parse(
    '$_supabaseUrl/rest/v1/sos_alerts_visible'
    '?event_id=eq.$_liveEventId&user_id=eq.$_qa1Id'
    '&order=created_at.desc&limit=1',
  );
  final response = await http.get(
    uri,
    headers: {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer ${session!.accessToken}',
      'Accept': 'application/json',
    },
  );
  expect(
    response.statusCode,
    200,
    reason: 'PostgREST respondió ${response.statusCode}: ${response.body}',
  );
  final rows = jsonDecode(response.body) as List<dynamic>;
  return rows.cast<Map<String, dynamic>>();
}

/// Reintenta la consulta hasta que aparezca una fila con el `status`
/// esperado, o falla tras el timeout — la escritura del SOS es
/// (persistencia local -> red) y no es instantánea.
Future<Map<String, dynamic>> _waitForSosStatus(
  String status, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  Map<String, dynamic>? last;
  while (DateTime.now().isBefore(deadline)) {
    final rows = await _fetchSosRows();
    if (rows.isNotEmpty && rows.first['status'] == status) {
      return rows.first;
    }
    last = rows.isNotEmpty ? rows.first : null;
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
  fail(
    'Ninguna fila de sos_alerts_visible llegó a status="$status" para '
    'qa1/"Rodada en curso" tras ${timeout.inSeconds}s. Última fila: $last',
  );
}

/// Limpieza: cierra por RPC cualquier SOS `active` de qa1 en la rodada en
/// curso que haya quedado abierto (ej. una corrida anterior interrumpida).
/// `close_sos` es idempotente, así que nunca falla por "ya está cerrado".
Future<void> _closeAnyOpenSos() async {
  final rows = await _fetchSosRows();
  if (rows.isEmpty || rows.first['status'] != 'active') return;
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return;
  final id = rows.first['id'];
  final uri = Uri.parse('$_supabaseUrl/rest/v1/rpc/close_sos');
  await http.post(
    uri,
    headers: {
      'apikey': _supabaseAnonKey,
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'p_sos_id': id}),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live ride v2: rodada en vivo (LV1/LV6) y ciclo de SOS (LV3/LV4/D19)',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // Una corrida anterior pudo dejar sesión persistida: la app abriría en
      // Mantenimiento y nunca aparecería la bienvenida.
      if (Supabase.instance.client.auth.currentSession != null) {
        await Supabase.instance.client.auth.signOut();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // --- a. qa1 entra al detalle de "Rodada en curso" y ve el CTA ------
      await _login(tester, 'qa1@gmail.com', 'Test123.');
      await _waitForText(tester, 'Mantenimiento');
      await tester.tap(find.bySemanticsLabel('EVENTOS'));
      await _settle(tester);
      await _waitForText(tester, 'Rodada en curso');
      await tester.tap(find.text('Rodada en curso'));
      await _settle(tester, seconds: 4);

      await tester.dragUntilVisible(
        find.text('Ver rodada en vivo'),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      expect(find.text('Ver rodada en vivo'), findsOneWidget);

      // Limpieza defensiva: por si una corrida previa dejó un SOS abierto,
      // antes de seguir con el resto del flujo.
      await _closeAnyOpenSos();

      // --- b. LV1: riders visibles, sin pedir permiso de ubicación -------
      await tester.tap(find.text('Ver rodada en vivo'));
      await _settle(tester, seconds: 4);

      // El chequeo de permiso al cargar LV1 es de solo lectura
      // (`checkPermission`, nunca `requestPermission`) — la vista de "sin
      // permiso" (D21) no debe montarse nunca por el solo hecho de abrir
      // la pantalla, solo al pulsar "Compartir mi ubicación".
      await _expectNeverAppears(tester, 'Necesitamos tu ubicación');

      // "QA Organizador Dos" (qa2, con posición sembrada) debe verse en la
      // hoja de riders.
      await _waitForText(tester, 'QA Organizador Dos');

      // --- c. Compartir ubicación -> aviso propio antes del sistema ------
      await tester.tap(find.text('Compartir mi ubicación'));
      await _settle(tester);
      await _waitForText(tester, 'Compartir tu ubicación con el grupo');
      expect(find.text('Permitir'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);

      await tester.tap(find.text('Ahora no'));
      await _settle(tester);
      // El diálogo del sistema de permisos nunca se dispara: no hay
      // `startSharing` ni chip "Compartiendo ubicación".
      expect(find.text('Compartiendo ubicación'), findsNothing);

      // --- d. SOS: mantener pulsado 1,5s -> pantalla de SOS activo -------
      await tester.tap(find.text('SOS'));
      await _settle(tester);
      await _waitForText(tester, '¿Pedir ayuda al grupo?');

      final holdButton = find.byType(SosHoldButton);
      expect(holdButton, findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getCenter(holdButton),
      );
      // Cruza el umbral de long-press de Flutter (~500ms) y luego los
      // 1500ms del propio hold del botón de SOS.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1600));
      await gesture.up();
      await _settle(tester, seconds: 3);

      await _waitForText(tester, 'SOS activo');
      await _waitForText(tester, 'Ya estoy bien — cerrar SOS');

      // Verificación directa en base (D16: el SOS se persiste y confirma
      // contra el servidor, la UI no es la fuente de verdad).
      final activeRow = await _waitForSosStatus('active');
      expect(activeRow['status'], 'active');
      expect(activeRow['user_id'], _qa1Id);
      expect(activeRow['event_id'], _liveEventId);

      // --- e. Cerrar el SOS con confirmación ------------------------------
      await tester.tap(find.text('Ya estoy bien — cerrar SOS'));
      await _settle(tester);
      await _waitForText(tester, '¿Cerrar tu SOS?');
      await tester.tap(find.text('Sí, estoy bien'));
      await _settle(tester, seconds: 4);

      final closedRow = await _waitForSosStatus(
        'closed',
        timeout: const Duration(seconds: 60),
      );
      expect(closedRow['status'], 'closed');
      expect(closedRow['closed_by'], _qa1Id);

      // --- Vuelta al detalle del evento y cierre de sesión de qa1 --------
      await tester.pageBack();
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('PERFIL'));
      await _settle(tester);
      await _signOut(tester);

      // --- f. qa2 (organizador) ve la lista completa de riders (LV6) -----
      await _login(tester, 'qa2@gmail.com', 'Test123.');
      await _waitForText(tester, 'Mantenimiento');
      await tester.tap(find.bySemanticsLabel('EVENTOS'));
      await _settle(tester);
      await tester.tap(find.text('Mías'));
      await _settle(tester);
      await _waitForText(tester, 'Rodada en curso');
      await tester.tap(find.text('Rodada en curso'));
      await _settle(tester, seconds: 4);

      await tester.dragUntilVisible(
        find.text('Ver rodada en vivo'),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.tap(find.text('Ver rodada en vivo'));
      await _settle(tester, seconds: 4);

      await tester.tap(find.byTooltip('Ver riders'));
      await _settle(tester, seconds: 3);

      await _waitForText(tester, 'Riders');
      await _waitForText(tester, 'QA Rider Uno');
      await _waitForText(tester, 'QA Organizador Dos');
    },
  );

  tearDown(() async {
    // Red de seguridad final: nunca dejar un SOS `active` de qa1 abierto
    // entre corridas, sin importar en qué paso haya fallado el test.
    try {
      await _closeAnyOpenSos();
    } catch (_) {
      // Best-effort: si la sesión ya no es válida (ej. la app cerró
      // sesión), no hay nada que limpiar por esta vía.
    }
  });
}
