# Backend → (eliminacion-cuenta-phase-01)

Repo: `/Users/cami/Developer/Personal/rideglory-api` (submódulos `api-gateway`, `users-ms`).
Working tree queda SUCIO a propósito — no se hizo commit.

## Baseline

- `users-ms`: `npx jest` → `No tests found` (0 spec files existían en el módulo antes de esta
  fase). No es una regresión: no había suite que correr.
- `api-gateway`: `npx jest --silent` → **13 suites passed, 1 failed** (`places.service.iter3.spec.ts`,
  8 tests) antes de tocar nada. Falla pre-existente y no relacionada (feature `places`, no tocado
  en esta fase). Confirmado con `git stash`-less inspección: el mismo archivo falla igual después
  de mis cambios, sin variación en el conteo de fallos.

Con baseline roja solo en un módulo no relacionado a la fase, se procedió (no aplica el criterio de
"status: fail" porque el fallo es preexistente y ajeno al alcance del backend de esta fase).

## Archivos cambiados

### `users-ms`

- `src/users/users.service.ts` (modify) — nuevo método `hardDelete(id)`: `findOne(id)` (404 si no
  existe) + `this.user.delete({ where: { id } })`. `remove()` (soft-delete) intacto.
- `src/users/users.controller.ts` (modify) — nuevo `@MessagePattern('hardDeleteUser') hardDelete(@Payload('id', ParseUUIDPipe) id: string)`. `@MessagePattern('removeUser')` intacto, sin tocar.
- `src/users/users.service.spec.ts` (create)
- `src/users/users.controller.spec.ts` (create)

### `api-gateway`

- `src/auth/firebase-auth.service.ts` (modify) — nuevo método `deleteUser(uid)` vía
  `getAuth(this.firebaseApp).deleteUser(uid)`, reutiliza `this.firebaseApp` ya inicializado.
- `src/auth/firebase-auth.service.spec.ts` (create)
- `src/users/account-deletion.service.ts` (create) — orquestador `deleteAccount(uid, email)`:
  1. `usersService.send('findUserByEmail', { email })` (propaga `RpcException` 404 tal cual)
  2. `// TODO fase 2` (no-op)
  3. `// TODO fase 3` (no-op)
  4. `usersService.send('hardDeleteUser', { id: user.id })`
  5. `firebaseAuthService.deleteUser(uid)` — siempre último; sin try/catch que trague errores del
     paso 4, sin `Promise.allSettled`.
- `src/users/account-deletion.service.spec.ts` (create) — verifica orden exacto de los 3 pasos con
  efecto observable (`findUserByEmail` → `hardDeleteUser` → `firebaseDeleteUser`), y dos casos de
  corte de cadena: 404 en paso 1 nunca llega a pasos 4/5; error en paso 4 nunca invoca paso 5.
- `src/users/users.controller.ts` (modify) — nuevo `DELETE /users/me` (`@HttpCode(204)`), resuelve
  `uid`/`email` únicamente de `request.user` (nunca de params/body), delega a
  `AccountDeletionService.deleteAccount`.
- `src/users/users.controller.spec.ts` (create)
- `src/users/users.module.ts` (modify) — registra `AccountDeletionService` en `providers`, agrega
  `imports: [AuthModule, ...]` para poder inyectar `FirebaseAuthService` (mismo patrón que
  `ai.module.ts`/`tracking.module.ts`, que ya importan `AuthModule` localmente pese a que también
  está en `AppModule`; Nest lo deduplica).

### Nota de higiene no listada en el change map (necesaria para que compile/testee)

`users.controller.ts`, `account-deletion.service.ts` y `users.module.ts` (api-gateway) usaban/usan
imports absolutos tipo `from 'config'` / `from 'auth/decorators/public.decorator'` que solo
resuelven vía el `paths` de `tsconfig.json` (`"*": ["./src/*"]`), no soportado por `ts-jest` sin
`moduleNameMapper`. Cambié esos imports a relativos (`'../config/services'`, `'../auth/...'`),
seguiendo el patrón que ya usa `maintenances.controller.ts` en el mismo repo. Cero cambio de
comportamiento; solo así las specs nuevas cargan. `users.module.ts` conserva el import del barrel
`'../config'` (necesita `envs` para `ClientsModule.registerAsync`), igual que antes — no tiene spec
directo así que no requería el mismo ajuste.

## Pruebas nuevas

- `users-ms/src/users/users.service.spec.ts`: `hardDelete` (éxito → `prisma.user.delete`, 404 si no
  existe) + regresión explícita de `remove()` (sigue siendo `prisma.user.update({ isDeleted: true
  })`, nunca llama `delete`).
- `users-ms/src/users/users.controller.spec.ts`: `hardDeleteUser` delega a `hardDelete` (no a
  `remove`) + regresión de `removeUser` delega a `remove` (no a `hardDelete`).
- `api-gateway/src/auth/firebase-auth.service.spec.ts`: `deleteUser` llama Admin SDK con el `uid`;
  reenvía el error original si el SDK falla.
- `api-gateway/src/users/account-deletion.service.spec.ts`: orden exacto de los 3 pasos observables;
  404 en paso 1 corta la cadena; error en paso 4 corta la cadena antes del paso 5 (criterio de
  aceptación más importante de la fase, AC7).
- `api-gateway/src/users/users.controller.spec.ts`: `DELETE /users/me` → 204 (retorno `undefined`);
  `uid`/`email` siempre leídos de `request.user`, nunca de params/body (test explícito con params y
  body "envenenados"); `UnauthorizedException` si falta `uid`/`email` en el token; propagación de
  errores del orquestador.

## Resultado final

```
users-ms:      npx jest --silent → 2 suites passed, 6 tests passed
api-gateway:   npx jest --silent → 16 suites passed / 1 failed (pre-existente, no relacionado),
               129 passed / 8 failed (mismos 8 de baseline, places.service.iter3.spec.ts)
```

`npx tsc --noEmit` limpio en ambos módulos (`api-gateway`, `users-ms`).

## Verificación manual

No se levantó el stack completo (docker-compose) en esta corrida — cambios cubiertos por unit
tests con mocks de `ClientProxy`/Prisma/Firebase Admin, sin DB real ni credenciales de Firebase
disponibles en este entorno. Recomendado antes de mergear: `DELETE /api/users/me` con un usuario
QA real contra el stack local, confirmando:
- 204 sin body.
- Row del usuario desaparece de la tabla `User` en `users-ms` (hard delete real, no
  `isDeleted: true`).
- El usuario deja de poder autenticar (Firebase Auth lo borró).
- Reintento del mismo `DELETE /users/me` con el mismo token ya no es válido (token de un usuario
  borrado en Firebase debe fallar en `verifyIdToken` en la siguiente llamada).

## Notas Frontend/QA

- Contrato: `DELETE /api/users/me`, sin body, `Authorization: Bearer <token>` (igual que el resto
  de endpoints). Éxito → `204 No Content`. Errores: mismo mapeo de `RpcException` 404 que ya usa
  `GET /users/me` si el usuario no existe en `users-ms` (caso borde, no debería pasar en flujo
  normal); cualquier error de Firebase Admin en el borrado se propaga como error 5xx genérico (no
  hay mapeo específico nuevo — Frontend debe tratarlo como error genérico con retry manual, tal
  como especifica el handoff de Architect).
- No hay endpoint de "deshacer" ni confirmación por email en esta fase — es irreversible desde que
  el usuario confirma en la UI. La página de confirmación en Frontend es la única barrera.
- Los pasos 2 y 3 (limpieza de fases futuras: imágenes, dependencias en otros MS, etc.) son no-ops
  explícitos (`// TODO fase 2` / `// TODO fase 3`) en `account-deletion.service.ts` — el hard delete
  del usuario en `users-ms` y el borrado en Firebase Auth SÍ ocurren en esta fase; el resto de
  limpieza queda pendiente para fases posteriores del PRD.
