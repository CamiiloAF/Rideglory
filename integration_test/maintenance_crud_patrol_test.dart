// Patrol e2e test: CRUD completo de un registro de mantenimiento.
//
// Flujo cubierto:
//   Home → tab Perfil → "Mantenimientos" (sin vehículo específico → la página
//   usa el vehículo principal del usuario) → botón "+" → wizard de tipo
//   (grid de 8 tipos, "Cambio de aceite") → "Continuar" → formulario
//   (modo "Completado" por defecto): kilometraje + taller + notas →
//   "Guardar Registro" → el nuevo registro aparece en la lista.
//   → tap sobre el registro → detalle (`MaintenanceDetailPage`) → "Editar"
//   → cambia las notas → "Guardar Registro" → el detalle refleja el cambio.
//   → "Eliminar" en el detalle → `ConfirmationDialog` ("Eliminar") →
//   confirmar → vuelve a la lista y el registro ya no aparece.
//
// PRECONDICIONES DE DATOS (la cuenta de prueba debe cumplirlas o el test
// falla con un timeout claro en el paso correspondiente):
//   1. La cuenta tiene AL MENOS UN vehículo NO archivado — `MaintenancesPage`,
//      al entrarse sin `initialVehicleId` (como aquí, desde el menú de
//      Perfil), usa `VehicleCubit.currentVehicle` como vehículo por
//      defecto para poder crear/listar mantenimientos. Si la cuenta no
//      tiene vehículos, el botón "+" seguirá existiendo pero el formulario
//      no tendrá un vehículo preseleccionado y el flujo puede comportarse
//      distinto (fuera del alcance de este test).
//   2. El kilometraje "321" usado como marcador del registro creado NO debe
//      coincidir por azar con el de otro mantenimiento ya existente del
//      mismo vehículo (extremadamente improbable, pero si el test empieza
//      a fallar de forma intermitente por colisión de texto, subir el
//      valor o añadir un sufijo aleatorio).
//
// Cómo correr:
//   patrol test -t integration_test/maintenance_crud_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _profileTabIcon = Icons.person_outline;
const _profileTitle = 'Mi perfil'; // AppBar de ProfilePage
const _menuMaintenances = 'Mantenimientos'; // profile_maintenances
const _maintenancesTitle = 'Mantenimientos'; // maintenance_maintenances (AppBar)
const _selectTypeStep =
    'Selecciona el tipo de mantenimiento'; // maintenance_form_step_select
const _oilChangeType = 'Cambio de aceite'; // MaintenanceType.oilChange.label
const _continueStep = 'Continuar'; // maintenance_form_step_continue
const _saveMaintenance = 'Guardar Registro'; // maintenance_saveMaintenance
const _maintenanceDetailTitle =
    'Detalle de mantenimiento'; // maintenance_maintenanceDetail
const _editCta = 'Editar'; // edit (CTA bar del detalle)
const _deleteCta = 'Eliminar'; // delete (CTA bar del detalle + confirm dialog)

// Marcador único del registro creado en este test: un kilometraje < 1000 se
// formatea SIN separador de miles (`NumberFormat('#,###')`), así que el texto
// "321 km" no depende del locale y sirve como ancla estable para encontrar la
// tarjeta recién creada en la lista. La tarjeta arma un solo `Text` con el
// string completo ("Realizado el <fecha> · 321 km",
// `maintenance_grouped_list_item.dart:114`), así que hay que buscar por
// substring (`find.textContaining`), no por texto exacto.
const _mileageMarker = '321';
const _mileageMarkerLabel = '$_mileageMarker km';
final _mileageMarkerFinder = find.textContaining(_mileageMarkerLabel);
const _workshop = 'Taller QA Patrol';
const _notesOriginal = 'Nota de mantenimiento QA Patrol - creación';
const _notesEdited = 'Nota de mantenimiento QA Patrol - EDITADA';

/// "Settle" acotado: algunas pantallas de este flujo (detalle de evento en
/// otros tests) animan de forma continua y cuelgan `pumpAndSettle`. Por
/// consistencia con el resto de la suite usamos el mismo patrón de
/// delay-real + un solo pump; el gating real lo hacen los
/// `waitUntilVisible`/`waitUntilExists`.
Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

void main() {
  patrolTest(
    'mantenimiento: crear, editar y eliminar un registro',
    timeout: const Timeout(Duration(minutes: 8)),
    _runMaintenanceCrudFlow,
  );
}

Future<void> _runMaintenanceCrudFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa.
  await bootstrapSession($);

  // 2. Ir al tab Perfil y abrir "Mantenimientos".
  await $(_profileTabIcon).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 45));

  await $(_profileTitle).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(_menuMaintenances).waitUntilExists(
    timeout: const Duration(seconds: 20),
  );
  await $(_menuMaintenances).scrollTo().tap();
  await _settle($, 3);

  await $(
    _maintenancesTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 30));

  // 3. CREAR: botón "+" del AppBar abre el wizard de tipo de mantenimiento.
  await $(Icons.add).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(Icons.add).tap();
  await _settle($);

  await $(
    _selectTypeStep,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_oilChangeType).tap();
  await _settle($);
  await $(_continueStep).tap();
  await _settle($, 3);

  // 4. Formulario en modo "Completado" (default). Solo se completan los
  // campos mínimos: kilometraje (requerido), taller y notas (marcadores
  // para las verificaciones posteriores). El campo de fecha ya viene
  // precargado con la fecha de hoy — no se toca.
  //
  // Orden de los `TextField` en el árbol de `MaintenanceFormContent`:
  //   0 = fecha de servicio (precargada, se omite)
  //   1 = kilometraje actual (`currentMileage`, requerido)
  //   2 = costo total (opcional, se omite)
  //   3 = taller / mecánico
  //   4 = notas / observaciones
  await $(TextField).at(1).enterText(_mileageMarker);
  await _settle($);
  await $(TextField).at(3).enterText(_workshop);
  await _settle($);
  await $(TextField).at(4).scrollTo().enterText(_notesOriginal);
  await _settle($);

  await $(_saveMaintenance).scrollTo().tap();
  await _settle($, 4);

  // 5. De vuelta en la lista: el nuevo registro aparece con el marcador de
  // kilometraje único. El refetch tras guardar puede tardar más de 20s en
  // el emulador (backend local + reconstrucción de la lista), por eso el
  // timeout es más generoso que el resto de las esperas de este archivo.
  await $(
    _mileageMarkerFinder,
  ).waitUntilVisible(timeout: const Duration(seconds: 45));

  // 6. Abrir el detalle del registro recién creado.
  await $(_mileageMarkerFinder).scrollTo().tap();
  await _settle($, 3);

  await $(
    _maintenanceDetailTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_workshop).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_notesOriginal).waitUntilVisible(timeout: const Duration(seconds: 10));

  // 7. EDITAR: CTA "Editar" del detalle abre el formulario precargado.
  await $(_editCta).tap();
  await _settle($, 3);

  // Mismo orden de campos que en creación (modo completado, precargado).
  await $(TextField).at(4).scrollTo().enterText(_notesEdited);
  await _settle($);
  await $(_saveMaintenance).scrollTo().tap();
  await _settle($, 4);

  // 8. El detalle refleja las notas editadas (sin volver a navegar: el
  // listener de `MaintenanceDetailView` actualiza el estado local con el
  // resultado del pop del formulario).
  await $(
    _maintenanceDetailTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_notesEdited).waitUntilVisible(timeout: const Duration(seconds: 15));
  expect($(_notesOriginal).exists, isFalse);

  // 9. ELIMINAR: CTA "Eliminar" del detalle → `ConfirmationDialog` apilado
  // sobre la página (el botón de confirmación queda al final del árbol,
  // igual que en `events_attendees_approve_reject_patrol_test.dart`).
  await $(_deleteCta).tap();
  await _settle($);
  await $(_deleteCta).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_deleteCta).last.tap();
  await _settle($, 4);

  // 10. De vuelta en la lista: el registro eliminado ya no aparece.
  await $(
    _maintenancesTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await _settle($, 2);
  expect($(_mileageMarkerFinder).exists, isFalse);
}
