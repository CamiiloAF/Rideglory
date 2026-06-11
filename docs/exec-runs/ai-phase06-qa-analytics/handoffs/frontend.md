# Frontend → QA — ai-phase06-qa-analytics

**Agente:** Flutter Frontend  
**Timestamp:** 2026-06-10T22:30:40Z

---

## Baseline

- `flutter test` sobre archivos afectados antes de cambios: **4 passed** (AC15 + AC16 del cubit).
- `dart analyze lib/`: **No issues found** (pre-cambios).

---

## Archivos cambiados

### Código productivo

| Archivo | Cambio |
|---|---|
| `lib/core/services/analytics/analytics_events.dart` | +3 constantes: `aiDescriptionGenerated`, `aiQuotaExceeded`, `aiGenerationFailed` (sección AI Fase 6) |
| `lib/core/services/analytics/analytics_params.dart` | +5 constantes: `aiTurnIndex`, `aiGenerationType`, `aiErrorCode`, `aiGenerationTypeDescription`, `aiGenerationTypeCover` (sección AI Fase 6) |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | Inyecta `AnalyticsService` como 3er param constructor; `logEvent` en rama de éxito (`aiDescriptionGenerated`) y rama de error (`aiQuotaExceeded` / `aiGenerationFailed`) en ambos métodos `sendMessage` y `retryLastMessage` |
| `lib/core/di/injection.config.dart` | **Regenerado** por `build_runner` — actualiza la factory DI del cubit al constructor de 3 parámetros |

### Tests

| Archivo | Cambio |
|---|---|
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | +`MockAnalyticsService`; actualiza todas las instancias a 3 params; +4 grupos CA7 (happy path, quota user, safety, network) |
| `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart` | +2 tests CA8: bold+italic combo, empty input |

### Documentación

| Archivo | Cambio |
|---|---|
| `docs/features/events.md` | `POST /events/generate-cover` marcado como ELIMINADO (Fase 5); nueva sección §9 "Asistentes IA" con `POST /ai/description` request/response/errores/history≤10; nueva sección §10 "Asistentes IA" con flujo completo y tabla de analytics; renumeración §11–§13 |

---

## Pruebas nuevas

### CA7 — Analytics en `AiDescriptionChatCubit` (4 tests nuevos)

| Test | Verificación |
|---|---|
| Happy path | `logEvent(aiDescriptionGenerated, {aiTurnIndex: 2})` called(1) tras `sendMessage` exitoso |
| `AiQuotaExceededUserException` | `logEvent(aiQuotaExceeded, {aiGenerationType: description, aiErrorCode: AiQuotaExceededUserException})` called(1) |
| `AiSafetyBlockedException` | `logEvent(aiGenerationFailed, {aiGenerationType: description, aiErrorCode: AiSafetyBlockedException})` called(1) |
| `AiNetworkErrorException` | `logEvent(aiGenerationFailed, {aiGenerationType: description, aiErrorCode: AiNetworkErrorException})` called(1) |

### CA8 — `MarkdownToDeltaConverter` edge cases (2 tests nuevos)

| Test | Verificación |
|---|---|
| bold+italic combo | `'**bold** y *italic*'` produce ops con `bold:true` e `italic:true` sin throw |
| empty input | `convert('')` retorna normalmente con al menos 1 op (trailing newline) |

---

## Resultado final

```
dart analyze lib/          → No issues found (0 errores, 0 warnings)
flutter test (25 tests)    → All tests passed
  - cubit (8): AC15 ×2, AC16 ×2, CA7 ×4
  - markdown converter (12): AC1 ×6, AC2 ×3, trailing newline ×1, CA8 ×2
  - widget sheet (5): AC13 ×2, AC14 ×3
```

### Gate de analytics
```bash
grep -rn "logEvent.*ai_" lib/ --include="*.dart"
```
Solo aparecen líneas en `ai_description_chat_cubit.dart` (6 llamadas: 3 en `sendMessage`, 3 en `retryLastMessage`). Ninguna en widgets ni en capas domain/data.

---

## Verificación manual

1. Abrir el formulario de creación de evento.
2. Abrir el asistente de descripción IA.
3. Enviar un mensaje — en Firebase Analytics DebugView debe aparecer `ai_description_generated` con `ai_turn_index: 2` (turno 1 = user, turno 2 = model).
4. Agotar la cuota diaria del usuario → debe aparecer `ai_quota_exceeded` con `ai_generation_type: description`.
5. Enviar un mensaje que active filtros de seguridad → `ai_generation_failed` con `ai_error_code: AiSafetyBlockedException`.

---

## Fix — hallazgos Tech Lead (2026-06-10T22:49:10Z)

### Hallazgo 1: dependencia fantasma `uuid`

`uuid: ^4.5.1` fue agregado en `pubspec.yaml` pero **nunca importado en `lib/`**. `generateNonce()` viene del paquete `sign_in_with_apple` (no de `uuid`). La dependencia fue eliminada.

**Archivo cambiado:** `pubspec.yaml` — línea `uuid: ^4.5.1` eliminada de la sección `# Utils`.

### Hallazgo 2: cero tests para `signInWithApple`

Se agregaron 2 tests en `test/features/authentication/application/auth_cubit_test.dart` bajo el grupo `signInWithApple`:

| ID | Caso | Verificación |
|---|---|---|
| TC-auth-A1 | Happy path (returning user) | `setUserId(SHA-256)`, `authSucceeded(apple)`, `setUserProperty(login_method, apple)`, estado `isAuthenticated` |
| TC-auth-A2 | Cancelación por usuario | `authFailed(apple, cancelled)`, `verifyNever(setUserId)`, estado `hasError` |

### Resultado tras el fix

```
flutter test test/features/authentication/application/auth_cubit_test.dart
→ 25 tests passed (23 previos + 2 nuevos Apple)
dart analyze lib/ → No issues found
```

---

## Notas para QA

- **No hay UI nueva** en esta fase — solo instrumentación de analytics y tests.
- El constructor del cubit cambió de 2 a 3 parámetros. La DI (`injection.config.dart`) fue regenerada con `build_runner`; no hay cambios manuales en ese archivo.
- `aiGenerationTypeCover` es un placeholder — el cubit de portada no existe aún; no tiene llamada en producción.
- La spec de backend (`rideglory-api/api-gateway/src/ai/ai-description.spec.ts`) y el constraint `@ArrayMaxSize(10)` en `rideglory-contracts` son responsabilidad del agente backend (no tocados aquí).
- Los tests de widget `ai_description_chat_sheet_test.dart` usan `AiChatErrorBanner` y `AiChatInputRow` directamente (sin `AiDescriptionChatCubit`), por lo que no requirieron actualización de constructor.
