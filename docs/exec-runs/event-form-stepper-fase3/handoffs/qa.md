# QA Handoff — event-form-stepper-fase3

**Fecha:** 2026-06-12T04:50:41Z
**Nivel:** normal
**Sign-off:** GREEN

---

## Catalogo — ACs §5 vs. cobertura

| AC | Descripcion | Test que lo cubre | Estado |
|---|---|---|---|
| AC-1 | `flutter test` pasa sin fallos (0 failing tests) | Suite completa 824 tests | PASS |
| AC-2 | `dart analyze lib/` 0 errores, 0 warnings (excl. generados) | `dart analyze lib/` → "No issues found!" | PASS |
| AC-3 | `grep -r "EventFormFields.city" lib/features/events/presentation/` sin output | Grep confirmado — exit 1 (sin resultados) | PASS |
| AC-4 | `_mockEvent` en `event_form_cubit_analytics_test.dart` no tiene campo `city` | `EventModel` nunca tuvo `city`; fixture no lo referencia | PASS |
| AC-5 | AC18 en `event_form_basic_info_section_test.dart` no referencia `EventFormFields.city` | Grep confirma 0 referencias a `city` en el archivo | PASS |
| AC-6 | 8 tests de cubit en `event_form_stepper_cubit_test.dart` pasan (superset: 14 tests) | TC-stp-01 a TC-stp-14 — todos pasan | PASS |
| AC-6a | TC-step-01: `nextStep()` incrementa de 0 a 1 | `TC-stp-2` en `event_form_stepper_cubit_test.dart` | PASS |
| AC-6b | TC-step-02: `nextStep()` en paso 3 no supera 3 | `TC-stp-3` | PASS |
| AC-6c | TC-step-03: `prevStep()` decrementa de 1 a 0 | `TC-stp-5` | PASS |
| AC-6d | TC-step-04: `prevStep()` en paso 0 no baja de 0 | `TC-stp-4` | PASS |
| AC-6e | TC-step-05: `goToStep(2)` asigna `currentStep == 2` | `TC-stp-6` | PASS |
| AC-6f | TC-step-06: `isCurrentStepValid()` con `formKey.currentState==null` retorna `true` | `TC-stp-9` / `TC-stp-10` | PASS |
| AC-6g | TC-step-07 (Auditor Opus): `buildEventToSave()` con form real montado produce `meetingPoint == ''` cuando `state.meetingPointName` es null | Widget test nuevo en `event_form_step1_test.dart` — PASS | PASS |
| AC-6h | TC-step-08: Estado inicial tiene `currentStep == 0` | `TC-stp-1` | PASS |
| AC-7 | 3 smoke tests de `event_form_step1_test.dart` pasan | TC-wdg-01/02/03 — todos pasan | PASS |
| AC-7a | TC-wdg-01: `EventFormStep1` renderiza sin overflow/excepciones con nombre vacio | `event_form_step1_test.dart` | PASS |
| AC-7b | TC-wdg-02: Boton 'Continuar' deshabilitado con nombre vacio | `event_form_step1_test.dart` | PASS |
| AC-7c | TC-wdg-03: Boton 'Continuar' habilitado cuando `validateStep` retorna true | `event_form_step1_test.dart` | PASS |

---

## Matriz de regresion — Guardrails §6

| Guardrail | Mecanismo de verificacion | Estado |
|---|---|---|
| No romper tests fuera de los 2 archivos modificados | `flutter test` completo — 824 tests, 0 failures | PASS |
| No modificar `lib/` excepto referencias residuales a `EventFormFields.city` | Grep confirma 0 residuos; `dart analyze lib/` limpio | PASS |
| `buildEventToSave()` con `formKey` no montado → mover a widget test, no suprimir | TC-step-07 implementado como widget test con `FormBuilder(key: cubit.formKey)` real montado | PASS |
| Mocks desregistrados en `tearDown` (anti-contaminacion GetIt) | `event_form_step1_test.dart` sigue el patron de `event_form_basic_info_section_test.dart`; tearDown desregistra `AiDescriptionChatCubit` y `PlaceService` | PASS |
| No resolver residuos de Fases 1-2 fuera del alcance sin reportar | Solo cambios en `test/`; sin tocar `lib/` | PASS |

---

## Ejecucion

### Comandos ejecutados

```
dart analyze lib/                                                     "No issues found!" (exit 0)
grep -r "EventFormFields.city" lib/features/events/presentation/      sin resultados
flutter test test/features/events/presentation/form/                  74 tests, all passed
flutter test (suite completa)                                         824 tests, all passed (exit 0)
```

### Resumen de resultados

| Suite | Tests | Passing | Failing | Pre-existing |
|---|---|---|---|---|
| `test/features/events/presentation/form/` | 74 | 74 | 0 | 0 |
| Suite completa | 824 | 824 | 0 | 0 |

Los 5 fallos pre-existentes de `event_form_stepper_p2_qa_test.dart` mencionados en el handoff del architect no se reproducen — todos sus 14 tests pasan. La suite completa pasa limpiamente.

El conteo sube de 823 a 824 por TC-step-07 (AC-6g) agregado en esta ronda de QA.

---

## Bugs

Sin bugs encontrados.

---

## Pruebas manuales

Para validacion manual completa del wizard de creacion de eventos (fuera del scope automatizado):

- [ ] Abrir la app con `flutter run --flavor dev --dart-define-from-file=config/dev.json`
- [ ] Navegar a Crear Evento; verificar que el stepper muestra 4 pasos con indicador correcto
- [ ] Paso 1: dejar nombre vacio — "Continuar" debe estar deshabilitado
- [ ] Paso 1: escribir un nombre — "Continuar" debe habilitarse
- [ ] Navegar Paso 1 → 2 → 3 → 4 y volver con "Atras"; verificar que el indicador de paso refleja el estado correcto (completado/activo/futuro)
- [ ] En Paso 4 (Revision): verificar que los botones "Editar" de cada seccion navegan al paso correcto
- [ ] En Paso 4: verificar que "Publicar evento" y "Guardar borrador" aparecen (y no aparecen en pasos 1-3)
- [ ] Flujo de edicion de evento existente: verificar que no aparece el `EventStepIndicator`

---

## Sign-off

**GREEN** — Suite completa (824 tests) pasa sin fallos. `dart analyze lib/` limpio. Todos los ACs del PRD §5 verificados. TC-step-07 (AC-6g, requerido por Auditor Opus) implementado como widget test y pasa: `buildEventToSave()` produce `meetingPoint == ''` cuando `state.meetingPointName` es null, ejerciendo `event_form_cubit.dart:348` bajo condiciones reales de form montado.

## Change log
- 2026-06-12T04:40:25Z: QA sign-off inicial (823 tests verdes, AC-6g documentado como deuda)
- 2026-06-12T04:50:41Z: TC-step-07 (AC-6g) implementado y pasa. 824/824 tests verdes. Gap cerrado.
