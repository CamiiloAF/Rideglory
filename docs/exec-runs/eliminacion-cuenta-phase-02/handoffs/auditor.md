# Auditoría — eliminacion-cuenta-phase-02 (agente backend)

**Fecha:** 2026-07-10T18:58:06Z
**Veredicto:** NO APROBADO (score 2/10)
**Motivo:** El agente se detuvo por baseline rojo legítimo y NO implementó el change map. No hay entregable que audit­ar: 0/8 AC cumplidos, 0 pruebas nuevas.

## Qué verifiqué (todas las afirmaciones del handoff son ciertas)

1. **Baseline genuinamente rojo.** Corrí `npx jest src/vehicles/vehicles.service.spec.ts` en `vehicles-ms` @ HEAD `1ec1392`: **2 failed, 17 passed**. Fallan:
   - `findByOwnerId (AC-1) › passes isDeleted:false and isArchived:false in the where clause`
   - `findByOwnerId (AC-1) › FAILS if isArchived filter is removed (guard test)`
   Causa confirmada: `vehicles.service.ts:93` usa `where: { ownerId, isDeleted: false }` — falta `isArchived: false`.
2. **Preexistente, no del agente.** `git log -1 -- vehicles.service.spec.ts` y `-- vehicles.service.ts` → ambos en commit `1ec1392` (2026-06-17), anterior a esta fase (hoy 2026-07-10). El desfase código/test ya estaba en el árbol.
3. **`findByOwnerId` NO está en el change map** de esta fase (que toca `hardDeleteAllByOwner`, `softDeleteAllByUserId`, `deleteFilesByUrls`, `ai.module.ts`, `users.module.ts`, `account-deletion.service.ts`). El agente actuó bien al no invadir un archivo fuera de alcance sin autorización.
4. **Working tree limpio** en `vehicles-ms`, `maintenances-ms` y `api-gateway`: `git status --short` vacío en los 3. Cero cambios de producción/tests, consistente con "no apliqué nada".

## Por qué NO apruebo pese al bloqueo legítimo

El criterio de aprobación exige AC cumplidos + pruebas que fallarían sin el cambio (en verde). Nada de eso existe: la implementación no se produjo. El bloqueo fue honesto y correcto, pero un handoff bloqueado no es un entregable aprobable. La fase queda **abierta**.

## Cambios requeridos para desbloquear y completar

1. **[Fuera de esta fase, pero bloqueante] Resolver el rojo preexistente** en `vehicles-ms/src/vehicles/vehicles.service.ts::findByOwnerId` (línea ~93). El comportamiento consistente con `findMainVehicleByOwnerId` (línea 101, ya filtra `isArchived: false`) y con la sección de garage archivado en Flutter es **añadir `isArchived: false` al `where`**. Confirmar la intención con Architect/Tech Lead; alternativa: corregir el spec si el comportamiento deseado fuera incluir archivados. Debe ir en su propio commit/PR, no mezclado con esta fase.
2. **Re-ejecutar la fase backend** una vez `vehicles-ms` esté verde, implementando el change map completo: `hardDeleteAllByOwner` (transacción Prisma Soat→Tecnomecanica→Vehicle, idempotente con garage vacío), `softDeleteAllByUserId` en maintenances-ms, `deleteFilesByUrls` (try/catch por archivo, ignora URLs nulas), inserción de las 2 RPC + limpieza Storage en `account-deletion.service.ts`, y specs por cada path + guardrails.
3. **Actualizar los 4 docs de features** (`vehicles.md`, `soat.md`, `tecnomecanica.md`, `maintenance.md`) con la nota de borrado en cascada (aún no tocados).
