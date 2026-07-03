# QA handoff — waiver-inscripcion-registro

**Date:** 2026-07-02T04:23:50Z
**Status:** done — green (post-auditor test hardening)

---

## Nota de esta corrida

El auditor Opus exigió 5 tests adicionales antes de dar por cerrada la fase (ver PRD §5 AC#1,
AC#3, AC#9/#10, AC#12). Se agregaron los 5 (uno de ellos desdoblado en 2 casos para cubrir tanto
el camino `true` como el default `false`), se re-corrió la suite completa y se actualiza este
catálogo con la cobertura resultante.

Tests agregados en esta corrida (0 cambios a `lib/`, solo `test/`):

1. `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`
   — grupo nuevo *"legal payload built from the real form (AC#9/#10, no buildRegistrationOverride
   seam)"*: 2 casos que ejercitan el `_buildRegistration()` real (sin seam) con un `FormBuilder`
   real (mismo patrón que el caso 2.2 de bloodType ya existente), fijando
   `shareMedicalInfo`/`allowOrganizerContact` vía `patchValue` y asertando sobre el
   `EventRegistrationModel` que llega a `mockAdd`: `riskAcceptanceVersion == 'v0.1-2026-06'`,
   `riskAcceptedAt != null`, y los dos booleanos reflejando el form (caso 1: ambos `true`; caso 2:
   ambos `false` por defecto).
2. Mismo archivo — grupo nuevo *"waiver privacy switches preload on edit (AC#3, guards cubit
   lines 166-169)"*: 1 caso que precarga una inscripción existente con
   `shareMedicalInfo: true, allowOrganizerContact: true` y asegura que
   `formKey.currentState.fields[...]?.value` refleja esos valores tras
   `_preloadFromExistingRegistration`.
3. `test/features/event_registration/constants/registration_form_fields_test.dart` — grupo nuevo
   *"RegistrationWizardSteps.fieldsByStep — waiver phase (AC#1)"*: 2 casos —
   `fieldsByStep.length == 5` (+ `stepCount == 5`) y "el 5º paso está vacío" — que fallarían si se
   revierte el 5º elemento `<String>[]`.
4. `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart`
   — 1 caso nuevo *"both AppSwitchTile widgets default to false in create mode (AC#3)"*: asserta
   `tile.initialValue == false` en los 2 `AppSwitchTile`, no solo `subtitle != null` como antes.
5. `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart`
   — 1 caso nuevo `TC-rfm-a4b`: `cubit.onStepAdvanced(4, AnalyticsParams.stepNameWaiver)` y
   `verify(logEvent(registrationStepAdvanced, {stepIndex: 4, stepName: 'waiver'}))`, mismo patrón
   que `TC-rfm-a2`/`TC-rfm-a4` para otros índices — cierra el gap documentado en la corrida
   anterior de QA (AC#12 solo tenía cobertura por lectura de código).

Total: **7 tests nuevos** en esta corrida (944 = 937 previos + 7).

---

## Catálogo (PRD §5 → cobertura)

| # | Criterio | Cobertura | Test(s) |
|---|----------|-----------|---------|
| 1 | Wizard de 5 pasos visible | nuevo + existente | **nuevo:** `registration_form_fields_test.dart` — `fieldsByStep.length == 5` / `stepCount == 5` / 5º elemento vacío; **existente:** `registration_wizard_controller_test.dart`, `registration_step_indicator_test.dart` (genéricos por `stepCount`, sin tocar) |
| 2 | Switches de privacidad con subtítulos | existente | `registration_medical_step_test.dart` — 2 `AppSwitchTile`, `subtitle != null` |
| 3 | Defaults correctos (create=false, edit=preload) | nuevo + existente | create: `registration_medical_step_test.dart` — **nuevo** caso `initialValue == false` explícito en ambos tiles (antes solo se comprobaba `subtitle != null`); edit: **nuevo** caso en `registration_form_cubit_preload_test.dart` que precarga con `shareMedicalInfo/allowOrganizerContact = true` y verifica `formKey.currentState.fields[...].value` (guarda las líneas 166-169 del cubit, antes solo cubiertas por lectura de código) |
| 4 | Paso waiver: último paso, contenido, sin nav bar | existente | `registration_waiver_step_test.dart`; nav bar oculta por `if (!_wizard.isLastStep)` en `registration_form_content.dart:237` |
| 5 | Cancelar → paso 4 (vehículo), no cierra página | existente | `registration_waiver_step_test.dart` — callback `onBack` |
| 6 | Validación de edad local, sin llamada backend | existente | `registration_form_cubit_age_validation_test.dart` |
| 7 | `UNDERAGE_RIDER` backend → l10n dedicado | existente | `registration_waiver_step_test.dart` (AC#7) |
| 8 | `birthDate` faltante → acción de perfil | existente | `registration_form_cubit_age_validation_test.dart` + `registration_waiver_step_test.dart` |
| 9 | `riskAcceptedAt`/`riskAcceptanceVersion` en payload | nuevo + existente | **nuevo (highest priority):** `registration_form_cubit_preload_test.dart` — ejercita el `_buildRegistration()` REAL (sin `buildRegistrationOverride`) con `FormBuilder` real, asertando `riskAcceptanceVersion == 'v0.1-2026-06'` y `riskAcceptedAt != null` sobre el modelo pasado a `mockAdd`; **existente:** `registration_form_cubit_age_validation_test.dart` (vía seam) |
| 10 | `shareMedicalInfo`/`allowOrganizerContact` en payload | nuevo + existente | mismo test nuevo que #9, 2 casos (`true`/`true` y default `false`/`false`) verificando el modelo real pasado a `mockAdd`; existente: caso vía seam en `registration_form_cubit_age_validation_test.dart` |
| 11 | Validación de marca de vehículo preservada (CTA→`onSubmit`) | existente | `registration_waiver_step_test.dart` |
| 12 | Analítica `registrationStepAdvanced` step_index=4/step_name='waiver' | **nuevo (cierra gap previo)** | `registration_form_cubit_analytics_test.dart` — `TC-rfm-a4b`: `onStepAdvanced(4, stepNameWaiver)` + `verify(logEvent(...))`, mismo patrón que `TC-rfm-a2`/`a4`. Antes solo había cobertura por lectura de código; ahora hay test directo. |
| 13 | `event.ownerName` null manejado, sin crash | existente | `registration_waiver_step_test.dart` |
| 14 | Cero strings hardcodeados, sin claves ARB muertas | manual (grep) | grep de `registration_waiver_step.dart`/`registration_medical_step.dart`: todos los `Text` vía `context.l10n.*`; 14 claves ARB nuevas todas referenciadas |
| 15 | `dart analyze` limpio | verificado | `dart analyze` → "No issues found!" |

## Matriz de regresión (PRD §6 guardrails)

| Guardrail | Mecanismo de verificación | Resultado |
|-----------|---------------------------|-----------|
| No modificar `app_router.dart` | `git diff --stat` no lo lista | OK |
| No `_buildXxx()` que retornan widgets / 1 widget por archivo | lectura de `registration_waiver_step.dart` | OK — 2 `StatelessWidget` (`RegistrationWaiverStep` público + `_RegistrationWaiverError` privado), sin métodos que retornan `Widget` |
| No `Expanded` dentro de `RegistrationWaiverStep` | grep `Expanded` en el archivo | OK — usa `ConstrainedBox(maxHeight: 280)` + `SingleChildScrollView` |
| Nav bar no duplicada / sin parámetro nuevo | `registration_form_content.dart:237` `if (!_wizard.isLastStep)` | OK |
| "Cancelar" solo vía `onBack`, nunca `context.pop()`/cubit directo | grep `context.pop\|cubit\.` en `registration_waiver_step.dart` | OK |
| CTA solo vía `onSubmit`, nunca `cubit.saveRegistration()` directo | mismo grep | OK |
| `RegistrationStepHeader.subtitle` sigue obligatorio | `git diff --stat` no lista el archivo | OK — no modificado |
| Cero strings hardcodeados | grep manual (AC#14) | OK |
| Solo `AppSwitchTile`, nunca `Switch`/`SwitchListTile`/`FormBuilderSwitch`/`CupertinoSwitch` | grep en `registration_medical_step.dart` | OK |
| Detección `UNDERAGE_RIDER` sigue siendo string-based, sin campo `code` inventado | lectura de `registration_waiver_step.dart`/`DomainException` | OK |
| No tocar `rideglory-api` | `git status` (solo `lib/`, `test/`, `docs/exec-runs/`) | OK |
| `dart analyze` y `flutter gen-l10n` limpios | ejecutado por QA | OK |

Watch-list adicional del architect (no AC, pero vigilada):
- `registration_wizard_controller_test.dart` / `registration_step_indicator_test.dart` — pasan sin modificar.
- `registration_form_cubit_preload_test.dart` — sin regresión de preload de bloodType (caso 2.2 pre-existente sigue verde tras agregar los 2 grupos nuevos al mismo archivo).
- `registration_form_cubit_analytics_test.dart` — pasa; el ajuste aditivo `birthDateOverrideForTesting` en `setUp()` (documentado por Frontend) sigue sin romper nada, y el caso nuevo `TC-rfm-a4b` no interfiere con los existentes.

## Ejecución

```
dart analyze                          → No issues found!
flutter test                          → 944/944 pass, 0 fail (0 skipped)
```

Corridas dirigidas (subset relevante a esta fase, incluidas en la corrida completa):
- `registration_form_cubit_age_validation_test.dart` — 5/5 pass
- `registration_waiver_step_test.dart` — pasa (incluye caso AC#7 post-auditoría de la corrida anterior)
- `registration_medical_step_test.dart` — 5/5 pass (incluye el nuevo caso `initialValue == false`)
- `registration_form_cubit_analytics_test.dart` — 15/15 pass (incluye `TC-rfm-a4b` nuevo)
- `registration_form_cubit_preload_test.dart` — 4/4 pass (incluye los 2 grupos nuevos: preload de switches + `_buildRegistration()` real con legal fields)
- `registration_form_fields_test.dart` — 6/6 pass (incluye el grupo nuevo de `fieldsByStep.length == 5`)
- `registration_wizard_controller_test.dart` / `registration_step_indicator_test.dart` — pasan sin modificar

Progresión: 918 (baseline pre-fase) → 937 (corrida QA anterior, tras el fix de AC#7) → **944**
(esta corrida, +7 tests exigidos por el auditor). No hay tests `pre_existing` fallando: la corrida
completa (944/944) no reporta ningún fallo.

No se corrió backend (`rideglory-api`) — fuera de alcance por directiva explícita del architect
("no rideglory-api changes in this phase"); Fases 1-2 de `legal-privacidad-edad` ya cubrieron y
testearon `UNDERAGE_RIDER` (422) en el backend.

## Bugs

Ninguno encontrado. Los 7 tests nuevos exigidos por el auditor pasan contra el código de
producción actual sin necesidad de ningún cambio en `lib/` — es decir, el comportamiento real del
cubit/widgets ya cumplía AC#1, #3, #9, #10 y #12; lo que faltaba era cobertura de test directa, no
una corrección de código. Working tree de `lib/` idéntico al de la corrida QA anterior (solo se
tocó `test/`).

## Pruebas manuales

No ejecutadas por QA (sin dispositivo/simulador en este entorno). Pendientes de verificación
humana en dispositivo real antes de considerar la fase 100% cerrada (sin cambios respecto a la
corrida anterior):

1. Flujo feliz completo (5 pasos → waiver → envío con switches según lo marcado).
2. Rider <18 años → título "No cumples la edad mínima" sin botón "Ir a mi perfil".
3. Edición de inscripción existente → switches precargados correctamente (ahora también cubierto
   por test automatizado, ver AC#3, pero la verificación visual en el widget real sigue pendiente).
4. Nav bar inferior no duplicada/superpuesta en el paso waiver.
5. `UNDERAGE_RIDER` real del backend (422, edge case de reloj/zona horaria) → mensaje genérico
   esperado.

Nota de riesgo ya documentada por el architect y no bloqueante: `error.message.contains('UNDERAGE_RIDER')`
es un chequeo frágil basado en el texto literal del backend; aceptable dado que no hay usuarios
reales aún (memoria del proyecto).

## Sign-off

**GREEN.** 15/15 AC cubiertos, todos con test automatizado directo (AC#12 ya no depende solo de
lectura de código/patrón — tiene su propio caso `TC-rfm-a4b`). Todos los guardrails de §6 se
cumplen. `dart analyze` limpio (repo completo). `flutter test` 944/944 sin fallos, sin
regresiones (+7 tests respecto a la corrida QA anterior, exigidos por el auditor Opus para AC#1,
AC#3 ×2, AC#9/#10, AC#12). Pendiente únicamente verificación manual en dispositivo (5 casos
listados arriba), que no bloquea el sign-off técnico pero se recomienda antes del release.
