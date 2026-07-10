// Patrol e2e test: captura MANUAL del SOAT (sin cámara/OCR) desde el detalle
// de un vehículo.
//
// Flujo cubierto:
//   Home → tab Garaje → primer vehículo (principal u "otro") → detalle del
//   vehículo → tarjeta "SOAT" (VehicleDocumentCard, sin SOAT vigente) →
//   `SoatEntryFlow` abre el sheet de opciones → "Completar formulario"
//   (vía manual, NO Galería/PDF) → `SoatManualCapturePage` en modo
//   creación/edición → llena Aseguradora + Fecha de inicio + Fecha de
//   vencimiento (válidas: vencimiento posterior a inicio) → "Guardar datos" →
//   vuelve al detalle del vehículo con la tarjeta SOAT en estado "Vigente".
//
// Por qué NO se prueba el flujo con documento (galería/PDF): ese camino
// depende de la cámara/galería real del emulador y del OCR on-device
// (ML Kit), mucho más frágil en Patrol. La vía manual (`SoatManualOptionCard`
// → "Completar formulario") cubre el mismo formulario y guardado en backend
// sin esa fragilidad. Ver docs/features/soat.md §6.1-6.2.
//
// PRECONDICIONES DE DATOS (si no se cumplen, el test falla en el gate
// correspondiente, no cuelga):
//   1. La cuenta de prueba tiene AL MENOS UN vehículo (no archivado) en su
//      garaje — el mismo vehículo usado en `registration_patrol_test.dart`
//      sirve. Sin vehículos, el garaje muestra el estado vacío y el test
//      falla en el gate del paso 3 (no hay tarjeta que tocar).
//   2. Ese vehículo NO tiene un SOAT vigente registrado (sin SOAT, o con SOAT
//      vencido/por vencer). Si ya tiene un SOAT vigente, la tarjeta navega
//      directo a "Mi SOAT" (`SoatStatusPage`) en vez de abrir el sheet de
//      opciones de captura, y el test falla en el gate del paso 4.
//
// Cómo correr:
//   patrol test -t integration_test/soat_manual_capture_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa1@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/vehicles/presentation/garage/garage_page_view.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_vehicle_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicle_item.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _garageHeader = 'Mi Garaje'; // garage header cuando hay vehículos
const _manualOptionCta =
    'Completar formulario'; // vehicle_soat_option_manual_cta
const _formTitle = 'Registrar SOAT'; // vehicle_soat_form_title
const _saveDataButton = 'Guardar datos'; // soat_save_data_btn
const _statusValid = 'Vigente'; // soat_status_valid (badge en la tarjeta)
const _testInsurer = 'Seguros Bolívar';

/// "Settle" acotado: evita `pumpAndSettle` colgándose por animaciones
/// continuas (p. ej. el hero del detalle de vehículo). Ver
/// `registration_patrol_test.dart` para la misma convención.
Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

void main() {
  patrolTest(
    'SOAT: captura manual sin documento deja el vehículo con SOAT vigente',
    timeout: const Timeout(Duration(minutes: 8)),
    _runSoatManualCaptureFlow,
  );
}

Future<void> _runSoatManualCaptureFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa.
  await bootstrapSession($);

  // 2. Ir al tab Garaje (icono del bottom-nav; no tiene label de texto propio
  // como 'EVENTOS' — mismo criterio que `vehicles_patrol_test.dart`).
  await $(Icons.directions_car_outlined).waitUntilVisible(
    timeout: const Duration(seconds: 20),
  );
  await $(Icons.directions_car_outlined).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 30));

  expect($(GaragePageView), findsOneWidget);
  await $(
    _garageHeader,
  ).waitUntilVisible(timeout: const Duration(seconds: 45));

  // 3. Abrir el detalle del primer vehículo disponible: el vehículo
  // "principal" (`GarageMainVehicleCard`) si existe, o el primero de "otros
  // vehículos" (`GarageOtherVehicleItem`) en caso contrario.
  if ($(GarageMainVehicleCard).exists) {
    await $(GarageMainVehicleCard).tap();
  } else {
    await $(GarageOtherVehicleItem).first.tap();
  }
  await _settle($, 3);

  // 4. Tarjeta "SOAT" dentro del detalle del vehículo: es el PRIMER
  // `VehicleDocumentCard` de la pantalla (el segundo es RTM/tecnomecánica).
  // Sin SOAT vigente, tocarla abre `SoatEntryFlow` (sheet de opciones) en vez
  // de navegar directo a "Mi SOAT".
  await $(
    VehicleDocumentCard,
  ).at(0).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(VehicleDocumentCard).at(0).scrollTo().tap();
  await _settle($);

  // 5. Sheet de opciones: elegir la vía MANUAL (no Galería/PDF).
  await $(
    _manualOptionCta,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_manualOptionCta).tap();
  await _settle($);

  // 6. Formulario unificado de captura manual, en modo creación/edición
  // (vehículo existente): título "Registrar SOAT".
  await $(_formTitle).waitUntilVisible(timeout: const Duration(seconds: 15));
  // El campo de aseguradora (vehicle_soat_insurer_label = "Aseguradora") es
  // el requerido (`_canSubmit`); el resto del formulario lo confirma más
  // abajo la habilitación del botón "Guardar datos".

  // Campos del formulario, en el orden en que aparecen en
  // `SoatManualCapturePage`: [0] policyNumber (opcional, se omite),
  // [1] insurer (requerido), [2] startDate, [3] expiryDate.
  await $(TextField).at(1).enterText(_testInsurer);
  await _settle($);

  // Fecha de inicio: hoy. Fecha de vencimiento: muy en el futuro para que el
  // estado quede "Vigente" (> 30 días para vencer). El formulario manual solo
  // exige `expiryDate.isAfter(startDate)` — a diferencia del parser OCR, no
  // hay ventana de 360-370 días (ver docs/features/soat.md §6.2 y §6.4).
  await _pickDate($, fieldIndex: 2, day: '01', month: '01', year: '2025');
  await _pickDate($, fieldIndex: 3, day: '01', month: '01', year: '2030');

  // 7. Guardar. Botón habilitado solo si aseguradora + ambas fechas son
  // válidas (`_canSubmit`).
  await $(_saveDataButton).waitUntilVisible(
    timeout: const Duration(seconds: 10),
  );
  await $(_saveDataButton).tap();
  await _settle($, 3);

  // 8. De vuelta en el detalle del vehículo: la tarjeta SOAT recarga y ahora
  // muestra el badge "Vigente" (soat_status_valid).
  await $(_statusValid).waitUntilVisible(timeout: const Duration(seconds: 20));
}

/// Abre el date picker de Material del campo en [fieldIndex], cambia a modo
/// de entrada de texto (icono con tooltip "Cambiar a cuadro de texto" en
/// localización es) y escribe la fecha en el formato `dd/mm/aaaa` que exige
/// `MaterialLocalizations` en español, luego confirma con "ACEPTAR".
///
/// Es el paso más fragil del flujo (interacción con un `showDatePicker` de
/// Material, no un widget propio de la app) — si Flutter cambia el tooltip o
/// el formato de fecha localizado, este helper es el primer lugar a revisar.
Future<void> _pickDate(
  PatrolIntegrationTester $, {
  required int fieldIndex,
  required String day,
  required String month,
  required String year,
}) async {
  await $(TextField).at(fieldIndex).tap();
  await _settle($);

  // Cambiar del calendario visual a la entrada de texto (más determinístico
  // en Patrol que navegar meses en el `GridView` del calendario).
  await $(find.byTooltip('Cambiar a cuadro de texto')).tap();
  await _settle($);

  // Dentro del diálogo hay un único `TextField` para la fecha en formato
  // dd/mm/aaaa (separador '/', `dateHelpText` de MaterialLocalizations es).
  // Scope al Dialog: los campos del formulario debajo también son `TextField`
  // (FormBuilderTextField renderiza TextField, no TextFormField), así que sin
  // acotar al diálogo `$(TextField)` matchearía varios.
  await $(Dialog).$(TextField).enterText('$day/$month/$year');
  await _settle($);

  await $('ACEPTAR').tap();
  await _settle($);
}
