# Auditoría — architect (eliminacion-cuenta-phase-02)

_Auditado: 2026-07-10T18:52:06Z_
_Veredicto: APROBADO (score 92)_

Esta es una entrega de **arquitectura / change map** (no hay código; `git diff` vacío, solo
artefactos untracked bajo `docs/exec-runs/`). Se audita fidelidad al código real, cobertura de AC,
orden de dependencias y contratos.

## Verificaciones contra código real (rideglory-api) — todas confirmadas

1. `AccountDeletionService` tiene exactamente 2 deps (`usersService`, `firebaseAuthService`) y los
   placeholders `// TODO fase 2` / `// TODO fase 3` entre `findUserByEmail` y `hardDeleteUser` +
   `firebaseAuthService.deleteUser`. El punto de inserción de fase 1 existe. ✔
2. `account-deletion.service.spec.ts` construye el servicio **posicionalmente** con 2 args → el
   architect flagea correctamente que el constructor crecerá a 5 y hay que actualizar TODAS las
   instanciaciones. ✔
3. `StorageCleanupService` está **huérfano en DI**: no aparece en `AiModule.providers`, ni se
   importa en ningún módulo; solo se instancia en su propio spec. Usa
   `getStorage(getApps()[0]).bucket()` + `file.delete()`. Firebase Admin está disponible en el
   gateway (`firebase-auth.service`). ✔
4. **Formato dual de URL confirmado y bien flageado (riesgo real):** `storage.service.ts` guarda
   covers de IA como `https://storage.googleapis.com/{bucket}/{path}` (sin `/o/`), mientras que las
   imágenes de vehículo/SOAT/RTM las sube el cliente Flutter como
   `firebasestorage.googleapis.com/v0/b/.../o/{encodedPath}`. `deleteFilesByUrls` debe parsear el
   formato correcto. El architect lo documentó en Riesgo #2. ✔
5. Schema Prisma: `Soat`/`Tecnomecanica` con `vehicleId String @unique` **sin `@relation`**;
   `Vehicle.imageUrl`, `Soat.documentUrl`, `Tecnomecanica.documentUrl` todos `String?` (nullable →
   sustenta AC4). No hay FK que cascadear → guardrail "sin migración" es correcto, no solo
   preferido. ✔
6. `maintenances.service.ts` ya tiene el precedente `softDeleteAllByVehicleId` con el patrón exacto
   propuesto (`updateMany({ where:{...,isDeleted:false}, data:{isDeleted:true} })`); `Maintenance`
   tiene columna `userId`; NO existe `maintenances.service.spec.ts` (CREATE, no MODIFY). ✔
7. `UsersModule` hoy solo registra `USERS_SERVICE` → hay que añadir `VEHICLES_SERVICE`/
   `MAINTENANCES_SERVICE` + importar `AiModule`. ✔

## Cobertura de AC
AC1→hardDeleteAllByOwner (tx); AC2→softDeleteAllByUserId; AC3→deleteFilesByUrls; AC4→filtrar null;
AC5→try/catch por archivo; AC6→ids=[] retorna vacío; AC7→solo docs Flutter; AC8→specs enumerados.
Todos cubiertos. Nada fuera de alcance (sin UI, sin EventRegistration, sin Cascade). Orden de
implementación respeta dependencias (contratos MS antes de orquestación gateway; docs en paralelo).
Flags correctos: uiChanges=false, backendChanges=true, frontendChanges=false, dbChanges=false,
needsDesign=false.

## Recomendaciones para el implementador (no bloqueantes)
- `hardDeleteAllByOwner`: el `findMany({ where: { ownerId } })` NO debe filtrar `isDeleted:false`
  (a diferencia de `findByOwnerId`), para purgar también objetos de Storage de vehículos ya
  soft-deleted. El handoff ya lo escribe sin filtro; mantenerlo explícito.
- Para las URLs de ESTA feature el formato primario es `firebasestorage.../o/{encodedPath}` (subida
  por cliente Flutter); el formato `storage.googleapis.com/{bucket}/{path}` es solo de covers de IA
  (fuera de alcance). El soporte dual es defensivo y correcto.
- Actualizar el nombre y aserciones del test "5 pasos en orden" a 6 pasos y actualizar las 3
  instanciaciones posicionales del spec al ampliar el constructor.
