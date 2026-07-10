// Patrol e2e test: ver el perfil de OTRO rider desde la lista de asistentes
// de un evento.
//
// Flujo cubierto:
//   Home (sesión de qa2, owner de "Mi Evento") → tab Eventos → "Mi Evento" →
//   sección "Inscritos" (solo visible al organizador) → tap en la primera
//   fila de inscrito (`EventDetailParticipantRow`) → detalle de inscripción
//   en modo organizador (`RegistrationDetailPage`, `isOrganizerView: true`) →
//   tap en la banda de resumen del piloto (`RegistrationDetailRiderSummary`)
//   → `RiderProfilePage` del asistente (userId != el del organizador) →
//   verifica: título "Perfil del motorista", el email NO se muestra, y el
//   botón "Seguir" abre el bottom sheet informativo "Muy pronto" (no ejecuta
//   ninguna acción de follow real). Ver docs/features/users.md §3.3 y §9.
//
// Por qué se navega vía "Inscritos" → detalle → banda de resumen (dos saltos)
// en vez de un tap directo en la lista de asistentes: es la ruta real del
// código. `AttendeeProcessedItem`/`AttendeePendingRequestCard` (en
// `attendees_list.dart`, la pantalla completa de "Ver inscritos") navegan a
// `RegistrationDetailPage`, NUNCA directo a `riderProfile`. Solo
// `RegistrationDetailRiderSummary.onTap` (dentro del detalle, vista
// organizador) y `RiderListItem` (participantes del tracking en vivo)
// navegan a `AppRoutes.riderProfile`. Se reusa el preview embebido en el
// detalle del evento (`EventDetailParticipantRow`, igual que
// `registration_organizer_patrol_test.dart`) porque no depende de abrir la
// pantalla completa de asistentes.
//
// PRECONDICIONES DE DATOS (si no se cumplen, el test falla en el gate
// correspondiente, no cuelga):
//   1. Existe el evento "Mi Evento", del cual la cuenta qa2@gmail.com es la
//      DUEÑA (organizadora). Solo el owner ve la sección "Inscritos".
//   2. "Mi Evento" tiene AL MENOS UNA inscripción visible para el organizador
//      (cualquier estado), de un usuario DISTINTO a qa2 — la dejada por
//      qa1@gmail.com en `registration_patrol_test.dart` sirve si ya corrió.
//      Sin inscritos, el test falla en el gate del paso 4 (no hay fila que
//      tocar).
//
// Cómo correr:
//   patrol test -t integration_test/users_rider_profile_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participant_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_rider_summary.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _targetEvent = 'Mi Evento'; // evento del cual qa2 es organizadora
const _registrationsSectionPrefix =
    'Inscritos'; // event_registrationsTab (con conteo, p. ej. "Inscritos (1)")
const _riderProfileTitle = 'Perfil del motorista'; // rider_profileTitle
const _followButton = 'Seguir'; // rider_follow
const _followComingSoonTitle = 'Muy pronto'; // rider_followComingSoonTitle

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
    'perfil de rider: organizador ve el perfil de un asistente sin su email '
    'y el botón Seguir abre el sheet "Próximamente"',
    timeout: const Timeout(Duration(minutes: 8)),
    _runRiderProfileFlow,
  );
}

Future<void> _runRiderProfileFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa de la organizadora (qa2).
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir "Mi Evento" (evento propio).
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingLocationPermission($);

  await $(_targetEvent).waitUntilVisible(timeout: const Duration(seconds: 45));
  await $(_targetEvent).scrollTo().tap();
  await _settle($, 3);

  // 3. La sección "Inscritos" solo la ve el organizador del evento.
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

  // 4. Abrir el detalle de la primera fila de inscrito visible en el
  // preview (`EventDetailParticipantRow`). Precondición #2: debe existir al
  // menos una fila.
  await $(EventDetailParticipantRow).waitUntilExists(
    timeout: const Duration(seconds: 20),
  );
  // La fila puede quedar fuera del viewport (bajo el pliegue, cerca del
  // borde donde se dibuja `EventDetailOwnerLifecycleBar` fijo abajo) tras
  // centrar el header "Inscritos" en el paso anterior — se necesita
  // `.scrollTo()` antes del tap, mismo gotcha que en
  // `registration_organizer_patrol_test.dart`.
  await $(EventDetailParticipantRow).first.scrollTo().tap();
  await _settle($, 3);

  // 5. Detalle de inscripción en modo organizador: la banda de resumen del
  // piloto es tocable y navega al perfil público del asistente.
  await $(RegistrationDetailRiderSummary).waitUntilVisible(
    timeout: const Duration(seconds: 15),
  );
  await $(RegistrationDetailRiderSummary).tap();
  await _settle($, 3);

  // 6. `RiderProfilePage` del asistente (userId distinto al de la
  // organizadora logueada).
  await $(
    _riderProfileTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  // El email del asistente NO debe mostrarse en su perfil ajeno (commit
  // 6cbd85c, "ocultar email en perfil ajeno" — ver docs/features/users.md
  // §3.3 y §9). Cualquier email visible contendría un '@'.
  expect(
    find.textContaining('@'),
    findsNothing,
    reason:
        'El perfil de un rider ajeno no debe mostrar el email del usuario.',
  );

  // 7. El botón "Seguir" no ejecuta ninguna acción de follow/unfollow real:
  // solo abre un bottom sheet informativo "Próximamente".
  await $(_followButton).waitUntilVisible(
    timeout: const Duration(seconds: 10),
  );
  await $(_followButton).tap();
  await _settle($);

  await $(
    _followComingSoonTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
}
