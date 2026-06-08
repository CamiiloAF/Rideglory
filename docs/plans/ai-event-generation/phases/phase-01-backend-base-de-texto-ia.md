# Fase 1 — Backend — Base de texto IA

**Slug:** ai-event-generation
**Fase:** 1 de 6
**Fecha:** 2026-06-05T21:52:44Z
**Nivel rg-exec recomendado:** normal

---

## Objetivo

El backend expone `POST /ai/description` que recibe contexto de evento + historial de chat y devuelve una descripción en Markdown generada por Gemini. El endpoint legacy `POST /events/generate-cover` (Unsplash + Claude) permanece intacto y la app existente no se interrumpe. Al final de esta fase el `AiModule` está operativo en api-gateway y los DTOs están publicados en rideglory-contracts.

---

## Alcance (entra / no entra)

### Entra
- Instalar `@google/genai` en `api-gateway/package.json`
- Crear directorio `api-gateway/src/ai/` con `AiModule`, `AiController` y `GeminiService`
- `GeminiService.generateDescription()`: llama a Gemini texto con historial de turnos, devuelve Markdown
- Modelo de texto configurable via `GEMINI_TEXT_MODEL` (env var); valor por defecto sugerido: `'gemini-2.5-flash'`
- Prompt del sistema con contexto rider colombiano (idioma español, Colombia, motociclismo)
- Endpoint `POST /ai/description` protegido automáticamente por el `APP_GUARD` global (`FirebaseAuthGuard` registrado en `auth.module.ts`) — sin anotación adicional en el controller
- Publicar en `rideglory-contracts/src/ai/`: `AiDescriptionRequestDto`, `AiDescriptionResponseDto`, `AiChatTurnDto`, `AiErrorResponseDto`, enum `AiChatRole`, enum `AiErrorCode`
- `AiDescriptionResponseDto` incluye campo `remainingGenerations: number` (ver nota de campo de control en la sección "Contratos")
- Agregar `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` a `api-gateway/.env.example`
- Registrar `AiModule` en `AppModule`
- Spec básico del controller (mock de `@google/genai`)

### No entra
- Generación de imágenes / portadas (Fase 2)
- Sistema de cuotas / límites diarios (Fase 3)
- Integración Flutter (Fases 4-5)
- Eliminar `ClaudeService`, `UnsplashService` ni el endpoint `POST /events/generate-cover` (Fase 5)
- Variables de entorno en EC2 (se documentan para deploy al final del plan; sin despliegue en esta fase)
- `StorageCleanupService` ni cron de barrido (Fase 2)

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Instalar dependencia Gemini**
   ```bash
   cd api-gateway && npm install @google/genai
   ```
   Verificar que el paquete quede en `dependencies` (no `devDependencies`) en `package.json`.

2. **Crear directorio `api-gateway/src/ai/`** con estructura:
   ```
   api-gateway/src/ai/
     ai.module.ts
     ai.controller.ts
     gemini.service.ts
     ai.controller.spec.ts
   ```

3. **Implementar `GeminiService`** (`gemini.service.ts`):
   - `@Injectable()` dentro de `AiModule`
   - Constructor: leer `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` de `process.env`; **lanzar `Error` descriptivo en startup si `GEMINI_API_KEY` está ausente o vacía** (`throw new Error('GEMINI_API_KEY is required')`); el modelo por defecto si `GEMINI_TEXT_MODEL` no está definido es `'gemini-2.5-flash'`
   - Método `async generateDescription(context: AiDescriptionEventContext, history: AiChatTurnDto[]): Promise<string>`:
     - Construir historial de contenido a partir de `history` (máx 10 turnos — el cliente recorta; el servicio acepta lo que llega)
     - System prompt en español con contexto rider colombiano (ver paso 4)
     - Llamada usando la superficie real de `@google/genai`:
       ```typescript
       const ai = new GoogleGenAI({ apiKey });
       const response = await ai.models.generateContent({
         model,
         contents,
         config: { systemInstruction },
       });
       return response.text; // propiedad string, no método
       ```
       **Verificar contra la documentación de `@google/genai` antes de merge** — la superficie del SDK puede diferir si la versión instalada es anterior a la 1.x estable; en particular confirmar que `response.text` es una propiedad string (no una función) y que `ai.models` es el namespace correcto.
     - Lanzar `HttpException` con código `network_error` (503) ante errores de red/timeout; lanzar con código `safety_blocked` (422) ante respuestas con `HARM_CATEGORY_*` bloqueadas
     - Envolver la llamada en `Promise.race` con timeout de 30 s; lanzar `network_error` si se excede

4. **Definir prompt del sistema** (constante en `gemini.service.ts` o en `ai/prompts/description.prompt.ts`):
   ```
   Eres un asistente para organizadores de eventos de motociclismo en Colombia.
   Tu objetivo es ayudar a redactar descripciones atractivas y claras para eventos de riders.
   Responde siempre en español colombiano informal pero profesional.
   Usa formato Markdown: párrafos, ## subtítulos, **negrita**, *itálica*, listas con guión.
   Sé conciso: máximo 400 palabras por respuesta.
   Contexto del evento: {title}, tipo {eventType}, ciudad {city}.
   ```
   La interpolación del contexto se realiza antes de pasar el system instruction.

5. **Implementar `AiController`** (`ai.controller.ts`):
   - `@Controller('ai')` — **sin** `@UseGuards(FirebaseAuthGuard)` en el controller ni en el método; el `APP_GUARD` registrado en `auth.module.ts` (como `APP_GUARD` global de NestJS) ya protege automáticamente todas las rutas; no se requiere anotación explícita. Si una ruta necesitara ser pública, usaría el decorador `@Public()` definido en `api-gateway/src/auth/decorators/public.decorator.ts` — no aplica aquí.
   - `@Post('description')` → recibe `AiDescriptionRequestDto`; llama `geminiService.generateDescription()`; devuelve `AiDescriptionResponseDto`
   - `remainingGenerations` en el response se fija en `-1` en esta fase (sin cuota real — Fase 3 lo reemplaza); el campo es obligatorio en el contrato desde ya
   - Manejo de excepciones: atrapar `HttpException` de `GeminiService` y re-lanzar con `AiErrorResponseDto` como body
   - Anotación `@ApiBearerAuth()` + `@ApiTags('ai')` si hay Swagger configurado

6. **Crear `AiModule`** (`ai.module.ts`):
   - `providers: [GeminiService]`
   - `controllers: [AiController]`
   - Sin `exports` en esta fase (el servicio no es necesario fuera del módulo)

7. **Registrar `AiModule` en `AppModule`** (`app.module.ts`):
   - Agregar `AiModule` al array `imports` de `@Module`

8. **Publicar DTOs en `rideglory-contracts/src/ai/`**:
   - Crear directorio `rideglory-contracts/src/ai/`
   - Crear `rideglory-contracts/src/ai/enums.ts` con `AiChatRole` y `AiErrorCode`
   - Crear los 4 DTOs (ver sección "Archivos a crear/modificar")
   - Crear `rideglory-contracts/src/ai/index.ts` re-exportando todo
   - Agregar `export * from './ai';` al `rideglory-contracts/src/index.ts`

9. **Agregar env vars a `api-gateway/.env.example`**:
   ```dotenv
   # Gemini Developer API (free tier)
   GEMINI_API_KEY=your_gemini_api_key_here
   # Modelo de texto Gemini (default: gemini-2.5-flash)
   GEMINI_TEXT_MODEL=gemini-2.5-flash
   ```

10. **Escribir spec `ai.controller.spec.ts`**:
    - Mock de `@google/genai` retornando texto Markdown fijo
    - Caso feliz: `POST /ai/description` responde 200 con `{ markdown: '...', remainingGenerations: -1 }`
    - Caso error de red: responde 503 con `{ error: 'network_error' }`
    - Caso safety: responde 422 con `{ error: 'safety_blocked' }`
    - Usar `eventType: EventType.TOURISM` en todos los fixtures (ver sección "Contratos")

11. **Verificar** con `npm run build` (sin errores TypeScript) y `npm test` (specs pasan); el servicio arranca sin error cuando `GEMINI_API_KEY` está definida en `.env`, y el constructor lanza `Error` descriptivo cuando está ausente (verificable con test unitario del constructor).

---

## Archivos a crear/modificar (rutas reales)

### rideglory-api/api-gateway

| Ruta | Accion | Que cambia |
|------|--------|-----------|
| `api-gateway/package.json` | Modificar | Agrega `"@google/genai": "^1.x"` en `dependencies` |
| `api-gateway/src/ai/ai.module.ts` | Crear | `AiModule` NestJS: providers `[GeminiService]`, controllers `[AiController]` |
| `api-gateway/src/ai/ai.controller.ts` | Crear | `@Controller('ai')` con `@Post('description')`; sin `@UseGuards` — protegido por `APP_GUARD` global; mapeo a `AiDescriptionResponseDto` |
| `api-gateway/src/ai/gemini.service.ts` | Crear | `GeminiService.generateDescription()` con `@google/genai`, model ID desde `GEMINI_TEXT_MODEL`, system prompt, timeout 30s, manejo de errores |
| `api-gateway/src/ai/ai.controller.spec.ts` | Crear | Tests unitarios del controller (mock GeminiService) con fixtures usando `EventType.TOURISM` |
| `api-gateway/src/app.module.ts` | Modificar | Agrega `AiModule` al array `imports` |
| `api-gateway/.env.example` | Modificar | Agrega `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` con comentarios descriptivos |

### rideglory-api/rideglory-contracts

| Ruta | Accion | Que cambia |
|------|--------|-----------|
| `rideglory-contracts/src/ai/enums.ts` | Crear | Enum `AiChatRole { user = 'user', model = 'model' }` y `AiErrorCode { quotaExceededUser = 'quota_exceeded_user', quotaExceededProject = 'quota_exceeded_project', safetyBlocked = 'safety_blocked', networkError = 'network_error' }` |
| `rideglory-contracts/src/ai/ai-chat-turn.dto.ts` | Crear | `AiChatTurnDto { role!: AiChatRole; content!: string }` con validadores `class-validator` y asignación definitiva |
| `rideglory-contracts/src/ai/ai-description-request.dto.ts` | Crear | `AiDescriptionRequestDto { eventContext!: AiDescriptionEventContext; history!: AiChatTurnDto[] }` con nested class `AiDescriptionEventContext` exportada explícitamente; importa `EventType` desde `'../events/enums'` |
| `rideglory-contracts/src/ai/ai-description-response.dto.ts` | Crear | `AiDescriptionResponseDto { markdown!: string; remainingGenerations!: number }` con nota de campo de control (ver "Contratos") |
| `rideglory-contracts/src/ai/ai-error-response.dto.ts` | Crear | `AiErrorResponseDto { error!: AiErrorCode; remaining?: number; message?: string }` |
| `rideglory-contracts/src/ai/index.ts` | Crear | Re-exporta todos los DTOs, enums y clases anidadas del directorio |
| `rideglory-contracts/src/index.ts` | Modificar | Agrega `export * from './ai';` |

---

## Contratos / API rideglory-api

### POST /ai/description

```
Auth:    Bearer (Firebase ID token — obligatorio; APP_GUARD global cubre la ruta automáticamente)
Request body:
{
  "eventContext": {
    "title": "Rodada al páramo de Sumapaz",
    "eventType": "TOURISM",        // enum EventType — valores válidos: TOURISM, URBAN, OFF_ROAD,
                                   // COMPETITION, SOLIDARITY, SHORT_DISTANCE
    "city": "Bogotá",
    "audience": "riders intermedios y avanzados"  // opcional
  },
  "history": [                    // máx 10 turnos; [] en el primer turno
    { "role": "user",  "content": "Hazla más épica y menciona la niebla" },
    { "role": "model", "content": "## Desafío entre nubes\n..." }
  ]
}

Response 200:
{
  "markdown": "## Rodada épica al páramo\n\nEntre la niebla...",
  "remainingGenerations": -1    // -1 = cuota no implementada aún (Fase 3)
}

Response 422:
{
  "error": "safety_blocked",
  "message": "La solicitud fue bloqueada por el filtro de seguridad de Gemini."
}

Response 503:
{
  "error": "network_error",
  "message": "Error de red al contactar Gemini API."
}

Response 401: (token inválido/ausente — APP_GUARD global)
Response 400: (body inválido — class-validator)
```

**Nota:** los códigos 429 (`quota_exceeded_user`, `quota_exceeded_project`) no se implementan en esta fase. Se agregan en Fase 3.

### DTOs: notas de implementación

**`ai-description-request.dto.ts` — clase anidada `AiDescriptionEventContext` con asignación definitiva:**

```typescript
import { EventType } from '../events/enums'; // importar desde rideglory-contracts

export class AiDescriptionEventContext {
  @IsString() title!: string;
  @IsEnum(EventType) eventType!: EventType;
  @IsString() city!: string;
  @IsOptional() @IsString() audience?: string;
}

export class AiDescriptionRequestDto {
  @ValidateNested() @Type(() => AiDescriptionEventContext)
  eventContext!: AiDescriptionEventContext;

  @IsArray() @ValidateNested({ each: true }) @Type(() => AiChatTurnDto)
  history!: AiChatTurnDto[];
}
```

`AiDescriptionEventContext` debe ser una clase exportada a nivel de módulo (no inline), para que `@ValidateNested` + `class-transformer` funcionen correctamente. Se re-exporta desde `rideglory-contracts/src/ai/index.ts`.

El uso de asignación definitiva (`!`) es la convención de rideglory-contracts para propiedades de DTO inicializadas vía `class-transformer`; evita el error TS2564 sin deshabilitar `strictPropertyInitialization` en el tsconfig.

**`ai-description-response.dto.ts` — campo de control `remainingGenerations` con asignación definitiva:**

```typescript
export class AiDescriptionResponseDto {
  // Excepción Pattern B: DTO compuesto con campo de control (remainingGenerations)
  // que no pertenece al modelo domain AiChatTurn. No extiende modelo domain.
  // Se fija en -1 hasta que la lógica de cuota esté activa (Fase 3).
  markdown!: string;
  remainingGenerations!: number;
}
```

*Nota para implementadores Flutter (Fases 4-5):* el DTO homólogo en Dart es una excepción documentada al estándar Pattern B del proyecto: es un DTO de respuesta compuesto (campo de control + dato de dominio) sin modelo de dominio 1:1. Comentar inline en el archivo Dart con: `// Excepción Pattern B: DTO de respuesta compuesto; remainingGenerations es campo de control sin modelo domain equivalente.`

**`ai-chat-turn.dto.ts` — asignación definitiva:**

```typescript
export class AiChatTurnDto {
  @IsEnum(AiChatRole) role!: AiChatRole;
  @IsString() content!: string;
}
```

**`ai-error-response.dto.ts` — asignación definitiva:**

```typescript
export class AiErrorResponseDto {
  @IsEnum(AiErrorCode) error!: AiErrorCode;
  @IsOptional() @IsNumber() remaining?: number;
  @IsOptional() @IsString() message?: string;
}
```

---

## Cambios de datos / migraciones

Ninguno. Esta fase no toca Prisma, Firestore ni ninguna base de datos. La cuota en Firestore es responsabilidad de Fase 3.

---

## Criterios de aceptacion

1. `npm run build` en `api-gateway` termina sin errores TypeScript.
2. `POST /ai/description` con un body válido y token Firebase válido responde 200 con un campo `markdown` de tipo string no vacío y `remainingGenerations: -1`.
3. `POST /ai/description` sin `Authorization` header responde 401 — el `APP_GUARD` global (`FirebaseAuthGuard` registrado en `auth.module.ts`) protege la ruta automáticamente; no hay anotación `@UseGuards` en el controller.
4. `POST /ai/description` con body malformado (falta `eventContext.title`) responde 400 (class-validator en pipe global).
5. `POST /ai/description` cuando `@google/genai` lanza error de red retorna 503 con body `{ error: 'network_error' }`.
6. `POST /ai/description` cuando Gemini retorna bloqueo de safety retorna 422 con body `{ error: 'safety_blocked' }`.
7. `POST /events/generate-cover` sigue respondiendo igual que antes (sin regresión — no se tocó `EventsController`).
8. `rideglory-contracts/src/ai/index.ts` exporta: `AiChatTurnDto`, `AiDescriptionRequestDto`, `AiDescriptionEventContext`, `AiDescriptionResponseDto`, `AiErrorResponseDto`, `AiChatRole`, `AiErrorCode`.
9. Todos los specs nuevos pasan con `npm test`.
10. `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` aparecen en `api-gateway/.env.example` con comentarios descriptivos.
11. El constructor de `GeminiService` lanza `Error` descriptivo (`'GEMINI_API_KEY is required'`) cuando la variable de entorno está ausente o vacía — verificable con un test unitario del constructor. El servicio arranca correctamente cuando `GEMINI_API_KEY` está definida.

---

## Pruebas

### Unitarias (spec en api-gateway)

**`api-gateway/src/ai/ai.controller.spec.ts`:**

| Caso | Descripcion | Asercion |
|------|-------------|----------|
| Happy path | Mock `GeminiService.generateDescription` retorna `"## Test\nContenido"`; body usa `eventType: EventType.TOURISM` | Response 200, `body.markdown === '## Test\nContenido'`, `body.remainingGenerations === -1` |
| Network error | Mock lanza `new HttpException({ error: 'network_error' }, 503)` | Response 503, `body.error === 'network_error'` |
| Safety blocked | Mock lanza `new HttpException({ error: 'safety_blocked' }, 422)` | Response 422, `body.error === 'safety_blocked'` |
| History vacío | `history: []` — primer turno; `eventType: EventType.TOURISM` | Response 200 (el servicio acepta historial vacío) |
| History con 10 turnos | `history` con exactamente 10 items | Response 200 — no se rechaza por longitud |
| GEMINI_API_KEY ausente | Constructor de `GeminiService` sin env var definida | Lanza `Error` con mensaje descriptivo (no falla silenciosamente) |

### De integración (manual / verificacion)

- Arrancar api-gateway local con `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` reales en `.env`
- Llamar `POST /ai/description` con token Firebase de un usuario de prueba y body mínimo válido (`eventType: 'TOURISM'`)
- Verificar que `markdown` en el response contiene texto en español con formato Markdown

### No aplican en esta fase

- Tests Flutter (Fases 4-5)
- Tests de cuota (Fase 3)

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigacion |
|----|--------|------|---------|-----------|
| R-01 | `@google/genai` cambia su superficie pública entre versiones (SDK relativamente nuevo) — en particular `response.text` como propiedad vs. método, y el namespace `ai.models` | Media | Medio | Verificar contra la documentación oficial de `@google/genai` antes de merge; fijar versión mayor en `package.json` (`"^1.x"`); el código de llamada debe incluir comentario "verificar contra docs de @google/genai" hasta que se confirme con prueba de integración manual |
| R-02 | `GEMINI_API_KEY` ausente en dev local → el constructor lanza `Error` al arrancar | Baja | Bajo | El constructor valida la presencia y lanza `Error` descriptivo; esto es el comportamiento correcto; el desarrollador debe copiar `.env.example` antes de correr el servicio |
| R-03 | Formato de historial `contents[]` incorrecto para `@google/genai` → 400 de Gemini | Media | Bajo | Leer documentación de `GenerateContentRequest.contents`; validar con un test de integración manual antes de merge |
| R-04 | Llamada a `GeminiService` sin timeout → request cuelga indefinidamente | Baja | Medio | Envolver llamada en `Promise.race` con timeout de 30s; lanzar `network_error` si se excede |
| R-05 | `class-validator` no instalado en rideglory-contracts | Baja | Bajo | Verificar `package.json` de rideglory-contracts; si no está, agregar `class-validator` y `class-transformer` como `peerDependencies` |
| R-06 | `EventType` no re-exportado desde `rideglory-contracts/src/index.ts` en la rama correcta | Baja | Bajo | Confirmar que `export * from './events'` está en `rideglory-contracts/src/index.ts` antes de importar desde `'../events/enums'` en el DTO de IA |
| R-07 | Valor inválido de `eventType` en fixtures/ejemplos → 400 por enum incorrecto | Baja | Bajo | Todos los ejemplos y fixtures usan `EventType.TOURISM`; valores válidos del enum: TOURISM, URBAN, OFF_ROAD, COMPETITION, SOLIDARITY, SHORT_DISTANCE |

---

## Dependencias

**Fases prerequisito:** ninguna. Esta es la primera fase del plan; no depende de cambios previos en Flutter ni backend.

**Dependencias externas:**
- Cuenta Gemini Developer API activa con free tier habilitado (clave `GEMINI_API_KEY`)
- Modelo de texto Gemini disponible en free tier (default `gemini-2.5-flash`; configurable via `GEMINI_TEXT_MODEL`)
- `api-gateway` arrancando localmente con el `.env` actualizado para pruebas de integración manual

**Bloqueantes para fases siguientes:**
- Fase 2 (portada IA) importa `GeminiService` y lo extiende con `generateCover()`; requiere que el módulo y el servicio estén creados
- Fase 3 (cuotas) inyecta `AiQuotaService` en `AiController`; requiere que el controller esté estructurado
- Los DTOs de rideglory-contracts publicados aquí son los que Fases 4-5 usarán desde Flutter

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que normal:**

Nuevo módulo NestJS con contratos externos (rideglory-contracts) e integración con API Gemini. Sin migración de datos, sin cambios de seguridad/auth. Blast radius acotado a api-gateway (el único archivo compartido existente que se modifica es `app.module.ts` — una línea de import).

El riesgo principal es la integración con el proveedor externo (Gemini): superficie real del SDK `@google/genai` (propiedad `response.text` vs. método, namespace `ai.models`), formato del request `contents[]`, manejo de errores del SDK, y comportamiento cuando la clave no está configurada. Estos son puntos que un auditor debe revisar en el código generado.

Nivel **normal** cubre: Architect pass (verifica estructura del módulo y manejo de errores), Build pass (implementa el código), QA pass (escribe specs), y 2 rondas del auditor Opus para validar la integración Gemini y la estructura de contratos antes de aprobar.

Nivel `lite` sería insuficiente porque hay un contrato externo (rideglory-contracts) que debe quedar correcto desde el inicio — errores aquí propagan a Fases 2-5. Nivel `full` sería sobredimensionado dado que no hay migración de datos ni cambios de auth.
