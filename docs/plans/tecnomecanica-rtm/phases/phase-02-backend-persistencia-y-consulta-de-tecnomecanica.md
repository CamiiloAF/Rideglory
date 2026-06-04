# Fase 2 — Backend: persistencia y consulta de tecnomecánica

> Plan: `tecnomecanica-rtm` · Fase 2 de 6 · Repo: **`rideglory-api`** (separado) · Generado: 2026-06-04T13:18:13Z
> Insumos: `05-sintesis.md`, `01-scan.md`, `03-architect-review.md`. Sesión de planeación: este archivo no modifica código.

---

## Objetivo

El sistema guarda, lee y borra la RTM (tecnomecánica) de un vehículo vía API con las **mismas garantías de seguridad y validación que el SOAT**: Firebase Auth en las 3 rutas, `validateVehicleOwnership` en upsert/find/delete, regla `expiryDate > startDate` server-side, y la consulta para el scheduler (`findTecnomecanicasExpiringIn`). El contrato `CreateTecnomecanicaDto` queda fijado con required/optional **explícitos**, sin replicar el mismatch latente de SOAT, y el GET responde **404 cuando no hay documento** para preservar la cadena `404 → Right(null) → ResultState.empty()` del frontend.

## Alcance (entra / no entra)

**Entra:**
- Nuevo `model Tecnomecanica` en `vehicles-ms/prisma/schema.prisma` (tabla **separada**, espejo de `Soat`, con campos propios: `certificateNumber`, `cdaName`, `cdaCode?`).
- Migración Prisma local → **validación humana** → remoto (la fase no cierra sin la validación local del humano).
- `TecnomecanicaService` (`vehicles-ms`), espejo mecánico de `SoatService`: `upsertTecnomecanica`, `findTecnomecanicaByVehicle`, `deleteTecnomecanica`, `findTecnomecanicasExpiringIn`.
- Handlers RPC `@MessagePattern` en `vehicles-ms/src/vehicles/vehicles.controller.ts` (los 4 patterns nuevos).
- 3 rutas REST `POST/GET/DELETE /api/vehicles/:vehicleId/tecnomecanica` en `api-gateway/src/vehicles/vehicles.controller.ts` con Firebase Auth guard, espejo de las de SOAT, **salvo que el GET responde 404 cuando no existe** (no `200 + null`).
- `CreateTecnomecanicaDto` en **ambos** paquetes (`api-gateway` y `vehicles-ms`), con required/optional explícitos.
- `tecnomecanica.service.spec.ts` cubriendo upsert / find / delete / expiring.

**No entra:**
- Cualquier código Flutter (eso es Fase 3). Aquí solo se define el contrato que Fase 3 consume.
- Recordatorios / crons / `NotificationType` RTM y el refactor `sendDocumentExpiryReminders` (eso es **Fase 5**). No se añade ningún `NotificationType` ni cron en esta fase.
- OCR / extracción / `documentUrl` autopoblado (RTM es captura manual; `documentUrl` es opcional y lo provee el cliente si existe).
- Tocar `SoatService`, `CreateSoatDto`, el `model Soat` o sus tests (regresión cero en SOAT backend; no se "arregla" aquí el mismatch latente de SOAT).
- Unificar SOAT y RTM en una tabla genérica con discriminador `kind`: decisión del PRD = **tablas separadas**.

## Que se debe hacer (pasos concretos y ordenados)

1. **Schema Prisma.** Añadir `model Tecnomecanica` a `vehicles-ms/prisma/schema.prisma`, espejo de `model Soat`: `id`, `vehicleId @unique`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate? DateTime`, `expiryDate DateTime`, `documentUrl?`, `createdAt`, `updatedAt`. (El `model Soat` no declara relación explícita al `Vehicle` — solo `vehicleId @unique` —; replicar exactamente ese estilo para no introducir un FK nuevo no presente en SOAT.)
2. **Migración local.** Ejecutar `prisma migrate dev --name add_tecnomecanica` contra la BD local. Verificar que crea la tabla y NO altera `Soat`. **Detenerse aquí y solicitar validación humana** de la migración local antes de tocar remoto (regla de proyecto / memoria "Deploy workflow"). No correr la migración remota dentro de la fase.
3. **DTO de escritura.** Crear `CreateTecnomecanicaDto` en `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` y su gemelo en `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts`, con los validadores de la tabla de Contratos. Mantener ambos archivos idénticos (igual que existen dos `create-soat.dto.ts` hoy).
4. **Service.** Crear `vehicles-ms/src/vehicles/tecnomecanica.service.ts` copiando `soat.service.ts` y renombrando entidad/campos: `upsertTecnomecanica` (`validateVehicleOwnership` + `parseDate` + regla `expiry > start`), `findTecnomecanicaByVehicle` (`findUnique by vehicleId`), `deleteTecnomecanica` (lanza 404/`RpcException` si no existe, espejo de `deleteSoat`), `findTecnomecanicasExpiringIn(daysUntilExpiry)` (ventana UTC día-exacto). Conservar `validateVehicleOwnership` 1:1 con SOAT (mismo helper / misma lógica de pertenencia).
5. **RPC controller.** En `vehicles-ms/src/vehicles/vehicles.controller.ts` añadir los 4 `@MessagePattern`: `upsertTecnomecanica`, `findTecnomecanicaByVehicle`, `deleteTecnomecanica`, `findTecnomecanicasExpiringIn`, con la misma forma de payload que sus equivalentes SOAT (`{ vehicleId, ownerId, dto }` / `{ vehicleId, ownerId }` / `{ daysUntilExpiry }`). Inyectar `TecnomecanicaService` en el constructor y registrarlo en el provider del módulo (`vehicles.module.ts`).
6. **REST gateway.** En `api-gateway/src/vehicles/vehicles.controller.ts` añadir las 3 rutas `':vehicleId/tecnomecanica'` (POST/GET/DELETE) con el mismo guard Firebase y extracción de `ownerId` que SOAT. **Diferencia obligatoria respecto a SOAT:** el GET de SOAT hace `return soat ?? null` (200 + null); el GET de RTM debe **lanzar `NotFoundException` (404)** cuando el RPC `findTecnomecanicaByVehicle` devuelve `null`, para preservar la convención `404 → Right(null) → empty` del frontend. Importar `CreateTecnomecanicaDto` desde el DTO del gateway.
7. **Tests.** Crear `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` espejo de `soat.service.spec.ts`, cubriendo upsert (incl. rechazo de `expiry <= start` y de no-dueño), find (con y sin documento), delete (incl. 404) y expiring (ventana de días). Ejecutar la suite del MS.
8. **Verificación local.** `npm run build` (o el equivalente del repo) en `vehicles-ms` y `api-gateway` sin errores TS; tests verdes; lint sin nuevos warnings. SOAT sigue verde sin tocar su acceptance.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

Todas las rutas son relativas a `/Users/cami/Developer/Personal/rideglory-api`.

| Acción | Ruta | Qué cambia |
|--------|------|------------|
| Modificar | `vehicles-ms/prisma/schema.prisma` | Añade `model Tecnomecanica` (tabla separada, espejo de `Soat`, con `certificateNumber/cdaName/cdaCode?`). |
| Crear | `vehicles-ms/prisma/migrations/<timestamp>_add_tecnomecanica/migration.sql` | Migración generada por `prisma migrate dev` que crea la tabla `Tecnomecanica`. |
| Crear | `vehicles-ms/src/vehicles/tecnomecanica.service.ts` | `TecnomecanicaService extends PrismaClient`: upsert/find/delete/expiring espejo de `SoatService`. |
| Crear | `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` | Tests unit de upsert/find/delete/expiring. |
| Crear | `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` | DTO de escritura con required/optional explícitos (lado MS). |
| Modificar | `vehicles-ms/src/vehicles/vehicles.controller.ts` | 4 `@MessagePattern` RTM + inyección de `TecnomecanicaService`. |
| Modificar | `vehicles-ms/src/vehicles/vehicles.module.ts` | Registra `TecnomecanicaService` como provider. |
| Crear | `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts` | Gemelo del DTO de escritura (lado gateway), idéntico al del MS. |
| Modificar | `api-gateway/src/vehicles/vehicles.controller.ts` | 3 rutas REST `/tecnomecanica` con Firebase guard; GET lanza 404 si no existe. |

> Verificado en repo: hoy existen `vehicles-ms/src/vehicles/dto/create-soat.dto.ts` **y** `api-gateway/src/vehicles/dto/create-soat.dto.ts` (idénticos). RTM replica ese patrón de DTO duplicado por paquete. `vehicles.module.ts` ya existe en gateway; confirmar el módulo del MS al implementar y registrar el provider donde hoy se registra `SoatService`.

## Contratos / API rideglory-api

### Rutas REST nuevas (api-gateway)

| Método | Path | Auth | Request body | Éxito | Errores |
|--------|------|------|--------------|-------|---------|
| `POST` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | `CreateTecnomecanicaDto` | `200/201` con la RTM persistida | `400` (fechas inválidas / `expiry<=start` / validación DTO), `403` (no es dueño), `404` (vehículo no existe) |
| `GET` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | — | `200` con la RTM | **`404` cuando no hay RTM** (NO `200 + null`) → cliente lo mapea a `Right(null) → empty`; `403` |
| `DELETE` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | — | `200` `{ success: true }` (forma espejo de `deleteSoat`) | `404` (no hay RTM), `403` |

> Diferencia explícita con SOAT: el `GET /soat` actual hace `return soat ?? null` (200 + null). El `GET /tecnomecanica` **debe** responder 404 en ausencia de documento. Esta es una decisión fijada en `05-sintesis.md` (A6) — no es una inconsistencia accidental.

### RPC `@MessagePattern` (vehicles-ms)

`upsertTecnomecanica` (`{ vehicleId, ownerId, dto }`), `findTecnomecanicaByVehicle` (`{ vehicleId, ownerId }`), `deleteTecnomecanica` (`{ vehicleId, ownerId }`), `findTecnomecanicasExpiringIn` (`{ daysUntilExpiry }`). Misma forma de payload que sus equivalentes SOAT (verificado en `vehicles.controller.ts` del MS).

### `CreateTecnomecanicaDto`

| Campo | Tipo | Required | Validadores NestJS | Notas |
|-------|------|----------|--------------------|-------|
| `certificateNumber` | string | **Sí** | `@IsString() @IsNotEmpty()` | nº del certificado RTM |
| `cdaName` | string | **Sí** | `@IsString() @IsNotEmpty()` | nombre del CDA (texto libre) |
| `cdaCode` | string | No | `@IsString() @IsOptional()` | código del CDA |
| `startDate` | string ISO | No | `@IsDateString() @IsOptional()` | opcional; el estado se calcula solo desde `expiryDate` |
| `expiryDate` | string ISO | **Sí (non-null)** | `@IsDateString() @IsNotEmpty()` | vencimiento; siempre presente cuando hay RTM |
| `documentUrl` | string | No | `@IsString() @IsOptional()` | sin OCR; opcional |

> **No replicar el mismatch latente de SOAT.** En `CreateSoatDto` (verificado en repo), `startDate` lleva `@IsDateString()` **sin** `@IsOptional()` e `insurer` es `@IsNotEmpty()`, mientras el cliente Flutter omite nulos — funciona solo porque la UI SOAT los obliga. RTM alinea explícitamente: lo único required server-side es `certificateNumber`, `cdaName` y `expiryDate`; `startDate` es `@IsOptional()`. La UI de Fase 3 debe enviar exactamente este conjunto.

## Cambios de datos / migraciones

**Sí — migración Prisma con creación de tabla.**

- Nueva tabla `Tecnomecanica` en la BD de `vehicles-ms` (tabla **separada**, no toca `Soat`). Migración generada con `prisma migrate dev --name add_tecnomecanica`.
- **Flujo obligatorio (regla de proyecto / memoria "Deploy workflow"):** correr la migración **local primero** → **validación humana** de que la migración es correcta y SOAT/datos existentes no se ven afectados → solo entonces remoto. **La Fase 2 no cierra hasta la validación humana de la migración local.** La migración remota queda fuera del trabajo automatizado de la fase (la dispara el humano).
- Sin backfill de datos (tabla nueva, vacía). Sin cambios en `model Soat` ni en otras tablas.

## Criterios de aceptacion (numerados, observables, testeables)

1. Existe `model Tecnomecanica` en `schema.prisma` con `vehicleId @unique`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate?`, `expiryDate`, `documentUrl?`, `createdAt`, `updatedAt`; `model Soat` queda byte-idéntico.
2. `prisma migrate dev` genera una migración que crea `Tecnomecanica` y **no** altera `Soat`; corre sin error en local.
3. Las **3 rutas** `/api/vehicles/:vehicleId/tecnomecanica` (POST/GET/DELETE) están protegidas por el mismo Firebase Auth guard que las de SOAT (sin token → 401/403).
4. `validateVehicleOwnership` se invoca en **upsert, find y delete**: un usuario que no es dueño del vehículo recibe `403` en las tres operaciones (espejo de SOAT).
5. El upsert rechaza con `400` cuando `expiryDate <= startDate` (validación server-side), y persiste correctamente cuando `startDate` se omite (es opcional).
6. `GET /tecnomecanica` responde **`404`** cuando no existe RTM para el vehículo (verificable con curl/test e2e), **no** `200` con cuerpo `null`.
7. `DELETE /tecnomecanica` responde `404` cuando no hay RTM y `{ success: true }` cuando borra (forma espejo de `deleteSoat`).
8. `CreateTecnomecanicaDto` rechaza con `400` un body sin `certificateNumber`, sin `cdaName` o sin `expiryDate`; **acepta** un body sin `startDate`, `cdaCode` ni `documentUrl`. El DTO existe idéntico en `api-gateway` y `vehicles-ms`.
9. `findTecnomecanicasExpiringIn(days)` devuelve solo las RTM cuyo `expiryDate` cae en la ventana UTC día-exacto de `days` (misma lógica que `findSoatsExpiringIn`).
10. `tecnomecanica.service.spec.ts` cubre upsert (éxito, `expiry<=start`, no-dueño), find (con/sin documento), delete (éxito, 404) y expiring; la suite del MS pasa verde.
11. Build TS de `vehicles-ms` y `api-gateway` sin errores; lint sin **nuevos** warnings.
12. La suite SOAT del backend sigue verde **sin tocar su acceptance** (regresión cero); ningún `NotificationType` ni cron fue añadido en esta fase.
13. La migración local fue **validada por un humano** antes de cerrar la fase (gate explícito, no automatizable).

## Pruebas (unitarias/widget/integracion)

- **Unitarias (`vehicles-ms`):** `tecnomecanica.service.spec.ts` espejo de `soat.service.spec.ts` — casos de los criterios 4, 5, 6/7 (a nivel service: delete sin registro lanza la excepción), 9, 10. Mockear `PrismaClient`/`validateVehicleOwnership` igual que en el spec de SOAT.
- **Contrato / validación DTO:** test (o e2e) que confirme el criterio 8 (required/optional del DTO). Si el repo prueba DTOs vía pipe de validación, espejar ese patrón; si no, cubrir con un caso e2e de gateway.
- **Integración / e2e gateway (en la medida que el repo lo soporte):** POST→GET→DELETE feliz; GET sin documento → 404 (criterio 6); acceso de no-dueño → 403 (criterio 4); falta token → no autorizado (criterio 3).
- **Regresión SOAT:** ejecutar `soat.service.spec.ts` y la suite de gateway de SOAT sin modificar sus assertions (criterio 12).
- **Verificación manual de migración:** humano corre la migración local y confirma estado de la BD (criterio 13).

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | Migración irreversible / dañar datos al tocar el schema. | Alta | Tabla **separada** (no altera `Soat`); flujo local → validación humana → remoto; la fase no cierra sin validación humana local (criterio 13). |
| R2 | Replicar el mismatch latente de SOAT (`startDate`/`insurer` required server-side que el cliente omite) → `400` silencioso en RTM. | Media | `CreateTecnomecanicaDto` fija required/optional explícitos; solo `certificateNumber`/`cdaName`/`expiryDate` required; `startDate` `@IsOptional()`. Alineado con la UI de Fase 3. |
| R3 | GET copiado tal cual de SOAT (`return soat ?? null`) rompe la cadena `404 → empty` del frontend. | Media | Paso 6 obliga `NotFoundException` en GET de RTM; criterio 6 lo verifica observable. |
| R4 | DTO duplicado (gateway + ms) se desincroniza. | Baja-Media | Mantener ambos archivos idénticos; revisar en el diff los dos a la vez (igual patrón que `create-soat.dto.ts`). |
| R5 | Front (Fase 3) bloqueado esperando la migración remota. | Baja-Media | Fase 3 puede desarrollarse contra el contrato/mock mientras se valida la migración local; el contrato queda congelado en esta fase. |
| R6 | Romper SOAT backend al editar `vehicles.controller.ts`/`vehicles.module.ts` compartidos. | Media | Solo se **añaden** patterns/providers, no se tocan los de SOAT; criterio 12 exige suite SOAT verde sin cambiar acceptance. |

## Dependencias (fases prerequisito y por que)

- **Depende de Fase 1.** Fase 1 fija las decisiones de arquitectura del frontend (ADR-A..F) y, en particular, el contrato de campos que la UI consumirá (`expiryDate` non-null como única fuente del estado, `startDate` opcional). El `CreateTecnomecanicaDto` de esta fase debe alinear required/optional con esa decisión de UI; definir el contrato backend antes de que el frontend lo necesite es válido, pero las decisiones de modelo (qué es opcional, 404→empty) provienen de Fase 1. Esta fase produce el contrato que **Fases 3 y 5 consumen** (Fase 3 = front RTM; Fase 5 = `findTecnomecanicasExpiringIn` para los crons).

## Ejecucion recomendada (nivel rg-exec: full)

**Por qué ese nivel:** Cambio de contrato `rideglory-api` + migración Prisma de datos (tabla nueva) + auth/ownership/PII central. La migración local→humano→remoto es difícil de revertir. Aunque el servicio es copia mecánica de SOAT, la rúbrica clasifica migraciones y cambios de contrato sensibles como **full** independientemente de lo mecánica que sea la escritura. El nivel full habilita auditoría adversarial e iteración con fix-loops para garantizar: que el GET 404 no se copió tal cual de SOAT, que el DTO no replica el mismatch latente, que `validateVehicleOwnership` está en las tres operaciones, y que SOAT no sufre regresión. El gate de validación humana de la migración es no automatizable y bloquea el cierre.
