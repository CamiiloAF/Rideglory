> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend

**Feature path:** `lib/features/events/presentation/tracking/cubit/`
**Test path:** `test/features/events/presentation/tracking/`

---

## Archivo a modificar

`lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart`

### Cambio en `_subscribeToEventEnded()`

Convertir el listener a `async`. Implementar los 4 pasos en orden exacto:

```dart
void _subscribeToEventEnded() {
  _eventEndedSubscription?.cancel();
  _eventEndedSubscription = _trackingRepository.eventEnded.listen((_) async {
    if (isClosed) return;
    // 1. Analytics — solo si había sesión activa
    if (state.isTracking) {
      _logSessionEnded(AnalyticsParams.trackingEndReasonEventEnded);
    }
    // 2. Cancelar GPS
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    // 3. Stop use case (cierra WS via leaveSession internamente) — solo si había sesión
    final uid = _userId;
    if (state.isTracking && uid != null) {
      await _stopTrackingUseCase(eventId: _eventId, userId: uid).fold(
        (_) {},
        (_) {},
      );
    }
    // 4. Emit final con guard isClosed
    if (!isClosed) {
      emit(state.copyWith(isTracking: false, isFinished: true));
    }
  });
}
```

### Seams `@visibleForTesting` a agregar

```dart
/// Deja el cubit con sesión de rider activa para tests de eventEnded.
/// Fija [userId] como rider activo, emite isTracking=true, y activa el listener.
@visibleForTesting
void debugPrimeForEventEndedTest(String userId) {
  _userId = userId;
  emit(state.copyWith(isTracking: true));
  _subscribeToEventEnded();
}

/// Activa solo el listener de eventEnded sin sesión activa (estado inicial).
/// Usado para Caso C: rider que recibe el broadcast sin estar en tracking.
@visibleForTesting
void debugSubscribeEventEndedForTest() {
  _subscribeToEventEnded();
}
```

---

## Archivo a crear

`test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart`

### Estructura requerida (4 casos exactos)

- **Caso A — path principal:** `debugPrimeForEventEndedTest(userId)` → agrega `eventEnded` al stream → `verify` stopUseCase llamado 1 vez, `verify` logEvent trackingSessionEnded 1 vez, estado `isTracking: false, isFinished: true`
- **Caso B — doble disparo:** primer evento activa cleanup normal; segundo evento llega con `isTracking == false` → `verify` stopUseCase llamado 1 vez (no 2), logEvent trackingSessionEnded 1 vez (no 2)
- **Caso C — sin sesión:** `debugSubscribeEventEndedForTest()` (sin prime) → agrega `eventEnded` → `verifyNever` stopUseCase, `verifyNever` logEvent trackingSessionEnded, estado `isFinished: true`
- **Caso D — use case Left:** `debugPrimeForEventEndedTest` + stub `stopTrackingUseCase` retorna `Left(DomainException(...))` → cubit no lanza, estado `isTracking: false, isFinished: true`, stopUseCase llamado 1 vez

### Imports y mocks necesarios

Reutilizar los mismos mocks de `live_tracking_cubit_analytics_test.dart`. Agregar `StreamController<void>` para `eventEnded`. Stub en setUp:
```dart
when(() => repo.eventEnded).thenAnswer((_) => eventEndedController.stream);
```

Para Caso D, stub del use case:
```dart
when(() => stopTrackingUseCase(eventId: any(named: 'eventId'), userId: any(named: 'userId')))
    .thenAnswer((_) async => Left(const DomainException(message: 'err')));
```

---

## Restricciones críticas

- NO modificar `live_tracking_cubit_analytics_test.dart`
- NO modificar `close()` ni `_handleAuthSignedOut()`
- NO tocar `TrackingRepository` ni `tracking_repository_impl.dart`
- `Nothing` viene de `package:rideglory/core/domain/nothing.dart` (no de dartz)
- Guards `isClosed` son obligatorios antes del emit final
- No hay nuevas dependencias en `pubspec.yaml`

> Full detail: handoffs/architect.md
