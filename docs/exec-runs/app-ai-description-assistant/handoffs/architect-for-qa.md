> Slim handoff — read this before docs/exec-runs/app-ai-description-assistant/handoffs/architect.md

# Architect → QA

**Slug:** app-ai-description-assistant | **Date:** 2026-06-08T19:10:47Z

---

## Comandos de calidad

```bash
dart analyze                                           # cero warnings/errors
flutter test                                           # todos pasan
dart run build_runner build --delete-conflicting-outputs  # sin conflictos
```

---

## Archivos de test a crear (7)

```
test/features/events/domain/use_cases/generate_event_description_use_case_test.dart
test/features/events/data/repository/ai_description_repository_impl_test.dart
test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart
test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart
test/shared/widgets/form/app_rich_text_editor_external_controller_test.dart
test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart
test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart
```

---

## Traceabilidad AC → test

| AC | Test target | Tipo |
|----|-------------|------|
| AC1 — Markdown→Delta subconjunto completo | `markdown_to_delta_converter_test.dart` | unit |
| AC2 — Markdown→Delta fallback sin error | `markdown_to_delta_converter_test.dart` | unit |
| AC3 — Inserción en editor — Delta visible | `app_rich_text_editor_external_controller_test.dart` | widget |
| AC4 — onChanged propagado determinista | `app_rich_text_editor_external_controller_test.dart` | widget |
| AC5 — Retrocompatibilidad sin externalController | `app_rich_text_editor_external_controller_test.dart` | widget |
| AC6 — Sin double dispose | `app_rich_text_editor_external_controller_test.dart` (MockQuillController) | widget |
| AC7 — ConfirmationDialog al reemplazar | `ai_description_chat_sheet_test.dart` | widget |
| AC8 — Inserción directa si editor vacío | `ai_description_chat_sheet_test.dart` | widget |
| AC9 — Mapeo 429/quota_exceeded_user | `ai_description_repository_impl_test.dart` | unit |
| AC10 — Mapeo 429/quota_exceeded_project | `ai_description_repository_impl_test.dart` | unit |
| AC11 — Mapeo 422/safety_blocked | `ai_description_repository_impl_test.dart` | unit |
| AC12 — Mapeo 503/network_error | `ai_description_repository_impl_test.dart` | unit |
| AC13 — Campo deshabilitado en quota_exceeded_user | `ai_description_chat_sheet_test.dart` | widget |
| AC14 — Reintentar en errores recuperables (×3) | `ai_description_chat_sheet_test.dart` | widget |
| AC15 — Cuota inicial desde Remote Config | `ai_description_chat_cubit_test.dart` | unit |
| AC16 — Cuota actualizada desde response | `ai_description_chat_cubit_test.dart` | unit |
| AC17 — EventFormContent sin callback coming soon | `event_form_basic_info_section_test.dart` + `dart analyze` | widget |
| AC18 — `_buildEventContext` con campos reales | `ai_description_chat_sheet_test.dart` o unit del cubit | unit/widget |
| AC19 — `dart analyze` limpio + `flutter test` | Comandos de calidad | — |

---

## Guardrails de regresión (verificar explícitamente)

1. **`AppRichTextEditor` sin `externalController`** — compilar y renderizar: `app_rich_text_editor_external_controller_test.dart` con `externalController: null`.
2. **`EventFormContent` compila** sin `onAiSuggest` en `EventFormBasicInfoSection`.
3. **`AiDescriptionChatCubit` es factory** (transient) — verificar que `injection.config.dart` generado NO usa `singleton`/`lazySingleton` para este cubit.
4. **`executeService()` ausente** en `AiDescriptionRepositoryImpl` — grep: `grep "executeService" lib/features/events/data/repository/ai_description_repository_impl.dart` debe retornar vacío.
5. **`QuillController.dispose()` invocado exactamente una vez** — test AC6.

---

## Mock recomendado

`mocktail` (ya en `pubspec.yaml ^1.0.4`). Usar `MockDio` o `MockAiDescriptionService` para aislar el repositorio impl.

> Full detail: docs/exec-runs/app-ai-description-assistant/handoffs/architect.md
