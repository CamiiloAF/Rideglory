> Slim handoff — read this before docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md

# Architect → Backend (NestJS) — ai-phase06-qa-analytics (rev 2)

## Objetivo de esta fase
Dos cambios productivos + un spec nuevo. No se modifica ningún otro archivo backend.

---

## 1. Modificar el DTO de contratos — `@ArrayMaxSize(10)` en `history`

**Archivo:** `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts`

Agregar el decorator `@ArrayMaxSize(10)` al campo `history`:

```ts
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,     // ← agregar este import
  IsArray,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { AiDescriptionEventContext } from './ai-description-event-context.dto';
import { AiChatTurnDto } from './ai-chat-turn.dto';

export class AiDescriptionRequestDto {
  @ValidateNested()
  @Type(() => AiDescriptionEventContext)
  eventContext!: AiDescriptionEventContext;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)      // ← nueva línea
  @ValidateNested({ each: true })
  @Type(() => AiChatTurnDto)
  history?: AiChatTurnDto[];

  @IsString()
  userMessage!: string;
}
```

**Rebuild obligatorio tras editar el DTO:**
```bash
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npm run build

cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
pnpm install
```

> Sin estos pasos los specs compilarán contra el DTO desactualizado y el test history>10 fallará en rojo.

---

## 2. Crear `rideglory-api/api-gateway/src/ai/ai-description.spec.ts`

El archivo cubre los **gaps genuinamente ausentes** en los specs existentes:
- `ai.controller.spec.ts` ya cubre: success 200, network_error 503, safety_blocked 422, quota_exceeded_project 429, quota_exceeded_user 429, DTO validation (missing title → 400), history vacío → 200, constructor GeminiService.
- `gemini.service.spec.ts` ya cubre: RESOURCE_EXHAUSTED → quota_exceeded_project, generic error → network_error.

**Lo que SÍ agrega este spec (no cubierto en ningún spec existente):**

### Suite A: Validación DTO — `history` > 10 turnos → 400

```ts
jest.mock('../config/envs', () => ({ envs: { databaseUrl: 'postgresql://test' } }));
jest.mock('@prisma/adapter-pg', () => ({ PrismaPg: jest.fn() }));

import { BadRequestException, ValidationPipe } from '@nestjs/common';
import { AiDescriptionRequestDto, AiChatRole, EventType } from '@rideglory/contracts';

describe('AiDescriptionRequestDto validation — history > 10', () => {
  it('throws BadRequestException when history has more than 10 turns', async () => {
    const pipe = new ValidationPipe({ whitelist: true, transform: true });
    const dto = {
      eventContext: {
        title: 'Test Event',
        eventType: EventType.TOURISM,
        city: 'Bogotá',
      },
      userMessage: 'Test',
      history: Array.from({ length: 11 }, (_, i) => ({
        role: i % 2 === 0 ? AiChatRole.USER : AiChatRole.MODEL,
        content: `Turn ${i}`,
      })),
    };

    await expect(
      pipe.transform(dto, { type: 'body', metatype: AiDescriptionRequestDto }),
    ).rejects.toThrow(BadRequestException);
  });
});
```

### Suite B: `GeminiService.generateDescription` — casos NO cubiertos en `gemini.service.spec.ts`

```ts
// Mockear @google/genai igual que en gemini.service.spec.ts
const mockGenerateContent = jest.fn();
jest.mock('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: { generateContent: mockGenerateContent },
  })),
}));

import { GeminiService } from './gemini.service';
import { AiErrorCode, AiDescriptionRequestDto, EventType } from '@rideglory/contracts';

describe('GeminiService.generateDescription — happy path and safety', () => {
  const validReq: AiDescriptionRequestDto = {
    eventContext: {
      title: 'Test Event',
      eventType: EventType.TOURISM,
      city: 'Bogotá',
    },
    userMessage: 'genera descripción',
  };

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GEMINI_API_KEY = 'test-key';
  });

  it('returns isDescription: true when model returns a markdown description', async () => {
    mockGenerateContent.mockResolvedValue({
      text: '## Ruta épica\nUna ruta increíble...',
    });

    const service = new GeminiService();
    const result = await service.generateDescription(validReq);

    expect(result.isDescription).toBe(true);
    expect(result.text).toContain('Ruta épica');
  });

  it('returns isDescription: false when model returns a clarifying question', async () => {
    mockGenerateContent.mockResolvedValue({
      text: '¿Cuál es la duración estimada del evento?',
    });

    const service = new GeminiService();
    const result = await service.generateDescription(validReq);

    expect(result.isDescription).toBe(false);
  });

  it('throws Error(AiErrorCode.SAFETY_BLOCKED) when Gemini blocks the request', async () => {
    mockGenerateContent.mockRejectedValue(new Error('SAFETY'));

    const service = new GeminiService();
    await expect(service.generateDescription(validReq)).rejects.toThrow(
      AiErrorCode.SAFETY_BLOCKED,
    );
  });
});
```

> **No agregar** tests de RESOURCE_EXHAUSTED → quota_exceeded_project ni timeout → network_error: ya están en `gemini.service.spec.ts` (líneas 34-62). Duplicarlos crea fragilidad y confusión.

---

## Verificación

```bash
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest src/ai/ai-description.spec.ts --no-coverage
```

Todos los tests deben pasar en verde. Si falla con MODULE_NOT_FOUND: ejecutar el rebuild de contratos del paso 1.

> Full detail: docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md
