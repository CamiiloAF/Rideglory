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
    timeout: const Timeout(Duration(minutes: 3)),
    ($) async {
      await app.main();
      await $.pumpAndSettle();

      // 1. Splash — handle location permission
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 2. Wait for login form (FormBuilderTextField renders TextField)
      await $(TextField).waitUntilVisible(
        timeout: const Duration(seconds: 15),
      );

      // 3. Handle location permission if it appears at login
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 4. Enter email
      await $(TextField).at(0).enterText(_testEmail);
      await $.pumpAndSettle();

      // 5. Enter password
      await $(TextField).at(1).enterText(_testPassword);
      await $.pumpAndSettle();

      // 6. Tap login button
      await $('Iniciar sesión').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 20));

      // 7. Handle location permission after login (Home loads map)
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 8. Wait for bottom nav to appear, then navigate to Events tab
      await $(Icons.calendar_today_outlined).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );
      await $(Icons.calendar_today_outlined).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // 9. Handle location permission if it appears on Events tab
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 10. Give the Events page time to navigate and load data from the API.
      //     pumpAndSettle with a generous timeout to let HTTP calls complete.
      await $.pumpAndSettle(timeout: const Duration(seconds: 20));

      // 11. Handle location permission if it appears again after events page loads
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 12. Verify Events screen loaded — the page header "Eventos" is always rendered
      //     as part of EventsPageView, regardless of data state.
      //     Also accept the empty state message or error icon as valid outcomes.
      //     Note: "EVENTOS" tab label is intentionally excluded — it is always visible
      //     in the bottom nav regardless of whether the Events page actually loaded.
      final hasPageTitle = $('Eventos').exists;
      final hasEmpty = $('No hay eventos disponibles').exists;
      final hasError = $(Icons.search_off_outlined).exists;

      expect(
        hasPageTitle || hasEmpty || hasError,
        isTrue,
        reason:
            'La pantalla de eventos debe mostrar el título de página o un estado de contenido',
      );
    },
  );
}
