// Patrol e2e test: registro (signup) de una cuenta nueva con email/password.
//
// Flujo cubierto:
//   Login → "Regístrate" → SignupView → completa nombre/email/password/
//   confirmación → acepta términos y condiciones → "Crear cuenta"
//   → Home (bottom nav "EVENTOS" visible).
//
// PRECONDICIONES DE DATOS:
//   1. Cada corrida genera un email SINTÉTICO ÚNICO
//      (`qa.signup.<timestamp>@rideglory-test.com`) para no colisionar con
//      cuentas reales ni con corridas anteriores — Firebase rechaza un signup
//      con un email ya registrado (`email-already-in-use`), y el mensaje de
//      error para ese código es el mismo genérico "Correo o contraseña
//      incorrectos." que para credenciales inválidas (antienumeración), lo
//      que haría fallar este test de forma confusa si el email se reutilizara.
//   2. El test crea una cuenta Firebase Auth + un registro de usuario en el
//      backend REALES en cada corrida. No hay limpieza automática — si se
//      corre muchas veces, purgar periódicamente las cuentas
//      `qa.signup.*@rideglory-test.com` desde la consola de Firebase/backend.
//   3. Si el dispositivo ya tiene una sesión Firebase persistida (Account
//      Manager tras un `patrol test` previo sin `--uninstall`), el test hace
//      logout primero (tab Perfil → "Cerrar sesión" → confirmar) para
//      garantizar que arranca desde Login. No se necesitan credenciales para
//      ese logout — la sesión ya está activa; solo se cierra.
//
// Cómo correr:
//   patrol test -t integration_test/authentication_signup_patrol_test.dart \
//     --device-id emulator-5554

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/main.dart' as app;

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS'; // bottom nav, único de Home
const _registerLink = 'Regístrate'; // auth_register_link (LoginRegisterRow)
const _joinCommunity = 'Únete a la comunidad'; // auth_join_community (heading)
const _createAccountButton = 'Crear cuenta'; // auth_create_account_btn/_title
// NOTA: "Crear cuenta" aparece DOS veces en pantalla (título de la sección y
// el botón submit) porque `auth_create_account_title` y
// `auth_create_account_btn` comparten el mismo texto en español. Por eso el
// tap usa `.last` (el botón siempre queda debajo del título en el árbol).
const _logoutMenuItem = 'Cerrar sesión'; // auth_logout (ProfileActionsList)
const _logoutConfirmMessage =
    '¿Estás seguro de que deseas cerrar sesión?'; // auth_logoutConfirmMessage

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.pumpAndSettle();
  }
}

/// Deja el device en la pantalla de Login, cerrando sesión primero si el
/// Firebase Account Manager persistió una sesión de una corrida anterior
/// (`patrol test` sin `--uninstall`).
Future<void> _ensureOnLoginScreen(PatrolIntegrationTester $) async {
  app.main();
  await $.pumpAndSettle();

  var onLogin = false;
  var onHome = false;
  for (var i = 0; i < 24 && !onLogin && !onHome; i++) {
    await Future<void>.delayed(const Duration(seconds: 5));
    await _grantPendingLocationPermission($);
    onLogin = $(TextField).exists;
    onHome = $(_tabEventos).exists;
  }

  if (onLogin) return;

  if (!onHome) {
    await $(_tabEventos).waitUntilVisible(timeout: const Duration(seconds: 30));
  }

  // Sesión persistida: iniciar sesión ya está resuelto (Home visible), pero
  // este test necesita arrancar SIN sesión, así que cierra sesión desde el
  // tab Perfil.
  await $(Icons.person_outline).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
  await _grantPendingLocationPermission($);

  await $(
    _logoutMenuItem,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_logoutMenuItem).tap();
  await $.pumpAndSettle();

  await $(
    _logoutConfirmMessage,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  // El diálogo repite el texto "Cerrar sesión" en el botón de confirmar
  // (título + CTA comparten `auth_logout`); el CTA de confirmación es el
  // último match en el árbol.
  await $(_logoutMenuItem).at($(_logoutMenuItem).evaluate().length - 1).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));

  await $(TextField).waitUntilVisible(timeout: const Duration(seconds: 20));
}

void main() {
  patrolTest(
    'signup: usuario nuevo se registra con email y password y llega a Home',
    timeout: const Timeout(Duration(minutes: 7)),
    _runSignupFlow,
  );
}

Future<void> _runSignupFlow(PatrolIntegrationTester $) async {
  // 1. Garantizar que arrancamos en Login (sin sesión previa).
  await _ensureOnLoginScreen($);

  // 2. Ir a Signup desde el link de Login.
  await $(_registerLink).tap();
  await $.pumpAndSettle();
  await $(
    _joinCommunity,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));

  // 3. Completar el formulario con un email sintético único (evita choques
  // con `email-already-in-use` entre corridas).
  final uniqueEmail =
      'qa.signup.${DateTime.now().millisecondsSinceEpoch}@rideglory-test.com';
  const password = 'Test1234'; // cumple política signup: 8+, mayúscula, dígito

  await $(TextField).at(0).enterText('QA Signup Test');
  await $.pumpAndSettle();
  await $(TextField).at(1).enterText(uniqueEmail);
  await $.pumpAndSettle();
  await $(TextField).at(2).enterText(password);
  await $.pumpAndSettle();
  await $(TextField).at(3).enterText(password);
  await $.pumpAndSettle();

  // 4. Aceptar términos y condiciones (checkbox, no es un FormBuilderField).
  await $(Checkbox).tap();
  await $.pumpAndSettle();

  // 5. Enviar. El botón "Crear cuenta" es el ÚLTIMO match (el título de la
  // sección comparte el mismo texto).
  await $(_createAccountButton).at(1).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 25));

  // 6. Permiso de ubicación tras signup (Home carga mapa).
  await _grantPendingLocationPermission($);

  // 7. Éxito: Home visible ('EVENTOS' del bottom nav).
  await $(_tabEventos).waitUntilVisible(timeout: const Duration(seconds: 30));
}
