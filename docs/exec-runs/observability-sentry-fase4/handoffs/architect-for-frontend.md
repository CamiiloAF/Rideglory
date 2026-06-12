> Slim handoff — read this before handoffs/architect.md

# Frontend handoff — observability-sentry Fase 4

**Fecha:** 2026-06-12T16:00:09Z

---

## Resumen de cambios Flutter

Esta fase es 100% client-side. Cero cambios en backend, DTOs ni migraciones.

---

## 1. Catálogo — nuevas constantes

### `analytics_events.dart` — añadir en la sección "Events — escritura (Fase 7)":

```dart
/// Intención de tap en publicar evento (antes del trabajo async).
/// Max 40 chars: 'events_publish_attempted'.length == 24. ✓
static const String eventsPublishAttempted = 'events_publish_attempted';

/// El rider avanzó al siguiente paso del wizard de creación.
/// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
/// Max 40 chars: 'events_step_advanced'.length == 20. ✓
static const String eventsStepAdvanced = 'events_step_advanced';

/// El rider retrocedió al paso anterior del wizard de creación.
/// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
/// Max 40 chars: 'events_step_back'.length == 16. ✓
static const String eventsStepBack = 'events_step_back';

/// El rider cerró el wizard sin publicar ni guardar borrador.
/// Params: [AnalyticsParams.formMode], [AnalyticsParams.abandonedAtStep].
/// Max 40 chars: 'events_create_abandoned'.length == 23. ✓
static const String eventsCreateAbandoned = 'events_create_abandoned';
```

### Añadir en la sección "Event registration — wizard":

```dart
/// Intención de tap en enviar inscripción (antes del trabajo async).
/// Max 40 chars: 'registration_submit_attempted'.length == 29. ✓
static const String registrationSubmitAttempted = 'registration_submit_attempted';
```

### Añadir sección nueva "Home — CTAs de navegación":

```dart
/// Tap en CTA "Ver eventos" en la tarjeta de home vacía (navegación pura).
/// Max 40 chars: 'home_empty_events_cta'.length == 21. ✓
static const String homeEmptyEventsCta = 'home_empty_events_cta';
```

---

## 2. Catálogo — nuevo parámetro y valores canónicos

### `analytics_params.dart` — añadir junto a los params de wizard:

```dart
/// Índice del paso en que se abandonó el wizard (0-based).
/// Tipo: `int`. Max key 40 chars: 17. ✓
static const String abandonedAtStep = 'abandoned_at_step';
```

### Añadir valores canónicos de `step_name` para el wizard de EVENTO (no registro):

```dart
// Valores canónicos de step_name (wizard de creación de evento)
static const String stepNameBasics  = 'basics';
static const String stepNameConfig  = 'config';
static const String stepNameRoute   = 'route';
static const String stepNameReview  = 'review';
```

Mapeo `currentStep → step_name`:
```
0 → basics
1 → config
2 → route
3 → review
```

---

## 3. EventFormCubit — cambios

Archivo: `lib/features/events/presentation/form/cubit/event_form_cubit.dart`

### 3.1 Agregar campo privado y helper de nombre de paso

```dart
bool _terminalEventEmitted = false;

static String _stepName(int index) => const ['basics', 'config', 'route', 'review'][index.clamp(0, 3)];
// O usar AnalyticsParams.stepNameBasics etc. directamente con switch.
```

### 3.2 `nextStep()` — emitir solo cuando el avance es efectivo

```dart
void nextStep() {
  final next = state.currentStep + 1;
  if (next > 3) return;
  _analytics.logEvent(AnalyticsEvents.eventsStepAdvanced, {
    AnalyticsParams.stepIndex: next,
    AnalyticsParams.stepName: _stepName(next),
  }).ignore();
  emit(state.copyWith(currentStep: next));
}
```

### 3.3 `prevStep()` — emitir solo cuando el retroceso es efectivo

```dart
void prevStep() {
  final prev = state.currentStep - 1;
  if (prev < 0) return;
  _analytics.logEvent(AnalyticsEvents.eventsStepBack, {
    AnalyticsParams.stepIndex: prev,
    AnalyticsParams.stepName: _stepName(prev),
  }).ignore();
  emit(state.copyWith(currentStep: prev));
}
```

### 3.4 `saveEvent()` — intención de tap al inicio

```dart
Future<void> saveEvent(EventModel eventToSave, { ... }) async {
  _analytics.logEvent(AnalyticsEvents.eventsPublishAttempted, {
    AnalyticsParams.formMode: isEditing
        ? AnalyticsParams.formModeEdit
        : AnalyticsParams.formModeCreate,
  }).ignore();
  emit(state.copyWith(saveResult: const ResultState.loading()));
  // ... resto igual, pero activar el flag en el fold exitoso:
  result.fold(
    (error) { /* igual */ },
    (event) {
      _terminalEventEmitted = true;  // <-- nuevo
      _analytics.logEvent(AnalyticsEvents.eventsPublished, { ... }).ignore();
      emit(state.copyWith(saveResult: ResultState.data(data: event)));
    },
  );
}
```

### 3.5 `saveDraft()` — activar flag en éxito

```dart
result.fold(
  (error) => ...,
  (event) {
    _terminalEventEmitted = true;  // <-- nuevo
    _analytics.logEvent(AnalyticsEvents.eventsDraftSaved, { ... }).ignore();
    emit(state.copyWith(saveResult: ResultState.data(data: event)));
  },
);
```

### 3.6 Sobrescribir `close()` para abandono

```dart
@override
Future<void> close() {
  if (!_terminalEventEmitted) {
    _analytics.logEvent(AnalyticsEvents.eventsCreateAbandoned, {
      AnalyticsParams.formMode: isEditing
          ? AnalyticsParams.formModeEdit
          : AnalyticsParams.formModeCreate,
      AnalyticsParams.abandonedAtStep: state.currentStep,
    }).ignore();
  }
  return super.close();
}
```

---

## 4. RegistrationFormCubit — cambios

Archivo: `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`

### 4.1 Flag y `saveRegistration()` — intención

```dart
bool _terminalEventEmitted = false;

Future<void> saveRegistration() async {
  _analytics.logEvent(AnalyticsEvents.registrationSubmitAttempted, {
    AnalyticsParams.formMode: isEditing
        ? AnalyticsParams.formModeEdit
        : AnalyticsParams.formModeCreate,
  }).ignore();
  // ... resto igual, activar flag en éxito:
  result.fold(
    (error) { /* igual */ },
    (saved) async {
      _terminalEventEmitted = true;  // <-- nuevo
      _analytics.logEvent(AnalyticsEvents.registrationSubmitted, { ... }).ignore();
      ...
    },
  );
}
```

### 4.2 `close()` para abandono

```dart
@override
Future<void> close() {
  if (!_terminalEventEmitted) {
    _analytics.logEvent(AnalyticsEvents.registrationAbandoned).ignore();
  }
  return super.close();
}
```

---

## 5. AppButton — params opcionales de analytics

Archivo: `lib/shared/widgets/form/app_button.dart`

Agregar al constructor (null por defecto — no rompe call sites existentes):

```dart
final String? analyticsTapEvent;
final Map<String, Object>? analyticsTapParams;
```

En el `InkWell.onTap`, envolver el `onPressed` existente:

```dart
onTap: onPressed == null || isLoading
    ? null
    : () {
        final tapEvent = analyticsTapEvent;
        if (tapEvent != null) {
          getIt<AnalyticsService>()
              .logEvent(tapEvent, analyticsTapParams)
              .ignore();
        }
        onPressed!();
      },
```

Import necesario: `package:rideglory/core/di/injection.dart`.

Aplicar el mismo patrón a `AppTextButton` en `lib/shared/widgets/form/app_text_button.dart`.

---

## 6. HomeEmptyEventsCard — reference wire-up

Archivo: `lib/features/home/presentation/widgets/home_empty_events_card.dart`

```dart
AppButton(
  label: context.l10n.home_emptyEventsCta,
  onPressed: () => context.go(AppRoutes.events),
  analyticsTapEvent: AnalyticsEvents.homeEmptyEventsCta,  // <-- nuevo
),
```

---

## 7. AppRouter — SentryNavigatorObserver

Archivo: `lib/shared/router/app_router.dart`

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
// ... imports existentes ...
import 'package:rideglory/main.dart' show kSentryDevVerify;
// (o mover kSentryDevVerify a un archivo de config accesible)

observers: <NavigatorObserver>[
  analyticsObserver,
  if (kReleaseMode || kSentryDevVerify)
    SentryNavigatorObserver(),
],
```

**Nota:** Si `kSentryDevVerify` no puede importarse desde `main.dart` sin ciclo, moverlo a `lib/core/config/sentry_config.dart` o simplemente declararlo `const` también en app_router (aceptable). La decisión la toma el implementador; lo importante es que el gating sea idéntico al de `beforeSend` en `main.dart`.

---

## 8. Localización

Sin cambios. Los nuevos eventos son constantes de analytics, no strings visibles al usuario.

---

## Reglas que aplican

- Un widget por archivo — ningún método `Widget _buildX()`.
- `analyticsTapEvent` se resuelve puntualmente en el handler, nunca en `build`.
- No emitir en tests con `AnalyticsService` real; usar mock/fake.
- `dart analyze` limpio; los 2 lints de `api_base_url_resolver.dart` son intencionados.

> Full detail: handoffs/architect.md
