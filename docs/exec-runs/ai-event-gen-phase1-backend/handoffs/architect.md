# Architect handoff — ai-event-gen-phase1-backend

**Date:** 2026-06-05T22:41:18Z
**Status:** done

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| 1 | `AiModule` en `api-gateway/src/ai/` con `AiController` + `GeminiService` | Patrón existente: cada dominio tiene su propio módulo NestJS |
| 2 | Sin `@UseGuards` en `AiController` | `AuthModule` registra `FirebaseAuthGuard` como `APP_GUARD` global — confirmado en `auth.module.ts`; protege toda ruta automáticamente |
| 3 | `GEMINI_API_KEY` leída en constructor de `GeminiService`; lanzar `Error` descriptivo si ausente | Fail-fast: el servicio no debe arrancar sin credenciales |
| 4 | `Promise.race` con 30 s para timeout | La API de Gemini puede tardar; no bloquear el thread indefinidamente |
| 5 | `AiDescriptionResponseDto` es excepción Pattern B documentada | DTO compuesto (campo de control `remainingGenerations` + dato `markdown`), sin modelo domain 1:1 |
| 6 | `AiDescriptionEventContext` como clase exportada a nivel de módulo | Necesario para que `@ValidateNested` + `class-transformer` funcionen correctamente |
| 7 | `EventType` se importa desde `'../events/enums'` en rideglory-contracts | Ya existe en `rideglory-contracts/src/events/enums/event.enums.ts`; `export * from './events'` ya presente en index — sin duplicación |
| 8 | `class-validator` ya es `peerDependency` en rideglory-contracts | Confirmado en `rideglory-contracts/package.json`; no requiere cambio |
| 9 | `@google/genai ^1.x` en `dependencies` (no devDependencies) de api-gateway | Runtime dependency; versión mayor fijada per PRD constraint §7 |

---

## Change map

| Repo | Archivo | Acción | Razón | Riesgo |
|------|---------|--------|-------|--------|
| rideglory-api | `api-gateway/package.json` | modify | Agregar `"@google/genai": "^1.x"` en `dependencies` | low |
| rideglory-api | `api-gateway/src/ai/ai.module.ts` | create | NestJS module que exporta GeminiService | low |
| rideglory-api | `api-gateway/src/ai/ai.controller.ts` | create | Controller `POST /ai/description`; sin @UseGuards | low |
| rideglory-api | `api-gateway/src/ai/gemini.service.ts` | create | GeminiService: llamada a Gemini API, timeout 30 s, manejo errores | med |
| rideglory-api | `api-gateway/src/ai/ai.controller.spec.ts` | create | Spec con 6 casos (200, 401 implícito vía guard, 400, 503, 422, constructor sin API key) | low |
| rideglory-api | `api-gateway/src/app.module.ts` | modify | Agregar `AiModule` al array `imports`; ningún otro cambio | low |
| rideglory-api | `api-gateway/.env.example` | modify | Agregar `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` con comentarios | low |
| rideglory-api | `rideglory-contracts/src/ai/enums/ai.enums.ts` | create | `AiChatRole`, `AiErrorCode` | low |
| rideglory-api | `rideglory-contracts/src/ai/dto/ai-chat-turn.dto.ts` | create | `AiChatTurnDto` { role: AiChatRole, content: string } | low |
| rideglory-api | `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | create | `AiDescriptionEventContext` con validaciones class-validator | low |
| rideglory-api | `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` | create | `AiDescriptionRequestDto` { eventContext, history?, userMessage } | low |
| rideglory-api | `rideglory-contracts/src/ai/dto/ai-description-response.dto.ts` | create | `AiDescriptionResponseDto` { markdown, remainingGenerations } | low |
| rideglory-api | `rideglory-contracts/src/ai/dto/ai-error-response.dto.ts` | create | `AiErrorResponseDto` { error: AiErrorCode } | low |
| rideglory-api | `rideglory-contracts/src/ai/index.ts` | create | Re-exporta enums + todos los DTOs del módulo AI | low |
| rideglory-api | `rideglory-contracts/src/index.ts` | modify | Agregar `export * from './ai'`; ningún otro cambio | low |

**Total: 15 archivos — 13 creates, 2 modifies en código app, 1 modify en .env.example**

---

## Contratos rideglory-api

### POST /ai/description

```
Auth:     Firebase ID token (Bearer) — APP_GUARD global
Method:   POST
Path:     /ai/description
```

**Request body** (`AiDescriptionRequestDto`):
```json
{
  "eventContext": {
    "title": "string (required, 1-200)",
    "eventType": "TOURISM | URBAN | OFF_ROAD | COMPETITION | SOLIDARITY | SHORT_DISTANCE",
    "city": "string (optional)",
    "date": "ISO8601 string (optional)",
    "distance": "number km (optional)",
    "difficulty": "EASY | MODERATE | MEDIUM | HARD | VERY_HARD (optional)"
  },
  "history": [
    { "role": "user | model", "content": "string" }
  ],
  "userMessage": "string (required)"
}
```

**Responses:**
| Status | Body | Condición |
|--------|------|-----------|
| 200 | `{ "markdown": "...", "remainingGenerations": -1 }` | Gemini respondió OK |
| 400 | validation error estándar NestJS | Body malformado / campo requerido ausente |
| 401 | Firebase error | Token ausente o inválido |
| 422 | `{ "error": "safety_blocked" }` | Gemini retorna bloqueo de safety |
| 503 | `{ "error": "network_error" }` | Error de red o timeout >30 s |

---

## Datos / migraciones

No hay cambios de esquema Prisma ni Firestore. Sin `MIGRATION_PLAN.md`.

---

## Env

Ver `docs/exec-runs/ai-event-gen-phase1-backend/analysis/ENV_DELTA.md`.

Variables nuevas en `api-gateway/.env.example`:

| Variable | Descripción | Ejemplo | Requerida |
|----------|-------------|---------|-----------|
| `GEMINI_API_KEY` | API key de Gemini Developer API | `AIza...` | Sí (runtime) |
| `GEMINI_TEXT_MODEL` | Modelo de texto Gemini (configurable) | `gemini-2.5-flash` | No (default en código) |

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `response.text` podría ser método en versiones antiguas del SDK | Verificar contra docs oficiales `@google/genai ^1.x` antes de merge; constraint §7 del PRD |
| Mapeo `AiChatTurnDto[] → GenerateContentRequest.contents` incorrecto | Validar con prueba de integración manual; cubrir con test unitario en spec |
| Build falla por tipos TS de `@google/genai` | Correr `npm run build` en api-gateway como verificación en QA |
| Safety blocking en respuestas legítimas | `422 safety_blocked` con mensaje user-friendly; rango normal para contenido de eventos |
| `GEMINI_API_KEY` ausente en staging/EC2 | Constructor lanza `Error` descriptivo → crash-fast visible en logs; no desplegar sin configurar |

---

## Orden de implementación

1. `rideglory-contracts`: crear directorio `src/ai/` completo (enums + DTOs + index)
2. `rideglory-contracts/src/index.ts`: agregar `export * from './ai'`
3. `api-gateway/package.json`: agregar `@google/genai ^1.x`
4. `api-gateway/src/ai/gemini.service.ts`: implementar GeminiService
5. `api-gateway/src/ai/ai.controller.ts`: implementar AiController
6. `api-gateway/src/ai/ai.module.ts`: registrar providers
7. `api-gateway/src/ai/ai.controller.spec.ts`: spec 6 casos
8. `api-gateway/src/app.module.ts`: agregar `AiModule` al array imports
9. `api-gateway/.env.example`: agregar variables con comentarios

---

## Superficie de regresión

- `POST /events/generate-cover`: no se toca `EventsController`, `ClaudeService`, ni `UnsplashService` — riesgo cero
- `app.module.ts`: solo se agrega `AiModule` al array; ningún módulo existente se mueve o modifica
- `rideglory-contracts/src/index.ts`: solo se agrega una línea; ningún export existente se altera
- Tests existentes no se modifican

---

## Fuera de alcance

- Generación de imágenes / portadas (Fase 2)
- Sistema de cuotas y códigos 429 (Fase 3)
- Integración Flutter: `AiDescriptionCubit`, Retrofit client, UI (Fases 4-5)
- Eliminar `ClaudeService`, `UnsplashService` ni `POST /events/generate-cover` (Fase 5)
- Variables de entorno en EC2 (sin despliegue en esta fase)
- `StorageCleanupService` y cron de barrido (Fase 2)
