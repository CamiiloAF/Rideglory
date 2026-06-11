# Tech Lead Handoff — ai-event-gen-phase1-backend

**Timestamp:** 2026-06-05T22:59:24Z
**Veredicto:** ready

---

## Veredicto

**READY** — 78/78 tests pasan, build TypeScript limpio, arquitectura correcta, seguridad OK. BUG-1 (dead-code ternario) corregido in-tree antes del sign-off. Sin blockers.

---

## Hallazgos

| ID | Archivo | Línea | Tipo | Descripción | Resolución |
|----|---------|-------|------|-------------|------------|
| BUG-1 | `api-gateway/src/ai/gemini.service.ts` | 71 | Bug / dead-code | Ternario `message === NETWORK_ERROR ? NETWORK_ERROR : NETWORK_ERROR` — ambas ramas idénticas; si el SDK Gemini lanza con mensaje `safety_blocked` en el catch del race, se re-clasificaría como `network_error`. | **Corregido** — cambiado a `message === SAFETY_BLOCKED ? SAFETY_BLOCKED : NETWORK_ERROR`. Tests siguen 78/78 PASS. |

Sin otros hallazgos fuera del change map. Todos los archivos modificados corresponden exactamente al plan del Arquitecto.

---

## Seguridad

| Check | Estado | Notas |
|-------|--------|-------|
| No secretos hardcodeados | OK | `GEMINI_API_KEY` solo via `process.env`; constructor lanza si ausente/vacío |
| Auth endpoint | OK | `APP_GUARD` global (`FirebaseAuthGuard`) en `AuthModule` protege `POST /ai/description` sin necesidad de `@UseGuards` en el controller |
| SQL injection | N/A | No hay queries Prisma ni SQL en este módulo |
| PII en logs | OK | No hay `console.log` ni logger calls con datos de usuario |
| Input validation | OK | `AiDescriptionRequestDto` usa `class-validator` con `@IsString`, `@IsEnum`, `@ValidateNested`, `@Type` para nested objects |
| CORS | OK | Hereda la config CORS del gateway — no cambios |
| Prompt injection | Aceptable | El `contextPrefix` incluye campos de usuario (title, city). Riesgo inherente al feature; sin datos sensibles; el system prompt limita el scope de salida |

---

## Arquitectura

| Check | Estado | Notas |
|-------|--------|-------|
| Módulo aislado | OK | `AiModule` independiente; no exporta `GeminiService` (acceso solo interno) |
| Contratos en `rideglory-contracts` | OK | Todos los DTOs y enums en `src/ai/`; re-exportados desde el index raíz |
| Pattern B / excepción documentada | OK | `AiDescriptionResponseDto` tiene comentario inline correcto: "Composite DTO: control field + domain data; no 1:1 domain model" |
| No URLs hardcodeadas | OK | Modelo configurable via `GEMINI_TEXT_MODEL`; API key via env var |
| Guardrails del arquitecto | OK | `ClaudeService`, `UnsplashService`, `EventsController` intactos; `app.module.ts` solo agrega `AiModule`; sin cambios a Prisma/Firestore |
| `EventType` importado de `../../events/enums` | OK | Importación correcta en `ai-description-event-context.dto.ts` |
| Timeout 30s | OK | `Promise.race` con `setTimeout(30_000)` — prevent Gemini call de colgar indefinidamente |
| `response.text` como propiedad (no método) | OK | Confirmado en `@google/genai ^1.52.0` — `response.text` es getter string |

---

## Tests

| Suite | Baseline | Tras cambio | Delta |
|-------|---------|-------------|-------|
| `api-gateway` (todas) | 71 | 78 | +7 |
| `ai.controller.spec.ts` | — | 7/7 | nuevo |
| `generate-cover.spec.ts` | 10/10 | 10/10 | sin regresión |

Cobertura de AC:
- CA-success-200: cubierto
- CA-network_error-503: cubierto
- CA-safety_blocked-422: cubierto
- CA-body_invalid-400: cubierto via `ValidationPipe` + `BadRequestException`
- CA-history_empty-200: cubierto
- CA-constructor_no_key: 2 casos (ausente + vacío)

---

## Pruebas Manuales

Ejecutar antes de merge a `main` con `GEMINI_API_KEY` real y token Firebase válido:

```bash
# Arrancar servidor
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
GEMINI_API_KEY=<real_key> npm run start:dev

# 1. 401 sin token (APP_GUARD)
curl -X POST http://localhost:3000/ai/description \
  -H "Content-Type: application/json" \
  -d '{"eventContext":{"title":"Test","eventType":"TOURISM","city":"Bogotá"},"userMessage":"Describe"}'
# Esperado: 401 Unauthorized

# 2. 400 body inválido (falta title)
curl -X POST http://localhost:3000/ai/description \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{"eventContext":{"eventType":"TOURISM","city":"Bogotá"},"userMessage":"Describe"}'
# Esperado: 400 Bad Request

# 3. 200 success
curl -X POST http://localhost:3000/ai/description \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "eventContext":{"title":"Ruta de los Andes","eventType":"TOURISM","city":"Medellín"},
    "userMessage":"Genera una descripción emocionante para este evento.",
    "history":[]
  }'
# Esperado: { "markdown": "...", "remainingGenerations": -1 }

# 4. Sin regresión generate-cover
curl -X POST http://localhost:3000/events/generate-cover \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"ruta de montaña en los Andes colombianos"}'
# Esperado: 200 con URL de imagen
```
