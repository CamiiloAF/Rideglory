# Architect handoff — rtm-backend-persistencia

**Date:** 2026-06-04T17:32:49Z
**Status:** done

---

## Decisiones

| ID | Decisión | Razonamiento |
|----|----------|--------------|
| A1 | `model Tecnomecanica` como tabla separada (no discriminador `kind`) | Constraint heredado PRD §7; fijado en 05-sintesis A6. |
| A2 | DTO duplicado: `create-tecnomecanica.dto.ts` existe idéntico en `api-gateway` y `vehicles-ms` | Espejo del patrón `create-soat.dto.ts` existente. |
| A3 | `startDate` marcado `@IsOptional()` en el DTO de RTM (corrección vs SOAT) | SOAT tiene `startDate: string` sin `@IsOptional()` — mismatch latente. RTM lo corrige de raíz. Cuando `startDate` se omite, el servicio omite la validación `expiry > start` y hace upsert sin `startDate`. |
| A4 | `GET /tecnomecanica` lanza `NotFoundException` (HTTP 404) cuando no existe RTM | SOAT devuelve `200 + null`; RTM mejora esto explícitamente. El gateway debe atrapar el `RpcException{status:404}` del MS (igual que en otros endpoints) y la NotFoundException HTTP se lanza en el gateway. |
| A5 | `TecnomecanicaService` extiende `PrismaClient` e implementa `OnModuleInit` | Mismo patrón que `SoatService`; no introduce nueva abstracción. |
| A6 | Tests en `tecnomecanica.service.spec.ts` siguen el patrón pure-logic del `soat.service.spec.ts` existente (sin mock de Prisma) | `soat.service.spec.ts` prueba lógica pura (date validation, expiry window) sin instanciar el servicio ni Prisma. `tecnomecanica.service.spec.ts` sigue ese mismo patrón. |
| A7 | La migración Prisma es local-first con gate humano antes de tocar remoto | Constraint PRD §7; la fase no cierra sin validación humana. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `vehicles-ms/prisma/schema.prisma` | modify | Añade `model Tecnomecanica` debajo de `model Soat` | low |
| `vehicles-ms/prisma/migrations/<ts>_add_tecnomecanica/migration.sql` | create | Migración generada por `prisma migrate dev` | med |
| `vehicles-ms/src/vehicles/tecnomecanica.service.ts` | create | Lógica CRUD + `findTecnomecanicasExpiringIn` | low |
| `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` | create | Unit tests pure-logic | low |
| `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` | create | DTO escritura del MS | low |
| `vehicles-ms/src/vehicles/vehicles.controller.ts` | modify | Añade 4 `@MessagePattern` RTM + inyecta `TecnomecanicaService` | low |
| `vehicles-ms/src/vehicles/vehicles.module.ts` | modify | Registra `TecnomecanicaService` en `providers` | low |
| `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts` | create | DTO escritura del gateway (idéntico al del MS) | low |
| `api-gateway/src/vehicles/vehicles.controller.ts` | modify | Añade 3 rutas REST RTM con Firebase Auth implícito + GET 404 | low |

**Archivos NO tocados:** `soat.service.ts`, `soat.service.spec.ts`, `create-soat.dto.ts` (ambas copias), `model Soat` en schema, `api-gateway/vehicles.module.ts`.

---

## Contratos rideglory-api

### `POST /api/vehicles/:vehicleId/tecnomecanica`

- **Auth:** Firebase guard (idéntico a SOAT; `getAuthenticatedUser` resuelve el `ownerId`)
- **Request body:** `CreateTecnomecanicaDto`
- **Success:** `201 Created` — objeto `Tecnomecanica` persistido
- **Errors:** `400` (validación DTO o `expiryDate <= startDate`), `401/403` (sin token / no dueño), `404` (vehículo no existe)

### `GET /api/vehicles/:vehicleId/tecnomecanica`

- **Auth:** Firebase guard
- **Success:** `200 OK` — objeto `Tecnomecanica`
- **Errors:** `404` (no existe RTM para el vehículo — `NotFoundException` HTTP), `401/403`

> Diferencia crítica vs SOAT: `getSoat` devuelve `soat ?? null` (200 con body null cuando no existe). `getTecnomecanica` debe lanzar `NotFoundException` cuando `findTecnomecanicaByVehicle` retorna `null`.

### `DELETE /api/vehicles/:vehicleId/tecnomecanica`

- **Auth:** Firebase guard
- **Success:** `200 OK` — `{ success: true }`
- **Errors:** `404` (no hay RTM), `401/403`

### MessagePatterns del MS (TCP)

| Pattern | Payload | Returns |
|---------|---------|---------|
| `'upsertTecnomecanica'` | `{ vehicleId, ownerId, dto: CreateTecnomecanicaDto }` | `Tecnomecanica` |
| `'findTecnomecanicaByVehicle'` | `{ vehicleId, ownerId }` | `Tecnomecanica \| null` |
| `'deleteTecnomecanica'` | `{ vehicleId, ownerId }` | `{ success: true }` |
| `'findTecnomecanicasExpiringIn'` | `{ daysUntilExpiry: number }` | `Tecnomecanica[]` |

---

## DTO: `CreateTecnomecanicaDto`

```typescript
import { IsDateString, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateTecnomecanicaDto {
  @IsString()
  @IsNotEmpty()
  certificateNumber: string;          // required

  @IsString()
  @IsNotEmpty()
  cdaName: string;                    // required

  @IsString()
  @IsOptional()
  cdaCode?: string;                   // optional

  @IsDateString()
  @IsOptional()
  startDate?: string;                 // optional — corrección vs SOAT

  @IsDateString()
  expiryDate: string;                 // required

  @IsString()
  @IsOptional()
  documentUrl?: string;               // optional
}
```

> Este DTO se crea **idéntico** en `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` y `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts`.

---

## `model Tecnomecanica` (Prisma schema)

```prisma
model Tecnomecanica {
  id                String    @id @default(uuid())
  vehicleId         String    @unique
  certificateNumber String
  cdaName           String
  cdaCode           String?
  startDate         DateTime?
  expiryDate        DateTime
  documentUrl       String?
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
}
```

---

## Datos / Migraciones

Ver `analysis/MIGRATION_PLAN.md` para el plan detallado.

**Resumen:**
1. El desarrollador backend añade `model Tecnomecanica` al `schema.prisma`.
2. Ejecuta `cd vehicles-ms && npx prisma migrate dev --name add_tecnomecanica` localmente — esto genera `migrations/<ts>_add_tecnomecanica/migration.sql`.
3. El humano valida que la migración crea `Tecnomecanica` y NO altera `Soat` (diff de `schema.prisma` solo añade líneas).
4. Gate: la fase no cierra sin esa validación humana.
5. Migración remota: responsabilidad del humano, fuera del scope automatizado.

---

## Env

No se requieren nuevas variables de entorno. La `DATABASE_URL` ya existe en `vehicles-ms`.

Ver `analysis/ENV_DELTA.md` — delta vacío confirmado.

---

## Riesgos

| Riesgo | Mitigación |
|--------|------------|
| La validación `expiry > start` en RTM asume que si `startDate` es undefined, se omite la comparación | `TecnomecanicaService.upsertTecnomecanica` solo llama `parseDate(startDate)` y valida si `startDate` está presente; de lo contrario salta la validación de fechas. |
| `GET /tecnomecanica` 404 vs SOAT 200+null — el Flutter frontend de Fase 3 debe esperar 404 y mapear a `empty()` | Documentado en contratos; el desarrollador Flutter de Fase 3 debe leer este handoff antes de implementar el servicio Retrofit. |
| `soat.service.spec.ts` usa pure-logic sin mock de Prisma; si el patrón cambia, los tests de RTM quedan inconsistentes | Ambas suites deben seguir el mismo patrón. |
| Migración remota no automatizada — riesgo de drift si el humano no la ejecuta antes del deploy | Gate explícito en criterio 13 del PRD. |

---

## Orden de implementación

1. `vehicles-ms/prisma/schema.prisma` — añadir `model Tecnomecanica`
2. Ejecutar migración local (gate humano)
3. `vehicles-ms/src/vehicles/dto/create-tecnomecanica.dto.ts` — crear DTO
4. `vehicles-ms/src/vehicles/tecnomecanica.service.ts` — crear service
5. `vehicles-ms/src/vehicles/vehicles.controller.ts` — añadir 4 MessagePatterns
6. `vehicles-ms/src/vehicles/vehicles.module.ts` — registrar TecnomecanicaService
7. `api-gateway/src/vehicles/dto/create-tecnomecanica.dto.ts` — crear DTO (copia idéntica)
8. `api-gateway/src/vehicles/vehicles.controller.ts` — añadir 3 rutas REST
9. `vehicles-ms/src/vehicles/tecnomecanica.service.spec.ts` — tests
10. Verificar: build TS de ambos paquetes sin errores, suite SOAT sigue verde

---

## Superficie de regresión

- `soat.service.spec.ts` — debe seguir verde sin tocar
- `soat.service.ts`, `create-soat.dto.ts`, `model Soat` — NO se tocan
- Rutas REST SOAT (`POST/GET/DELETE /api/vehicles/:vehicleId/soat`) — sin cambios funcionales
- `@MessagePattern` existentes en `vehicles.controller.ts` (MS) — no se alteran, solo se añaden 4 nuevos
- Build TypeScript de `vehicles-ms` y `api-gateway` — sin errores nuevos
- No se añade `NotificationType` ni cron en esta fase

---

## Fuera de alcance

- Código Flutter / Fase 3
- Recordatorios, crons, `NotificationType` RTM (Fase 5)
- OCR / `documentUrl` autopoblado
- Unificación SOAT + RTM en tabla genérica
- Corrección del mismatch de `startDate` en SOAT (se corrige solo en RTM)
