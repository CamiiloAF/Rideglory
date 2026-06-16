// Patrol integration test: splash → location permission → login → garage
//
// Cómo correr:
//   patrol test -t integration_test/vehicles_patrol_test.dart \
//     --dart-define=TEST_EMAIL=tu@email.com \
//     --dart-define=TEST_PASSWORD=tupassword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
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
    'login → garage: usuario ve la pantalla de vehículos',
    timeout: const Timeout(Duration(minutes: 5)),
    ($) async {
      app.main();
      await $.pumpAndSettle();

      // Loop combinado: espera el formulario de login mientras maneja el diálogo
      // de permiso de ubicación que puede aparecer en cualquier momento durante
      // el splash. Firebase cold start puede tardar 30-60s en emuladores.
      var _loginFound = false;
      for (var _i = 0; _i < 18 && !_loginFound; _i++) {
        await Future.delayed(const Duration(seconds: 5));
        if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
          await $.platformAutomator.mobile.grantPermissionWhenInUse();
          await $.pumpAndSettle();
        }
        _loginFound = $(TextField).exists;
      }
      if (!_loginFound) {
        await $(TextField).waitUntilVisible(
          timeout: const Duration(seconds: 15),
        );
      }

      // 4. Llenar email (TextField en índice 0 = campo de correo)
      await $(TextField).at(0).enterText(_testEmail);
      await $.pumpAndSettle();

      // 5. Llenar contraseña (TextField en índice 1 = campo de contraseña)
      await $(TextField).at(1).enterText(_testPassword);
      await $.pumpAndSettle();

      // 6. Iniciar sesión
      await $('Iniciar sesión').tap();

      // Esperar que Firebase Auth responda y navegue a Home
      await $.pumpAndSettle(timeout: const Duration(seconds: 20));

      // 7. Permiso de ubicación en Home (puede pedirse al cargar el mapa)
      if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
        await $.platformAutomator.mobile.grantPermissionWhenInUse();
        await $.pumpAndSettle();
      }

      // 8. Home visible — esperar bottom nav y navegar a Garaje
      await $(Icons.directions_car_outlined).waitUntilVisible(
        timeout: const Duration(seconds: 30),
      );
      await $(Icons.directions_car_outlined).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 30));

      // 9. Verificar que la pantalla de garage cargó
      expect($(GaragePageView), findsOneWidget);

      // 10. Esperar que la API de vehículos responda (puede tardar unos segundos)
      //     Con vehículos → header "Mi Garaje"
      //     Sin vehículos → "No tienes vehículos registrados"
      await $.pumpAndSettle(timeout: const Duration(seconds: 45));

      final hasVehicles = $('Mi Garaje').exists;
      final isEmpty = $('No tienes vehículos registrados').exists;
      expect(
        hasVehicles || isEmpty,
        isTrue,
        reason: 'La pantalla del garaje debe mostrar vehículos o el estado vacío',
      );
    },
  );
}
