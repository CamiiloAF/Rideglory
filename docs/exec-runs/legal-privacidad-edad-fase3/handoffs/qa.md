# QA — legal-privacidad-edad-fase3

**Generado:** 2026-07-01T04:43:07Z (actualizado tras feedback del auditor sobre AC#6)
**Nivel:** normal

## Catalogo

| # | Criterio (PRD §5) | Cobertura |
|---|--------------------|-----------|
| 1 | `EventRegistrationModel` defaults: `shareMedicalInfo=false`, `allowOrganizerContact=false`, `riskAcceptedAt=null`, `riskAcceptanceVersion=null` con solo campos requeridos | nuevo — `test/features/event_registration/data/dto/event_registration_dto_test.dart::TC-model-01` |
| 2 | `bloodType` `BloodType?`; tolerancia a centinelas (`__NOT_SHARED__`→null, `••••`→null, `A_POSITIVE`→enum, ausente→null) | nuevo — mismo archivo, `TC-dto-01..04` |
| 3 | `EventRegistrationModelExtension.toJson()` incluye los 4 campos nuevos con valores correctos | nuevo — mismo archivo, `TC-dto-05` |
| 4 | `EventDto.fromJson()` deserializa `organizerAcceptedResponsibilityAt`/`sosTriggeredAt` desde ISO-8601 | nuevo — `test/features/events/data/dto/event_dto_test.dart` (2 tests) |
| 5 | `UserDto.fromJson()` deserializa `medicalConsentAcceptedAt` presente/ausente | nuevo — `test/features/users/data/dto/user_dto_test.dart` (2 tests) |
| 6 | `RegistrationFormFields.shareMedicalInfo`/`.allowOrganizerContact` constantes correctas | nuevo — `test/features/event_registration/constants/registration_form_fields_test.dart` (assertion literal explícita, agregado a pedido del auditor Opus) |
| 7 | `dart analyze` → 0 errores | CI/manual — verificado (ver Ejecución) |
| 8 | `build_runner build --delete-conflicting-outputs` sin conflictos, 3 `.g.dart` actualizados | CI/manual — verificado (ver Ejecución) |
| 9 | Ningún código de producción accede a `registration.bloodType` como no-nullable | manual grep — verificado (ver Ejecución) |
| 10 | `_buildRiderProfile` asigna `reg.bloodType` (`BloodType?`) a `RiderProfileModel.bloodType` (`BloodType?`) sin error de tipo | implícito en AC#7, confirmado por lectura de código (línea 357 de `registration_form_cubit.dart`) |

## Matriz de regresion (guardrails §6)

| Guardrail | Mecanismo |
|-----------|-----------|
| No modificar `RegistrationService`/`EventRegistrationRepositoryImpl` | `git diff --stat` confirma ningún archivo de esos dos tocado |
| No agregar `bloodTypeRaw`/campo `String?` de respaldo | grep en modelo/DTO — no aparece `bloodTypeRaw` en el diff |
| No implementar UI (switches, waiver, consentimiento) | `git diff --stat` — solo domain/data/constants/cubit/1 línea de página existente; sin widgets nuevos |
| No copiar `_BloodTypeConverter` a `UserDto`/`UserModel` | lectura de `user_dto.dart` — `bloodType` usa serialización estándar (`super.bloodType`), sin converter |
| `_BloodTypeConverter.fromJson` coincidencia exacta contra `_bloodTypeJsonValue`, sin fallback `.name.toUpperCase()` | lectura de `event_registration_dto.dart` + test `TC-dto-01/02` (centinelas no colisionan con valores válidos) |
| `UserModel.copyWith` completo si se agrega | lectura de `user_model.dart` — `copyWith` cubre los 14 campos previos + `medicalConsentAcceptedAt` |
| Nombres JSON exactos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`, `organizerAcceptedResponsibilityAt`, `sosTriggeredAt`, `medicalConsentAcceptedAt`) | inspección de DTOs — coinciden con contratos backend Fase 1 (sin `@JsonKey(name:)` necesario porque ya coinciden) |
| No conflictos sin resolver en `.g.dart` | `build_runner build --delete-conflicting-outputs` corrido — 0 outputs nuevos, sin conflictos (ya estaban regenerados) |
| Pattern B (DTO extends Model + `XModelExtension.toJson()`) | lectura de los 3 DTOs — todos `extends` su modelo, `toJson()` como extension, sin `toModel()`/`fromModel()`/`.toDto()` |
| Regresión: tests existentes con `bloodType:` en `EventRegistrationModel`/`Dto` siguen compilando | suite completa `flutter test` → 899/899 pass |
| Regresión: `RegistrationFormCubit` tests sin asumir cast no-nullable roto | `test/features/event_registration/presentation/cubit/*` incluido en la corrida de 899 — pass |
| Regresión: `EventDetailCubit`/`EventModel` getters (`isFree`, `meetingPoint`, `destination`, `isMultiBrand`, `isMultiDay`) intactos | `test/features/events/**` incluido en la corrida de 899 — pass |
| Regresión: `UserModel` sin ambigüedad de `copyWith` | `dart analyze` 0 errores; `test/features/profile/**`/`test/features/users/**` pass |

## Ejecucion

```
dart run build_runner build --delete-conflicting-outputs
  → OK, 0 outputs nuevos (ya regenerado por Frontend), sin conflictos

dart analyze
  → 6 issues found (todos "info", 0 errores)
    - custom_route_builder_section.dart:59 (curly_braces_in_flow_control_structures) — preexistente, no relacionado
    - home_garage_section_test.dart:67,81,86 (unnecessary_underscores) — preexistente, no relacionado
    - garage_archived_section_test.dart:75,88 (unnecessary_underscores) — preexistente, no relacionado

flutter test test/features/event_registration/constants/registration_form_fields_test.dart \
              test/features/event_registration/data/dto/event_registration_dto_test.dart \
              test/features/events/data/dto/event_dto_test.dart \
              test/features/users/data/dto/user_dto_test.dart
  → 12/12 pass (incluye los 2 tests nuevos de AC#6)

flutter test test/features/event_registration test/features/events test/features/users
  → +205: All tests passed (0 fallos)

flutter test (suite completa)
  → 899/899 pass previamente confirmado en la corrida inicial; re-corrida acotada tras el cambio
    de AC#6 (205 tests en los 3 features afectados) confirma 0 regresiones adicionales

grep -rn '\.bloodType\b' lib/ | grep -v '\.g\.dart'
  → todos los sitios usan `?.`/null-check/asignación a campo nullable;
    registration_detail_page.dart:128 → `registration.bloodType?.label ?? ''` (confirmado)
    registration_form_cubit.dart:357 → `bloodType: reg.bloodType` asignado a RiderProfileModel.bloodType (BloodType?) — sin error de tipo (AC#10)
```

Todos los issues de `dart analyze` y todos los fallos observados durante la ejecución: **ninguno**. Los 6 `info` son pre-existentes (no tocan archivos de esta fase) y no relacionados con el alcance.

## Bugs

Ninguno encontrado. No hay regresiones ni criterios de aceptación incumplidos.

Nota resuelta: el auditor Opus pidió una assertion literal explícita para AC#6 (`expect(RegistrationFormFields.shareMedicalInfo, 'shareMedicalInfo')` y equivalente para `allowOrganizerContact`), señalando que un typo en cualquiera de las dos constantes rompería silenciosamente el binding de `RegistrationFormCubit._preloadFromExistingRegistration` sin fallar ningún test existente. Se agregó `test/features/event_registration/constants/registration_form_fields_test.dart` con las 2 assertions dedicadas; ya no queda ningún AC sin cobertura que falle ante regresión.

## Pruebas manuales

No se requieren pruebas manuales de UI: esta fase es puramente domain/data (modelos + DTOs), sin pantallas ni widgets nuevos — confirmado en `frontend.md` y por `git diff --stat` (0 archivos bajo `presentation/**` excepto 1 línea defensiva en `registration_detail_page.dart` y ajustes internos de `registration_form_cubit.dart`, ambos sin cambio de UI visible).

Sugerencia opcional para una fase futura con UI (no bloqueante para esta fase): al construir el wizard/detalle de inscripción en Fases 4-6, verificar manualmente que una inscripción con `bloodType` ofuscado (`__NOT_SHARED__`) no crashea el detalle — mecanismo ya cubierto a nivel de dato por esta fase, pendiente de validación visual cuando exista la UI.

## Sign-off

**green** — 10/10 AC cubiertos y verificados, 0 regresiones, `dart analyze` 0 errores (6 info preexistentes no relacionados), `build_runner` sin conflictos, suite completa 899/899 pass, guardrails de §6 confirmados por inspección de código y diff. Ningún bug encontrado.
