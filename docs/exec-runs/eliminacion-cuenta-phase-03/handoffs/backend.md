# Backend → (Frontend / QA) — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T19:49:16Z_

## Baseline

- `events-ms`: `npm test` → **6 suites / 48 tests pass** (verde antes de tocar código).
- `api-gateway`: `npm test` (completo) → **1 suite roja preexistente** (`places.service.iter3.spec.ts`,
  8 tests) por `MAPBOX_ACCESS_TOKEN` no cargado en el entorno de Jest — **no relacionada** con esta
  fase (no toca `places/`, ni contratos ni env vars de Mapbox). Baseline acotado al área de esta
  fase (`npm test -- account-deletion`) → **1 suite / 7 tests pass**. Se decidió continuar dado que
  el rojo preexistente es ajeno al alcance (no está en el change map) y el baseline del área
  afectada estaba verde. Ver nota más abajo.

## Archivos cambiados

**`rideglory-contracts`** (`/Users/cami/Developer/Personal/rideglory-api/rideglory-contracts`):
- `src/events/dto/anonymize-registrations-payload.dto.ts` (nuevo) — `AnonymizeRegistrationsPayloadDto { userId: string (@IsUUID) }`.
- `src/events/dto/index.ts` — export del nuevo DTO.
- `npm run build` corrido + `npm install` en la raíz del monorepo para relinkear `@rideglory/contracts` en `events-ms`/`api-gateway` (gotcha conocido).

**`events-ms`**:
- `src/registrations/registrations.controller.ts` — nuevo `@MessagePattern('anonymizeRegistrationsByUserId')`.
- `src/registrations/registrations.service.ts` — nuevo método `anonymizeByUserId(userId)` (`updateMany` + constante `ANONYMIZED_FULL_NAME = 'Usuario eliminado'`, distinta e independiente de `FULL_MASK`). Además, ajustes de tipos por el cambio de nulabilidad de Prisma: `persistRiderProfile()` ahora acepta los campos ahora-nulables como opcionales (con fallback `?? undefined`), y el genérico de `applyPrivacyMask<T>` amplía `eps`/`emergencyContactName`/`emergencyContactPhone`/`phone`/`identificationNumber`/`email`/`residenceCity` a `string | null` (el masking ya toleraba `null` vía `maskTail`, solo hacía falta el tipo).
- `src/registrations/registrations.service.anonymization.spec.ts` (nuevo) — spec de anonimización.
- `prisma/schema.prisma` — 8 columnas de `EventRegistration` pasan a nullable (`identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone`). `bloodType` y `fullName` intactos (`NOT NULL`).
- `prisma/migrations/20260710194244_registration_nullable_pii/migration.sql` (nuevo) — `ALTER TABLE ... DROP NOT NULL` x8. **Aplicada y verificada localmente** (ver Verificación manual). **No desplegada.**

**`api-gateway`**:
- `src/users/users.module.ts` — registrado `EVENTS_SERVICE` en `ClientsModule.registerAsync` (no existía; verificado antes de añadir, sin duplicado).
- `src/users/account-deletion.service.ts` — reescrito `deleteAccount()` con el orden de 8 pasos fijado por el Architect: `findUserByEmail` → **precondición `findEventsByOwnerId` + 409 `ACTIVE_EVENTS_AS_ORGANIZER`** → `hardDeleteAllByOwner` → `deleteFilesByUrls` (best-effort) → `softDeleteMaintenancesByUserId` → **`anonymizeRegistrationsByUserId`** → `hardDeleteUser` → `firebaseAuthService.deleteUser`. Docblock actualizado (6→8 pasos).
- `src/users/account-deletion.service.spec.ts` — reescrito: cobertura de los 8 pasos en orden, el bloqueo 409 sin efectos secundarios, no-bloqueo con eventos `CANCELLED`/`FINISHED`/sin eventos, y fallo de cada paso nuevo abortando los siguientes.
- `src/common/exceptions/rpc-custom-exception.filter.ts` — **cambio no listado explícitamente en el change map, necesario para cumplir el criterio de aceptación #5**: el filtro global solo emitía `{statusCode, message, traceId}` y descartaba cualquier propiedad extra del error RPC (`error`, `activeEvents`). Se amplió `normalizeError()` para capturar el resto de propiedades del objeto de error en un campo `extra` y `catch()` para hacer spread de `extra` en el body JSON antes de `traceId`. Cambio aditivo y retrocompatible: los tests preexistentes del filtro (8 tests, `objectContaining`) siguen pasando sin modificación, y ningún `RpcException` existente en el código tenía propiedades extra antes de este cambio (por lo que su output no cambia).

## Pruebas nuevas

- `events-ms/src/registrations/registrations.service.anonymization.spec.ts` (7 tests): filtra estrictamente por `EventRegistration.userId` (nunca `Event.ownerId`); anonimiza exactamente los 8 campos PII + `fullName` + los 2 booleanos de consentimiento de contacto/médico; **no** toca `bloodType`, `medicalInsurance`, evidencia legal (`riskAcceptedAt`/`riskAcceptanceVersion`/`medicalConsentAcceptedAt`/`medicalConsentVersion`), `vehicleId`, `status`, `eventId`, `userId`, `id`; no reutiliza `FULL_MASK`; retorna `count`; idempotencia (dos llamadas seguidas, mismo efecto); `count: 0` sin excepción cuando no hay registros.
- `api-gateway/src/users/account-deletion.service.spec.ts` (11 tests, antes 7): los 8 pasos en orden; caso feliz variantes (garage vacío, fallo de storage no aborta); 409 `ACTIVE_EVENTS_AS_ORGANIZER` con `activeEvents` no vacío y **cero** llamadas a pasos de borrado (incluye verificación de que ni `anonymizeRegistrationsByUserId` ni `hardDeleteUser` se invocan); no-bloqueo con eventos `CANCELLED`/`FINISHED` o sin eventos propios; fallo de cada paso nuevo/existente (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`, `anonymizeRegistrationsByUserId`, `hardDeleteUser`) abortando los pasos siguientes.

## Resultado final

- `events-ms`: `npm test` → **7 suites / 55 tests pass**. `npm run build` (tsc) → sin errores.
- `api-gateway`: `npm test -- account-deletion` → **11/11 pass**. `npm test -- rpc-custom-exception` → **8/8 pass** (sin regresión). `npm test` completo → **16/17 suites pass, 143/151 tests pass**; la única suite roja (`places.service.iter3.spec.ts`, 8 tests) es la **misma preexistente del baseline**, no relacionada con esta fase. `npm run build` (tsc) → sin errores.
- `users-ms` y `vehicles-ms`: `npm test` → verdes (6/6 y 50/50) tras el `npm install` de raíz que relinkeó `@rideglory/contracts` — sin regresión por el cambio de contracts.
- `rideglory-contracts`: `npm run build` → sin errores.

## Verificación manual

- Migración Prisma aplicada localmente contra la BD de `events-ms` en `localhost:5432/events`
  (Postgres nativo local, no el contenedor Docker — el `docker-compose.yml` de este repo no publica
  el puerto 5432 al host). Verificado con `psql`:
  - Las 8 columnas ahora aparecen `Nullable` en `\d "EventRegistration"`.
  - `bloodType` y `fullName` siguen `NOT NULL`.
  - `SELECT count(*) FROM "EventRegistration"` = 5 filas existentes; `SELECT count(*) WHERE
    "identificationNumber" IS NULL` = 0 — **la migración no tocó datos existentes**, solo relajó el
    constraint (aditiva, confirmado).
  - `prisma generate` corrido para regenerar el cliente.
  - **No se desplegó** contra ningún entorno remoto/producción.
- Nota sobre `prisma migrate dev`: al intentar generarla con el comando estándar, Prisma reportó
  "drift" preexistente en 2 migraciones antiguas del repo (`20260611000000_remove_event_city`,
  `20260701014208_add_medical_consent_risk_fields`, modificadas después de aplicadas — ajeno a esta
  fase) y pidió resetear la BD local (perdiendo los 5 registros existentes que necesitaba para
  verificar la aditividad). Se optó por escribir el `migration.sql` a mano (ALTER TABLE ... DROP NOT
  NULL x8, contenido idéntico al que Prisma habría generado) y aplicarlo con `prisma migrate deploy`
  (que no hace drift-check, solo aplica pendientes) — evita el reset y logra el mismo resultado
  aditivo. Documentado aquí para que quien despliegue a producción sepa que el archivo fue escrito
  a mano, no generado por `migrate dev`, aunque su contenido es el ALTER TABLE estándar esperado.

## Notas Frontend/QA

- **Contrato 409 confirmado y ahora entregable end-to-end**: `DELETE /users/me` responde
  `{"statusCode": 409, "message": "<texto ES>", "error": "ACTIVE_EVENTS_AS_ORGANIZER",
  "activeEvents": [{"id","name","state"}], "traceId"?}`. El mensaje ES exacto usado:
  *"No puedes eliminar tu cuenta mientras tengas eventos activos como organizador. Cancela o
  finaliza tus eventos primero."* — Frontend puede confiar en `error` y `activeEvents` como
  propiedades del body (antes de este cambio el filtro global las descartaba; ver arriba).
- El campo `activeEvents` solo incluye eventos en `DRAFT`/`SCHEDULED`/`IN_PROGRESS`, no todos los
  eventos del organizador.
- `anonymizeRegistrationsByUserId` es un `MessagePattern` interno (`events-ms`), no expuesto por
  HTTP — Frontend no lo llama directamente; solo observa el efecto (nombre `"Usuario eliminado"` y
  campos nulos) en `AttendeesList`/`RegistrationDetailPage` para inscripciones de cuentas
  eliminadas, tal como especifica `PRD_NORMALIZED.md` criterios 9-10.
- Pendiente de mi alcance (fuera del change map de Backend): los cambios de Flutter (nulabilidad de
  `EventRegistrationModel`/DTO, `ProfileActionsList`, `ActiveEventsBlockSheet`,
  `RegistrationDetailPage`, l10n) — corresponden al agente Frontend.
- QA: para probar el 409 end-to-end se necesita un usuario organizador con al menos un evento en
  `DRAFT`/`SCHEDULED`/`IN_PROGRESS`; para probar la anonimización, un rider con al menos una
  `EventRegistration` cuya cuenta se elimine y verificar en la BD de `events-ms` (no solo UI) los
  campos nulos y la evidencia legal intacta, tal como piden los criterios 5-8 del PRD normalizado.
- La migración Prisma queda **aplicada solo en el entorno local de este agente** (Postgres nativo
  `localhost:5432/events`). Antes de desplegar a producción, correr la migración contra la BD real
  de `events-ms` en producción con verificación humana explícita (no incluida en este alcance).
