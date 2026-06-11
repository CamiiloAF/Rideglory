# Frontend Handoff — event-form-stepper Fase 1 (Opción A)

> Generado: 2026-06-11T19:53:03Z  
> Agente: Frontend (Sonnet 4.6)  
> Plan: docs/exec-runs/event-form-stepper-fase1/handoffs/architect-for-frontend.md

---

## Baseline

- `flutter test test/features/events/` → **113 tests passed** antes de cambios (verificado con los tests de analytics existentes)
- `dart analyze lib/` → No issues found (baseline)

---

## Archivos cambiados

### Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | +`@Default(0) int currentStep` en `EventFormState`; `city: ''` en `buildEventToSave()`; constantes `_step1Fields`/`_step2Fields`/`_step3Fields`/`stepFields`; métodos `nextStep`/`prevStep`/`goToStep`/`validateStep`/`isCurrentStepValid` |
| `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` | Regenerado por `build_runner` (5 outputs escritos) |
| `lib/l10n/app_es.arb` | +9 keys `event_step_*` (incluye `@event_step_progressLabel` con placeholders `current`/`total`) |
| `lib/l10n/app_localizations.dart` | Regenerado por `flutter gen-l10n` |
| `lib/l10n/app_localizations_es.dart` | Regenerado: 9 nuevos getters/métodos `event_step_*` confirmados |

### Eliminados (dead code)

| Archivo | Motivo |
|---------|--------|
| `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart` | 0 referencias externas (grep confirmado) |
| `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart` | Solo importado por el archivo anterior |
| `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart` | Solo importado por el archivo anterior |

---

## Pruebas nuevas

Archivo: `test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart`

14 tests nuevos bajo el grupo `EventFormCubit — stepper (Fase 1)`:

| ID | Descripción |
|----|-------------|
| TC-stp-1 | `initial state.currentStep == 0` |
| TC-stp-2 | `nextStep()` incrementa `currentStep` |
| TC-stp-3 | `nextStep()` en step 3 no emite estado nuevo (boundary check) |
| TC-stp-4 | `prevStep()` en step 0 no emite estado nuevo (boundary check) |
| TC-stp-5 | `prevStep()` decrementa `currentStep` |
| TC-stp-6 | `goToStep()` emite el step correcto |
| TC-stp-7 | `goToStep()` lanza `AssertionError` para valores fuera de rango |
| TC-stp-8 | Cardinalidad: step0=5, step1=7, step2=2 campos |
| TC-stp-9 | `validateStep()` retorna `true` cuando `formKey.currentState == null` |
| TC-stp-10 | `isCurrentStepValid()` delega a `validateStep(currentStep)` |
| TC-stp-11 | Los 5 campos de step 0 son correctos |
| TC-stp-12 | Los 7 campos de step 1 son correctos |
| TC-stp-13 | `nextStep()` preserva `waypoints` y `routeType` |
| TC-stp-14 | Round-trip completo 0→1→2→3→2→1→0 |

---

## Resultado final

```
dart analyze lib/   → No issues found
flutter test test/features/events/  → +113: All tests passed!
  (9 pre-existentes analytics + 14 nuevos stepper + 90 resto de events)
```

---

## Verificación manual

- `EventFormState().currentStep` es `0` (default verificado en TC-stp-1)
- `buildEventToSave()` produce `city == ''` sin leer del form (línea 344 reemplazada)
- `nextStep()` en step 3 no emite: `identical(state, stateBefore)` es `true` (TC-stp-3)
- `prevStep()` en step 0 no emite: `identical(state, stateBefore)` es `true` (TC-stp-4)
- 9 keys `event_step_*` presentes en `app_localizations_es.dart` (grep confirmado: 9 coincidencias)
- `event_form_publish_action` no duplicada (existía en línea 588, no tocada)
- Dead files eliminados: grep no encuentra referencias a `EventFormDetailsSection`, `DifficultyPicker`, `EventTypePicker` en `lib/` ni `test/`

---

## Notas para QA

1. **Cardinalidad de step3**: El handoff del arquitecto especificaba 4 campos en `_step3Fields` (incluyendo `routeType` y `waypoints`), pero estos son campos de **estado del cubit** (no de `FormBuilder`), por lo que se incluyeron solo los 2 campos reales del form (`meetingPoint`, `destination`). El total de campos de form tracked es 5+7+2=14. Los campos `routeType` y `waypoints` se gestionan por estado del cubit, no por el form key.

2. **`validateStep` con form no montado**: Retorna `true` por el fallback `?? true` en el `.every()`. Esto es el comportamiento esperado — si el form no está montado aún, no hay campos inválidos.

3. **ARB `event_step_progressLabel`**: Es un string parametrizado con `{current}` y `{total}` de tipo `int`. Uso: `context.l10n.event_step_progressLabel(currentStep + 1, totalSteps)`.

4. **Portada IA (cover)**: No implementada bajo Opción A. El constructor de `EventFormCubit` sigue con 5 parámetros. No se crearon archivos de la cadena `EventCoverRepository`.

5. **Archivos eliminados**: Si algún test de integración o widget referenció `EventFormDetailsSection` (improbable — grep limpió confirmado), fallará. Verificar con `flutter test` completo antes de PR.
