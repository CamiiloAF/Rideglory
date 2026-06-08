> Slim handoff — read this before docs/exec-runs/ai-quota-system/handoffs/architect.md

# Architect → QA (ai-quota-system)

## Scope

Solo backend (`rideglory-api`). Sin cambios en Flutter — `dart analyze` debe seguir limpio sin ninguna acción.

## Comandos

```bash
# TypeScript check (api-gateway)
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx tsc --noEmit

# TypeScript check (contracts)
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npx tsc --noEmit

# Tests del módulo ai
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest --testPathPattern=ai --coverage

# Flutter (no debe cambiar)
cd /Users/cami/Developer/Personal/Rideglory
dart analyze
```

## Criterios de aceptación trazables

| AC | Dónde verificar |
|----|-----------------|
| 1. POST /ai/description con cuota agotada → 429 `quota_exceeded_user`, `remaining: 0` | `ai.controller.spec.ts` — nuevo caso |
| 2. POST /ai/cover con cuota agotada → 429 `quota_exceeded_user`, `remaining: 0` | `ai.controller.spec.ts` — nuevo caso |
| 3. 200 con `remainingGenerations = limit - (count+1)` correcto | `ai.controller.spec.ts` — nuevo caso |
| 4. Concurrencia: 2 requests no superan límite | `ai-quota.service.spec.ts` — test con transacción mock |
| 5. Gemini 429 → HTTP 429 `quota_exceeded_project` | `ai.controller.spec.ts` — nuevo caso |
| 6. Safety blocked → 422 `safety_blocked` (ya existe para description; agregar para cover) | `ai.controller.spec.ts` |
| 7. Network error → 503 `network_error` (ya existe para description; agregar para cover) | `ai.controller.spec.ts` |
| 8. `expireAt = createdAt + 2 días` en Firestore | `ai-quota.service.spec.ts` — verificar campo |
| 9. Remote Config leído; caché 5 min | `ai-quota.service.spec.ts` — mock `getRemoteConfig` |
| 10. Fallo Gemini no hace rollback (count queda N+1) | Semántica documentada; no hay código de rollback — verificar ausencia |
| 11. `tsc --noEmit` limpio | Comando arriba |

## Archivos de test a crear/modificar

| Archivo | Acción |
|---------|--------|
| `api-gateway/src/ai/ai-quota.service.spec.ts` | CREAR — unitario con Firestore mock y Remote Config mock |
| `api-gateway/src/ai/ai.controller.spec.ts` | MODIFY — agregar mock de `AiQuotaService`; nuevos casos de cuota y cover errors |
| `api-gateway/src/ai/gemini.service.spec.ts` | MODIFY — agregar casos de `generateCover` errores y detección `QUOTA_EXCEEDED_PROJECT` |

## Archivos protegidos

No modificar: `firebase-auth.service.ts`, `/events/generate-cover`, ningún archivo fuera del módulo `ai/`.

> Full detail: docs/exec-runs/ai-quota-system/handoffs/architect.md
