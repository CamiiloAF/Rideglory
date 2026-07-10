# Architect — eliminacion-cuenta-phase-02

_Generado: 2026-07-10T18:49:08Z_

## 0 Correcciones al §4 del PRD (código real vs. best-effort)

- El PRD dice "vehicles.service.ts — nuevo hardDeleteAllByOwner". Confirmado: `VehiclesService`
  (`vehicles-ms/src/vehicles/vehicles.service.ts`) extiende `PrismaClient` directamente (no un
  repositorio inyectado), y **`SoatService`/`TecnomecanicaService` son clases separadas** que
  también extienden `PrismaClient` cada una con su propia instancia — pero las 3 apuntan al mismo
  schema/DB, por lo que `this.soat`, `this.tecnomecanica` y `this.vehicle` están disponibles todos
  dentro de `VehiclesService`. Decisión: implementar `hardDeleteAllByOwner` **dentro de
  `VehiclesService`**, sin pasar por `SoatService`/`TecnomecanicaService`, para poder envolver los
  3 borrados en un único `this.$transaction(...)` (mismo patrón que `remove()` ya usa para borrado
  individual de un vehículo).
- El PRD asume que el paso "storage-cleanup" ya está conectado. Falso: **`StorageCleanupService`
  (`api-gateway/src/ai/storage-cleanup.service.ts`) NO está registrado en ningún módulo** (no
  aparece en `AiModule.providers` ni en ningún otro `@Module`). Solo se instancia manualmente en su
  propio spec (`new StorageCleanupService()`). Es código huérfano en DI hoy. Para reusarlo desde
  `UsersModule` hace falta registrarlo como provider+export en `AiModule` (o moverlo a un módulo
  compartido) e importar ese módulo en `UsersModule`.
- El PRD asume que la respuesta 502 de RPC ya incluye un flag `retryable: true` ("mismo patrón que
  hard-delete/:id ya usa hoy... 502 Bad Gateway con retryable: true"). Revisado
  `api-gateway/src/vehicles/vehicles.controller.ts` (`hardDelete`): el `catchError` de
  `softDeleteMaintenancesByVehicleId` sí devuelve `502 Bad Gateway`, pero **no existe ningún campo
  `retryable` en el codebase** (`grep -rn "retryable"` no da resultados). Es un patrón parcial: se
  reusa el `timeout(15_000)` + `catchError` → 502, pero sin el campo `retryable` (no se inventa acá;
  fuera de alcance de esta fase introducirlo).
- Prisma schema confirmado (`vehicles-ms/prisma/schema.prisma`): `Soat` y `Tecnomecanica` tienen
  `vehicleId String @unique` **sin `@relation`** hacia `Vehicle` — no hay FK real a nivel Prisma/DB,
  solo convención de aplicación. Esto confirma el guardrail "no `onDelete: Cascade`" porque ni
  siquiera hay una relación que cascadear; el borrado por `vehicleId IN (...)` es la única opción
  real, no solo la preferida.
- Confirmado el mecanismo de subida de imágenes: el cliente Flutter sube directo a Firebase Storage
  vía SDK (`ImageStorageService.uploadImage` → `ref.getDownloadURL()`), no hay endpoint backend de
  subida para vehículos/SOAT/RTM. La URL guardada en `Vehicle.imageUrl` / `Soat.documentUrl` /
  `Tecnomecanica.documentUrl` es la URL de descarga estándar de Firebase
  (`https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?alt=media&token=...`).
  El Admin SDK de Node **no tiene equivalente a `refFromURL`** (eso es solo del SDK cliente que usa
  Flutter) — `deleteFilesByUrls` debe parsear el segmento `/o/{encodedPath}` de la URL,
  `decodeURIComponent` y pasar ese path a `bucket.file(path).delete()`.
- `storagePaths` confirmados por convención real (Flutter): `vehicles/{name}.jpg`,
  `soat/{vehicleId}/{ts}_soat.{ext}`, `tecnomecanica/{vehicleId}/{ts}_rtm.{ext}` — coincide con el
  PRD, no requiere cambio.
- `maintenances-ms` ya tiene `softDeleteAllByVehicleId(vehicleId)` (service) +
  `softDeleteMaintenancesByVehicleId` (MessagePattern) como precedente directo — el nuevo
  `softDeleteAllByUserId` es un `updateMany({ where: { userId, isDeleted: false } })` análogo, sin
  loop.
- No existe `maintenances-ms/src/maintenances/maintenances.service.spec.ts` hoy (el PRD lo trata
  como archivo a crear/extender — es CREATE, no MODIFY).
- `UsersModule` (api-gateway) hoy solo registra `USERS_SERVICE` vía `ClientsModule`. No tiene
  `VEHICLES_SERVICE` ni `MAINTENANCES_SERVICE` — hay que añadirlos, reusando el mismo patrón
  (`Transport.TCP`, `envs.vehiclesMsPort/Host`, `TracingSerializer`) que ya existe en
  `vehicles.module.ts` y `maintenances.module.ts` de api-gateway.

## 1 Decisiones

1. **`hardDeleteAllByOwner(ownerId)` vive en `VehiclesService`** (no en servicios separados), usa
   `this.$transaction` con 3 pasos en este orden: `soat.deleteMany({ vehicleId: { in: ids } })` →
   `tecnomecanica.deleteMany({ vehicleId: { in: ids } })` → `vehicle.deleteMany({ ownerId })`. Antes
   de la transacción, un `findMany({ where: { ownerId } })` captura `imageUrl` de cada vehículo y,
   dentro de la misma query/transacción, los `documentUrl` de `soat`/`tecnomecanica` asociados
   (`findMany({ vehicleId: { in: ids } })` antes de borrar). El método retorna
   `{ deletedVehicleCount: number, imageUrls: string[] }` (URLs no nulas, deduplicadas) para que
   `api-gateway` alimente la limpieza de Storage. Sin vehículos → `ids = []`,
   `deleteMany` con `in: []` no lanza, retorna `{ deletedVehicleCount: 0, imageUrls: [] }` (cumple
   criterio 6).
2. **`softDeleteAllByUserId(userId)` vive en `MaintenancesService`**, análogo a
   `softDeleteAllByVehicleId` existente: `this.maintenance.updateMany({ where: { userId,
   isDeleted: false }, data: { isDeleted: true } })`. Es idempotente por construcción (Prisma
   `updateMany` sobre filas ya `isDeleted: true` no las vuelve a tocar, no lanza si `count === 0`).
3. **`StorageCleanupService.deleteFilesByUrls(urls: string[])`** nuevo método público: por cada URL
   no nula, deriva el path (`decodeURIComponent` del segmento entre `/o/` y `?`), hace
   `bucket.file(path).delete()` dentro de un `try/catch` **individual** (loguea `warn` y continúa —
   nunca aborta el batch; cumple criterios 4 y 5). URLs `null`/`undefined` se filtran antes de
   iterar (no cuentan como fallo). Se registra `StorageCleanupService` como provider **y export**
   de `AiModule` (saca del limbo de DI en el que está hoy); `UsersModule` importa `AiModule` para
   inyectarlo en `AccountDeletionService`.
4. **Orquestación en `AccountDeletionService.deleteAccount`** — reemplaza los dos `// TODO faseN`
   por el paso de dominio, manteniendo el orden global "dominio → PII usuario → Firebase Auth":
   ```
   1. findUserByEmail (ya existe)
   2. vehiclesService.send('hardDeleteAllByOwner', { ownerId: user.id })  → { imageUrls }
   3. storageCleanupService.deleteFilesByUrls(imageUrls)   // best-effort, no lanza
   4. maintenancesService.send('softDeleteMaintenancesByUserId', { userId: user.id })
   5. usersService.send('hardDeleteUser', { id: user.id })  (ya existe, ahora paso 5)
   6. firebaseAuthService.deleteUser(uid)  (ya existe, siempre último)
   ```
   Los pasos 2 y 4 usan `timeout(15_000)` + `catchError` → `RpcException` `502 Bad Gateway` (mismo
   patrón que `hardDelete` de `vehicles.controller.ts`, sin inventar el campo `retryable`
   inexistente). El paso 3 (Storage) **nunca** lanza hacia arriba: cualquier error se loguea dentro
   de `deleteFilesByUrls` (ya decidido en el punto 3) y el batch entero de Storage se envuelve
   además en un `try/catch` externo en `AccountDeletionService` como cinturón y tirantes, para que
   un fallo inesperado del SDK de Storage (p. ej. credenciales) tampoco aborte los pasos 4-6.
5. **No se toca `schema.prisma`** — no hay migración (confirmado: no hay relación real a
   cascadear).
6. **No se agrega DTO nuevo en `rideglory-contracts`.** El payload de `hardDeleteAllByOwner` es un
   `string` (`ownerId`) y la respuesta es un objeto plano `{ deletedVehicleCount, imageUrls }` —
   no hay validación de entrada compleja que justifique el costo de rebuild+reinstall en cada MS
   consumidor. Mismo criterio para `softDeleteMaintenancesByUserId` (`userId: string`).
7. **Flags de la fase:**
   - `uiChanges`: false — no hay cambios de UI/UX; el copy de confirmación ya existe desde fase 1.
   - `backendChanges`: true — todo el trabajo de código vive en `rideglory-api`.
   - `frontendChanges`: false — cero cambios de código Flutter; solo `docs/features/*.md`.
   - `dbChanges`: false — no hay migración de Prisma (ni falta, dado que no hay relación real).
   - `needsDesign`: false — no hay pantallas nuevas ni copy nuevo.

## 2 Change map

| file | action | reason | risk |
|---|---|---|---|
| `vehicles-ms/src/vehicles/vehicles.service.ts` | modify | nuevo `hardDeleteAllByOwner(ownerId)`: captura URLs, borra Soat/Tecnomecanica/Vehicle del owner en una transacción | med |
| `vehicles-ms/src/vehicles/vehicles.controller.ts` | modify | nuevo `@MessagePattern('hardDeleteAllByOwner')` que delega al service | low |
| `vehicles-ms/src/vehicles/vehicles.service.spec.ts` | modify | tests de `hardDeleteAllByOwner`: N vehículos con SOAT/RTM, garage vacío, dedupe de URLs, transacción atómica | low |
| `maintenances-ms/src/maintenances/maintenances.service.ts` | modify | nuevo `softDeleteAllByUserId(userId)` análogo a `softDeleteAllByVehicleId` | low |
| `maintenances-ms/src/maintenances/maintenances.controller.ts` | modify | nuevo `@MessagePattern('softDeleteMaintenancesByUserId')` | low |
| `maintenances-ms/src/maintenances/maintenances.service.spec.ts` | create | no existe hoy; tests de `softDeleteAllByUserId` (M registros, 0 registros, idempotencia) | low |
| `api-gateway/src/ai/storage-cleanup.service.ts` | modify | nuevo `deleteFilesByUrls(urls: string[])`: parseo de path desde download URL + `try/catch` individual por archivo | med |
| `api-gateway/src/ai/storage-cleanup.service.spec.ts` | modify | tests de `deleteFilesByUrls`: URL válida, URL corrupta, archivo inexistente (no aborta batch), lista vacía/con nulls filtrados | low |
| `api-gateway/src/ai/ai.module.ts` | modify | registrar `StorageCleanupService` como provider **y export** (hoy no está en DI) | med |
| `api-gateway/src/users/users.module.ts` | modify | añadir registros `ClientsModule` para `VEHICLES_SERVICE` y `MAINTENANCES_SERVICE` (mismo patrón que `vehicles.module.ts`); importar `AiModule` para `StorageCleanupService` | med |
| `api-gateway/src/users/account-deletion.service.ts` | modify | reemplaza los 2 `// TODO faseN` por la orquestación de dominio (vehículos → storage → mantenimientos), inyecta 3 nuevas dependencias en el constructor | high |
| `api-gateway/src/users/account-deletion.service.spec.ts` | modify | actualizar mocks del constructor (nuevas deps) + tests: orden de los 6 pasos, garage vacío, fallo individual de Storage no aborta, fallo RPC de vehicles-ms/maintenances-ms sí aborta | med |
| `docs/features/vehicles.md` | modify | nota: borrado de cuenta elimina vehículos (hard delete) en cascada, con sus imágenes | low |
| `docs/features/soat.md` | modify | nota: borrado de cuenta elimina SOAT + documento asociado | low |
| `docs/features/tecnomecanica.md` | modify | nota: borrado de cuenta elimina RTM + documento asociado | low |
| `docs/features/maintenance.md` | modify | nota: borrado de cuenta hace soft-delete de mantenimientos por `userId` (no por vehículo) | low |

Nota: `api-gateway/src/users/users.controller.ts` y `users.controller.spec.ts` **no** requieren
cambios — el endpoint `DELETE /users/me` ya delega todo a `accountDeletionService.deleteAccount`;
esta fase solo cambia el interior de ese método.

## 3 Contratos (rideglory-api)

Nuevos `MessagePattern` (RPC internos, sin endpoints HTTP nuevos):

- `hardDeleteAllByOwner` (vehicles-ms) — payload `{ ownerId: string }` → respuesta
  `{ deletedVehicleCount: number; imageUrls: string[] }`. `imageUrls` es la unión deduplicada y
  sin nulls de `Vehicle.imageUrl`, `Soat.documentUrl`, `Tecnomecanica.documentUrl` de todos los
  vehículos del owner, capturada **antes** de borrar las filas.
- `softDeleteMaintenancesByUserId` (maintenances-ms) — payload `{ userId: string }` → respuesta
  Prisma `{ count: number }` (mismo shape que `softDeleteMaintenancesByVehicleId` ya devuelve).

No se agrega ningún DTO a `rideglory-contracts` (ver Decisión 6) — evita el gotcha de
`npm run build` + reinstalar en cada MS consumidor para esta fase.

## 4 Datos/migraciones

Ninguna. No hay `MIGRATION_PLAN.md`. Confirmado en el schema real de `vehicles-ms` que `Soat` y
`Tecnomecanica` no tienen `@relation` hacia `Vehicle` (solo `vehicleId String @unique` como
convención de aplicación) — no existe FK que cascadear ni migración de schema que redactar. El
borrado es 100% a nivel de código de servicio, en una transacción Prisma explícita.

## 5 Env

Ninguno. No hay `ENV_DELTA.md`. Todas las piezas usan configuración ya existente: `DATABASE_URL`
(vehicles-ms/maintenances-ms), puertos/hosts de `vehiclesMsPort`/`maintenancesMsPort` (ya en
`envs.ts` de api-gateway, ya usados por `vehicles.module.ts`/`maintenances.module.ts`), y las
credenciales de Firebase Admin ya inicializadas para `storage-cleanup.service.ts` (cron existente)
y `storage.service.ts`.

## 6 Riesgos

- **`StorageCleanupService` pasa de huérfano-en-DI a inyectado en un flujo crítico (borrado de
  cuenta).** Si el registro en `AiModule` (provider+export) o el import en `UsersModule` queda mal
  cableado, Nest fallará al boot con `Nest can't resolve dependencies` — detectable inmediato en
  `npm run start:dev` de `api-gateway`, no en runtime silencioso.
- **Parseo de la download URL de Firebase.** Si una URL no sigue el formato
  `.../o/{path}?alt=media...` (p. ej. quedó guardada con la variante `storage.googleapis.com/
  {bucket}/{path}` que usa `storage.service.ts` para covers, o quedó corrupta a mano), el parser
  debe fallar de forma controlada (try/catch individual) y no lanzar — cubierto por Decisión 3, pero
  Backend debe testear ambos formatos de URL si aparecen en datos reales (grep rápido en Firestore/
  Postgres antes de asumir un único formato).
- **`AccountDeletionService` crece de 2 a 5 dependencias inyectadas** (`usersService`,
  `firebaseAuthService`, + `vehiclesService`, `maintenancesService`, `storageCleanupService`) — el
  spec existente mockea el constructor posicionalmente; hay que actualizar **todas** las
  instanciaciones en el spec, no solo agregar los nuevos mocks al final si el orden de parámetros
  cambia.
- **Orden dentro de la transacción de `vehicles-ms`:** el guardrail exige Soat → Tecnomecanica →
  Vehicle en una única transacción. Si `vehicle.deleteMany` corre primero y algo falla en el borrado
  de `Soat`/`Tecnomecanica`, Prisma revierte todo por ser una transacción — correcto — pero si se
  implementa como 3 llamadas sueltas (sin `$transaction`) se rompe la atomicidad exigida por el
  guardrail sin que ningún test lo detecte a simple vista (los tests de "camino feliz" pasan igual).
- **`api-gateway/src/vehicles/vehicles.controller.ts` (`hardDelete` de UN vehículo) no cambia en
  esta fase** — coexiste con el nuevo `hardDeleteAllByOwner`. Riesgo bajo de confusión de nombres
  (`hardDeleteVehicle` singular vs `hardDeleteAllByOwner` plural) pero no hay colisión de código.

## 7 Orden de implementación

1. `vehicles-ms`: `hardDeleteAllByOwner` (service + controller + spec).
2. `maintenances-ms`: `softDeleteAllByUserId` (service + controller + spec nuevo).
3. `api-gateway`: `StorageCleanupService.deleteFilesByUrls` + spec; registrar provider/export en
   `AiModule`.
4. `api-gateway`: `UsersModule` — añadir `ClientsModule` para `VEHICLES_SERVICE`/
   `MAINTENANCES_SERVICE` + importar `AiModule`.
5. `api-gateway`: `AccountDeletionService` — orquestación completa (pasos 2-4 nuevos) + actualizar
   spec existente (nuevas deps + nuevos casos de orden/fallo).
6. Flutter (paralelo, sin dependencia de 1-5): actualizar `docs/features/vehicles.md`,
   `soat.md`, `tecnomecanica.md`, `maintenance.md`.
7. QA manual dirigido: verificar en BD (no solo por HTTP 200) que `Vehicle`/`Soat`/`Tecnomecanica`
   desaparecen y `Maintenance.isDeleted = true`, y en consola de Firebase Storage que los objetos
   ya no existen — usando cuentas QA (`qa1@gmail.com`/`qa2@gmail.com`), nunca usuarios reales de
   producción.

## 8 Superficie de regresión

- `DELETE /users/me` (fase 1) — su único caller conocido es la pantalla de confirmación de
  eliminación de cuenta ya entregada; el contrato HTTP (endpoint, status codes, body) no cambia,
  solo lo que pasa internamente. Riesgo: que el paso nuevo tarde más y el timeout del lado cliente
  (Flutter) se dispare — verificar el timeout configurado en `AppDio` para esa llamada específica
  si existe uno custom.
- Endpoint existente `DELETE /vehicles/hard-delete/:id` (borrado de un solo vehículo) — no se toca,
  pero comparte tablas (`Vehicle`, `Soat`, `Tecnomecanica`, `Maintenance`) con el nuevo flujo de
  borrado por owner; cualquier test de integración que corra ambos flujos contra la misma BD de test
  en paralelo podría interferir si no aísla por `ownerId`.
- `AiModule` — pasa de no exportar nada a exportar `StorageCleanupService`; cualquier otro consumidor
  futuro de `AiModule` ahora ve ese provider en su scope. Sin impacto funcional actual (nadie más lo
  usa), pero ampliar el export surface del módulo es un cambio de forma, no solo de contenido.
- Suite Flutter (`test/features/vehicles/`, `soat/`, `tecnomecanica/`, `maintenance/`) — debe seguir
  en verde sin tocar código de producción Flutter; solo se tocan `.md`.

## 9 Fuera de alcance

- `onDelete: Cascade` en Prisma (decisión explícita del guardrail, y confirmado que no hay relación
  real que cascadear).
- Anonimización de `EventRegistration` / bloqueo por organizador con eventos activos (fase 3).
- Manejo de fallos parciales/reintentos/idempotencia del endpoint completo de 5(→6) pasos (fase 4);
  esta fase solo garantiza idempotencia interna de su propio paso.
- Migrar la convención de `storagePath` a un esquema por `ownerId`.
- Cualquier cambio de UI/UX/copy en Flutter.
- Añadir el campo `retryable` a las respuestas de error RPC (no existe hoy en el codebase; no se
  inventa en esta fase aunque el PRD lo mencione como si ya existiera).
