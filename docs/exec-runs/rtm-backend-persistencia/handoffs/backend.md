# Backend → QA Handoff
Generated: 2026-06-04T17:41:26Z

---

## Baseline

- `soat.service.spec.ts`: 9/9 tests verde antes de cualquier cambio.
- `tsc --noEmit` en `vehicles-ms` y `api-gateway`: sin errores.

---

## Archivos cambiados

### vehicles-ms

| Archivo | Accion |
|---------|--------|
| `prisma/schema.prisma` | Añadido `model Tecnomecanica` después de `model Soat`; `model Soat` byte-idéntico |
| `prisma/migrations/20260604173849_add_tecnomecanica/migration.sql` | Migración creada con `prisma migrate diff` — solo crea la tabla `Tecnomecanica` y su índice único sobre `vehicleId` |
| `src/vehicles/dto/create-tecnomecanica.dto.ts` | Nuevo DTO con `startDate` `@IsOptional()` (corrección deliberada vs SOAT) |
| `src/vehicles/tecnomecanica.service.ts` | Service completo: upsert, find, delete, expiringIn |
| `src/vehicles/tecnomecanica.service.spec.ts` | 18 tests pure-logic |
| `src/vehicles/vehicles.controller.ts` | 4 `@MessagePattern` RTM + inyección `TecnomecanicaService`; ningún pattern existente modificado |
| `src/vehicles/vehicles.module.ts` | `TecnomecanicaService` en `providers[]` |

### api-gateway

| Archivo | Accion |
|---------|--------|
| `src/vehicles/dto/create-tecnomecanica.dto.ts` | Copia idéntica del DTO del MS |
| `src/vehicles/vehicles.controller.ts` | 3 rutas REST con Firebase Auth implícito; GET lanza `NotFoundException` si `rtm` es null |

---

## Pruebas nuevas

`tecnomecanica.service.spec.ts` — 18 tests:

**upsert — date validation (7 tests)**
- Acepta expiry > start
- Rechaza expiry == start
- Rechaza expiry < start
- Acepta sin startDate (optional)
- Rechaza expiryDate inválida
- Rechaza startDate inválida cuando se provee
- Acepta ISO-8601 datetime completo

**find — ownership (3 tests)**
- Retorna registro cuando owner coincide
- Retorna null cuando owner coincide pero no hay RTM
- Retorna 403 cuando owner no coincide

**delete (3 tests)**
- `{ success: true }` cuando existe y owner coincide
- 404 cuando no existe RTM
- 403 cuando owner no coincide

**findTecnomecanicasExpiringIn — expiry window (5 tests)**
- Detecta RTM expirando exactamente hoy (day 0)
- No coincide RTM expirando en 2 días al chequear day 0
- Detecta RTM expirando en 7 días
- No coincide RTM ya expirada
- No coincide RTM en 30 días al chequear day 7

---

## Resultado final

```
Test Suites: 2 passed, 2 total
Tests:       27 passed, 27 total (9 SOAT + 18 RTM)
tsc --noEmit: 0 errores (vehicles-ms + api-gateway)
```

---

## Verificacion manual (gate humano)

La migración fue aplicada manualmente al DB local `vehicles` en `localhost:5430`:

```bash
# SQL aplicado directamente
psql ... -f migrations/20260604173849_add_tecnomecanica/migration.sql
# Output: CREATE TABLE / CREATE INDEX

# Verificación
psql ... -c "\dt"
# Muestra: Soat, Tecnomecanica, Vehicle, _prisma_migrations
```

Diff del schema confirma que `Tecnomecanica` es la única tabla nueva; `Soat` no fue alterada.

**Nota sobre migración remota:** La migración remota es responsabilidad del humano. El archivo SQL está en `vehicles-ms/prisma/migrations/20260604173849_add_tecnomecanica/migration.sql`. Ejecutar con `prisma migrate deploy` (no `migrate dev`) en producción.

---

## Notas Frontend / QA

### Contratos de API

**POST** `/api/vehicles/:vehicleId/tecnomecanica` → 201
```json
{
  "certificateNumber": "string (required)",
  "cdaName": "string (required)",
  "cdaCode": "string (optional)",
  "startDate": "ISO-8601 (optional)",
  "expiryDate": "ISO-8601 (required)",
  "documentUrl": "string (optional)"
}
```

**GET** `/api/vehicles/:vehicleId/tecnomecanica` → 200 con objeto RTM, o **404** si no existe.
- Diferencia deliberada con SOAT: SOAT devuelve `200 + null`; RTM devuelve `404`. El Flutter debe manejar `404 → Right(null) → ResultState.empty()`.

**DELETE** `/api/vehicles/:vehicleId/tecnomecanica` → `{ "success": true }` o 404.

### Seguridad
- Las 3 rutas REST en api-gateway están protegidas por el mismo Firebase Auth guard que SOAT (middleware `FirebaseAuthMiddleware`).
- `validateVehicleOwnership` se invoca en upsert, find y delete; responde 403 si el vehicle no pertenece al usuario autenticado.

### Scheduler futuro (Fase 5)
- `findTecnomecanicasExpiringIn(days)` está disponible via `@MessagePattern('findTecnomecanicasExpiringIn')` en el MS.
- Misma ventana UTC día-exacto que `findSoatsExpiringIn`.

### Regresión SOAT
- `soat.service.spec.ts`: 9/9 verde sin modificaciones.
- Ninguna ruta SOAT ni MessagePattern SOAT fue alterada.
