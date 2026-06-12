# PRD Normalizado — Observability Sentry Fase 4: Insights de Producto

- **Generado (UTC):** 2026-06-12T15:58:07Z
- **Slug:** `observability-sentry-fase4`
- **Fuente:** `docs/plans/observability-sentry/phases/phase-04-insights-de-producto-taps-screen-view-y-catalogo.md`
- **Nivel rg-exec:** lite

---

## 1 Objetivo

Ampliar la instrumentación de analytics (GA4) existente para que Producto pueda entender el comportamiento real de los riders en los embudos clave: intención de tap en CTAs críticos, `screen_view` consistente, drop-off observable por paso en el wizard de creación de evento (4 pasos: basics/config/route/review) y en el wizard de registro, y abandono de ambos flujos. Todo con un catálogo de baja cardinalidad, sin PII, documentado en markdown. Sin pantallas nuevas. Sin PostHog. Cablear además `SentryNavigatorObserver` (ya desbloqueado por Fase 3).

---

## 2 Por qué

- El wizard de creación de evento (4 pasos) ya está implementado y commiteado, pero carece de instrumentación de step-tracking y abandono; el de registro tiene steps pero le falta el evento de abandono.
- Los CTAs de publicar evento y enviar registro no tienen evento de intención (`*_attempted`), solo resultado; sin intención no se puede distinguir "intentó pero falló" de "ni lo intentó".
- `SentryNavigatorObserver` estaba diferido por falta de `SentryFlutter.init`; la Fase 3 ya lo entregó, así que el cableado es seguro en esta fase.
- El catálogo `docs/features/analytics.md` quedará desactualizado sin este cierre documental.

---

## 3 Alcance

### Entra

1. **Step tracking en wizard de creación de evento** (`EventFormCubit`): eventos `events_step_advanced` y `events_step_back` en `nextStep()`/`prevStep()` con params `step_index` (0-3) y `step_name` (basics/config/route/review), solo cuando el cambio es efectivo.
2. **Abandono de creación de evento**: `events_create_abandoned` en `EventFormCubit.close()` con flag idempotente, params `form_mode` + `abandoned_at_step` (= `state.currentStep`). No emite si ya se publicó o guardó borrador.
3. **Intención de tap — publicar evento**: `events_publish_attempted` al entrar a `EventFormCubit.saveEvent(...)`, antes del trabajo async.
4. **Intención de tap — enviar registro**: `registration_submit_attempted` al entrar a `RegistrationFormCubit.saveRegistration()`, antes del trabajo async.
5. **Abandono de registro**: cablear `registration_abandoned` (constante ya existe, sin call site) en `RegistrationFormCubit.close()` con flag idempotente.
6. **Fallback de tap en design system**: params opcionales `analyticsTapEvent: String?` y `analyticsTapParams: Map<String, Object>?` en `AppButton` y `AppTextButton`; cableado de referencia en `home_empty_events_card.dart` (CTA de navegación pura, sin Cubit). `AnalyticsService` se resuelve puntualmente en el handler, nunca en `build`.
7. **`SentryNavigatorObserver`**: añadir a la lista `observers` de `app_router.dart` (junto al `analyticsObserver` existente). Gating existente: dev solo bajo `kSentryDevVerify`, prod siempre.
8. **Catálogo**: 5 nuevas constantes en `analytics_events.dart` + 1 param nuevo (`abandoned_at_step`) + 4 valores canónicos de `step_name` en `analytics_params.dart`. Actualizar `docs/features/analytics.md`.

### No entra

- PostHog, dashboards, BigQuery export.
- Pantallas nuevas o cambios de copy/estilo en el tile de opt-out.
- Params PII o de alta cardinalidad (ids dinámicos, emails, placas, coordenadas).
- Nuevos eventos de auth: se reusa `authMethodSelected` en sus call sites existentes (cobertura total ya presente).

### Regla anti-doble-conteo (vinculante)

Cada CTA emite exactamente UN evento de intención. Taxonomía: intención (`*_attempted`/`*_selected`) en la entrada del handler vs. resultado (`*_published`/`*_submitted`/`*_failed`) en la completación. Nunca dos eventos de intención por un mismo tap. El fallback en `AppButton`/`AppTextButton` se usa solo para CTAs de navegación pura sin Cubit.

---

## 4 Áreas afectadas

| Área | Archivos principales |
|------|----------------------|
| Analytics catalog | `lib/core/services/analytics/analytics_events.dart`, `analytics_params.dart` |
| Event form cubit | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` |
| Registration form cubit | `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` |
| Design system | `lib/shared/widgets/form/app_button.dart`, `app_text_button.dart` |
| Home card (tap referencia) | `lib/features/home/presentation/widgets/home_empty_events_card.dart` |
| Router | `lib/shared/router/app_router.dart` |
| Docs | `docs/features/analytics.md` |
| Tests | `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart`, `test/features/event_registration/presentation/cubit/registration_form_cubit_test.dart`, `test/shared/widgets/form/app_button_test.dart` |

Sin cambios en backend, contratos, esquemas de datos ni migraciones.

---

## 5 Criterios de aceptación

1. **Intención de tap sin doble conteo.** Existe un test de cubit que, al invocar `EventFormCubit.saveEvent(...)` con éxito, verifica que se emite `events_publish_attempted` (intención, exactamente una vez, antes del trabajo async) y `events_published` (resultado), y que NO se emite un segundo evento de intención. Análogamente, `RegistrationFormCubit.saveRegistration()` emite `registration_submit_attempted` + `registration_submitted`. Para auth no se añaden eventos nuevos: un assert documental/comentario confirma que se reusa `authMethodSelected`. El test falla contra el código actual.

2. **Drop-off por step + abandono en wizard de creación (4 pasos).** Un test de cubit verifica: (a) `nextStep()`/`prevStep()` con avance/retroceso efectivo emiten `events_step_advanced`/`events_step_back` con `step_index` y `step_name` correctos (basics/config/route/review); (b) `nextStep()` bloqueado por validación NO emite el evento; (c) `close()` sin publicación ni borrador emite exactamente una vez `events_create_abandoned` con `form_mode` y `abandoned_at_step = state.currentStep`; (d) tras `saveEvent`/`saveDraft` exitoso + `close()`, `events_create_abandoned` NO se emite (flag idempotente). El test falla contra el cubit actual.

3. **Abandono de registro cableado.** Un test verifica que `RegistrationFormCubit.close()` sin envío exitoso emite `registration_abandoned` exactamente una vez, y que tras `saveRegistration()` exitoso + `close()` no se emite. Falla contra el código actual (la constante existe pero sin call site).

4. **Catálogo de baja cardinalidad y sin PII.** Las 5 constantes nuevas tienen ≤40 chars (verificable por `.length`), no contienen ids/email/placa/VIN/coordenadas, y sus params son `form_mode`, `step_index`, `step_name`, `abandoned_at_step` o ninguno. `docs/features/analytics.md` lista todos los eventos (incluyendo los 5 nuevos) con trigger real y política no-PII. `dart analyze` limpio.

5. **`screen_view` consistente + `SentryNavigatorObserver` cableado.** Un test confirma que `AnalyticsRouteObserver` emite `screen_view` por transición con dedupe (sin regresión). `grep SentryNavigatorObserver lib/shared/router/app_router.dart` encuentra el observer dentro de la lista `observers` activa.

6. **Opt-out intacto.** El tile `profile_analytics_optout_tile.dart` sigue usando `AppSwitch` con knob/elementos oscuros sobre primario, sin cambios de copy ni estilo. Sin Material `Switch`/`SwitchListTile`/`FormBuilderSwitch`.

7. **Sin `GestureDetector` extra ni helpers que retornen widgets.** El diff no introduce `GestureDetector` nuevos alrededor de botones ni métodos `Widget _buildX()`. Los taps se emiten en handlers de Cubit o vía el param opcional del design system, nunca envolviendo widgets en detectores extra.

---

## 6 Guardrails de regresión

- `dart analyze` sin errores nuevos (el archivo `api_base_url_resolver.dart` con `shouldUseLocalApi=true` tiene 2 lints conocidos e intencionados — no tocar).
- `flutter test` verde: ningún test existente debe romperse.
- El param `analyticsTapEvent` en `AppButton`/`AppTextButton` es null por defecto; comportamiento sin cambios cuando no se provee.
- No emitir analytics en tests unitarios con un `AnalyticsService` real; usar fake/mock que registre llamadas.
- El flag idempotente `_terminalEventEmitted` previene doble emisión de abandono en hot-reload o re-creación de cubit.
- `SentryNavigatorObserver` usa el mismo gating de Fase 3: en dev solo bajo `kSentryDevVerify`, en prod siempre.

---

## 7 Constraints heredados

- **Un widget por archivo** — ningún método `Widget _buildX()`.
- **Texto oscuro sobre primario** — sobre acento naranja, texto/iconos/knob van oscuros (`darkBgPrimary`), nunca blanco.
- **Switch unificado** — solo `AppSwitch`/`AppSwitchTile`; nunca Material/CupertinoSwitch.
- **Localización** — cualquier texto visible en `app_es.arb`; no hardcodear literales en UI.
- **DTO Pattern B** — no aplica directamente; esta fase no toca DTOs ni endpoints.
- **No commitear** — el árbol de trabajo queda sucio; el humano commitea tras revisar.
- **No tocar** `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`.
- **`api_base_url_resolver.dart`** con `shouldUseLocalApi=true` es config local del usuario; no revertir ni commitear.
