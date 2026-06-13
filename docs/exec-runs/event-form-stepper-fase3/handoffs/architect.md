# Architect handoff — event-form-stepper-fase3

**Date:** 2026-06-12T04:31:27Z
**Status:** done — CORRECCIÓN APLICADA (Auditor Opus)

---

## Decisiones

### D-1: Estado real vs. PRD — cuatro de cinco deltas ya están completos

El PRD describe cinco acciones, pero cuatro ya fueron aplicadas durante Fases 1-2 (o nunca
existió el campo `city` en `EventModel`):

| PRD action | Estado real |
|---|---|
| `event_form_cubit_analytics_test.dart`: cambiar `city: 'Medellín'` → `city: ''` en `_mockEvent` línea 39 | `EventModel` nunca tuvo campo `city`; el fixture no lo referencia. Ya OK. |
| `event_form_basic_info_section_test.dart`: actualizar comentario línea 6, nombre AC18 línea 147, assertion `ctx.city` línea 220 | El test actual no referencia `city` en ninguna de esas líneas. Ya OK. |
| Crear `event_form_cubit_stepper_test.dart` con 8 tests | Existe como `event_form_stepper_cubit_test.dart` con **14 tests** (superconjunto). Ya OK. |
| `dart analyze lib/` limpio | Resultado: "No issues found!" Ya OK. |
| **Crear `event_form_step1_test.dart` con 3 smoke tests** | **CREADO.** 3 tests pasan (TC-wdg-01/02/03). |

### D-2: El único archivo a crear es `event_form_step1_test.dart`

Ruta: `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart`

### D-3: Dependencias del scaffold de widget test

`EventFormStep1` consume tres cubits via `context.read`/`BlocBuilder`:
- `EventFormCubit` — leído vía `context.read<EventFormCubit>()` para `isEditing` y `editingEvent`
- `FormImageCubit` — usado en `BlocBuilder<FormImageCubit, ResultState<FormImageData>>`
- `AiDescriptionChatCubit` — usado internamente en `EventFormBasicInfoSection`

El scaffold de test debe proveer los tres via `MultiBlocProvider` + mock cubits.
`PlaceService` también debe registrarse en GetIt (ver patrón en `event_form_basic_info_section_test.dart` líneas 117-128).

### D-4: TC-wdg-02 / TC-wdg-03 — "Continuar" está en `NavigationRow` dentro de `EventStepNavBar`

El botón 'Continuar' se habilita/deshabilita vía `cubit.validateStep(currentStep)`.
Cuando `formKey.currentState == null` (test unitario sin widget montado), `validateStep` retorna `true`.
Para TC-wdg-02 (botón deshabilitado con nombre vacío), el `EventFormCubit` REAL debe estar montado
con su `formKey` en el árbol Flutter para que `validateStep` pueda leer el campo `name`.

La alternativa más simple y alineada con los guardrails del PRD (§6): usar `MockEventFormCubit`
(patrón de `event_form_stepper_p2_qa_test.dart`) y stubs `when(() => cubit.validateStep(any())).thenReturn(false/true)`.

### D-5: No hay cambios en `lib/`, backend, migraciones ni env vars

Esta fase es puramente tests. El código de producción no se toca (salvo referencia residual a
`EventFormFields.city` que el grep confirma que no existe).

---

## Change map

| File | Action | Reason | Risk |
|---|---|---|---|
| `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart` | create | 3 smoke tests TC-wdg-01/02/03 pendientes del PRD | low |
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | no-op | Ya correcto; `EventModel` nunca tuvo `city` | — |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | no-op | Ya correcto; sin referencias a `city` | — |
| `test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart` | no-op | Existe con 14 tests (superset de los 8 del PRD) | — |

---

## Contratos

Sin contratos de API. Fase puramente de tests Flutter.

---

## Datos / migraciones

Sin cambios de schema ni migraciones.

---

## Env

Sin nuevas variables de entorno.

---

## Riesgos

| Riesgo | Mitigación |
|---|---|
| TC-wdg-02/03 requieren `EventFormCubit` real montado con formKey en árbol Flutter | Usar `MockEventFormCubit` + stubs `validateStep` (patrón ya probado en `event_form_stepper_p2_qa_test.dart`) — más confiable que montar el cubit real |
| `AiDescriptionChatCubit` se registra en GetIt por `EventFormBasicInfoSection` | Seguir el patrón tearDown de `event_form_basic_info_section_test.dart` líneas 130-134 |
| `FormImageCubit` necesita `ImageStorageService` si se instancia real | Usar `MockFormImageCubit extends MockCubit<ResultState<FormImageData>>` con stub `initial()` |
| TC-wdg-01 puede tener overflow real por Mapbox o widgets pesados dentro de `EventFormBasicInfoSection` | Usar `tester.pumpWidget` con tamaño de pantalla estándar y `pumpAndSettle`; si Mapbox presente en step2/3, step1 no lo contiene |

---

## Orden de implementación

1. Crear `test/features/events/presentation/form/widgets/steps/event_form_step1_test.dart` con TC-wdg-01, TC-wdg-02, TC-wdg-03.
2. Ejecutar `flutter test test/features/events/presentation/form/widgets/steps/` para verificar los nuevos tests.
3. Ejecutar `flutter test` completo para confirmar cero regresiones.
4. Ejecutar `dart analyze lib/` para confirmar cero issues.

---

## Superficie de regresión

Tests en `test/features/events/presentation/form/` — actualmente 73 tests todos verdes (70 previos + 3 nuevos TC-wdg-*).
Los 5 tests que fallan en el full run (`event_form_stepper_p2_qa_test.dart` — AC-5/6/7 y AC-9) son regresiones
pre-existentes de Fase 2 (faltan claves l10n en `event_form_step4_review.dart`), confirmado por git stash.
No son causados por el nuevo archivo. `dart analyze lib/` — "No issues found!".
Contaminación GetIt: mitigada con tearDown que desregistra `AiDescriptionChatCubit` y `PlaceService`.

---

## Fuera de alcance

- Widget tests para `EventFormStep2`, `EventFormStep3`, `EventFormStep4Review`.
- Tests de integración end-to-end del wizard.
- Profiling `IndexedStack` + Mapbox (deuda técnica Fase 2).
- Tests del backend.
- Cambios en `lib/` (ningun residuo de `EventFormFields.city` encontrado).
