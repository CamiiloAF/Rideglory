# 03 — Architect Review

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:21:31Z
**Verdict:** `ok_con_ajustes`

---

## Validación por fase

### Fase 1 — Contratos y schema de backend
**Complejidad: media**

Técnicamente sólida. La migración de Prisma requiere 4 campos en `EventRegistration` y 1 en `Event`. El crítico es el default seguro en la migración:

```sql
-- EventRegistration
ALTER TABLE "EventRegistration" ADD COLUMN "shareMedicalInfo" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "EventRegistration" ADD COLUMN "allowOrganizerContact" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "EventRegistration" ADD COLUMN "riskAcceptedAt" TIMESTAMP(3);
ALTER TABLE "EventRegistration" ADD COLUMN "riskAcceptanceVersion" VARCHAR(50);
-- Event
ALTER TABLE "Event" ADD COLUMN "organizerAcceptedResponsibilityAt" TIMESTAMP(3);
```

`rideglory-contracts` es submódulo — el flujo obligatorio es: PR en `rideglory-contracts` → `npm run build` → `pnpm install` en `events-ms` y `api-gateway`. `UpdateRegistrationDto` hereda via `PartialType(OmitType(CreateRegistrationDto, ['eventId']))`, por lo que agregar campos a `CreateRegistrationDto` los hace opcionales en `UpdateRegistrationDto` automáticamente — correcto para este caso.

**Ajuste requerido:** `CreateRegistrationDto` necesita `@IsBoolean()` para `shareMedicalInfo` y `allowOrganizerContact` (no opcionales — deben ser `required` en la creación, con default `false` si el frontend no los envía). `riskAcceptedAt` y `riskAcceptanceVersion` deben ser `@IsOptional()` en el DTO de contratos pero **no** opcionales en el servicio: si `riskAcceptedAt` es null al crear, el backend debe rechazar con `400 RISK_NOT_ACCEPTED`. La validación de negocio debe distinguirse del campo nullable en DB (timestamp es nullable para inscripciones pre-migración).

---

### Fase 2 — Validación de edad y ofuscación condicional
**Complejidad: media-alta**

Esta es la fase más delicada del plan. Dos sub-problemas distintos:

**2a. Validación de edad:** Straightforward en `RegistrationsService.create()`. Calcular `Math.floor((Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000)) < 18` y lanzar `RpcException({ status: 422, message: 'AGE_BELOW_MINIMUM' })`. El frontend debe manejar este error explícitamente con mensaje l10n.

**2b. Ofuscación condicional en `findByEvent`:** La lógica requiere que el servicio acceda al `Event.state` y `Event.sosTriggeredAt`. `RegistrationsService` ya tiene `ensureEventExists()` que retorna el evento — reusar para obtener el estado del evento sin una segunda query. La ofuscación aplica campo por campo:

| Campo | Condición para mostrar real |
|-------|----------------------------|
| `eps`, `medicalInsurance`, `bloodType` | `event.state === IN_PROGRESS && shareMedicalInfo === true` |
| `emergencyContactName`, `emergencyContactPhone` | `event.state === IN_PROGRESS` |
| `phone` | `allowOrganizerContact === true` |
| `identificationNumber`, `email`, `residenceCity` | `sosTriggeredAt !== null` (SOS activo) |

**Ajuste requerido:** La ofuscación debe aplicarse TAMBIÉN en `findMyRegistrationForEvent` (para que el rider vea lo que el organizador ve de él, o para el propio rider — aclarar qué vista usa este endpoint). Si el endpoint es solo para el rider sobre su propia inscripción, la ofuscación NO aplica allí. La ofuscación aplica en `findByEvent` (vista organizador). Recomendar endpoint separado `GET /events/:id/registrations` (organizador) vs `GET /events/:id/registrations/me` (rider) con lógica distinta — arquitectura actual ya lo separa.

**Decisión arquitectónica para el "No compartido" vs `"••••"`:** El PO propone string literal `"No compartido"` desde el backend. Aceptado. No contamina el modelo — el frontend renderiza lo que recibe. Pero el contrato debe especificar explícitamente en `EventRegistrationDto` que estos campos pasan a `string` (no nullable) cuando están ofuscados.

---

### Fase 3 — Modelos y DTOs Flutter
**Complejidad: baja**

`EventRegistrationModel` es una clase Dart plana (no freezed) con `copyWith` manual — agregar 4 campos nuevos es mecánico. `EventRegistrationDto extends EventRegistrationModel` (Pattern B) — los campos nuevos van en ambos. El `copyWith` manual debe extenderse.

`EventModel` necesita `organizerAcceptedResponsibilityAt: DateTime?`. `EventDto extends EventModel` — mismo patrón.

`sosTriggeredAt` debe mapearse en `EventModel` ahora (ya existe en Prisma, el scan lo confirma). Sin esto, la Fase 7 no puede condicionar los botones de contacto.

`RegistrationService` usa cliente Dio manual (no Retrofit) — los campos nuevos se agregan al `Map<String, dynamic>` usando `.toJson()` del DTO, no construcción manual (memoria DTO toJson rule).

**Sin code-gen adicional** — no hay nuevos archivos `.g.dart` para los modelos de dominio (no freezed). Solo `EventRegistrationDto` y `EventDto` requieren regenerar sus `.g.dart`.

---

### Fase 4 — Waiver del rider en el flujo de inscripción
**Complejidad: media**

El wizard actual tiene `stepCount=4` con `IndexedStack`. Hay dos opciones de integración:

**Opción A (recomendada):** Paso 5 de waiver — incrementar `stepCount` a 5, agregar `registration_waiver_step.dart` en `wizard/steps/`, actualizar `RegistrationWizardSteps.fieldsByStep` y `_stepNameFor` en analytics. Los 2 `AppSwitchTile` (`shareMedicalInfo`, `allowOrganizerContact`) van en el paso médico existente (paso 2), NO en el waiver — son preferencias de privacidad médica, no parte del waiver de riesgos.

**Opción B:** Modal pre-submit (BottomSheet). Más simple pero interrumpe el flujo de un wizard que ya tiene pasos definidos — inconsistente con el patrón UX establecido.

**Elegir Opción A.**

`RegistrationFormCubit._buildRegistration()` debe incluir los campos nuevos. Los 2 switches son `FormBuilderField` en el paso médico con valores por defecto `false`. `riskAcceptedAt = DateTime.now()` y `riskAcceptanceVersion = 'v0.1-2026-06'` se inyectan en `_buildRegistration()` al momento del submit (no son campos del formulario).

Validación local de edad: en `RegistrationFormCubit.saveRegistration()` antes de emitir `loading()`, calcular edad desde `birthDate` del form y emitir `ResultState.error()` con mensaje l10n si `< 18`. Esto es validación de UX — el backend valida independientemente.

**Ajuste requerido:** `RegistrationFormFields` debe incluir las constantes `shareMedicalInfo` y `allowOrganizerContact`. El `_preloadFromExistingRegistration` debe patchear estos campos en modo edición.

---

### Fase 5 — Aceptación de responsabilidad del organizador
**Complejidad: baja**

`PublishRow` dispara `saveEvent` directamente. La intercepción puede hacerse de dos formas:

**Opción A:** Navegar a una nueva `OrganizerResponsibilityPage` via `context.pushNamed()` antes del `saveEvent`. La página tiene el texto y el botón "Acepto" que llama de regreso al cubit.

**Opción B:** `ConfirmationDialog` (ya existe en shared). Más simple, pero el texto legal puede ser largo y los dialogs no hacen scroll bien en esta app.

**Elegir Opción A** (página completa). `organizerAcceptedResponsibilityAt` se envía en el body de `PATCH /events/:id` o `POST /events` (dependiendo si es creación o publicación de borrador). El `CreateEventDto` en contratos no tiene este campo — debe agregarse como `@IsOptional()` para no romper flujos de creación de borrador donde la responsabilidad no aplica aún.

**Decisión arquitectónica:** La responsabilidad solo se exige cuando `state` pasa a `SCHEDULED` (publicar). El backend valida que si `state === SCHEDULED`, entonces `organizerAcceptedResponsibilityAt` debe ser no-null. El flutter envía el timestamp cuando el organizador toca "Acepto y publicar".

---

### Fase 6 — Autorización Ley 1581 en perfil médico
**Complejidad: media**

El PO deja abierta la pregunta de si el consentimiento va solo en `SharedPreferences` o también en backend.

**Decisión arquitectónica:** El consentimiento Ley 1581 DEBE persistirse en backend, no solo localmente. Razón: si el usuario cambia de dispositivo o reinstala la app, perder el consentimiento local significaría mostrar la pantalla de nuevo cuando el usuario ya consintió. Más importante: para auditoría legal, el timestamp de consentimiento debe estar en el servidor.

**Implementación:** Nuevo campo `medicalConsentAcceptedAt: DateTime?` en `users-ms` tabla `User` (Prisma). Nuevo endpoint `POST /users/me/medical-consent` — body: `{ consentVersion: string }`, respuesta: `{ medicalConsentAcceptedAt: DateTime }`. El frontend: al abrir perfil médico, consulta si `currentUser.medicalConsentAcceptedAt != null`. Si es null, navega a `MedicalConsentPage` antes de mostrar el formulario. `MedicalConsentCubit` extiende `Cubit<ResultState<DateTime>>`.

**Impacto en Fase 3:** `UserModel` en Flutter necesita `medicalConsentAcceptedAt: DateTime?`. Esto debe coordinarse con la Fase 3 o agregarse como Fase 3b.

**Impacto en backend:** `users-ms` requiere migración de Prisma adicional + nuevo endpoint. `rideglory-contracts` necesita `MedicalConsentDto`. Esto es trabajo de backend adicional no contemplado en la Fase 1.

**Ajuste requerido:** La Fase 6 tiene dependencia de backend no listada en la Fase 1. O se expande la Fase 1 para incluir este campo, o se crea una Fase 1b. Recomiendo expandir la Fase 1.

---

### Fase 7 — Vista del organizador con ofuscación y contacto
**Complejidad: baja**

`RegistrationDetailPage` ya distingue `isRegistrantViewer` via `registration.userId == currentUserId`. Los botones de contacto deben renderizarse cuando `!isRegistrantViewer && registration.allowOrganizerContact == true`.

`UrlLauncherHelper.openWhatsApp(phone)` y `openPhone(phone)` ya están implementados y listos.

Los valores ofuscados `"No compartido"` / `"••••"` se renderizan via `RegistrationDetailDataRow.value` sin cambios en el widget — simplemente el backend retorna ese string y el frontend lo muestra.

**Ajuste menor:** `RegistrationDetailExtra` no lleva `eventOwnerId` actualmente de forma consistente en todos los navegadores — verificar que todos los `context.pushNamed(AppRoutes.registrationDetail, extra: RegistrationDetailExtra(..., eventOwnerId: event.ownerId))` lo estén enviando, o agregar `isOrganizerView: bool` explícito al extra para eliminar la ambigüedad.

---

## Contratos

### `rideglory-contracts` — cambios requeridos

#### `CreateRegistrationDto` (ampliado)
```typescript
@IsBoolean()
shareMedicalInfo: boolean = false;

@IsBoolean()
allowOrganizerContact: boolean = false;

@IsOptional()
@Type(() => Date)
@IsDate()
riskAcceptedAt?: Date;

@IsOptional()
@IsString()
riskAcceptanceVersion?: string;
```
Nota: El backend rechaza (`422 RISK_NOT_ACCEPTED`) si `riskAcceptedAt` no está presente al crear una inscripción nueva.

#### `EventRegistrationDto` (respuesta — campos ofuscables pasan a `string`)
```typescript
// Campos que pueden estar ofuscados (siempre string, nunca null cuando ofuscados)
eps: string;
medicalInsurance: string | null;  // null solo si el rider no lo llenó
bloodType: string;                // BloodType enum o '••••'
emergencyContactName: string;
emergencyContactPhone: string;
phone: string;
identificationNumber: string;
email: string;
residenceCity: string;

// Nuevos campos
shareMedicalInfo: boolean;
allowOrganizerContact: boolean;
riskAcceptedAt: Date | null;
riskAcceptanceVersion: string | null;
```

#### `UpdateRegistrationDto`
Se hereda automáticamente vía `PartialType(OmitType(CreateRegistrationDto, ['eventId']))`. Los 4 campos nuevos quedan opcionales — correcto para edición.

#### `CreateEventDto` / `UpdateEventDto`
```typescript
@IsOptional()
@Type(() => Date)
@IsDate()
organizerAcceptedResponsibilityAt?: Date;
```

#### Nuevo: `MedicalConsentDto` (en `users/dto/`)
```typescript
export class MedicalConsentDto {
  @IsString()
  @MinLength(1)
  consentVersion!: string;
}

export class MedicalConsentResponseDto {
  medicalConsentAcceptedAt!: Date;
}
```

### Endpoints nuevos / modificados

| Método | Path | MS | Cambio |
|--------|------|----|--------|
| `POST` | `/events/:eventId/registrations` | events-ms | Validación edad ≥18, persistir 4 campos legales, rechazar si `riskAcceptedAt` null |
| `PATCH` | `/registrations/:id` | events-ms | Aceptar 4 campos legales opcionales |
| `GET` | `/events/:eventId/registrations` | events-ms | Ofuscación condicional por campo |
| `PATCH` | `/events/:id` | events-ms (via api-gateway) | Aceptar `organizerAcceptedResponsibilityAt`; validar si state→SCHEDULED |
| `POST` | `/users/me/medical-consent` | users-ms (via api-gateway) | Nuevo endpoint — persiste `medicalConsentAcceptedAt` |
| `GET` | `/users/me` | users-ms | Retornar `medicalConsentAcceptedAt` en `UserDto` |

### Migraciones de Prisma

**events-ms** — una migración, 5 campos:
- `EventRegistration`: `shareMedicalInfo Bool @default(false)`, `allowOrganizerContact Bool @default(false)`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`
- `Event`: `organizerAcceptedResponsibilityAt DateTime?`

**users-ms** — una migración, 1 campo:
- `User`: `medicalConsentAcceptedAt DateTime?`

### Flutter — modelos / DTOs nuevos y modificados

| Artefacto | Cambio | Code-gen |
|-----------|--------|----------|
| `EventRegistrationModel` | +4 campos: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt?`, `riskAcceptanceVersion?` | No (clase plana) |
| `EventRegistrationDto` | +4 campos (hereda de Model, Pattern B) | Sí (`.g.dart`) |
| `EventModel` | +2 campos: `organizerAcceptedResponsibilityAt?`, `sosTriggeredAt?` | No (clase plana) |
| `EventDto` | +2 campos (hereda de Model, Pattern B) | Sí (`.g.dart`) |
| `UserModel` | +1 campo: `medicalConsentAcceptedAt?` | No |
| `UserDto` | +1 campo (hereda de Model, Pattern B) | Sí (`.g.dart`) |
| `RegistrationFormFields` | +2 constantes: `shareMedicalInfo`, `allowOrganizerContact` | No |

---

## Riesgos

### R1 — Default de ofuscación retroactivo (ALTO)
Las inscripciones existentes tienen `shareMedicalInfo = false` por el DEFAULT de Prisma. Esto significa que los organizadores de rodadas activas **perderán acceso** a datos médicos de pilotos inscritos antes de la migración. Para rodadas sin usuarios reales (confirmado en memoria: `project_no_real_users.md`) esto no es problema en producción, pero es un defecto de diseño que debe ser explícito en la implementación.

**Mitigación:** La migración debe documentar el comportamiento esperado. Si en el futuro hay usuarios reales, considerar un default temporal `true` con banner de acción requerida al piloto.

### R2 — Submódulo rideglory-contracts como cuello de botella (ALTO)
Cualquier PR de contratos bloquea backend Y frontend. Si los contratos tardan en mergearse, la Fase 1 no puede cerrarse y todas las demás fases esperan.

**Mitigación:** Priorizar el PR de contratos como primera acción. Backend y Flutter deben poder desarrollarse en paralelo con los contratos localmente enlazados (`npm link` o path local en `package.json`).

### R3 — `bloodType` ofuscado rompe el enum en Flutter (MEDIO)
Si el backend retorna `"••••"` en el campo `bloodType`, el `EventRegistrationDto` intentará deserializarlo como `BloodType` enum y fallará. El scan confirma que `bloodType` es un `BloodType` enum en el DTO.

**Mitigación arquitectónica requerida:** En `EventRegistrationDto.fromJson()`, el campo `bloodType` debe deseriziarlse como `String` en el DTO de respuesta (no como enum), y el `EventRegistrationModel.bloodType` debe cambiar a `String` o el DTO de respuesta debe tener un campo separado. **Decisión:** el campo `bloodType` en el modelo de dominio pasa a ser `BloodType?` con getter que hace parse seguro — si el valor no es un enum válido (porque está ofuscado), retorna `null` y la UI muestra el valor raw. Esto es un cambio de modelo en Fase 3 que el implementador debe atender.

### R4 — `RegistrationDetailExtra` no porta `isOrganizerView` explícito (BAJO)
La distinción organizador/piloto actualmente se infiere de `registration.userId == currentUserId`. Esto funciona para el piloto viendo su propia inscripción. Pero si el organizador también se inscribió (como organizador-participante, caso que el backend ya maneja), `isRegistrantViewer` será `true` aunque sea el organizador. Los botones de contacto no aparecerían.

**Mitigación:** Agregar `isOrganizerView: bool` explícito a `RegistrationDetailExtra`, derivado en el punto de navegación donde el organizador abre el detalle de la inscripción de un rider.

### R5 — Consentimiento Ley 1581 solo local es insuficiente (BAJO-MEDIO)
El PO dejó abierta la opción de `SharedPreferences` only. La decisión arquitectónica es que debe ir en backend (ver Fase 6). Si el implementador usa solo `SharedPreferences`, el consentimiento se pierde al reinstalar — riesgo de compliance.

**Mitigación:** La Fase 6 debe especificar explícitamente "persiste en backend + caché local en SharedPreferences para offline-first".

### R6 — `EventRegistrationDto` en contratos tiene campos como `BloodType` enum (MEDIO)
El `EventRegistrationDto` en `rideglory-contracts` importa `BloodType` del enum. Si el backend retorna strings ofuscados en lugar del enum, la serialización en el lado del backend también puede fallar si el servicio intenta mapear el enum.

**Mitigación:** En el mapper de respuesta (`RegistrationsService.findByEvent()`), los campos ofuscados se asignan como strings puros. El `EventRegistrationDto` en contratos debe declarar `bloodType: BloodType | string` (union type) para tipado correcto. El frontend maneja el parse defensivo.

---

## Ajustes

### Ajuste 1 — Expandir Fase 1 para incluir `users-ms`
**Impacto:** Fase 1 pasa de 2 migraciones en events-ms a 3 migraciones (events-ms x2 tablas + users-ms x1 tabla). El contrato `MedicalConsentDto` y el campo `medicalConsentAcceptedAt` en `UserDto` son parte de Fase 1.

**Justificación:** La Fase 6 depende de este campo en backend. Si no está en Fase 1, el plan tiene una dependencia cruzada no resuelta y la Fase 6 queda bloqueada hasta que alguien haga una migración tardía.

### Ajuste 2 — Dividir Fase 2 en dos sub-fases o tareas explícitas
**2a — Validación de edad:** 1 método en `RegistrationsService.create()`, bajo riesgo.
**2b — Ofuscación condicional:** Lógica por capas en `findByEvent()`, requiere manejar el edge case del `BloodType` enum + mapeo de strings ofuscados. Riesgo medio.

El implementador debe abordar 2a primero, luego 2b, con tests unitarios para cada capa de ofuscación.

### Ajuste 3 — Fase 3 debe incluir `UserModel.medicalConsentAcceptedAt`
Si la Fase 1 expande para incluir el campo en `users-ms`, la Fase 3 debe incluir el campo correspondiente en `UserModel` y `UserDto` Flutter. El scan de `users-ms` no fue exhaustivo — verificar que `UserDto` en contratos ya exista y agregar el campo.

### Ajuste 4 — Especificar `bloodType` como `String` en `EventRegistrationDto` de respuesta
En `rideglory-contracts/src/events/dto/event-registration.dto.ts`, cambiar:
```typescript
bloodType!: BloodType;
// a:
bloodType!: BloodType | string;
```
Y en Flutter `EventRegistrationModel`, cambiar `bloodType: BloodType` a `bloodType: BloodType?` con getter de parse seguro. Los formularios de creación/edición siguen usando `BloodType` enum.

### Ajuste 5 — `RegistrationDetailExtra` debe exponer `isOrganizerView`
Agregar campo `isOrganizerView: bool` al constructor de `RegistrationDetailExtra`. Todos los puntos de navegación que abren el detalle de inscripción desde la lista de inscriptos del evento deben pasar `isOrganizerView: true`.

### Ajuste 6 — `riskAcceptedAt` obligatorio en backend para nuevas inscripciones, nullable en DB
La migración pone `riskAcceptedAt DateTime?` (nullable, para inscripciones pre-migración). El servicio NestJS aplica validación de negocio: si `riskAcceptedAt === undefined` o `null` al crear una inscripción NUEVA, rechaza con `422 RISK_NOT_ACCEPTED`. Inscripciones existentes con `riskAcceptedAt = null` son válidas (pre-migración). Esta distinción debe estar documentada en el handoff al backend.
