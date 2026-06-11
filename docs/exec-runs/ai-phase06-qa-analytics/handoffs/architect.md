# Architect handoff — ai-phase06-qa-analytics

**Date:** 2026-06-10T22:08:01Z
**Status:** done (rev 2 — correcciones Auditor)

---

## Decisiones

| # | Decisión | Justificación |
|---|----------|---------------|
| D1 | `AnalyticsService` se inyecta por constructor en `AiDescriptionChatCubit` — DI lo resuelve automáticamente vía `@injectable` | Clean Architecture: presentación no puede llamar `getIt` directamente; el cubit ya recibe sus use cases por constructor, patrón uniforme |
| D2 | Los `logEvent` van en `sendMessage` y `retryLastMessage`, NO en el bloc listener del widget | El PRD fija como criterio de aceptación bloqueante que ningún `logEvent('ai_*')` aparezca fuera de `*_cubit.dart` |
| D3 | Las constantes de cuota de portada (`aiGenerationTypeCover`) se agregan en `AnalyticsParams` como placeholder de string aunque el cubit de portada no exista | PRD CA2 explícito; sirve para la fase futura sin romper nada hoy |
| D4 | `ai-description.spec.ts` se crea como archivo separado para cubrir los gaps genuinamente ausentes: (a) validación `history > 10 turnos` — requiere agregar `@ArrayMaxSize(10)` al DTO para que el test sea ejecutable en verde; (b) happy-path `GeminiService.generateDescription` con `isDescription true/false`; (c) safety_blocked path en `GeminiService`. Los escenarios de quota/network **ya están cubiertos** en `gemini.service.spec.ts` y no se duplican. | La rev 1 incluía un test `history > 10 → 400` que sería siempre RED porque el DTO no tiene `@ArrayMaxSize(10)`; la rev 2 corrige esto agregando el decorator al DTO. `gemini.service.spec.ts` ya aserta RESOURCE_EXHAUSTED → quota_exceeded_project y timeout → network_error; duplicarlos crea fragilidad. |
| D5 | `app_es.arb` no recibe modificaciones: los 4 keys de error tipado (`ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`) ya existen en líneas 1173-1176 | Confirmado con grep; agregar duplicados violaría el guardrail de regresión |
| D6 | `markdown_to_delta_converter_test.dart` recibe 2 tests adicionales (bold+italic combinado, input vacío) que faltan para cumplir CA8 | El resto de los 6 escenarios ya está cubierto |
| D7 | El `aiTurnIndex` en el snippet de analytics se calcula como `newHistory.length` donde `newHistory = [...updatedHistory, modelTurn]` en `sendMessage` y `newHistory = [...state.history, modelTurn]` en `retryLastMessage` | `retryLastMessage` no tiene variable `updatedHistory`; usar `newHistory.length` hace la expresión uniforme e inequívoca en ambos métodos. Equivale a: índice 1-based del turno del modelo en la historia final. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/core/services/analytics/analytics_events.dart` | modify | Agregar `aiDescriptionGenerated`, `aiQuotaExceeded`, `aiGenerationFailed` | low |
| `lib/core/services/analytics/analytics_params.dart` | modify | Agregar `aiTurnIndex`, `aiGenerationType`, `aiErrorCode`, `aiGenerationTypeCover`, `aiGenerationTypeDescription` | low |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | modify | Inyectar `AnalyticsService`; añadir `logEvent` en `sendMessage` y `retryLastMessage` con expresión `newHistory.length` | med |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | modify | Añadir mock de `AnalyticsService` y 4 tests de verificación de analytics (CA7) | low |
| `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart` | modify | Añadir 2 tests faltantes: bold+italic combinado, input vacío (CA8) | low |
| `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` | modify | Agregar `@ArrayMaxSize(10)` al campo `history` para que el test history>10 sea ejecutable en verde (D4) | low |
| `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` | create | Spec dedicada: history>10 → 400 (requiere D4), GeminiService happy-path + safety_blocked | low |
| `docs/features/events.md` | modify | Marcar `POST /events/generate-cover` como ELIMINADO; agregar sección "Asistentes IA" con `POST /ai/description` | low |

**Archivos que NO se tocan (confirmados por análisis):**
- `lib/l10n/app_es.arb` — los 4 keys `ai_error_*` ya existen (líneas 1173-1176)
- `lib/l10n/app_localizations_es.dart` — solo se regenera si app_es.arb cambia (no cambia)
- `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` — no existe en el repo
- `gemini.service.spec.ts` — ya cubre quota/network; no se modifica
- `ai.controller.spec.ts` — ya cubre todos los escenarios del controller; no se modifica

---

## Contratos rideglory-api

### `POST /ai/description` (ya implementado en Fase 4 — solo documentar y testear)

**Auth:** Firebase ID token (Bearer)

**Request body** (`AiDescriptionRequestDto`):
```json
{
  "eventContext": {
    "title": "Ruta de los Andes",        // required string
    "eventType": "tourism",              // required EventType enum
    "city": "Medellín",                  // required string
    "difficulty": "intermediate",        // optional
    "startDate": "2026-07-15"            // optional
  },
  "userMessage": "Genera una descripción emocionante...",  // required
  "history": [                           // optional, max 10 turns (ArrayMaxSize(10))
    { "role": "user", "content": "..." },
    { "role": "model", "content": "..." }
  ]
}
```

**Success 200** (`AiDescriptionResponseDto`):
```json
{
  "markdown": "## Título\nContenido...",
  "remainingGenerations": 7,
  "isDescription": true
}
```

**Errores:**
| HTTP | Body `error` field | Caso |
|------|--------------------|------|
| 400 | `BadRequestException` (NestJS ValidationPipe) | `title` faltante o `history` > 10 elementos |
| 422 | `"safety_blocked"` | Gemini rechazó por contenido |
| 429 | `"quota_exceeded_user"` + `remaining: 0` | Límite diario del usuario |
| 429 | `"quota_exceeded_project"` | Límite de la API key de Gemini |
| 503 | `"network_error"` | Error de red / inesperado hacia Gemini |

### `GET /ai/quota` (ya implementado — sin cambios)
Retorna `{ descriptionRemaining: number }`.

### Contracts rebuild (pasos obligatorios tras modificar el DTO)

Después de agregar `@ArrayMaxSize(10)` a `ai-description-request.dto.ts`:

```bash
# 1. Rebuild el paquete de contratos
cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
npm run build

# 2. Re-instalar en api-gateway para que recoja el dist actualizado
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
pnpm install

# 3. Verificar que el test pasa
npx jest src/ai/ai-description.spec.ts --no-coverage
```

> Referencia: memory `project_contracts_rebuild_gotcha.md` — si no se hace `npm run build` + `pnpm install`, los specs fallan con MODULE_NOT_FOUND.

---

## Datos / Migraciones

No aplica. La cuota vive en Firestore (no Prisma). No hay migración de base de datos en esta fase.

---

## Env

No se agregan variables de entorno. `GEMINI_API_KEY` ya existe desde Fase 4.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| La modificación del DTO `AiDescriptionRequestDto` con `@ArrayMaxSize(10)` es un cambio productivo del backend; requiere rebuild de rideglory-contracts antes de que los specs compilen | Documentado en "Contracts rebuild" arriba; sin rebuild el spec falla con MODULE_NOT_FOUND |
| La inyección de `AnalyticsService` en el cubit rompe los BlocProviders existentes si no se actualiza el provider del form | El cubit es `@injectable`; el `BlocProvider` en el form usa `getIt` para resolverlo — DI resuelve el nuevo parámetro automáticamente. Sin riesgo si se sigue el patrón existente |
| Los tests del cubit requieren mock de `AnalyticsService` — al agregar el 3er parámetro, todas las instancias del cubit en tests deben actualizarse | Tres puntos afectados: el grupo de tests AC15/AC16 existentes, los 4 nuevos tests de analytics, y potencialmente `ai_description_chat_sheet_test.dart` si instancia el cubit directamente |
| La expresión `newHistory.length` en `retryLastMessage` podría no coincidir semánticamente con `updatedHistory.length + 1` de `sendMessage` si el estado tiene history anterior | Son equivalentes por definición: `newHistory = [...state.history, modelTurn]` → `newHistory.length = state.history.length + 1`; y en `sendMessage` `updatedHistory.length + 1 = state.history.length + 2` (user turn + model turn). La uniformidad es que ambos usan `newHistory.length` que es el índice 1-based del último turno modelo |

---

## Orden de implementación

1. **Contracts DTO** — `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` (agregar `@ArrayMaxSize(10)`) + rebuild
2. **Analytics constants** — `analytics_events.dart`, `analytics_params.dart` (ninguna dependencia Flutter)
3. **Cubit** — `ai_description_chat_cubit.dart` (depende de que las constantes existan)
4. **Cubit test** — `ai_description_chat_cubit_test.dart` (depende del cubit actualizado)
5. **Converter test** — `markdown_to_delta_converter_test.dart` (independiente, paralelizable con 4)
6. **Backend spec** — `ai-description.spec.ts` (independiente del Flutter, depende del rebuild de contratos del paso 1)
7. **Docs** — `docs/features/events.md` (independiente, al final)
8. **Verificación final** — `dart analyze` + `flutter test` + `npx jest src/ai/ai-description.spec.ts`

---

## Superficie de regresión

- `AiDescriptionChatCubit`: constructor cambia de 2 a 3 parámetros. Todos los lugares donde se instancia directamente (BlocProvider en el form, archivos de test) deben actualizarse.
- `ai_description_chat_sheet_test.dart`: verificar si instancia el cubit directamente o usa `MockAiDescriptionChatCubit extends Mock` (en cuyo caso no requiere cambio).
- Los tests existentes AC15/AC16 en `ai_description_chat_cubit_test.dart` deben seguir pasando tras la refactorización del constructor.
- `dart analyze` debe mantenerse en 0 errores/warnings (las nuevas constantes de analytics son `static const String`).
- El cambio en el DTO de contratos es backward-compatible (agrega validación más estricta en un campo opcional). Clientes que envíen ≤10 turnos no se ven afectados.
- `gemini.service.spec.ts` y `ai.controller.spec.ts` no se modifican — sus tests deben seguir verdes.

---

## Fuera de alcance

- `AiCoverChatCubit` — eliminado en Fase 5; no existe; no se crea
- `ai-cover.spec.ts` — endpoint eliminado en Fase 5
- `GenerateEventCoverUseCase` — eliminado; no se testea
- Constantes `aiImageGenerated`, `aiCoverUsed` en `AnalyticsEvents` — reservadas para cuando el cubit de portada se reimplemente
- Deploy EC2 — fuera de scope automático
- Tests E2E / patrol
- Migración Prisma
