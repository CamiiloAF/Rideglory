// Patrol e2e test: creación y publicación completa de un evento.
//
// Flujo cubierto:
//   Home → tab Eventos → FAB "+" (CreateEventFab) → wizard de 4 pasos
//   Step 1 (Básica): portada (galería) → nombre → dificultad → tipo de evento
//     → "Continuar"
//   Step 2 (Descripción): editor Quill → "Continuar"
//   Step 3 (Ruta y detalles): "Crear ruta" → 2 waypoints vía "Seleccionar en
//     mapa" → "Continuar" (route builder) → "Continuar" (step 3; cupo/precio
//     se dejan sin tocar, son opcionales)
//   Step 4 (Revisión): "Publicar evento" → sheet "Responsabilidad del
//     organizador" → "Acepto y publico el evento" → SnackBar de éxito
//   → el wizard cierra y el evento nuevo aparece en la lista de Eventos.
//
// POR QUÉ SE PRUEBA "PUBLICAR":
//   La funcionalidad de guardar borradores fue eliminada del producto
//   (incluido `EventFormCubit.saveDraft()`, que ya era código muerto sin
//   callsite desde la UI). El step 4 en modo creación solo ofrece "Publicar
//   evento" (PublishRow), así que este test ejerce el único camino real de
//   guardado: publicar.
//
// LO QUE NO SE PUEDE GARANTIZAR DE FORMA 100% DETERMINÍSTICA (documentado a
// propósito, en vez de ocultarlo):
//   1. PORTADA: Step 1 exige una imagen de portada para poder avanzar
//      (`validateImageRequired`), y el único origen es la galería del
//      dispositivo (`CoverPickerSheet` — "no AI generation button", ver
//      comentario en el archivo fuente). Eso dispara el selector nativo de
//      fotos de Android (Photo Picker / `image_picker` con
//      `ImageSource.gallery`). Se usa `$.platformAutomator.mobile.pickImageFromGallery(index: 0)`
//      (API dedicada de Patrol para este flujo, ver
//      `MobileAutomator.pickImageFromGallery` en el paquete `patrol`) en vez
//      de un `tapAt(Offset)` calibrado a mano — resuelve por selector nativo
//      (UiSelector/BySelector) el primer ítem de la grilla, así que no
//      depende de coordenadas relativas frágiles a resolución/tema del Photo
//      Picker. PRECONDICIÓN: el emulador/dispositivo debe tener AL MENOS UNA
//      imagen en la galería (si no, el test falla con un error explícito de
//      Patrol en vez de un timeout opaco). Sembrar una imagen de prueba antes
//      de correr:
//        adb push sample.jpg /sdcard/Pictures/sample.jpg
//        adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
//          -d file:///sdcard/Pictures/sample.jpg
//   2. RUTA/MAPBOX: a diferencia de la portada, esta parte SÍ es
//      determinística sin datos externos: "Seleccionar en mapa" toma el
//      centro de cámara actual y, si el reverse-geocoding de Mapbox falla
//      (sin red, cuota, etc.), `EventRouteConfigScreen._confirmPickMode` cae
//      a un nombre fallback ("Punto en el mapa") — ver el `catch (_) {}` en
//      `event_route_config_screen.dart:134`. Por eso este test NO depende de
//      una búsqueda textual ni de que Mapbox resuelva una dirección real;
//      basta con que el mapa se renderice y la cámara tenga un centro válido
//      (viewport por defecto de Colombia). El único requisito real es tener
//      Mapbox configurado (ya lo está para toda la app) y permiso de
//      ubicación (se maneja igual que en los otros tests Patrol del repo).
//
// PRECONDICIONES DE DATOS:
//   1. Cuenta qa2@gmail.com (owner de "Mi Evento" — ver memoria del proyecto)
//      para no interferir con las inscripciones que ejerce qa1@gmail.com en
//      registration_patrol_test.dart.
//   2. El emulador/dispositivo tiene al menos 1 imagen en la galería (ver
//      punto 1 arriba).
//   3. La cuenta puede llegar al límite de eventos publicados si este test se
//      corre muchas veces seguidas — no hay límite documentado en
//      docs/features/events.md, pero si el backend lo introduce, este test
//      empezaría a fallar en el paso de publicación (revisar el mensaje de
//      `event_organizerResponsibility_errorGeneric` en el sheet).
//
// Cómo correr:
//   patrol test -t integration_test/events_create_publish_patrol_test.dart \
//     --device-id emulator-5554 \
//     --dart-define=TEST_EMAIL=qa2@gmail.com \
//     --dart-define=TEST_PASSWORD=Test123.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/difficulty/flame_selector.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_empty.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_preview_wrapper.dart';
import 'package:rideglory/features/events/presentation/list/widgets/create_event_fab.dart';

import 'support/patrol_bootstrap.dart';

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS';
const _coverPickerTitle = 'Portada del evento'; // event_cover_picker_title
const _coverPickerGallery = 'Subir desde galería'; // event_cover_picker_gallery
const _eventName =
    'QA E2E - Rodada de prueba'; // nombre único-ish para ubicarlo en la lista
const _offRoadType = 'Off-road'; // EventType.offRoad.label
const _description =
    'Evento generado por el test e2e de creación y publicación. '
    'No requiere acción manual.';
const _stepContinue = 'Continuar'; // event_step_continue
const _routeCreateButton = 'Crear ruta'; // route_create_button
const _pickModeButton = 'Seleccionar en mapa'; // route_builder_pick_mode_button
const _pickModeConfirm = 'Añadir este punto'; // route_builder_pick_mode_confirm
const _routeBuilderContinue = 'Continuar'; // route_builder_continue
const _publishButton = 'Publicar evento'; // event_step_review_publishButton
const _responsibilityTitle =
    'Responsabilidad del organizador'; // event_organizerResponsibility_title
const _acceptResponsibility =
    'Acepto y publico el evento'; // event_organizerResponsibility_acceptButton
const _eventCreatedSuccess =
    'Evento creado exitosamente'; // event_eventCreatedSuccess

Future<void> _grantPendingPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await _settle($);
  }
}

/// "Settle" acotado: NUNCA espera a que el árbol quede inactivo. El mapa de
/// Mapbox (paso de ruta) anima de forma continua (flyTo), así que
/// `pumpAndSettle` se colgaría esperando frames que nunca dejan de llegar. En
/// su lugar bombeamos frames por una duración fija; el gating real (esperar
/// que aparezca el paso/sheet siguiente) lo hacen los
/// `waitUntilVisible`/`waitUntilExists`.
Future<void> _settle(PatrolIntegrationTester $, [int seconds = 2]) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await $.pump();
}

void main() {
  patrolTest(
    'crear evento: usuario completa el wizard y publica',
    timeout: const Timeout(Duration(minutes: 10)),
    _runCreatePublishFlow,
  );
}

Future<void> _runCreatePublishFlow(PatrolIntegrationTester $) async {
  // 1. App lista en Home con sesión activa (qa2, owner de "Mi Evento").
  await bootstrapSession($);

  // 2. Ir al tab Eventos y abrir el wizard de creación desde el FAB "+".
  await $(_tabEventos).tap();
  await _settle($, 3);
  await _grantPendingPermission($);

  await $(
    CreateEventFab,
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
  await $(CreateEventFab).tap();
  await _settle($, 2);

  // 3. Step 1 — Básica: portada, nombre, dificultad, tipo de evento.
  await _pickCoverFromGallery($);
  await _fillBasicInfo($);
  await $(_stepContinue).tap();
  await _settle($, 2);

  // 4. Step 2 — Descripción (editor Quill).
  await _fillDescription($);
  await $(_stepContinue).tap();
  await _settle($, 2);

  // 5. Step 3 — Ruta y detalles: crear ruta con 2 waypoints vía "Seleccionar
  // en mapa" (no depende de que Mapbox resuelva una dirección real — ver nota
  // de cabecera). Cupo máximo y precio se dejan sin tocar (opcionales).
  await _buildSimpleRoute($);
  await $(_stepContinue).tap();
  await _settle($, 2);

  // 6. Step 4 — Revisión: publicar.
  await $(
    _publishButton,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_publishButton).tap();
  await _settle($, 2);

  // 7. Sheet de responsabilidad del organizador: aceptar y publicar.
  await $(
    _responsibilityTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(_acceptResponsibility).tap();

  // 8. Éxito: SnackBar global + el wizard cierra devolviendo el evento creado
  // a la lista, que lo agrega sin re-fetch (ver EventsCubit.addEvent). El
  // guardado viaja al backend (sube portada a Firebase Storage + POST
  // /events), así que el timeout es amplio.
  await $(
    _eventCreatedSuccess,
  ).waitUntilExists(timeout: const Duration(seconds: 30));
  await _settle($, 3);

  // 9. Verificación final: el evento recién creado aparece en la lista de
  // Eventos (agregado optimistamente por EventsCubit.addEvent, sin re-fetch).
  await $(_eventName).waitUntilExists(timeout: const Duration(seconds: 20));
  await $(_eventName).scrollTo();
}

Future<void> _pickCoverFromGallery(PatrolIntegrationTester $) async {
  await $(CoverEmpty).tap();
  await _settle($);

  await $(
    _coverPickerTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_coverPickerGallery).tap();
  await _settle($, 3);

  // El picker nativo de fotos puede pedir permiso de acceso a medios antes de
  // mostrarse (versiones de Android previas al Photo Picker sin permisos).
  await _grantPendingPermission($);
  await _settle($, 2);

  // Selector nativo dedicado (ver nota de cabecera) en vez de tapAt(Offset):
  // resuelve el primer ítem de la grilla del Photo Picker sin depender de
  // coordenadas relativas. Depende de que el emulador/dispositivo tenga al
  // menos una foto en la galería.
  await $.platformAutomator.mobile.pickImageFromGallery(index: 0);
  await _settle($, 3);

  // Confirma que la imagen se cargó en el wizard antes de seguir.
  await $(
    CoverPreviewWrapper,
  ).waitUntilExists(timeout: const Duration(seconds: 20));
}

Future<void> _fillBasicInfo(PatrolIntegrationTester $) async {
  // AppTextField envuelve FormBuilderTextField, que renderiza TextField (no
  // TextFormField) — mismo gotcha que en soat_manual_capture_patrol_test.dart.
  await $(TextField).at(0).enterText(_eventName);
  await _settle($);

  // Dificultad y tipo de evento ya tienen un valor por defecto
  // (EventDifficulty.one / EventType.onRoad, ver
  // EventFormScaffold._getInitialValues) que satisface el validador
  // "requerido". Se tocan explícitamente para ejercer la interacción real de
  // selección, no solo depender del default.
  //
  // El teclado nativo que abre `enterText` sobre el nombre del evento reduce
  // el viewport del `SingleChildScrollView` de Step 1 (FlameSelector queda
  // debajo del pliegue) — se necesita `.scrollTo()` antes del tap, mismo
  // gotcha que en `vehicles_archive_setmain_patrol_test.dart`.
  final flameSelectorFinder = await $(FlameSelector).scrollTo();
  await flameSelectorFinder.$(GestureDetector).at(2).tap(); // dificultad 3
  await _settle($);
  // EventFormEventTypeSection queda justo debajo de FlameSelector: el scroll
  // anterior no necesariamente lo deja visible, así que se repite el mismo
  // scrollTo() antes de tocarlo.
  await $(_offRoadType).scrollTo().tap();
  await _settle($);
}

// QuillEditor no es un EditableText estándar, así que `PatrolFinder.enterText`
// (pensado para TextField/TextFormField) no aplica aquí. Simular el canal de
// IME con `tester.testTextInput.enterText()` dispara una excepción asíncrona
// dentro de `QuillContainer.insert` ('index == 0 || (index > 0 && index <
// length)') porque el diff de `RawEditorStateTextInputClientMixin` no calza
// con el largo real del documento (que siempre trae un '\n' final) — se
// manifiesta tarde (después de que el resto del wizard ya avanzó) y tumba el
// test aunque el flujo funcional haya sido exitoso. En vez de eso, se
// manipula el `Document` del `QuillController` directamente (mismo objeto
// que usa la UI), evitando el canal de IME por completo.
Future<void> _fillDescription(PatrolIntegrationTester $) async {
  await $(QuillEditor).tap();
  await _settle($);
  final editor = $.tester.widget<QuillEditor>(find.byType(QuillEditor));
  editor.controller.document.insert(0, _description);
  await $.pump();
  await _settle($);
}

Future<void> _buildSimpleRoute(PatrolIntegrationTester $) async {
  await $(_routeCreateButton).tap();
  await _settle($, 3);
  await _grantPendingPermission($);
  await _settle($, 2);

  // 2 waypoints vía "Seleccionar en mapa" → "Añadir este punto". No requiere
  // que el reverse-geocoding de Mapbox resuelva una dirección real (fallback
  // a "Punto en el mapa" si falla, ver nota de cabecera).
  for (var i = 0; i < 2; i++) {
    await $(
      _pickModeButton,
    ).waitUntilVisible(timeout: const Duration(seconds: 15));
    await $(_pickModeButton).tap();
    await _settle($);
    await $(
      _pickModeConfirm,
    ).waitUntilVisible(timeout: const Duration(seconds: 10));
    await $(_pickModeConfirm).tap();
    await _settle($, 2);
  }

  await $(
    _routeBuilderContinue,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  await $(_routeBuilderContinue).tap();
  await _settle($, 2);
}
