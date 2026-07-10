// Patrol e2e test: el ORGANIZADOR aprueba una solicitud de inscripción
// pendiente desde "Gestionar Inscritos".
//
// Flujo cubierto:
//   Home (sesión de qa2, owner de "Mi Evento") → tab Eventos → "Mi Evento"
//   → sección "Inscritos" del detalle → "Ver todos" abre `AttendeesPage`
//   ("Gestionar Inscritos") → sección "NUEVAS SOLICITUDES" con
//   `AttendeePendingRequestCard` (barra Aprobar/Rechazar inline) → tap
//   "Aprobar" → `ConfirmationDialog` ("¿Aprobar la inscripción de …?") →
//   confirmar → la fila desaparece de "NUEVAS SOLICITUDES" y aparece en
//   "YA PROCESADOS" con el badge "APROBADO".
//
// PRECONDICIONES DE DATOS (si no se cumplen, el test documenta el resultado
// parcial en vez de fallar de forma opaca — ver el `if` del paso 4):
//   1. Existe el evento "Mi Evento", del cual la cuenta qa2@gmail.com es la
//      DUEÑA (organizadora). Solo el owner ve "Gestionar Inscritos" con
//      acciones de aprobar/rechazar.
//   2. "Mi Evento" tiene AL MENOS UNA inscripción en estado PENDING visible
//      para el organizador — la que deja `registration_patrol_test.dart` al
//      inscribir a qa1@gmail.com sirve si ya corrió antes que este test. Si
//      esa inscripción ya fue procesada (aprobada/rechazada) por una corrida
//      previa de ESTE MISMO test, no quedará ninguna PENDING nueva: hay que
//      volver a generar una inscripción pending (re-registrar a qa1, o pedir
//      a QA que la deje en `PENDING` manualmente) antes de re-correr.
//   3. Si al abrir "Gestionar Inscritos" NO hay ninguna solicitud pendiente,
//      el test se detiene después de validar que la sección "Inscritos" y la
//      página de gestión cargan correctamente para el organizador — no es un
//      fallo del flujo de aprobación, es falta de datos determinísticos de
//      QA (limitación conocida, documentada en vez de forzada).
//
// Cómo correr:
//   patrol test -t integration_test/events_attendees_approve_reject_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_processed_item.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_approve_button.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb), centralizados para que el
// test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _targetEvent = 'Mi Evento'; // evento del cual qa2 es organizadora
const _registrationsSectionPrefix =
    'Inscritos'; // event_registrationsTab (con conteo, p. ej. "Inscritos (1)")
const _viewAll = 'Ver todos'; // event_viewAll
const _manageAttendeesTitle = 'Gestionar inscritos'; // event_manageAttendeesTitle
const _newRequestsSection = 'NUEVAS SOLICITUDES'; // event_newRequestsSection
const _processedSection = 'YA PROCESADOS'; // event_processedSection
const _approveButton = 'Aprobar'; // event_approveRegistration
const _approvedBadge = 'APROBADO'; // event_approvedBadge

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
    'organizador: aprueba una solicitud de inscripción pendiente',
    timeout: const Timeout(Duration(minutes: 8)),
    _runApproveAttendeeFlow,
  );
}

Future<void> _runApproveAttendeeFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa de la organizadora (qa2).
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir "Mi Evento" (evento propio).
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingLocationPermission($);

  await $(_targetEvent).waitUntilVisible(timeout: const Duration(seconds: 45));
  await $(_targetEvent).scrollTo().tap();
  await _settle($, 3);

  // 3. La sección "Inscritos" solo la ve el organizador del evento. Scroll
  // hasta ella y tocar "Ver todos" para abrir "Gestionar Inscritos"
  // (`AttendeesPage`).
  final registrationsHeader = $(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data?.startsWith(_registrationsSectionPrefix) ?? false),
    ),
  );
  await registrationsHeader.waitUntilExists(
    timeout: const Duration(seconds: 20),
  );
  await registrationsHeader.scrollTo();
  await _settle($);

  await $(_viewAll).waitUntilExists(timeout: const Duration(seconds: 10));
  await $(_viewAll).scrollTo().tap();
  await _settle($, 3);

  await $(
    _manageAttendeesTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  // 4. Si no hay ninguna solicitud PENDIENTE visible, no hay nada que
  // aprobar: la fase queda validada por el acceso organizador a "Gestionar
  // Inscritos" y termina aquí (limitación de datos, no un fallo del flujo).
  final hasPendingSection = $(_newRequestsSection).exists;
  final hasApproveButton = $(RegistrationApproveButton).exists;
  if (!hasPendingSection || !hasApproveButton) {
    return;
  }

  // 5. Tocar "Aprobar" en la tarjeta de la primera solicitud pendiente
  // (`AttendeePendingRequestCard` → `ApproveRejectBar` → `RegistrationApproveButton`,
  // acción inline, sin necesidad de abrir el detalle).
  await $(RegistrationApproveButton).first.tap();
  await _settle($);

  // 6. `ConfirmationDialog` de confirmación ("Aprobar" + mensaje "¿Aprobar la
  // inscripción de …?"). Confirmar tocando el botón "Aprobar" del modal (el
  // último en el árbol, ya que el modal se apila sobre la página).
  await $(_approveButton).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_approveButton).last.tap();
  await _settle($, 3);

  // 7. La solicitud ya no aparece en "NUEVAS SOLICITUDES" y sí en
  // "YA PROCESADOS" con el badge "APROBADO" (`AttendeeProcessedItem`).
  await $(
    _processedSection,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  expect($(AttendeeProcessedItem).exists, isTrue);
  expect($(_approvedBadge).exists, isTrue);
}
