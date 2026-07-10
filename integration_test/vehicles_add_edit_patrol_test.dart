// Patrol e2e test: agregar un vehículo nuevo desde el garage y luego editarlo.
//
// Flujo cubierto:
//   Home → tab Garaje → "Agregar" (GarageHeader) → VehicleFormPage (creación)
//   → llenar campos mínimos requeridos (nombre, marca, modelo, año, kilometraje)
//   → "Guardar moto" → snackbar de éxito → vuelve al garage → el vehículo nuevo
//   aparece en la lista (tarjeta principal o "Otros vehículos", según si el
//   usuario ya tenía un vehículo principal)
//   → abrir sus opciones (GarageOptionsBottomSheet) → "Editar vehículo"
//   → cambiar el apodo (campo "Nombre del vehículo") → "Guardar moto"
//   → snackbar de éxito → vuelve al garage → el nuevo nombre se ve en la lista.
//
// PRECONDICIONES DE DATOS:
//   1. La cuenta de prueba ya tiene sesión Firebase válida (ver TEST_EMAIL /
//      TEST_PASSWORD) y llega a Home sin fricciones (perfil no bloqueante).
//   2. No se requiere ningún vehículo previo estrictamente, pero se recomienda
//      que la cuenta YA tenga al menos 1 vehículo activo (no archivado) para
//      que el garage muestre el header "Mi Garaje" con el botón "Agregar"
//      (en cuentas 100% vacías el CTA equivalente es "Agregar vehículo" desde
//      el estado vacío — este test asume el primero). Cuentas QA de referencia:
//      qa1@gmail.com / qa2@gmail.com (ver docs/features/vehicles.md).
//   3. La marca usada ("Honda") debe seguir en
//      `ColombiaMotosBrandsData.brands` (lib/core/data/colombia_motos_brands_data.dart).
//      Si cambia el catálogo de marcas, actualizar el valor aquí.
//   4. El vehículo creado por este test NO se limpia al final (no hay borrado
//      permanente en el flujo) — queda en el garage de la cuenta de prueba con
//      el prefijo "QA E2E ". Aceptable para una cuenta de QA; si se necesita
//      un entorno limpio, borrar manualmente los vehículos con ese prefijo.
//
// Cómo correr:
//   patrol test -t integration_test/vehicles_add_edit_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_vehicle_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicle_item.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb), centralizados para que el
// test rompa de forma evidente si cambian las claves.
const _addVehicleShort = 'Agregar'; // vehicle_addShort (GarageHeader)
const _saveVehicleButton = 'Guardar moto'; // vehicle_form_save
const _editVehicleOption = 'Editar vehículo'; // vehicle_editVehicle
const _brandToPick = 'Honda'; // debe existir en ColombiaMotosBrandsData.brands

Future<void> _settle(PatrolIntegrationTester $, [int seconds = 1]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

/// Busca, en el árbol actual, el vehículo (tarjeta principal u "otro
/// vehículo") cuyo nombre sea [name]. Retorna su `id`, o `null` si no se
/// encuentra (aún no cargó / nombre incorrecto).
String? _findVehicleIdByName(String name) {
  final mainMatches = find
      .byWidgetPredicate(
        (widget) =>
            widget is GarageMainVehicleCard && widget.vehicle.name == name,
      )
      .evaluate();
  if (mainMatches.isNotEmpty) {
    return (mainMatches.first.widget as GarageMainVehicleCard).vehicle.id;
  }

  final otherMatches = find
      .byWidgetPredicate(
        (widget) =>
            widget is GarageOtherVehicleItem && widget.vehicle.name == name,
      )
      .evaluate();
  if (otherMatches.isNotEmpty) {
    return (otherMatches.first.widget as GarageOtherVehicleItem).vehicle.id;
  }
  return null;
}

/// Abre el `GarageOptionsBottomSheet` del vehículo identificado por [name],
/// sin importar si hoy se muestra como principal (ícono `more_horiz`) o como
/// "otro vehículo" (ícono `more_vert`).
Future<void> _openOptionsFor(PatrolIntegrationTester $, String name) async {
  final isMain = find
      .byWidgetPredicate(
        (widget) =>
            widget is GarageMainVehicleCard && widget.vehicle.name == name,
      )
      .evaluate()
      .isNotEmpty;

  if (isMain) {
    await $(Icons.more_horiz).tap();
  } else {
    final itemFinder = find.byWidgetPredicate(
      (widget) =>
          widget is GarageOtherVehicleItem && widget.vehicle.name == name,
    );
    await $(itemFinder).$(Icons.more_vert).tap();
  }
  await _settle($);
}

void main() {
  patrolTest(
    'garage: agrega un vehículo y luego lo edita',
    timeout: const Timeout(Duration(minutes: 6)),
    _runAddEditFlow,
  );
}

Future<void> _runAddEditFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa.
  await bootstrapSession($);

  // 2. Ir al tab Garaje.
  await $(
    Icons.directions_car_outlined,
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(Icons.directions_car_outlined).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 30));
  expect($(GaragePageView), findsOneWidget);

  // 3. Esperar a que la API de vehículos responda y abrir el form de creación.
  await $(
    _addVehicleShort,
  ).waitUntilVisible(timeout: const Duration(seconds: 45));
  await $(_addVehicleShort).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));

  // 4. Llenar los campos MÍNIMOS requeridos para guardar
  // (ver lib/features/vehicles/constants/vehicle_form_fields.dart y
  // vehicle_form_basic_section.dart: name, brand, model, year y mileage son
  // los únicos `isRequired: true`; placa/VIN/color/specs quedan vacíos).
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final vehicleName = 'QA E2E $suffix';

  // 4a. Nombre.
  await $(TextField).at(0).scrollTo().enterText(vehicleName);
  await _settle($);

  // 4b. Marca (autocomplete): escribir y SELECCIONAR la sugerencia — el
  // FormBuilderField solo confirma el valor cuando se toca un ítem del
  // overlay (ver AppAutocompleteField._select); si solo se escribe, el
  // validador rechaza el guardado con "Selecciona una opción válida".
  await $(TextField).at(1).scrollTo().enterText(_brandToPick);
  await _settle($);
  await $(_brandToPick).waitUntilVisible(timeout: const Duration(seconds: 10));
  // El texto "Honda" aparece DOS veces mientras el overlay está abierto: en
  // el propio TextField (lo que acabamos de escribir) y en el ítem de
  // sugerencia (`InkWell` dentro de `_SuggestionsOverlay`). Tocar `$(_brandToPick)`
  // sin acotar puede golpear el campo (no-op de cursor) en vez de la
  // sugerencia real, dejando el validador en "Selecciona una opción válida".
  // Acotamos al `InkWell` del overlay, que el campo de texto no tiene.
  await $(
    find.descendant(of: find.byType(InkWell), matching: find.text(_brandToPick)),
  ).tap();
  await _settle($);

  // 4c. Modelo.
  await $(TextField).at(2).scrollTo().enterText('CB1');
  await _settle($);

  // 4d. Año.
  await $(TextField).at(3).scrollTo().enterText('2022');
  await _settle($);

  // 4e. Kilometraje actual (AppMileageField, campo requerido con validador
  // numérico >= 0).
  await $(TextField).at(5).scrollTo().enterText('15000');
  await _settle($);

  // 5. Guardar.
  await $(_saveVehicleButton).scrollTo().tap();
  await _settle($, 3);

  // 6. Éxito: snackbar + regreso al garage con el vehículo nuevo visible.
  await $(vehicleName).waitUntilVisible(timeout: const Duration(seconds: 30));
  expect(_findVehicleIdByName(vehicleName), isNotNull);

  // 7. Abrir sus opciones y entrar a "Editar vehículo".
  await _openOptionsFor($, vehicleName);
  await $(
    _editVehicleOption,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_editVehicleOption).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));

  // 8. Cambiar el apodo (campo "Nombre del vehículo", precargado con el
  // valor actual) y guardar.
  final editedName = '$vehicleName Editada';
  await $(TextField).at(0).scrollTo().enterText(editedName);
  await _settle($);
  await $(_saveVehicleButton).scrollTo().tap();
  await _settle($, 3);

  // 9. Verificar que el cambio persistió en la UI del garage.
  await $(editedName).waitUntilVisible(timeout: const Duration(seconds: 30));
  expect(_findVehicleIdByName(editedName), isNotNull);
  expect(find.text(vehicleName), findsNothing);
}
