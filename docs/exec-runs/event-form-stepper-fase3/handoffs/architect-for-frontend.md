> Slim handoff — read this before docs/exec-runs/event-form-stepper-fase3/handoffs/architect.md

# Architect → Frontend — event-form-stepper-fase3

**Fecha:** 2026-06-12T04:12:36Z

## Una sola tarea

Crear `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart`
con 3 smoke tests. Todo lo demás del PRD ya está completo en el codebase.

## Tests requeridos

| ID | Descripción |
|---|---|
| TC-wdg-01 | `EventFormStep1` renderiza sin overflow ni excepciones con nombre vacío |
| TC-wdg-02 | Botón 'Continuar' de `EventStepNavBar` deshabilitado cuando `validateStep` retorna false |
| TC-wdg-03 | Botón 'Continuar' habilitado cuando `validateStep` retorna true |

## Patrón de scaffold

Usar `MockEventFormCubit` (patrón de `event_form_stepper_p2_qa_test.dart`), no el cubit real.
Stubs necesarios:
- `cubit.isEditing` → false
- `cubit.editingEvent` → null
- `cubit.state` → `EventFormState()` (o con `currentStep: 0`)
- `cubit.validateStep(any())` → false (TC-wdg-02) / true (TC-wdg-03)

Para `FormImageCubit`: `MockFormImageCubit extends MockCubit<ResultState<FormImageData>>`
con `whenListen` emitiendo `ResultState.initial()`.

Para `AiDescriptionChatCubit` (usado internamente por `EventFormBasicInfoSection`):
registrar en GetIt siguiendo el patrón de `event_form_basic_info_section_test.dart`
líneas 114-134 (setUp registra, tearDown desregistra).

Para `PlaceService`: registrar en GetIt con stub vacío (igual que `event_form_basic_info_section_test.dart`).

## Localización

```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
locale: const Locale('es'),
```

## Cómo verificar 'Continuar'

```dart
// El botón se encuentra por texto l10n:
final continueBtn = find.text('Continuar');
// Deshabilitado: onPressed == null → verificar con tester.widget<AppButton>()
```

`AppButton` expone su `onPressed` como campo público. Verificar que sea null (TC-wdg-02)
o non-null (TC-wdg-03).

## Verificación final

```bash
flutter test test/features/events/presentation/form/widgets/steps/
dart analyze lib/
flutter test  # cero regresiones
```

> Full detail: docs/exec-runs/event-form-stepper-fase3/handoffs/architect.md
