// Patrol integration test: splash → login → Events tab
//
// Cómo correr:
//   patrol test -t integration_test/events_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=usuario2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/main.dart' as app;

// ignore: do_not_use_environment
const _testEmail = String.fromEnvironment(
  'TEST_EMAIL',
  defaultValue: 'tu_email@ejemplo.com',
);
// ignore: do_not_use_environment
const _testPassword = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: 'tu_password',
);

void main() {
  patrolTest(
    'login → events: usuario ve la pantalla de eventos',
    timeout: const Timeout(Duration(minutes: 7)),
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Firebase Auth puede persistir la sesión en el Account Manager de Android
      // incluso tras reinstalar el APK (patrol test --uninstall). Por eso el
      // splash puede navegar al Home (sesión activa) o al Login (sin sesión).
      // Loop de 24 × 5s = 120s: maneja el diálogo de permiso y detecta cualquiera
      // de los dos destinos.
      var _onLogin = false;
      var _onHome = false;
      for (var _i = 0; _i < 24 && !_onLogin && !_onHome; _i++) {
        await Future.delayed(const Duration(seconds: 5));
        if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
          await $.platformAutomator.mobile.grantPermissionWhenInUse();
          await $.pumpAndSettle();
        }
        _onLogin = $(TextField).exists;
        _onHome = $('EVENTOS').exists; // bottom nav visible = ya en home
      }

      if (_onLogin) {
        // Flujo login normal
        await $(TextField).at(0).enterText(_testEmail);
        await $.pumpAndSettle();
        await $(TextField).at(1).enterText(_testPassword);
        await $.pumpAndSettle();
        await $('Iniciar sesión').tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 20));

        // Permiso de ubicación tras login (Home carga mapa)
        if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
          await $.platformAutomator.mobile.grantPermissionWhenInUse();
          await $.pumpAndSettle();
        }
      }

      // Llegar aquí = sesión activa (login completado o sesión Firebase persistida)
      // 'EVENTOS' (mayúsculas) es único del bottom-nav; evita tocar el icono
      // decorativo de HomeEmptyEventsCard.
      await $('EVENTOS').waitUntilVisible(
        timeout: const Duration(seconds: 30),
      );
      await $('EVENTOS').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // 9. Handle location permission if it appears on Events tab
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 10. Handle location permission if it appears again after events page loads
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 11. Wait for the Events screen to render (header or content state).
      //     pumpAndSettle alone no es suficiente para esperar la respuesta HTTP,
      //     así que esperamos el título con un timeout explícito.
      //     Note: "EVENTOS" tab label is intentionally excluded — it is always visible
      //     in the bottom nav regardless of whether the Events page actually loaded.
      await $('Eventos').waitUntilVisible(
        timeout: const Duration(seconds: 45),
      );
    },
  );
}
