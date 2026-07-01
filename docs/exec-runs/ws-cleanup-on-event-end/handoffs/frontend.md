# Frontend Handoff — ws-cleanup-on-event-end

**Timestamp:** 2026-06-20T01:58:57Z  
**Agent:** Frontend (Flutter lib/)

---

## Baseline

`flutter test test/features/events/presentation/tracking/` → **5 passed** (existing analytics tests).

---

## Archivos cambiados

### Modificado

**`lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart`**

`_subscribeToEventEnded()` refactorizado de síncrono a `async` con los 4 pasos en orden exacto:

1. Analytics — `_logSessionEnded(trackingEndReasonEventEnded)` solo si `state.isTracking`.
2. Cancelar GPS — `await _positionSubscription?.cancel(); _positionSubscription = null`.
3. Stop use case — `await _stopTrackingUseCase(...)` con result desempaquetado via `fold` (ignorando ambas ramas; el error no debe interrumpir el flujo de cleanup).
4. Emit final — `emit(state.copyWith(isTracking: false, isFinished: true))` protegido por `if (!isClosed)`.

Se agregaron 2 seams `@visibleForTesting`:
- `debugPrimeForEventEndedTest(userId)`: fija `_userId`, emite `isTracking=true`, llama `_subscribeToEventEnded()`.
- `debugSubscribeEventEndedForTest()`: activa el listener sin sesión activa (para Caso C).

**Nota de corrección:** el handoff del architect indicaba `await useCase(...).fold(...)` directamente, pero `fold` es método de `Either`, no de `Future<Either>`. Se corrigió a `final result = await useCase(...); result.fold(...)`.

### Creado

**`test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart`**

4 casos nuevos bajo el grupo `LiveTrackingCubit — eventEnded cleanup`:

| Caso | Descripción | Verificaciones |
|------|-------------|----------------|
| A | Path principal — rider activo recibe eventEnded | stopUseCase llamado 1×, logEvent trackingSessionEnded 1×, isTracking=false, isFinished=true |
| B | Doble disparo — segundo evento llega con isTracking=false | stopUseCase llamado 1× (no 2), logEvent 1× (no 2) |
| C | Sin sesión activa | verifyNever stopUseCase, verifyNever logEvent, isFinished=true |
| D | Use case retorna Left | Cubit no lanza, stopUseCase llamado 1×, isTracking=false, isFinished=true |

---

## Pruebas nuevas

```
test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart
  LiveTrackingCubit — eventEnded cleanup
    Caso A — path principal ...                [PASS]
    Caso B — doble disparo ...                 [PASS]
    Caso C — sin sesión activa ...             [PASS]
    Caso D — use case retorna Left ...         [PASS]
```

---

## Resultado final

```
flutter test test/features/events/presentation/tracking/
→ 9 passed (4 nuevos + 5 existentes)

dart analyze lib/.../live_tracking_cubit.dart test/.../live_tracking_cubit_event_ended_test.dart
→ No issues found!
```

---

## Verificación manual

Para verificar en la app:
1. Organizador inicia un evento con riders conectados al tracking en vivo.
2. Organizador pulsa "Terminar rodada" (`endRide`).
3. Cada rider conectado debe ver la pantalla hacer pop/mostrar estado "finalizado" (`isFinished=true`).
4. El GPS de cada rider debe cancelarse (no continuar en background).
5. El WebSocket debe cerrarse correctamente vía `stopTrackingUseCase`.

---

## Notas para QA

- **Caso de doble-fire:** El stream `eventEnded` es broadcast; si por alguna razón el backend emite dos veces, el segundo disparo no debe duplicar el llamado a stopUseCase ni el evento de analytics. El flag `state.isTracking` actúa como guard natural.
- **Caso de rider sin tracking activo** (solo espectador): `isFinished` se emite igualmente para que la UI pueda responder, pero no se llama stopUseCase ni se registra el evento de analytics de fin de sesión.
- **Error en stopUseCase** (Caso D): el cleanup continúa y `isFinished=true` se emite de todas formas. El error queda silenciado en el cubit pero debería llegar al servidor de observabilidad (Sentry) si el use case lo propaga.
- **Guard `isClosed`**: si el cubit ya fue cerrado (`close()`) antes de que el async listener complete, el `emit` final es skipped correctamente.
