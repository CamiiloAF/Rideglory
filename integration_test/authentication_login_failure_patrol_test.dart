// Patrol e2e test: login con credenciales inválidas.
//
// Flujo cubierto:
//   Login → email inexistente + password incorrecto → "Iniciar sesión"
//   → SnackBar de error genérico ("Correo o contraseña incorrectos.")
//   → el usuario PERMANECE en Login (no navega a Home).
//
// PRECONDICIONES DE DATOS:
//   1. El email usado (`qa.no-existe.<timestamp>@rideglory-test.com`) NO debe
//      existir en Firebase Auth. Se genera con timestamp para blindarse
//      contra que alguna corrida anterior lo haya registrado por error.
//   2. El mensaje de error es GENÉRICO por diseño (antienumeración de
//      cuentas): Firebase Auth mapea `user-not-found`, `wrong-password` e
//      `invalid-credential` al mismo texto "Correo o contraseña incorrectos."
//      (`_getFirebaseAuthErrorMessage` en
//      `lib/core/http/rest_client_functions.dart`). Este test NO puede (ni
//      debe) distinguir "usuario no existe" de "password incorrecto".
//   3. Si el dispositivo ya tiene una sesión Firebase persistida (Account
//      Manager tras un `patrol test` previo sin `--uninstall`), este test no
//      puede ejercer el flujo de login — necesita arrancar en la pantalla de
//      Login. Si detecta Home en vez de Login, falla rápido con un mensaje
//      explícito en vez de colgarse, para que quede claro que hace falta
//      reinstalar (`patrol test --uninstall`) antes de correrlo.
//
// Cómo correr:
//   patrol test -t integration_test/authentication_login_failure_patrol_test.dart \
//     --device-id emulator-5554 \
//     --uninstall
//
// (--uninstall es importante: garantiza que no hay sesión Firebase
// persistida y que el splash cae en Login.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/main.dart' as app;

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS'; // bottom nav, único de Home
const _signInButton = 'Iniciar sesión'; // auth_sign_in
const _invalidCredentialsError =
    'Correo o contraseña incorrectos.'; // mensaje genérico anti-enumeración

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.pumpAndSettle();
  }
}

void main() {
  patrolTest(
    'login: credenciales inválidas muestra error y no navega a Home',
    timeout: const Timeout(Duration(minutes: 5)),
    _runLoginFailureFlow,
  );
}

Future<void> _runLoginFailureFlow(PatrolIntegrationTester $) async {
  app.main();
  await $.pumpAndSettle();

  // Firebase Auth puede persistir la sesión en el Account Manager de Android
  // incluso tras reinstalar el APK. Loop de 24 × 5s = 120s: maneja el diálogo
  // de permiso y detecta cualquiera de los dos destinos (Login u Home).
  var onLogin = false;
  var onHome = false;
  for (var i = 0; i < 24 && !onLogin && !onHome; i++) {
    await Future<void>.delayed(const Duration(seconds: 5));
    await _grantPendingLocationPermission($);
    onLogin = $(TextField).exists;
    onHome = $(_tabEventos).exists;
  }

  // Este test EXISTE para verificar el camino de error del form de login: si
  // el device ya tiene sesión activa no hay forma de ejercerlo sin antes
  // cerrar sesión (fuera del alcance de este test). Falla rápido y explícito
  // en vez de intentar loguear con credenciales inválidas sobre una sesión ya
  // autenticada (lo cual no probaría nada).
  expect(
    onLogin,
    isTrue,
    reason:
        'El device ya tiene una sesión Firebase activa (Home visible). '
        'Corre este test con `patrol test --uninstall` para garantizar que '
        'arranca sin sesión persistida y cae en Login.',
  );

  // 1. Credenciales inválidas: email que no existe + password cualquiera.
  final nonExistentEmail =
      'qa.no-existe.${DateTime.now().millisecondsSinceEpoch}@rideglory-test.com';

  await $(TextField).at(0).enterText(nonExistentEmail);
  await $.pumpAndSettle();
  await $(TextField).at(1).enterText('PasswordIncorrecto1');
  await $.pumpAndSettle();
  await $(_signInButton).tap();

  // 2. Esperar el SnackBar de error genérico. `pumpAndSettle` no basta —
  // depende de la respuesta (fallida) de Firebase Auth, que puede tardar.
  await $(
    _invalidCredentialsError,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  // 3. El usuario NO navegó a Home: sigue en Login (form de email/password
  // sigue presente, bottom nav de Home NO existe).
  expect($(TextField), findsWidgets);
  expect(
    $(_tabEventos).exists,
    isFalse,
    reason: 'Un login fallido no debe navegar a Home',
  );
}
