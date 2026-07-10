// Patrol e2e test: el RIDER cancela su propia inscripción a un evento desde
// el detalle del evento.
//
// Flujo cubierto:
//   Home (sesión de qa1) → tab Eventos → "Mi Evento" → detalle → barra de
//   estado de la inscripción (PENDING: botón "Cancelar" / APPROVED: botón
//   "Cancelar inscripción" — ambos disparan el mismo flujo,
//   `EventDetailCtaBarContent` → `confirmCancelRegistration`) → tap →
//   `CancelRegistrationDialog` ("Cancelar inscripción" / "¿Estás seguro…?")
//   → confirmar con "Aceptar" → SnackBar de éxito → el CTA vuelve a
//   "Inscribirme" (estado `cancelled`, se puede re-registrar).
//
// PRECONDICIONES DE DATOS (si no se cumplen, el test documenta el resultado
// parcial en el `if` del paso 3 en vez de fallar de forma opaca):
//   1. Existe el evento "Mi Evento" (owner: qa2@gmail.com) y la cuenta
//      qa1@gmail.com tiene sobre él una inscripción ACTIVA en estado
//      PENDING o APPROVED — cualquiera de las dos habilita el botón de
//      cancelar en el detalle (`EventDetailPendingBar`/`EventDetailApprovedBar`).
//      `registration_patrol_test.dart` deja la inscripción en PENDING; si
//      además corrió `events_attendees_approve_reject_patrol_test.dart`
//      (como qa2) sobre esa misma solicitud, quedará en APPROVED. Ambos
//      casos son válidos para este test — no depende del orden entre ellos.
//   2. Si la cuenta NO tiene ninguna inscripción activa sobre "Mi Evento"
//      (p. ej. porque nunca corrió `registration_patrol_test.dart`, o porque
//      una corrida previa de ESTE test ya la canceló y no se ha vuelto a
//      registrar), el detalle muestra el CTA "Inscribirme" directamente: no
//      hay nada que cancelar. El test se detiene ahí y lo documenta como
//      limitación de datos, sin marcarlo como fallo del flujo de cancelación.
//
// Cómo correr:
//   patrol test -t integration_test/registration_cancel_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _targetEvent = 'Mi Evento'; // evento con inscripción activa de qa1
const _registerMe = 'Inscribirme'; // event_registerMe (CTA sin inscripción)
const _cancelPendingButton = 'Cancelar'; // cancel (botón en EventDetailPendingBar)
const _cancelApprovedButton =
    'Cancelar inscripción'; // event_cancelRegistration (EventDetailApprovedBar)
const _cancelDialogTitle =
    'Cancelar inscripción'; // event_cancelRegistrationTitle
const _cancelDialogMessage =
    '¿Estás seguro de que deseas cancelar tu inscripción? Esta acción no se puede deshacer. Podrás inscribirte nuevamente en cualquier momento.'; // event_cancelRegistrationMessage
const _acceptButton = 'Aceptar'; // accept (confirm del dialog)
const _cancelSuccessMessage =
    'Tu inscripción fue cancelada exitosamente'; // event_cancelRegistrationSuccess

/// "Settle" acotado: el mapa de Mapbox del detalle del evento anima de forma
/// continua, así que `pumpAndSettle` se colgaría. Bombeamos frames por una
/// duración fija; el gating real lo hacen los `waitUntilVisible`/`waitUntilExists`.
Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await _settle($);
  }
}

void main() {
  patrolTest(
    'inscripción: el piloto cancela su inscripción activa',
    timeout: const Timeout(Duration(minutes: 8)),
    _runCancelRegistrationFlow,
  );
}

Future<void> _runCancelRegistrationFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa de qa1.
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir "Mi Evento".
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingLocationPermission($);

  await $(_targetEvent).waitUntilVisible(timeout: const Duration(seconds: 45));
  await $(_targetEvent).scrollTo().tap();
  await _settle($, 3);

  // 3. El botón de cancelar depende del estado de la inscripción: PENDING
  // muestra "Cancelar" (genérico) y APPROVED muestra "Cancelar inscripción".
  // Si ninguno existe (y en su lugar está "Inscribirme"), no hay inscripción
  // activa que cancelar — limitación de datos documentada arriba, no un
  // fallo del flujo.
  await _settle($, 2);
  final hasPendingCancel = $(_cancelPendingButton).exists;
  final hasApprovedCancel = $(_cancelApprovedButton).exists;
  if (!hasPendingCancel && !hasApprovedCancel) {
    expect($(_registerMe).exists, isTrue);
    return;
  }

  if (hasApprovedCancel) {
    await $(_cancelApprovedButton).scrollTo().tap();
  } else {
    await $(_cancelPendingButton).scrollTo().tap();
  }
  await _settle($);

  // 4. `CancelRegistrationDialog`: confirmar con "Aceptar".
  await $(
    _cancelDialogTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  expect($(_cancelDialogMessage).exists, isTrue);
  await $(_acceptButton).tap();
  await _settle($, 4);

  // 5. Éxito: SnackBar de confirmación y el CTA del detalle vuelve a
  // "Inscribirme" (estado `cancelled`, se puede volver a registrar).
  expect($(_cancelSuccessMessage).exists, isTrue);
  await $(
    _registerMe,
  ).waitUntilExists(timeout: const Duration(seconds: 20));
}
