# Migration Plan — ai-quota-system

**Generado:** 2026-06-05T23:44:51Z

## Cambios de base de datos

### Prisma
No hay cambios de schema Prisma. Esta fase no toca ningún microservicio ni api-gateway Prisma.

### Firestore (infra manual)

**Estructura de colección:**
```
ai_usage_quotas/
  {userId}/
    days/
      {YYYY-MM-DD}/   ← documentos con TTL
        descriptionCount: number
        coverCount: number
        createdAt: Timestamp
        expireAt: Timestamp  ← campo TTL (createdAt + 2 días)
```

**No se requiere creación manual de colecciones** — Firestore crea las colecciones y documentos on-demand cuando `AiQuotaService.checkAndIncrement()` hace su primer write.

**TTL policy (acción única antes del primer deploy en producción):**

```bash
# Configurar TTL en el collection-group "days"
gcloud firestore fields ttls update expireAt \
  --collection-group=days \
  --project=<FIREBASE_PROJECT_ID>

# Verificar
gcloud firestore fields ttls describe expireAt \
  --collection-group=days \
  --project=<FIREBASE_PROJECT_ID>
```

Nota: La TTL policy en Firestore puede tardar 24 horas en activarse. Los documentos con `expireAt` en el pasado serán eliminados automáticamente una vez activa.

**Índices Firestore:** No se requieren índices adicionales — las queries son by-document-path (no range queries ni composite).

## Remote Config (acción antes del deploy)

Crear los siguientes parámetros en Firebase Remote Config Console:

| Parámetro | Tipo | Valor inicial | Descripción |
|-----------|------|---------------|-------------|
| `ai_description_daily_limit` | String | `"10"` | Máx generaciones de descripción por usuario por día |
| `ai_cover_daily_limit` | String | `"5"` | Máx generaciones de portada por usuario por día |

El código usa `parseInt(value)` con fallback `10`/`5` si el parámetro no existe o no parsea.
