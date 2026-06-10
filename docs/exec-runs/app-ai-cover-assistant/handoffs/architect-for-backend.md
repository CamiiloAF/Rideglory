> Slim handoff — read this before docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md

# Backend handoff — app-ai-cover-assistant

## Tu misión: retiro legacy atómico

`POST /ai/cover` **ya existe y funciona** (`api-gateway/src/ai/ai.controller.ts`). No tienes nada que crear.
Tu tarea es eliminar el endpoint legacy y sus dependencias.

## Orden de ejecución (crítico)

```
1. Eliminar generate-cover.spec.ts PRIMERO (contiene uso directo de axios — falso positivo en el grep)
2. Eliminar dto/generate-cover.dto.ts
3. Eliminar src/common/claude.service.ts
4. Eliminar src/common/unsplash.service.ts
5. Editar events.controller.ts (quitar @Post('generate-cover') + imports + constructor args ClaudeService/UnsplashService)
6. Editar events.module.ts (quitar ClaudeService y UnsplashService de providers[])
7. Verificar: grep -r "axios" src/ --include="*.ts" → debe retornar 0 líneas
8. Editar package.json → eliminar "@anthropic-ai/sdk" y "axios"
9. Editar .env.example → eliminar líneas ANTHROPIC_API_KEY (línea 30) y UNSPLASH_ACCESS_KEY (línea 33)
```

## Archivos a eliminar

- `api-gateway/src/events/generate-cover.spec.ts`
- `api-gateway/src/events/dto/generate-cover.dto.ts`
- `api-gateway/src/common/claude.service.ts`
- `api-gateway/src/common/unsplash.service.ts`

## Archivos a modificar

### `events.controller.ts`
- Eliminar import `ClaudeService` y `UnsplashService`
- Eliminar import `GenerateCoverDto`
- Eliminar `private readonly claudeService: ClaudeService` del constructor
- Eliminar `private readonly unsplashService: UnsplashService` del constructor
- Eliminar método `@Post('generate-cover') async generateCover(...)` completo

### `events.module.ts`
- Eliminar `import { ClaudeService }` y `import { UnsplashService }`
- Eliminar `ClaudeService` y `UnsplashService` del array `providers[]`

### `package.json`
- Eliminar `"@anthropic-ai/sdk"` de dependencies
- Eliminar `"axios"` de dependencies (cero usos tras pasos anteriores)

### `.env.example`
- Eliminar líneas `ANTHROPIC_API_KEY=...` y `UNSPLASH_ACCESS_KEY=...`

## Verificación final

```bash
grep -r "ClaudeService\|UnsplashService\|anthropic-ai/sdk\|anthropic" api-gateway/src/ --include="*.ts"
# Esperado: 0 líneas

grep -r "axios" api-gateway/src/ --include="*.ts"
# Esperado: 0 líneas
```

## Env vars en EC2
NO eliminar todavía de EC2 — hacerlo post-deploy estable (guardrail del PRD).

> Full detail: docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md
