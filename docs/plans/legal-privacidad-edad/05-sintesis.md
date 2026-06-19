# 05 — Síntesis y plan final consolidado

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:39:51Z
**Autor:** Product Owner (síntesis post-revisiones + correcciones Auditor Opus — ronda 2)

---

## Overview

Plan de 7 fases para cumplir los requisitos legales de la app: validación de edad mínima (≥18), consentimiento informado de datos médicos (Ley 1581), waiver de riesgos para riders, declaración de responsabilidad para organizadores, y ofuscación condicional de datos PII en la vista del organizador.

El plan cubre backend (events-ms, users-ms, rideglory-contracts) y Flutter de forma coordinada. Las Fases 1-3 son de infraestructura; las Fases 4-7 son de producto. Las dependencias explícitas se detallan en la tabla de fases. La cadena crítica es: Fase 1 → (Fase 2 || Fase 3) → Fase 4 → Fases 5/6/7.

---

## Cambios aplicados

### Desde Architect Review (03)

| Ajuste | Impacto en el plan |
|--------|-------------------|
| **Arch-1** Expandir Fase 1 con `users-ms` | Fase 1 incluye migración de `User.medicalConsentAcceptedAt`, contratos `MedicalConsentDto` / `MedicalConsentResponseDto`, y endpoint `POST /users/me/medical-consent`. |
| **Arch-2** Dividir Fase 2 en 2a + 2b | La Fase 2 se mantiene unificada pero el handoff exige abordar las sub-tareas **secuencialmente** (2a validación de edad → 2b ofuscación condicional) con tests unitarios por capa. |
| **Arch-3** `UserModel.medicalConsentAcceptedAt` en Fase 3 | Fase 3 incluye extensión de `UserModel` y `UserDto` con `medicalConsentAcceptedAt: DateTime?`. |
| **Arch-4** `bloodType` como `BloodType | string` en contratos | Fase 1 declara `bloodType: BloodType | string` en `EventRegistrationDto` de contratos. Fase 3 cambia `bloodType` de `BloodType` a `BloodType?` con getter de parse seguro en `EventRegistrationModel`. |
| **Arch-5** `isOrganizerView: bool` explícito en `RegistrationDetailExtra` | Fase 7 agrega este campo al extra y todos los puntos de navegación lo proveen. |
| **Arch-6** `riskAcceptedAt` nullable en DB, obligatorio en lógica de negocio | Documentado en handoff de Fase 1: migración usa `DateTime?`; el servicio NestJS rechaza nuevas inscripciones sin el campo con `422 RISK_NOT_ACCEPTED`. |

### Desde Plan Review (04)

| Ajuste | Impacto en el plan |
|--------|-------------------|
| **A1** Centinela semántico para datos ofuscados (OBLIGATORIO) | El backend no retorna strings literales en español. Retorna el centinela `"__NOT_SHARED__"` para campos no compartidos. Esta decisión se fija en Fase 1 antes de cerrar los contratos. |
| **A2** Aclarar punto de intercepción Ley 1581 antes de Fase 6 (OBLIGATORIO) | Fase 6 intercepta el paso médico del wizard de inscripción (opción a — scope acotado, cero nuevas pantallas de perfil). No se crea flujo de perfil médico nuevo en esta iteración. |
| **A3** Subtítulos obligatorios en `AppSwitchTile` de privacidad (OBLIGATORIO) | Fase 4 especifica subtítulos requeridos para ambos switches: `shareMedicalInfo` y `allowOrganizerContact`. |
| **A4** Pre-flight A4 — fuente única de `stepCount` (CORRECCIÓN APLICADA — ver C2) | `RegistrationWizardController` se instancia con `stepCount: RegistrationWizardSteps.stepCount` (getter = `fieldsByStep.length`). La única edición necesaria es agregar la lista del paso waiver a `RegistrationWizardSteps.fieldsByStep`; con eso `stepCount` sube a 5 automáticamente. |
| **A5** Error `UNDERAGE_RIDER` mapeado en `RegistrationFormCubit` | Fase 4 maneja explícitamente este código del backend (no mensaje genérico). Coordinado con Fase 2 que define el código. |
| **A6** `OrganizerResponsibilityPage` como pantalla completa (OBLIGATORIO) | Fase 5 implementa pantalla completa navegada con `context.pushNamed`. Archivo: `event_organizer_responsibility_page.dart` bajo `lib/features/events/presentation/form/`. |
| **A7** `RegistrationContactActions` como widget separado (OBLIGATORIO) | Fase 7 requiere `registration_contact_actions.dart` como archivo independiente. Prohibido como método `_buildContactActions()`. |

### Correcciones del Auditor Opus — ronda 1

| Corrección | Fase | Detalle |
|-----------|------|---------|
| **C1** `EventRegistrationModelExtension.toJson()` debe incluir los 4 campos nuevos | 3 | Actualizar `toJson()` en `event_registration_dto.dart` líneas 57-88 para incluir `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt` y `riskAcceptanceVersion`. Sin esto el payload de escritura los descarta silenciosamente. Criterio verificable: un test/curl confirma que el body del POST contiene los 4 campos. |
| **C2** Pre-flight A4 corregido: fuente única de `stepCount` — ver corrección ronda 2 abajo | 4 | Corregida en ronda 2 (ver C2-R2). |
| **C3** Ruta correcta del paso médico | 4 | El archivo real es `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart`. El nuevo `registration_waiver_step.dart` va en `.../wizard/steps/` para consistencia. |
| **C4** Registrar ruta nueva `AppRoutes.organizerResponsibility` | 5 | Definir `AppRoutes.organizerResponsibility` y su `GoRoute` en `lib/shared/router/app_router.dart` antes de usar `context.pushNamed`. La ruta no existe hoy. |
| **C5** Registrar `AppRoutes.medicalConsent` + `GoRoute` en `app_router.dart` | 6 | Definir la ruta antes de usarla. `MedicalConsentCubit` es `@injectable` y se provee via `BlocProvider` en el árbol, siguiendo el patrón de `AnalyticsConsentCubit` y la regla `feedback_avoid_singleton_cubits`. No usar `getIt`/singleton. |
| **C6** `RegistrationContactActions` es independiente del early-return de `RegistrationDetailBottomBar` | 7 | `RegistrationDetailBottomBar` retorna `SizedBox.shrink()` cuando `actions.isEmpty`. `RegistrationContactActions` debe evaluarse independientemente. Una inscripción aprobada con `allowOrganizerContact == true` muestra los botones de contacto aunque `actions` esté vacío. El `build()` de `RegistrationDetailBottomBar` debe sacar los botones de contacto del branch de `actions`. |
| **C7** Fuente de `EventState` y `sosTriggeredAt` en `RegistrationDetailPage` | 7 | `RegistrationDetailPage` no expone hoy el estado del evento. Los campos `EventState.inProgress` y `sosTriggeredAt` deben llegar vía `RegistrationDetailExtra` (agregar `eventState: EventState?` y `eventSosTriggeredAt: DateTime?`) o como parámetros de `EventRegistrationParams`. El implementador elige el mecanismo y lo documenta en el handoff de la fase. |

### Correcciones del Auditor Opus — ronda 2

| Corrección | Fase | Detalle |
|-----------|------|---------|
| **C2-R2** Pre-flight de Fase 4: eliminar instrucción de cambiar `stepCount` en el controller directamente | 4 | El controller se instancia en `registration_form_content.dart` con `stepCount: RegistrationWizardSteps.stepCount` (getter = `fieldsByStep.length`, fuente única). **La única edición de `stepCount` necesaria es agregar la lista del paso waiver a `RegistrationWizardSteps.fieldsByStep`**; con eso `stepCount` sube a 5 automáticamente en el controller y en `RegistrationStepIndicator`. El pre-flight de la ronda anterior era contradictorio: instruía cambiar `stepCount: 5` manualmente (paso a) Y después agregar la lista a `fieldsByStep` (paso b) — la fuente única elimina el paso a. |
| **C8** S3 convertido en check de pre-flight verificable en Fase 2 | 2 | El supuesto S3 (`sosTriggeredAt` ya en Prisma de events-ms) se convierte en un gate accionable obligatorio en el pre-flight de la Fase 2: **confirmar que `Event.sosTriggeredAt` existe en `schema.prisma` de events-ms antes de mapearlo**. Si no existe, agregar la migración en Fase 1 o al inicio de Fase 2 antes de cualquier lógica de ofuscación de Capa B. No avanzar a 2b si el campo no está confirmado en el schema. |
| **C9** Columna `dependsOn` explícita en la tabla de fases | 1-7 | Ver tabla de fases abajo — columna `dependsOn` agregada con las dependencias explícitas por id de fase. |

---

## Lista final de fases

| # | Título | dependsOn | Nivel | Por qué ese nivel |
|---|--------|-----------|-------|-------------------|
| 1 | Contratos, schema de backend y endpoint medical-consent | [] | **full** | Migraciones en 2 MS (events-ms + users-ms), PR en submódulo `rideglory-contracts`, campos PII, edge cases de default retroactivo, alto blast radius, difícil de revertir. |
| 2 | Validación de edad y ofuscación condicional en backend | [1] | **full** | Lógica de seguridad/PII central, error semántico `UNDERAGE_RIDER`, ofuscación por capas con edge case de enum `BloodType`, tests unitarios obligatorios por capa, cross-cutting en events-ms. |
| 3 | Modelos y DTOs Flutter | [1] | **normal** | Feature acotada sin migraciones ni endpoints. Cambio de tipo en `bloodType` (getter de parse seguro), extensión de 3 modelos/DTOs, actualización de `toJson()` con criterio verificable. Requiere `build_runner` sin conflictos. |
| 4 | Waiver del rider en el flujo de inscripción | [2, 3] | **full** | UI cross-cutting sobre wizard existente (reconciliar `fieldsByStep` + `_stepNameFor`), switches de consentimiento con subtítulos WCAG, validación doble de edad, manejo explícito de `UNDERAGE_RIDER`, strings l10n, reglas de widget por archivo. |
| 5 | Aceptación de responsabilidad del organizador | [1, 3] | **normal** | Pantalla nueva con intercepción de flujo de publicación + registro de ruta nueva en `app_router.dart`. Lógica acotada (solo en creación, no en edición). Texto legal scrollable con botones fijos. |
| 6 | Autorización Ley 1581 en paso médico del wizard | [1, 3] | **normal** | Pantalla nueva de consentimiento + registro de ruta + `MedicalConsentCubit` @injectable. Persistencia offline-first (SharedPreferences + backend). Scope acotado al wizard. |
| 7 | Vista del organizador con ofuscación y contacto | [2, 3] | **normal** | `RegistrationDetailPage` con `isOrganizerView` explícito, refactor de `RegistrationDetailBottomBar` para independizar botones de contacto del early-return, widget `RegistrationContactActions` separado, fuente de `EventState` para coherencia de UI. |

---

## Detalle por fase

### Fase 1 — Contratos, schema de backend y endpoint medical-consent
**Nivel: full | dependsOn: []**

**Backend (events-ms):**
- Migración Prisma: 4 campos en `EventRegistration` (`shareMedicalInfo Bool @default(false)`, `allowOrganizerContact Bool @default(false)`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`) + 1 campo en `Event` (`organizerAcceptedResponsibilityAt DateTime?`).
- Defaults seguros documentados en la migración: `shareMedicalInfo = false`, `allowOrganizerContact = false`, `riskAcceptedAt = null` para inscripciones pre-migración.
- Verificar en `schema.prisma` de events-ms si `Event.sosTriggeredAt` existe. Si no existe, agregar el campo aquí mismo como `sosTriggeredAt DateTime?` con su migración — este campo es prerrequisito de la ofuscación de Capa B en Fase 2.

**Backend (users-ms):**
- Migración Prisma: 1 campo en `User` (`medicalConsentAcceptedAt DateTime?`).
- Nuevo endpoint `POST /users/me/medical-consent` — body: `MedicalConsentDto { consentVersion: string }`, respuesta: `MedicalConsentResponseDto { medicalConsentAcceptedAt: Date }`.
- `GET /users/me` retorna `medicalConsentAcceptedAt` en `UserDto`.

**rideglory-contracts:**
- `CreateRegistrationDto`: agregar `shareMedicalInfo: boolean = false`, `allowOrganizerContact: boolean = false`, `riskAcceptedAt?: Date`, `riskAcceptanceVersion?: string`. Todos con `@IsBoolean()` / `@IsOptional()` según corresponda.
- `EventRegistrationDto` (respuesta): campos ofuscables pasan a `string`; `bloodType: BloodType | string`; agregar `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`.
- `CreateEventDto` / `UpdateEventDto`: agregar `organizerAcceptedResponsibilityAt?: Date`.
- Nuevo: `MedicalConsentDto`, `MedicalConsentResponseDto` en `users/dto/`.
- **Centinela semántico fijado:** el backend retorna `"__NOT_SHARED__"` para campos no compartidos. Documentar en el contrato. String literal en español no aceptable.

**Handoff crítico al implementador:**
- `riskAcceptedAt` es nullable en DB para inscripciones pre-migración; el servicio NestJS debe rechazar nuevas inscripciones sin este campo con `422 RISK_NOT_ACCEPTED`.
- Seguir gotcha de `project_contracts_rebuild_gotcha.md`: `npm run build` + `pnpm install` en cada MS afectado (events-ms, users-ms, api-gateway).

---

### Fase 2 — Validación de edad y ofuscación condicional en backend
**Nivel: full | dependsOn: [1]**

**Pre-flight obligatorio — verificar `sosTriggeredAt` en schema (gate accionable):**
- Abrir `schema.prisma` de events-ms y confirmar que el modelo `Event` contiene `sosTriggeredAt DateTime?`.
- Si no existe: agregar el campo y generar la migración Prisma **antes de escribir cualquier lógica de la Fase 2b**. Si ya fue agregado en Fase 1, omitir este paso. Este gate no es una nota de impacto — es un bloqueo: no avanzar a 2b si `sosTriggeredAt` no está confirmado en el schema.

**2a — Validación de edad (abordar primero, bajo riesgo):**
- En `RegistrationsService.create()`: calcular edad desde `birthDate` del usuario. Si `< 18`, lanzar `RpcException({ status: 422, code: 'UNDERAGE_RIDER' })`.
- Tests unitarios: caso límite (17 años 364 días), caso válido (18 exactos), caso sin `birthDate`.

**2b — Ofuscación condicional en `findByEvent` (abordar segundo, riesgo medio):**

| Campo | Condición para mostrar real | Ofuscado con |
|-------|----------------------------|--------------|
| `eps`, `medicalInsurance`, `bloodType` | `event.state === IN_PROGRESS && shareMedicalInfo === true` | `"__NOT_SHARED__"` |
| `emergencyContactName`, `emergencyContactPhone` | `event.state === IN_PROGRESS` | `"••••"` |
| `phone` | `allowOrganizerContact === true` | `"••••"` |
| `identificationNumber`, `email`, `residenceCity` | `sosTriggeredAt !== null` (SOS activo) | `"••••"` |

- `bloodType` en el mapper de respuesta se asigna como string puro (no como enum) para permitir la ofuscación.
- `findMyRegistrationForEvent` (vista del rider sobre su propia inscripción) NO aplica ofuscación.
- Tests unitarios por capa: evento en curso + `shareMedicalInfo = false`, evento en curso + `shareMedicalInfo = true`, evento no iniciado, SOS activo.

---

### Fase 3 — Modelos y DTOs Flutter
**Nivel: normal | dependsOn: [1]**

- `EventRegistrationModel`: +4 campos (`shareMedicalInfo: bool = false`, `allowOrganizerContact: bool = false`, `riskAcceptedAt: DateTime?`, `riskAcceptanceVersion: String?`). Cambiar `bloodType` de `BloodType` a `BloodType?` con getter de parse seguro: si el valor no parsea como enum (porque es `"••••"` o `"__NOT_SHARED__"`), retorna `null` y la UI muestra el string crudo.
- `EventRegistrationDto extends EventRegistrationModel` (Pattern B): mismos 4 campos nuevos + ajuste de tipo en `bloodType`. Regenerar `.g.dart`.
- **`EventRegistrationModelExtension.toJson()`** en `lib/features/event_registration/data/dto/event_registration_dto.dart` (líneas 57-88): actualizar la construcción del `EventRegistrationDto` para incluir `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt` y `riskAcceptanceVersion`. Sin esta actualización el payload de escritura los descarta silenciosamente. **Criterio de aceptación verificable:** un test unitario o curl confirma que el body del `POST /events/:id/registrations` contiene los 4 campos.
- `EventModel`: +2 campos (`organizerAcceptedResponsibilityAt: DateTime?`, `sosTriggeredAt: DateTime?`).
- `EventDto extends EventModel`: mismos 2 campos. Regenerar `.g.dart`.
- `UserModel`: +1 campo (`medicalConsentAcceptedAt: DateTime?`).
- `UserDto extends UserModel`: +1 campo. Regenerar `.g.dart`.
- `RegistrationFormFields`: +2 constantes (`shareMedicalInfo`, `allowOrganizerContact`).
- `RegistrationService`: usar `.toJson()` del DTO para payloads de escritura (regla `feedback_dto_toJson.md`); no construir `Map<String, dynamic>` manualmente.
- `_preloadFromExistingRegistration` debe patchear los 2 campos booleanos en modo edición.
- Gate: `dart analyze` sin errores; `dart run build_runner build --delete-conflicting-outputs` sin conflictos.

---

### Fase 4 — Waiver del rider en el flujo de inscripción
**Nivel: full | dependsOn: [2, 3]**

**Pre-flight obligatorio — fuente única de `stepCount`:**
1. Leer `registration_step_indicator.dart` como primer paso — confirmar que recibe `stepCount` como parámetro (no hardcodeado). Si está hardcodeado, generalizarlo antes de continuar.
2. Leer `registration_form_content.dart` para confirmar que `RegistrationWizardController` se instancia con `stepCount: RegistrationWizardSteps.stepCount`. Este getter deriva su valor de `fieldsByStep.length` — es la **fuente única**. No modificar el constructor del controller directamente.
3. Agregar la lista del paso waiver a `RegistrationWizardSteps.fieldsByStep` en `lib/features/event_registration/constants/registration_form_fields.dart`. La lista del paso waiver es `[]` (el waiver no tiene `FormBuilder` fields; la aceptación la maneja el cubit al submit). Con este cambio, `stepCount` sube a 5 automáticamente en el controller y en `RegistrationStepIndicator`.
4. Agregar `AnalyticsParams.stepNameWaiver` (definir la constante si no existe) en `_stepNameFor` de `registration_form_content.dart` como el índice 4.

**Paso médico (`lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart`):** agregar al final, bajo `FormSectionHeader("Privacidad")`, dos `AppSwitchTile`:
- `shareMedicalInfo`: título `registration_shareMedicalInfoTitle`, subtítulo `registration_shareMedicalInfoSubtitle` ("El organizador podrá ver tu grupo sanguíneo y EPS durante el evento"). Default: `false`.
- `allowOrganizerContact`: título `registration_allowContactTitle`, subtítulo `registration_allowContactSubtitle` ("El organizador podrá llamarte o escribirte por WhatsApp"). Default: `false`.

**Nuevo paso 5 — Waiver (`lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart`):**
- Título `registration_waiverTitle` ("Antes de inscribirte").
- Texto `registration_waiverBodyV0` (placeholder legal) scrollable — `Expanded(child: SingleChildScrollView(...))`.
- Nombre del organizador visible para contexto.
- Botones fijos al fondo: `AppButton` "Entiendo, inscribirme" (`registration_waiverCtaButton`) + `AppTextButton` "Cancelar" (`registration_waiverCancelButton`).
- Estado loading: `AppButton(isLoading: true)`.
- Estado error: `AppDialog`. Si el error es `UNDERAGE_RIDER`, mostrar `registration_underageMessage` (no mensaje genérico).

**Validación de edad en `RegistrationFormCubit`:**
- Antes de emitir `loading()` en `saveRegistration()`, calcular edad desde `birthDate` del form.
- Si `birthDate` no existe: emitir `ResultState.error()` con `registration_missingBirthDateMessage` + acción "Ir a mi perfil".
- Si `< 18`: emitir `ResultState.error()` con `registration_underageMessage`.
- Si el backend retorna `UNDERAGE_RIDER`: mapear al mismo mensaje l10n.

**`RegistrationFormCubit._buildRegistration()`:** incluir `riskAcceptedAt = DateTime.now()` y `riskAcceptanceVersion = 'v0.1-2026-06'` al momento del submit.

**Strings l10n (Fase 4):** `registration_waiverTitle`, `registration_waiverBodyV0`, `registration_waiverCtaButton`, `registration_waiverCancelButton`, `registration_privacySectionTitle`, `registration_shareMedicalInfoTitle`, `registration_shareMedicalInfoSubtitle`, `registration_allowContactTitle`, `registration_allowContactSubtitle`, `registration_underageTitle`, `registration_underageMessage`, `registration_missingBirthDateMessage`, `registration_goToProfile`.

---

### Fase 5 — Aceptación de responsabilidad del organizador
**Nivel: normal | dependsOn: [1, 3]**

**Registro de ruta (obligatorio, primer paso):**
- Definir `AppRoutes.organizerResponsibility` en `lib/shared/router/app_router.dart`.
- Registrar su `GoRoute` (path: `/events/organizer-responsibility` o similar) antes de usar `context.pushNamed`. La ruta no existe hoy en el router.

**Nueva pantalla `event_organizer_responsibility_page.dart`** bajo `lib/features/events/presentation/form/`:
- Navegación: `PublishRow` intercepta "Publicar evento" y llama `context.pushNamed(AppRoutes.organizerResponsibility)` antes de `cubit.saveEvent()`. Solo en creación nueva (`cubit.isEditing == false`).
- Contenido: título `event_organizerResponsibilityTitle`, texto `event_organizerResponsibilityBodyV0` scrollable (`Expanded(child: SingleChildScrollView(...))`), `AppButton` "Acepto y publico el evento" fijo al fondo.
- Al aceptar: llama `cubit.setOrganizerResponsibility(DateTime.now())` y luego `cubit.saveEvent()`.
- Estado loading: `AppButton(isLoading: true)`.
- Estado error: `Text` de error inline sobre el botón (con `colorScheme.error`); no reemplaza la pantalla.
- Estado success: pop de la pantalla; el wizard completa el flujo.
- `AppTextButton` de retroceso: `event_organizerResponsibilityBackButton` ("Revisar evento").
- `organizerAcceptedResponsibilityAt` se incluye en el payload de `POST /events` o `PATCH /events/:id` al pasar a `SCHEDULED`.

**Strings l10n (Fase 5):** `event_organizerResponsibilityTitle`, `event_organizerResponsibilityBodyV0`, `event_organizerResponsibilityCtaButton`, `event_organizerResponsibilityBackButton`.

---

### Fase 6 — Autorización Ley 1581 en paso médico del wizard
**Nivel: normal | dependsOn: [1, 3]**

**Punto de intercepción:** el paso médico del wizard de inscripción (opción a — scope acotado). No se crea flujo de perfil médico nuevo.

**Registro de ruta (obligatorio, primer paso):**
- Definir `AppRoutes.medicalConsent` en `lib/shared/router/app_router.dart`.
- Registrar su `GoRoute` antes de usar `context.pushNamed`.

**`MedicalConsentCubit`:**
- Clase `@injectable` (no singleton) — provista via `BlocProvider` en el árbol, siguiendo el patrón de `AnalyticsConsentCubit` y la regla `feedback_avoid_singleton_cubits`. No usar `getIt` para accederla.
- Extiende `Cubit<ResultState<DateTime>>`.
- Método: `acceptConsent(String consentVersion)`.

**Flujo:**
1. Al navegar al paso médico, el controlador del wizard verifica si `currentUser.medicalConsentAcceptedAt != null` (consultando `SharedPreferences` como caché offline-first; el valor viene del `UserModel` hidratado al login).
2. Si `null`: navega a `MedicalConsentPage` (`context.pushNamed(AppRoutes.medicalConsent)`) antes de mostrar el paso médico.
3. Si no `null`: el paso médico se muestra normalmente.

**Nueva pantalla `medical_consent_page.dart`** bajo `lib/features/event_registration/presentation/wizard/`:
- Título `registration_law1581Title` ("Autorización de datos personales").
- Texto `registration_law1581BodyV0` scrollable — propósito, datos tratados, destinatarios.
- `AppButton` "Autorizar" (`registration_law1581AuthorizeButton`) fijo al fondo.
- `AppTextButton` "No autorizar" (`registration_law1581DeclineButton`).
- Si "Autorizar": `MedicalConsentCubit.acceptConsent(consentVersion)` → `POST /users/me/medical-consent` → persistir `medicalConsentAcceptedAt` en `SharedPreferences` (clave `medical_consent_accepted_at`) y en backend (fuente de verdad). Al completar, pop de regreso al paso médico.
- Si "No autorizar": mostrar `registration_law1581DeclinedMessage` informativo (el rider puede continuar el wizard sin completar los campos médicos) + pop al paso anterior.

**Persistencia offline-first:** `SharedPreferences` como caché local; el backend es la fuente de verdad. Evita mostrar la pantalla en sesiones offline cuando ya hubo consentimiento.

**Strings l10n (Fase 6):** `registration_law1581Title`, `registration_law1581BodyV0`, `registration_law1581AuthorizeButton`, `registration_law1581DeclineButton`, `registration_law1581DeclinedMessage`.

---

### Fase 7 — Vista del organizador con ofuscación y contacto
**Nivel: normal | dependsOn: [2, 3]**

**`RegistrationDetailExtra`:** agregar campos `isOrganizerView: bool` + `eventState: EventState?` + `eventSosTriggeredAt: DateTime?`. Todos los puntos de navegación que abren el detalle desde la lista de inscriptos del evento pasan `isOrganizerView: true` y el estado actual del evento.

**Fuente de `EventState` e `eventSosTriggeredAt`:** estos datos deben llegar vía `RegistrationDetailExtra` en el momento de la navegación. El implementador debe confirmar que el punto de navegación (lista de inscriptos del evento) tiene acceso al `EventModel` con `state` y `sosTriggeredAt` (mapeados en Fase 3) y los pasa al extra. Documentar la fuente en el handoff de la fase.

**`RegistrationDetailPage`:** usa `extra.isOrganizerView` (no `registration.userId == currentUserId`) para determinar la vista.

**`RegistrationDetailDataRow`:** renderiza el valor tal como llega del backend. Si el backend envía `"••••"` o `"__NOT_SHARED__"`, la UI muestra el centinela localizado (o el string crudo si no hay mapeo — el mapeo del centinela es trabajo de UX futuro, no bloqueante de esta fase).

**Refactor de `RegistrationDetailBottomBar`:**
- `RegistrationContactActions` debe evaluarse independientemente del early-return en línea 48 (`if (actions.isEmpty) return const SizedBox.shrink()`).
- Una inscripción aprobada con `allowOrganizerContact == true` muestra los botones de contacto aunque `actions` esté vacío (la inscripción aprobada no tiene acciones de aprobar/rechazar).
- Solución: el `build()` de `RegistrationDetailBottomBar` debe construir `RegistrationContactActions` por separado del branch de acciones de organizador, y retornar `SizedBox.shrink()` solo si TANTO `actions` como `RegistrationContactActions` están vacíos.

**Nuevo widget `registration_contact_actions.dart`** (archivo independiente, regla cero tolerancia):
- Renderiza dos botones (variante outline/ghost): "Llamar" con `Icons.call_rounded` y "WhatsApp".
- Solo se renderiza cuando `extra.isOrganizerView && registration.allowOrganizerContact == true`.
- Usa `UrlLauncherHelper.openPhone(registration.phone)` y `UrlLauncherHelper.openWhatsApp(registration.phone)`.
- Se incluye en `RegistrationDetailBottomBar`, no como método `_buildContactActions()`.

**Strings l10n (Fase 7):** `registration_callButton` ("Llamar"), `registration_whatsappButton` ("WhatsApp").

---

## Supuestos y riesgos

### Supuestos

| # | Supuesto | Impacto si falla |
|---|----------|-----------------|
| S1 | No hay usuarios reales en producción (confirmado en `project_no_real_users.md`) — el default retroactivo `shareMedicalInfo = false` no afecta datos reales. | Ninguno en esta iteración. |
| S2 | "Evento en curso" = `EventState.inProgress` (ya existe en `EventModel`). | Si la definición cambia, la Fase 2 requiere ajuste en el predicado. |
| S3 | `sosTriggeredAt` puede o no existir en el schema de Prisma de events-ms — **verificar en pre-flight de Fase 2 (gate accionable)**. Si no existe, agregar migración en Fase 1 o al inicio de Fase 2 antes de cualquier lógica de ofuscación de Capa B. | Bloquea la Fase 2b si no se verifica antes de implementar. |
| S4 | El texto del waiver (v0) y la declaración Ley 1581 se implementan como placeholders en ARB. El texto definitivo del abogado se incorpora sin cambios de código. | Si el texto del abogado requiere interactividad (formularios, firmas), amplía el scope. |
| S5 | Centinela semántico elegido: `"__NOT_SHARED__"` (acordado en Fase 1 antes de cerrar contratos). | Si se usa string literal en español, se genera deuda de localización. |
| S6 | Autorización Ley 1581 intercepta el paso médico del wizard (no flujo de perfil nuevo). | Si se decide interceptar en el perfil del usuario, la Fase 6 requiere nueva sección en `EditProfilePage`. |
| S7 | `rideglory-contracts` es submódulo; el flujo de PR puede tomar tiempo. Backend y Flutter se desarrollan en paralelo con contratos localmente enlazados. | Si el PR de contratos tarda, la cadena completa espera. |
| S8 | `RegistrationStepIndicator` recibe `stepCount` como parámetro (verificar en pre-flight de Fase 4 — primer paso obligatorio). Si está hardcodeado, generalizar antes de agregar el paso de waiver. | Sin generalización previa, el indicador visual rompe al agregar el paso 5. |

### Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | `rideglory-contracts` como cuello de botella | Alta | Bloquea Fases 1-7 si el PR tarda. | Priorizar como primera acción; usar `npm link` local mientras tanto. |
| R2 | `bloodType` ofuscado rompe deserialización del enum en Flutter | Media | `EventRegistrationDto.fromJson()` lanza excepción en runtime. | Fase 3 implementa getter de parse seguro. Cubierto en el plan. |
| R3 | Default retroactivo `shareMedicalInfo = false` para inscripciones existentes | Baja (sin usuarios reales) | Organizadores perderían acceso a datos médicos de rodadas activas. | Documentado en migración. Con usuarios reales, considerar default temporal `true` con banner. |
| R4 | Descarte silencioso de campos en `toJson()` de `EventRegistrationModelExtension` | Alta (confirmado por auditor) | Los 4 campos legales no viajan en el POST aunque el modelo los tenga. | Fase 3 requiere criterio de aceptación verificable: test/curl confirma presencia de los 4 campos en el body. |
| R5 | `RegistrationDetailBottomBar` early-return oculta botones de contacto en inscripciones aprobadas | Media | El organizador no puede llamar/contactar al rider aunque lo haya autorizado. | Fase 7 refactoriza el `build()` para independizar `RegistrationContactActions` del early-return. |
| R6 | `RegistrationDetailPage` no tiene acceso al estado del evento | Media | La coherencia de la UI entre ofuscación backend y vista Flutter depende de datos que no fluyen hoy. | Fase 7 extiende `RegistrationDetailExtra` con `eventState` y `eventSosTriggeredAt`. |
| R7 | Consentimiento Ley 1581 solo en `SharedPreferences` | Baja | Pérdida de consentimiento al reinstalar; riesgo de compliance. | Persistencia offline-first: caché local + backend como fuente de verdad. |
| R8 | Organizador que también es participante | Baja | `isRegistrantViewer` basado en `userId` da falso positivo. | Fase 7 usa `isOrganizerView: bool` explícito en `RegistrationDetailExtra`. |
| R9 | Texto legal no disponible a tiempo | Media | Flujo completo bloqueado en producción aunque técnicamente funcional. | Placeholder v0 con texto genérico hasta obtener asesoría legal. |
| R10 | `sosTriggeredAt` no existe en Prisma de events-ms | Media | La ofuscación de Capa B (cédula/correo/ciudad en SOS) no puede implementarse. | Gate accionable en pre-flight de Fase 2: verificar antes de escribir lógica de Fase 2b. |

---

## Criterios de éxito globales

- Un rider menor de 18 años no puede inscribirse ni en la app (validación local) ni en el backend (422 `UNDERAGE_RIDER`).
- Un rider puede elegir explícitamente si comparte su información médica (`shareMedicalInfo`) y si permite contacto del organizador (`allowOrganizerContact`) al inscribirse. Los switches tienen subtítulos explicativos. La elección llega al backend (verificado por test/curl en Fase 3).
- El organizador ve los campos de inscripción con valores reales u ofuscados (`"__NOT_SHARED__"` / `"••••"`) según las reglas de privacidad. Flutter localiza los centinelas a texto en español.
- Un organizador no puede publicar un evento sin aceptar la declaración de responsabilidad. El timestamp queda en el backend.
- Un rider no puede completar los campos médicos del wizard sin una autorización Ley 1581 explícita. El consentimiento se persiste en backend y en caché local.
- `dart analyze` pasa sin errores en Flutter; `build_runner` genera sin conflictos; contratos compilados en todos los MS afectados.
- Todos los strings de UI están en `app_es.arb`; cero strings hardcodeados en widgets.
