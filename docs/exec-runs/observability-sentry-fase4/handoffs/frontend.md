# Frontend handoff — observability-sentry Fase 4

**Fecha:** 2026-06-12T16:26:49Z

---

## Baseline

`flutter test` antes de cualquier cambio: **+616 passed, -2 pre-existing failures** en
`test/features/events/presentation/form/cubit/event_form_stepper_cubit_test.dart` (TC-stp-8,
TC-stp-11). Esos fallos existen en el branch antes de esta fase y no son responsabilidad de este
agente.

---

## Archivos cambiados

### Código de producción

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `lib/core/services/analytics/analytics_events.dart` | mod | Añadidas 6 constantes: `eventsPublishAttempted`, `eventsStepAdvanced`, `eventsStepBack`, `eventsCreateAbandoned`, `registrationSubmitAttempted`, `homeEmptyEventsCta`. |
| `lib/core/services/analytics/analytics_params.dart` | mod | Añadido param `abandonedAtStep` + 4 valores canónicos de `step_name` para wizard de evento (`stepNameBasics`, `stepNameConfig`, `stepNameRoute`, `stepNameReview`). |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | mod | Flag `_terminalEventEmitted`, helper `_stepName()`, analítica en `nextStep()`/`prevStep()`/`saveEvent()`/`saveDraft()`, y `close()` para abandono. |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | mod | Flag `_terminalEventEmitted`, intent en `saveRegistration()`, y `close()` para abandono. |
| `lib/shared/widgets/form/app_button.dart` | mod | Params opcionales `analyticsTapEvent`/`analyticsTapParams`; ambos `InkWell.onTap` (ghost y regular) envuelven `onPressed` con lógica de analytics. |
| `lib/shared/widgets/form/app_text_button.dart` | mod | Mismos params opcionales; método helper `_wrapWithAnalytics()` para evitar duplicación. |
| `lib/features/home/presentation/widgets/home_empty_events_card.dart` | mod | Wire-up de `analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta` en el `AppButton` existente. |
| `lib/shared/router/app_router.dart` | mod | `SentryNavigatorObserver` añadido al array `observers` con gating `kReleaseMode || kSentryDevVerify`. |
| `lib/core/config/sentry_config.dart` | create | Extrae `kSentryDevVerify` de `main.dart` a un archivo de config dedicado para evitar ciclo de imports. |
| `lib/main.dart` | mod | Elimina declaración local de `kSentryDevVerify`; importa desde `sentry_config.dart`. |
| `docs/features/analytics.md` | mod | Catálogo actualizado con 6 nuevos eventos, `abandoned_at_step`, 4 valores de `step_name`, garantías no-PII y patrón `_terminalEventEmitted`. |

### Tests nuevos / ampliados

| Archivo | Tipo | Tests añadidos |
|---------|------|----------------|
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | mod | CA1, CA2a, CA2b, CA2c, CA2d, CA2e, CA2f (7 nuevos tests) |
| `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` | mod | CA1b, CA3, CA3b (3 nuevos tests) |
| `test/shared/widgets/form/app_button_test.dart` | create | CA7a, CA7b, CA7c (3 nuevos tests) |

---

## Pruebas nuevas

### event_form_cubit_analytics_test.dart (7 casos nuevos)

| ID | Descripción |
|----|-------------|
| CA1 | `saveEvent` dispara `events_publish_attempted` con `form_mode` |
| CA2a | `nextStep` desde paso 0 dispara `events_step_advanced` con `step_index=1`, `step_name=config` |
| CA2b | `prevStep` desde paso 1 dispara `events_step_back` con `step_index=0`, `step_name=basics` |
| CA2c | `close()` sin publicar dispara `events_create_abandoned` con `abandoned_at_step=1` |
| CA2d | `close()` tras publicar exitoso NO dispara `events_create_abandoned` (idempotencia) |
| CA2e | `nextStep` en paso 3 es no-op (sin evento) |
| CA2f | `prevStep` en paso 0 es no-op (sin evento) |

### registration_form_cubit_analytics_test.dart (3 casos nuevos)

| ID | Descripción |
|----|-------------|
| CA1b | `saveRegistration` sin form state no dispara `registration_submit_attempted` (early return) |
| CA3 | `close()` sin enviar dispara `registration_abandoned` |
| CA3b | `close()` dispara `registration_abandoned` exactamente una vez |

### app_button_test.dart (3 casos nuevos)

| ID | Descripción |
|----|-------------|
| CA7a | Tap con `analyticsTapEvent` no-null dispara el evento y el `onPressed` |
| CA7b | Tap con `analyticsTapEvent=null` es no-op para analytics (onPressed sigue funcionando) |
| CA7c | Tap con `isLoading=true` no dispara analytics ni `onPressed` |

---

## Resultado final

```
flutter test
+630 passed, -2 pre-existing failures (TC-stp-8, TC-stp-11 en event_form_stepper_cubit_test.dart)
dart analyze lib/ test/shared/widgets/form/app_button_test.dart
  test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart
  lib/features/event_registration/presentation/cubit/registration_form_cubit.dart
  → No issues found
```

Los 2 fallos pre-existentes son anteriores a esta fase y están documentados en el baseline.

### Correcciones del Auditor (ronda 2)

Aplicadas tres correcciones exigidas por AC:

| ID | Archivo | Corrección |
|----|---------|------------|
| AC4a | `test/shared/widgets/form/app_button_test.dart` | Eliminado import `package:get_it/get_it.dart` sin usar (línea 10). |
| AC4b | `test/shared/widgets/form/app_button_test.dart` | Mapa literal `{'key': 'value'}` convertido a `const` (lint `prefer_const_literals_to_create_immutables`). |
| AC3 | `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` | Añadido test **CA3c**: verifica que `close()` NO emite `registration_abandoned` cuando `_terminalEventEmitted = true`. |

**Nota sobre CA3c:** `saveRegistration()` exitoso requiere un `FormBuilderState` real (árbol de widgets); no es simulable en un test unitario puro. Se añadió el método `@visibleForTesting markTerminalEventEmittedForTesting()` a `RegistrationFormCubit` para permitir el test del flag idempotente sin romper encapsulamiento productivo. El comportamiento del flag en el path real sigue cubierto por el hecho de que `_terminalEventEmitted = true` está explícitamente antes de `emit(ResultState.data(...))` en `saveRegistration()`.

---

## Verificación manual

1. **Wizard de creación:** Abrir "Crear evento", avanzar/retroceder pasos → verificar en Firebase DebugView o consola que `events_step_advanced` y `events_step_back` se disparan con `step_index` y `step_name` correctos.
2. **Publicar evento:** Tap en "Publicar" → verificar `events_publish_attempted` antes del spinner.
3. **Abandono:** Abrir wizard y cerrar sin publicar → verificar `events_create_abandoned` con `abandoned_at_step`.
4. **Home CTA vacío:** En home sin eventos, tap en "Ver eventos" → verificar `home_empty_events_cta`.
5. **SentryNavigatorObserver:** Con `--dart-define=SENTRY_DEV_VERIFY=true`, navegar entre pantallas → verificar breadcrumbs de navegación en Sentry (Transactions o Breadcrumbs).

---

## Notas para QA

- `kSentryDevVerify` se activa con `--dart-define=SENTRY_DEV_VERIFY=true`. Sin este flag, en debug Sentry sigue inactivo.
- `events_publish_attempted` se emite ANTES del trabajo async — es un evento de intención (funnel). Si el usuario pulsa "Publicar" y la red falla, veremos `events_publish_attempted` + `events_publish_failed`, sin `events_published`. Esto es correcto por diseño.
- El `close()` de abandono es "mejor esfuerzo" — se emite al destruir el cubit. En pruebas de integración real verificar que `BlocProvider` cierra el cubit al hacer pop de la pantalla.
- Los 4 valores de `step_name` para el wizard de evento (`basics`, `config`, `route`, `review`) son distintos de los del wizard de registro (`personal`, `medical`, `emergency`, `vehicle`). No mezclar en consultas de BigQuery.
