# Architect → Backend — eliminacion-cuenta-phase-03

Contrato completo: `handoffs/architect.md`. Este archivo es el resumen accionable para
`rideglory-api`.

## Qué construir

1. **Contrato**: `AnonymizeRegistrationsPayloadDto { userId: string (@IsUUID) }` en
   `rideglory-contracts/src/events/dto/anonymize-registrations-payload.dto.ts` + export en
   `dto/index.ts`. Luego `npm run build` en `rideglory-contracts` y reinstalar en
   `events-ms`/`api-gateway` (gotcha conocido — ver memoria `project_contracts_rebuild_gotcha`).

2. **Migración Prisma** (`events-ms/prisma/schema.prisma`): relajar a nullable estas 8 columnas
   de `EventRegistration`: `identificationNumber`, `birthDate`, `phone`, `email`,
   `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone`. NO tocar
   `bloodType`. Ver `analysis/MIGRATION_PLAN.md` para el detalle paso a paso. Correr y
   verificar localmente; no desplegar.

3. **`events-ms/src/registrations/registrations.service.ts`**: nuevo método
   `anonymizeByUserId(userId: string): Promise<{ count: number }>` usando
   `this.eventRegistration.updateMany({ where: { userId }, data: {...} })`. Constante
   `const ANONYMIZED_FULL_NAME = 'Usuario eliminado';` — **no reusar ni tocar** `FULL_MASK`
   (`'••••'`, línea ~29) ni la función de masking condicional por `shareMedicalInfo` (línea
   ~482 en adelante) — son mecanismos distintos e independientes.

   Campos a escribir: `fullName: ANONYMIZED_FULL_NAME`, `identificationNumber: null`,
   `birthDate: null`, `phone: null`, `email: null`, `residenceCity: null`, `eps: null`,
   `emergencyContactName: null`, `emergencyContactPhone: null`, `shareMedicalInfo: false`,
   `allowOrganizerContact: false`.

   Campos que **NO** se tocan: `bloodType`, `medicalInsurance`, `riskAcceptedAt`,
   `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion`, `vehicleId`,
   `status`, `eventId`, `userId`, `id`.

4. **`events-ms/src/registrations/registrations.controller.ts`**: nuevo
   `@MessagePattern('anonymizeRegistrationsByUserId')` que recibe
   `AnonymizeRegistrationsPayloadDto` y llama a `anonymizeByUserId(payload.userId)`.

5. **`api-gateway/src/users/users.module.ts`**: registrar `EVENTS_SERVICE` en
   `ClientsModule.registerAsync` — copiar exactamente el bloque de `events.module.ts`
   (`envs.eventsMsPort`, `envs.eventsMsHost`, ya existen en `config/envs.ts`, sin delta de
   `.env`). Verificado en código que `EVENTS_SERVICE` **no** está registrado ahí todavía — no
   hay riesgo de duplicado.

6. **`api-gateway/src/users/account-deletion.service.ts`**: inyectar `EVENTS_SERVICE` en el
   constructor. Reescribir `deleteAccount(uid, email)` con este orden exacto (no alterable sin
   coordinación con Architect):
   1. Resolver `user.id` (ya existe, primer paso actual).
   2. **Nuevo — precondición**: `findEventsByOwnerId` en `EVENTS_SERVICE` con `{ ownerId:
      user.id }` (mismo pattern que ya usa `api-gateway/src/events/events.controller.ts:57`).
      Filtrar eventos con `state IN (DRAFT, SCHEDULED, IN_PROGRESS)`. Si hay al menos uno →
      `throw new RpcException({ status: HttpStatus.CONFLICT, error: 'ACTIVE_EVENTS_AS_ORGANIZER',
      message: '<texto ES accionable>', activeEvents: [...] })` (mapear al shape HTTP 409 en el
      filtro/interceptor de excepciones existente del gateway — revisar cómo se traduce hoy
      `RpcException.status` a HTTP status en este controlador antes de asumir el mapeo).
      **Ningún paso posterior se ejecuta si esto lanza.**
   3. Hard-delete vehículos (`hardDeleteAllByOwner`, ya existente, sin cambios).
   4. Limpieza Storage (best-effort, ya existente, sin cambios).
   5. Soft-delete mantenimientos (ya existente, sin cambios).
   6. **Nuevo**: `EVENTS_SERVICE.send('anonymizeRegistrationsByUserId', { userId: user.id })`
      con el mismo patrón de `timeout(15_000)` + `catchError` que los pasos existentes.
   7. Hard-delete usuario en `users-ms` (ya existente, sin cambios).
   8. Eliminar usuario en Firebase Auth (ya existente, siempre último, sin cambios).

   Actualizar el docblock del método (actualmente dice "6 pasos fijos") para reflejar el nuevo
   conteo y orden.

7. **Body 409 exacto** (contrato con Flutter — no negociable sin avisar a Frontend):
   ```json
   { "error": "ACTIVE_EVENTS_AS_ORGANIZER", "message": "<texto ES>", "activeEvents": [{"id": "...", "name": "...", "state": "..."}] }
   ```
   El campo `message` es obligatorio y debe ser texto humano en español — el cliente Flutter
   extrae `message` primero (ver `rest_client_functions.dart`), así que si falta, se degrada a
   mostrar el literal `"ACTIVE_EVENTS_AS_ORGANIZER"` al usuario.

## Tests a escribir

- `registrations.service.anonymization.spec.ts`: campos anonimizados correctos, campos
  preservados intactos (evidencia legal), idempotencia (dos llamadas seguidas → mismo `count`
  y mismo estado final tras la segunda), no afecta filas de otro `userId`, no afecta `Event`.
- Spec de `account-deletion.service.ts`: 409 con eventos activos no ejecuta ningún paso de
  borrado (mockear los clients y verificar `send` no invocado); flujo exitoso invoca los 8
  pasos en orden; `activeEvents` no vacío en el body 409.

## Guardrails específicos (no violar)

- No reusar `FULL_MASK` ni tocar la función de masking condicional.
- No filtrar por `Event.ownerId` al anonimizar — filtro es por `EventRegistration.userId`.
- No registrar `EVENTS_SERVICE` dos veces si por alguna razón ya existiera (verificar antes).
- No alterar el orden de orquestación fijado arriba.
- Migración: correr y verificar localmente, no desplegar sin verificación humana.
