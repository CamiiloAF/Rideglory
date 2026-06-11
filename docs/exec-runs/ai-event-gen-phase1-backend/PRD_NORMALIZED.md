# PRD Normalizado — ai-event-gen-phase1-backend

**Generado:** 2026-06-05T22:39:40Z
**Fuente:** docs/plans/ai-event-generation/phases/phase-01-backend-base-de-texto-ia.md
**Nivel rg-exec:** normal

---

## 1 Objetivo

Exponer `POST /ai/description` en `api-gateway` de `rideglory-api`: recibe contexto de evento + historial de chat (hasta 10 turnos) y devuelve una descripción en Markdown generada por Gemini. El endpoint legacy `POST /events/generate-cover` queda intacto. Al finalizar la fase, `AiModule` está operativo y los DTOs están publicados en `rideglory-contracts`.

---

## 2 Por qué

La generación de descripciones de eventos con IA es el núcleo del plan `ai-event-generation`. Esta fase establece el módulo base (`AiModule`, `GeminiService`, contratos) del que dependen las fases 2–5. Sin los DTOs publicados en `rideglory-contracts`, las fases de Flutter (4-5) no pueden arrancar. El blast radius está acotado a `api-gateway/src/ai/` y un único import en `app.module.ts`.

---

## 3 Alcance

### Entra
- Instalar `@google/genai` en `api-gateway/package.json` (en `dependencies`)
- Crear `api-gateway/src/ai/` con `AiModule`, `AiController`, `GeminiService`, `ai.controller.spec.ts`
- `GeminiService.generateDescription()`: llama a Gemini con historial de turnos, system prompt en español colombiano, timeout de 30 s (`Promise.race`), manejo de errores (503 network_error, 422 safety_blocked)
- Modelo de texto configurable vía `GEMINI_TEXT_MODEL` (default `gemini-2.5-flash`)
- Constructor de `GeminiService` lanza `Error` descriptivo si `GEMINI_API_KEY` está ausente o vacía
- `AiController` sin `@UseGuards` — protegido por `APP_GUARD` global (`FirebaseAuthGuard`)
- `remainingGenerations: -1` en respuesta (cuota real en Fase 3)
- Publicar en `rideglory-contracts/src/ai/`: `AiChatTurnDto`, `AiDescriptionRequestDto`, `AiDescriptionEventContext`, `AiDescriptionResponseDto`, `AiErrorResponseDto`, enum `AiChatRole`, enum `AiErrorCode`
- `rideglory-contracts/src/index.ts` re-exporta `./ai`
- `api-gateway/.env.example` con `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL`
- `AiModule` registrado en `AppModule`
- Spec básico del controller (mock de `@google/genai`, 6 casos)

### No entra
- Generación de imágenes / portadas (Fase 2)
- Sistema de cuotas / límites diarios (Fase 3)
- Integración Flutter (Fases 4-5)
- Eliminar `ClaudeService`, `UnsplashService` ni `POST /events/generate-cover` (Fase 5)
- Variables de entorno en EC2 ni despliegue
- `StorageCleanupService` ni cron de barrido (Fase 2)
- Códigos 429 (`quota_exceeded_user`, `quota_exceeded_project`)

---

## 4 Áreas afectadas

| Repo | Ruta | Tipo de cambio |
|------|------|---------------|
| `rideglory-api` | `api-gateway/package.json` | Agrega dependencia `@google/genai` |
| `rideglory-api` | `api-gateway/src/ai/` (nuevo directorio) | Crea 4 archivos: module, controller, service, spec |
| `rideglory-api` | `api-gateway/src/app.module.ts` | Agrega `AiModule` al array `imports` |
| `rideglory-api` | `api-gateway/.env.example` | Agrega 2 variables con comentarios |
| `rideglory-api` | `rideglory-contracts/src/ai/` (nuevo directorio) | Crea 6 archivos: enums, 4 DTOs, index |
| `rideglory-api` | `rideglory-contracts/src/index.ts` | Agrega `export * from './ai'` |

---

## 5 Criterios de aceptación

1. `npm run build` en `api-gateway` termina sin errores TypeScript.
2. `POST /ai/description` con body válido y token Firebase válido responde 200 con campo `markdown` (string no vacío) y `remainingGenerations: -1`.
3. `POST /ai/description` sin `Authorization` header responde 401 — el `APP_GUARD` global (`FirebaseAuthGuard` en `auth.module.ts`) protege la ruta; no hay `@UseGuards` en el controller.
4. `POST /ai/description` con body malformado (falta `eventContext.title`) responde 400 (class-validator + pipe global).
5. `POST /ai/description` cuando `@google/genai` lanza error de red retorna 503 con body `{ error: 'network_error' }`.
6. `POST /ai/description` cuando Gemini retorna bloqueo de safety retorna 422 con body `{ error: 'safety_blocked' }`.
7. `POST /events/generate-cover` sigue respondiendo igual que antes (sin regresión — no se tocó `EventsController`).
8. `rideglory-contracts/src/ai/index.ts` exporta: `AiChatTurnDto`, `AiDescriptionRequestDto`, `AiDescriptionEventContext`, `AiDescriptionResponseDto`, `AiErrorResponseDto`, `AiChatRole`, `AiErrorCode`.
9. Todos los specs nuevos pasan con `npm test`.
10. `GEMINI_API_KEY` y `GEMINI_TEXT_MODEL` aparecen en `api-gateway/.env.example` con comentarios descriptivos.
11. El constructor de `GeminiService` lanza `Error` descriptivo (`'GEMINI_API_KEY is required'`) cuando la variable de entorno está ausente o vacía — verificable con test unitario del constructor.

---

## 6 Guardrails de regresión

- `POST /events/generate-cover` (Unsplash + Claude) no debe tocarse ni romperse en esta fase.
- `app.module.ts`: el único cambio permitido es agregar `AiModule` al array `imports`; no mover ni reordenar otros módulos.
- No eliminar ni modificar `ClaudeService`, `UnsplashService` ni ningún servicio existente.
- No modificar el esquema de Prisma ni Firestore.
- Los tests existentes (`npm test`) deben seguir pasando sin cambios.
- No agregar `@UseGuards(FirebaseAuthGuard)` explícito al controller — confiar en el `APP_GUARD` global ya configurado.
- No alterar `rideglory-contracts/src/index.ts` más allá de agregar la línea `export * from './ai'`.

---

## 7 Constraints heredados

- **SDK `@google/genai`**: verificar contra documentación oficial antes de merge que `response.text` es propiedad (no método) y que `ai.models` es el namespace correcto; fijar versión mayor `"^1.x"` en `package.json`.
- **Formato de historial**: `contents[]` de Gemini — validar con prueba de integración manual que el mapeo `AiChatTurnDto[] → GenerateContentRequest.contents` es correcto.
- **Asignación definitiva (`!`)**: todos los DTOs en `rideglory-contracts` usan `prop!: Type` para evitar TS2564 sin deshabilitar `strictPropertyInitialization`.
- **`AiDescriptionEventContext`**: debe ser clase exportada a nivel de módulo (no inline) para que `@ValidateNested` + `class-transformer` funcionen.
- **`AiDescriptionResponseDto`** es excepción documentada al estándar Pattern B: DTO de respuesta compuesto (campo de control `remainingGenerations` + dato de dominio `markdown`), sin modelo domain 1:1. Comentar inline.
- **`EventType`**: todos los fixtures y ejemplos usan `EventType.TOURISM`; valores válidos: `TOURISM, URBAN, OFF_ROAD, COMPETITION, SOLIDARITY, SHORT_DISTANCE`.
- **Timeout**: la llamada a Gemini debe envolverse en `Promise.race` con 30 s; lanzar `network_error` si se excede.
- **`class-validator` en rideglory-contracts**: verificar que esté en `package.json` como `peerDependency`; agregar si falta.
- **`EventType` import**: confirmar que `export * from './events'` ya está en `rideglory-contracts/src/index.ts` antes de importar desde `'../events/enums'` en el DTO de IA.
- **Sin despliegue en esta fase**: las variables de entorno para EC2 se documentan pero no se despliegan.
