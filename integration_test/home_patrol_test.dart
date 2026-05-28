// Patrol integration test: splash → login → Home screen content
//
// Cómo correr:
//   patrol test -t integration_test/home_patrol_test.dart \
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
    'login → home: usuario ve el dashboard principal',
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

      // 7. Handle location permission after login
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 8. Wait for bottom nav to confirm we're on Home.
      //    Home tab is ACTIVE so it shows the filled Icons.home (not Icons.home_outlined).
      //    The other tabs show their outlined variants since they are inactive.
      //    Use Icons.directions_car_outlined (garage tab — inactive) as the sentinel
      //    that the bottom nav is rendered.
      await $(Icons.directions_car_outlined).waitUntilVisible(
        timeout: const Duration(seconds: 10),
      );

      // 9. Wait for HomeHeader to load data from API
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // 10. Handle location permission a final time if it appears after data loads
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 11. Verify HomeHeader greeting — always present (shows "HOLA, RIDER" uppercase
      //     when user has no fullName, or the user's name otherwise).
      //     home_greeting = "Hola, Rider" → rendered toUpperCase() = "HOLA, RIDER"
      final hasGreeting = $('HOLA, RIDER').exists;

      // 12. Verify bottom nav tabs are present — active home shows Icons.home (filled),
      //     other tabs show outlined variants.
      final hasActiveHomeTab = $(Icons.home).exists;
      final hasGarageTab = $(Icons.directions_car_outlined).exists;
      final hasEventsTab = $(Icons.calendar_today_outlined).exists;
      final hasProfileTab = $(Icons.person_outline).exists;

      expect(
        hasActiveHomeTab || hasGarageTab || hasEventsTab || hasProfileTab,
        isTrue,
        reason: 'La barra de navegación inferior debe mostrar los tabs',
      );

      // 13. The home page body shows either loading, or garage + events sections.
      //     After settle, we expect at least the greeting or one of the sections.
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      final hasSectionGarage = $('MI GARAJE').exists;
      final hasSectionEvents = $('PRÓXIMAS RODADAS').exists;
      final hasViewAll = $('VER TODAS').exists;

      // Home is considered loaded if greeting appears OR any section is visible
      expect(
        hasGreeting ||
            hasSectionGarage ||
            hasSectionEvents ||
            hasViewAll,
        isTrue,
        reason:
            'El home debe mostrar el saludo o las secciones de garaje/eventos',
      );
    },
  );
}
