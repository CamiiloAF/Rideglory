# QA Handoff — ai-phase06-qa-analytics

**Timestamp:** 2026-06-10T22:40:45Z  
**Agente:** QA (nivel normal)  
**Sign-off:** conditional

---

## Catalogo — AC §5 vs. cobertura de test

| CA | Descripción | Cobertura | Veredicto |
|----|-------------|-----------|-----------|
| CA1 | `logEvent.*ai_` solo en `*_cubit.dart` | Gate grep: sin resultados (el cubit usa constantes, no strings literales — vacuamente OK; logEvent calls confinadas a `ai_description_chat_cubit.dart`) | PASS |
| CA2 | Constantes `aiDescriptionGenerated`, `aiQuotaExceeded`, `aiGenerationFailed`, `aiGenerationTypeCover` existen | Verificado con grep en `analytics_events.dart` + `analytics_params.dart` | PASS |
| CA3 | `AiDescriptionChatCubit` recibe `AnalyticsService` y llama `logEvent` en éxito/cuota/error | Inspeccion directa del cubit: 3er param `AnalyticsService`, 6 llamadas (3 en `sendMessage`, 3 en `retryLastMessage`) | PASS |
| CA4 | 4 keys de error tipado en `app_es.arb` sin duplicados | grep devuelve exactamente 4 líneas (`ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`) | PASS |
| CA5 | `dart analyze` 0 errors, 0 warnings | Exit code 0; 8 issues a nivel `info` (3 nuevos introducidos en esta fase en `ai_description_chat_cubit_test.dart`: `prefer_const_constructors` en `Left(...)` líneas 209, 245, 281) | CONDICIONAL |
| CA6 | `flutter test` 100% verde | Exit code 0; todos los tests de `test/features/events/` pasaron | PASS |
| CA7 | `ai_description_chat_cubit_test.dart` cubre 4 grupos de analytics | 4 tests CA7: happy path (aiDescriptionGenerated), quota user (aiQuotaExceeded), safety blocked (aiGenerationFailed), network (aiGenerationFailed) — todos verdes | PASS |
| CA8 | `markdown_to_delta_converter_test.dart` cubre bold+italic combo e input vacío | 2 tests nuevos: combo + empty — verdes | PASS |
| CA9 | `ai-description.spec.ts` cubre gaps genuinos según architect | 5 tests / 2 suites: (a) history > 10 → BadRequestException, (b) exactly 10 → acepta, (c) isDescription: true, (d) isDescription: false, (e) safety_blocked throw | PASS |
| CA10 | `docs/features/events.md` documenta `POST /ai/description`; `POST /events/generate-cover` marcado ELIMINADO; sección "Asistentes IA" | Verificado: línea 662 con strikethrough + "ELIMINADO (Fase 5)"; sección "Asistentes IA" en §9 y §10 | PASS |
| CA11 | `@ArrayMaxSize(10)` en `ai-description-request.dto.ts` | Verificado: líneas 3 + 19 del DTO en `rideglory-contracts` | PASS |
| Legacy | `get_generate_cover_use_case_test.dart` y `ai-cover.spec.ts` no existen | Ambos ausentes confirmado con `ls` | PASS |

---

## Matriz de regresion — Guardrails §6

| Guardrail | Mecanismo de verificacion | Estado |
|-----------|--------------------------|--------|
| No modificar widgets/pages/screens | grep por `_widget.dart`, `_page.dart`, `_screen.dart` en diff — cero ocurrencias; `dart analyze` no reporta errores en capas UI | PASS |
| No alterar `DomainException` base | Cubit usa `exception is AiQuotaExceededUserException` (subclase existente); no hay cambios en `lib/core/exceptions/` | PASS |
| No strings duplicadas en `app_es.arb` | grep de 4 keys devuelve exactamente 4 líneas (sin duplicados) | PASS |
| No crear tests del cubit de portada | `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` no existe | PASS |
| No crear `ai-cover.spec.ts` | `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts` no existe | PASS |
| No agregar `aiImageGenerated` ni `aiCoverUsed` | grep en `analytics_events.dart` — constantes ausentes | PASS |
| Tests de Fase 4 siguen verdes | `ai_description_chat_cubit_test.dart` (8 tests), `markdown_to_delta_converter_test.dart` (12 tests), `ai_description_chat_sheet_test.dart` (5 tests), `generate_event_description_use_case_test.dart` (3 tests) — todos verdes | PASS |

---

## Ejecucion

### Flutter

```
dart analyze
  Exit code: 0
  8 issues (todos info-level, ninguno error ni warning):
    - 3 NUEVOS en test/.../ai_description_chat_cubit_test.dart:209,245,281 (prefer_const_constructors)
    - 1 pre-existente en test/.../ai_description_repository_impl_test.dart:36 (no_leading_underscores)
    - 1 pre-existente en test/.../event_form_basic_info_section_test.dart:47 (prefer_const_literals)
    - 3 pre-existentes en test/.../app_rich_text_editor_external_controller_test.dart:17,42,91

flutter test test/features/events/
  Exit code: 0 — todos los tests verdes
  test/features/events/data/repository/ai_description_repository_impl_test.dart: 5 tests PASS
  test/features/events/domain/use_cases/generate_event_description_use_case_test.dart: 3 tests PASS
  test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart: 8 tests PASS
  test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart: 12 tests PASS
  test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart: 5 tests PASS
```

### Backend

```
cd rideglory-api/api-gateway
npx jest src/ai/ --no-coverage
  Test Suites: 6 passed, 6 total
  Tests:       37 passed, 37 total  (baseline era 32; +5 nuevos en ai-description.spec.ts)
  Sin regresiones.
```

---

## Bugs

### BUG-QA-01 — 3 prefer_const_constructors en tests nuevos de analytics

**Severidad:** Menor (lint info; no afecta comportamiento ni CI exit code)  
**Archivo:** `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`  
**Lineas:** 209, 245, 281  
**Descripcion:** Los tres nuevos grupos CA7 (quota user, safety blocked, network) usan `Left(const AiXxxException(...))` en vez de `const Left(AiXxxException(...))`. Dart prefiere const en el constructor exterior. El análisis lo reporta como `prefer_const_constructors`. El código es funcionalmente correcto; el lint info es nuevo (no pre-existente) introducido por esta fase.  
**Fix sugerido:** Cambiar `Left(const AiQuotaExceededUserException(...))` → `const Left(AiQuotaExceededUserException(...))` en líneas 209, 245, 281.

---

## Pruebas manuales

Las siguientes verificaciones requieren dispositivo/simulador real con Firebase DebugView activo (fuera del scope automatizado de esta fase):

1. **Happy path analytics:** Abrir asistente de descripción, enviar mensaje, verificar en Firebase DebugView que aparece `ai_description_generated` con `ai_turn_index: 2`.
2. **Cuota agotada:** Agotar cuota diaria del usuario → verificar `ai_quota_exceeded` con `ai_generation_type: description`.
3. **Safety blocked:** Enviar prompt que active filtros → verificar `ai_generation_failed` con `ai_error_code: AiSafetyBlockedException`.
4. **Backend validation:** `POST /api/ai/description` con `history` de 11 turnos → debe retornar 400.
5. **Docs:** Verificar en `docs/features/events.md` que `POST /events/generate-cover` aparece tachado y que la sección "Asistentes IA" describe el flujo completo.

---

## Sign-off

**Veredicto: CONDITIONAL**

Todos los tests funcionales pasan (flutter test exit 0; jest 37/37). Todos los CAs funcionales están satisfechos. La condicion de bloqueo menor es el BUG-QA-01: 3 lint infos `prefer_const_constructors` introducidos en esta fase en el archivo de tests de analytics. Son correcciones de una línea (`Left(const X)` → `const Left(X)`) en test code, sin impacto funcional. Recomendado resolverlos antes del commit para mantener el proyecto limpio de issues lint.
