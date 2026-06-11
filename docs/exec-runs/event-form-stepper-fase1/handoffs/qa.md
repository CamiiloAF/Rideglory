# QA Handoff — event-form-stepper Fase 1

**Date:** 2026-06-11T20:11:04Z
**Status:** done (rev 2 — Auditor Opus iteration)
**Slug:** event-form-stepper-fase1
**Opción adoptada:** A (sin portada IA)

---

## Catalogo

| ID | AC PRD §5 | ¿Aplica Opción A? | Tipo | Descripción | Resultado |
|----|-----------|-------------------|------|-------------|-----------|
| TC-F1-01 | AC-1 | Sí | Estático | `dart analyze lib/` — 0 errores, 0 warnings nuevos | PASS |
| TC-F1-02 | AC-2 | NO | — | City opcional en backend — fuera de alcance Opción A | SKIP |
| TC-F1-03 | AC-3 | NO | — | Cadena Flutter omisión condicional — fuera de alcance Opción A | SKIP |
| TC-F1-04 | AC-4 | NO | — | Firma nullable propagada — fuera de alcance Opción A | SKIP |
| TC-F1-05 | AC-5 | Sí | Unitario | `EventFormState().currentStep == 0` (TC-stp-1) | PASS |
| TC-F1-06 | AC-6 | Sí | Unitario + Widget | `buildDraftToSave()` con city≠'' en form → `city == ''`; `buildEventToSave()` hardcodea `city: ''` | PASS — BUG detectado y corregido: ver BUG-F1-01 |
| TC-F1-07 | AC-7 | NO | — | `generateCover()` con city nullable — fuera de alcance Opción A | SKIP |
| TC-F1-08 | AC-8 | Sí | Widget | `validateStep(0)` con `FormBuilder` real + `GlobalKey<FormBuilderState>`: falso con name vacío, verdadero con name no vacío | PASS |
| TC-F1-09 | AC-9 | Sí (ajustado) | Unitario | Cardinalidad: step0=5, step1=7, step2=2 (TC-stp-8) | PASS — desviación documentada: step3 tiene 2 campos (no 4); routeType/waypoints son estado del cubit, no form fields (decisión D6 del arquitecto) |
| TC-F1-10 | AC-10 | Sí | Unitario | `stepFields[0]` es `_step1Fields` (TC-stp-11, TC-stp-12) | PASS |
| TC-F1-11 | AC-11 | Sí | Unitario | `nextStep()` en step 3 no emite; `prevStep()` en step 0 no emite (TC-stp-3, TC-stp-4) | PASS |
| TC-F1-12 | AC-12 | Sí | Estático | 9 keys `event_step_*` presentes en `AppLocalizationsEs`; `event_form_publish_action` no duplicada | PASS — test automatizado añadido |
| TC-F1-13 | AC-13 | Sí | Estático | `event_form_details_section.dart` y `sections/details/` ausentes | PASS |
| TC-F1-14 | AC-14 | Sí | Suite | `flutter test test/features/events/` — 119 tests, 0 fallos | PASS |

**Tests nuevos entregados por Frontend (TC-stp-*):**

| TC | Descripción | Resultado |
|----|-------------|-----------|
| TC-stp-1 | `initial state.currentStep == 0` | PASS |
| TC-stp-2 | `nextStep()` incrementa `currentStep` | PASS |
| TC-stp-3 | `nextStep()` en step 3 no emite nuevo estado | PASS |
| TC-stp-4 | `prevStep()` en step 0 no emite nuevo estado | PASS |
| TC-stp-5 | `prevStep()` decrementa `currentStep` | PASS |
| TC-stp-6 | `goToStep()` emite step correcto | PASS |
| TC-stp-7 | `goToStep()` lanza `AssertionError` fuera de rango | PASS |
| TC-stp-8 | Cardinalidad: step0=5, step1=7, step2=2 | PASS |
| TC-stp-9 | `validateStep()` retorna `true` sin form montado | PASS |
| TC-stp-10 | `isCurrentStepValid()` delega a `validateStep(currentStep)` | PASS |
| TC-stp-11 | Los 5 campos de step 0 son correctos | PASS |
| TC-stp-12 | Los 7 campos de step 1 son correctos | PASS |
| TC-stp-13 | `nextStep()` preserva `waypoints` y `routeType` | PASS |
| TC-stp-14 | Round-trip completo 0→1→2→3→2→1→0 | PASS |

**Tests nuevos añadidos por QA (Auditor Opus iteration):**

Archivo: `test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart`

| TC | AC | Descripción | Resultado |
|----|-----|-------------|-----------|
| TC-aud-1 | AC-6 | `buildEventToSave()` — `EventModel` acepta `city: ''` (aserción estática del tipo) | PASS |
| TC-aud-2 | AC-6 | `buildDraftToSave()` con `city='Cartagena'` en form → `draft.city == ''` | PASS — inicialmente FAIL, BUG-F1-01 corregido en cubit |
| TC-aud-3 | AC-8 | `validateStep(0)` retorna `false` con `name` vacío en FormBuilder real | PASS |
| TC-aud-4 | AC-8 | `validateStep(0)` retorna `true` con `name` no vacío en FormBuilder real | PASS |
| TC-aud-5 | AC-12 | Los 9 getters/métodos `event_step_*` existen en `AppLocalizationsEs` y retornan strings no vacíos | PASS |
| TC-aud-6 | AC-12 | `event_form_publish_action` existe y no duplica valor de ninguna step label | PASS |

---

## Matriz de regresión (Guardrails §6)

| Guardrail | Mecanismo de verificación | Estado |
|-----------|--------------------------|--------|
| `POST /events/generate-cover` sigue funcionando con `city` enviado | No aplica en Opción A — ningún cambio de backend en Fase 1 | N/A |
| Formulario creación/edición de eventos sigue funcionando | Ningún widget modificado; `dart analyze` limpio; `flutter test` 119/119 | OK |
| Sin nuevas referencias a `EventFormDetailsSection` o sub-widgets | `grep -r EventFormDetailsSection lib/` → 0 resultados | OK |
| Validator `dateRange` en `EventFormDateTimeSection` no falla | No hubo cambios en ese widget; `dart analyze` limpio; test suite completa verde | OK |
| `dart analyze` y `flutter test` pasan sin fallos nuevos | `dart analyze` → No issues found; `flutter test` → 119 pass / 0 fail | OK |
| Ningún archivo de localización existente pierde keys | Solo se añadieron 9 nuevas keys `event_step_*`; verificado con TC-aud-5 | OK |
| `event_form_publish_action` no duplicada en ARB | TC-aud-6 pasa; `grep -c event_form_publish_action app_es.arb` → 1 | OK |

---

## Ejecución

```
$ dart analyze lib/
Analyzing lib...
No issues found!

$ flutter test test/features/events/ --reporter json
Suite success: True
Total: 119, Passed: 119, Failed: 0

$ flutter test test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart
Total: 6, Passed: 6, Failed: 0

$ flutter test test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart
Total: 14, Passed: 14, Failed: 0

$ flutter test test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart
Total: 10, Passed: 10, Failed: 0
```

**Nota sobre conteos:** Los 119 del runner de suite coinciden con el conteo JSON `testDone` (excluyendo hidden/setUp). Los 142 del handoff de Frontend incluían setUp entries como tests; ambas métricas son consistentes.

---

## Bugs

| ID | Descripción | Area | Archivo | Severidad |
|----|-------------|------|---------|-----------|
| BUG-F1-01 | `buildDraftToSave()` leía `city` del form en línea 418 (`formData[EventFormFields.city]`). Cuando el campo `city` está registrado en `EventFormBasicInfoSection` con un valor no vacío, `draft.city` devolvía ese valor en lugar de `''`, violando AC-6. **Corregido:** línea 418 cambiada a `city: ''`. | frontend | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | High — viola AC-6; borrador guardado con ciudad incorrecta |

**Observación de bajo impacto (no bug funcional):**

El directorio vacío `lib/features/events/presentation/form/widgets/sections/details/` permanece en el working tree. Git no rastrea directorios vacíos; desaparecerá al commitear.

**Desviación de AC-9 documentada (no bug):** `_step3Fields` tiene 2 entradas (`meetingPoint`, `destination`), no 4. El arquitecto documentó la decisión en D6: `routeType` y `waypoints` son campos de estado del cubit, no del `FormBuilder`. Tests actualizados para reflejar esto.

---

## Pruebas manuales

| Verificación | Resultado |
|-------------|-----------|
| `EventFormState().currentStep` es `0` | Confirmado: línea 28 — `@Default(0) int currentStep` |
| `buildEventToSave()` produce `city == ''` | Confirmado: línea 345 — `city: ''` hardcoded |
| `buildDraftToSave()` produce `city == ''` | Confirmado post-fix: línea 418 — `city: ''` hardcoded (fue `formData[EventFormFields.city]`) |
| `nextStep()` en step 3 no emite | Confirmado: `if (next <= 3)` → `4 <= 3` = false → no emit |
| `prevStep()` en step 0 no emite | Confirmado: `if (prev >= 0)` → `-1 >= 0` = false → no emit |
| 9 keys `event_step_*` en `AppLocalizationsEs` | Confirmado: TC-aud-5 pasa + 9 getters/métodos verificados en compilación |
| `event_form_publish_action` no duplicada | Confirmado: TC-aud-6 pasa; 1 ocurrencia en ARB |
| Dead files eliminados y sin referencias externas | Confirmado: 0 resultados en grep sobre `lib/` y `test/` |
| Constructor de `EventFormCubit` — 5 params sin cambio | Confirmado: `(CreateEventUseCase, UpdateEventUseCase, UploadEventImageUseCase, GetCurrentUserIdUseCase, AnalyticsService)` |
| `validateStep(0)` con form real retorna false/true | Confirmado: TC-aud-3 y TC-aud-4 pasan con `FormBuilder` + `GlobalKey<FormBuilderState>` |

---

## Sign-off

- **AC-1:** PASS — `dart analyze` limpio
- **AC-2, AC-3, AC-4, AC-7:** SKIP (fuera de alcance Opción A — portada IA excluida)
- **AC-5:** PASS — `currentStep` default 0, copyWith funcional
- **AC-6:** PASS — `city: ''` en ambos builders tras corrección de BUG-F1-01
- **AC-8:** PASS — `validateStep(0)` verificado con `FormBuilder` real (TC-aud-3, TC-aud-4); TC-stp-9 cubre el caso sin form montado
- **AC-9:** PASS con desviación documentada — step3 tiene 2 form fields (arquitecto D6); tests actualizados
- **AC-10:** PASS — `stepFields` mapeado correctamente
- **AC-11:** PASS — límites de navegación correctos
- **AC-12:** PASS — 9 ARB keys presentes y verificadas en compilación con `AppLocalizationsEs` (TC-aud-5, TC-aud-6)
- **AC-13:** PASS — archivos dead code eliminados
- **AC-14:** PASS — 119/119 tests en verde

**Bugs bloqueantes corregidos:** BUG-F1-01 (city en buildDraftToSave) — corregido en esta iteración.

**Calidad:** GREEN — listo para commit por el humano. Las Fases 2 y 3 pueden arrancar sobre esta base.

---

## Deferred

- **AC-2, AC-3, AC-4, AC-7 (portada IA):** excluida en Opción A; requiere decisión del humano sobre Opción B.
- **Eliminación de `city` del formulario visible** (`EventFormBasicInfoSection`): fuera del alcance de Fase 1; campo sigue visible pero `buildDraftToSave()` ahora ignora su valor correctamente.
- **Backend (`generate-cover.dto.ts`):** `city` como opcional — no implementado en Opción A.

---

## Change log

- 2026-06-11T20:00:40Z: QA run inicial, Fase 1 Opción A. 142/142 tests (conteo Frontend). 0 bugs bloqueantes. Sign-off GREEN (rev 1).
- 2026-06-11T20:11:04Z: Iteración Auditor Opus. Detectado y corregido BUG-F1-01 (`buildDraftToSave()` leía city del form). Añadidos 6 tests (TC-aud-1..6). AC-8 completado con FormBuilder real. AC-12 automatizado con aserción de compilación. 119/119 tests en verde. Sign-off GREEN (rev 2).
