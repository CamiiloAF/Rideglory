> Slim handoff — read this before docs/exec-runs/ai-event-gen-phase1-backend/handoffs/architect.md

# Backend slim handoff — ai-event-gen-phase1-backend

## Repo objetivo
`/Users/cami/Developer/Personal/rideglory-api`

## 1. Contratos nuevos en rideglory-contracts

Crear `rideglory-contracts/src/ai/` con la siguiente estructura:

```
src/ai/
  enums/
    ai.enums.ts          ← AiChatRole { USER='user', MODEL='model' }, AiErrorCode { NETWORK_ERROR='network_error', SAFETY_BLOCKED='safety_blocked' }
  dto/
    ai-chat-turn.dto.ts           ← AiChatTurnDto { role!: AiChatRole; content!: string }
    ai-description-event-context.dto.ts  ← AiDescriptionEventContext (clase exportada, @ValidateNested target)
    ai-description-request.dto.ts        ← AiDescriptionRequestDto { eventContext!, history?, userMessage! }
    ai-description-response.dto.ts       ← AiDescriptionResponseDto { markdown!: string; remainingGenerations!: number }
    ai-error-response.dto.ts             ← AiErrorResponseDto { error!: AiErrorCode }
  index.ts               ← export * from './enums'; export * from './dto';
```

Todos los campos con `prop!: Type` (definitiva assignment assertion).
`AiDescriptionResponseDto` es excepción Pattern B — comentar inline: "Composite DTO: control field + domain data; no 1:1 domain model".

Agregar `export * from './ai'` en `rideglory-contracts/src/index.ts` (solo esta línea, al final).

`EventType` se importa desde `'../events/enums'` en `AiDescriptionEventContext`.

## 2. AiModule en api-gateway

Agregar `@google/genai ^1.x` en `api-gateway/package.json` dependencies.

Crear `api-gateway/src/ai/`:

### gemini.service.ts
- `@Injectable() GeminiService`
- Constructor: leer `process.env.GEMINI_API_KEY`; si ausente/vacío → `throw new Error('GEMINI_API_KEY is required')`
- Leer `process.env.GEMINI_TEXT_MODEL ?? 'gemini-2.5-flash'`
- `generateDescription(req: AiDescriptionRequestDto): Promise<string>`
  - Mapear `req.history` a `contents[]` de Gemini (role/parts)
  - System prompt en español colombiano (tono cálido, motociclismo)
  - `Promise.race([geminiCall, timeout(30000)])` → si timeout: lanzar con código `network_error`
  - Verificar que `response.text` es propiedad (no método) en `@google/genai ^1.x` antes de merge
  - Si Gemini retorna bloqueo safety → lanzar con código `safety_blocked`

### ai.controller.ts
- `@Controller('ai') AiController`
- SIN `@UseGuards` — APP_GUARD global de AuthModule protege la ruta
- `@Post('description') async generateDescription(@Body() dto: AiDescriptionRequestDto)`
  - Llamar `geminiService.generateDescription(dto)`
  - Éxito: `{ markdown, remainingGenerations: -1 }`
  - Capturar errores: `network_error` → `ServiceUnavailableException({ error: 'network_error' })`; `safety_blocked` → `UnprocessableEntityException({ error: 'safety_blocked' })`

### ai.module.ts
- `@Module({ controllers: [AiController], providers: [GeminiService] }) AiModule`

### ai.controller.spec.ts
- 6 casos: success 200, body inválido (falta title) 400, timeout/network_error 503, safety_blocked 422, constructor sin API key lanza Error, history vacío OK

## 3. Registrar en AppModule

`api-gateway/src/app.module.ts`: agregar `AiModule` al array `imports` (una sola línea, no mover otros módulos).

## 4. .env.example

Agregar al final de `api-gateway/.env.example`:
```
# Gemini — AI description generation
GEMINI_API_KEY=your-gemini-api-key
# Gemini text model (default: gemini-2.5-flash)
# GEMINI_TEXT_MODEL=gemini-2.5-flash
```

## 5. Guardrails críticos

- NO modificar `ClaudeService`, `UnsplashService`, `EventsController`
- NO mover ni reordenar módulos existentes en `app.module.ts`
- NO alterar `rideglory-contracts/src/index.ts` más allá de la línea `export * from './ai'`
- NO esquema Prisma ni Firestore

> Full detail: docs/exec-runs/ai-event-gen-phase1-backend/handoffs/architect.md
