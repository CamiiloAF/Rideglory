// Patrol e2e test: marcar un vehículo existente como principal, archivarlo y
// desarchivarlo, todo desde `GarageOptionsBottomSheet`.
//
// Flujo cubierto (mismo vehículo durante las 3 acciones, ver
// docs/features/vehicles.md §4 `VehicleActionCubit` y §8 Archivado/borrado):
//   Home → tab Garaje → toma el primer "otro vehículo" (no principal, activo)
//   → sus opciones → "Marcar como principal" → verifica que la tarjeta
//   principal ahora es ESE vehículo
//   → sus opciones (ahora como principal) → "Archivar" → confirmar en el
//   modal → verifica que desaparece de la lista activa y aparece en
//   "Archivados"
//   → sus opciones (desde "Archivados") → "Restaurar" → verifica que vuelve
//   a la lista activa y ya no está en "Archivados".
//
// PRECONDICIONES DE DATOS (la cuenta de prueba debe cumplirlas o el test
// falla con un timeout/expect claro en el paso correspondiente):
//   1. Sesión Firebase válida (TEST_EMAIL / TEST_PASSWORD) que llega a Home.
//   2. La cuenta tiene AL MENOS 2 vehículos ACTIVOS (no archivados): un
//      principal (`isMainVehicle: true`) y al menos un "otro vehículo". El
//      test toma el primero de "Otros vehículos" como objetivo — no debe
//      importar su nombre, se identifica por `VehicleModel.id` leído
//      directamente del widget en pantalla (no hay valores hardcodeados).
//   3. Ninguno de los vehículos de la cuenta está referenciado por una
//      inscripción a un evento ACTIVO que dependa de que siga sin archivar
//      (archivar no bloquea nada a nivel de API hoy, pero evita falsos
//      positivos si en el futuro se agrega esa validación).
//   4. Cuentas QA de referencia: qa1@gmail.com / qa2@gmail.com, password
//      Test123. (ver memoria del proyecto `project_qa_test_users`). Si se usa
//      qa2@gmail.com (owner de "Mi Evento"), confirmar que tiene ≥2 vehículos
//      activos antes de correr — si no, agregar uno vía el otro test
//      (`vehicles_add_edit_patrol_test.dart`) antes de esta corrida.
//
// Nota: este test dejará al vehículo objetivo en el MISMO estado final que al
// inicio (activo, no archivado) pero puede que ya NO sea el vehículo
// principal (el desarchivado solo se promueve a principal si no queda
// ningún otro activo marcado como principal — ver
// `VehicleCubit.unarchiveLocally` en vehicles.md §8). Esto es aceptable para
// una cuenta de QA; no se intenta restaurar el vehículo principal original.
//
// Cómo correr:
//   patrol test -t integration_test/vehicles_archive_setmain_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_vehicle_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicle_item.dart';
import 'package:rideglory/shared/widgets/modals/app_modal.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _myGarageHeader = 'Mi Garaje'; // vehicle_myGarage
const _setMainOption = 'Marcar como principal'; // vehicle_setMainVehicle
const _archiveOption = 'Archivar'; // vehicle_archiveVehicle (fila del sheet)
const _archiveConfirmButton =
    'Archivar'; // vehicle_archiveConfirmButton (modal)
const _archivedSuccessSnackbar =
    'Vehículo archivado'; // vehicle_vehicleArchived
const _unarchiveOption = 'Restaurar'; // vehicle_unarchiveVehicle
const _restoredSuccessSnackbar =
    'Vehículo restaurado'; // vehicle_vehicleRestored
const _archivedSectionHeader = 'ARCHIVADOS'; // vehicle_archivedSection

Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

Finder _mainCardFinder() => find.byType(GarageMainVehicleCard);

Finder _otherItemByIdFinder(String vehicleId, {bool? isArchived}) {
  return find.byWidgetPredicate((widget) {
    if (widget is! GarageOtherVehicleItem || widget.vehicle.id != vehicleId) {
      return false;
    }
    if (isArchived == null) return true;
    return widget.vehicle.isArchived == isArchived;
  });
}

bool _isCurrentMain(PatrolIntegrationTester $, String vehicleId) {
  final mainCardFinder = _mainCardFinder();
  if (mainCardFinder.evaluate().isEmpty) return false;
  final vehicle = $.tester
      .widget<GarageMainVehicleCard>(mainCardFinder)
      .vehicle;
  return vehicle.id == vehicleId;
}

/// Abre el `GarageOptionsBottomSheet` del vehículo [vehicleId], sin importar
/// si hoy se muestra como tarjeta principal (ícono `more_horiz`, único en
/// pantalla) o como "otro vehículo" / archivado (ícono `more_vert` dentro de
/// su propio `GarageOtherVehicleItem`).
Future<void> _openOptionsForId(
  PatrolIntegrationTester $,
  String vehicleId,
) async {
  if (_isCurrentMain($, vehicleId)) {
    await $(Icons.more_horiz).tap();
  } else {
    final itemFinder = _otherItemByIdFinder(vehicleId);
    await $(itemFinder).$(Icons.more_vert).tap();
  }
  await _settle($);
}

Future<void> _ensureArchivedSectionExpanded(
  PatrolIntegrationTester $,
  String vehicleId,
) async {
  if (_otherItemByIdFinder(vehicleId, isArchived: true).evaluate().isNotEmpty) {
    return;
  }
  await $(_archivedSectionHeader).scrollTo().tap();
  await _settle($);
}

void main() {
  patrolTest(
    'garage: marca principal, archiva y desarchiva un vehículo existente',
    timeout: const Timeout(Duration(minutes: 6)),
    _runArchiveSetMainFlow,
  );
}

Future<void> _runArchiveSetMainFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa.
  await bootstrapSession($);

  // 2. Ir al tab Garaje y esperar a que carguen los vehículos.
  await $(
    Icons.directions_car_outlined,
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(Icons.directions_car_outlined).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 30));
  expect($(GaragePageView), findsOneWidget);

  await $(
    _myGarageHeader,
  ).waitUntilVisible(timeout: const Duration(seconds: 45));

  // 3. Tomar el vehículo objetivo: el primer "otro vehículo" ACTIVO (no
  // principal, no archivado). Falla aquí con un mensaje claro si la cuenta
  // de prueba no tiene al menos 2 vehículos activos (precondición #2).
  final otherActiveFinder = find.byWidgetPredicate(
    (widget) => widget is GarageOtherVehicleItem && !widget.vehicle.isArchived,
  );
  expect(
    otherActiveFinder,
    findsWidgets,
    reason:
        'La cuenta de prueba necesita al menos 2 vehículos activos '
        '(1 principal + 1 "otro vehículo") para este test — ver '
        'precondición #2 en la cabecera del archivo.',
  );
  final VehicleModel target =
      ($.tester.widget(otherActiveFinder.first) as GarageOtherVehicleItem)
          .vehicle;
  final targetId = target.id!;

  // ── Paso 1: marcar como principal ────────────────────────────────────────
  await _openOptionsForId($, targetId);
  await $(
    _setMainOption,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_setMainOption).tap();
  await _settle($, 3);

  expect(
    _isCurrentMain($, targetId),
    isTrue,
    reason:
        'Tras "Marcar como principal", la tarjeta principal debe ser el '
        'vehículo objetivo (id=$targetId).',
  );

  // ── Paso 2: archivar ─────────────────────────────────────────────────────
  await _openOptionsForId($, targetId);
  await $(
    _archiveOption,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_archiveOption).tap();
  await _settle($);

  // Confirmar en el modal (AppModal): el botón "Archivar" del modal y el de
  // la fila del sheet (detrás, todavía montado) comparten el mismo texto, así
  // que se acota la búsqueda al árbol de `AppModal`.
  await $(find.byType(AppModal))
      .$(_archiveConfirmButton)
      .waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(find.byType(AppModal)).$(_archiveConfirmButton).tap();

  await $(
    _archivedSuccessSnackbar,
  ).waitUntilExists(timeout: const Duration(seconds: 20));
  await _settle($, 2);

  expect(
    _isCurrentMain($, targetId),
    isFalse,
    reason:
        'El vehículo archivado no debe seguir siendo la tarjeta '
        'principal (el backend/VehicleCubit promueven otro activo).',
  );
  expect(
    otherActiveFinder.evaluate().any(
      (element) =>
          (element.widget as GarageOtherVehicleItem).vehicle.id == targetId,
    ),
    isFalse,
    reason: 'El vehículo archivado no debe aparecer en la lista activa.',
  );

  await _ensureArchivedSectionExpanded($, targetId);
  expect(
    _otherItemByIdFinder(targetId, isArchived: true),
    findsOneWidget,
    reason: 'El vehículo archivado debe aparecer en la sección "Archivados".',
  );

  // ── Paso 3: desarchivar ──────────────────────────────────────────────────
  // El ítem archivado puede quedar fuera del viewport si ya había otros
  // vehículos archivados antes de esta corrida (p. ej. de una corrida previa
  // de `vehicles_add_edit_patrol_test.dart`) — hace falta `.scrollTo()` antes
  // del tap, igual que en `maintenance_crud_patrol_test.dart`.
  final archivedItemFinder = await $(
    _otherItemByIdFinder(targetId, isArchived: true),
  ).scrollTo();
  await archivedItemFinder.$(Icons.more_vert).tap();
  await _settle($);

  await $(
    _unarchiveOption,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_unarchiveOption).tap();

  await $(
    _restoredSuccessSnackbar,
  ).waitUntilExists(timeout: const Duration(seconds: 20));
  await _settle($, 2);

  expect(
    _otherItemByIdFinder(targetId, isArchived: true),
    findsNothing,
    reason: 'El vehículo restaurado ya no debe aparecer en "Archivados".',
  );
  final isBackAsMain = _isCurrentMain($, targetId);
  final isBackAsOther = _otherItemByIdFinder(
    targetId,
    isArchived: false,
  ).evaluate().isNotEmpty;
  expect(
    isBackAsMain || isBackAsOther,
    isTrue,
    reason:
        'El vehículo restaurado debe volver a la lista activa (como '
        'principal o como "otro vehículo").',
  );
}
