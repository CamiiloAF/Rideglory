> Slim handoff — read this before handoffs/architect.md

# Architect → Backend — eliminacion-cuenta-phase-04

Repo: `/Users/cami/Developer/Personal/rideglory-api` (separado; no commitear desde esta corrida).

## Corrección clave vs. el PRD

El orquestador real es **`api-gateway/src/users/account-deletion.service.ts`**
(`AccountDeletionService.deleteAccount`), no `users.controller.ts`. El controller (`deleteMe`) solo
delega. El PRD no menciona este archivo — es el más importante de la fase.

## Qué tocar (exactamente esto, nada más)

1. **`api-gateway/src/users/account-deletion.service.ts`** — `deleteAccount()` hace
   `firstValueFrom(usersService.send('findUserByEmail', { email }))` como primera línea. Si el
   usuario ya fue borrado por completo en una corrida previa, esto lanza 404 y hoy se propaga como
   error no documentado (rompe el contrato `204/409/401/502`). Envolver en try/catch: si el error
   es "not found" (helper `isNotFoundRpcError`, ver abajo), hacer `return` (éxito idempotente, el
   controller ya responde 204 por `@HttpCode(HttpStatus.NO_CONTENT)`); si es cualquier otro error,
   relanzar tal cual (no enmascarar fallos reales).
   - **Verificar la forma real** del error tal como cruza el `ClientProxy` de NestJS microservices
     antes de escribir el type-guard — no asumas que es una instancia de `RpcException` local;
     usualmente llega como el objeto plano `{status, message}` pasado al constructor original en
     `users-ms`. Los `catchError` ya existentes en este mismo archivo acceden a `error?.message` —
     revisa si también exponen `status`/`statusCode` para reusar el mismo patrón duck-typing.
2. **`users-ms/src/users/users.service.ts`** — `hardDelete(id)` hoy llama primero a
   `this.findOne(id)`, que lanza `RpcException 404` **antes** de llegar a `this.user.delete()`.
   Esto significa que el fix que pedía el PRD original ("catch P2025 en el delete") nunca se
   alcanza. Fix correcto: quitar el precondition `findOne`, llamar `this.user.delete({ where: {
   id } })` directo, envuelto en try/catch de `Prisma.PrismaClientKnownRequestError` código
   `P2025` → no-op idempotente (log + return sin lanzar, no relanzar).
3. **`api-gateway/src/auth/firebase-auth.service.ts`** — `deleteUser(uid)` relanza cualquier error
   del Admin SDK tal cual. Agregar catch específico: si `error.code === 'auth/user-not-found'` →
   no-op idempotente; cualquier otro código se relanza igual que hoy. El spec actual simula el
   error con `new Error('auth/user-not-found')` (mensaje, no `.code`) — verificar la forma real
   que expone `firebase-admin` (`FirebaseAuthError` con `.code`) y ajustar el mock del spec.
4. **Tests a actualizar/crear:**
   - `account-deletion.service.spec.ts`: test de retry-tras-éxito-completo (404 en paso 1 →
     resuelve sin lanzar) + test de carrera concurrente (dos `deleteAccount()` en vuelo).
   - `users.service.spec.ts`: el test existente `'throws RpcException 404 when the user does not
     exist, without calling delete'` (línea ~61) queda **obsoleto** — reescribirlo para afirmar
     no-op idempotente en su lugar. No borrar la regresión de `remove()` (soft-delete) que está
     justo debajo, esa se queda igual.
   - `firebase-auth.service.spec.ts`: ajustar el mock de error a la forma real (`.code`) y agregar
     caso no-op.
   - Un test de regresión (no cambio de código) en `vehicles-ms`, `maintenances-ms`, `events-ms`
     que demuestre que `hardDeleteAllByOwner`, `softDeleteAllByUserId`, `anonymizeByUserId` ya son
     idempotentes (doble llamada → mismo resultado, sin error). **No tocar su código de
     producción** — ya son correctos (`findMany`-condicional / `updateMany`).

## Qué NO tocar

- No reordenar los 8 pasos de `deleteAccount()`.
- No tocar `hardDeleteAllByOwner`, `softDeleteAllByUserId`, `anonymizeByUserId` (ya idempotentes).
- No agregar `AbortController`/`req.on('close')` — confirmado que no existe y no hace falta;
  Express/Nest ya completa el handler aunque el socket del cliente se cierre.
- No cambiar el contrato de respuesta de `DELETE /users/me` (`204/409/401/502`).
- No agregar tabla de estado de borrado ni polling.
- Guard de idempotencia debe ser específico al código "no encontrado" — nunca un catch genérico
  que oculte otras excepciones reales.

## Prueba de desconexión forzada (AC2)

Confirmar (test de integración o documentado como manual si no hay infraestructura) que si el
socket HTTP del cliente se cierra a mitad de `deleteAccount()`, los 8 pasos se completan igual en
BD. Esto ya debería ser cierto por default de Node/Express — el objetivo es **verificarlo**, no
construir nada nuevo.

> Full detail: handoffs/architect.md
