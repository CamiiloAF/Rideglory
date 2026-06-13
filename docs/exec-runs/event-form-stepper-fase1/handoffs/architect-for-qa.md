> Slim handoff — read this before docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md

# QA tasks — event-form-stepper Fase 1 (Opción A — sin portada IA)

## Test commands

```bash
dart analyze          # must be clean (0 errors, 0 new warnings in lib/)
flutter test          # all existing tests must pass
```

## Existing tests — estado esperado bajo Opción A

| Test file | ¿Necesita cambio? | Razón |
|-----------|-------------------|-------|
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | **NO** | Constructor sigue con 5 params (sin use case nuevo en Opción A). El 5° param es `AnalyticsService` — confirmado. |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | **NO** | No importa `EventFormDetailsSection`; no afectado por eliminación |

## Acceptance criteria traceability (Opción A)

| AC | ¿Aplica en Opción A? | What to verify | How |
|----|---------------------|---------------|-----|
| AC-1 | Sí | `dart analyze` limpio | Run `dart analyze`; 0 errores en archivos no generados |
| AC-2 | **NO** (cover fuera de alcance) | — | — |
| AC-3 | **NO** (cover fuera de alcance) | — | — |
| AC-4 | **NO** (cover fuera de alcance) | — | — |
| AC-5 | Sí | `currentStep` default | `EventFormState().currentStep == 0` |
| AC-6 | Sí (parcial) | `city: ''` en `buildEventToSave()` | Inspeccionar línea ~344 — debe ser `city: ''` sin leer del form |
| AC-7 | **NO** (cover fuera de alcance) | — | — |
| AC-8 | Sí | `validateStep(0)` behavior | Con `name` vacío → false; con valor → true (requiere `FormBuilder` + `GlobalKey` en test de Fase 3) |
| AC-9 | Sí | Cardinalidad de `_stepXFields` | `_step1Fields.length`, `_step2Fields.length`, `_step3Fields.length` — verificar contra definición real |
| AC-10 | Sí | `stepFields` map | `EventFormCubit.stepFields[0]` es `_step1Fields` |
| AC-11 | Sí | Límites de navegación | `nextStep()` en step 3 no emite; `prevStep()` en step 0 no emite |
| AC-12 | Sí | 9 ARB keys | Presentes en `app_localizations_es.dart`; `event_form_publish_action` no duplicada |
| AC-13 | Sí | Código muerto eliminado | `event_form_details_section.dart` y `sections/details/` ausentes |
| AC-14 | Sí | Tests en verde | `flutter test` pasa sin fallos nuevos |

## New tests (Fase 1 scope: NONE)

No se requieren tests nuevos en esta fase. Tests para `validateStep()`, `stepFields`, `nextStep()`/`prevStep()` son scope de Fase 3.

## Regression surface

- `EventFormCubit` constructor — **sin cambio bajo Opción A**. El test existente sigue verde.
- `EventFormState` gana `currentStep` con `@Default(0)` — los assertions existentes sobre `saveResult`, `waypoints`, etc. siguen funcionando.
- `buildEventToSave()` cambia `city` de lectura-del-form a `city: ''` — si algún test verifica el `EventModel` construido, debe esperar `city: ''`. Actualmente ningún test verifica esto.
- Eliminación de `EventFormDetailsSection` — no hay test para ese widget; no rompe nada.

> Full detail: docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md
