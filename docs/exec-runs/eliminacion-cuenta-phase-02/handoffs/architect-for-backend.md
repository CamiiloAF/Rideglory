# Architect → Backend — eliminacion-cuenta-phase-02

Ver `handoffs/architect.md` para el detalle completo. Resumen accionable:

## Qué construir, en este orden

1. **`vehicles-ms/src/vehicles/vehicles.service.ts`** — nuevo método en `VehiclesService`
   (extiende `PrismaClient`, no crear servicio nuevo):
   ```
   async hardDeleteAllByOwner(ownerId: string): Promise<{ deletedVehicleCount: number; imageUrls: string[] }>
   ```
   - `findMany({ where: { ownerId } })` para capturar `id` + `imageUrl` de cada vehículo.
   - Si `ids.length === 0` → devolver `{ deletedVehicleCount: 0, imageUrls: [] }` sin abrir
     transacción.
   - Capturar `documentUrl` de `soat.findMany({ where: { vehicleId: { in: ids } } })` y
     `tecnomecanica.findMany({ where: { vehicleId: { in: ids } } })` antes de borrar.
   - `this.$transaction` en este orden exacto: `soat.deleteMany({ vehicleId: { in: ids } })` →
     `tecnomecanica.deleteMany({ vehicleId: { in: ids } })` → `vehicle.deleteMany({ ownerId })`.
   - `imageUrls` = unión de `Vehicle.imageUrl` + `Soat.documentUrl` + `Tecnomecanica.documentUrl`,
     filtrando `null`/`undefined` y deduplicando.
   - Controller: `vehicles-ms/src/vehicles/vehicles.controller.ts` →
     `@MessagePattern('hardDeleteAllByOwner') @Payload('ownerId') ownerId: string`.
   - Spec: `vehicles-ms/src/vehicles/vehicles.service.spec.ts` — casos: N vehículos con SOAT+RTM
     con foto, garage vacío, vehículo sin imagen (`imageUrl: null`), URLs duplicadas entre
     vehículo/SOAT/RTM (dedupe), transacción atómica (mock de fallo a mitad de transacción no deja
     residuos — verificar con `$transaction` real de Prisma test DB si el proyecto usa DB real en
     specs, o mock si usa mocks; seguir el patrón que ya usan los specs vecinos
     `soat.service.spec.ts`/`tecnomecanica.service.spec.ts`).

2. **`maintenances-ms/src/maintenances/maintenances.service.ts`** — nuevo método análogo a
   `softDeleteAllByVehicleId` ya existente:
   ```
   softDeleteAllByUserId(userId: string) {
     return this.maintenance.updateMany({ where: { userId, isDeleted: false }, data: { isDeleted: true } });
   }
   ```
   - Controller: `@MessagePattern('softDeleteMaintenancesByUserId') @Payload('userId') userId: string`.
   - Spec nuevo: `maintenances-ms/src/maintenances/maintenances.service.spec.ts` (no existe hoy) —
     casos: M registros del usuario en distintos vehículos, 0 registros, idempotencia (correr dos
     veces, segunda vez `count: 0`).

3. **`api-gateway/src/ai/storage-cleanup.service.ts`** — nuevo método público:
   ```
   async deleteFilesByUrls(urls: string[]): Promise<void>
   ```
   - Filtrar `null`/`undefined`/`''` antes de iterar.
   - Por cada URL: extraer el path desde el patrón
     `https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encodedPath}?...` — el segmento entre
     `/o/` y `?` es el path URL-encoded; `decodeURIComponent(...)` para obtener el path real
     (ej. `vehicles/foo.jpg`). Envolver **cada** `bucket.file(path).delete()` en su propio
     `try/catch`, loguear `this.logger.warn` en fallo y seguir con la siguiente URL — nunca
     relanzar.
   - Si el proyecto tiene URLs guardadas con el formato alterno de `storage.service.ts`
     (`https://storage.googleapis.com/{bucket}/{path}`, sin `/o/`), soportar también ese caso (path
     = todo después de `{bucket}/`). Verificar cuál formato aparece realmente en datos de vehicles/
     soat/tecnomecanica antes de descartar uno.
   - Registrar `StorageCleanupService` en `api-gateway/src/ai/ai.module.ts`: agregarlo a
     `providers` (ya falta hoy) y agregar un array `exports: [StorageCleanupService]`.
   - Spec: `api-gateway/src/ai/storage-cleanup.service.spec.ts` — agregar casos para
     `deleteFilesByUrls`: URL válida borra el archivo correcto, lista vacía no hace nada, URL
     corrupta/objeto inexistente no lanza y continúa con el resto del batch, `null` en la lista se
     ignora sin contar como fallo.

4. **`api-gateway/src/users/users.module.ts`** — agregar a `ClientsModule.registerAsync([...])`
   dos entradas nuevas para `VEHICLES_SERVICE` y `MAINTENANCES_SERVICE`, copiando literalmente el
   bloque que ya existe en `api-gateway/src/vehicles/vehicles.module.ts` (mismo `Transport.TCP`,
   `envs.vehiclesMsPort/Host`, `envs.maintenancesMsPort/Host`, `TracingSerializer`). Agregar
   `AiModule` a `imports` para poder inyectar `StorageCleanupService`.

5. **`api-gateway/src/users/account-deletion.service.ts`** — constructor pasa de 2 a 5 deps:
   `usersService` (`USERS_SERVICE`), `firebaseAuthService`, + nuevas `vehiclesService`
   (`VEHICLES_SERVICE`), `maintenancesService` (`MAINTENANCES_SERVICE`), `storageCleanupService`
   (`StorageCleanupService`). Reemplazar los comentarios `// TODO fase 2` / `// TODO fase 3` por:
   ```
   const { deletedVehicleCount, imageUrls } = await firstValueFrom(
     this.vehiclesService.send('hardDeleteAllByOwner', { ownerId: user.id }).pipe(
       timeout(15_000),
       catchError((error) => { throw new RpcException({ message: ..., status: HttpStatus.BAD_GATEWAY }); }),
     ),
   );

   try {
     await this.storageCleanupService.deleteFilesByUrls(imageUrls);
   } catch (error) {
     this.logger.warn(`Storage cleanup failed for account deletion: ${error}`);
     // no relanzar — el borrado de cuenta continúa igual
   }

   await firstValueFrom(
     this.maintenancesService.send('softDeleteMaintenancesByUserId', { userId: user.id }).pipe(
       timeout(15_000),
       catchError((error) => { throw new RpcException({ message: ..., status: HttpStatus.BAD_GATEWAY }); }),
     ),
   );
   ```
   dejando el `hardDeleteUser` + `firebaseAuthService.deleteUser` existentes como pasos finales,
   en ese orden, sin tocarlos.
   - Spec: `account-deletion.service.spec.ts` — el test existente de "5 pasos en orden" ahora debe
     cubrir 6 pasos: `findUserByEmail → hardDeleteAllByOwner → deleteFilesByUrls →
     softDeleteMaintenancesByUserId → hardDeleteUser → firebaseDeleteUser`. Agregar casos: garage
     vacío (`imageUrls: []`, `deleteFilesByUrls` se llama igual con array vacío o se skipea — decidir
     y testear explícitamente), fallo de `deleteFilesByUrls` no aborta el flujo (los pasos 4-6 igual
     se ejecutan), fallo de `hardDeleteAllByOwner` o de `softDeleteMaintenancesByUserId` sí propaga
     y aborta (no se llega a `hardDeleteUser`/Firebase).

## Contratos nuevos (RPC internos, sin HTTP nuevo, sin DTO en `rideglory-contracts`)

- `hardDeleteAllByOwner` (vehicles-ms): `{ ownerId: string }` → `{ deletedVehicleCount: number; imageUrls: string[] }`.
- `softDeleteMaintenancesByUserId` (maintenances-ms): `{ userId: string }` → `{ count: number }`.

## Guardrails duros de esta fase

- Sin migración de Prisma, sin `onDelete: Cascade` (no hay `@relation` real que cascadear).
- Los 3 borrados de `vehicles-ms` van en **una sola transacción Prisma**, orden: Soat →
  Tecnomecanica → Vehicle.
- `deleteFilesByUrls` nunca lanza hacia el caller — `try/catch` por archivo.
- Nada de endpoints HTTP nuevos; todo vía `MessagePattern`.
- Si tocas `rideglory-contracts` (no debería hacer falta en esta fase): `npm run build` + reinstalar
  en cada MS consumidor antes de correr tests.
- No commitear (el árbol queda sucio para revisión humana).
