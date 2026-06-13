# Architect handoff — observability-sentry Fase 4

**Date:** 2026-06-12T16:00:09Z
**Status:** done

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| D1 | No hay cambios en backend, contratos ni migraciones. | PRD §4 lo indica explícitamente; toda la instrumentación ocurre en cliente Flutter. |
| D2 | `events_publish_attempted` se emite al inicio de `EventFormCubit.saveEvent()`, antes de la llamada async. | Permite separar "intentó" de "completó"; sin doble conteo porque el resultado ya tiene `eventsPublished` / `eventsPublishFailed`. |
| D3 | `events_step_advanced` / `events_step_back` se emiten dentro de `nextStep()` / `prevStep()` solo cuando el cambio de índice es efectivo (guarda: `next <= 3` / `prev >= 0`). No se emiten cuando la validación bloquea el avance — la llamada a `validateStep` seguirá siendo responsabilidad del caller de `nextStep()`; el cubit emite solo si el estado cambia. | Garantía de baja cardinalidad; evita falsos positivos si el rider llega al step 3 y vuelve a pulsar Siguiente. |
| D4 | Flag `bool _terminalEventEmitted` en `EventFormCubit` controla abandono idempotente. Se activa en `saveEvent()` exitoso y en `saveDraft()` exitoso. `close()` emite `events_create_abandoned` solo si el flag está en false. | Previene doble emisión en hot-reload o re-creación del cubit por el BlocProvider. |
| D5 | `RegistrationFormCubit` recibe el mismo flag `bool _terminalEventEmitted`; se activa en `saveRegistration()` exitoso; `close()` emite `registration_abandoned` solo si flag == false. La constante `registrationAbandoned` ya existe en el catálogo sin call site — solo se agrega el call site. | La constante ya está documentada en Fase 7; solo falta cablear el punto de cierre. |
| D6 | `AppButton` y `AppTextButton` en `lib/shared/widgets/form/` reciben dos parámetros opcionales nulos por defecto: `analyticsTapEvent: String?` y `analyticsTapParams: Map<String, Object>?`. `AnalyticsService` se resuelve puntualmente en el handler via `GetIt` (`getIt<AnalyticsService>()`) — nunca en `build`. | Mantiene `AppButton` sin BlocProvider; no rompe ningún sitio de llamada existente (todos los null son no-ops). |
| D7 | `HomeEmptyEventsCard` es el único reference wire-up del fallback de tap en design system. El `AppButton` existente recibe `analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta` (nueva constante, ver catálogo). | Demuestra el patrón sin afectar CTAs que ya tienen cubit (donde la intención se emite en el handler). |
| D8 | `SentryNavigatorObserver` se añade a la lista `observers` de `AppRouter.appRouter` junto al `analyticsObserver` existente. Gating: en debug solo cuando `kSentryDevVerify == true`; en prod siempre. Se implementa con un condicional en la lista de observers. | Sentry ya fue inicializado en Fase 3; el DSN vacío en dev hace que el observer sea un no-op efectivo sin el flag. |
| D9 | Se añaden 4 valores canónicos de `step_name` para el wizard de evento en `AnalyticsParams`: `stepNameBasics='basics'`, `stepNameConfig='config'`, `stepNameRoute='route'`, `stepNameReview='review'`. | Los 4 ya existentes (`personal`, `medical`, `emergency`, `vehicle`) son del wizard de registro; el de creación necesita los suyos propios. |
| D10 | Nueva constante `homeEmptyEventsCta` en `AnalyticsEvents` para el CTA de referencia en `HomeEmptyEventsCard`. Esto hace 6 constantes nuevas totales (PRD dice 5; el item 7 de alcance implica un evento de tap para la referencia). | Sin la constante no hay catálogo. `.length == 22` ≤ 40. |

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `lib/core/services/analytics/analytics_events.dart` | modify | Añadir 6 constantes: `eventsPublishAttempted`, `eventsStepAdvanced`, `eventsStepBack`, `eventsCreateAbandoned`, `registrationSubmitAttempted`, `homeEmptyEventsCta` | low |
| `lib/core/services/analytics/analytics_params.dart` | modify | Añadir `abandonedAtStep` key + 4 valores canónicos de `step_name` para el wizard de evento (`stepNameBasics`, `stepNameConfig`, `stepNameRoute`, `stepNameReview`) | low |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | (1) `_terminalEventEmitted` flag; (2) `close()` con abandono idempotente; (3) `events_publish_attempted` al inicio de `saveEvent()`; (4) `events_step_advanced/back` en `nextStep()`/`prevStep()` | med — cubit de wizard crítico |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | modify | (1) `_terminalEventEmitted` flag; (2) `close()` con `registration_abandoned`; (3) `registration_submit_attempted` al inicio de `saveRegistration()` | med — cubit de registro |
| `lib/shared/widgets/form/app_button.dart` | modify | Añadir params opcionales `analyticsTapEvent` / `analyticsTapParams`; resolver `AnalyticsService` puntualmente en `onTap` handler | low — null por defecto, sin breaking change |
| `lib/shared/widgets/form/app_text_button.dart` | modify | Idem AppButton | low — null por defecto |
| `lib/features/home/presentation/widgets/home_empty_events_card.dart` | modify | Pasar `analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta` al `AppButton` existente | low |
| `lib/shared/router/app_router.dart` | modify | Añadir `SentryNavigatorObserver` a lista `observers` con gating `kSentryDevVerify` | low |
| `docs/features/analytics.md` | modify | Actualizar catálogo con los 6 nuevos eventos y el nuevo param `abandoned_at_step` | low |
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | modify | Añadir tests para step tracking, publish intent, abandono (CAs 1 y 2) | low |
| `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` | modify | Añadir tests para submit intent, abandono (CAs 1 y 3) | low |
| `test/shared/widgets/form/app_button_test.dart` | create | Test widget del param opcional `analyticsTapEvent` (CA 7) | low |

---

## Contratos rideglory-api

Ninguno. Esta fase es 100% client-side; cero cambios en endpoints, DTOs, contratos ni módulos NestJS.

---

## Datos / Migraciones

Ninguna. No hay nuevos esquemas, tablas, colecciones Firestore ni campos en modelos de dominio.

---

## Env

Ningún delta de variables de entorno. La palanca `SENTRY_DEV_VERIFY` ya existe (definida en `main.dart` Fase 3); no se añaden claves nuevas.

---

## Riesgos

| Riesgo | Nivel | Mitigación |
|--------|-------|------------|
| Doble conteo de `events_create_abandoned` en hot-reload | med | Flag `_terminalEventEmitted`; tests CAs 2(c) y 2(d) lo verifican |
| `EventFormCubit.close()` nunca llamado en el árbol actual | low | Verificar que el BlocProvider del wizard dispone el cubit al hacer pop; si no, agregar `dispose()` manual en la página |
| `AppButton` no tiene acceso a `BuildContext` en el InkWell handler — resolución via `getIt` | low | `getIt<AnalyticsService>()` es singleton ya registrado al momento del tap; no requiere context |
| `SentryNavigatorObserver` requiere que `SentryFlutter.init` esté completo antes del primer frame | low | Ya está en Fase 3; el init ocurre antes de `runApp` |
| Test de `AppButton` requiere inyectar un fake `AnalyticsService` en `GetIt` | low | `getIt.registerSingleton<AnalyticsService>(FakeAnalyticsService())` en `setUp`; `getIt.reset()` en `tearDown` |

---

## Orden de implementación

1. `analytics_events.dart` — nuevas constantes (base; todo lo demás las importa)
2. `analytics_params.dart` — `abandonedAtStep` + 4 step_name values
3. `event_form_cubit.dart` — step tracking + publish intent + abandono
4. `registration_form_cubit.dart` — submit intent + abandono
5. `app_button.dart` + `app_text_button.dart` — params opcionales
6. `home_empty_events_card.dart` — reference wire-up
7. `app_router.dart` — `SentryNavigatorObserver`
8. `docs/features/analytics.md` — update catalog
9. Tests (event_form_cubit_analytics_test, registration_form_cubit_analytics_test, app_button_test)

---

## Superficie de regresión

- **EventFormCubit**: `nextStep()`, `prevStep()`, `saveEvent()`, `saveDraft()` cambian; cualquier test que llame a estos métodos puede requerir mock de `AnalyticsService`. El test existente `event_form_cubit_analytics_test.dart` ya usa `MockAnalyticsService`.
- **RegistrationFormCubit**: `saveRegistration()` cambia; el test existente `registration_form_cubit_analytics_test.dart` necesita stub de `logEvent` para el nuevo evento.
- **AppButton / AppTextButton**: el `onTap` handler accede a `getIt`; tests de widget que no configuren `getIt` lanzarán `StateError`. Usar `getIt.registerSingleton` en setUp.
- **AppRouter**: la lista `observers` tiene un nuevo elemento condicionado; no hay impacto en routing, solo en tracking de Sentry.
- `dart analyze` debe quedar limpio (los 2 lints de `api_base_url_resolver.dart` son intencionados; no tocar).

---

## Fuera de alcance

- PostHog, BigQuery, dashboards.
- Nuevos eventos de auth (ya cubiertos por Fase anterior).
- Pantallas nuevas o cambios de copy en el tile de opt-out.
- Parámetros PII o de alta cardinalidad.
- Backend / rideglory-api.
