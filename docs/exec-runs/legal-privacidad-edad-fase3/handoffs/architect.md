# Architect — legal-privacidad-edad-fase3 (Modelos y DTOs Flutter)

**Generado:** 2026-07-01T04:20:26Z
**Contrato:** `docs/exec-runs/legal-privacidad-edad-fase3/PRD_NORMALIZED.md`

## Decisiones

- **frontendChanges = true**; backendChanges = false, dbChanges = false, uiChanges = false, needsDesign = false. Toda la fase es Flutter domain/data (modelos + DTOs + un cast en un cubit existente + una línea de UI de solo-lectura); no hay pantallas, widgets nuevos ni flujos de interacción. `registration_detail_page.dart` línea 128 es un cambio de null-safety puntual (`?.label ?? ''`), no una decisión de diseño — no requiere Pencil.
- Verifiqué los contratos reales en `rideglory-api` (no solo el PRD) para confirmar nombres de campo JSON exactos:
  - `EventRegistrationDto`: `shareMedicalInfo` y `allowOrganizerContact` son `@IsOptional() @IsBoolean()` en `CreateRegistrationDto`/`UpdateRegistrationDto` (rideglory-contracts/src/events/dto/create-registration.dto.ts) → default `false` en Flutter es correcto. `riskAcceptedAt`/`riskAcceptanceVersion` también opcionales ahí.
  - `bloodType` en `CreateRegistrationDto` sigue siendo `@IsEnum(BloodType)` **requerido** (no opcional) en el body de escritura — el modelo Flutter se vuelve `BloodType?` solo para tolerar deserialización de centinelas en lecturas (GET), pero el wizard (fuera de alcance) sigue exigiendo selección antes de poder enviar el registro. No hay riesgo de 400 en escritura porque el formulario ya valida `bloodType` como campo requerido del step 2 (`RegistrationWizardSteps.fieldsByStep`), sin cambios en esta fase.
  - `EventModel`: `organizerAcceptedResponsibilityAt` SÍ está whitelisted en `CreateEventDto`/`UpdateEventDto` (aceptado en escritura, usado por Fase 5). `sosTriggeredAt` NO está en `CreateEventDto` (es servidor-controlado, mutado solo por el endpoint de SOS) — pero el `api-gateway` usa `ValidationPipe({ whitelist: true })` **sin** `forbidNonWhitelisted`, por lo que si `EventModelExtension.toJson()` incluye `sosTriggeredAt` en un PATCH/POST de evento, el campo se descarta silenciosamente en el backend sin error 400. Confirmado seguro incluirlo en el `toJson()` generado (no hace falta excluirlo con `@JsonKey(includeToJson: false)`).
  - `UserModel.medicalConsentAcceptedAt`: columna directa en el modelo Prisma `User` (`Date | null`), expuesta tal cual en `GET /users/me`; no hay ofuscación para este campo (confirma el guardrail "la vista GET /users/me nunca se ofusca").
  - Los centinelas de `bloodType` (`__NOT_SHARED__`, `••••`) descritos en el PRD corresponden a la ofuscación que implementará Fase 2 (backend, "validación de edad y ofuscación condicional") — no encontré lógica de ofuscación de `bloodType` ya desplegada en `rideglory-api` hoy, pero la tolerancia en Flutter debe construirse igual ahora (defensiva, ver AC#2) porque Fase 3 solo depende de Fase 1, no de Fase 2.
- Patrón `_BloodTypeConverter`: `JsonConverter<BloodType?, String?>` local a `event_registration_dto.dart` (mismo archivo, no un archivo nuevo) — sigue el patrón ya usado en el mismo archivo para `_VehicleSummaryConverter`. `fromJson` hace *match* exacto contra los 8 valores `@JsonValue` de `BloodType` (switch/map explícito) y retorna `null` para cualquier otro string (incluye centinelas); nunca usa `bt.name.toUpperCase()` como fallback (guardrail explícito del PRD — evita falsos positivos como `'APOSITIVE'`).
- `UserModel` no tiene `copyWith` hoy — se agrega completo (todos los 14 campos existentes + `medicalConsentAcceptedAt`), no parcial.
- `RegistrationFormCubit._buildRegistration()` línea ~333: cambia `formData[RegistrationFormFields.bloodType] as BloodType` → `as BloodType?`, porque `EventRegistrationModel.bloodType` ahora es `BloodType?`. El formulario del wizard sigue validando el campo como requerido (fuera de alcance de esta fase), así que en la práctica el valor nunca es null en un submit exitoso; el cast solo deja de forzar un tipo no-nulo que ya no coincide con la firma del modelo.
- `_buildRiderProfile` no necesita cambios de código (ya asigna `reg.bloodType` a `RiderProfileModel.bloodType`, que ya era `BloodType?`); el AC#10 se satisface automáticamente al hacer `EventRegistrationModel.bloodType` nullable — queda confirmado por `dart analyze` (AC#7), no requiere una edición separada.
- `registration_form_content.dart` y `registration_blood_type_selector.dart` (grep de `.bloodType`) no necesitan cambios: interactúan vía `FormBuilderState`/nombres de campo dinámicos (`dynamic`), no acceden a `.bloodType` tipado directamente.
- `rider_profile_repository_impl.dart:62` (`profile.bloodType!.name`) no se toca — `RiderProfileModel.bloodType` ya era `BloodType?` antes de esta fase; no está en el §4 del PRD y no lo afecta el cambio de `EventRegistrationModel`.
- `edit_profile_page.dart:95` (`widget.user.bloodType?.name`) no se toca — ya usa `?.`, no está en el §4 del PRD, y `UserModel.bloodType` no cambia de tipo en esta fase (guardrail: no copiar el converter a `UserDto`/`UserModel`).

## Change map

| file | action | reason | risk |
|---|---|---|---|
| `lib/features/event_registration/domain/model/event_registration_model.dart` | modify | +4 campos (`shareMedicalInfo` bool default false, `allowOrganizerContact` bool default false, `riskAcceptedAt` DateTime?, `riskAcceptanceVersion` String?); `bloodType` cambia de `BloodType` a `BloodType?`; `copyWith` actualizado con los 4 campos nuevos | med |
| `lib/features/event_registration/data/dto/event_registration_dto.dart` | modify | +4 campos en constructor DTO; `bloodType` → `BloodType?` con `@_BloodTypeConverter()` a nivel de campo (no de clase, para no afectar otros converters de la clase); definir `_BloodTypeConverter` (match exacto contra los 8 `@JsonValue`, retorna `null` en cualquier otro caso); `EventRegistrationModelExtension.toJson()` propaga los 4 campos nuevos | high |
| `lib/features/event_registration/data/dto/event_registration_dto.g.dart` | modify (autogenerado) | regenerado por `build_runner` tras el cambio de DTO | low |
| `lib/features/events/domain/model/event_model.dart` | modify | +2 campos `organizerAcceptedResponsibilityAt` (DateTime?), `sosTriggeredAt` (DateTime?); `copyWith` actualizado | low |
| `lib/features/events/data/dto/event_dto.dart` | modify | +2 campos en constructor DTO (nombres JSON ya coinciden 1:1 con backend, sin `@JsonKey`); `EventModelExtension.toJson()` propaga los 2 campos (seguro por whitelist sin forbidNonWhitelisted, ver Decisiones) | low |
| `lib/features/events/data/dto/event_dto.g.dart` | modify (autogenerado) | regenerado por `build_runner` | low |
| `lib/features/users/domain/model/user_model.dart` | modify | +1 campo `medicalConsentAcceptedAt` (DateTime?); agregar `copyWith` completo (no existe hoy) | med |
| `lib/features/users/data/dto/user_dto.dart` | modify | +1 campo en constructor DTO (serialización estándar `json_serializable`, sin converter custom — el campo nunca se ofusca); `UserModelExtension.toJson()` lo propaga | low |
| `lib/features/users/data/dto/user_dto.g.dart` | modify (autogenerado) | regenerado por `build_runner` | low |
| `lib/features/event_registration/constants/registration_form_fields.dart` | modify | +2 constantes `shareMedicalInfo`, `allowOrganizerContact` (solo declaración; no se agregan a `RegistrationWizardSteps.fieldsByStep` — eso es UI de Fases 4/5/6) | low |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | modify | `_preloadFromExistingRegistration` hace `patchValue` de los 2 booleanos nuevos (siempre, sin `if != null` porque son no-nulos con default); `_buildRegistration` cambia el cast de `bloodType` a `as BloodType?` | med |
| `lib/features/event_registration/presentation/registration_detail_page.dart` | modify | línea 128: `registration.bloodType.label` → `registration.bloodType?.label ?? ''` (requerido para compilar tras el cambio de tipo) | low |
| `test/features/event_registration/data/dto/event_registration_dto_test.dart` | create | Cubre AC#1 (defaults), AC#2 (tolerancia a centinelas — con `'__NOT_SHARED__'`, `'••••'`, `'A_POSITIVE'`), AC#3 (`toJson()` incluye los 4 campos con valores correctos) | low |
| `test/features/events/data/dto/event_dto_test.dart` | create | Cubre AC#4 (`fromJson` con ambos campos como strings ISO-8601, sin excepción) | low |
| `test/features/users/data/dto/user_dto_test.dart` | create | Cubre AC#5 (`fromJson` con y sin `medicalConsentAcceptedAt` presente) | low |

**No tocar** (guardrails explícitos, confirmados contra el código real): `lib/features/event_registration/data/service/registration_service.dart`, `lib/features/event_registration/data/repository/event_registration_repository_impl.dart`, `lib/features/events/domain/model/rider_profile_model.dart`, `lib/features/events/data/repository/rider_profile_repository_impl.dart`, `lib/features/profile/presentation/edit_profile_page.dart`, cualquier archivo bajo `rideglory-api`.

## Contratos

Sin cambios de contrato — Fase 1 (backend) ya cerró los contratos. Verificación cruzada realizada contra `rideglory-api` (no solo el PRD):

| Campo Flutter | Fuente backend verificada | Tipo/nullability confirmada |
|---|---|---|
| `EventRegistrationModel.shareMedicalInfo` | `create-registration.dto.ts`: `@IsOptional() @IsBoolean() shareMedicalInfo?: boolean` | opcional en escritura → default `false` en Flutter es seguro |
| `EventRegistrationModel.allowOrganizerContact` | ídem, `allowOrganizerContact?: boolean` | opcional → default `false` |
| `EventRegistrationModel.riskAcceptedAt` | ídem, `@IsOptional() @Type(() => Date) @IsDate() riskAcceptedAt?: Date` | opcional → default `null` |
| `EventRegistrationModel.riskAcceptanceVersion` | `event-registration.dto.ts` (response): `riskAcceptanceVersion!: string \| null` | nullable → default `null` |
| `EventRegistrationModel.bloodType` | `event-registration.dto.ts` (response) declara `bloodType!: BloodType` no-nullable en el tipo TS, pero el PRD documenta que el valor real puede ser un centinela string cuando Fase 2 (backend) active la ofuscación — no verificable hoy porque Fase 2 aún no está implementada en `rideglory-api`; tratar como riesgo conocido y aceptado (defensivo) | `BloodType?` en Flutter, tolerante |
| `EventModel.organizerAcceptedResponsibilityAt` | `create-event.dto.ts`: `@IsOptional() @Type(() => Date) @IsDate() organizerAcceptedResponsibilityAt?: Date`; Prisma `Event.organizerAcceptedResponsibilityAt: DateTime?` | nullable, aceptado en request y response |
| `EventModel.sosTriggeredAt` | Prisma `Event.sosTriggeredAt: DateTime?`; mutado solo por `events.service.ts` (`triggerSos`/`resolveSos`), NO en `CreateEventDto` | nullable, solo-lectura desde la perspectiva del cliente |
| `UserModel.medicalConsentAcceptedAt` | Prisma `User.medicalConsentAcceptedAt: DateTime?`; `users.service.ts` lo persiste vía `PATCH /users/me/medical-consent` (endpoint separado, Fase 1) y lo devuelve en `GET /users/me` como columna directa | nullable, sin ofuscación |

No se requiere `analysis/MIGRATION_PLAN.md` (no hay migraciones — Fase 1 ya las aplicó en backend) ni `analysis/ENV_DELTA.md` (sin cambios de entorno).

## Datos/migraciones

N/A — esta fase no toca `rideglory-api`, no hay migraciones Prisma que ejecutar ni schemas que cambiar. Los campos ya existen en la base de datos desde Fase 1.

## Env

N/A — sin cambios de variables de entorno, `.env`, ni configuración de Firebase Remote Config.

## Riesgos

- **Riesgo de tipo en cascada:** cambiar `EventRegistrationModel.bloodType` a `BloodType?` rompe la compilación en cualquier punto que lo trate como no-nulo. Grep exhaustivo confirma un solo punto de uso no-nulo fuera de la definición del modelo: `registration_detail_page.dart:128`. El cast en `registration_form_cubit.dart:333` también debe actualizarse (ya identificado en el PRD). Verificar con `dart analyze` tras el cambio (AC#7) antes de dar la fase por completa.
- **Build runner conflicts:** los 3 `.g.dart` afectados deben regenerarse en el mismo `dart run build_runner build --delete-conflicting-outputs`; si el build falla por conflictos, correr `dart run build_runner clean` primero (ya documentado como guardrail).
- **`_BloodTypeConverter` mal implementado (fallback laxo):** si el converter usa `bt.name.toUpperCase()` en vez de un match exacto contra los 8 `@JsonValue`, puede producir falsos positivos silenciosos con strings casi-válidos. Los tests nuevos deben cubrir explícitamente los 3 casos del AC#2 (centinela `__NOT_SHARED__`, centinela `••••`, valor válido `A_POSITIVE`) para blindar contra esta regresión.
- **`UserModel.copyWith` parcial:** si se agrega incompleto (olvidando algún campo existente), cualquier código futuro que dependa de `copyWith` para preservar campos no listados los perdería silenciosamente (se resetearían a los valores por defecto del constructor, que para la mayoría son `null`). Debe incluir los 14 campos actuales + el nuevo.
- **Riesgo bajo/nulo de regresión en escritura de eventos:** incluir `sosTriggeredAt` en `EventModelExtension.toJson()` es seguro porque el `ValidationPipe` del api-gateway usa `whitelist: true` sin `forbidNonWhitelisted`, así que el campo se descarta sin error si se envía en un create/update de evento. Confirmado leyendo `api-gateway/src/main.ts:23`.

## Orden

1. `lib/features/event_registration/domain/model/event_registration_model.dart` (base — nada más compila sin esto)
2. `lib/features/event_registration/data/dto/event_registration_dto.dart` (+ `_BloodTypeConverter`)
3. `lib/features/events/domain/model/event_model.dart`
4. `lib/features/events/data/dto/event_dto.dart`
5. `lib/features/users/domain/model/user_model.dart` (+ `copyWith`)
6. `lib/features/users/data/dto/user_dto.dart`
7. `dart run build_runner build --delete-conflicting-outputs` (regenera los 3 `.g.dart`)
8. `lib/features/event_registration/constants/registration_form_fields.dart`
9. `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` (patchValue + cast)
10. `lib/features/event_registration/presentation/registration_detail_page.dart` (fix de compilación)
11. `dart analyze` (gate — 0 errores)
12. Tests nuevos: `event_registration_dto_test.dart`, `event_dto_test.dart`, `user_dto_test.dart`
13. `flutter test` sobre los tests nuevos + suite existente que toque estos modelos (`test/features/events/presentation/cubit/event_detail_cubit_test.dart`, `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart`, etc. — confirmar que no rompieron por el cambio de tipo)

## Superficie de regresión

- Cualquier test existente que construya `EventRegistrationModel` o `EventRegistrationDto` con `bloodType:` posicional/nombrado sigue compilando (el tipo acepta valores no-nulos igual, solo se relaja la nulabilidad) — no se esperan roturas, pero corren igual como parte del gate.
- `RegistrationFormCubit` tests existentes (`registration_form_cubit_analytics_test.dart`, si construyen `EventRegistrationModel` con `bloodType`) deben seguir pasando sin cambios de aserciones.
- `EventDetailCubit`/`EventModel` tests existentes no deberían verse afectados — los 2 campos nuevos son opcionales con default `null` vía constructor, no cambian el comportamiento de ningún getter existente (`isFree`, `meetingPoint`, `destination`, `isMultiBrand`, `isMultiDay`).
- `UserModel`/`UserDto` tests existentes (si los hay) no deberían verse afectados — campo nuevo opcional.
- Ningún test de widgets/UI debería verse afectado salvo el que renderiza `registration_detail_page.dart` (verificar snapshot/golden si existe, aunque el cambio es semánticamente idéntico cuando `bloodType` no es null).

## Fuera de alcance

- Lógica de UI (switches, pantallas de waiver, consentimiento) — Fases 4, 5, 6.
- Ofuscación en el frontend (renderizado de centinelas) — Fase 7.
- Campo `bloodTypeRaw: String?` de respaldo.
- Cambios en `RegistrationService`, `EventRegistrationRepositoryImpl`, `rider_profile_repository_impl.dart`.
- Nuevos use cases o interfaces de repositorio.
- Cambios en `rideglory-api` (backend ya cerrado en Fase 1; Fase 2 de ofuscación backend es un futuro dependsOn no cubierto aquí).
- Agregar `shareMedicalInfo`/`allowOrganizerContact` a `RegistrationWizardSteps.fieldsByStep` (validación de wizard) — es UI, Fases 4/5/6.
