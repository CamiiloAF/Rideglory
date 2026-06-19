# 01 — System Scan

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:18:06Z

---

## Inventario Flutter

### `lib/features/event_registration/`

**Domain:**
- `EventRegistrationModel` — modelo plano sin freezed; campos: `id`, `eventId`, `eventName`, `userId`, `status` (enum), `fullName`, `identificationNumber`, `birthDate` (DateTime), `phone`, `email`, `residenceCity`, `eps`, `medicalInsurance?`, `bloodType` (enum), `emergencyContactName`, `emergencyContactPhone`, `vehicleId?`, `vehicleSummary?`. **Faltan:** `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`.
- `VehicleSummaryModel` — resumen de vehículo para mostrar en detalle.
- `EventRegistrationRepository` (interfaz) + use cases: `add`, `update`, `cancel`, `approve`, `reject`, `setReadyForEdit`, `getByEvent`, `getMyRegistrationForEvent`, `getMyRegistrations`.

**Data:**
- `EventRegistrationDto extends EventRegistrationModel` — Pattern B correcto; `toJson()` resuelve `birthDate` manualmente. Sin campos legales aún.
- `RegistrationService` — cliente Dio manual (no Retrofit); métodos: `create`, `update`, `cancel`, `approve`, `reject`, `setReadyForEdit`, `findByEvent`, `findMyRegistrationForEvent`, `findMyRegistrations`. El body de `create`/`update` acepta `Map<String, dynamic>` arbitrario — flexible para agregar nuevos campos.

**Presentation:**
- `RegistrationFormCubit` — maneja wizard de 4 pasos + `saveToProfile`. `_buildRegistration()` construye `EventRegistrationModel` desde `FormBuilder`. **Sin** lógica de edad, waiver, ni consentimientos.
- Wizard de 4 pasos (Personal → Medical → Emergency → Vehicle) via `RegistrationWizardController` (`stepCount=4`). El waiver será un paso/pantalla adicional (o modal pre-submit).
- `RegistrationFormContent` — `IndexedStack` con todos los pasos montados para preservar estado del `FormBuilder`. Añadir un paso implica incrementar `stepCount` y registrar `fieldsByStep`.
- `RegistrationDetailPage` — muestra todas las secciones (personal, médica, emergencia, vehículo) tal cual llegan del backend. **Sin** lógica de ofuscación ni botones WhatsApp/llamada.
- `RegistrationDetailBottomBar` — acciones para organizador (aprobar/rechazar/solicitar edición) y piloto (editar/cancelar). Sin botones de contacto.

### `lib/features/events/`

**Domain:**
- `EventModel` — sin `organizerAcceptedResponsibilityAt`. Ya tiene `EventState` con `inProgress` (útil para ofuscación condicional). `sosTriggeredAt` ya existe en Prisma pero no está mapeado al Flutter model.
- `EventState.inProgress` existe pero no se expone al detalle de inscripción.

**Presentation:**
- `EventFormCubit` — wizard de 4 pasos de creación. `PublishRow` dispara directamente `saveEvent` sin pantalla de responsabilidad del organizador.
- Flujo de publicación: Step 4 (review) → botón "Publicar" → guarda. **Falta** pantalla/modal de aceptación de responsabilidad antes del publish.

### `lib/features/profile/`

- `ProfilePage`, `EditProfilePage`, `ProfileContent` — gestión de perfil de usuario básico. Sin pantalla de autorización Ley 1581 para datos médicos.
- `AnalyticsConsentCubit` — consentimiento de analytics (ya existe como patrón). Sirve de referencia para el patrón de consentimiento nuevo.
- `SignupTermsCheckbox` — ya referencia T&C y privacidad estáticos en GitHub Pages (`camiiloaf.github.io/Rideglory/web/`). El waiver de eventos es diferente.

### `lib/features/authentication/`

- `SignupTermsCheckbox` — acepta T&C + política de privacidad global. No es el waiver contextual de eventos.

### `lib/shared/helpers/`

- `UrlLauncherHelper` — `openPhone(phone)` y `openWhatsApp(phone)` ya implementados y listos para usar en `RegistrationDetailPage`.

---

## Dependencias

| Paquete | Versión | Relevancia para este plan |
|---------|---------|--------------------------|
| `url_launcher` | `^6.3.1` | Ya instalado; `UrlLauncherHelper.openWhatsApp/openPhone` listos. |
| `flutter_bloc` | `^9.1.1` | Cubits nuevos para waiver + consentimiento. |
| `freezed_annotation` | `^3.1.0` | Para nuevos estados freezed. |
| `flutter_form_builder` | `^10.2.0` | Wizard existente; pasos extra usan `FormBuilderSwitch` — pero el proyecto exige `AppSwitchTile`. |
| `form_builder_validators` | `^11.0.0` | Validación de campos. |
| `go_router` | `^17.0.0` | Navegación a nuevas pantallas (waiver, responsabilidad, 1581). |

**No se necesita ningún paquete nuevo** para implementar este plan.

---

## Superficie rideglory-api

### Microservicio `events-ms`

**Prisma schema — `EventRegistration`:**
Campos actuales: `id`, `eventId`, `userId`, `status`, `fullName`, `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `medicalInsurance?`, `bloodType`, `emergencyContactName`, `emergencyContactPhone`, `vehicleId?`, `createdAt`, `updatedAt`.
**Faltan:** `shareMedicalInfo Bool`, `allowOrganizerContact Bool`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`.

**Prisma schema — `Event`:**
Campos actuales: incluye `state EventState`, `sosTriggeredAt DateTime?`. **Falta:** `organizerAcceptedResponsibilityAt DateTime?`.

**`RegistrationsService.create()`:** Sin validación de edad. Procesa `birthDate` como campo normal sin cálculo de edad.

**Endpoints (api-gateway → events-ms via TCP):**

| Método | Path | Propósito | Gap |
|--------|------|-----------|-----|
| `POST` | `/events/:eventId/registrations` | Crear inscripción | Sin validación edad ≥18, sin campos legales |
| `PATCH` | `/registrations/:id` | Actualizar inscripción | Sin campos legales |
| `POST` | `/registrations/:id/cancel` | Cancelar | OK |
| `POST` | `/registrations/:id/approve` | Aprobar | OK |
| `POST` | `/registrations/:id/reject` | Rechazar | OK |
| `POST` | `/registrations/:id/ready-for-edit` | Solicitar edición | OK |
| `GET` | `/events/:eventId/registrations` | Lista para organizador | Sin ofuscación condicional |
| `GET` | `/events/:eventId/registrations/me` | Mi inscripción | Sin ofuscación condicional |
| `GET` | `/registrations/me` | Mis inscripciones | OK |

### Contratos (`rideglory-contracts`)

- `CreateRegistrationDto` — sin `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`.
- `EventRegistrationDto` — sin campos legales.
- `UpdateRegistrationDto` — sin campos legales.

### Microservicio `users-ms`

- No requiere cambios para este plan (los campos de consentimiento van en inscripción, no en usuario).

---

## Gap Analysis

| Componente | Estado | Detalle |
|------------|--------|---------|
| **Validación edad ≥18 en backend** | not started | `create()` no calcula ni verifica edad a partir de `birthDate`. |
| **Campos legales en `EventRegistration` (Prisma)** | not started | `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` no existen en schema. |
| **Campo legal en `Event` (Prisma)** | not started | `organizerAcceptedResponsibilityAt` no existe. |
| **Contratos DTO (`rideglory-contracts`)** | not started | `CreateRegistrationDto`, `UpdateRegistrationDto`, `EventRegistrationDto` sin campos legales. |
| **Ofuscación condicional GET registrations** | not started | `findByEvent` retorna datos crudos sin lógica de privacidad por capas. |
| **`EventRegistrationModel` Flutter** | not started | Sin `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`. |
| **`EventModel` Flutter** | not started | Sin `organizerAcceptedResponsibilityAt`. |
| **`EventRegistrationDto` Flutter** | not started | Sin campos legales nuevos. |
| **Pantalla waiver (rider)** | not started | No existe; el wizard termina en el paso de vehículo sin pantalla de aceptación de riesgos. |
| **Opt-ins médico/contacto (`AppSwitchTile`)** | not started | No existen en wizard. |
| **Validación local edad Flutter** | not started | `RegistrationFormCubit._buildRegistration()` no verifica edad. |
| **Pantalla responsabilidad organizador** | not started | `PublishRow` publica directamente sin pantalla de aceptación. |
| **Botones WhatsApp/llamada en `RegistrationDetailPage`** | not started | `UrlLauncherHelper` listo, pero no se usa en detalle de inscripción. |
| **Pantalla autorización Ley 1581** | not started | No existe en flujo de perfil médico. |
| **`RegistrationDetailPage` — renderizado ofuscado** | not started | Muestra datos directamente; no interpreta `••••` ni flags. |
| **l10n strings** | not started | Ningún string de waiver/consentimiento/edad en `app_es.arb`. |
| **T&C / waiver URLs estáticos** | partial | Existe T&C global en GitHub Pages; falta URL del waiver contextual de eventos y la pantalla de Ley 1581. |
| **`EventState.inProgress` expuesto a Flutter** | partial | Existe en `EventModel.state` pero el detalle de inscripción no lo lee para condicionamiento de UI. |
| **`sosTriggeredAt` en Flutter** | partial | Existe en Prisma, pero `EventModel` Flutter no lo mapea (requerido para Capa B de ofuscación). |

---

## Patrones

1. **Wizard multi-paso** (`RegistrationFormContent` + `RegistrationWizardController`): el waiver es un paso adicional o una pantalla modal pre-submit. Agregar paso implica: (a) nuevo archivo step, (b) registrar en `RegistrationWizardSteps.fieldsByStep`, (c) incrementar `stepCount`, (d) extender `_stepNameFor` en analytics.

2. **Consentimiento booleano local** (`AnalyticsConsentCubit`): patrón existente para almacenar un flag de consentimiento y exponerlo como estado. Los opt-ins `shareMedicalInfo`/`allowOrganizerContact` siguen el mismo patrón dentro del `RegistrationFormCubit` como flags adicionales, o como campos `FormBuilderField` dentro del step de waiver.

3. **Ofuscación en backend, render transparente en Flutter**: la app no necesita lógica de ofuscación; recibe los datos tal cual (reales u ofuscados `••••`/flag) y los renderiza en `RegistrationDetailDataRow`. La lógica de ofuscación es 100% backend.

4. **UrlLauncherHelper** ya provee `openWhatsApp` y `openPhone` listos para uso. Solo falta inyectarlos en `RegistrationDetailPage` condicionados a `allowOrganizerContact`.

5. **Pattern B DTO**: `EventRegistrationDto extends EventRegistrationModel` — todo campo nuevo en el modelo debe reflejarse en el DTO con la misma firma.

---

## Implicaciones para el plan

1. **El backend es el trabajo más crítico y bloqueante**: la migración de Prisma (4 campos en `EventRegistration`, 1 en `Event`), la actualización de contratos (`rideglory-contracts`) y la validación de edad ≥18 deben ser Fase 1. Sin esto, la app Flutter no puede integrarse end-to-end.

2. **El wizard de inscripción necesita cirugía puntual, no reescritura**: agregar 1 paso de waiver + 2 `AppSwitchTile` en el paso médico es incremental. El `IndexedStack` ya soporta N pasos. El `stepCount` sube de 4 a 5 (o el waiver va como pantalla modal antes del submit, evitando tocar el step indicator).

3. **`RegistrationDetailPage` requiere 3 cambios encadenados**: (a) el backend retorna datos ofuscados, (b) Flutter los renderiza tal cual, (c) se agregan botones de contacto condicionados a `allowOrganizerContact`. El orden no puede invertirse.

4. **`EventModel` y `EventState.inProgress` son palancas ya disponibles**: `event.state == EventState.inProgress` puede usarse para condicionar la visibilidad de los botones de contacto sin cambios de modelo, solo consumiendo el estado que ya llega desde `EventRegistrationParams`.

5. **El texto legal (waiver y Ley 1581) es un bloqueador de UX pero no de arquitectura**: se puede implementar todo el flujo con placeholders `v0` y actualizar el texto sin cambios de código (via URL estática en GitHub Pages o inline string). Debe resolverse la pregunta abierta #1 antes de la fase de Flutter.
