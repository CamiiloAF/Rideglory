> Slim handoff — read this before docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md

# Architect → QA — ai-phase06-qa-analytics (rev 2)

## Comandos de verificación

```bash
# 1. Lint Flutter (0 errores, 0 warnings)
dart analyze

# 2. Tests Flutter (100% verde)
flutter test

# 3. Gate bloqueante: logEvent solo en cubits
grep -rn "logEvent.*ai_" lib/ --include="*.dart"
# Resultado esperado: únicamente líneas en *_cubit.dart

# 4. Test backend spec (requiere que el rebuild de contratos ya se haya ejecutado)
cd /Users/cami/Developer/Personal/rideglory-api/api-gateway
npx jest src/ai/ai-description.spec.ts --no-coverage

# 5. Verificar que specs existentes no se rompieron
npx jest src/ai/ai.controller.spec.ts src/ai/gemini.service.spec.ts --no-coverage
```

---

## Criterios de aceptación — trazabilidad

| CA | Verificación |
|----|-------------|
| CA1 | `grep -rn "logEvent.*ai_" lib/ --include="*.dart"` → solo `*_cubit.dart` |
| CA2 | `grep -n "aiDescriptionGenerated\|aiQuotaExceeded\|aiGenerationFailed\|aiGenerationTypeCover" lib/core/services/analytics/` → existen los 4 |
| CA3 | `AiDescriptionChatCubit` constructor tiene 3 params; `sendMessage` y `retryLastMessage` llaman `logEvent`; ambos usan `newHistory.length` para `aiTurnIndex` |
| CA4 | `grep "ai_error_quota_exceeded_user\|ai_error_quota_exceeded_project\|ai_error_safety_blocked\|ai_error_network" lib/l10n/app_es.arb` → exactamente 4 líneas (sin duplicados) |
| CA5 | `dart analyze` → 0 errors, 0 warnings |
| CA6 | `flutter test` → 100% |
| CA7 | `ai_description_chat_cubit_test.dart` contiene `verify(() => mockAnalyticsService.logEvent` × 4 grupos (happy path, quota user, safety blocked, network) |
| CA8 | `markdown_to_delta_converter_test.dart` cubre bold+italic combo e input vacío |
| CA9 | `ai-description.spec.ts` existe y pasa: (a) history > 10 → 400 BadRequestException; (b) GeminiService happy-path isDescription: true; (c) GeminiService happy-path isDescription: false; (d) GeminiService safety_blocked throw |
| CA10 | `docs/features/events.md` contiene "ELIMINADO (Fase 5)" y sección "Asistentes IA" |
| CA11 | `rideglory-contracts/src/ai/dto/ai-description-request.dto.ts` contiene `@ArrayMaxSize(10)` en el campo `history` |

---

## Tests que NO deben existir

- `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` — confirmar que no existe
- `rideglory-api/api-gateway/src/ai/ai-cover.spec.ts` — confirmar que no existe

---

## Notas de regresión

- `ai.controller.spec.ts` y `gemini.service.spec.ts` no se modifican — sus tests deben seguir verdes tras el rebuild de contratos
- El cambio en el DTO (`@ArrayMaxSize(10)`) es backward-compatible: solo agrega validación más estricta en un campo opcional

> Full detail: docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md
