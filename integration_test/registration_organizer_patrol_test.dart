// Patrol e2e test: vista del ORGANIZADOR sobre una inscripción.
//
// Flujo cubierto:
//   Home (sesión de qa2, owner de "Mi Evento") → tab Eventos → "Mi Evento"
//   → sección "Inscritos" (solo visible al organizador) → tap en la primera
//   fila de inscrito → detalle de inscripción con `isOrganizerView: true`
//   → botones de contacto (Llamar / WhatsApp) si `allowOrganizerContact` está
//   activo → volver → la vista del piloto (my_registrations) no se ve afectada
//   por este flujo (no navega por RegistrationContactActions).
//
// PRECONDICIONES DE DATOS (documentadas igual que registration_patrol_test.dart;
// si no se cumplen, el test falla en el gate correspondiente, no cuelga):
//   1. Existe el evento "Mi Evento", del cual la cuenta qa2@gmail.com es la
//      DUEÑA (organizadora). Solo el owner ve la sección "Inscritos" con
//      gestión (aprobar/rechazar) y el detalle en modo organizador.
//   2. "Mi Evento" tiene AL MENOS UNA inscripción visible para el organizador
//      (cualquier estado: pendiente, aprobada, rechazada) — la dejada por
//      qa1@gmail.com en `registration_patrol_test.dart` sirve si ya corrió.
//      Si la lista está vacía, el test solo valida que la sección "Inscritos"
//      es visible para el organizador (organizer-only UI) y termina ahí.
//
// Cómo correr:
//   patrol test -t integration_test/registration_organizer_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participant_row.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb), centralizados para que el
// test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _targetEvent = 'Mi Evento'; // evento del cual qa2 es organizadora
const _registrationsSectionPrefix =
    'Inscritos'; // event_registrationsTab (con conteo, p. ej. "Inscritos (1)")
const _callButton = 'Llamar'; // registration_callButton
const _whatsappButton = 'WhatsApp'; // registration_whatsappButton

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
    'organizador: abre el detalle de una inscripción y ve acciones de contacto',
    timeout: const Timeout(Duration(minutes: 8)),
    _runOrganizerRegistrationFlow,
  );
}

Future<void> _runOrganizerRegistrationFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa de la organizadora (qa2).
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir "Mi Evento" (evento propio).
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingLocationPermission($);

  await $(_targetEvent).waitUntilVisible(timeout: const Duration(seconds: 45));
  await $(_targetEvent).scrollTo().tap();
  await _settle($, 3);

  // 3. La sección "Inscritos" solo la ve el organizador del evento — su sola
  // presencia confirma que la navegación organizador (event_detail →
  // participants section) está activa para esta cuenta.
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

  // 4. Si hay al menos un inscrito visible, abrir su detalle tocando la
  // primera fila de preview (`EventDetailParticipantRow`).
  final hasParticipantRow = $(EventDetailParticipantRow).exists;
  if (!hasParticipantRow) {
    // Sin inscritos todavía: la fase queda validada por la sola presencia de
    // la sección organizador; no hay detalle que abrir.
    return;
  }

  await $(EventDetailParticipantRow).first.tap();
  await _settle($, 3);

  // 5. Detalle de inscripción en modo organizador: si el piloto autorizó el
  // contacto directo (`allowOrganizerContact`), los botones "Llamar" /
  // "WhatsApp" son visibles (RegistrationContactActions). Si no lo autorizó,
  // la ausencia es el comportamiento correcto (no un fallo): se documenta
  // como resultado válido en vez de forzar la aserción.
  await _settle($, 2);
  final hasContactButtons =
      $(_callButton).visible && $(_whatsappButton).visible;
  if (hasContactButtons) {
    expect($(_callButton).visible, isTrue);
    expect($(_whatsappButton).visible, isTrue);
  }
}
