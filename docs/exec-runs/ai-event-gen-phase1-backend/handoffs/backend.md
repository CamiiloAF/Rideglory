# Backend Handoff — ai-event-gen-phase1-backend

**Timestamp:** 2026-06-05T22:48:26Z

---

## Baseline

- `npm test` en `api-gateway` antes de cualquier cambio: **71 tests, 5 suites — todos verdes**.
- `npm run build` en `rideglory-contracts` y `api-gateway`: sin errores TypeScript.

---

## Archivos cambiados

### rideglory-contracts (contratos nuevos)

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `rideglory-contracts/src/ai/enums/ai.enums.ts` | CREATE | `AiChatRole { USER, MODEL }` y `AiErrorCode { NETWORK_ERROR, SAFETY_BLOCKED }` |
| `rideglory-contracts/src/ai/dto/ai-chat-turn.dto.ts` | CREATE | `AiChatTurnDto` con `role: AiChatRole` y `content: string` |
| `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | CREATE | `AiDescriptionEventContext` — clase exportada para `@ValidateNested`; importa `EventType` de `../../events/enums` |
| `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` | CREATE | `AiDescriptionRequestDto` — `eventContext!`, `history?`, `userMessage!` |
| `rideglory-contracts/src/ai/dto/ai-description-response.dto.ts` | CREATE | `AiDescriptionResponseDto` — excepción Pattern B documentada inline (composite DTO) |
| `rideglory-contracts/src/ai/dto/ai-error-response.dto.ts` | CREATE | `AiErrorResponseDto { error: AiErrorCode }` |
| `rideglory-contracts/src/ai/dto/index.ts` | CREATE | Re-exporta todos los DTOs |
| `rideglory-contracts/src/ai/index.ts` | CREATE | `export * from './enums'` + `export * from './dto'` |
| `rideglory-contracts/src/index.ts` | MODIFY | Línea agregada al final: `export * from './ai'` |

### api-gateway (módulo nuevo)

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `api-gateway/package.json` | MODIFY | `@google/genai ^1.52.0` agregado a `dependencies` (npm instaló ^1.52.0, mayor ^1.x) |
| `api-gateway/src/ai/gemini.service.ts` | CREATE | `GeminiService` — constructor lanza si `GEMINI_API_KEY` ausente/vacío; `generateDescription()` con mapeo de historial, system prompt ES-CO, `Promise.race` 30s, safety check |
| `api-gateway/src/ai/ai.controller.ts` | CREATE | `AiController` — `POST /ai/description` sin `@UseGuards`; success `{ markdown, remainingGenerations: -1 }`; captura `network_error → 503`, `safety_blocked → 422` |
| `api-gateway/src/ai/ai.module.ts` | CREATE | `@Module({ controllers: [AiController], providers: [GeminiService] })` |
| `api-gateway/src/ai/ai.controller.spec.ts` | CREATE | 7 casos de test (ver sección siguiente) |
| `api-gateway/src/app.module.ts` | MODIFY | `AiModule` agregado al array `imports` — ningún otro módulo movido |
| `api-gateway/.env.example` | MODIFY | Sección `# Gemini` con `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` comentada |

---

## Pruebas nuevas

Archivo: `api-gateway/src/ai/ai.controller.spec.ts`

| # | Descripción | Resultado esperado |
|---|-------------|-------------------|
| 1 | Success — DTO válido | 200 `{ markdown, remainingGenerations: -1 }` |
| 2 | `network_error` desde `GeminiService` | `ServiceUnavailableException` (503) con `{ error: 'network_error' }` |
| 3 | `safety_blocked` desde `GeminiService` | `UnprocessableEntityException` (422) con `{ error: 'safety_blocked' }` |
| 4 | Body inválido (falta `eventContext.title`) | `BadRequestException` (400) via `ValidationPipe` |
| 5 | `history: []` (array vacío) | 200 OK — no explota con historial vacío |
| 6 | Constructor sin `GEMINI_API_KEY` | `new GeminiService()` lanza `Error('GEMINI_API_KEY is required')` |
| 7 | Constructor con `GEMINI_API_KEY=''` | `new GeminiService()` lanza `Error('GEMINI_API_KEY is required')` |

---

## Resultado final

```
Test Suites: 5 passed, 5 total
Tests:       78 passed, 78 total  (baseline: 71 + 7 nuevos)
Time:        0.722s
npm run build (api-gateway): ✓ sin errores TypeScript
npm run build (rideglory-contracts): ✓ sin errores TypeScript
```

---

## Verificación manual

Para verificar el endpoint manualmente (requiere `GEMINI_API_KEY` real y server corriendo):

```bash
# Arrancar servidor
cd api-gateway && npm run start:dev

# Test 200 (requiere token Firebase válido)
curl -X POST http://localhost:3000/ai/description \
  -H "Authorization: Bearer <firebase-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "eventContext": {
      "title": "Ruta de los Andes",
      "eventType": "TOURISM",
      "city": "Medellín"
    },
    "userMessage": "Genera una descripción emocionante para este evento.",
    "history": []
  }'
# Esperado: { "markdown": "...", "remainingGenerations": -1 }

# Test 401 (sin token)
curl -X POST http://localhost:3000/ai/description \
  -H "Content-Type: application/json" \
  -d '{ "eventContext": { "title": "Test" , "eventType": "TOURISM", "city": "Bogotá" }, "userMessage": "Describe" }'
# Esperado: 401 Unauthorized

# Test 400 (body inválido)
curl -X POST http://localhost:3000/ai/description \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{ "eventContext": { "eventType": "TOURISM", "city": "Bogotá" }, "userMessage": "Describe" }'
# Esperado: 400 Bad Request
```

---

## Notas Frontend/QA

- **Contrato publicado:** `@rideglory/contracts` ahora exporta `AiChatTurnDto`, `AiDescriptionRequestDto`, `AiDescriptionEventContext`, `AiDescriptionResponseDto`, `AiErrorResponseDto`, `AiChatRole`, `AiErrorCode`. Los paquetes Flutter pueden importar desde el bundle compilado.
- **`remainingGenerations: -1`** es el valor placeholder de esta fase; la cuota real se implementa en Fase 3.
- **No se requiere migración de BD** — este módulo no toca Prisma ni Firestore.
- **Guard:** la ruta es protegida por el `APP_GUARD` global (`FirebaseAuthGuard`). El controller NO tiene `@UseGuards` explícito.
- **Modelo configurable:** `GEMINI_TEXT_MODEL` (default `gemini-2.5-flash`) — útil para cambiar a `gemini-2.0-flash` si hay quota issues.
- **Safety blocks:** si Gemini rechaza el prompt por contenido, el endpoint retorna 422 `{ error: 'safety_blocked' }`. El frontend debe mostrar mensaje apropiado al usuario.
- **Timeout 30s:** si Gemini no responde en 30 segundos, retorna 503 `{ error: 'network_error' }`.
- **`POST /events/generate-cover`** sigue intacto — sin regresión (71 tests base siguen verdes).
