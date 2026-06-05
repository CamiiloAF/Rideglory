# Migration Plan — add_tecnomecanica

**Phase:** rtm-backend-persistencia
**Date:** 2026-06-04T17:32:49Z

## Scope

Una sola migración que crea la tabla `Tecnomecanica`. No altera `Soat` ni `Vehicle`.

## Pasos locales (para el desarrollador backend)

```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms

# 1. Verificar estado limpio de schema antes de migrar
git diff prisma/schema.prisma   # solo debe mostrar el model Tecnomecanica añadido

# 2. Generar y aplicar migración local
npx prisma migrate dev --name add_tecnomecanica

# 3. Regenerar cliente Prisma (se hace automáticamente con migrate dev)
# npx prisma generate   # solo si es necesario

# 4. Verificar que la migración NO alteró Soat
cat prisma/migrations/<ts>_add_tecnomecanica/migration.sql
# Debe contener solo CREATE TABLE "Tecnomecanica" + CREATE UNIQUE INDEX
# NO debe contener ALTER TABLE "Soat" ni DROP/ALTER de columnas existentes
```

## SQL esperado en la migración

```sql
-- CreateTable
CREATE TABLE "Tecnomecanica" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "certificateNumber" TEXT NOT NULL,
    "cdaName" TEXT NOT NULL,
    "cdaCode" TEXT,
    "startDate" TIMESTAMP(3),
    "expiryDate" TIMESTAMP(3) NOT NULL,
    "documentUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Tecnomecanica_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Tecnomecanica_vehicleId_key" ON "Tecnomecanica"("vehicleId");
```

## Gate humano (criterio 13 del PRD)

Antes de cerrar la fase, un humano debe:
1. Revisar el SQL generado y confirmar que solo crea `Tecnomecanica`.
2. Confirmar que la suite `npm test` pasa verde en `vehicles-ms`.
3. Solo después de esa validación se puede proceder a la migración remota.

## Migración remota

Fuera del scope automatizado. Responsabilidad del humano.
```bash
# En el entorno de producción/staging:
npx prisma migrate deploy
```
