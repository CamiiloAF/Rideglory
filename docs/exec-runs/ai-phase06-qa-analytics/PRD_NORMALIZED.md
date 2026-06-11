# PRD Normalizado — Fase 6: QA, Analytics y Cierre (ai-event-generation)

**Slug:** ai-phase06-qa-analytics  
**Generado:** 2026-06-10T21:58:03Z  
**Fuente:** docs/plans/ai-event-generation/phases/phase-06-qa-analytics-y-cierre.md  
**Nivel rg-exec:** normal

---

## 1 Objetivo

Cerrar el feature de asistentes IA para eventos con observabilidad completa, tests Flutter al 100%, spec NestJS detallada para el endpoint de descripción, y documentación actualizada del feature — todo sin tocar código productivo nuevo (el comportamiento ya fue implementado en Fases 1-5).

---

## 2 Por qué

El asistente de descripción con IA (Fase 4) no tiene instrumentación de analytics ni tests que cubran los escenarios de error tipados. La documentación del feature (`docs/features/events.md`) sigue referenciando el stack de portada antiguo (Unsplash/Claude, `POST /events/generate-cover`) eliminado en Fase 5. Sin esta fase el feature no es observable en producción y los tests no dan confianza suficiente para el deploy.

---

## 3 Alcance

### Entra
- Agregar constantes de analytics en `AnalyticsEvents` y `AnalyticsParams` para el flujo de descripción IA (+ constantes de portada como placeholders de string, aunque el cubit de portada no existe aún)
- Inyectar `AnalyticsService` en `AiDescriptionChatCubit` y agregar `logEvent(...)` en los métodos de generación y error
- Gate bloqueante: verificar con grep que **ningún** `logEvent('ai_*')` aparece fuera de archivos `*_cubit.dart`
- Verificar que los 4 keys de error tipado YA están en `app_es.arb` (confirmado en el repo actual: `ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`). Solo agregar keys de UI faltantes si no existen
- Crear `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` con cobertura detallada del endpoint `POST /ai/description`
- Actualizar / complementar tests Flutter existentes para cubrir los nuevos escenarios de analytics (los archivos de test ya existen — ver Restricciones)
- Actualizar `docs/features/events.md`: marcar `POST /events/generate-cover` como ELIMINADO (Fase 5), documentar `POST /ai/description`, agregar sección "Asistentes IA"
- `dart analyze` limpio (0 errores, 0 warnings)
- `flutter test` 100% verde

### No entra
- `AiCoverChatCubit` — fue eliminado en Fase 5 junto con todo el stack de portada IA. No existe en el repo. No se crea, no se toca, no se testea
- Spec `ai-cover.spec.ts` — el endpoint `POST /ai/cover` fue eliminado en Fase 5; no se crea spec para él
- Tests de `AiCoverChatCubit` — el cubit no existe; tampoco `generate_event_cover_use_case_test.dart`
- `get_generate_cover_use_case_test.dart` — verificar si existe; si existe, eliminar (imports rotos). Si ya fue eliminado en Fase 5, nada que hacer
- Código de aplicación Flutter nuevo
- Código backend nuevo
- Deploy EC2 (responsabilidad del humano tras revisión local)
- Migración Prisma (cuota vive en Firestore)
- Tests E2E / patrol

---

## 4 Áreas afectadas

| Área | Archivos clave |
|------|---------------|
| Analytics (Flutter) | `lib/core/services/analytics/analytics_events.dart`, `lib/core/services/analytics/analytics_params.dart` |
| Cubit de descripción | `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` |
| Localización | `lib/l10n/app_es.arb`, `lib/l10n/app_localizations_es.dart` (regenerado) |
| Tests Flutter (existentes, a complementar) | `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`, `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`, `test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart`, `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` |
| Spec backend | `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` (crear) |
| Docs | `docs/features/events.md` |
| Test legacy (limpiar si existe) | `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` |

---

## 5 Criterios de aceptación

1. `grep -rn "logEvent.*ai_" lib/ --include="*.dart"` devuelve únicamente líneas en archivos `*_cubit.dart`. Ninguna línea en `*_widget.dart`, `*_page.dart`, `*_screen.dart` ni `*_view.dart`.

2. Las constantes `aiDescriptionGenerated`, `aiQuotaExceeded`, `aiGenerationFailed` existen en `AnalyticsEvents`; `aiGenerationTypeCover` (constante de string, valor `'cover'`) existe en `AnalyticsParams` aunque no se use aún. Las constantes `aiImageGenerated` y `aiCoverUsed` **no se agregan** — corresponden al cubit de portada eliminado.

3. `AiDescriptionChatCubit` recibe `AnalyticsService` por constructor e invoca:
   - `logEvent(aiDescriptionGenerated, {aiTurnIndex: ...})` tras respuesta exitosa
   - `logEvent(aiQuotaExceeded, {aiGenerationType: 'description', aiErrorCode: ...})` tras error de cuota
   - `logEvent(aiGenerationFailed, {aiGenerationType: 'description', aiErrorCode: ...})` tras cualquier otro error

4. Los 4 keys de error tipado ya presentes en `app_es.arb` (`ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`) se conservan sin duplicar. No se agregan keys de UI del asistente de portada (`ai_cover_*`). Solo se agregan keys de UI de descripción que no existan aún.

5. `dart analyze` devuelve 0 errores y 0 warnings en el proyecto Flutter.

6. `flutter test` pasa al 100%: todos los tests existentes siguen verdes; si `get_generate_cover_use_case_test.dart` existe, fue eliminado antes de correr los tests.

7. `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` cubre explícitamente que `analyticsService.logEvent` fue invocado con los parámetros correctos en: happy path (aiDescriptionGenerated), quota exceeded (aiQuotaExceeded + aiGenerationTypeDescription), safety blocked (aiGenerationFailed), network error (aiGenerationFailed).

8. `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart` cubre los escenarios: párrafo simple, `## Heading`, `**bold**`, `*italic*`, `- item` (lista), elemento no soportado (inserción como texto plano sin excepción), combinaciones bold+italic, input vacío.

9. `rideglory-api/api-gateway/src/ai/ai-description.spec.ts` existe y contiene suites para: happy path (200 + `{markdown, remainingGenerations}`), quota exceeded user (429), quota exceeded project (429), safety blocked (422), network error (503), validación DTO (`BadRequestException` si falta `title`, si `history` > 10 turnos), unit de `GeminiService.generateDescription`.

10. `docs/features/events.md` documenta `POST /ai/description`; `POST /events/generate-cover` está marcado como `ELIMINADO (Fase 5)`; existe sección "Asistentes IA" con el flujo de `AiDescriptionChatCubit`, `GenerateEventDescriptionUseCase`, `MarkdownToDeltaConverter`. No menciona `POST /ai/cover` (eliminado).

---

## 6 Guardrails de regresión

- No modificar ningún widget, page ni screen — esta fase es solo analytics, tests y docs
- No alterar `DomainException` base si no es estrictamente necesario para el mapeo de `_toAnalyticsErrorCode`; preferir el patrón `if (error is AiQuotaExceededUserException)` usando las subclases ya existentes en `lib/core/exceptions/ai_domain_exceptions.dart`
- No agregar strings duplicadas en `app_es.arb` — verificar existencia antes de insertar cualquier key
- No crear archivos de test para cubit de portada ni para `GenerateEventCoverUseCase` — ese código fue eliminado
- No crear `ai-cover.spec.ts` — el endpoint fue eliminado en Fase 5
- No agregar `aiImageGenerated` ni `aiCoverUsed` en `AnalyticsEvents` — corresponden al stack de portada eliminado
- Los tests de Fase 4 ya existentes (`ai_description_chat_cubit_test.dart`, `markdown_to_delta_converter_test.dart`, `ai_description_chat_sheet_test.dart`, `generate_event_description_use_case_test.dart`) deben seguir pasando — solo complementar cobertura de analytics si falta

---

## 7 Constraints heredados

- **Clean Architecture:** `AnalyticsService` se inyecta por constructor en `AiDescriptionChatCubit`; no usar `getIt<AnalyticsService>()` directamente en el cubit. El cubit es `@injectable` — el DI resuelve la inyección automáticamente.
- **Un widget por archivo:** no aplica a esta fase (no se crean widgets).
- **Localización:** toda string de usuario va en `app_es.arb`; no hardcodear en UI.
- **Rutas reales vs. plan:** las rutas de cubits y tests en el repo difieren de las rutas del plan original. Usar siempre las rutas reales:
  - Cubit: `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart`
  - Test cubit: `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`
  - Test converter: `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`
  - Test widget: `test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart`
- **Backend:** `rideglory-api` está en `/Users/cami/Developer/Personal/rideglory-api`. El directorio AI del api-gateway es `api-gateway/src/ai/`. El spec debe seguir el mismo patrón de mocking que los specs existentes (`jest.fn()`, `jest.clearAllMocks()` en `beforeEach`).
- **No commitear:** el árbol de trabajo queda sucio; el humano revisa y commitea.
- **Deploy EC2:** fuera del scope de ejecución automática — requiere validación humana local-first según `docs/DEPLOY.md`.
