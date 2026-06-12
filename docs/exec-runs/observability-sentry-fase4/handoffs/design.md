# Design handoff — observability-sentry Fase 4

**Date:** 2026-06-12T16:06:48Z
**Status:** done

---

## Design system baseline

| Token | Valor |
|-------|-------|
| Primary | `#f98c1f` |
| Dark bg | `#0A0A0A` |
| Surface | `#161616` |
| Surface-2 | `#1F1F1F` |
| Border | `#2D2D2D` |
| Font | Space Grotesk |
| Border radius | 8px (botones/inputs) · 12px (cards) · 16px (cards grandes) |

**Cambios este sprint:** Ninguno — esta fase no modifica tokens ni introduce variantes visuales.

---

## Pantallas

Esta fase es de **instrumentación pura**: no hay pantallas nuevas, no hay cambios de layout, ni alteraciones de copy visible al usuario. Todo el trabajo ocurre en capas invisibles (cubits, observers de navegación, params opcionales en el design system).

| Pantalla | Historia | Tipo | Mockup | Estado |
|----------|----------|------|--------|--------|
| `HomeEmptyEventsCard` | CA7 — reference wire-up de `analyticsTapEvent` en AppButton | UPDATE | Sin mockup (sin cambio visual) | done |
| `EventFormCubit` flows | CA1, CA2 — step tracking + publish intent + abandono | UPDATE (cubit, no UI) | Sin mockup (sin cambio visual) | done |
| `RegistrationFormCubit` flows | CA1b, CA3 — submit intent + abandono | UPDATE (cubit, no UI) | Sin mockup (sin cambio visual) | done |

No se generan mockups HTML porque ninguna pantalla cambia visualmente. El design system absorbe los nuevos params sin afectar la apariencia.

---

## Flujos UX

### Flujo 1 — Wizard de creación de evento (instrumentado, no cambia visually)

```
[Paso 0: basics] →(nextStep OK)→ [Paso 1: config] →(nextStep OK)→ [Paso 2: route] →(nextStep OK)→ [Paso 3: review]
      ↑                                                                                                      ↓
  (prevStep)                                                                              [Publicar] → events_publish_attempted
      ↓                                                                                                      ↓
  (pop/close sin publicar)                                                               events_published / events_publish_failed
      ↓
  events_create_abandoned (idempotente — solo si no se publicó/guardó borrador)
```

Eventos emitidos (invisibles para el rider):
- `events_step_advanced` con `{step_index, step_name}` en cada avance efectivo.
- `events_step_back` con `{step_index, step_name}` en cada retroceso efectivo.
- `events_publish_attempted` al entrar a `saveEvent()`, antes del trabajo async.
- `events_create_abandoned` en `close()` si `_terminalEventEmitted == false`.

### Flujo 2 — Wizard de registro (instrumentado, no cambia visually)

```
[Registro form] → [Enviar]
                      ↓
             registration_submit_attempted (intención)
                      ↓
             registration_submitted / registration_submit_failed (resultado)

[pop/close sin enviar] → registration_abandoned (idempotente)
```

### Flujo 3 — HomeEmptyEventsCard (reference tap)

El `AppButton` existente recibe el nuevo param `analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta`. El comportamiento visible es idéntico: el rider ve el mismo card y CTA. El tap dispara la navegación normal + un evento de analytics en background. Sin cambio visual.

### Flujo 4 — Navegación con SentryNavigatorObserver

`AppRouter` ahora registra transiciones de pantalla en Sentry (condicionado: dev solo con `kSentryDevVerify`, prod siempre). El rider no percibe diferencia.

---

## Componentes

| Pantalla / Cubit | Componentes usados | Componentes nuevos |
|-----------------|--------------------|--------------------|
| `AppButton` (design system) | — | Params opcionales `analyticsTapEvent: String?` + `analyticsTapParams: Map<String, Object>?` (null por defecto, sin breaking change) |
| `AppTextButton` (design system) | — | Mismos params opcionales que `AppButton` |
| `HomeEmptyEventsCard` | `AppButton` (existente) | Ninguno — solo se pasa el nuevo param al botón existente |
| `EventFormCubit` | `AnalyticsService` (ya inyectado) | `_terminalEventEmitted: bool` (campo privado, no es widget) |
| `RegistrationFormCubit` | `AnalyticsService` (ya inyectado) | `_terminalEventEmitted: bool` (campo privado, no es widget) |
| `AppRouter` | `SentryNavigatorObserver` (existente en Sentry SDK) | Ninguno — solo se agrega a la lista `observers` |

**Regla crítica:** Los params de analytics en `AppButton`/`AppTextButton` se resuelven via `getIt<AnalyticsService>()` en el `onTap` handler — nunca en `build()`. Esto evita dependencia de `BuildContext` en el design system y mantiene el widget stateless.

---

## Copy

Esta fase no introduce copy nuevo visible para el rider. Toda la instrumentación es silenciosa.

**Constantes de catálogo (no UI, solo código):**

| Constante | Valor string | Longitud | Contexto |
|-----------|-------------|----------|---------|
| `eventsPublishAttempted` | `'events_publish_attempted'` | 25 | Intención de publicar evento |
| `eventsStepAdvanced` | `'events_step_advanced'` | 21 | Avance de paso en wizard |
| `eventsStepBack` | `'events_step_back'` | 17 | Retroceso de paso en wizard |
| `eventsCreateAbandoned` | `'events_create_abandoned'` | 24 | Abandono de creación |
| `registrationSubmitAttempted` | `'registration_submit_attempted'` | 30 | Intención de enviar registro |
| `homeEmptyEventsCta` | `'home_empty_events_cta'` | 22 | Tap en CTA de estado vacío de home |

Todos ≤ 40 chars (requerimiento de catálogo). Ninguno contiene PII.

**Params canónicos de step_name:**

| Constante | Valor | Paso del wizard |
|-----------|-------|-----------------|
| `stepNameBasics` | `'basics'` | Paso 0 — datos básicos |
| `stepNameConfig` | `'config'` | Paso 1 — configuración |
| `stepNameRoute` | `'route'` | Paso 2 — ruta |
| `stepNameReview` | `'review'` | Paso 3 — revisión y publicación |

---

## Accesibilidad

Sin cambios en la superficie de accesibilidad:

- `AppButton` y `AppTextButton` no alteran sus `Semantics`, labels ni touch targets (mínimo 44×44px garantizado por la implementación existente).
- Los params de analytics son transparentes para lectores de pantalla — no producen texto ni interacciones semánticas adicionales.
- El `SentryNavigatorObserver` no emite eventos de accesibilidad.
- Contraste de colores: sin cambios — el design system base no se modifica.
- Texto oscuro sobre primario (`AppColors.darkBgPrimary`): sin variantes nuevas de botón afectadas por esta fase.

---

## Notas para Frontend

1. **No hay cambios de UI que requieran revisión visual.** Todo el diff es instrumentación interna; el QA visual puede ser un smoke test de regresión (pantallas se ven igual).

2. **Params opcionales en AppButton / AppTextButton:** Añadir los dos params al constructor con valor `null` por defecto. En el `onTap` handler, antes de llamar al `onPressed` del caller, hacer:
   ```dart
   if (analyticsTapEvent != null) {
     getIt<AnalyticsService>().logEvent(
       analyticsTapEvent!,
       params: analyticsTapParams,
     );
   }
   onPressed?.call();
   ```
   El `AnalyticsService` es singleton registrado al inicio; `getIt` es seguro en el handler. **No usar `BuildContext`.**

3. **Flag `_terminalEventEmitted` en cubits:** Inicializar en `false`. Activarlo a `true` en la rama exitosa de `saveEvent()`/`saveDraft()` (EventFormCubit) y `saveRegistration()` (RegistrationFormCubit). En `close()`, emitir el evento de abandono solo si el flag es `false`. Esto es thread-safe porque los cubits son single-threaded por diseño de BLoC.

4. **Step tracking — guarda de validación:** `events_step_advanced` se emite en `nextStep()` **solo después de verificar que la validación pasa** y que el índice efectivamente cambia (`currentStep < 3`). Si la validación bloquea, no emitir nada. El cubit ya tiene la lógica de validación; el evento va en la rama de éxito.

5. **Orden de llamadas en `saveEvent()`:**
   ```
   emit(publish_attempted)  ← intención, antes del async
   await useCase.save(...)
   emit(published)          ← resultado
   _terminalEventEmitted = true
   ```
   El evento de intención va **antes** de cualquier await. El resultado va después.

6. **`SentryNavigatorObserver` en `app_router.dart`:** Añadir a la lista `observers` con el mismo gating que `main.dart`:
   ```dart
   observers: [
     analyticsObserver,
     if (kReleaseMode || kSentryDevVerify) SentryNavigatorObserver(),
   ],
   ```
   Verificar que `kSentryDevVerify` ya está importado/definido en el alcance del router (viene de Fase 3).

7. **HomeEmptyEventsCard:** Cambio mínimo — un param adicional en el `AppButton` existente:
   ```dart
   AppButton(
     label: context.l10n.home_emptyEventsCta,
     onPressed: () => context.go(AppRoutes.events),
     analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta,
   ),
   ```
   Sin cambio visual ni de layout.

8. **Tests:** Usar un `FakeAnalyticsService` (implementa `AnalyticsService`) que registre llamadas en una lista. Registrarlo en `getIt` en `setUp` y limpiar en `tearDown` con `getIt.reset()` o `getIt.unregister`. Esto aplica tanto para tests de cubit como para el widget test de `AppButton`.

9. **`dart analyze` limpio:** Los 2 lints de `api_base_url_resolver.dart` son intencionados y no se tocan.

---

## Artefactos de diseño

- Mockups HTML: **ninguno** (esta fase no produce cambios visuales).
- Directorio de análisis: `docs/exec-runs/observability-sentry-fase4/analysis/design/` (vacío — sin artefactos gráficos requeridos).
- Fuente de verdad visual: `rideglory.pen` — sin modificaciones en esta fase.

---

## Change log

- 2026-06-12T16:06:48Z: Handoff inicial — fase de instrumentación pura, sin cambios visuales.
