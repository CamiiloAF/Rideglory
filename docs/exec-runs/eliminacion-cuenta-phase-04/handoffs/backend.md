# Backend → (Frontend/QA) — eliminacion-cuenta-phase-04

_Generado: 2026-07-11T17:35:33Z_
Repo: `/Users/cami/Developer/Personal/rideglory-api` (submódulos: `api-gateway`, `users-ms`,
`vehicles-ms`, `maintenances-ms`, `events-ms`). Working tree queda SUCIO a propósito — el humano
commitea en cada submódulo.

## Baseline

Antes de tocar nada se corrió la suite completa de los 5 submódulos afectados:

- `api-gateway`: `src/users/account-deletion.service.spec.ts` + `src/auth/firebase-auth.service.spec.ts`
  → 13 passed, 13 total. Verde.
- `users-ms`: `src/users/users.service.spec.ts` → 4 passed, 4 total. Verde.
- `vehicles-ms`: `src/vehicles/vehicles.service.spec.ts` → 23 passed, 23 total. Verde.
- `maintenances-ms`: `src/maintenances/maintenances.service.spec.ts` → 3 passed, 3 total. Verde.
- `events-ms`: `src/registrations/registrations.service.spec.ts` → 2 passed, 2 total. Verde.

Baseline verde en los 5 submódulos → se procedió con los cambios.

## Archivos cambiados

**`api-gateway`**
- `src/users/account-deletion.service.ts` — nuevo helper `isNotFoundRpcError(error)` (duck-typing:
  soporta tanto el objeto plano `{status, message}` que cruza el `ClientProxy` real como una
  instancia de `RpcException` local vía `.getError()`, verificado contra el patrón ya usado en
  `rpc-custom-exception.filter.ts` y `vehicles.controller.ts`). `deleteAccount()` ahora envuelve el
  `findUserByEmail` inicial en try/catch: si el error es "no encontrado" → `return` (éxito
  idempotente, el controller ya responde `204` vía `@HttpCode(HttpStatus.NO_CONTENT)`); cualquier
  otro error se relanza sin modificar.
- `src/users/account-deletion.service.spec.ts` — reescrito el test que antes esperaba que el 404
  de `findUserByEmail` se propagara (ahora se llama
  "propagates a non-404 error..." y usa `502` en su lugar). Se agregaron 4 tests nuevos: retry con
  error 404 como objeto plano, retry con 404 como `RpcException` real, carrera concurrente (dos
  `deleteAccount()` en vuelo con happy path completo, ambas resuelven), y carrera donde la segunda
  llamada llega después de que la primera ya completó todo (encuentra 404 en `findUserByEmail` y
  resuelve idempotente sin invocar Firebase de nuevo).
- `src/auth/firebase-auth.service.ts` — `deleteUser(uid)` agrega catch específico para
  `error.code === 'auth/user-not-found'` → no-op idempotente (log + return); cualquier otro código
  se relanza igual que antes.
- `src/auth/firebase-auth.service.spec.ts` — el mock de error se corrigió a la forma real del
  Admin SDK (`Object.assign(new Error(...), {code: '...'})` en vez de un mensaje de texto plano) y
  se agregó el caso no-op (`auth/user-not-found` → resuelve `undefined`); el test de "rethrow" ahora
  usa un código no relacionado (`auth/insufficient-permission`) para no solaparse con el nuevo caso.

**`users-ms`**
- `src/users/users.service.ts` — `hardDelete(id)` ya NO llama a `findOne(id)` como precondición
  (eso hacía inalcanzable el catch de `P2025` que pedía el PRD original). Ahora llama
  `this.user.delete({ where: { id } })` directo, envuelto en try/catch de
  `Prisma.PrismaClientKnownRequestError` código `P2025` → no-op idempotente (`log` + `return null`,
  no relanza); cualquier otro error se relanza.
- `src/users/users.service.spec.ts` — el mock de `../generated/prisma` ahora exporta también
  `Prisma.PrismaClientKnownRequestError` (clase mock con `.code`). El test obsoleto `'throws
  RpcException 404 when the user does not exist, without calling delete'` se reemplazó por dos
  tests: uno que confirma el no-op idempotente ante `P2025` (sin llamar `findFirst`) y otro que
  confirma que errores no-`P2025` se relanzan. La regresión de `remove()` (soft-delete) no se tocó.

**`vehicles-ms`**
- `src/vehicles/vehicles.service.spec.ts` — un test de regresión nuevo dentro de
  `describe('hardDeleteAllByOwner')` que prueba que la función ya es idempotente (segunda llamada
  con garage vacío → `{deletedVehicleCount: 0, imageUrls: []}`, sin abrir una segunda transacción).
  Código de producción **sin tocar** (ya correcto: `findMany` + early-return).

**`maintenances-ms`**
- No se tocó ningún archivo. El test de regresión de idempotencia de `softDeleteAllByUserId` ya
  existía (`'is idempotent — running it twice yields count:0 on the second run'`), cumple el
  requisito del change map sin necesidad de cambios.

**`events-ms`**
- `src/registrations/registrations.service.spec.ts` — se agregó `mockUpdateMany` al mock de
  `eventRegistration` y un nuevo `describe('RegistrationsService.anonymizeByUserId — regression...')`
  con un test que prueba que `anonymizeByUserId` ya es idempotente vía `updateMany` (segunda
  llamada → `count: 0`, sin error). Código de producción **sin tocar**.

## Pruebas nuevas

| Archivo | Tests nuevos/reescritos |
|---|---|
| `api-gateway/src/users/account-deletion.service.spec.ts` | 1 reescrito (404→502 no-idempotente) + 4 nuevos (retry objeto plano, retry RpcException, carrera concurrente happy-path, carrera con 2ª llamada tras completar) |
| `api-gateway/src/auth/firebase-auth.service.spec.ts` | 1 reescrito (mock con `.code` real) + 1 nuevo (no-op `auth/user-not-found`) |
| `users-ms/src/users/users.service.spec.ts` | 1 reescrito (no-op P2025) + 1 nuevo (rethrow no-P2025) |
| `vehicles-ms/src/vehicles/vehicles.service.spec.ts` | 1 nuevo (regresión idempotencia, sin tocar producción) |
| `maintenances-ms/src/maintenances/maintenances.service.spec.ts` | 0 (ya existía) |
| `events-ms/src/registrations/registrations.service.spec.ts` | 1 nuevo (regresión idempotencia, sin tocar producción) |

## Resultado final

Suite completa por submódulo tras los cambios:

- `api-gateway`: `account-deletion.service.spec.ts` + `firebase-auth.service.spec.ts` → **18
  passed, 18 total**. Verde.
  - `npx jest` completo (17 suites): 148 passed / 8 failed — los 8 fallos son **preexistentes**
    (`PlacesService`, tests que dependen de `MAPBOX`/`GOOGLE` tokens no configurados en este
    entorno local; confirmado corriendo el mismo comando tras `git stash` sobre el baseline: mismos
    8 fallos, mismo archivo `places.service.iter3.spec.ts`, sin relación con esta fase). No
    tocados.
- `users-ms`: `npx jest` completo → **7 passed, 7 total**. Verde.
- `vehicles-ms`: `npx jest` completo → **51 passed, 51 total**. Verde.
- `maintenances-ms`: `npx jest` completo → **3 passed, 3 total**. Verde.
- `events-ms`: `npx jest` completo → **56 passed, 56 total**. Verde.

## Verificación manual

- **AC2 (desconexión forzada durante `DELETE /users/me`)**: no se construyó infraestructura nueva
  de test de integración con socket real (fuera de alcance según el handoff del Architect — "no
  agregar AbortController/req.on('close')"). Verificado por **lectura de código**: `deleteAccount()`
  es una cadena de `await`s puramente en el servidor (Node/Express/Nest), sin ningún listener sobre
  el request/response del cliente (`req.on('close')`, `AbortController`, etc.) que pudiera abortar
  la ejecución si el socket del cliente se cierra. Los 8 pasos de la orquestación se ejecutan hasta
  completarse (o fallar por su propia lógica) independientemente del estado de la conexión HTTP
  entrante — esto es el comportamiento por defecto de Express/Nest. **Queda documentado como
  verificación de código, no como test de integración con socket real** (no había infraestructura
  para simularlo sin overreach de scope).
- **AC5 (carrera concurrente, dos `deleteAccount()` en vuelo)**: cubierto con dos tests nuevos en
  `account-deletion.service.spec.ts` que simulan (a) dos llamadas simultáneas con happy-path
  completo, y (b) una segunda llamada que llega después de que la primera ya completó todo el
  flujo (incluido Firebase) — en ambos casos ambas llamadas resuelven sin error, y Firebase
  `deleteUser` no se invoca doble en el caso (b).
- **AC6 (timeout Dio 60s vs. 30-45s estimado)**: fuera del alcance de este agente backend — el
  change map asigna la nota documental a `user_repository_impl.dart` (Frontend). No se tocó nada
  de Flutter desde esta corrida backend.

## Notas Frontend/QA

- El contrato de error/respuesta de `DELETE /users/me` (`204/409/401/502`) **no cambió** — un
  reintento tras eliminación completa ahora responde `204` en vez de un error no documentado.
  Frontend puede confiar en que reintentar el borrado de cuenta (p. ej. tras cerrar la app a mitad
  del flujo y reabrir) siempre converge a `204`, nunca a un 5xx inesperado.
- El único caso donde el 401 debe seguir propagándose sin cambios es cuando el token del cliente ya
  es inválido — eso lo maneja el interceptor de Firebase Auth en Flutter (fuera del scope de este
  agente backend; ver handoff de Frontend).
- QA: para probar la carrera concurrente real (no solo unit test), se necesitarían dos llamadas
  HTTP simultáneas a `DELETE /users/me` con el mismo token contra un entorno con BD real — no se
  automatizó a nivel HTTP/e2e en esta corrida, solo a nivel de unit test del servicio orquestador
  con los `ClientProxy` mockeados.
- Ningún cambio de este agente afecta variables de entorno (`ENV_DELTA.md` no aplicó ningún cambio
  backend en esta fase) ni migraciones de base de datos.
