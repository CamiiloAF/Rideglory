# PRD Normalizado — RTM Backend: Persistencia y Consulta de Tecnomecánica

> Slug: `rtm-backend-persistencia` · Fuente: `docs/plans/tecnomecanica-rtm/phases/phase-02-backend-persistencia-y-consulta-de-tecnomecanica.md` · Normalizado: 2026-06-04T17:31:13Z · Nivel: normal

---

## 1 Objetivo

Implementar la capa backend (rideglory-api) que guarda, lee y borra la RTM (tecnomecánica) de un vehículo vía API, con las mismas garantías de seguridad y validación que el SOAT: Firebase Auth en las 3 rutas REST, `validateVehicleOwnership` en upsert/find/delete, regla `expiryDate > startDate` server-side, y el método `findTecnomecanicasExpiringIn` para el scheduler futuro.

El contrato `CreateTecnomecanicaDto` queda fijado con required/optional explícitos (sin replicar el mismatch latente de SOAT). El GET responde **404 cuando no hay documento**, preservando la cadena `404 → Right(null) → ResultState.empty()` que el frontend espera.

---

## 2 Por qué

- Sin este backend, la Fase 3 (Flutter RTM) no tiene contrato contra el que implementar ni endpoint real al que conectarse.
- El SOAT tiene un mismatch latente en su DTO (`startDate` sin `@IsOptional()`) que funciona solo por la UI; RTM lo corrige de raíz al fijar required/optional explícitos antes de que el frontend exista.
- El `GET /soat` actual devuelve `200 + null` en ausencia de documento; si RTM lo copia tal cual, la cadena `404 → empty` del frontend se rompe silenciosamente.
- `findTecnomecanicasExpiringIn` es prerequisito del scheduler de recordatorios de la Fase 5; debe existir antes que los crons.

---

## 3 Alcance

**Entra:**
- `model Tecnomecanica` en `vehicles-ms/prisma/schema.prisma` (tabla separada, espejo de `Soat`, con campos propios: `certificateNumber`, `cdaName`, `cdaCode?`).
- Migración Prisma local (`prisma migrate dev --name add_tecnomecanica`) con gate de validación humana antes de tocar remoto.
- `TecnomecanicaService` en `vehicles-ms`: `upsertTecnomecanica`, `findTecnomecanicaByVehicle`, `deleteTecnomecanica`, `findTecnomecanicasExpiringIn`.
- 4 `@MessagePattern` RPC en `vehicles-ms/src/vehicles/vehicles.controller.ts`.
- 3 rutas REST `POST/GET/DELETE /api/vehicles/:vehicleId/tecnomecanica` en `api-gateway` con Firebase Auth guard; el GET lanza `NotFoundException` (404) si no existe RTM.
- `CreateTecnomecanicaDto` idéntico en `api-gateway` y `vehicles-ms`, con required/optional explícitos.
- `tecnomecanica.service.spec.ts` cubriendo upsert / find / delete / expiring.

**No entra:**
- Código Flutter (Fase 3).
- Recordatorios / crons / `NotificationType` RTM (Fase 5).
- OCR / `documentUrl` autopoblado (es opcional, lo provee el cliente).
- Tocar `SoatService`, `CreateSoatDto`, `model Soat` o sus tests.
- Unificar SOAT y RTM en tabla genérica con discriminador `kind`.

---

## 4 Áreas afectadas

| Repo | Ruta | Cambio |
|------|------|--------|
| rideglory-api | `vehicles-ms/prisma/schema.prisma` | Añade `model Tecnomecanica` |
| rideglory-api | `vehicles-ms/prisma/migrations/<ts>_add_tecnomecanica/` | Migración generada |
| rideglory-api | `vehicles-ms/src/vehicles/tecnomecanica.service.ts` | Nuevo service |
| rideglory-api | `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` | Tests unitarios |
| rideglory-api | `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` | DTO escritura (MS) |
| rideglory-api | `vehicles-ms/src/vehicles/vehicles.controller.ts` | 4 `@MessagePattern` + inyección |
| rideglory-api | `vehicles-ms/src/vehicles/vehicles.module.ts` | Registra `TecnomecanicaService` |
| rideglory-api | `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts` | DTO escritura (gateway) |
| rideglory-api | `api-gateway/src/vehicles/vehicles.controller.ts` | 3 rutas REST + GET 404 |

---

## 5 Criterios de aceptación

1. Existe `model Tecnomecanica` en `schema.prisma` con `vehicleId @unique`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate?`, `expiryDate`, `documentUrl?`, `createdAt`, `updatedAt`; `model Soat` queda byte-idéntico.
2. `prisma migrate dev` genera una migración que crea `Tecnomecanica` y **no** altera `Soat`; corre sin error en local.
3. Las 3 rutas `/api/vehicles/:vehicleId/tecnomecanica` (POST/GET/DELETE) están protegidas por el mismo Firebase Auth guard que las de SOAT (sin token → 401/403).
4. `validateVehicleOwnership` se invoca en upsert, find y delete: un usuario no-dueño del vehículo recibe `403` en las tres operaciones.
5. El upsert rechaza con `400` cuando `expiryDate <= startDate` (validación server-side), y persiste correctamente cuando `startDate` se omite (es opcional).
6. `GET /tecnomecanica` responde **`404`** cuando no existe RTM para el vehículo (NO `200` con cuerpo `null`).
7. `DELETE /tecnomecanica` responde `404` cuando no hay RTM y `{ success: true }` cuando borra (espejo de `deleteSoat`).
8. `CreateTecnomecanicaDto` rechaza con `400` un body sin `certificateNumber`, sin `cdaName` o sin `expiryDate`; acepta un body sin `startDate`, `cdaCode` ni `documentUrl`. El DTO existe idéntico en `api-gateway` y `vehicles-ms`.
9. `findTecnomecanicasExpiringIn(days)` devuelve solo las RTM cuyo `expiryDate` cae en la ventana UTC día-exacto de `days` (misma lógica que `findSoatsExpiringIn`).
10. `tecnomecanica.service.spec.ts` cubre upsert (éxito, `expiry<=start`, no-dueño), find (con/sin documento), delete (éxito, 404) y expiring; la suite del MS pasa verde.
11. Build TS de `vehicles-ms` y `api-gateway` sin errores; lint sin nuevos warnings.
12. La suite SOAT del backend sigue verde sin tocar su acceptance (regresión cero); ningún `NotificationType` ni cron fue añadido en esta fase.
13. La migración local fue validada por un humano antes de cerrar la fase (gate explícito, no automatizable).

---

## 6 Guardrails de regresión

- `model Soat` y `CreateSoatDto` no se tocan; diff de `schema.prisma` solo debe añadir líneas, no modificar las existentes de `Soat`.
- Suite `soat.service.spec.ts` y e2e de SOAT corren sin cambios en sus assertions y pasan verde.
- No se añade ningún `NotificationType` ni entrada de cron en esta fase.
- Las rutas REST de SOAT (`POST/GET/DELETE /api/vehicles/:vehicleId/soat`) no sufren modificaciones funcionales.
- Ningún `@MessagePattern` existente en `vehicles.controller.ts` (MS) es alterado; solo se añaden los 4 nuevos de RTM.
- La migración remota NO la dispara el workflow automatizado; el humano la ejecuta tras validar local.

---

## 7 Constraints heredados

- **Tablas separadas** (no discriminador `kind`): decisión de arquitectura fijada en `05-sintesis.md` (A6), no negociable.
- **DTO duplicado por paquete** (`api-gateway` + `vehicles-ms`): mismo patrón que `create-soat.dto.ts` hoy; mantener ambos idénticos.
- **GET 404 en ausencia de RTM** (no `200 + null`): diferencia deliberada respecto al comportamiento de SOAT, fijada en `05-sintesis.md` A6.
- **`startDate` opcional** en `CreateTecnomecanicaDto` (`@IsOptional()`): corrección del mismatch latente de SOAT; no replicar el comportamiento de `create-soat.dto.ts`.
- **Deploy workflow**: migración local → validación humana → remoto. La fase no cierra sin validación humana de la migración local (criterio 13). La migración remota es responsabilidad del humano.
- **Firebase Auth guard** obligatorio en las 3 rutas REST: mismo guard que SOAT, sin excepciones.
- **`validateVehicleOwnership`** en las 3 operaciones (upsert/find/delete): no omitir en ninguna.
- **Sin OCR / documentUrl autopoblado**: `documentUrl` es opcional y solo lo provee el cliente.
