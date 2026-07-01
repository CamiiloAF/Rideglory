# PRD Normalizado — WS Cleanup on Event End (Flutter)

**Slug:** ws-cleanup-on-event-end
**Fuente:** docs/plans/event-tracking-fixes/phases/phase-01-ws-cleanup-on-event-end-flutter.md
**Generado:** 2026-06-20T01:52:03Z

---

## 1 Objetivo

Cuando el backend emite el evento WebSocket `tracking.event.ended`, `LiveTrackingCubit._subscribeToEventEnded()` debe ejecutar el cleanup completo de recursos en el orden correcto: (1) registrar analytics, (2) cancelar la suscripción GPS, (3) invocar `_stopTrackingUseCase` (que internamente cierra el WS via `leaveSession` antes de la llamada HTTP), y (4) emitir el estado final de UI (`isTracking: false, isFinished: true`).

Actualmente el cubit solo llama `_logSessionEnded` y emite `isFinished: true`, dejando el stream de GPS activo y el WS sin cerrar, lo que provoca pings de ubicación al backend para un evento ya en estado FINISHED.

---

## 2 Por que

- Los riders que reciben el broadcast `tracking.event.ended` continúan enviando actualizaciones de ubicación GPS al backend porque `_positionSubscription` nunca se cancela.
- El WebSocket tampoco se cierra (`leaveSession` no se invoca), manteniendo conexiones activas innecesarias.
- La Fase 3 del plan (`event-tracking-fixes`) implementa un cron de auto-cierre de eventos tras 24 horas; sin este fix, ese cron genera un estado corrupto donde riders siguen pingueando eventos FINISHED.
- El orden incorrecto es una regresión silenciosa: el efecto (pings a evento FINISHED) ocurre en el backend sin señal visible en UI, difícil de detectar en QA manual.

---

## 3 Alcance

### Entra

- Modificar `LiveTrackingCubit._subscribeToEventEnded()` en `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart`: el listener pasa a `async`; implementa los 4 pasos de cleanup en orden exacto (analytics → cancel GPS → stop use case con fold → emit final con guard `isClosed`).
- Agregar seam `@visibleForTesting void debugPrimeForEventEndedTest(String userId)` al cubit (para Casos A, B y D: rider activo).
- Agregar seam `@visibleForTesting void debugSubscribeEventEndedForTest()` al cubit (para Caso C: rider inactivo, solo activa el listener).
- Crear archivo de test `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` con exactamente 4 casos de test.

### No entra

- No se agrega `leaveSession` como método abstracto a `TrackingRepository` (la interfaz de dominio): `TrackingRepositoryImpl.stopTracking` ya llama `leaveSession` internamente antes de `stopSession`.
- No se modifican otros métodos del cubit (`close`, `_handleAuthSignedOut`, `stopTracking`, etc.).
- No se modifican archivos de backend (`rideglory-api`).
- No se tocan otros cubits ni pantallas.
- No se modifica el test existente `live_tracking_cubit_analytics_test.dart`.

---

## 4 Areas afectadas

| Capa | Archivo | Cambio |
|------|---------|--------|
| Presentation / Cubit | `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | Refactor de `_subscribeToEventEnded()` + 2 seams `@visibleForTesting` |
| Test | `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` | Archivo nuevo con 4 casos |

Archivos en solo-lectura (referencia):
- `lib/features/events/data/tracking/tracking_repository_impl.dart` (confirmar orden líneas 100-101: `leaveSession` antes de `stopSession`)

---

## 5 Criterios de aceptacion

1. `dart analyze` sobre el proyecto completo no reporta nuevas violaciones introducidas por esta fase.
2. `flutter test` (suite completa) pasa en verde, incluyendo `live_tracking_cubit_analytics_test.dart` sin modificaciones.
3. El nuevo test `live_tracking_cubit_event_ended_test.dart` existe y tiene exactamente 4 casos de test que pasan.
4. **Caso A (path principal):** `_stopTrackingUseCase` es verificado como invocado exactamente 1 vez; `analyticsService.logEvent` con `AnalyticsEvents.trackingSessionEnded` es verificado como invocado exactamente 1 vez; estado final `isTracking: false` e `isFinished: true`.
5. **Caso B (doble-disparo):** `analyticsService.logEvent` con `trackingSessionEnded` es verificado como invocado exactamente 1 vez (no 2) gracias al flag `_sessionEndLogged`; `_stopTrackingUseCase` es verificado como invocado exactamente 1 vez (no 2) porque el segundo disparo llega con `state.isTracking == false`.
6. **Caso C (sin sesión activa):** `verifyNever` pasa para `stopTrackingUseCase` y para `analytics.logEvent` con `trackingSessionEnded`; el estado emitido tiene `isFinished: true`.
7. **Caso D (use case retorna `Left`):** el cubit no lanza excepción (el fold absorbe el Left); estado final `isTracking: false` e `isFinished: true`; `_stopTrackingUseCase` verificado como invocado exactamente 1 vez.
8. El orden de cleanup en `_subscribeToEventEnded()` es prescriptivo: (1) `_logSessionEnded` si `state.isTracking`, (2) `await _positionSubscription?.cancel()` + `_positionSubscription = null`, (3) `await _stopTrackingUseCase(...)`.fold(...) si `state.isTracking && uid != null`, (4) `if (!isClosed) emit(state.copyWith(isTracking: false, isFinished: true))`.
9. `close()` y `_handleAuthSignedOut()` no son modificados por esta fase, y la suite existente continúa en verde.

---

## 6 Guardrails de regresion

- La suite completa de tests (`flutter test`) debe pasar sin degradación: ningún test existente puede quedar roto.
- `live_tracking_cubit_analytics_test.dart` no debe ser modificado y debe continuar en verde.
- No se introducen dependencias nuevas (`pubspec.yaml` no cambia).
- No se modifican contratos de dominio (`TrackingRepository` interface no recibe métodos nuevos).
- No se toca `rideglory-api` (cambio puramente Flutter).
- El flag `_sessionEndLogged` existente en el cubit no es removido ni modificado en su comportamiento.
- Los guards `isClosed` antes del emit final son obligatorios (no opcionales).

---

## 7 Constraints heredados

- **Orden de despliegue obligatorio:** Fase 1 (este fix) → Fase 2 → Fase 3 (cron auto-end de eventos en backend). Sin esta fase, el cron de Fase 3 deja riders en estado corrupto.
- **`leaveSession` no va al dominio:** La opción de agregar `leaveSession` como método abstracto a `TrackingRepository` fue descartada por el Auditor Opus (corrección C1). `TrackingRepositoryImpl.stopTracking` ya invoca `leaveSession` internamente (línea 100) antes de `stopSession` (línea 101) — agregar una segunda llamada explícita crearía un doble `leaveSession`.
- **Dos seams separados requeridos:** `debugPrimeForEventEndedTest` y `debugSubscribeEventEndedForTest` son necesarios porque tienen estados iniciales mutuamente excluyentes; no se pueden unificar en un solo seam.
- **`Nothing` del proyecto, no de `dartz`:** El tipo `Nothing` para el `Right` del use case viene de `lib/core/domain/nothing.dart`; `dartz` no provee ninguna clase `Nothing`.
- **Nivel de esfuerzo:** `normal` (el cambio de cubit es quirúrgico pero los tests de conteo exacto y análisis de doble-disparo requieren más que `lite`; no hay contratos API nuevos ni cambios cross-repo que justifiquen `full`).
- **Strings / l10n:** Esta fase no introduce texto visible al usuario; no aplica la regla de l10n.
- **Git:** El árbol de trabajo queda sucio intencionalmente; no se commitea hasta revisión humana.
