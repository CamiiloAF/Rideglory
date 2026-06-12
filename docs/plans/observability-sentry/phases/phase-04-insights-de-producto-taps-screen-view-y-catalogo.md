# Fase 4 — Insights de producto: taps, screen_view y catálogo documentado

- **Generado (UTC):** 2026-06-10T22:25:24Z
- **Plan:** observability-sentry
- **Nivel rg-exec recomendado:** lite
- **dependsOn:** [Fase 3] (ambas subtareas antes diferidas — `SentryNavigatorObserver` y drop-off por step — ya están desbloqueadas: Fase 3 entregó `SentryFlutter.init` y el wizard de 4 pasos ya está commiteado)
- **Insumos:** `05-sintesis.md`, `01-scan.md`, `03-architect-review.md`

## Objetivo

Producto entiende mejor el comportamiento real de los riders: intención de tap en los CTA clave, `screen_view` consistente y drop-off observable **por paso** en los embudos con wizard (creación de evento, registro) más auth, todo con un catálogo de eventos de baja cardinalidad, sin PII, y documentado en markdown. Es expansión incremental sobre la base ya instrumentada (~61 eventos en `analytics_events.dart`, opt-out funcional, `AnalyticsRouteObserver` emitiendo `screen_view`). **Sin pantallas nuevas. PostHog fuera de alcance.**

> **ACTUALIZADO 2026-06-12 — el form de creación ya NO es de una sola pantalla.** El wizard de 4 pasos (`event-form-stepper`) **ya está implementado y commiteado** (`lib/features/events/presentation/form/cubit/event_form_cubit.dart` con `currentStep` 0-3, `nextStep()`/`prevStep()`/`goToStep()`; widgets `widgets/steps/event_form_step1..4`). Por tanto la subtarea antes diferida "drop-off por step" **entra ahora en alcance** y espeja el patrón ya existente del wizard de registro (`registration_step_advanced`/`registration_step_back`). Los pasos son: `0=basics` (nombre/fechas/hora), `1=config` (dificultad/tipo/precio/cupos/marcas), `2=route` (punto de encuentro/destino), `3=review`.

## Alcance (entra / no entra)

### Entra

1. **Instrumentar drop-off POR STEP en el wizard de creación de evento** (espeja el wizard de registro):
   - `events_step_advanced` (NUEVO) en `EventFormCubit.nextStep()` cuando el avance es efectivo (validación OK, `currentStep` cambió), con params `step_index` (0-3) y `step_name` (`basics`/`config`/`route`/`review`).
   - `events_step_back` (NUEVO) en `EventFormCubit.prevStep()` cuando el retroceso es efectivo, mismos params.
   - `events_create_abandoned` (NUEVO) en `EventFormCubit.close()` con flag idempotente, params `form_mode` **+ `abandoned_at_step`** (= `currentStep` alcanzado al cerrar, baja cardinalidad 0-3) para ubicar dónde se cae el embudo.
   - Se reusan los eventos ya existentes `events_create_started` (apertura), `events_published` / `events_draft_saved` (resultado) y `events_publish_failed`.
2. **Cablear el evento de abandono de registro ya declarado pero NO emitido** (`AnalyticsEvents.registrationAbandoned`, constante presente, sin call site hoy) en `RegistrationFormCubit.close()` con flag idempotente. El embudo de registro por step ya está instrumentado (`registration_step_advanced` / `registration_step_back`); esta fase solo añade la cola de abandono que falta.
3. **Intención de tap (intent) en los CTA clave que hoy NO tienen evento de intención**, emitida desde el handler del Cubit ya inyectado con `AnalyticsService`:
   - `events_publish_attempted` (NUEVO) al entrar a `EventFormCubit.saveEvent(...)`, antes del trabajo async. Mide intención de publicar; distinta del resultado `events_published`/`events_publish_failed`.
   - `registration_submit_attempted` (NUEVO) al entrar a `RegistrationFormCubit.saveRegistration()`, antes del trabajo async. Mide intención de enviar; distinta del resultado `registration_submitted`/`registration_submit_failed`.
4. **`screen_view` consistente** confirmando que el `AnalyticsRouteObserver` cubre las transiciones (GA4) y **cableando** `SentryNavigatorObserver` en la lista `observers` de `app_router.dart` (la Fase 3 ya entregó `SentryFlutter.init`).
5. **Catálogo hardcoded de baja cardinalidad sin PII**: añadir a `analytics_events.dart` solo las 3 constantes nuevas (`eventsCreateAbandoned`, `eventsPublishAttempted`, `registrationSubmitAttempted`), respetando límite GA4 de 40 chars y la política no-PII ya documentada en esos archivos. Reusan `AnalyticsParams.formMode`; no se añaden params nuevos.
6. **Doc markdown del catálogo**: actualizar `docs/features/analytics.md` con la tabla completa de eventos vigentes (nombre, trigger real, params, no-PII) incluyendo los nuevos, según la regla de "actualizar docs de feature".

### Regla anti-doble-conteo (vinculante) — taps por Cubit vs. fallback en design system

- Cada CTA clave emite **exactamente UN evento de intención**. Si ya existe un evento de dominio equivalente (intención o resultado) que cubre ese tap, **NO se añade un segundo evento**; se reusa el existente. La taxonomía queda: intención (`*_attempted` / `*_selected`) en la **entrada del handler** vs. resultado (`*_succeeded`/`*_published`/`*_submitted`/`*_failed`) en la **completación**. Nunca dos eventos de intención por un mismo tap.
  - **Submit auth (email login/signup/forgot)** y **social (Google/Apple)**: ya emiten `authMethodSelected` como intención en sus call sites reales (`login_view.dart:79`, `signup_view.dart:71`, `forgot_password_view.dart:74`, `login_social_section.dart:40`, `signup_social_buttons.dart:24`). **Reuso total: cero código nuevo de auth en esta fase.**
  - **Apertura de wizard de registro**: ya cubierta por `registration_started` (`onWizardStarted`). No se añade tap de apertura. El **submit** sí gana intención propia (`registration_submit_attempted`) porque hoy no existe un evento de intención de envío, solo el resultado.
  - **Publicar evento**: `events_create_started` mide la **apertura del form**, no el tap de publicar; por eso el tap de publicar gana intención propia (`events_publish_attempted`), distinta del resultado.
- **Fallback en `AppButton`/`AppTextButton`** (param opcional): se usa **solo para CTAs que NO pasan por un Cubit** (navegación pura), donde no hay handler donde emitir. Ejemplos reales: `home_empty_events_card.dart:57` (`context.go(AppRoutes.events)`), `home_empty_garage_card.dart` (push a `createVehicle`), `create_event_fab.dart:19` (push a `createEvent`). Para estos, el param permite instrumentar el tap sin envolver el widget en un `GestureDetector` extra ni crear un helper que retorne widgets.

### No entra

- ~~Drop-off **por step** en creación de evento~~ → **AHORA ENTRA** (el wizard ya existe; ver alcance #1).
- Cableado efectivo de `SentryNavigatorObserver`: la Fase 3 ya entregó `SentryFlutter.init`, así que la subtarea diferible #1 **también entra ahora** (añadir el observer a `app_router.dart`).
- PostHog, dashboards, BigQuery export.
- Pantallas nuevas o cambios de copy en el tile de opt-out (se respeta tal cual: `AppSwitch`, knob/elementos oscuros sobre primario).
- Nuevos params PII o de alta cardinalidad (ids dinámicos, emails, placas, coordenadas).

## Que se debe hacer (pasos concretos y ordenados)

1. **Añadir las constantes al catálogo** en `analytics_events.dart`:
   - `eventsStepAdvanced = 'events_step_advanced'` (20 chars ✓), trigger = `EventFormCubit.nextStep()` con avance efectivo. Params: `step_index`, `step_name`.
   - `eventsStepBack = 'events_step_back'` (16 chars ✓), trigger = `EventFormCubit.prevStep()` con retroceso efectivo. Params: `step_index`, `step_name`.
   - `eventsCreateAbandoned = 'events_create_abandoned'` (24 chars ✓), trigger = `EventFormCubit.close()` sin publicación ni borrado, una sola vez por instancia (flag idempotente). Params: `form_mode` + `abandoned_at_step`.
   - `eventsPublishAttempted = 'events_publish_attempted'` (24 chars ✓), trigger = entrada a `saveEvent` antes del async. Param: `formMode`.
   - `registrationSubmitAttempted = 'registration_submit_attempted'` (29 chars ✓), trigger = entrada a `saveRegistration()` antes del async. Sin params PII.
   - En `analytics_params.dart`: reusar `stepIndex`/`stepName`/`formMode` ya existentes; añadir 1 param nuevo `abandonedAtStep = 'abandoned_at_step'` y 4 valores canónicos de `step_name` para el wizard de eventos: `stepNameBasics='basics'`, `stepNameConfig='config'`, `stepNameRoute='route'`, `stepNameReview='review'` (no reusar los del wizard de registro, que son personal/medical/emergency/vehicle).
2. **`EventFormCubit`** (`lib/features/events/presentation/form/cubit/event_form_cubit.dart`):
   - Añadir campo privado `bool _terminalEventEmitted = false;`.
   - `nextStep()` (~517): si el avance es efectivo (`next <= 3` y se emite), loguear `eventsStepAdvanced` con `step_index = next` y `step_name` mapeado. `prevStep()` (~522): análogo con `eventsStepBack` y `step_index = prev`. Helper privado `String _stepName(int)` → basics/config/route/review.
   - En `saveEvent(...)` (línea ~205, branch de publicación): emitir `eventsPublishAttempted` (con `formMode`) como primera línea, antes de `emit(... loading)`. En el branch de éxito (donde ya se emite `eventsPublished`, ~235) marcar `_terminalEventEmitted = true`.
   - En `saveDraft(...)` (~439): en el branch de éxito (donde se emite `eventsDraftSaved`, ~464) marcar `_terminalEventEmitted = true`.
   - Override `Future<void> close()`: si `!_terminalEventEmitted`, emitir `eventsCreateAbandoned` con `form_mode` + `abandoned_at_step = state.currentStep`; luego `return super.close();`. Mejor esfuerzo, sin await bloqueante (`.ignore()` como el resto del cubit).
3. **`RegistrationFormCubit`** (`lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`):
   - Añadir `bool _terminalEventEmitted = false;`.
   - En `saveRegistration()` (~226): emitir `registrationSubmitAttempted` como primera línea, antes del async. En el branch de éxito (donde ya se emite `registrationSubmitted`, ~254) marcar `_terminalEventEmitted = true`.
   - Override `close()`: si `!_terminalEventEmitted`, emitir `registrationAbandoned` (constante ya existente, hoy sin call site); luego `super.close()`. Mejor esfuerzo con `.ignore()`.
4. **Fallback de tap en design system** (fija el contrato del param; cableado mínimo en 1 CTA real):
   - En `AppButton` y `AppTextButton`, añadir dos params opcionales: `final String? analyticsTapEvent;` y `final Map<String, Object>? analyticsTapParams;`. El tipo **`Map<String, Object>?`** coincide con la firma real `AnalyticsService.logEvent(String name, [Map<String, Object>? parameters])` (no `Object?`).
   - El design system **no** se acopla a `getIt`: el `AnalyticsService` se resuelve **dentro del `onTap`** vía `getIt<AnalyticsService>()` solo cuando `analyticsTapEvent != null` (lectura puntual en el handler, nunca en el constructor ni en `build`), o —preferido— el llamador emite el evento en su propio `onPressed` y NO usa el param. Mitiga el acoplamiento del design system a DI (riesgo 5).
   - Si `analyticsTapEvent != null`, en el `InkWell.onTap` (`AppButton`) / `onPressed` (`AppTextButton`) emitir el evento antes de invocar `onPressed` original. Comportamiento idéntico al actual cuando el param es null (default).
   - Cablear el param en al menos un CTA de navegación pura real (`home_empty_events_card.dart:57`) como referencia ejecutable.
5. **`screen_view`**: verificar (test) que `AnalyticsRouteObserver` sigue emitiendo `screen_view` por transición con dedupe; y **añadir `SentryNavigatorObserver()`** a la lista `observers` de `app_router.dart:76` (junto a `analyticsObserver`). Ya no está diferido: la Fase 3 entregó `SentryFlutter.init`. En dev solo reporta bajo `kSentryDevVerify`; en prod siempre.
6. **Doc del catálogo**: actualizar `docs/features/analytics.md` con la tabla de los 3 eventos nuevos + la nota de la regla anti-doble-conteo (intención `*_attempted`/`*_selected` en entrada de handler vs. resultado en completion). No duplicar el catálogo en un archivo aparte.
7. **Regenerar DI y lint** si se tocó algún constructor inyectable (no debería: los 3 cubits ya reciben `AnalyticsService`). Correr `dart run build_runner build --delete-conflicting-outputs` solo si fue necesario, `dart analyze` y `dart format lib/`.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

- `lib/core/services/analytics/analytics_events.dart` — añade `eventsStepAdvanced`, `eventsStepBack`, `eventsCreateAbandoned`, `eventsPublishAttempted`, `registrationSubmitAttempted` con doc de trigger y no-PII.
- `lib/core/services/analytics/analytics_params.dart` — añade `abandonedAtStep = 'abandoned_at_step'` y los 4 valores canónicos de `step_name` para eventos (`basics`/`config`/`route`/`review`); reusa `stepIndex`/`stepName`/`formMode`.
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — flag idempotente, `events_step_advanced`/`events_step_back` en `nextStep`/`prevStep`, `events_publish_attempted` al entrar a `saveEvent`, `events_create_abandoned` (con `abandoned_at_step`) en `close()`.
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` — flag idempotente, `registration_submit_attempted` al entrar a `saveRegistration()`, cableado de `registration_abandoned` en `close()`.
- `lib/shared/widgets/form/app_button.dart` — param opcional `analyticsTapEvent: String?` + `analyticsTapParams: Map<String, Object>?`; emite tap en `onTap` solo si está presente; sin acoplar a `getIt` salvo lectura puntual en el handler.
- `lib/shared/widgets/form/app_text_button.dart` — mismo par de params opcionales y misma semántica que `AppButton`.
- `lib/features/home/presentation/widgets/home_empty_events_card.dart` — cablea el param de tap en el CTA de navegación pura (ejemplo real, no pasa por Cubit).
- `lib/shared/router/app_router.dart` — cablear `SentryNavigatorObserver()` en la lista `observers` (la Fase 3 ya entregó `SentryFlutter.init`).
- `docs/features/analytics.md` — tabla del catálogo actualizada con los 3 eventos nuevos y la regla intención-vs-resultado.

## Contratos / API rideglory-api (o "ninguno")

Ninguno. La fase es 100% Flutter (GA4). No toca `@rideglory/contracts`, message patterns, ni endpoints del gateway.

## Cambios de datos / migraciones (o "ninguno")

Ninguno. No hay esquema de datos ni migraciones; GA4 ingiere eventos hardcoded de baja cardinalidad.

## Criterios de aceptacion (numerados, observables, testeables)

1. **Intención de tap sin doble conteo (call sites concretos).** Existe un test de cubit que, al invocar `EventFormCubit.saveEvent(...)` con éxito, verifica que se emite `events_publish_attempted` (intención, una vez, al inicio) **y además** `events_published` (resultado), y que NO se emite un segundo evento de intención por el mismo tap. Análogamente, `RegistrationFormCubit.saveRegistration()` emite `registration_submit_attempted` + `registration_submitted`. Para los CTA de auth (submit email + social), un assert documental/comentario confirma que NO se añadieron eventos de tap nuevos: se reusa `authMethodSelected` en sus call sites existentes. El test de los dos cubits falla contra el código actual (que no emite `*_attempted`).
2. **Drop-off por step + abandono de creación de evento (wizard de 4 pasos).** Un test de cubit verifica: (a) `nextStep()`/`prevStep()` con avance/retroceso efectivo emiten `events_step_advanced`/`events_step_back` con `step_index` y `step_name` correctos (basics/config/route/review); (b) al hacer `close()` **sin** haber publicado ni guardado borrador, se emite exactamente una vez `events_create_abandoned` con `form_mode` **y `abandoned_at_step = state.currentStep`**; (c) tras un `saveEvent`/`saveDraft` exitoso seguido de `close()`, `events_create_abandoned` **NO** se emite (flag idempotente). El test falla contra el cubit actual, que no instrumenta steps ni `close()`.
3. **Abandono de registro cableado.** Un test verifica que `RegistrationFormCubit.close()` sin envío exitoso emite `registration_abandoned` exactamente una vez, y que tras `saveRegistration()` exitoso + `close()` no se emite. Falla contra el código actual (la constante existe pero no tiene call site).
4. **Catálogo de baja cardinalidad y sin PII.** Las 3 constantes nuevas tienen ≤40 chars (verificable por `.length`), no contienen ids/email/placa/VIN/coordenadas, y sus params son `form_mode` o ninguno. `docs/features/analytics.md` lista los 3 con su trigger real y su política no-PII. `dart analyze` limpio.
5. **`screen_view` consistente + `SentryNavigatorObserver` cableado.** Un test confirma que `AnalyticsRouteObserver` emite `screen_view` por transición con dedupe (sin regresión). El `SentryNavigatorObserver` **SÍ** aparece ahora en la lista `observers` activa de `app_router.dart` (la Fase 3 entregó `SentryFlutter.init`); criterio observable: `grep SentryNavigatorObserver app_router.dart` lo encuentra dentro de `observers`.
6. **Opt-out intacto.** El tile `profile_analytics_optout_tile.dart` sigue usando `AppSwitch` con knob/elementos oscuros sobre primario; sin cambios de copy ni de estilo. Sin Material `Switch`/`SwitchListTile`/`FormBuilderSwitch`.
7. **Sin GestureDetectors extra ni helpers que retornen widgets.** El diff no introduce `GestureDetector` nuevos alrededor de botones ni métodos `Widget _buildX()`; los taps se emiten en handlers de Cubit o vía el param opcional del design system.

## Pruebas (unitarias/widget/integracion)

- **Unitarias (cubit, las principales):**
  - `event_form_cubit_analytics_test.dart` (extender el existente): `events_step_advanced`/`events_step_back` con `step_index`+`step_name` correctos y solo cuando el cambio de step es efectivo (no en avance bloqueado por validación); `events_publish_attempted` al entrar a `saveEvent`; `events_create_abandoned` en `close()` con `abandoned_at_step` solo si no hubo terminal; idempotencia tras publish/draft.
  - `registration_form_cubit`: `registration_submit_attempted` al entrar a `saveRegistration()`; `registration_abandoned` en `close()` con idempotencia.
  - Usar un `AnalyticsService` fake/mock que registre los `logEvent(name, params)` invocados (patrón ya presente en los tests de analytics existentes).
- **Widget (acotada):**
  - `app_button` / `app_text_button`: con `analyticsTapEvent` presente, el tap emite el evento antes de `onPressed`; con el param null (default), comportamiento idéntico al actual (no regresión, no resuelve `getIt` en `build`).
- **Observer:** test de `AnalyticsRouteObserver` (si no existe) o assert de no-regresión del dedupe de `screen_view`.
- **Integración:** no se requiere; la fase es incremental sin flujos nuevos end-to-end.
- **Comandos:** `flutter test`, `dart analyze`, `dart format --output=none lib/`.

## Riesgos y mitigaciones

| # | Riesgo | Mitigación |
|---|--------|------------|
| 1 | **Doble conteo** intención vs. resultado (taps que duplican `registrationSubmitted`/`eventsPublished`). | Regla vinculante: un solo evento de intención por CTA; reuso de `authMethodSelected`; nombres `*_attempted` claramente distintos del resultado; criterio 1 con test que verifica exactamente un intent + un result. |
| 2 | **Doble conteo de step events** (emitir `events_step_advanced` cuando el avance NO fue efectivo por validación fallida). | Emitir el evento SOLO dentro del branch que realmente cambia `currentStep` (en `nextStep`, dentro del `if (next <= 3)`; análogo en `prevStep`). Test que verifica que un `nextStep` bloqueado no emite. |
| 3 | **Abandono emitido de más** (close en hot-reload, re-creación de cubit, doble close). | Flag idempotente `_terminalEventEmitted`; emisión solo en `close()` y solo si no hubo terminal; tests de idempotencia. Mejor esfuerzo (`.ignore()`), sin bloquear el dispose. |
| 4 | **`SentryNavigatorObserver` reportando en dev** fuera de la ventana de verificación. | La Fase 3 ya entregó `SentryFlutter.init` con gating: en dev solo reporta bajo `kSentryDevVerify`; en prod siempre. Cablearlo es seguro; criterio 5 verifica que está en `observers`. |
| 5 | **Acoplar el design system a `getIt`** con el param de tap. | El `AnalyticsService` se lee puntualmente dentro del `onTap` (no en el constructor ni en `build`), o el llamador emite el evento en su propio `onPressed`; el param es opcional y null por defecto, tipado `Map<String, Object>?`. |
| 6 | **PII / alta cardinalidad** colándose en params nuevos. | Solo `form_mode` o sin params; revisión contra la denylist (email, placa, VIN, coords, ids dinámicos); doc no-PII en `analytics.md` y en los doc-comments de las constantes. |
| 7 | **Regresión de `screen_view`** al tocar el router. | No se toca la lógica del observer; solo se añade un comentario TODO; test de no-regresión del dedupe. |

## Dependencias (fases prerequisito y por que)

- **Prerequisito duro:** ninguno para el grueso de la fase. La parte GA4 (taps de intención, `events_create_abandoned`, `registration_abandoned`, verificación de `screen_view` vía `AnalyticsRouteObserver` ya existente, catálogo y doc) es paralelizable y **no requiere Sentry**.
- **Subtarea #1 — `SentryNavigatorObserver` (YA DESBLOQUEADA):** la **Fase 3** ya entregó `SentryFlutter.init`, así que se cablea en esta fase. Ya no es diferible.
- **Subtarea #2 — drop-off por step en creación de evento (YA DESBLOQUEADA):** el wizard de 4 pasos (`event-form-stepper`) ya está implementado y commiteado, así que se instrumenta `events_step_advanced`/`events_step_back` + `abandoned_at_step`. Ya no es diferible.

## Ejecucion recomendada (nivel rg-exec: lite)

Por qué ese nivel: expansión incremental sobre base existente — agregar call sites de taps de intención, ~5 constantes de baja cardinalidad, step events + drop-off (abandono con `abandoned_at_step`) en el wizard, cableo de `SentryNavigatorObserver` y un doc markdown. Una sola área (analytics Flutter), sin contratos, sin migraciones, reversible, sin PII nueva, reusa el tile opt-out existente. Las dos subtareas antes diferidas ya están desbloqueadas (Fase 3 entregó `SentryFlutter.init`; el wizard de 4 pasos ya está commiteado), así que entran ambas en esta corrida.
