# QA handoff — observability-sentry Fase 4

**Fecha:** 2026-06-12T17:12:21Z
**Agente:** QA
**Nivel:** normal
**Ronda:** 2 (correcciones Auditor Opus aplicadas)

---

## Catalogo de CAs

| CA | Descripción | Test | Estado |
|----|-------------|------|--------|
| CA1 | `saveEvent()` emite `events_publish_attempted` (1 vez, antes del async) + `events_published`; sin doble intención | `event_form_cubit_analytics_test.dart` — "CA1: saveEvent → events_publish_attempted with form_mode fired first" | PASS |
| CA1b | `saveRegistration()` con form state nulo → `registration_submit_attempted` NO se emite (early return) | `registration_form_cubit_analytics_test.dart` — "CA1b: saveRegistration with no form state → registration_submit_attempted NOT fired" | PASS |
| CA1b_positive | `saveRegistration()` exitoso (vía seam) → `registration_submit_attempted` Y `registration_submitted` se emiten | `registration_form_cubit_analytics_test.dart` — "CA1b_positive: saveRegistration with valid data via seam" | PASS (nuevo ronda 2) |
| CA2a | `nextStep()` desde paso 0 emite `events_step_advanced` con `step_index=1`, `step_name=config` | `event_form_cubit_analytics_test.dart` — "CA2a: nextStep from step 0 → events_step_advanced step_index=1 step_name=config" | PASS |
| CA2b | `prevStep()` desde paso 1 emite `events_step_back` con `step_index=0`, `step_name=basics` | `event_form_cubit_analytics_test.dart` — "CA2b: prevStep from step 1 → events_step_back step_index=0 step_name=basics" | PASS |
| CA2c | `close()` sin publicación emite `events_create_abandoned` exactamente 1 vez | `event_form_cubit_analytics_test.dart` — "CA2c: close() without publish → events_create_abandoned fired once" | PASS |
| CA2d | `saveEvent()` exitoso + `close()` → NO emite `events_create_abandoned` (flag idempotente) | `event_form_cubit_analytics_test.dart` — "CA2d: close() after saveEvent success → events_create_abandoned NOT fired" | PASS |
| CA2e | `nextStep()` en paso 3 es no-op (sin evento) | `event_form_cubit_analytics_test.dart` — "CA2e: nextStep when already at step 3 → events_step_advanced NOT fired" | PASS |
| CA2f | `prevStep()` en paso 0 es no-op (sin evento) | `event_form_cubit_analytics_test.dart` — "CA2f: prevStep when already at step 0 → events_step_back NOT fired" | PASS |
| CA3 | `close()` sin envío exitoso emite `registration_abandoned` 1 vez | `registration_form_cubit_analytics_test.dart` — "CA3: close() without submit → registration_abandoned fired once" | PASS |
| CA3b | `close()` dispara `registration_abandoned` exactamente una vez (idempotencia básica) | `registration_form_cubit_analytics_test.dart` — "CA3b: close() fires registration_abandoned exactly once on first close" | PASS |
| CA3c | `close()` tras `_terminalEventEmitted=true` (helper) → `registration_abandoned` NO se emite | `registration_form_cubit_analytics_test.dart` — "CA3c: close() after successful saveRegistration → registration_abandoned NOT fired" | PASS |
| CA3c_real | `saveRegistration()` exitoso real (vía seam) + `close()` → `registration_abandoned` NO se emite (valida el cableado en el fold de éxito) | `registration_form_cubit_analytics_test.dart` — "CA3c_real: saveRegistration success via seam + close()" | PASS (nuevo ronda 2) |
| CA4 | 6 constantes ≤40 chars, sin PII; `docs/features/analytics.md` actualizado | `dart analyze lib/` + revisión manual | PASS |
| CA5 | `SentryNavigatorObserver` en `app_router.dart` con gating `kReleaseMode \|\| kSentryDevVerify` | `grep SentryNavigatorObserver lib/shared/router/app_router.dart` | PASS |
| CA6 | `profile_analytics_optout_tile.dart` sin cambios (opt-out intacto) | `git diff -- lib/features/profile/` = 0 líneas | PASS |
| CA7a | Tap con `analyticsTapEvent` no-null dispara el evento y el `onPressed` | `app_button_test.dart` — "CA7a: tapping AppButton with analyticsTapEvent fires the event" | PASS |
| CA7b | Tap con `analyticsTapEvent=null` → no-op para analytics (onPressed sigue funcionando) | `app_button_test.dart` — "CA7b: tapping AppButton with null analyticsTapEvent is a no-op for analytics" | PASS |
| CA7c | Tap con `isLoading=true` → no dispara analytics ni `onPressed` | `app_button_test.dart` — "CA7c: tapping AppButton with isLoading=true does not fire analytics" | PASS |
| AC1-auth | Aserto documental: no se añaden eventos de auth nuevos en Fase 4; `authMethodSelected` se reutiliza | `registration_form_cubit_analytics_test.dart` — "AC1-auth: authMethodSelected is the single auth event reused in Fase 4" | PASS (nuevo ronda 2) |

---

## Matriz de regresion

| Guardrail §6 | Mecanismo | Resultado |
|-------------|-----------|-----------|
| `dart analyze` sin errores nuevos | `dart analyze lib/` ejecutado | CLEAN — No issues found |
| `flutter test` verde (ningún test previo roto) | Suite completa ejecutada | 956 passed, 2 pre-existing failures (TC-stp-8, TC-stp-11 en `event_form_stepper_cubit_test.dart`) — sin regresiones nuevas |
| `analyticsTapEvent` null por defecto sin cambios de comportamiento | CA7b verifica no-op; revisión de diff: `InkWell.onTap` preserva el handler original | PASS |
| No emitir analytics en tests unitarios con `AnalyticsService` real | Los tests usan `MockAnalyticsService` (mocktail); `getIt.reset()` en tearDown en `app_button_test` | PASS |
| Flag idempotente `_terminalEventEmitted` previene doble emisión | CA2d, CA3c, CA3c_real verifican idempotencia; flag seteado antes de `emit(ResultState.data(...))` | PASS |
| `SentryNavigatorObserver` con gating dev/prod de Fase 3 | `kReleaseMode \|\| kSentryDevVerify` en el condicional del observer | PASS |
| No GestureDetector extra alrededor de botones | `git diff --unified=0 -- lib/shared/widgets/form/app_button.dart` sin líneas `+GestureDetector` ni `+Widget _build` | PASS |
| Un widget por archivo / sin métodos `Widget _buildX()` | Revisión del diff: `app_text_button.dart` usa helper `_wrapWithAnalytics()` que retorna `VoidCallback?`, no un Widget | PASS |

---

## Ejecucion

### `dart analyze lib/`

```
Analyzing lib...
No issues found!
```

### `dart analyze test/` (archivos nuevos)

```
Analyzing event_form_cubit_analytics_test.dart, registration_form_cubit_analytics_test.dart, app_button_test.dart...
No issues found!
```

Nota: `dart analyze test/` completo muestra 15 issues (info/warning), todos en archivos pre-existentes
(`sentry_crash_reporter_test.dart`, `ai_description_repository_impl_test.dart`,
`event_form_basic_info_section_test.dart`, `event_form_step1_test.dart`,
`app_rich_text_editor_external_controller_test.dart`, `event_form_stepper_cubit_test.dart`,
`event_form_stepper_p2_qa_test.dart`). Ninguno introducido por esta fase.

### `flutter test` (suite completa)

```
Total passed: 956
Total failures: 2
Success: false

FAIL [pre-existing]: EventFormCubit — stepper (Fase 1) TC-stp-8: _step1Fields.length == 5, _step2Fields.length == 7, _step3Fields.length == 2
  Error: Expected: <5> Actual: <3>
  File: test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart:117

FAIL [pre-existing]: EventFormCubit — stepper (Fase 1) TC-stp-11: step 0 fields are correct
  Error: Expected: contains all of ['name', 'description', 'dateRange', 'isMultiDay', 'meetingTime']
  Actual: ['name', 'dateRange', 'meetingTime']
  File: test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart:138
```

Ambos fallos estaban documentados en el baseline del agente Frontend como pre-existentes antes de que esta fase comenzara.

### `flutter test` (archivos nuevos/modificados ronda 2)

```
+14: All tests passed! (registration_form_cubit_analytics_test.dart — 14 tests)
+16: All tests passed! (event_form_cubit_analytics_test.dart — 16 tests)
+3: All tests passed! (app_button_test.dart — 3 tests)
```

Nuevos tests añadidos en ronda 2: CA1b_positive, CA3c_real, AC1-auth (3 nuevos).
Total tests nuevos de esta fase: 33 (ronda 1: 30, ronda 2: +3).

### Guardrails ad-hoc verificados

```bash
$ grep SentryNavigatorObserver lib/shared/router/app_router.dart
      if (kReleaseMode || kSentryDevVerify) SentryNavigatorObserver(),

$ git diff -- lib/features/profile/
(0 líneas — sin cambios)
```

Longitud de constantes nuevas (todas ≤40 chars):
- `events_publish_attempted`: 24 ✓
- `events_step_advanced`: 20 ✓
- `events_step_back`: 16 ✓
- `events_create_abandoned`: 23 ✓
- `registration_submit_attempted`: 29 ✓
- `home_empty_events_cta`: 21 ✓

`docs/features/analytics.md`: las 6 constantes nuevas aparecen en el catálogo (grep confirmado).

---

## Correcciones ronda 2 (requeridas por Auditor Opus)

### Cambios en código de producción

| Archivo | Cambio |
|---------|--------|
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | Añadido campo `@visibleForTesting buildRegistrationOverride: EventRegistrationModel? Function()?`; modificado `_buildRegistration()` para comprobar el override antes del FormBuilderState. Esto permite tests unitarios del path positivo sin árbol de widgets. |
| `lib/core/services/analytics/analytics_events.dart` | Añadido comentario documental en `authMethodSelected` confirmando la decisión explícita de Fase 4 de no añadir eventos de auth nuevos (§3 "No entra" del PRD). |

### Cambios en tests

| Archivo | Tests añadidos |
|---------|----------------|
| `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` | `setUpAll` con `registerFallbackValue`; helper `_buildFakeRegistration()`; **CA1b_positive** (path positivo: `registration_submit_attempted` + `registration_submitted` se emiten); **CA3c_real** (save real vía seam + close → no abandoned, valida el cableado del fold de éxito); **AC1-auth** (aserto documental de reutilización de `authMethodSelected`). |

### Justificación de CA3c_real + `Future.delayed(Duration.zero)`

dartz `Either.fold()` no awaita callbacks async. En consecuencia, `saveRegistration()` retorna antes de que el callback async interno (que hace `await _saveRiderProfileUseCase(...)` y luego `emit(data)`) complete. Si se llama a `close()` inmediatamente después, el `emit(data)` pendiente lanza "Cannot emit new states after calling close". La solución canónica es bombear la cola de microtareas con `await Future<void>.delayed(Duration.zero)` entre `saveRegistration()` y `close()`. Esta técnica está documentada en el propio comentario del test para que futuros mantenedores entiendan el por qué.

---

## Bugs

Ningún bug nuevo identificado en esta fase. Los 2 fallos de `flutter test` son pre-existentes (TC-stp-8 y TC-stp-11, documentados en el baseline del Frontend).

---

## Pruebas manuales

Las siguientes pruebas requieren correr la app con Firebase DebugView activo (`--dart-define=FIREBASE_DEBUG_VIEW=true`) o la consola de Flutter:

1. **Step tracking wizard de creación:** Abrir "Crear evento", avanzar/retroceder pasos. Esperado: `events_step_advanced`/`events_step_back` con `step_index` y `step_name` correctos en Firebase DebugView.
2. **Intención de publicar:** Tap en "Publicar". Esperado: `events_publish_attempted` antes del spinner, seguido de `events_published` (éxito) o `events_publish_failed` (error).
3. **Abandono de creación:** Abrir wizard, retroceder a la pantalla home sin publicar. Esperado: `events_create_abandoned` con `abandoned_at_step` correcto.
4. **Home CTA vacío:** En home sin eventos, tap en "Ver eventos". Esperado: `home_empty_events_cta` en consola.
5. **SentryNavigatorObserver:** Con `--dart-define=SENTRY_DEV_VERIFY=true`, navegar entre pantallas. Esperado: breadcrumbs de navegación en Sentry (Transactions/Breadcrumbs).
6. **Opt-out intacto:** Perfil → toggle de analytics. Confirmar que el switch sigue siendo `AppSwitch` (pill naranja, knob oscuro) sin cambios visuales.

---

## Sign-off

**Veredicto: GREEN**

- `dart analyze lib/` limpio (sin issues nuevos).
- `flutter test` verde salvo los 2 fallos pre-existentes (TC-stp-8, TC-stp-11) que son anteriores a esta fase.
- Los 33 tests nuevos de esta fase pasan en verde (30 ronda 1 + 3 ronda 2).
- Todos los CAs §5 tienen cobertura de test, incluyendo los paths positivos exigidos por el Auditor.
- Todos los guardrails §6 verificados mecánicamente.
- Seam `buildRegistrationOverride` añadido a `RegistrationFormCubit` para garantizar que CA1b_positive y CA3c_real fallen si los call sites son removidos.
- Comentario documental añadido en `AnalyticsEvents.authMethodSelected` confirmando la decisión de no extender auth en Fase 4.
- Sin bugs introducidos por esta fase.
