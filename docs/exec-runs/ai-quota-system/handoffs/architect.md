# Architect handoff — ai-quota-system

**Date:** 2026-06-05T23:44:51Z
**Status:** done
**Slug:** ai-quota-system
**Nivel:** normal

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| D-1 | `AiModule` importa `AuthModule` (no re-declara `FirebaseAuthService` como provider propio) | `FirebaseAuthService` ya está exportado por `AuthModule`; importar el módulo es la forma NestJS correcta de garantizar que su constructor (que llama `initializeApp()`) corra antes que `AiQuotaService`. Evita una segunda instancia. |
| D-2 | `AiQuotaService` accede a Firebase via `getApps()[0]` sin inyectar `FirebaseAuthService` | Patrón explícito del PRD; el App singleton ya existe por D-1. |
| D-3 | `GeminiService.generateCover()` recibe un bloque try/catch con mapeo a `AiErrorCode` | `generateCover` actualmente no tiene manejo de errores — cualquier error de Gemini (429, SAFETY, timeout) burbujea sin mapear. Consistencia con `generateDescription`. |
| D-4 | Detección de quota de proyecto (Gemini 429) en `GeminiService`, no en `AiController` | El SDK de Gemini (`@google/genai`) lanza un objeto Error con campo `status` o mensaje "Resource has been exhausted" / "429" — `GeminiService` es la capa correcta para inspeccionar errores del SDK y lanzar `Error(AiErrorCode.QUOTA_EXCEEDED_PROJECT)`. El controller solo mapea `AiErrorCode` → `HttpException`. |
| D-5 | No se crea `ai-quota-error-response.dto.ts` separado | `AiErrorResponseDto` ya existe en contracts con campo `error: AiErrorCode`; es suficiente. Solo se agregan los 2 nuevos valores al enum. |
| D-6 | Caché en memoria del Remote Config: `Map<string, { value: number; expireAt: number }>` con TTL 5 min | No hay librería de caché en api-gateway; patrón manual es simple y cumple el requisito. |
| D-7 | Transacción Firestore con `runTransaction` + `transaction.get` + `transaction.set` | Garantiza atomicidad para dos llamadas concurrentes del mismo usuario (AC-4). Sin rollback en fallo Gemini (AC-10). |

---

## Change map

| Repositorio | Archivo | Acción | Razón | Risk |
|-------------|---------|--------|-------|------|
| `rideglory-api` | `rideglory-contracts/src/ai/enums/ai.enums.ts` | MODIFY | Agregar `QUOTA_EXCEEDED_USER` y `QUOTA_EXCEEDED_PROJECT` al enum `AiErrorCode` | low |
| `rideglory-api` | `api-gateway/src/ai/ai-quota.service.ts` | CREATE | Servicio de cuota diaria: Firestore + Remote Config + caché 5 min | med |
| `rideglory-api` | `api-gateway/src/ai/ai.module.ts` | MODIFY | Importar `AuthModule`; agregar `AiQuotaService` a providers | low |
| `rideglory-api` | `api-gateway/src/ai/ai.controller.ts` | MODIFY | Inyectar `AiQuotaService`; `checkAndIncrement()` antes de cada llamada Gemini; mapear `quota_exceeded_project` HTTP 429 en ambos endpoints; error handling en `generateCover` | med |
| `rideglory-api` | `api-gateway/src/ai/gemini.service.ts` | MODIFY | Agregar detección de Gemini 429 (`QUOTA_EXCEEDED_PROJECT`) en `generateDescription`; agregar try/catch completo en `generateCover` | low |

**No cambia:** `flutter/lib/`, `events-ms/`, `users-ms/`, `vehicles-ms/`, Prisma schema, `firebase-auth.service.ts`, `/events/generate-cover` (legacy).

---

## Contratos

### Contratos existentes (sin breaking changes)

```
POST /ai/description
  Auth: Bearer <Firebase ID Token>
  Request:  AiDescriptionRequestDto  (sin cambios)
  Response 200: { markdown: string, remainingGenerations: number }   ← era -1, ahora límite real
  Response 422: { error: "safety_blocked" }                          (sin cambios)
  Response 429: { error: "quota_exceeded_user", remaining: 0 }       ← NUEVO
  Response 429: { error: "quota_exceeded_project" }                  ← antes era 503
  Response 503: { error: "network_error" }                           (sin cambios)

POST /ai/cover
  Auth: Bearer <Firebase ID Token>
  Request:  AiCoverRequestDto  (sin cambios)
  Response 200: { imageUrl: string, remainingGenerations: number }   ← era -1, ahora real
  Response 422: { error: "safety_blocked" }                          ← NUEVO (antes sin mapear)
  Response 429: { error: "quota_exceeded_user", remaining: 0 }       ← NUEVO
  Response 429: { error: "quota_exceeded_project" }                  ← NUEVO (antes sin mapear)
  Response 503: { error: "network_error" }                           ← NUEVO (antes sin mapear)
```

**Campo `remainingGenerations`:**
- Fórmula: `limit - currentCountAfterIncrement`
- Si `limit=10` y el request es el tercero del día → `remainingGenerations = 7`
- Tipo: `number` (ya existe en DTOs de contracts)

**Semántica del 429 dual:**
- `quota_exceeded_user` (HTTP 429): el usuario agotó su cuota diaria (límite de Remote Config)
- `quota_exceeded_project` (HTTP 429): Gemini API devolvió 429 (cuota del proyecto en Google AI)

### Enum additions (`ai.enums.ts`)

```typescript
export enum AiErrorCode {
  NETWORK_ERROR = 'network_error',
  SAFETY_BLOCKED = 'safety_blocked',
  QUOTA_EXCEEDED_USER = 'quota_exceeded_user',    // NUEVO
  QUOTA_EXCEEDED_PROJECT = 'quota_exceeded_project', // NUEVO
}
```

---

## Datos / migraciones

**No hay cambios en Prisma.** No hay `prisma migrate`.

**Firestore** (infra manual, no código):
- Colección raíz: `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}`
- Documento fields: `descriptionCount: number`, `coverCount: number`, `createdAt: Timestamp`, `expireAt: Timestamp`
- `expireAt = createdAt + 2 días`
- **TTL policy** (acción manual única, antes del primer deploy):
  ```bash
  gcloud firestore fields ttls update expireAt \
    --collection-group=days \
    --project=<PROJECT_ID>
  ```
- Verificar: `gcloud firestore fields ttls describe expireAt --collection-group=days --project=<PROJECT_ID>`

Ver `docs/exec-runs/ai-quota-system/analysis/MIGRATION_PLAN.md` para instrucciones completas.

---

## Env

**Remote Config** (Firebase Console — acción manual antes del deploy):
- `ai_description_daily_limit`: String numérico (ej: `"10"`)
- `ai_cover_daily_limit`: String numérico (ej: `"5"`)

**Fallbacks defensivos en código:** `10` y `5` respectivamente. Si Remote Config no está disponible o el valor no es parseable, el fallback se usa silenciosamente.

**Rol IAM requerido** (solo si el service account actual no lo tiene):
- `roles/remoteconfig.viewer` en el proyecto GCP para que `firebase-admin` pueda leer `getRemoteConfig(app).getTemplate()`.

Ver `docs/exec-runs/ai-quota-system/analysis/ENV_DELTA.md` para detalles.

---

## Riesgos

| Riesgo | Severidad | Mitigación |
|--------|-----------|-----------|
| `getApps()[0]` llamado antes que `FirebaseAuthService` inicialice | alta | D-1: importar `AuthModule` garantiza el orden de módulos en NestJS |
| Gemini SDK cambia el formato de error 429 | media | Detectar por múltiples heurísticas: status code HTTP del error, mensaje "Resource has been exhausted", `error.status === 429`; fallback a `NETWORK_ERROR` |
| `getRemoteConfig(app).getTemplate()` requiere rol IAM `remoteConfig.viewer` | media | Documentar en ENV_DELTA; si falta, el service fallback a hardcoded limits (no crash) |
| Dos llamadas concurrentes superan el límite | alta | `runTransaction` en Firestore garantiza atomicidad — AC-4 |
| Test `ai.controller.spec.ts` existente rompe con nuevo signature del constructor | media | Tests actuales mockean `GeminiService` y `StorageService`; agregar mock de `AiQuotaService` en `beforeEach` — cambio aditivo, no destructivo |

---

## Orden de implementación

1. `rideglory-contracts/src/ai/enums/ai.enums.ts` — agregar 2 valores al enum (sin breaking changes; requiere rebuild de contracts)
2. `api-gateway/src/ai/gemini.service.ts` — agregar detección de `QUOTA_EXCEEDED_PROJECT` y error handling en `generateCover`
3. `api-gateway/src/ai/ai-quota.service.ts` — crear el servicio completo
4. `api-gateway/src/ai/ai.module.ts` — importar `AuthModule` + registrar `AiQuotaService`
5. `api-gateway/src/ai/ai.controller.ts` — inyectar `AiQuotaService` + integrar quota + mapeo de errores

**Rationale:** contracts primero porque `ai-quota.service.ts` importa los nuevos `AiErrorCode` values; `gemini.service.ts` antes del controller porque el controller depende de los tipos de error que `GeminiService` lanza; el módulo antes del controller para que DI esté configurado.

---

## Superficie de regresión

- `ai.controller.spec.ts` (182 líneas) — requiere mock adicional de `AiQuotaService`; tests existentes son aditivos
- `gemini.service.spec.ts` — puede requerir casos nuevos para `generateCover` error paths y `QUOTA_EXCEEDED_PROJECT`
- `AuthModule` — solo se importa en `AiModule`; `FirebaseAuthService` no se modifica
- `APP_GUARD` de `FirebaseAuthGuard` — global en `AppModule`; no afectado
- Endpoints legacy `/events/generate-cover` — sin cambios

---

## Fuera de alcance

- Eliminación de `ClaudeService`, `UnsplashService`, ni `/events/generate-cover` (Fase 5)
- Lógica Flutter de cuota (Fases 4 y 5) — la app mostrará `remainingGenerations` cuando el backend lo emita
- `GeminiService.generateDescription()` ni `generateCover()` implementación base (Fases 1 y 2 — ya completo)
- Deploy a EC2 (Fase 6)
- Cambios en `docs/features/events.md` (nota de botón inoperativo) — fuera del scope de código; el humano actualiza la doc
