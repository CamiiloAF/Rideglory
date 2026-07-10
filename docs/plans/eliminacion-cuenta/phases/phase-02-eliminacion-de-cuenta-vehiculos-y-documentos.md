# Fase 2 — Eliminación de cuenta — vehículos y documentos

_Generado: 2026-07-07T16:00:08Z_

## Objetivo

Como rider que elimina su cuenta (fase 1 ya entregó la orquestación de identidad de
`DELETE /users/me`), al confirmar la eliminación también desaparecen de inmediato mis motos, sus
fotos, mi historial de mantenimientos y mis documentos SOAT/RTM (con sus imágenes), sin exponer
ningún cambio visible nuevo sobre el flujo de fase 1: la pantalla y el copy de confirmación ya los
mencionan desde esa fase, esta fase solo hace que la promesa sea cierta en el backend.

## Alcance (entra / no entra)

**Entra:**
- Nuevo método interno `vehiclesService.hardDeleteAllByOwner(ownerId)` en `vehicles-ms`, invocado
  desde el paso de orquestación de `DELETE /users/me` en `api-gateway` (extiende la secuencia ya
  fijada en fase 1: dominio → PII de usuario → Firebase Auth).
- Borrado explícito de `Soat` y `Tecnomecanica` por `vehicleId IN (...)` antes/junto al
  `deleteMany` de `Vehicle` del owner (no existe `onDelete: Cascade` hoy — hallazgo del Architect).
- Nuevo `MessagePattern` `softDeleteMaintenancesByUserId` en `maintenances-ms` (por `userId`
  directo, reemplaza la necesidad de loopear `softDeleteMaintenancesByVehicleId` por cada
  vehículo), invocado una sola vez desde `api-gateway` con el `userId` del owner.
- Borrado en lote de las imágenes de Firebase Storage asociadas a los vehículos, SOAT y RTM del
  usuario: `imageUrl` de `Vehicle`, `documentUrl` de `Soat` y de `Tecnomecanica`. La estrategia es
  **derivar el path del objeto desde cada download URL guardada** (no introducir una convención de
  carpeta por `ownerId` nueva: hoy las subidas usan `vehicles/{nombre}.jpg`,
  `soat/{vehicleId}/...`, `tecnomecanica/{vehicleId}/...` sin `ownerId` en el path, y migrar esa
  convención de subida obligaría a tocar 3 puntos de la app Flutter y no resolvería los objetos ya
  existentes de todas formas). Se reusa el patrón de `storage-cleanup.service.ts`
  (`bucket.file(...).delete()`), adaptado para recibir una lista de URLs en vez de un `prefix`.
- Manejo explícito de "documento sin imagen" (`imageUrl`/`documentUrl` nulo — SOAT/RTM capturados
  sin foto) y de fallos individuales de borrado de Storage (objeto ya no existe, URL corrupta): no
  deben abortar la orquestación completa del borrado de cuenta.
- Actualizar el contrato de orquestación de `DELETE /users/me` (documentado en fase 1) para incluir
  este paso en el orden ya fijado.
- Actualizar `docs/features/vehicles.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`
  y `docs/features/maintenance.md` si esta fase cambia comportamiento documentado (agregar mención
  de que el borrado de cuenta limpia estos datos en cascada).

**No entra:**
- Ningún cambio de UI/UX en Flutter: la pantalla de confirmación y su copy ya existen desde fase 1
  y ya mencionan "tus motos, fotos, mantenimientos y documentos" — esta fase es 100% backend.
- Anonimización de `EventRegistration` ni bloqueo por organizador con eventos activos (fase 3).
- Manejo de fallos parciales/reintentos/idempotencia de la orquestación multi-paso completa (fase
  4); esta fase solo debe garantizar que su propio paso (`hardDeleteAllByOwner` +
  `softDeleteMaintenancesByUserId` + limpieza de Storage) sea internamente atómico/idempotente por
  sí mismo, no el endpoint completo de 5 pasos.
- Migrar la convención de subida de imágenes existente (`storagePath`) a un esquema por `ownerId`;
  fuera de alcance salvo que el equipo decida invertir en ello como mejora futura independiente.
- Endpoint `DELETE /users/me`, validación de token, y los pasos de PII de usuario / Firebase Auth
  (ya entregados en fase 1) — esta fase solo añade un paso a la secuencia existente.

## Qué se debe hacer (pasos concretos y ordenados)

1. **Verificar contrato de fase 1**: leer el archivo de fase 1 ya implementado (u orquestación
   actual de `UsersController.deleteMe` / equivalente en `api-gateway`) para confirmar el punto
   exacto donde se inserta el paso de dominio "vehículos" en la secuencia de 5 pasos.
2. **`vehicles-ms`**: agregar `VehiclesService.hardDeleteAllByOwner(ownerId: string)`:
   - Dentro de una transacción Prisma (`this.$transaction`):
     a. `const vehicleIds = (await tx.vehicle.findMany({ where: { ownerId }, select: { id: true, imageUrl: true } }))` —
        capturar también `imageUrl` para el paso de Storage.
     b. `await tx.soat.deleteMany({ where: { vehicleId: { in: vehicleIds.map(v => v.id) } } })`
        (capturar `documentUrl` antes de borrar, con un `findMany` previo).
     c. `await tx.tecnomecanica.deleteMany({ where: { vehicleId: { in: vehicleIds.map(v => v.id) } } })`
        (idem, capturar `documentUrl` antes).
     d. `await tx.vehicle.deleteMany({ where: { ownerId } })`.
   - Devolver `{ vehicleIds, imageUrls: [...] }` (URLs de vehículo + SOAT + RTM recolectadas) para
     que el llamador (`api-gateway`) dispare la limpieza de Storage.
   - Registrar el nuevo `@MessagePattern('hardDeleteAllByOwner')` en `VehiclesController`.
3. **`maintenances-ms`**: agregar `MaintenancesService.softDeleteAllByUserId(userId: string)`
   (mismo patrón que `softDeleteAllByVehicleId`, pero `where: { userId }`) y su
   `@MessagePattern('softDeleteMaintenancesByUserId')` en `MaintenancesController`.
4. **`api-gateway`**: en el punto de orquestación de `DELETE /users/me` fijado por fase 1, insertar
   (en el orden ya definido, antes del paso de PII de usuario):
   ```
   await firstValueFrom(
     this.maintenancesService.send('softDeleteMaintenancesByUserId', { userId }).pipe(
       timeout(15_000),
       catchError(...) // BAD_GATEWAY, mismo patrón que hard-delete/:id
     ),
   );
   const { imageUrls } = await firstValueFrom(
     this.vehiclesService.send('hardDeleteAllByOwner', { ownerId: userId }).pipe(
       timeout(15_000),
       catchError(...) // BAD_GATEWAY
     ),
   );
   await this.storageCleanupService.deleteFilesByUrls(imageUrls); // no debe abortar el flujo si falla
   ```
   Nota: se llama primero a mantenimientos (por `userId`, no depende de tener los `vehicleId`s
   todavía) y luego a vehículos — evita depender del orden de retorno de `hardDeleteAllByOwner`
   para saber qué mantenimientos borrar, ya que `Maintenance.userId` es un campo directo.
5. **`api-gateway/src/ai/storage-cleanup.service.ts`**: extraer/añadir un método reusable
   `deleteFilesByUrls(urls: string[]): Promise<void>` que:
   - Ignore URLs nulas/vacías.
   - Derive el path del objeto desde cada download URL (`decodeURIComponent` del segmento entre
     `/o/` y `?alt=media` de la URL de Firebase Storage, patrón estándar de Admin SDK).
   - Llame `bucket.file(path).delete()` por cada una, con `try/catch` individual por archivo (loguear
     y continuar, nunca abortar el batch por un archivo faltante/URL corrupta — mismo espíritu
     defensivo que `ImageStorageService.deleteImage` en Flutter).
   - Este método se inyecta/reusa en el módulo de `users`/orquestación de borrado de cuenta (mover
     `StorageCleanupService` a un módulo compartido si hoy vive acoplado solo al módulo `ai`).
6. **Pruebas backend**: unit tests de `hardDeleteAllByOwner` (Prisma mock: confirma borrado de
   Soat/Tecnomecanica antes de Vehicle, confirma que devuelve las URLs correctas, confirma
   comportamiento con owner sin vehículos → no debe fallar), de
   `softDeleteAllByUserId` (maintenances-ms) y de `deleteFilesByUrls` (incluir caso de URL
   corrupta/objeto inexistente sin abortar el batch).
7. **Prueba de integración manual** (no hay usuarios reales en prod, usar usuarios QA): con
   `qa2@gmail.com` (owner), crear un vehículo con foto, SOAT con foto, RTM con foto y un
   mantenimiento; ejecutar `DELETE /users/me`; verificar en la base de datos de cada MS
   (`vehicles-ms`, `maintenances-ms`) que las filas desaparecieron, y en la consola de Firebase
   Storage que los 3 objetos de imagen fueron eliminados.
8. **Actualizar docs de feature** afectados (`docs/features/vehicles.md`, `soat.md`,
   `tecnomecanica.md`, `maintenance.md`) con la nueva nota de comportamiento: "al eliminar la
   cuenta, estos datos se borran/archivan en cascada como parte de `DELETE /users/me`".

## Archivos a crear/modificar (rutas reales, qué cambia)

**`rideglory-api` (repo separado, `/Users/cami/Developer/Personal/rideglory-api`):**
- `vehicles-ms/src/vehicles/vehicles.service.ts` — nuevo método `hardDeleteAllByOwner(ownerId)`
  (transacción: recolectar URLs, borrar Soat/Tecnomecanica por `vehicleId IN (...)`, luego
  `deleteMany` de Vehicle).
- `vehicles-ms/src/vehicles/vehicles.controller.ts` — nuevo `@MessagePattern('hardDeleteAllByOwner')`.
- `maintenances-ms/src/maintenances/maintenances.service.ts` — nuevo método
  `softDeleteAllByUserId(userId)`.
- `maintenances-ms/src/maintenances/maintenances.controller.ts` — nuevo
  `@MessagePattern('softDeleteMaintenancesByUserId')`.
- `api-gateway/src/users/users.controller.ts` (o donde fase 1 haya dejado la orquestación de
  `DELETE /users/me`) — insertar las 2 llamadas RPC nuevas + la limpieza de Storage, en el orden
  fijado por el contrato de fase 1/`03-architect-review.md`.
- `api-gateway/src/ai/storage-cleanup.service.ts` (o módulo compartido nuevo si se decide mover) —
  nuevo método `deleteFilesByUrls(urls: string[])`.
- `rideglory-contracts` (paquete compartido) — si se decide tipar el payload/respuesta de
  `hardDeleteAllByOwner` con un DTO propio (`HardDeleteAllByOwnerResultDto` con `vehicleIds` +
  `imageUrls`), agregarlo aquí y reconstruir (`npm run build` + reinstalar en cada MS afectado —
  ver gotcha de contracts en memoria del proyecto).
- Tests nuevos: `vehicles-ms/src/vehicles/vehicles.service.spec.ts`,
  `maintenances-ms/src/maintenances/maintenances.service.spec.ts`,
  `api-gateway/src/ai/storage-cleanup.service.spec.ts` (o el spec del módulo donde termine viviendo
  `deleteFilesByUrls`).

**Rideglory (Flutter, este repo) — solo documentación, sin código:**
- `docs/features/vehicles.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`,
  `docs/features/maintenance.md` — nota de comportamiento sobre borrado en cascada al eliminar
  cuenta.

## Contratos / API rideglory-api

Extiende (no reemplaza) el contrato de `DELETE /users/me` fijado en fase 1, insertando un paso más
en la orquestación síncrona interna:

| MS | Pattern | Payload | Respuesta | Notas |
|----|---------|---------|-----------|-------|
| `vehicles-ms` | `hardDeleteAllByOwner` (nuevo) | `{ ownerId: string }` | `{ vehicleIds: string[], imageUrls: string[] }` | Borra `Soat`/`Tecnomecanica` por `vehicleId IN (...)` antes del `deleteMany` de `Vehicle`; idempotente (owner sin vehículos → arrays vacíos, no error). |
| `maintenances-ms` | `softDeleteMaintenancesByUserId` (nuevo) | `{ userId: string }` | `void` | Análogo a `softDeleteMaintenancesByVehicleId` pero por `userId` directo; idempotente. |

No se crean endpoints HTTP nuevos en `api-gateway` (el `DELETE /users/me` ya existe desde fase 1);
solo se agregan 2 llamadas RPC internas + 1 llamada a Storage dentro de su orquestación existente.
Errores de estos pasos deben mapearse igual que los pasos existentes de fase 1
(`502 Bad Gateway` con `retryable: true`, mismo patrón que `hard-delete/:id` ya usa hoy con
`timeout(15_000)` + `catchError`).

## Cambios de datos / migraciones

Ninguno. No se agrega `onDelete: Cascade` al schema de Prisma en esta fase (se descarta esa opción
del Architect en favor de borrado explícito por `vehicleId IN (...)` en la capa de servicio, que es
más simple de auditar/testear paso a paso y no requiere migración). No se cambia la convención de
`storagePath` de subida de imágenes (se mantiene `vehicles/{nombre}.jpg`, `soat/{vehicleId}/...`,
`tecnomecanica/{vehicleId}/...`); el borrado en lote deriva el path desde la download URL guardada
en cada fila, sin depender de una convención de carpeta por `ownerId`.

## Criterios de aceptación (numerados, observables, testeables)

1. Al ejecutar `DELETE /users/me` para un usuario con N vehículos, cada uno con SOAT y RTM (con
   foto/documento) y M registros de mantenimiento, al finalizar la petición: `vehicles-ms` no tiene
   ninguna fila de `Vehicle`, `Soat` ni `Tecnomecanica` con ese `ownerId`/`vehicleId` asociado
   (verificado por query directa a la base de datos, no solo por la respuesta HTTP).
2. Los M registros de `Maintenance` del usuario quedan con `isDeleted: true` (soft delete,
   consistente con el comportamiento individual existente) sin necesidad de loopear por
   `vehicleId`.
3. Las imágenes de Firebase Storage referenciadas por `Vehicle.imageUrl`, `Soat.documentUrl` y
   `Tecnomecanica.documentUrl` del usuario ya no existen en el bucket tras el borrado (verificado
   en la consola de Firebase Storage o con `bucket.file(path).exists()`).
4. Un usuario con SOAT o RTM capturado sin foto (`documentUrl: null`) completa el borrado de
   cuenta sin error (el paso de limpieza de Storage ignora URLs nulas).
5. Un usuario con un vehículo cuya imagen ya no existe en Storage (borrada manualmente o URL
   corrupta) completa el borrado de cuenta sin error 500 — el fallo de un archivo individual se
   loguea y no aborta el batch ni la orquestación completa.
6. Un usuario sin ningún vehículo (garage vacío) completa el borrado de cuenta sin error
   (`hardDeleteAllByOwner` devuelve arrays vacíos, no lanza excepción).
7. `dart analyze` y `flutter test` siguen en verde (esta fase no toca código Flutter, solo docs).
8. Los tests unitarios nuevos de `vehicles-ms`, `maintenances-ms` y del servicio de limpieza de
   Storage pasan en CI del repo `rideglory-api`.

## Pruebas (unitarias/widget/integración)

- **Unitarias backend** (`rideglory-api`, Jest):
  - `vehicles.service.spec.ts`: `hardDeleteAllByOwner` borra Soat/Tecnomecanica antes que Vehicle
    (orden verificado con mocks de Prisma), devuelve `imageUrls` correctos, maneja owner sin
    vehículos.
  - `maintenances.service.spec.ts`: `softDeleteAllByUserId` marca `isDeleted: true` para todas las
    filas del `userId`, es idempotente si se llama dos veces.
  - `storage-cleanup.service.spec.ts` (o el spec del módulo final): `deleteFilesByUrls` ignora
    nulos/vacíos, continúa el batch si un archivo individual falla, deriva correctamente el path
    desde una URL de Firebase Storage real de ejemplo.
- **Integración manual** (no hay entorno de integración automatizado cross-MS en este repo hoy):
  ejecutar el flujo completo con `qa2@gmail.com` como se describe en el paso 7 de "Qué se debe
  hacer", confirmando en base de datos y en Firebase Storage (no solo por la respuesta HTTP 204).
- **Flutter**: ninguna prueba nueva (esta fase no modifica código de la app); confirmar que la
  suite existente de `test/features/vehicles/`, `test/features/soat/`, `test/features/tecnomecanica/`
  y `test/features/maintenance/` sigue en verde sin cambios (regresión, no cobertura nueva).

## Riesgos y mitigaciones

1. **Cascada incompleta si se olvida borrar Soat/Tecnomecanica antes que Vehicle** — mitigado
   ejecutando los 3 borrados dentro de una única transacción Prisma en `hardDeleteAllByOwner`, con
   test unitario que falla si el orden se invierte accidentalmente.
2. **Path derivado incorrectamente desde la download URL** (URLs de Firebase Storage pueden variar
   levemente en formato entre versiones del SDK) — mitigado con test unitario usando una URL real
   de ejemplo del proyecto (extraída de un documento SOAT/vehículo real en QA) y manejo defensivo
   `try/catch` por archivo individual, nunca aborta el batch completo.
3. **Timeout de la cadena de 2 llamadas RPC nuevas + limpieza de Storage sumado a los pasos
   existentes de fase 1** — mitigado reusando el mismo `timeout(15_000)` por paso individual que ya
   usa `hard-delete/:id`; si en pruebas reales el total se acerca al timeout de Dio (20s) configurado
   en `AppDio`, escalar la decisión a fase 4 (que ya tiene este riesgo en su alcance), no resolverlo
   aquí de forma improvisada.
4. **Objeto de Storage ya borrado/URL corrupta rompe el borrado de cuenta completo** — mitigado con
   `try/catch` por archivo dentro de `deleteFilesByUrls`, logueando y continuando (criterio de
   aceptación 5).
5. **`rideglory-contracts` desincronizado** si se agrega un DTO tipado para la respuesta de
   `hardDeleteAllByOwner` — mitigado siguiendo el flujo ya documentado en memoria del proyecto:
   `npm run build` en `rideglory-contracts` + `pnpm install`/reinstalar en cada MS consumidor antes
   de correr tests, para evitar `MODULE_NOT_FOUND`.
6. **Confusión sobre dónde vive `StorageCleanupService`** (hoy acoplado al módulo `ai`) — mitigado
   documentando explícitamente en el PR si se mueve a un módulo compartido o si se inyecta
   directamente en el módulo de usuarios/orquestación; no duplicar la lógica de derivar el path en
   dos archivos distintos.

## Dependencias (fases prerequisito y por qué)

- **Fase 1** (Eliminación de cuenta — núcleo de identidad): fija el endpoint `DELETE /users/me`, el
  orden de orquestación de 5 pasos (dominio → PII de usuario → Firebase Auth al final) y la
  pantalla/copy de confirmación en Flutter. Esta fase 2 depende de que ese punto de inserción exista
  ya en `api-gateway` antes de agregar el paso de vehículos/documentos; no se puede implementar en
  paralelo sin acordar primero el contrato exacto de fase 1.

## Ejecución recomendada (nivel rg-exec: full)

Cambios de contrato cross-MS (`vehicles-ms`, `maintenances-ms`) sin precedente de "bulk por owner"
en el repo, manejo de PII/documentos legales (SOAT/RTM) y borrado en lote de Storage sin convención
de path establecida — riesgo de datos huérfanos si la cascada queda mal implementada.
