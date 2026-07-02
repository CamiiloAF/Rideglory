# Frontend — legal-privacidad-edad-fase3

## Baseline

`flutter test` no se pudo correr como baseline aislado: se lanzó en background al inicio de la sesión pero coincidió en el tiempo con los primeros `Edit` de este mismo agente (compilación concurrente), por lo que su output mezcla errores preexistentes del working tree sucio (otras fases WIP: p.ej. `EventFormState.waypoints` no definido en `route_points_card.dart`, no relacionado con esta fase) con el estado en edición. No se usó como referencia de aprobación; en su lugar se validó exclusivamente contra el estado final (ver `## Resultado final`).

`dart analyze` inicial (antes de tocar código) no se ejecutó por separado; el `dart analyze` final solo reporta 6 `info` preexistentes y no relacionados (curly braces, unnecessary underscores en tests de otro feature), 0 errores.

## Archivos cambiados

- `lib/features/event_registration/domain/model/event_registration_model.dart` — +4 campos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`), `bloodType` pasa a `BloodType?`, `copyWith` actualizado.
- `lib/features/event_registration/data/dto/event_registration_dto.dart` — +4 campos en el DTO; `_BloodTypeConverter` tolerante a centinelas (`__NOT_SHARED__`, `••••`) aplicado **a nivel de clase** (`@_BloodTypeConverter()` junto a `@_VehicleSummaryConverter()`), no a nivel de campo — ver nota de desviación abajo; `EventRegistrationModelExtension.toJson()` propaga los 4 campos nuevos (fix C1).
- `lib/features/event_registration/data/dto/event_registration_dto.g.dart` — regenerado.
- `lib/features/events/domain/model/event_model.dart` — +2 campos `organizerAcceptedResponsibilityAt`, `sosTriggeredAt`; `copyWith` actualizado.
- `lib/features/events/data/dto/event_dto.dart` — +2 campos en el DTO (`super.xxx`, sin `@JsonKey(name:)`, nombres JSON ya coinciden); `EventModelExtension.toJson()` los propaga.
- `lib/features/events/data/dto/event_dto.g.dart` — regenerado.
- `lib/features/users/domain/model/user_model.dart` — +1 campo `medicalConsentAcceptedAt`; se agregó `copyWith` completo (14 campos existentes + el nuevo), no existía antes.
- `lib/features/users/data/dto/user_dto.dart` — +1 campo, serialización estándar (sin converter custom); `UserModelExtension.toJson()` lo propaga.
- `lib/features/users/data/dto/user_dto.g.dart` — regenerado.
- `lib/features/event_registration/constants/registration_form_fields.dart` — +2 constantes `shareMedicalInfo`, `allowOrganizerContact` (solo declaración, no agregadas a `RegistrationWizardSteps.fieldsByStep`).
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` — `_preloadFromExistingRegistration` parchea los 2 booleanos nuevos (sin guard `if != null`, son no-nullable con default); `_buildRegistration` castea `formData[...]` a `BloodType?`.
- `lib/features/event_registration/presentation/registration_detail_page.dart` — línea 128: `registration.bloodType?.label ?? ''`.
- `test/features/event_registration/data/dto/event_registration_dto_test.dart` (nuevo) — AC#1, AC#2, AC#3.
- `test/features/events/data/dto/event_dto_test.dart` (nuevo) — AC#4.
- `test/features/users/data/dto/user_dto_test.dart` (nuevo) — AC#5.

### Desviación respecto al handoff: `_BloodTypeConverter` a nivel de clase, no de campo

El handoff pedía `@_BloodTypeConverter()` **en el campo `bloodType` dentro del constructor** (field-level). Se intentó exactamente así (`@_BloodTypeConverter() required super.bloodType,` y también en línea separada) y `build_runner`/`json_serializable` 6.11.2 **ignoró silenciosamente la anotación**: el `.g.dart` generado seguía usando `$enumDecodeNullable(_$BloodTypeEnumMap, json['bloodType'])` (el enum decoder automático de `@JsonValue`), no el converter custom. Esto no es un error de sintaxis — el analyzer no reporta nada — sino una limitación de `json_serializable` al leer anotaciones de tipo `JsonConverter` en parámetros `super.xxx` (a diferencia de `@JsonKey(name: ...)`, que sí funciona sobre `super.xxx`, confirmado en `createdDate`/`updatedDate` de `event_dto.dart`).

Fix aplicado: mover `@_BloodTypeConverter()` a **nivel de clase** (mismo patrón que `@_VehicleSummaryConverter()`, ya usado en el archivo), lo cual es seguro porque `bloodType` es el único campo de tipo `BloodType?` en `EventRegistrationDto`. Verificado en el `.g.dart` regenerado: `bloodType: const _BloodTypeConverter().fromJson(json['bloodType'] as String?)` y el `toJson` simétrico. Los 3 tests de AC#2 (sentinel `__NOT_SHARED__` → null, `••••` → null, `A_POSITIVE` → `BloodType.aPositive`) pasan contra el converter real, confirmando que el fix funciona end-to-end.

## Pruebas nuevas

- `test/features/event_registration/data/dto/event_registration_dto_test.dart` — 6 tests (TC-model-01, TC-dto-01..05): defaults de campos legales, tolerancia del converter a 2 centinelas + valor válido + clave ausente, `toJson()` propaga los 4 campos con valores exactos.
- `test/features/events/data/dto/event_dto_test.dart` — 2 tests (TC-dto-01, TC-dto-02): `fromJson` con ambos campos presentes (ISO-8601 → `DateTime` no-null) y ambos ausentes (→ `null`).
- `test/features/users/data/dto/user_dto_test.dart` — 2 tests (TC-dto-01, TC-dto-02): `fromJson` con `medicalConsentAcceptedAt` presente y ausente.

Total: 10 tests nuevos, los 10 pasan.

## Resultado final

```
dart run build_runner build --delete-conflicting-outputs   → OK, 0 errores
dart analyze                                                → 0 errores, 6 info preexistentes no relacionados
flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart \
              test/features/events/data/dto/event_dto_test.dart \
              test/features/users/data/dto/user_dto_test.dart  → 10/10 pass
flutter test test/features/event_registration test/features/events \
              test/features/users test/features/profile         → 215/215 pass
flutter test (suite completa)                                    → 899/899 pass, "All tests passed!", exit 0
```

testResult: `flutter test` → 899 pass / 0 fail.

## Verificación manual

- `grep -rn '\.bloodType\b' lib/` (guardrail AC#9 del handoff): único call-site no-null-safe fuera de la definición del modelo/DTO era `registration_detail_page.dart:128`, corregido con `?.label ?? ''`. Todos los demás sitios (`registration_form_cubit.dart`, `edit_profile_page.dart`, `rider_profile_repository_impl.dart`) ya usaban `?.`/`!`/guard `!= null` previo a este cambio.
- No se tocó `registration_service.dart`, `event_registration_repository_impl.dart`, `rider_profile_repository_impl.dart`, `rider_profile_model.dart`, `edit_profile_page.dart` (fuera de alcance, confirmado por guardrail).
- No se agregó `bloodTypeRaw` ni fallback `String?`.
- No se copió `_BloodTypeConverter` a `UserDto`/`UserModel`.
- No se agregaron los 2 nuevos campos de `event_registration` a `RegistrationWizardSteps.fieldsByStep` (fuera de alcance, fases 4/5/6).

## Notas para QA

- Los 4 campos legales de `EventRegistrationModel` (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) y los 2 de `EventModel` (`organizerAcceptedResponsibilityAt`, `sosTriggeredAt`) y el de `UserModel` (`medicalConsentAcceptedAt`) son puramente de dominio/data en esta fase — **no hay UI nueva**, no hay pantallas ni widgets que los muestren o permitan editarlos todavía (eso es fase 4/5/6 según el handoff).
- El único cambio de comportamiento observable end-to-end: `bloodType` ahora puede llegar como `null` desde el backend (cuando el campo está ofuscado con un centinela tipo `__NOT_SHARED__` o `••••` en respuestas donde el usuario no compartió el dato), y la UI de detalle de inscripción (`registration_detail_page.dart`) ya no crashea en ese caso — muestra string vacío en lugar del tipo de sangre.
- Recomendado para QA manual: cargar una inscripción existente en el detalle (`RegistrationDetailPage`) y confirmar que la fila "Tipo de sangre" no crashea ni muestra `null` textual cuando el backend envía un centinela u omite el campo.
- No se requiere verificación de wizard de inscripción (booleanos `shareMedicalInfo`/`allowOrganizerContact` no están en los pasos del wizard todavía, solo se preservan en preload/build si ya existían en una inscripción editada).
