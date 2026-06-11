> Slim handoff — read this before docs/exec-runs/ai-quota-system/handoffs/architect.md

# Architect → Backend (ai-quota-system)

## Repositorio objetivo
`/Users/cami/Developer/Personal/rideglory-api`

## Archivos a tocar (en este orden)

### 1. `rideglory-contracts/src/ai/enums/ai.enums.ts` — MODIFY
Agregar 2 valores al enum existente:
```typescript
QUOTA_EXCEEDED_USER = 'quota_exceeded_user',
QUOTA_EXCEEDED_PROJECT = 'quota_exceeded_project',
```

### 2. `api-gateway/src/ai/gemini.service.ts` — MODIFY
- En `generateDescription()`: dentro del catch general, antes de relanzar `NETWORK_ERROR`, chequear si el error es de cuota de proyecto Gemini (status 429 / mensaje "Resource has been exhausted" / "RESOURCE_EXHAUSTED") → lanzar `Error(AiErrorCode.QUOTA_EXCEEDED_PROJECT)`.
- En `generateCover()`: agregar try/catch completo igual al de `generateDescription` — mapear safety → `SAFETY_BLOCKED`, cuota Gemini → `QUOTA_EXCEEDED_PROJECT`, resto → `NETWORK_ERROR`.

### 3. `api-gateway/src/ai/ai-quota.service.ts` — CREATE
```typescript
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getRemoteConfig } from 'firebase-admin/remote-config';
import { AiErrorCode } from '@rideglory/contracts';

type QuotaType = 'description' | 'cover';

interface CachedLimits {
  description: number;
  cover: number;
  expireAt: number; // Date.now() ms
}
```

**Lógica de `checkAndIncrement(userId: string, type: QuotaType): Promise<number>`:**
1. Leer límites via `getLimits()` (caché 5 min en memoria).
2. Calcular `dayKey = new Date().toISOString().slice(0, 10)` (YYYY-MM-DD, UTC).
3. `docRef = db.collection('ai_usage_quotas').doc(userId).collection('days').doc(dayKey)`
4. `runTransaction`:
   - `get(docRef)`; si no existe → `count = 0`, `created = now`; si existe → `count = snap.data().descriptionCount | coverCount`.
   - Si `count >= limit` → lanzar `new HttpException({ error: AiErrorCode.QUOTA_EXCEEDED_USER, remaining: 0 }, HttpStatus.TOO_MANY_REQUESTS)`.
   - `set(docRef, { descriptionCount | coverCount: count + 1, createdAt: created || now, expireAt: Timestamp 2 días desde createdAt }, { merge: true })`.
   - Retornar `limit - (count + 1)`.

**Lógica de `getLimits(): Promise<CachedLimits>`:**
- Si caché válida (`Date.now() < cache.expireAt`): retornar cache.
- `const app = getApps()[0]`; `const rc = getRemoteConfig(app)`; `const template = await rc.getTemplate()`.
- Parsear `ai_description_daily_limit` y `ai_cover_daily_limit` (defaultValue.value → `parseInt`).
- Fallback: `10` para description, `5` para cover si no existe o no parsea.
- Almacenar en `this.cachedLimits = { description, cover, expireAt: Date.now() + 5 * 60 * 1000 }`.

### 4. `api-gateway/src/ai/ai.module.ts` — MODIFY
```typescript
import { AuthModule } from '../auth/auth.module';
import { AiQuotaService } from './ai-quota.service';

@Module({
  imports: [AuthModule],
  controllers: [AiController],
  providers: [GeminiService, StorageService, StorageCleanupService, AiQuotaService],
})
```
Nota: `AuthModule` va en `imports`, no en `providers`. Esto garantiza que `FirebaseAuthService` (y su `initializeApp()`) se resuelva antes que `AiQuotaService`.

### 5. `api-gateway/src/ai/ai.controller.ts` — MODIFY
- Agregar `AiQuotaService` al constructor.
- En `generateDescription`: antes de llamar `geminiService`, `const remaining = await this.quotaService.checkAndIncrement(userId, 'description')`.  
  - Requiere extraer `userId` del request (igual que `generateCover` ya lo hace con `@Req()`).
  - En el catch: agregar caso `AiErrorCode.QUOTA_EXCEEDED_PROJECT` → `throw new HttpException({ error: AiErrorCode.QUOTA_EXCEEDED_PROJECT }, HttpStatus.TOO_MANY_REQUESTS)`.
  - En el return 200: `{ markdown, remainingGenerations: remaining }`.
- En `generateCover`: misma estructura — `checkAndIncrement(userId, 'cover')` antes de Gemini, catch con mapeo completo de 4 errores, `remainingGenerations: remaining`.

## Contratos HTTP (referencia)

| Endpoint | Status | Body |
|----------|--------|------|
| POST /ai/description | 200 | `{ markdown, remainingGenerations }` |
| POST /ai/description | 429 | `{ error: "quota_exceeded_user", remaining: 0 }` |
| POST /ai/description | 429 | `{ error: "quota_exceeded_project" }` |
| POST /ai/description | 422 | `{ error: "safety_blocked" }` |
| POST /ai/description | 503 | `{ error: "network_error" }` |
| POST /ai/cover | 200 | `{ imageUrl, remainingGenerations }` |
| POST /ai/cover | 429 | `{ error: "quota_exceeded_user", remaining: 0 }` |
| POST /ai/cover | 429 | `{ error: "quota_exceeded_project" }` |
| POST /ai/cover | 422 | `{ error: "safety_blocked" }` |
| POST /ai/cover | 503 | `{ error: "network_error" }` |

## Env / Remote Config

- Crear en Firebase Remote Config (Console): `ai_description_daily_limit` = `"10"`, `ai_cover_daily_limit` = `"5"` (Strings).
- IAM: service account necesita `roles/remoteconfig.viewer`.
- No cambiar `.env` real.

## Tests

- Agregar `mockQuotaService = { checkAndIncrement: jest.fn() }` al `beforeEach` del spec existente.
- Tests de cuota son nuevos y aditivos — no romper los 182 líneas existentes.
- `gemini.service.spec.ts`: agregar casos para `generateCover` errores y `quota_exceeded_project`.
- Correr: `cd api-gateway && npx jest --testPathPattern=ai`; luego `npx tsc --noEmit`.

## Guardrail clave

**No modificar** `firebase-auth.service.ts`, `AuthModule`, ni ningún otro módulo fuera de `ai/`.

> Full detail: docs/exec-runs/ai-quota-system/handoffs/architect.md
