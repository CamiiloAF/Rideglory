# Summary — legal-privacidad-edad-fase3 (Modelos y DTOs Flutter)

**Fecha revisión:** 2026-07-01T04:47:00Z
**Nivel:** normal
**Veredicto Tech Lead:** ready

## Objetivo

Extender los modelos de dominio y DTOs Flutter con los campos legales/de privacidad ya definidos
en los contratos del backend (Fase 1): 4 campos legales en `EventRegistrationModel`
(`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`),
tolerancia a centinelas de ofuscación en `bloodType` (`BloodType?` + `_BloodTypeConverter`),
2 timestamps de responsabilidad/SOS en `EventModel`, y 1 timestamp de consentimiento médico en
`UserModel`. Sin UI nueva — puramente domain/data.

## Qué cambió por área

### Domain
- `event_registration_model.dart`: `bloodType` pasa de `BloodType` a `BloodType?`; +4 campos legales
  con defaults (`false`/`false`/`null`/`null`); `copyWith` actualizado.
- `event_model.dart`: +2 campos `DateTime?` (`organizerAcceptedResponsibilityAt`, `sosTriggeredAt`);
  `copyWith` actualizado.
- `user_model.dart`: +1 campo `DateTime? medicalConsentAcceptedAt`; se agregó `copyWith` completo
  (no existía) cubriendo los 14 campos previos + el nuevo.

### Data (DTOs)
- `event_registration_dto.dart`: +4 campos en el constructor DTO; `_BloodTypeConverter`
  (`JsonConverter<BloodType?, String?>`) con *match* exacto contra los 8 `@JsonValue` del enum
  (sin fallback `.name.toUpperCase()`), aplicado a **nivel de clase** (no de campo — desviación
  documentada frente al handoff del architect, causada por una limitación real de
  `json_serializable` con converters en parámetros `super.xxx`; verificada contra el `.g.dart`
  generado). `EventRegistrationModelExtension.toJson()` propaga los 4 campos nuevos.
- `event_dto.dart`: +2 campos, serialización estándar vía `apiJsonDateTimeConverters` (nivel de
  clase, ya cubre los nuevos `DateTime?`); `toJson()` los propaga.
- `user_dto.dart`: +1 campo, serialización estándar (sin converter — el campo nunca se ofusca);
  `toJson()` lo propaga.
- Los 3 `.g.dart` (gitignorados) están regenerados y verificados contra el código fuente.

### Presentation
- `registration_form_fields.dart`: +2 constantes (`shareMedicalInfo`, `allowOrganizerContact`),
  solo declaración (no añadidas a `fieldsByStep` — correcto, es alcance de fases 4/5/6).
- `registration_form_cubit.dart`: `_preloadFromExistingRegistration` parchea los 2 booleanos
  nuevos; `_buildRegistration` castea `bloodType` a `BloodType?`.
- `registration_detail_page.dart`: línea 128 usa `registration.bloodType?.label ?? ''` (fix de
  compilación necesario tras el cambio de tipo).

### Tests (nuevos)
- `test/features/event_registration/data/dto/event_registration_dto_test.dart` (6 tests: defaults,
  3 casos de tolerancia a centinelas/valor válido/ausencia, `toJson()`).
- `test/features/events/data/dto/event_dto_test.dart` (2 tests: ambos campos presentes/ausentes).
- `test/features/users/data/dto/user_dto_test.dart` (2 tests: campo presente/ausente).
- `test/features/event_registration/constants/registration_form_fields_test.dart` (2 tests:
  assertions literales de las nuevas constantes — agregado a pedido del auditor Opus de QA para
  blindar AC#6 contra typos silenciosos).

## Archivos

```
 lib/features/event_registration/constants/registration_form_fields.dart          |  2 ++
 lib/features/event_registration/data/dto/event_registration_dto.dart             | 37 +++++++++++++++++++
 lib/features/event_registration/domain/model/event_registration_model.dart       | 22 +++++++++++-
 lib/features/event_registration/presentation/cubit/registration_form_cubit.dart  |  6 +++-
 lib/features/event_registration/presentation/registration_detail_page.dart       |  2 +-
 lib/features/events/data/dto/event_dto.dart                                      |  4 +++
 lib/features/events/domain/model/event_model.dart                                |  6 ++++
 lib/features/users/data/dto/user_dto.dart                                        |  2 ++
 lib/features/users/domain/model/user_model.dart                                  | 42 ++++++++++++++++++++++
 9 files changed, 120 insertions(+), 3 deletions(-)
```

Más 3 `.g.dart` regenerados (gitignorados, no aparecen en `git diff`) y 4 archivos de test nuevos.
100% de los archivos tocados están en el change map del architect — 0 archivos fuera de mapa.

## Pruebas

Re-ejecutadas y verificadas de forma independiente por Tech Lead (no solo confiando en los
handoffs):

```
dart run build_runner build --delete-conflicting-outputs
  → OK, 0 outputs nuevos (ya regenerados), sin conflictos

dart analyze
  → 6 issues, todos "info" preexistentes no relacionados con esta fase
    (curly_braces_in_flow_control_structures en custom_route_builder_section.dart;
     unnecessary_underscores en home_garage_section_test.dart y garage_archived_section_test.dart)
  → 0 errores

flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart \
              test/features/events/data/dto/event_dto_test.dart \
              test/features/users/data/dto/user_dto_test.dart \
              test/features/event_registration/constants/registration_form_fields_test.dart
  → 12/12 pass

flutter test (suite completa)
  → 901/901 pass, "All tests passed!", exit 0
```

Cada AC del PRD (§5, 10 criterios) tiene cobertura de test explícita o verificación manual
documentada — ver `handoffs/qa.md` para el catálogo AC→test.

## Riesgos / watchlist

- **Desviación documentada (no bloqueante):** `@_BloodTypeConverter()` se aplicó a nivel de clase
  en vez de nivel de campo (como especificaba el handoff del architect), por una limitación real
  de `json_serializable` 6.11.2 con converters en parámetros `super.xxx`. Es seguro porque
  `bloodType` es el único campo `BloodType?` en `EventRegistrationDto`; verificado contra el
  `.g.dart` generado (`const _BloodTypeConverter().fromJson(...)` aplicado correctamente). Si en
  una fase futura se agrega un segundo campo de tipo `BloodType?` a este DTO, este patrón de
  clase dejaría de ser seguro y habría que revisarlo.
- **Riesgo de negocio aceptado y documentado por el architect:** los centinelas de ofuscación de
  `bloodType` (`__NOT_SHARED__`, `••••`) aún no existen en el backend real (Fase 2 de ofuscación
  no implementada todavía) — la tolerancia se construyó de forma defensiva, adelantada a Fase 2.
  No es un blocker de esta fase (el PRD lo declara explícitamente como dependencia futura), pero
  el equipo debe confirmar en Fase 2 que los valores centinela reales coinciden exactamente con
  los strings usados en los tests (`'__NOT_SHARED__'`, `'••••'`).
- **`copyWith` con patrón `??`:** tanto en `EventRegistrationModel` como en `UserModel`, los campos
  nuevos usan el patrón estándar `campo ?? this.campo` en `copyWith`, lo que significa que no se
  puede resetear un campo `DateTime?`/`String?` a `null` vía `copyWith` (limitación preexistente y
  consistente con el resto del código base — no es una regresión introducida por esta fase).
- **Sin UI todavía:** los 7 campos nuevos no tienen ningún punto de entrada de UI en esta fase
  (correcto, es alcance de Fases 4-6); QA no requiere pruebas manuales de pantalla.

## Mensaje de commit sugerido

```
feat(legal): extender modelos y DTOs Flutter con campos legales de privacidad (fase 3)

Agrega los 4 campos de consentimiento/waiver a EventRegistrationModel/Dto (con
tolerancia a centinelas de ofuscación en bloodType vía BloodType? + _BloodTypeConverter),
2 timestamps de responsabilidad/SOS a EventModel/Dto, y el timestamp de consentimiento
médico a UserModel/Dto (incluye copyWith completo, antes inexistente). Corrige el único
call-site no-null-safe de bloodType en registration_detail_page.dart. Sin UI nueva —
domain/data únicamente, preparando el terreno para las fases 4-7 (wizard, waiver,
ofuscación visual).
```
