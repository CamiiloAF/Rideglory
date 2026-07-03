# Flutter Dev handoff — legal-privacidad-edad-fase7-organizador

**Date:** 2026-07-03T17:14:01Z
**Status:** done

## Baseline

- `flutter test test/features/event_registration/` antes de tocar nada:
  **92/92 pass**.
- Confirmado, tal como indicó el Architect, que el 95% del alcance del PRD
  (`isOrganizerView`, `RegistrationContactActions`, los 3 call-sites de
  navegación organizador en `attendees_list.dart`,
  `event_detail_participants_section.dart`, y el bottom bar de detalle) ya
  estaba implementado y con tests existentes en verde. No se tocó nada de eso.

## Screens / features delivered

| Screen / Cubit | Route / path | Status | Notes |
|----------------|--------------|--------|-------|
| `RegistrationDetailPage` — fila "Tipo de sangre" | `/registration/detail` (sin cambio de ruta) | Fix AC10 | Fallback de 2 pasos: `bloodType?.label ?? bloodTypeRaw ?? notAvailable` |
| Cobertura Patrol organizador | `integration_test/registration_organizer_patrol_test.dart` (nuevo) | Nuevo | Cubre navegación `event_detail → Inscritos → detalle organizador → contacto` |

## Layer changes

- **Domain**: `EventRegistrationModel` — nuevo campo `final String? bloodTypeRaw`
  (constructor + `copyWith`), opcional, default `null`. No afecta `==`/`hashCode`
  (siguen basados en `id`).
- **Data**: `EventRegistrationDto`
  - Constructor: `bloodTypeRaw` anotado
    `@JsonKey(includeFromJson: false, includeToJson: false)` para que
    `json_serializable` nunca intente leerlo/escribirlo desde/hacia una clave
    literal `"bloodTypeRaw"` en el JSON (no existe tal clave en el backend).
  - `EventRegistrationDto.fromJson` ahora es un factory custom: llama al
    generado `_$EventRegistrationDtoFromJson(json)`, y si
    `generated.bloodType == null` pero `json['bloodType']` es un string no
    vacío (el `_BloodTypeConverter` no pudo mapearlo — p. ej. `"••••"` o
    `"__NOT_SHARED__"`), reconstruye el DTO con ese string crudo en
    `bloodTypeRaw`. Si el converter sí mapeó o el JSON no traía la clave,
    retorna el DTO generado sin cambios (evita una alocación extra en el caso
    común).
  - `toJson()` nunca serializa `bloodTypeRaw` (por el `@JsonKey` de arriba) —
    confirmado con test dedicado.
  - `EventRegistrationModelExtension.toJson()` propaga `bloodTypeRaw` al
    construir el DTO intermedio (aunque nunca sale en el JSON final, por
    consistencia si algo lee el objeto intermedio).
- **Presentation**: `registration_detail_page.dart` línea ~124-129 — el
  `value` de la fila `registration_rowBloodType` cambia de
  `bloodType?.label ?? context.l10n.registration_maskedValue` a
  `bloodType?.label ?? bloodTypeRaw ?? context.l10n.notAvailable` (AC10 exacto
  del PRD). No se tocó el árbol de widgets (confirmado por Design: sin cambio
  visual).

## Code generation

- Run: `dart run build_runner build --delete-conflicting-outputs` (27s, JIT,
  161 outputs escritos).
- Archivo regenerado relevante:
  `lib/features/event_registration/data/dto/event_registration_dto.g.dart`
  (no editado a mano).

## API integration

- Sin cambios de endpoints. El fix es puramente de deserialización/fallback de
  UI sobre la respuesta ya existente de `GET /registrations/*`.
- Deviations from architect contract: ninguna.

## l10n keys added

- Ninguna clave nueva (prohibido por AC10). `registration_maskedValue`
  ("••••") queda sin call-sites tras el fix — **no se eliminó** en esta fase
  (documentado como deuda menor por Architect/Design, decisión de
  Frontend/QA no forzada aquí).

## Test results

- `dart analyze`: **pass** (0 issues en los archivos tocados; 15 infos
  preexistentes en otros archivos del repo, no relacionados con esta fase, ya
  presentes antes de mis cambios).
- `flutter test` (suite completa del repo, tras los cambios): **974/974
  pass**. Incluye 6 tests nuevos netos: 2 en `registration_detail_page_test.dart`
  (casos 1.3/1.4) + 4 en `event_registration_dto_test.dart` (TC-dto-06..09)
  — ver detalle abajo.
- Cómo correr:
  - `flutter test test/features/event_registration/presentation/registration_detail_page_test.dart`
  - `flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart`
  - `flutter test` (suite completa)

## Test coverage detail (nuevos)

### `test/features/event_registration/presentation/registration_detail_page_test.dart`
- **1.3** (nuevo): `bloodType=null` + `bloodTypeRaw='••••'` → renderiza el
  string crudo `'••••'` en la fila.
- **1.4** (nuevo): `bloodType=null` + `bloodTypeRaw=null` → renderiza `'N/A'`
  (localizado, `notAvailable`). La aserción usa `find.byWidgetPredicate` sobre
  `RegistrationDetailDataRow` con `label == 'Tipo de sangre'` porque la página
  tiene otra fila (`Vehículo`) que también cae a `'N/A'` cuando
  `vehicleSummary` es `null` — un `find.text('N/A')` simple habría sido
  ambiguo (2 matches).

### `test/features/event_registration/data/dto/event_registration_dto_test.dart`
- **TC-dto-06**: sentinel `'••••'` no mapeado → `dto.bloodType == null` y
  `dto.bloodTypeRaw == '••••'`.
- **TC-dto-07**: string válido `'A_POSITIVE'` → `dto.bloodType == aPositive` y
  `dto.bloodTypeRaw == null` (el converter sí mapeó, no hay fallback).
- **TC-dto-08**: clave `bloodType` ausente en el JSON → ambos campos `null`.
- **TC-dto-09**: `dto.toJson()` nunca incluye la clave `bloodTypeRaw`.

### `integration_test/registration_organizer_patrol_test.dart` (nuevo)
- Flujo: login como `qa2@gmail.com` (owner de "Mi Evento") → tab Eventos →
  abrir "Mi Evento" → localizar la sección "Inscritos" (organizer-only UI,
  confirma que la navegación organizador está activa para esta cuenta) → si
  hay al menos un inscrito visible, tap en la primera fila
  (`EventDetailParticipantRow`) → detalle en modo organizador → si
  `allowOrganizerContact` está activo, verifica que "Llamar"/"WhatsApp" son
  visibles.
- Diseñado para ser tolerante a datos: si "Mi Evento" no tiene inscritos
  todavía, el test termina tras validar que la sección organizador es visible
  (no falla — documentado en el header del archivo como precondición #2).
- No se pudo ejecutar en un dispositivo/emulador real desde este entorno (sin
  emulador Android/iOS disponible en la sesión) — el archivo compila y pasa
  `dart analyze` limpio; queda pendiente de correr en CI/manual con
  `patrol test -t integration_test/registration_organizer_patrol_test.dart --device-id <id> --dart-define=TEST_EMAIL=qa2@gmail.com --dart-define=TEST_PASSWORD=<pwd>`.

## Known gaps

- `registration_maskedValue` queda como clave l10n sin uso en código. No
  elimino en esta fase por decisión explícita del Architect/Design (fuera de
  alcance de AC10); si QA/PO decide limpiarla, es un cambio de 1 línea en
  `app_es.arb` + regenerar l10n.
- El nuevo test Patrol organizador no corrió contra un emulador real en esta
  sesión (sin dispositivo disponible). Requiere verificación manual/CI antes
  de considerarlo verde end-to-end.

## Next agent needs to know

- **QA**: correr `integration_test/registration_organizer_patrol_test.dart`
  contra un emulador con la cuenta `qa2@gmail.com` (owner de "Mi Evento") y,
  si es posible, asegurar que existe al menos una inscripción de
  `qa1@gmail.com` con `allowOrganizerContact = true` para ejercer la rama de
  botones de contacto (si no, el test solo valida la sección organizador y
  termina, sin fallar).
- **Tech lead**: el punto más sutil del cambio es el `@JsonKey(includeFromJson: false, includeToJson: false)`
  sobre un **super-parameter** (`super.bloodTypeRaw`) en el constructor del
  DTO — es válido en Dart moderno y `json_serializable` lo respeta (confirmado
  por build_runner + tests), pero si alguien migra este patrón a otro DTO sin
  el `@JsonKey`, el generador intentará (inofensivamente) buscar una clave
  `"bloodTypeRaw"` inexistente en el JSON del backend, la cual siempre será
  `null` — no rompe nada, pero sería ruido en el DTO generado.

## Change log

- 2026-07-03T17:14:01Z: AC10 implementado — `bloodTypeRaw` en modelo/DTO,
  fallback de 2 pasos en `registration_detail_page.dart`, 6 tests unit/widget
  nuevos, 1 test Patrol e2e nuevo para el flujo organizador. `dart analyze` y
  `flutter test` en verde.
