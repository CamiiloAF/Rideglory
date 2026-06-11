# Backend → QA/Frontend (ai-quota-system)

_Timestamp: 2026-06-05T23:59:10Z_

## Baseline

Corrí `cd api-gateway && npx jest --testPathPatterns=ai` antes de tocar código:

- **Test Suites:** 4 passed, 4 total
- **Tests:** 27 passed, 27 total
- Sin errores de TypeScript (`npx tsc --noEmit` limpio)

## Archivos cambiados

### rideglory-api (backend)

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `rideglory-contracts/src/ai/enums/ai.enums.ts` | modify | Agregados `QUOTA_EXCEEDED_USER` y `QUOTA_EXCEEDED_PROJECT` al enum `AiErrorCode` |
| `api-gateway/src/ai/gemini.service.ts` | modify | `generateDescription`: catch mapea RESOURCE_EXHAUSTED → `QUOTA_EXCEEDED_PROJECT`; `generateCover`: wrap try/catch completo con mapeo safety / quota_project / network_error |
| `api-gateway/src/ai/ai-quota.service.ts` | create | Nuevo servicio: cuota diaria por usuario en Firestore con `runTransaction`, caché de límites desde Remote Config (5 min), lanza `HttpException(429)` al exceder |
| `api-gateway/src/ai/ai.module.ts` | modify | Import `AuthModule` (init order), agrega `AiQuotaService` a providers |
| `api-gateway/src/ai/ai.controller.ts` | modify | Inyecta `AiQuotaService`; `generateDescription` requiere `@Req()` para `userId`; ambos endpoints llaman `checkAndIncrement` antes de Gemini; mapeo completo de 4 errores en catch; `remainingGenerations` viene del servicio de cuota |
| `api-gateway/src/ai/ai.controller.spec.ts` | modify | Actualizado para inyectar `mockQuotaService`; `generateDescription` recibe `fakeRequest`; nuevos tests: quota_exceeded_user, quota_exceeded_project para description y cover; `remainingGenerations` dinámico |
| `api-gateway/src/ai/gemini.service.spec.ts` | modify | Nuevos tests: `quota_exceeded_project` por RESOURCE_EXHAUSTED / "Resource has been exhausted", safety_blocked por SAFETY finishReason, network_error genérico — en generateCover y generateDescription |
| `api-gateway/src/ai/ai-quota.service.spec.ts` | create | Tests unitarios del servicio de cuota: límite no alcanzado, doc nuevo, límite alcanzado (429), cover quota, fallback RC, caché 5 min |

> Nota: después de modificar `ai.enums.ts` se requirió `cd rideglory-contracts && npm run build` para que los tests resolvieran los nuevos valores del enum.

## Pruebas nuevas

**ai.controller.spec.ts** — 7 nuevos tests:
- `generateDescription — quota_exceeded_project → 429`
- `generateDescription — quota_exceeded_user → 429` (propagado desde quota service)
- `generateCover — success 200` (reescrito: verifica `remainingGenerations` dinámico y `checkAndIncrement`)
- `generateCover — safety_blocked → 422`
- `generateCover — quota_exceeded_project → 429`
- `generateCover — quota_exceeded_user → 429`
- `generateCover — network_error → 503`

**gemini.service.spec.ts** — 7 nuevos tests:
- `generateCover`: quota_exceeded_project (RESOURCE_EXHAUSTED), quota_exceeded_project ("Resource has been exhausted"), safety_blocked (SAFETY finishReason), network_error genérico
- `generateDescription`: quota_exceeded_project (RESOURCE_EXHAUSTED), quota_exceeded_project ("Resource has been exhausted"), network_error genérico

**ai-quota.service.spec.ts** — 7 nuevos tests:
- description: under limit (returns remaining=6), doc no existe (remaining=9), at limit → 429
- cover: at limit → 429, under limit (remaining=2)
- getLimits: fallback cuando RC falla, caché (getTemplate llamado 1 vez)

## Resultado final

```
Test Suites: 5 passed, 5 total
Tests:       47 passed, 47 total  (baseline: 27)
npx tsc --noEmit: limpio
```

## Verificación manual

Para probar el sistema de cuota de extremo a extremo en dev:

1. Configurar en Firebase Remote Config: `ai_description_daily_limit = "2"`, `ai_cover_daily_limit = "1"`.
2. Publicar los cambios en RC.
3. Llamar `POST /ai/description` dos veces con el mismo usuario → la segunda debe retornar `remainingGenerations: 0`.
4. Llamar `POST /ai/description` una tercera vez → debe retornar `HTTP 429 { error: "quota_exceeded_user", remaining: 0 }`.
5. Verificar en Firestore: `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` → `descriptionCount: 2`.
6. Para probar `quota_exceeded_project`: simular escenario de cuota Gemini agotada (o mockear en test de integración).

## Notas Frontend/QA

- **Nuevo campo en respuesta 200:** `remainingGenerations` es ahora un número real (≥ 0), ya no `-1`. El frontend puede mostrar un contador al usuario.
- **HTTP 429 con `error: "quota_exceeded_user"`:** el cuerpo incluye `{ error, remaining: 0 }`. Mostrar mensaje de "límite diario alcanzado".
- **HTTP 429 con `error: "quota_exceeded_project"`:** cuota Gemini del proyecto agotada. Mostrar mensaje genérico de servicio no disponible.
- **`generateDescription` ahora requiere autenticación** para extraer `userId` del token. Si antes se llamaba sin Auth header en tests de integración, agregar el header.
- **Remote Config IAM:** la service account necesita `roles/remoteconfig.viewer` para que `getLimits()` funcione; si no, usa fallbacks (description=10, cover=5).
- **TTL documentos Firestore:** cada doc `ai_usage_quotas/{userId}/days/{day}` tiene campo `expireAt` a 2 días. Se puede configurar un TTL en Firestore Console para limpieza automática.
