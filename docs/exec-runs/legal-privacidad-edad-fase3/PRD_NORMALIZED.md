# PRD Normalizado — legal-privacidad-edad-fase3 (Modelos y DTOs Flutter)

**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-03-modelos-y-dtos-flutter.md`
**Nivel rg-exec:** normal
**dependsOn:** Fase 1 (contratos backend)
**Generado:** 2026-07-01T04:17:36Z

---

## 1. Objetivo

Extender los modelos de dominio y DTOs de Flutter para reflejar los campos legales definidos en los contratos del backend (Fase 1). Al finalizar, la app debe poder serializar y enviar los 4 campos legales de inscripción en el body del POST, `EventModel` debe exponer los timestamps de responsabilidad del organizador y SOS, y `UserModel` debe portar el timestamp de consentimiento médico (Ley 1581) — sin descartes silenciosos en ningún payload de escritura.

## 2. Por qué

El backend (Fase 1) ya define los campos legales/de privacidad en sus contratos (consentimiento médico, waiver de riesgo, contacto del organizador, responsabilidad del organizador, SOS). Si el frontend Flutter no refleja estos campos en sus modelos/DTOs, cualquier payload de escritura descartará silenciosamente esta información legal crítica (riesgo de cumplimiento — Ley 1581 de protección de datos y responsabilidad legal en eventos de riesgo). Además, el backend puede retornar centinelas de ofuscación (`"__NOT_SHARED__"`, `"••••"`) en `bloodType` que el enum actual no tolera, lo que rompería la deserialización.

## 3. Alcance

### Entra
- `EventRegistrationModel`: +4 campos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) y cambio de tipo de `bloodType` de `BloodType` (no-nullable) a `BloodType?` con `_BloodTypeConverter` custom.
- `EventRegistrationDto`: mismos 4 campos + `bloodType: BloodType?` con `_BloodTypeConverter`; regenerar `.g.dart`.
- `EventRegistrationModelExtension.toJson()`: incluir los 4 campos nuevos (corrección C1 — evitar descarte silencioso).
- `EventModel`/`EventDto`: +2 campos (`organizerAcceptedResponsibilityAt`, `sosTriggeredAt`); `toJson()` actualizado; regenerar `.g.dart`.
- `UserModel`/`UserDto`: +1 campo (`medicalConsentAcceptedAt`); `copyWith` completo en `UserModel` si no existe; `toJson()` actualizado; regenerar `.g.dart`.
- `RegistrationFormFields`: +2 constantes (`shareMedicalInfo`, `allowOrganizerContact`).
- `RegistrationFormCubit`: `_preloadFromExistingRegistration` parchea los 2 booleanos nuevos; `_buildRegistration` cast a `BloodType?`.
- `registration_detail_page.dart` línea 128: `registration.bloodType?.label ?? ''` para compilar con el tipo nullable.
- Gate de calidad: `dart analyze` sin errores + `dart run build_runner build --delete-conflicting-outputs` sin conflictos.
- Tests unitarios de `toJson()` y de `_BloodTypeConverter` (incluyendo tolerancia a centinelas).

### No entra
- Lógica de UI (switches, pantallas de waiver, consentimiento) — Fases 4, 5 y 6.
- Ofuscación en el frontend — el backend retorna los centinelas, Flutter los renderiza tal cual en Fase 7.
- Campo `bloodTypeRaw: String?` de respaldo en el modelo — no se agrega en esta fase.
- Cambios en `RegistrationService` ni en `EventRegistrationRepositoryImpl` (el repo ya llama `registration.toJson()`; solo cambia el contenido).
- Nuevos use cases o interfaces de repositorio.
- Cambios en el backend (`rideglory-api`).

## 4. Áreas afectadas (best-effort)

- `lib/features/event_registration/domain/model/event_registration_model.dart`
- `lib/features/event_registration/data/dto/event_registration_dto.dart` (+ `.g.dart` autogenerado)
- `lib/features/events/domain/model/event_model.dart`
- `lib/features/events/data/dto/event_dto.dart` (+ `.g.dart` autogenerado)
- `lib/features/users/domain/model/user_model.dart`
- `lib/features/users/data/dto/user_dto.dart` (+ `.g.dart` autogenerado)
- `lib/features/event_registration/constants/registration_form_fields.dart`
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`
- `lib/features/event_registration/presentation/registration_detail_page.dart`
- Tests nuevos: `test/features/event_registration/data/dto/event_registration_dto_test.dart`, `test/features/events/data/dto/event_dto_test.dart`, `test/features/users/data/dto/user_dto_test.dart`

## 5. Criterios de aceptación (numerados, observables, testeables)

1. `EventRegistrationModel` tiene los 4 campos nuevos con sus defaults correctos: instanciado con solo los campos requeridos existentes, `shareMedicalInfo` es `false`, `allowOrganizerContact` es `false`, `riskAcceptedAt` es `null`, `riskAcceptanceVersion` es `null`.
2. `bloodType` en el modelo es `BloodType?`; deserialización tolerante a centinelas: `EventRegistrationDto.fromJson({'bloodType': '__NOT_SHARED__', ...})` completa sin excepción y `bloodType` retorna `null`; con `'A_POSITIVE'` retorna `BloodType.aPositive`; con `'••••'` retorna `null`.
3. `EventRegistrationModelExtension.toJson()` incluye los 4 campos en el body de escritura: modelo con `shareMedicalInfo: true`, `allowOrganizerContact: false`, `riskAcceptedAt: DateTime(2026, 6, 19)`, `riskAcceptanceVersion: 'v0.1-2026-06'` → `.toJson()` contiene las 4 claves con los valores correctos (criterio canónico, no requiere curl).
4. `EventDto.fromJson()` deserializa `organizerAcceptedResponsibilityAt` y `sosTriggeredAt` sin lanzar excepción, con `DateTime?` correctos a partir de strings ISO-8601.
5. `UserDto.fromJson()` deserializa `medicalConsentAcceptedAt` sin lanzar excepción, tanto con el campo presente como ausente (`DateTime?` correcto en ambos casos).
6. `RegistrationFormFields` expone las 2 nuevas constantes: `shareMedicalInfo == 'shareMedicalInfo'` y `allowOrganizerContact == 'allowOrganizerContact'`.
7. `dart analyze` retorna 0 errores (warnings aceptables solo si son preexistentes y documentados).
8. `dart run build_runner build --delete-conflicting-outputs` completa sin errores ni conflictos; los 3 archivos `.g.dart` afectados quedan actualizados.
9. Ningún código de producción accede a `registration.bloodType` como `BloodType` no-nullable directamente (`grep -rn '\.bloodType\b' lib/` — cada resultado usa `?.` o null check explícito); línea 128 de `registration_detail_page.dart` muestra `registration.bloodType?.label ?? ''`.
10. `_buildRiderProfile` en `RegistrationFormCubit` asigna `reg.bloodType` (`BloodType?`) a `RiderProfileModel.bloodType` (`BloodType?`) sin error de tipo (confirmado por AC#7).

## 6. Guardrails de regresión

- No modificar `RegistrationService` ni `EventRegistrationRepositoryImpl` — el `toJson()` ya es llamado correctamente por el repo; solo cambia su contenido.
- No agregar `bloodTypeRaw` ni ningún campo `String?` de respaldo al modelo de dominio — el render de centinelas es de Fase 7.
- No implementar UI (switches, waiver, consentimiento) — eso es de Fases 4/5/6.
- No copiar `_BloodTypeConverter` a `UserDto`/`UserModel` — la vista `GET /users/me` nunca se ofusca (regla confirmada en Fase 2); usar serialización estándar de `json_serializable` para `bloodType` en `UserDto`.
- El `_BloodTypeConverter.fromJson` debe usar coincidencia exacta contra `_bloodTypeJsonValue` (los 8 valores `@JsonValue` del enum) — no usar `bt.name.toUpperCase()` como fallback (genera falsos positivos, ej. `'APOSITIVE'` ≠ `'A_POSITIVE'`).
- `UserModel.copyWith`, si no existe, debe agregarse completo (no parcial) para no dejar el modelo con un `copyWith` incompleto.
- No tocar el backend (`rideglory-api`) — los contratos ya están cerrados en Fase 1; los nombres de campo JSON en los DTOs Flutter deben coincidir exactamente (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`, `organizerAcceptedResponsibilityAt`, `sosTriggeredAt`, `medicalConsentAcceptedAt`); usar `@JsonKey(name: '...')` si algún nombre difiere.
- No dejar conflictos sin resolver en `.g.dart` — usar `--delete-conflicting-outputs`; si falla, correr `dart run build_runner clean` primero.
- Preservar el patrón Pattern B obligatorio del proyecto: DTOs extienden su modelo 1:1 (`XDto extends XModel`), con `XModelExtension.toJson()`; no usar `toModel()`/`fromModel()`/`.toDto()`.

## 7. Constraints heredados

- Clean Architecture: domain sin imports de Flutter ni I/O de red; data sin `BuildContext`; presentation sin llamadas HTTP directas ni exposición de DTOs.
- Pattern B de DTOs es mandatorio (ver `.claude/rules/rideglory-coding-standards.mdc` y `docs/prds/prd-dto-inheritance-standard.md`); referencia canónica: `lib/features/events/data/dto/event_dto.dart`.
- Cubits: `Cubit<ResultState<T>>` para operaciones simples; sin flags booleanos de loading/error.
- Strings de UI: no aplica en esta fase (no hay UI nueva), pero cualquier string visible futura debe ir en `app_es.arb` vía `context.l10n`.
- `dart analyze` debe pasar antes de considerar la fase completa; exclusiones estándar `**/*.g.dart`, `**/*.freezed.dart`.
- No commitear cambios — el árbol de trabajo queda sucio para revisión humana (regla de la corrida rg-exec).
- No modificar `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`, ni la nota fuente original del plan.
