// Patrol e2e test: inscripción completa a un evento.
//
// Flujo cubierto:
//   Home → tab Eventos → primer evento → detalle → "Inscribirme"
//   → wizard de 4 pasos (Personal → Médico → Emergencia → Vehículo)
//   → sheet consentimiento Ley 1581 ("Autorizar") al salir de Médico
//   → selección de vehículo → "Confirmar Inscripción"
//   → sheet waiver de riesgos ("Entiendo, inscribirme")
//   → SnackBar de éxito.
//
// PRECONDICIONES DE DATOS (la cuenta de prueba debe cumplirlas o el test falla
// con un timeout claro en el paso correspondiente, no cuelga):
//   1. Existe al menos un evento ABIERTO en la lista (estado programado) para el
//      cual el usuario NO es organizador y NO está ya inscrito — solo así el
//      detalle muestra el botón "Inscribirme".
//   2. El perfil del piloto (rider profile) está COMPLETO: nombre, cédula,
//      fecha de nacimiento (≥18), teléfono, correo, ciudad, EPS, tipo de sangre
//      y contacto de emergencia. El wizard precarga estos campos, así que los
//      pasos avanzan sin necesidad de teclear. Si algún requerido está vacío, el
//      "Siguiente" no avanza y el test falla en el gate siguiente.
//   3. La cuenta tiene al menos UN vehículo (no archivado) cuya marca está
//      permitida por el evento.
//
// Cómo correr (NO usar mientras el emulador esté ocupado con debug):
//   patrol test -t integration_test/registration_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=usuario2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para que
// el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _registerMe = 'Inscribirme'; // event_registerMe (barra de detalle)
const _registrationTitle =
    'Inscripción al Evento'; // registration_registrationPageTitle
const _nextStep = 'Siguiente'; // registration_nextStep
const _authorizeConsent = 'Autorizar'; // registration_law1581_authorizeButton
const _medicalStepTitle = 'Información Médica'; // registration_stepMedicalTitle
const _emergencyStepTitle =
    'Contacto de Emergencia'; // registration_stepEmergencyTitle
const _vehicleStepTitle =
    'Vehículo de Inscripción'; // registration_stepVehicleTitle
const _selectVehicle =
    'Selecciona tu vehículo'; // registration_selectVehiclePlaceholder
const _finishRegistration =
    'Confirmar Inscripción'; // registration_finishRegistration
const _acceptWaiver = 'Entiendo, inscribirme'; // registration_waiverCtaButton
const _success =
    'Inscripción enviada exitosamente. Está pendiente de aprobación.'; // registration_registrationSentSuccess

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.pumpAndSettle();
  }
}

void main() {
  patrolTest(
    'inscripción: usuario completa el wizard y ve el éxito',
    timeout: const Timeout(Duration(minutes: 8)),
    ($) async {
      // 1. App lista en Home con sesión activa.
      await bootstrapSession($);

      // 2. Ir al tab Eventos y abrir el primer evento de la lista.
      await $(_tabEventos).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));
      await _grantPendingLocationPermission($);

      await $(EventCard).waitUntilVisible(timeout: const Duration(seconds: 45));
      await $(EventCard).first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // 3. Abrir la inscripción desde el detalle.
      await $(
        _registerMe,
      ).waitUntilVisible(timeout: const Duration(seconds: 20));
      await $(_registerMe).scrollTo().tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // 4. Paso Personal (precargado del rider profile). Avanzar.
      await $(
        _registrationTitle,
      ).waitUntilVisible(timeout: const Duration(seconds: 20));
      await $(_nextStep).tap();
      await $.pumpAndSettle();

      // 5. Paso Médico → "Siguiente" dispara el sheet de consentimiento Ley 1581.
      await $(
        _medicalStepTitle,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_nextStep).tap();
      await $.pumpAndSettle();

      await $(
        _authorizeConsent,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_authorizeConsent).tap();
      await $.pumpAndSettle();

      // 6. Paso Emergencia (precargado). Avanzar.
      await $(
        _emergencyStepTitle,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_nextStep).tap();
      await $.pumpAndSettle();

      // 7. Paso Vehículo: abrir el selector y elegir el primer vehículo.
      await $(
        _vehicleStepTitle,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_selectVehicle).tap();
      await $.pumpAndSettle();
      // El bottom sheet lista los vehículos; toca el primero.
      await $(ListView).$(GestureDetector).first.tap();
      await $.pumpAndSettle();

      // 8. Confirmar → abre el waiver de riesgos → aceptar e inscribirse.
      await $(
        _finishRegistration,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_finishRegistration).tap();
      await $.pumpAndSettle();

      await $(
        _acceptWaiver,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
      await $(_acceptWaiver).tap();
      await $.pumpAndSettle();

      // 9. SnackBar de éxito (la inscripción viaja al backend; timeout amplio).
      await $(_success).waitUntilVisible(timeout: const Duration(seconds: 30));
    },
  );
}
