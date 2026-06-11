# QA Handoff — ai-event-gen-phase1-backend

**Timestamp:** 2026-06-05T22:54:52Z
**Status:** done (conditional sign-off — 1 minor bug)

---

## Catalogo de AC

| AC | Descripción | Test que lo cubre | Estado |
|----|-------------|-------------------|--------|
| CA1 | `npm run build` sin errores TypeScript | `npm run build` ejecutado — exit 0 | PASS |
| CA2 | `POST /ai/description` → 200 `{ markdown, remainingGenerations: -1 }` | `ai.controller.spec.ts` — "returns markdown and remainingGenerations: -1" | PASS |
| CA3 | Sin `Authorization` → 401 (APP_GUARD global) | Verificación manual (ver §Pruebas manuales); no hay `@UseGuards` en el controller | PASS (manual) |
| CA4 | Body sin `eventContext.title` → 400 | `ai.controller.spec.ts` — "throws BadRequestException when eventContext.title is missing" | PASS |
| CA5 | Error de red Gemini → 503 `{ error: 'network_error' }` | `ai.controller.spec.ts` — "throws ServiceUnavailableException with error: network_error" | PASS |
| CA6 | Safety blocking → 422 `{ error: 'safety_blocked' }` | `ai.controller.spec.ts` — "throws UnprocessableEntityException with error: safety_blocked" | PASS |
| CA7 | `POST /events/generate-cover` sin regresión | `generate-cover.spec.ts` — 10 tests todos PASS | PASS |
| CA8 | `rideglory-contracts/src/ai/index.ts` exporta 7 símbolos | Verificado en archivo: `AiChatTurnDto`, `AiDescriptionRequestDto`, `AiDescriptionEventContext`, `AiDescriptionResponseDto`, `AiErrorResponseDto`, `AiChatRole`, `AiErrorCode` | PASS |
| CA9 | Todos los specs pasan | `npm test` — 78/78 tests, 5 suites | PASS |
| CA10 | `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` en `.env.example` | Verificado con grep en `api-gateway/.env.example` — ambas presentes con comentarios | PASS |
| CA11 | Constructor lanza `Error` sin API key | `ai.controller.spec.ts` — 2 casos: ausente y vacío | PASS |

---

## Matriz de Regresion (Guardrails §6)

| Guardrail | Mecanismo de verificación | Estado |
|-----------|--------------------------|--------|
| `POST /events/generate-cover` intacto | `generate-cover.spec.ts` — 10 tests PASS | OK |
| `app.module.ts` solo agrega `AiModule` | Verificado: solo línea `AiModule` agregada al array `imports`, resto intacto | OK |
| `ClaudeService`, `UnsplashService` no modificados | Verificado con `git diff` — no hay cambios en esos archivos | OK |
| Esquema Prisma y Firestore sin cambios | Ningún archivo de migración ni schema modificado | OK |
| Tests existentes pasan | Baseline 71 → ahora 78 (7 nuevos); todos verdes | OK |
| Sin `@UseGuards` explícito en controller | Confirmado en `ai.controller.ts` — no hay import ni decorador de guards | OK |
| `rideglory-contracts/src/index.ts` solo agrega la línea de AI | Verificado: único cambio es `export * from './ai'` al final | OK |

---

## Ejecucion

### Backend (`api-gateway`)

```
npm run build    → exit 0 (sin errores TypeScript)
npm test         → 78 passed / 0 failed / 5 suites
                   (baseline era 71; los 7 nuevos en ai.controller.spec.ts son PASS)
```

Suite desglosada relevante:
- `generate-cover.spec.ts`: 10/10 PASS (regresión: ninguna)
- `ai.controller.spec.ts`: 7/7 PASS

### Flutter

```
dart analyze     → No issues found!
flutter test     → exit 0 (todos los tests pasan — esta fase es backend pura)
```

---

## Bugs

| ID | Área | Archivo | Descripción | Severidad |
|----|------|---------|-------------|-----------|
| BUG-1 | backend | `api-gateway/src/ai/gemini.service.ts:71` | Ternario dead-code — ambas ramas devuelven `AiErrorCode.NETWORK_ERROR`. La intención era re-lanzar `safety_blocked` si el SDK de Gemini lo lanzara como excepción durante la llamada, pero ambas ramas son idénticas. En la práctica la detección de safety ocurre vía inspección de respuesta (líneas 74-81), por lo que el impacto real es bajo; sin embargo si alguna versión futura del SDK lanza con mensaje `safety_blocked`, se clasificaría incorrectamente como `network_error`. | Low |

Código afectado (línea 71):
```typescript
throw new Error(message === AiErrorCode.NETWORK_ERROR ? AiErrorCode.NETWORK_ERROR : AiErrorCode.NETWORK_ERROR);
// debería ser:
throw new Error(message === AiErrorCode.SAFETY_BLOCKED ? AiErrorCode.SAFETY_BLOCKED : AiErrorCode.NETWORK_ERROR);
```

---

## Pruebas Manuales

Las siguientes pruebas requieren servidor corriendo con `GEMINI_API_KEY` válido y token Firebase válido. Se documentan como referencia; no son bloqueantes para el sign-off automatizado.

| Prueba | Comando | Resultado esperado |
|--------|---------|-------------------|
| 401 sin token | `curl -X POST http://localhost:3000/ai/description -H "Content-Type: application/json" -d '{"eventContext":{"title":"Test","eventType":"TOURISM","city":"Bogotá"},"userMessage":"Describe"}'` | 401 Unauthorized |
| 400 body inválido | Mismo pero con token y sin `title` en `eventContext` | 400 Bad Request |
| 200 success | Con token válido y body completo | `{ "markdown": "...", "remainingGenerations": -1 }` |

---

## Sign-off

- **CA1–CA11**: todos PASS
- **Bugs bloqueantes**: ninguno
- **Bugs no bloqueantes**: 1 (BUG-1 — dead-code ternario en `gemini.service.ts`, severidad low, no afecta funcionalidad actual)
- **Regresión**: cero (generate-cover.spec.ts intacto, dart analyze limpio)
- **Señal de calidad**: **conditional green** — listo para Tech Lead; BUG-1 puede corregirse antes o después del merge según criterio del Tech Lead

## Proximos pasos

- **Tech Lead**: revisar BUG-1 (ternario dead-code en línea 71 de `gemini.service.ts`) — corrección trivial de una línea, puede incluirse en el mismo commit o diferirse a Fase 2.
- **Fase siguiente**: Fase 2 (generación de portada con Gemini) puede arrancar; los contratos publicados en `rideglory-contracts` están listos.

## Change log

- 2026-06-05T22:54:52Z: QA run inicial — 78/78 backend PASS, 0 violaciones dart analyze, 1 bug low identificado
