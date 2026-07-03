# Architect handoff — legal-consentimientos-fase5

**Date:** 2026-07-03T02:30:37Z
**Status:** done

## Pre-flight (bloqueante) — resultado

Todos los checks del §7 de la fuente pasan; el trabajo de Fases 1/3 ya está mergeado y es de solo lectura para esta fase:

| Check | Resultado |
|---|---|
| `EventModelExtension.toJson()` incluye `organizerAcceptedResponsibilityAt` | ✅ `lib/features/events/data/dto/event_dto.dart` / `.g.dart`, campo `DateTime?` en `EventModel` (`lib/features/events/domain/model/event_model.dart:68`) |
| `UserModel.medicalConsentAcceptedAt: DateTime?` | ✅ `lib/features/users/domain/model/user_model.dart:38` |
| `POST /users/me/medical-consent` existe en backend | ✅ `api-gateway/src/users/users.controller.ts:51` → `users-ms/src/users/users.service.ts` (migración `20260701014335_add_medical_consent_accepted_at` ya aplicada) |
| Línea base `dart analyze` | Capturar en pre-flight de Build/Backend antes de tocar código (no se ejecutó desde este rol; Architect no modifica código) |

**Hallazgo importante (gap en la fuente):** el contrato real del endpoint exige un body `{ consentVersion: string }` (`MedicalConsentDto`, `class-validator` `@IsString @MinLength(1)`) y responde `{ medicalConsentAcceptedAt: Date }` — no un body vacío como insinúa el AC#9 de la fuente. `MedicalConsentCubit` DEBE enviar `consentVersion` o el backend responde 400. Ver `## Contratos` abajo para el valor a usar.

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
| ------- | -------------- | ------------ | -------------------- |
| events (Bloque A) | ninguno (modelo ya tiene el campo) | ninguno | `EventFormCubit.setOrganizerResponsibility(DateTime)`, `OrganizerResponsibilityExtra` (transporte), `EventOrganizerResponsibilityPage` (nueva), `PublishRow` interceptado |
| users (Bloque B, capa datos) | ninguno (modelo ya tiene el campo) | `UserRepository.acceptMedicalConsent(String consentVersion)`, `UserRepositoryImpl` impl, `UserService.acceptMedicalConsent` (Retrofit), `MedicalConsentResponseDto` (nuevo, response-only), `UserStorageService.getMedicalConsentAcceptedAt()/setMedicalConsentAcceptedAt(DateTime)` (`FlutterSecureStorage`) | ninguno directo (consumido por el cubit de event_registration) |
| event_registration (Bloque B, capa presentación) | ninguno | ninguno | `MedicalConsentCubit` (nuevo, `@injectable`, `Cubit<ResultState<DateTime>>`), `MedicalConsentPage` (nueva), interceptor en `RegistrationFormContent._onNext()` |
| routing (compartido) | — | — | `AppRoutes.organizerResponsibility`, `AppRoutes.medicalConsent` + 2 `GoRoute` en la lista raíz (hermanos del `StatefulShellRoute`, NUNCA anidados dentro) |

## API contracts (rideglory-api changes)

**Ninguno.** El contrato ya existe (Fases 1/3) y es de solo lectura para esta fase. Documentado aquí solo para que Frontend implemente correctamente la llamada:

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|-------------|---------|--------|
| POST | `/users/me/medical-consent` | Firebase Bearer (interceptor existente) | `{ "consentVersion": string }` (no vacío) | `200 { "medicalConsentAcceptedAt": "<ISO8601>" }` | `401` si falta email en el token; `400` si `consentVersion` vacío/ausente (class-validator) |

`consentVersion`: usar una constante versionada análoga a `RegistrationFormCubit`'s `riskAcceptanceVersion` (`'v0.1-2026-06'`, visto en el diff en progreso de `registration_form_cubit.dart`). Definir `const medicalConsentVersion = 'v0.1-2026-06'` en `MedicalConsentCubit` (o en `RegistrationFormFields`/constante compartida si Build prefiere centralizarla) — mantener el mismo string que el ARB v0 placeholder para trazabilidad legal.

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `MedicalConsentResponseDto` | data | `lib/features/users/data/dto/medical_consent_response_dto.dart` (nuevo) | Excepción documentada a Pattern B: response-only, sin modelo de dominio par (el dato relevante ya vive en `UserModel.medicalConsentAcceptedAt`, refrescado por separado). Un solo campo `medicalConsentAcceptedAt: DateTime` (usar `ApiDateTimeConverter` no-nullable, ya que el backend siempre lo devuelve tras 200). Debe llevar un comentario `// Pattern B exception: response-only DTO, no domain model counterpart.` |
| `OrganizerResponsibilityExtra` | presentation | `lib/features/events/presentation/form/organizer_responsibility_extra.dart` (nuevo) | Clase de transporte plana (no DTO, no domain model): `EventFormCubit cubit`, `FormImageCubit imageCubit`, `EventModel eventToSave`. Pasada vía `state.extra` en el `GoRoute` (mismo patrón que otros `extra as X` del router, p.ej. `vehicleDetail`). Al construir el nuevo page, envolver en `MultiBlocProvider` con `BlocProvider.value` para ambos cubits — así `EventOrganizerResponsibilityPage` opera sobre las MISMAS instancias que `EventFormView` sigue escuchando debajo en el stack (mecanismo de doble-pop del AC#5 depende de esto: un solo `saveResult.data` emitido, dos listeners lo consumen). |

No hay DTOs nuevos para Bloque A (el campo ya existe en `EventDto`/`EventModel`).

## Environment variables

Ninguna. No se requieren nuevas claves `.env` para esta fase.

## Data / migraciones

Ninguna. La migración Prisma (`add_medical_consent_accepted_at`) ya está aplicada (Fase 1). No ejecutar `prisma migrate` en esta fase — si algo la requiere, es señal de que el pre-flight falló y hay que detenerse.

## Change map (lista maestra — Build solo toca esto)

| file | action | reason | risk |
|---|---|---|---|
| `lib/shared/router/app_routes.dart` | modify | 2 constantes nuevas: `organizerResponsibility`, `medicalConsent` | low |
| `lib/core/http/api_routes.dart` | modify | constante `meMedicalConsent = '/users/me/medical-consent'` | low |
| `lib/features/users/data/dto/medical_consent_response_dto.dart` | create | DTO response-only (excepción Pattern B documentada) | low |
| `lib/features/users/data/service/user_service.dart` | modify | método Retrofit `acceptMedicalConsent(Map<String,dynamic> body)` `@POST(ApiRoutes.meMedicalConsent)` | med |
| `lib/features/users/data/service/user_service.g.dart` | modify (generado) | regenerar con `dart run build_runner build --delete-conflicting-outputs` tras el cambio anterior | low |
| `lib/features/users/domain/repository/user_repository.dart` | modify | firma abstracta `Future<Either<DomainException, DateTime>> acceptMedicalConsent(String consentVersion)` | low |
| `lib/features/users/data/repository/user_repository_impl.dart` | modify | implementación vía `executeService` + `MedicalConsentResponseDto` | med |
| `lib/core/services/user_storage_service.dart` | modify | `getMedicalConsentAcceptedAt()` / `setMedicalConsentAcceptedAt(DateTime)` bajo clave `medical_consent_accepted_at` (sin prefijo de uid — es un flag de dispositivo, igual que `_analyticsEnabledKey`; documentar la decisión en el código) | low |
| `lib/features/event_registration/presentation/cubit/medical_consent_cubit.dart` | create | `@injectable`, `Cubit<ResultState<DateTime>>`; `accept()` llama `UserRepository.acceptMedicalConsent` + `UserStorageService.setMedicalConsentAcceptedAt`; expone `Future<bool> hasCachedConsent()` (lee `UserStorageService.getMedicalConsentAcceptedAt()`) | med |
| `lib/features/event_registration/presentation/wizard/medical_consent_page.dart` | create | pantalla nueva; `AppButton` "Autorizar" (spinner via `isLoading`) + `AppTextButton` "No autorizar"; un widget por archivo | med |
| `lib/features/event_registration/presentation/registration_form_content.dart` | modify | interceptor en `_onNext()`: si `_wizard.currentStep == 0` y step válido, antes de `_wizard.next()` verificar caché (`MedicalConsentCubit.hasCachedConsent()`); si falta, `pushNamed(AppRoutes.medicalConsent)` y avanzar solo si retorna `true`; flag `_isNavigating` para evitar doble tap (ya exigido por guardrails) | med — archivo con diff sin commitear en progreso (waiver/edad), coordinar merge lógico, no revertir esos cambios |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | método `setOrganizerResponsibility(DateTime acceptedAt)` — NO reemplaza `saveEvent`; guarda el timestamp para que `EventOrganizerResponsibilityPage` construya el `EventModel` final con `copyWith(organizerAcceptedResponsibilityAt: acceptedAt)` antes de invocar `saveEvent` | low |
| `lib/features/events/presentation/form/organizer_responsibility_extra.dart` | create | clase de transporte (ver arriba) | low |
| `lib/features/events/presentation/form/event_organizer_responsibility_page.dart` | create | pantalla nueva; "Acepto y publico el evento" captura `final acceptedAt = DateTime.now();` UNA vez y lo usa tanto en `setOrganizerResponsibility` como en el `copyWith` pasado a `saveEvent` (AC#4: mismo objeto); "Revisar evento" → `context.pop()` sin guardar; error inline con `colorScheme.error`, sin pop | med |
| `lib/features/events/presentation/form/widgets/steps/publish_row.dart` | modify | `_onPublish`: si `!cubit.isEditing`, tras `buildEventToSave()` no nulo, en vez de `saveEvent` directo, `context.pushNamed(AppRoutes.organizerResponsibility, extra: OrganizerResponsibilityExtra(...))`; si `event == null`, mantener el SnackBar `event_formIncompleteMessage` existente (AC#3) — revisar si ya existe o hay que agregarlo | med |
| `lib/shared/router/app_router.dart` | modify | 2 `GoRoute` nuevos, HERMANOS del `StatefulShellRoute` (mismo nivel que `createVehicle`/`maintenances`), `parentNavigatorKey: _rootNavigatorKey`, path absoluto, `state.extra as OrganizerResponsibilityExtra` / sin extra tipado para `medicalConsent` (no necesita transporte de cubit, es standalone) | med (riesgo R6 explícito en la fuente) |
| `lib/l10n/app_es.arb` | modify | 10 claves nuevas: 5 Bloque A (`event_organizerResponsibility*`) + 5 Bloque B (`registration_law1581*` / `registration_medicalConsent*`) — coordinar con el diff ya en progreso en este archivo, no duplicar/perder claves existentes | low |
| `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart` | modify (generado) | `flutter gen-l10n` tras editar el ARB | low |
| `lib/core/di/injection.config.dart` (o equivalente generado) | modify (generado) | regenerar con `build_runner` tras anotar `MedicalConsentCubit` `@injectable` | low |
| `test/features/events/presentation/form/cubit/event_form_cubit_test.dart` | modify | tests de `setOrganizerResponsibility` | low |
| `test/features/events/presentation/form/widgets/steps/publish_row_test.dart` | modify | tests del interceptor (navega en vez de guardar directo; modo edición sin cambios) | low |
| `test/features/events/presentation/form/event_organizer_responsibility_page_test.dart` | create | tests de aceptar/error/revisar | low |
| `test/features/event_registration/presentation/cubit/medical_consent_cubit_test.dart` | create | tests de accept/error/hasCachedConsent | low |
| `test/features/event_registration/presentation/wizard/medical_consent_page_test.dart` | create | tests de autorizar/no autorizar/error | low |
| `test/core/services/user_storage_service_test.dart` | modify | tests de get/set `medical_consent_accepted_at` | low |

## Orden de implementación

1. Rutas/constantes compartidas: `app_routes.dart`, `api_routes.dart` (no lógica, base para todo lo demás).
2. Capa de datos Bloque B: `MedicalConsentResponseDto` → `UserService.acceptMedicalConsent` → `build_runner` (regenerar `user_service.g.dart`) → `UserRepository`/`UserRepositoryImpl` → `UserStorageService` (get/set).
3. Bloque A: `EventFormCubit.setOrganizerResponsibility` → `OrganizerResponsibilityExtra` → `EventOrganizerResponsibilityPage` → `PublishRow` interceptor → `GoRoute organizerResponsibility` en `app_router.dart`.
4. Bloque B (presentación): `MedicalConsentCubit` (`@injectable`) → `MedicalConsentPage` → `GoRoute medicalConsent` en `app_router.dart` → interceptor en `RegistrationFormContent._onNext()`.
5. l10n: agregar las 10 claves al ARB (una sola pasada, coordinada con el diff en progreso) → `flutter gen-l10n`.
6. `dart run build_runner build --delete-conflicting-outputs` (una sola pasada final, regenera `injection.config.dart` y cualquier `.g.dart` pendiente).
7. Tests (todos los listados) → `dart analyze` contra línea base → `flutter test`.

## Superficie de regresión

- **Routing raíz:** agregar `GoRoute`s hermanos del `StatefulShellRoute` es de bajo riesgo estructural si se sigue el patrón existente (`createVehicle`, `soatStatus`, etc.), pero un error de anidación (meterlos dentro del shell) rompe el guardrail R6 y puede duplicar/perder el stack de navegación de las tabs. Verificar con `flutter test` de navegación si existen.
- **`PublishRow` / `EventFormCubit`:** el modo edición (`isEditing == true`) NO debe tocarse; cualquier cambio que toque la rama `if (cubit.isEditing)` es una regresión directa contra AC#2. El doble-pop depende de que `EventFormView` siga montado debajo en el stack (no se debe reemplazar la pantalla, solo apilar sobre ella).
- **`registration_form_content.dart`:** archivo con trabajo en progreso sin commitear (validación de edad + waiver, ver `git diff` de `registration_form_cubit.dart`). El interceptor de `_onNext()` solo debe activarse en la transición `currentStep == 0 → 1`; no debe interferir con la navegación de los pasos 1→2→3 ni con el flujo de envío final (`_onFinishPressed`/waiver sheet), que son de otra fase en curso.
- **`UserStorageService`:** es compartido por todo el flujo de auth/perfil (`saveUser`/`getUser` con prefijo de uid). Las nuevas claves de consentimiento médico van SIN prefijo de uid (dato de dispositivo, patrón igual a `_analyticsEnabledKey`) — no colisionan con `_keyPrefix` pero hay que verificar que un logout/cambio de usuario en el mismo dispositivo no filtre el consentimiento de otro rider (fuera de alcance explícito de esta fase; documentar como riesgo abierto, no resolver aquí).
- **`user_service.g.dart` / `injection.config.dart`:** regenerarlos afecta el grafo de DI completo; ejecutar `build_runner` UNA sola vez al final de Bloque A+B para minimizar conflictos de regeneración repetida.
- **ARB compartido:** ya tiene un diff en progreso (trabajo de waiver/inscripción); agregar las 10 claves nuevas debe hacerse con cuidado de no reordenar/tocar las claves ya modificadas por ese trabajo paralelo.

## Riesgos y preguntas abiertas

- **Gap de contrato (`consentVersion`):** la fuente no menciona el body requerido por el backend. Resuelto arriba — Frontend debe enviar `consentVersion` fijo versionado. Si Backend/Frontend prefieren centralizar el string en un solo lugar (constante compartida) en vez de duplicarlo entre `RegistrationFormCubit.riskAcceptanceVersion` y `MedicalConsentCubit`, es una decisión de implementación libre, no bloqueante.
- **Filtración de consentimiento entre usuarios en el mismo dispositivo:** fuera de alcance (ver arriba), pero dejar registrado para una fase futura de "logout limpia consentimientos locales".
- **Doble pop (Bloque A):** depende de compartir la MISMA instancia de `EventFormCubit`/`FormImageCubit` vía `BlocProvider.value` en la nueva ruta — si Build usa `getIt<EventFormCubit>()` (nueva instancia) en vez del objeto recibido por `extra`, el AC#4/#5 se rompe silenciosamente (dos objetos `EventModel` distintos, o el `EventFormView` de abajo nunca ve el `saveResult.data` y no hace el segundo pop). Marcar como punto de verificación explícito en QA.

## Next agent needs to know

- **Backend (rideglory-api):** ningún cambio requerido; el contrato ya existe. Si Frontend reporta que `consentVersion` falta o el endpoint rechaza el request, es un bug de Frontend, no de Backend — no tocar `users-ms`/`api-gateway` en esta fase.
- **Frontend:** seguir el orden de implementación de arriba; usar `handoffs/architect-for-frontend.md` (slim) para el detalle operativo por archivo.
- **QA:** ver `handoffs/architect-for-qa.md` — trazabilidad AC#1–17, énfasis en el mecanismo de doble-pop y en no romper el modo edición ni los pasos 1-3 del wizard de inscripción.

## Change log

- 2026-07-03: handoff inicial, pre-flight verificado, change map y orden definidos.
