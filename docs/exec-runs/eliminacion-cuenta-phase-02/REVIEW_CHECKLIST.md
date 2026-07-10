# REVIEW_CHECKLIST — eliminacion-cuenta-phase-02

Pasos manuales antes de commitear. El working tree queda sucio a propósito — nadie de este
workflow ejecuta `git add`/`commit`/`push`.

## 1. Revisión de diff

- [ ] `cd rideglory-api/vehicles-ms && git diff` — revisar `hardDeleteAllByOwner` y el
      `@MessagePattern` nuevo.
- [ ] `cd rideglory-api/maintenances-ms && git diff` + `git status` (el spec es archivo nuevo,
      `?? src/maintenances/maintenances.service.spec.ts` — hay que `git add` explícito, no queda
      en `git diff`).
- [ ] `cd rideglory-api/api-gateway && git diff` — revisar orquestación de 6 pasos en
      `account-deletion.service.ts`, `storage-cleanup.service.ts` y el wiring de
      `users.module.ts`/`ai.module.ts`.
- [ ] `cd Rideglory && git diff docs/features/` — confirmar que son solo las 4 notas de cascada,
      sin cambios de copy visible al usuario.

## 2. Decisión de scope pre-commit

- [ ] Decidir si el fix de test `findByOwnerId (AC-1)` en
      `vehicles-ms/src/vehicles/vehicles.service.spec.ts` (quita la aserción incorrecta de
      `isArchived:false`) va en el mismo commit de esta fase o en un commit separado de
      "test fix" — no es parte del change map original del PRD (ver Riesgos en SUMMARY.md).

## 3. Tests (reproducir localmente antes de commitear)

- [ ] `cd rideglory-api/vehicles-ms && npx jest src/vehicles`
- [ ] `cd rideglory-api/maintenances-ms && npx jest src/maintenances`
- [ ] `cd rideglory-api/api-gateway && npx jest src/ai src/users`
- [ ] `cd Rideglory && dart analyze` (debe quedar en 0 errores; los 15 `info` preexistentes no
      relacionados a esta fase pueden ignorarse)
- [ ] `cd Rideglory && flutter test` (sin cambios de código esperados, debe seguir en verde)

## 4. rideglory-contracts

- [ ] Confirmar que NO se agregó ningún DTO nuevo a `rideglory-contracts` en esta fase (el PRD lo
      dejaba como opcional). Si se decide tipar `HardDeleteAllByOwnerResult` más adelante, recordar
      `npm run build` + reinstalar en cada MS consumidor antes de correr tests (gotcha conocido).

## 5. Pruebas manuales (antes de considerar la fase cerrada para producción)

Usar **solo** cuentas QA dedicadas (`qa1@gmail.com`/`qa2@gmail.com`, password `Test123.`) o una
cuenta QA desechable — hay usuarios reales en producción desde 2026-07-10. El borrado de cuenta es
irreversible.

- [ ] Usuario con N vehículos, cada uno con SOAT y RTM (con foto) y M mantenimientos →
      `DELETE /users/me` → verificar por query directa a Postgres de `vehicles-ms` que no quedan
      filas de `Vehicle`/`Soat`/`Tecnomecanica` con ese `ownerId`/`vehicleId`.
- [ ] Verificar en `maintenances-ms` que los `Maintenance` de ese `userId` quedan con
      `isDeleted: true`.
- [ ] Verificar en consola de Firebase Storage (o `bucket.file(path).exists()`) que las imágenes de
      esos vehículos y los documentos SOAT/RTM ya no existen.
- [ ] Usuario con SOAT o RTM sin foto (`documentUrl: null`) completa el borrado sin error.
- [ ] Usuario con imagen de vehículo borrada manualmente del bucket antes de eliminar la cuenta
      (URL colgada) completa el borrado sin error 500.
- [ ] Usuario sin ningún vehículo (garage vacío) completa el borrado sin error.
- [ ] Confirmar que la pantalla y el copy de confirmación de eliminación de cuenta no cambiaron
      visualmente respecto a fase 1.

## 6. Post-commit (fuera de este workflow)

- [ ] Si `rideglory-api` usa PRs por submódulo, abrir uno por cada MS tocado
      (`vehicles-ms`, `maintenances-ms`, `api-gateway`) y actualizar el puntero del super-repo tras
      mergear cada uno.
- [ ] Actualizar `docs/PRD.md`/`docs/PLAN.md`/`docs/PRODUCT_STATUS.md` del proyecto de
      eliminación de cuenta si corresponde marcar la fase 2 como completa (fuera del scope de este
      Tech Lead — esos archivos están explícitamente prohibidos para este agente).
