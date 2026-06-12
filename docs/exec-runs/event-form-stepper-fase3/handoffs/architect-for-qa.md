> Slim handoff — read this before docs/exec-runs/event-form-stepper-fase3/handoffs/architect.md

# Architect → QA — event-form-stepper-fase3

**Fecha:** 2026-06-12T04:31:27Z — CORRECCIÓN APLICADA (Auditor Opus)

## Estado de tests al cierre de Fase 3

73 tests pasan en `test/features/events/presentation/form/` (70 previos + 3 nuevos TC-wdg-*).
`dart analyze lib/` — "No issues found!"
5 fallas pre-existentes en `event_form_stepper_p2_qa_test.dart` (fases anteriores, no esta fase).

## Criterios de aceptación a verificar

| AC | Verificación |
|---|---|
| AC-1 | `flutter test` — 0 failing tests |
| AC-2 | `dart analyze lib/` — 0 errores, 0 warnings (excluyendo `*.g.dart`, `*.freezed.dart`) |
| AC-3 | `grep -r "EventFormFields.city" lib/features/events/presentation/` — sin output |
| AC-4 | `_mockEvent` en `event_form_cubit_analytics_test.dart` — campo `city` no existe (correcto: `EventModel` nunca tuvo `city`) |
| AC-5 | Test AC18 en `event_form_basic_info_section_test.dart` — no referencia `EventFormFields.city` |
| AC-6 | `event_form_stepper_cubit_test.dart` — 14 tests pasan (superset de los 8 del PRD) |
| AC-7 | `event_form_step1_test.dart` — 3 nuevos smoke tests pasan (TC-wdg-01/02/03) |

## Comandos de verificación

```bash
# 1. Smoke tests nuevos
flutter test test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart

# 2. Suite completa de form
flutter test test/features/events/presentation/form/

# 3. Analyze
dart analyze lib/

# 4. Grep residuo city
grep -r "EventFormFields.city" lib/features/events/presentation/

# 5. Full test suite (regresión global)
flutter test
```

## Notas

- AC-3/AC-4/AC-5/AC-6 ya pasan desde el inicio de esta fase.
- El único trabajo nuevo es TC-wdg-01/02/03 en `event_form_step1_test.dart`.
- Contaminación GetIt entre tests: verificar que tearDown desregistre `AiDescriptionChatCubit`.

> Full detail: docs/exec-runs/event-form-stepper-fase3/handoffs/architect.md
