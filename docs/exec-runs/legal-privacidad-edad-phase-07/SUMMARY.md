# Summary — legal-privacidad-edad-fase7-organizador

**Fecha:** 2026-07-03T17:49:58Z
**Nivel:** normal (retroactivo)

## Objetivo

Adaptar `RegistrationDetailPage` para que el organizador vea los datos de cada
inscrito (reales u ofuscados según Fase 2) y pueda contactar al rider vía
Llamar/WhatsApp cuando `allowOrganizerContact == true`. La distinción
organizador/piloto pasa a un campo explícito `isOrganizerView: bool` en
`RegistrationDetailExtra` en lugar de comparar `userId`.

**Hallazgo clave de esta corrida:** al abrir el árbol de trabajo, ~95% del
alcance del PRD ya estaba implementado (isOrganizerView, `RegistrationContactActions`,
los 3 call-sites de navegación organizador, bottom bar con contacto
independiente del early-return de acciones). El único gap real era el
**Criterio de Aceptación 10** (fallback nullable de `bloodType`): el código
mostraba siempre `"••••"` cuando `bloodType` era `null`, sin distinguir la
razón real, porque `bloodTypeRaw` (asumido por el PRD como entregado por
Fase 3) no existía en el modelo/DTO. El Architect decidió cerrar este gap
como extensión mínima dentro de la misma fase, en vez de bloquear toda la
corrida — decisión razonable dado que es de solo lectura, aditiva, y no
requiere tocar `rideglory-api`.

## Que cambio por area

### Domain
- `EventRegistrationModel`: nuevo campo `final String? bloodTypeRaw` (constructor
  opcional + `copyWith`), default `null`. No afecta `==`/`hashCode` (basados en `id`).

### Data
- `EventRegistrationDto`:
  - Constructor: `super.bloodTypeRaw` anotado
    `@JsonKey(includeFromJson: false, includeToJson: false)` — el campo nunca
    se lee ni se escribe directamente desde/hacia una clave JSON literal.
  - `fromJson` pasa de ser un simple alias del generado a un factory custom:
    invoca `_$EventRegistrationDtoFromJson(json)` y, solo si
    `generated.bloodType == null` y `json['bloodType']` es un string no vacío
    (el `_BloodTypeConverter` no pudo mapearlo, p. ej. `"••••"` o
    `"__NOT_SHARED__"`), reconstruye el DTO con ese valor crudo en
    `bloodTypeRaw`.
  - `toJson()` nunca serializa `bloodTypeRaw` (confirmado por test dedicado
    TC-dto-09 y por inspección del `.g.dart` regenerado).
  - `EventRegistrationModelExtension.toJson()` propaga `bloodTypeRaw` al DTO
    intermedio por consistencia (no sale en el JSON final de escritura).
- `event_registration_dto.g.dart` regenerado vía
  `dart run build_runner build --delete-conflicting-outputs` (archivo
  gitignored, no aparece en el diff — confirmado que el converter de
  `bloodType` no cambió y `bloodTypeRaw` no aparece en las claves generadas).

### Presentation
- `registration_detail_page.dart` (fila "Tipo de sangre"): fallback pasa de
  `bloodType?.label ?? context.l10n.registration_maskedValue` a
  `bloodType?.label ?? bloodTypeRaw ?? context.l10n.notAvailable` — AC10
  exacto del PRD. Sin cambios de árbol de widgets ni strings nuevos en el ARB.
- Todo lo demás del alcance del PRD (`isOrganizerView`, `RegistrationContactActions`,
  navegación organizador en `attendees_list.dart`,
  `event_detail_participants_section.dart`, `event_detail_view.dart`, bottom
  bar con contacto independiente del early-return) **ya estaba implementado**
  antes de esta corrida — no se tocó.

### Tests
- `event_registration_dto_test.dart`: 4 casos nuevos (TC-dto-06..09) cubriendo
  el fallback de `bloodTypeRaw` en parsing y su exclusión de `toJson()`.
- `registration_detail_page_test.dart`: 6 casos nuevos —
  1.3/1.4 (bloodType nullable con/sin raw), grupo "isOrganizerView switch"
  (AC1/AC4, título+rider summary+status banner por flag, incluyendo el caso
  organizador-participante donde `registration.userId` coincide con el
  usuario autenticado), y un caso de "obfuscated phone passthrough" (AC9).
- `attendees_list_navigation_test.dart`: TC-2-44/45 nuevos — tap real en filas
  pending/processed capturando el `RegistrationDetailExtra` empujado vía
  `GoRouter`, afirmando `isOrganizerView == true` (los casos previos solo
  verificaban que el widget se renderizara, insuficiente para detectar una
  regresión del flag).
- `event_detail_participants_section_test.dart` (nuevo archivo): navegación
  real con `GoRouter`, tap en una fila de participante, afirma
  `isOrganizerView == true` en el extra capturado (AC2).
- `integration_test/registration_organizer_patrol_test.dart` (nuevo): Patrol
  e2e del flujo organizador — ejecutado 1/1 pass contra `emulator-5554`, pero
  el entorno de prueba no tenía inscritos en "Mi Evento" en el momento de la
  corrida, por lo que la rama de botones de contacto no se ejercitó
  end-to-end (test tolerante a datos, no falla en ese caso; documentado como
  seguimiento no bloqueante).

## Archivos

Modificados:
- `lib/features/event_registration/data/dto/event_registration_dto.dart`
- `lib/features/event_registration/domain/model/event_registration_model.dart`
- `lib/features/event_registration/presentation/registration_detail_page.dart`
- `test/features/event_registration/data/dto/event_registration_dto_test.dart`
- `test/features/event_registration/presentation/registration_detail_page_test.dart`
- `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`

Creados:
- `integration_test/registration_organizer_patrol_test.dart`
- `test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart`

Regenerados (gitignored, no aparecen en `git diff`):
- `lib/features/event_registration/data/dto/event_registration_dto.g.dart`

Todos los archivos tocados están dentro del change map del Architect. Cero
archivos de `rideglory-api`, cero migraciones, cero endpoints nuevos.

## Pruebas

- `dart analyze lib/features/event_registration/`: **0 issues.**
- `flutter test test/features/event_registration/ --concurrency=1`: **101/101 pass.**
- `flutter test test/features/events/presentation/detail/widgets/event_detail_participants_section_test.dart test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`: **7/7 pass** (verificado en esta revisión).
- Frontend reportó `flutter test` completo del repo: **974/974 pass** (incluye los 6 tests nuevos netos de esta corrida antes de la ronda de auditoría; QA sumó 4 más tras el rechazo del auditor Opus).
- Patrol e2e organizador: 1/1 pass en `emulator-5554`, con caveat de cobertura documentado (sin inscritos de seed para ejercitar la rama de contacto).

## Riesgos/watchlist

- **R1 (bajo, aceptado):** `bloodTypeRaw` fue una extensión de alcance sobre
  Fase 3 (prerrequisito bloqueante declarado). Es aditiva, de solo lectura,
  no rompe contratos ni consumidores existentes — riesgo residual mínimo.
- **R2 (deuda menor, no bloqueante):** clave ARB `registration_maskedValue`
  ("••••") queda sin call-sites tras el fix de AC10. No se eliminó en esta
  corrida (fuera de alcance explícito). Limpieza opcional de 1 línea si
  PO/tech lead lo decide.
- **R3 (seguimiento no bloqueante):** el Patrol organizador nuevo no ejercitó
  la rama de botones de contacto en esta ejecución por falta de datos de
  seed en "Mi Evento". Recomendado re-correr sembrando una inscripción de
  `qa1@gmail.com` con `allowOrganizerContact=true` antes de considerar el
  flujo 100% verificado e2e. No bloqueante porque la rama está cubierta por
  widget tests deterministas (`registration_contact_actions_test.dart`,
  `registration_detail_bottom_bar_test.dart`).
- **R4 (informativo):** el patrón `@JsonKey(includeFromJson: false, includeToJson: false)`
  sobre un super-parameter (`super.bloodTypeRaw`) es válido y funciona, pero
  si se replica en otro DTO sin el `@JsonKey`, el generador buscará
  (inofensivamente) una clave inexistente en el JSON del backend.
- Sin riesgos de seguridad, PII en logs, ni exposición de contratos backend
  detectados en el diff.

## Mensaje de commit sugerido

```
fix(event_registration): fallback de bloodType nullable con bloodTypeRaw (AC10 fase 7)

El resto del alcance de la fase 7 (isOrganizerView, RegistrationContactActions,
navegacion organizador, bottom bar) ya estaba implementado; esta corrida cierra
el unico gap real: bloodType null mostraba siempre "****" sin distinguir la
razon del backend. Se agrega bloodTypeRaw (modelo + DTO, solo lectura, nunca
serializado en escritura) y el fallback bloodType?.label ?? bloodTypeRaw ?? N/A.
Incluye tests deterministas de isOrganizerView (AC1/AC2/AC4), passthrough de
telefono ofuscado (AC9), parsing/serializacion de bloodTypeRaw (AC10), y un
nuevo Patrol e2e del flujo organizador.
```
