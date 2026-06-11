> Slim handoff — read this before docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md

# Frontend tasks — event-form-stepper Fase 1 (Opción A — sin portada IA)

## Pre-flight (blocking)

Run `git status`. If there are `??` files in `lib/features/events/` other than known `app-ai-description-assistant` exec-run artifacts, **stop and report to the human**.

---

## IMPORTANTE: Portada IA fuera de alcance

Los archivos `EventCoverRepository`, `GetGenerateCoverUseCase`, `EventCoverRepositoryImpl` NO existen en el codebase. El PRD los asumió como existentes — no lo son. Bajo Opción A (recomendada), NO se crean. El constructor de `EventFormCubit` NO cambia (sigue con 5 params).

Confirmar con el humano antes de crear cualquier archivo de la cadena cover.

---

## Files to MODIFY

| File | What changes |
|------|-------------|
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | 4 cambios — ver abajo |
| `lib/l10n/app_es.arb` | +9 keys `event_step_*` |

## Files to DELETE

- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
- `lib/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart`
- `lib/features/events/presentation/form/widgets/sections/details/event_type_picker.dart`

Verify first: `grep -r "EventFormDetailsSection" lib/ test/ --include="*.dart" -l` — debe retornar solo el propio archivo.

## Generated files (run after changes)

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

---

## EventFormCubit changes (4 modifications — Opción A)

### 1. `EventFormState` — add `currentStep` only

```dart
@freezed
abstract class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(ResultState<EventModel>.initial()) ResultState<EventModel> saveResult,
    @Default(0) int currentStep,   // ADD — solo este campo
    @Default(<String>[]) List<String> waypoints,
    // ...rest unchanged...
  }) = _EventFormState;
}
```

NO añadir `coverResult` bajo Opción A.

### 2. `buildEventToSave()` — fix city (línea ~344)

Change:
```dart
city: formData[EventFormFields.city] as String,
```
To:
```dart
city: '',
```

`buildDraftToSave()` (línea ~417) ya usa `?.trim() ?? ''` — sin cambio adicional.

### 3. Add step navigation and validation

```dart
// Step field mapping — all EventFormFields except city, routeType, waypoints (cubit state)
static const List<String> _step1Fields = [
  EventFormFields.name,
  EventFormFields.description,
  EventFormFields.dateRange,
  EventFormFields.isMultiDay,
  EventFormFields.meetingTime,
];

static const List<String> _step2Fields = [
  EventFormFields.difficulty,
  EventFormFields.eventType,
  EventFormFields.price,
  EventFormFields.isFreeEvent,
  EventFormFields.maxParticipants,
  EventFormFields.isMultiBrand,
  EventFormFields.allowedBrands,
];

static const List<String> _step3Fields = [
  EventFormFields.meetingPoint,
  EventFormFields.destination,
  EventFormFields.routeType,
  EventFormFields.waypoints,
];

static const Map<int, List<String>> stepFields = {
  0: _step1Fields,
  1: _step2Fields,
  2: _step3Fields,
};

void nextStep() {
  final next = state.currentStep + 1;
  if (next <= 3) emit(state.copyWith(currentStep: next));
}

void prevStep() {
  final prev = state.currentStep - 1;
  if (prev >= 0) emit(state.copyWith(currentStep: prev));
}

void goToStep(int step) {
  assert(step >= 0 && step <= 3, 'step must be between 0 and 3');
  emit(state.copyWith(currentStep: step));
}

bool validateStep(int step) {
  final fields = stepFields[step];
  if (fields == null) return true;
  return fields.every(
    (name) => formKey.currentState?.fields[name]?.validate() ?? true,
  );
}

bool isCurrentStepValid() => validateStep(state.currentStep);
```

**Nota cardinalidad:** verificar que `routeType` y `waypoints` sean correctamente asignados. Si son solo campos de estado del cubit (no del `FormBuilder`), moverlos fuera de `_step3Fields` y ajustar el total. AC-9 del PRD dice 16 campos totales sin `city`.

### 4. Constructor — SIN CAMBIO (Opción A)

El constructor sigue con 5 params: `CreateEventUseCase, UpdateEventUseCase, UploadEventImageUseCase, GetCurrentUserIdUseCase, AnalyticsService`. El test existente `event_form_cubit_analytics_test.dart` no requiere modificación.

---

## ARB keys to add (`app_es.arb`)

Add in the `event_` section, before the closing `}`. Do NOT add `event_form_publish_action` — already exists at line 588.

```json
"event_step_basicInfo": "Básico",
"event_step_details": "Detalles",
"event_step_route": "Ruta",
"event_step_reviewAndPublish": "Revisar",
"event_step_continue": "Continuar",
"event_step_back": "Atrás",
"event_step_of": "de",
"event_step_saveDraft": "Guardar borrador",
"event_step_progressLabel": "Paso {current} de {total}",
"@event_step_progressLabel": {
  "placeholders": {
    "current": { "type": "int" },
    "total": { "type": "int" }
  }
}
```

---

## Acceptance criteria checklist (Opción A)

- [ ] `dart analyze` limpio
- [ ] `EventFormState().currentStep == 0`
- [ ] `buildEventToSave()` produce `city == ''` (sin leer del form)
- [ ] `_step1Fields.length == 5`, `_step2Fields.length == 7`, `_step3Fields.length == 4` (verificar cardinalidad real)
- [ ] `nextStep()` en step 3 no emite estado nuevo
- [ ] `prevStep()` en step 0 no emite estado nuevo
- [ ] 9 keys `event_step_*` presentes en `app_localizations_es.dart`
- [ ] `event_form_publish_action` no duplicada
- [ ] `event_form_details_section.dart` y `sections/details/` eliminados
- [ ] `flutter test` pasa sin fallos nuevos

> Full detail: docs/exec-runs/event-form-stepper-fase1/handoffs/architect.md
