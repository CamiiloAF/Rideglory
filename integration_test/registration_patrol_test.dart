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
//   1. Existe el evento "Mi Evento" (programado) en la lista, para el cual el
//      usuario NO es organizador y NO está ya inscrito — solo así el detalle
//      muestra el botón "Inscribirme". (owner: qa2@gmail.com; inscribe: qa1.)
//   2. El perfil del piloto (rider profile) está COMPLETO: nombre, cédula,
//      fecha de nacimiento (≥18), teléfono, correo, ciudad, EPS, tipo de sangre
//      y contacto de emergencia. El wizard precarga estos campos, así que los
//      pasos avanzan sin necesidad de teclear. Si algún requerido está vacío, el
//      "Siguiente" no avanza y el test falla en el gate siguiente.
//   3. La cuenta tiene al menos UN vehículo (no archivado) cuya marca está
//      permitida por el evento.
//
// Cómo correr:
//   patrol test -t integration_test/registration_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_bootstrap.dart';

// NOTA sobre Mapbox: el preview de mapa del detalle del evento (`RouteMapPreview`)
// dispara un `flyTo` que quedaba en vuelo al navegar al wizard, lanzando una
// `PlatformException` async NO capturada que tumbaba este test (aunque el flujo
// funcionara). NO se silencia desde aquí a propósito: silenciar un error async
// no capturado dispara el `assert` de `flutter_test` en `handleUncaughtError`
// (binding.dart ~1018). El fix correcto vive en la app: `RouteMapPreview` ahora
// captura el cierre del canal en `_guardMapCamera`. Si este test vuelve a fallar
// por un error de Mapbox, es una regresión de ese guard, no algo a ocultar aquí.

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para que
// el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _targetEvent = 'Mi Evento'; // evento programado que qa1 puede inscribir
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
// Estado ESTABLE post-éxito: al inscribirse, la página vuelve al detalle y el
// CTA pasa a la barra "pendiente de revisión". Preferimos este marcador
// persistente al SnackBar de éxito, que muere con el `pop` inmediato de la
// página de inscripción y es imposible de capturar de forma confiable.
const _registrationPending =
    'Tu solicitud está siendo revisada por el organizador.'; // event_requestUnderReview

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await _settle($);
  }
}

/// "Settle" acotado: NUNCA espera a que el árbol quede inactivo. El mapa de
/// Mapbox (detalle/eventos) anima de forma continua (flyTo), así que
/// `pumpAndSettle` se colgaría esperando frames que nunca dejan de llegar. En su
/// lugar bombeamos frames por una duración fija; el gating real (esperar que
/// aparezca el paso/sheet siguiente) lo hacen los `waitUntilVisible`/`waitUntilExists`.
Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  // Delay de tiempo real (no depende del reloj del binding) + UN solo pump. A
  // diferencia de `pump(duration)` en el binding live, esto NUNCA se bloquea
  // aunque el mapa de Mapbox anime sin parar; y a diferencia de `pumpAndSettle`,
  // no espera a que el árbol quede inactivo.
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

void main() {
  patrolTest(
    'inscripción: usuario completa el wizard y ve el éxito',
    timeout: const Timeout(Duration(minutes: 8)),
    _runRegistrationFlow,
  );
}

Future<void> _runRegistrationFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa.
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir "Mi Evento" (programado, no inscrito).
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingLocationPermission($);

  // La tarjeta de "Mi Evento" puede quedar fuera del viewport inicial según
  // su posición en la lista (ordenada por fecha) — igual que el CTA
  // "Inscribirme" más abajo, esperamos EXISTENCIA (no visibilidad en
  // pantalla) y dejamos que scrollTo() la traiga a vista.
  await $(_targetEvent).waitUntilExists(timeout: const Duration(seconds: 45));
  await $(_targetEvent).scrollTo().tap();
  await _settle($, 3);

  // 3. Abrir la inscripción desde el detalle. Para un usuario NO-owner el
  // CTA "Inscribirme" va EMBEBIDO dentro del CustomScrollView (no es una
  // bottomNavigationBar fija), así que existe pero fuera del viewport:
  // esperamos a que exista y hacemos scrollTo para traerlo a pantalla.
  await $(_registerMe).waitUntilExists(timeout: const Duration(seconds: 20));
  await $(_registerMe).scrollTo().tap();
  await _settle($, 3);

  // 4. Paso Personal (precargado del rider profile). Avanzar.
  await $(
    _registrationTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_nextStep).tap();
  await _settle($);

  // 5. Paso Médico → "Siguiente" dispara el sheet de consentimiento Ley 1581.
  await $(
    _medicalStepTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_nextStep).tap();
  await _settle($);

  await $(
    _authorizeConsent,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_authorizeConsent).tap();
  await _settle($);

  // 6. Paso Emergencia (precargado). Avanzar.
  await $(
    _emergencyStepTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_nextStep).tap();
  await _settle($);

  // 7. Paso Vehículo: abrir el selector y elegir el primer vehículo.
  await $(
    _vehicleStepTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_selectVehicle).tap();
  await _settle($);
  // El bottom sheet lista los vehículos; toca el primero.
  await $(ListView).$(GestureDetector).first.tap();
  await _settle($);

  // 8. Confirmar → abre el waiver de riesgos → aceptar e inscribirse.
  await $(
    _finishRegistration,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_finishRegistration).tap();
  await _settle($);

  await $(_acceptWaiver).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_acceptWaiver).tap();
  await _settle($);

  // 9. Éxito: la página de inscripción hace pop y el detalle del evento
  // muestra el CTA "pendiente de revisión" para qa1. Va embebido en el
  // scroll del detalle, así que basta con que EXISTA (timeout amplio porque
  // la inscripción viaja al backend antes de que el estado cambie).
  await $(
    _registrationPending,
  ).waitUntilExists(timeout: const Duration(seconds: 30));
}
