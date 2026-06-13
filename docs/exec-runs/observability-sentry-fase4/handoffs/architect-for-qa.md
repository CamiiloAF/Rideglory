> Slim handoff — read this before handoffs/architect.md

# QA handoff — observability-sentry Fase 4

**Fecha:** 2026-06-12T16:00:09Z

---

## Comandos de verificación

```bash
# Análisis estático (debe quedar limpio)
dart analyze

# Suite completa
flutter test

# Tests nuevos / modificados por esta fase
flutter test test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart
flutter test test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart
flutter test test/shared/widgets/form/app_button_test.dart

# Grep de guardrail: SentryNavigatorObserver cableado
grep SentryNavigatorObserver lib/shared/router/app_router.dart
```

---

## Trazabilidad de CAs

| CA | Descripción | Test de referencia |
|----|-------------|-------------------|
| CA1 | `EventFormCubit.saveEvent()` exitoso emite `events_publish_attempted` (1 vez, antes del async) + `events_published`; sin doble intención | `event_form_cubit_analytics_test.dart` — test "saveEvent emits publish_attempted then published" |
| CA1b | `RegistrationFormCubit.saveRegistration()` exitoso emite `registration_submit_attempted` + `registration_submitted` | `registration_form_cubit_analytics_test.dart` — test "saveRegistration emits submit_attempted then submitted" |
| CA2a | `nextStep()` / `prevStep()` con cambio efectivo emiten `events_step_advanced` / `events_step_back` con `step_index` y `step_name` correctos | `event_form_cubit_analytics_test.dart` — "nextStep emits step_advanced" |
| CA2b | `nextStep()` cuando ya está en step 3 (bloqueado) NO emite | `event_form_cubit_analytics_test.dart` — "nextStep at max does not emit" |
| CA2c | `close()` sin publicación emite `events_create_abandoned` exactamente 1 vez con `form_mode` + `abandoned_at_step` | `event_form_cubit_analytics_test.dart` — "close without save emits abandoned" |
| CA2d | `saveEvent()` exitoso + `close()` → NO emite `events_create_abandoned` (flag idempotente) | `event_form_cubit_analytics_test.dart` — "close after save does NOT emit abandoned" |
| CA3 | `RegistrationFormCubit.close()` sin submit exitoso emite `registration_abandoned` 1 vez | `registration_form_cubit_analytics_test.dart` — "close without save emits abandoned" |
| CA3b | `saveRegistration()` exitoso + `close()` → NO emite `registration_abandoned` | `registration_form_cubit_analytics_test.dart` — "close after save does NOT emit abandoned" |
| CA4 | 6 nuevas constantes tienen ≤40 chars, sin PII; `docs/features/analytics.md` actualizado | `dart analyze` + revisión manual del catálogo |
| CA5 | `grep SentryNavigatorObserver lib/shared/router/app_router.dart` retorna ≥1 línea | Script de grep del CA |
| CA6 | `profile_analytics_optout_tile.dart` sin cambios (opt-out intacto) | `git diff -- lib/features/profile/` debe mostrar 0 líneas en ese archivo |
| CA7 | `AppButton` con `analyticsTapEvent` nulo no introduce `GestureDetector` extra; con valor no nulo emite al tap | `app_button_test.dart` |

---

## Setup de mocks para tests de cubit

```dart
// En setUp de event_form_cubit_analytics_test.dart
when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
```

## Setup de GetIt para app_button_test.dart

```dart
setUp(() {
  getIt.registerSingleton<AnalyticsService>(FakeAnalyticsService());
});
tearDown(() async {
  await getIt.reset();
});
```

---

## Regresión crítica a vigilar

- `flutter test` verde completo (ningún test previo debe romperse).
- `dart analyze` sin errores nuevos (los 2 lints de `api_base_url_resolver.dart` son OK).
- Confirmar que `AppButton` con `analyticsTapEvent: null` se comporta exactamente igual que antes (sin tap extra, sin crash).

> Full detail: handoffs/architect.md
