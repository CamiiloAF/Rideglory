# PRD Normalizado — eliminacion-cuenta-phase-02

_Generado: 2026-07-10T18:45:40Z_
_Fuente: `docs/plans/eliminacion-cuenta/phases/phase-02-eliminacion-de-cuenta-vehiculos-y-documentos.md`_

## 1 Objetivo

Como rider que elimina su cuenta (fase 1 ya entregó la orquestación de identidad de
`DELETE /users/me`), al confirmar la eliminación también deben desaparecer de inmediato sus motos,
las fotos de esas motos, su historial de mantenimientos y sus documentos SOAT/RTM (con sus
imágenes), sin exponer ningún cambio visible nuevo sobre el flujo de fase 1: la pantalla y el copy
de confirmación ya los mencionan desde esa fase; esta fase solo hace que la promesa sea cierta en
el backend.

## 2 Por qué

Hoy `DELETE /users/me` (fase 1) borra la identidad/PII del usuario pero no toca sus datos de
dominio (vehículos, SOAT, RTM, mantenimientos) ni las imágenes asociadas en Firebase Storage. No
existe `onDelete: Cascade` en el schema de Prisma para estas relaciones, por lo que sin esta fase
quedarían filas y objetos de Storage huérfanos (PII de documentos legales incluida) tras el borrado
de cuenta, contradiciendo el copy que ya se le muestra al usuario en la pantalla de confirmación.

## 3 Alcance

**Entra:**
- Nuevo método interno `vehiclesService.hardDeleteAllByOwner(ownerId)` en `vehicles-ms`, invocado
  desde el paso de orquestación de `DELETE /users/me` en `api-gateway` (extiende la secuencia ya
  fijada en fase 1: dominio → PII de usuario → Firebase Auth).
- Borrado explícito de `Soat` y `Tecnomecanica` por `vehicleId IN (...)` antes/junto al
  `deleteMany` de `Vehicle` del owner (no existe `onDelete: Cascade` hoy).
- Nuevo `MessagePattern` `softDeleteMaintenancesByUserId` en `maintenances-ms` (por `userId`
  directo, reemplaza la necesidad de loopear `softDeleteMaintenancesByVehicleId` por cada
  vehículo), invocado una sola vez desde `api-gateway` con el `userId` del owner.
- Borrado en lote de las imágenes de Firebase Storage asociadas a los vehículos, SOAT y RTM del
  usuario (`Vehicle.imageUrl`, `Soat.documentUrl`, `Tecnomecanica.documentUrl`), derivando el path
  del objeto desde cada download URL guardada (sin introducir convención de carpeta por `ownerId`
  nueva). Reusa el patrón de `storage-cleanup.service.ts` (`bucket.file(...).delete()`), adaptado
  para recibir una lista de URLs en vez de un `prefix`.
- Manejo explícito de "documento sin imagen" (`imageUrl`/`documentUrl` nulo) y de fallos
  individuales de borrado de Storage (objeto ya no existe, URL corrupta): no deben abortar la
  orquestación completa del borrado de cuenta.
- Actualizar el contrato de orquestación de `DELETE /users/me` (documentado en fase 1) para incluir
  este paso en el orden ya fijado.
- Actualizar `docs/features/vehicles.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`
  y `docs/features/maintenance.md` con la nota de que el borrado de cuenta limpia estos datos en
  cascada.

**No entra:**
- Ningún cambio de UI/UX en Flutter: la pantalla de confirmación y su copy ya existen desde fase 1
  — esta fase es 100% backend.
- Anonimización de `EventRegistration` ni bloqueo por organizador con eventos activos (fase 3).
- Manejo de fallos parciales/reintentos/idempotencia de la orquestación multi-paso completa (fase
  4); esta fase solo garantiza que su propio paso sea internamente atómico/idempotente por sí
  mismo.
- Migrar la convención de subida de imágenes existente (`storagePath`) a un esquema por `ownerId`.
- Endpoint `DELETE /users/me`, validación de token, y los pasos de PII de usuario / Firebase Auth
  (ya entregados en fase 1) — esta fase solo añade un paso a la secuencia existente.

## 4 Áreas afectadas (best-effort)

**`rideglory-api` (repo separado):**
- `vehicles-ms/src/vehicles/vehicles.service.ts` — nuevo `hardDeleteAllByOwner(ownerId)`.
- `vehicles-ms/src/vehicles/vehicles.controller.ts` — nuevo `@MessagePattern('hardDeleteAllByOwner')`.
- `maintenances-ms/src/maintenances/maintenances.service.ts` — nuevo `softDeleteAllByUserId(userId)`.
- `maintenances-ms/src/maintenances/maintenances.controller.ts` — nuevo
  `@MessagePattern('softDeleteMaintenancesByUserId')`.
- `api-gateway/src/users/users.controller.ts` (o donde fase 1 dejó la orquestación de
  `DELETE /users/me`) — insertar las 2 llamadas RPC nuevas + limpieza de Storage.
- `api-gateway/src/ai/storage-cleanup.service.ts` (o módulo compartido nuevo) — nuevo método
  `deleteFilesByUrls(urls: string[])`.
- `rideglory-contracts` — opcionalmente `HardDeleteAllByOwnerResultDto`, si se decide tipar
  (requiere `npm run build` + reinstalar en cada MS consumidor).
- Tests nuevos: `vehicles-ms/src/vehicles/vehicles.service.spec.ts`,
  `maintenances-ms/src/maintenances/maintenances.service.spec.ts`,
  `api-gateway/src/ai/storage-cleanup.service.spec.ts` (o spec del módulo final).

**Rideglory (Flutter, este repo) — solo documentación, sin código:**
- `docs/features/vehicles.md`, `docs/features/soat.md`, `docs/features/tecnomecanica.md`,
  `docs/features/maintenance.md` — nota de comportamiento sobre borrado en cascada al eliminar
  cuenta.

## 5 Criterios de aceptación (numerados, observables, testeables)

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

## 6 Guardrails de regresión

- No agregar `onDelete: Cascade` al schema de Prisma en esta fase (decisión explícita del
  Architect: borrado explícito por `vehicleId IN (...)` en la capa de servicio, más auditable/
  testeable, sin requerir migración).
- No cambiar la convención de `storagePath` de subida de imágenes (`vehicles/{nombre}.jpg`,
  `soat/{vehicleId}/...`, `tecnomecanica/{vehicleId}/...`); el borrado en lote deriva el path desde
  la download URL guardada en cada fila.
- No introducir cambios de UI/UX ni de copy en Flutter — la pantalla de confirmación de fase 1 no
  se toca.
- No implementar anonimización de `EventRegistration` ni bloqueo por organizador con eventos
  activos (reservado a fase 3).
- No resolver el manejo de fallos parciales/reintentos/idempotencia del endpoint completo de 5
  pasos (reservado a fase 4); solo garantizar idempotencia interna del propio paso de esta fase.
- Dentro de `vehicles-ms`, los 3 borrados (`Soat`, `Tecnomecanica`, `Vehicle`) deben ejecutarse en
  una única transacción Prisma, en ese orden, para evitar cascada incompleta.
- `deleteFilesByUrls` debe manejar cada archivo con `try/catch` individual (loguear y continuar),
  nunca abortar el batch completo por un archivo faltante o URL corrupta.
- No crear endpoints HTTP nuevos en `api-gateway`; solo 2 llamadas RPC internas + 1 llamada a
  Storage dentro de la orquestación existente de `DELETE /users/me`.
- Si se agrega un DTO en `rideglory-contracts`, reconstruir (`npm run build`) y reinstalar en cada
  MS consumidor antes de correr tests, para evitar `MODULE_NOT_FOUND`.
- La suite Flutter existente (`test/features/vehicles/`, `test/features/soat/`,
  `test/features/tecnomecanica/`, `test/features/maintenance/`) debe seguir en verde sin cambios de
  código (regresión, no cobertura nueva).

## 7 Constraints heredados

- Arquitectura de microservicios (`vehicles-ms`, `maintenances-ms`, `api-gateway`) con comunicación
  vía `MessagePattern`/RPC interno, mismo patrón que `hard-delete/:id` ya usa hoy
  (`timeout(15_000)` + `catchError` → `502 Bad Gateway` con `retryable: true`).
- Dependencia de fase 1 (Eliminación de cuenta — núcleo de identidad): fija el endpoint
  `DELETE /users/me`, el orden de orquestación de 5 pasos (dominio → PII de usuario → Firebase Auth
  al final) y la pantalla/copy de confirmación en Flutter. Esta fase depende de que ese punto de
  inserción exista ya en `api-gateway`.
- Backend vive en el repo separado `rideglory-api`
  (`/Users/cami/Developer/Personal/rideglory-api`), super-repo con submódulos por microservicio;
  cambios pueden abarcar múltiples repos/PRs.
- Gotcha de `rideglory-contracts`: tras cambiar el paquete compartido, `npm run build` +
  `pnpm install` en cada MS consumidor, o fallan con `MODULE_NOT_FOUND`.
- No hay usuarios reales en prod al momento del plan original (nota: memoria del proyecto indica
  que desde 2026-07-10 SÍ hay usuarios reales; extremar cautela al ejecutar pruebas de integración
  manual, aunque el plan sugiere usar cuentas QA `qa1@gmail.com`/`qa2@gmail.com`).
- Reglas de arquitectura Rideglory (`.claude/rules/rideglory-coding-standards.mdc`): dominio sin
  I/O ni Flutter imports; data sin BuildContext; presentación sin DTOs expuestos — aplica solo a la
  parte de docs Flutter tocada por esta fase, ya que no hay cambios de código en la app.
- No se toca `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`,
  `.claude/**`, ni la nota de fase fuente.
