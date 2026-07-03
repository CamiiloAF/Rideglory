// Shared Patrol bootstrap helper for Rideglory e2e tests.
//
// [bootstrapSession] extracts the common "launch app → grant permissions →
// log in (or reuse a persisted Firebase session) → land on Home" flow that
// every Patrol test needs before it can exercise its own feature.
//
// Cómo correr un test que use este helper (ejemplo):
//   patrol test -t integration_test/registration_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=usuario2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.
//
// NOTE: los otros 4 tests Patrol (events/home/profile/vehicles) todavía llevan
// su propia copia inline de este flujo. Pueden migrar a [bootstrapSession] más
// adelante; se dejaron intactos aquí para acotar el diff.

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/main.dart' as app;

// ignore: do_not_use_environment
const _defaultTestEmail = String.fromEnvironment(
  'TEST_EMAIL',
  defaultValue: 'tu_email@ejemplo.com',
);
// ignore: do_not_use_environment
const _defaultTestPassword = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: 'tu_password',
);

/// Launches the app and leaves it on the Home shell with an active session.
///
/// Handles the platform location-permission dialog (which can appear at several
/// points) and both entry paths: a fresh login form or a Firebase session that
/// Android's Account Manager persisted across reinstalls. Credentials come from
/// the `TEST_EMAIL` / `TEST_PASSWORD` dart-defines by default.
///
/// Throws (via [PatrolFinder.waitUntilVisible]) with a clear timeout if the app
/// never reaches Home — the caller then fails fast instead of hanging.
Future<void> bootstrapSession(
  PatrolIntegrationTester $, {
  String email = _defaultTestEmail,
  String password = _defaultTestPassword,
}) async {
  app.main();
  await $.pumpAndSettle();

  // Firebase Auth puede persistir la sesión en el Account Manager de Android
  // incluso tras reinstalar el APK (patrol test --uninstall). Por eso el splash
  // puede navegar al Home (sesión activa) o al Login (sin sesión). Loop de
  // 24 × 5s = 120s: maneja el diálogo de permiso y detecta cualquiera de los
  // dos destinos.
  var onLogin = false;
  var onHome = false;
  for (var i = 0; i < 24 && !onLogin && !onHome; i++) {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
      await $.platformAutomator.mobile.grantPermissionWhenInUse();
      await $.pumpAndSettle();
    }
    onLogin = $(TextField).exists;
    onHome = $('EVENTOS').exists; // bottom nav visible = ya en home
  }

  if (onLogin) {
    await $(TextField).at(0).enterText(email);
    await $.pumpAndSettle();
    await $(TextField).at(1).enterText(password);
    await $.pumpAndSettle();
    await $('Iniciar sesión').tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Permiso de ubicación tras login (Home carga mapa).
    if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
      await $.platformAutomator.mobile.grantPermissionWhenInUse();
      await $.pumpAndSettle();
    }
  }

  // Llegar aquí = sesión activa (login completado o sesión Firebase persistida).
  // 'EVENTOS' (mayúsculas) es único del bottom-nav; confirma que estamos en Home.
  await $('EVENTOS').waitUntilVisible(timeout: const Duration(seconds: 30));

  // El permiso de ubicación puede reaparecer al asentarse el Home.
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.pumpAndSettle();
  }
}
