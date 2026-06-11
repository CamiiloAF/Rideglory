> Slim handoff — read this before docs/exec-runs/ai-event-gen-phase1-backend/handoffs/architect.md

# QA slim handoff — ai-event-gen-phase1-backend

## Comandos de verificación

```bash
# Desde /Users/cami/Developer/Personal/rideglory-api/api-gateway
npm run build          # debe terminar sin errores TypeScript
npm test               # todos los specs deben pasar (incluyendo los nuevos)
```

## Criterios de aceptación — traceability

| CA | Verificación |
|----|-------------|
| CA1 `npm run build` sin errores | `npm run build` en api-gateway |
| CA2 `POST /ai/description` 200 `{ markdown, remainingGenerations: -1 }` | Test manual o spec ai.controller.spec.ts caso success |
| CA3 Sin `Authorization` → 401 | APP_GUARD global; probar con curl sin header |
| CA4 Body sin `eventContext.title` → 400 | spec ai.controller.spec.ts caso validación |
| CA5 Error de red Gemini → 503 `{ error: 'network_error' }` | spec ai.controller.spec.ts caso timeout/network |
| CA6 Safety blocking → 422 `{ error: 'safety_blocked' }` | spec ai.controller.spec.ts caso safety |
| CA7 `POST /events/generate-cover` sigue igual | spec generate-cover.spec.ts existente no debe romperse |
| CA8 `rideglory-contracts/src/ai/index.ts` exporta 7 símbolos | Verificar manualmente el archivo |
| CA9 Todos los specs pasan | `npm test` |
| CA10 GEMINI vars en .env.example | Verificar que `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` están en el archivo |
| CA11 Constructor lanza Error sin API key | spec ai.controller.spec.ts caso constructor |

## Regresión esperada: cero

- `generate-cover.spec.ts` existente debe pasar sin cambios
- No hay tests de Flutter afectados (fase backend pura)

## Archivos nuevos a revisar

```
api-gateway/src/ai/ai.module.ts
api-gateway/src/ai/ai.controller.ts
api-gateway/src/ai/gemini.service.ts
api-gateway/src/ai/ai.controller.spec.ts
rideglory-contracts/src/ai/index.ts
rideglory-contracts/src/ai/enums/ai.enums.ts
rideglory-contracts/src/ai/dto/ (5 archivos)
```

> Full detail: docs/exec-runs/ai-event-gen-phase1-backend/handoffs/architect.md
