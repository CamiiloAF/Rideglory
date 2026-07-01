# Fase 1 — WS Cleanup on Event End (Flutter)

**Slug:** event-tracking-fixes / phase-01
**Timestamp:** 2026-06-20T00:30:21Z
**Nivel rg-exec:** normal

---

## Objetivo

Cuando el backend emite `tracking.event.ended` via WebSocket, `LiveTrackingCubit._subscribeToEventEnded()` debe ejecutar el cleanup completo de recursos en el orden correcto: (1) registrar analytics, (2) cancelar la suscripción GPS, (3) invocar `_stopTrackingUseCase` (que internamente cierra el WS via `leaveSession` antes de la llamada HTTP), y (4) emitir el estado final de UI. Actualmente el cubit solo llama `_logSessionEnded` y emite `isFinished: true`, dejando el stream de GPS activo y el WS sin cerrar, lo que provoca pings de ubicación al backend para un evento ya FINISHED.

---

## Alcance

### Entra

- Modificar `LiveTrackingCubit._subscribeToEventEnded()` (línea 546 de `live_tracking_cubit.dart`) para implementar los 4 pasos de cleanup en el orden exacto definido en este plan.
- Agregar el seam `@visibleForTesting void debugPrimeForEventEndedTest(String userId)` al cubit para habilitar los tests de los Casos A, B y D (rider activo).
- Agregar el seam `@visibleForTesting void debugSubscribeEventEndedForTest()` al cubit para habilitar el Caso C (rider inactivo, solo suscripción sin sesión).
- Nuevo archivo de test `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` que cubre:
  - El path principal: cleanup en orden correcto, estado final correcto.
  - Path de guard `_sessionEndLogged` (doble-disparo de `eventEnded`): analytics logeado exactamente una vez.
  - Path sin sesión activa (`state.isTracking == false` / `_userId == null`): `_stopTrackingUseCase` no invocado.
  - `_stopTrackingUseCase` invocado exactamente 1 vez en el path principal (lo que implica que `leaveSession` del `TrackingWsClient` se invoca exactamente 1 vez, via `TrackingRepositoryImpl.stopTracking`).

### No entra

- NO se agrega `leaveSession` como método abstracto a `TrackingRepository` (la interfaz de dominio). El Architect (03) propuso la Opción B pero la corrección C1 del Auditor Opus la descartó: `TrackingRepositoryImpl.stopTracking` ya llama `leaveSession` en su implementación (línea 100 de `tracking_repository_impl.dart`) antes de `stopSession`. Agregar `leaveSession` al dominio crearía una segunda llamada innecesaria.
- NO se modifican otros métodos del cubit (`close`, `_handleAuthSignedOut`, `stopTracking`, etc.). Ya implementan cleanup correcto.
- NO se modifican archivos de backend (`rideglory-api`).
- NO se tocan otros cubits ni pantallas.
- NO se modifica el test existente `live_tracking_cubit_analytics_test.dart` (se mantiene; el nuevo archivo es independiente).

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Leer y entender el estado actual del cubit

Leer completo `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` para confirmar:
- Línea 546: `_subscribeToEventEnded()` solo llama `_logSessionEnded` y emite `isFinished: true`.
- Línea 93: `_sessionEndLogged` flag.
- Línea 77: `_positionSubscription` es `StreamSubscription<Position>?`.
- Líneas 94-105 de `tracking_repository_impl.dart`: `stopTracking` llama `leaveSession` en la línea 100, ANTES de `stopSession` en la línea 101.

### Paso 2 — Implementar el orden de cleanup en `_subscribeToEventEnded()`

Reemplazar el cuerpo del listener (líneas 549-554) con los 4 pasos en orden exacto:

```dart
void _subscribeToEventEnded() {
  _eventEndedSubscription?.cancel();
  _eventEndedSubscription = _trackingRepository.eventEnded.listen((_) async {
    if (isClosed) return;
    // Paso 1: Analytics — antes de mutar estado; _sessionEndLogged previene doble-conteo.
    if (state.isTracking) {
      _logSessionEnded(AnalyticsParams.trackingEndReasonEventEnded);
    }
    // Paso 2: Cancelar GPS — evita pings al backend mientras se ejecuta el stop.
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    // Paso 3: Stop use case — cierra WS (leaveSession interno en stopTracking)
    //         y llama HTTP stopSession. fold sin relanzar: si el evento ya es
    //         FINISHED en backend, leaveSession ya ocurrió dentro de stopTracking
    //         antes del fallo HTTP; Left no deja el WS abierto.
    final uid = _userId;
    if (state.isTracking && uid != null) {
      await _stopTrackingUseCase(eventId: _eventId, userId: uid)
          .fold((_) => null, (_) => null);
    }
    // Paso 4: Emit UI — al final, tras todo el cleanup.
    if (!isClosed) {
      emit(state.copyWith(isTracking: false, isFinished: true));
    }
  });
}
```

Notas de implementación críticas:
- El listener pasa a `async` para que los `await` del GPS y del use case sean secuenciales.
- `isClosed` se verifica al inicio y antes del emit final (el cubit puede cerrarse mientras el listener ejecuta).
- `_positionSubscription = null` inmediatamente tras el cancel, consistente con el patrón de `_handleAuthSignedOut` (líneas 376-377).
- El fold `(_) => null` captura tanto `Left` como `Right` sin relanzar — el cleanup de WS ya ocurrió dentro de `stopTracking` antes de la llamada HTTP, por lo que incluso un `Left` (HTTP 4xx, evento ya FINISHED) no deja el WS abierto.
- `_userId` se captura en `uid` antes de verificar el guard, igual que en `_handleAuthSignedOut` y `close()`.

### Paso 3 — Agregar los dos seams `@visibleForTesting` y preparar el test

#### 3a — Agregar los seams al cubit

Agregar los dos métodos `@visibleForTesting` al cubit, junto a `debugPrimeSosForTest`.

**Seam 1: `debugPrimeForEventEndedTest`** — para los Casos A, B y D (rider activo con sesión iniciada):

```dart
/// Test-only seam: deja el cubit listo para ejercitar el path de eventEnded
/// con una sesión de rider activa, sin pasar por el flujo de Geolocator/permisos
/// (que usa APIs estáticas). Asigna [userId] a _userId, activa el listener
/// _subscribeToEventEnded(), y emite state.copyWith(isTracking: true) para
/// simular una sesión en curso. NO se usa en producción.
@visibleForTesting
void debugPrimeForEventEndedTest(String userId) {
  _userId = userId;
  _subscribeToEventEnded();
  emit(state.copyWith(isTracking: true));
}
```

**Seam 2: `debugSubscribeEventEndedForTest`** — para el Caso C (sin sesión activa, solo activa el listener):

```dart
/// Test-only seam: activa únicamente el listener de eventEnded sin establecer
/// userId ni isTracking. Permite ejercitar el path "eventEnded recibido antes
/// de que el rider inicie sesión" (state.isTracking == false, _userId == null).
/// NO se usa en producción.
@visibleForTesting
void debugSubscribeEventEndedForTest() {
  _subscribeToEventEnded();
}
```

**Por qué dos seams:** `debugPrimeForEventEndedTest` no puede usarse para el Caso C porque setea `isTracking: true` y `_userId`, lo que activa el guard `state.isTracking && uid != null` y haría que `_stopTrackingUseCase` se invoque. El Caso C necesita exactamente el estado opuesto: listener activo pero sin sesión. El seam `debugSubscribeEventEndedForTest` activa el listener sin alterar el estado inicial del cubit (que tiene `isTracking: false` y `_userId == null` por defecto).

**Nota sobre la alternativa descartada:** La opción "crear el cubit y `add(null)` sin ningún prime" es incorrecta porque el cubit no recibe eventos externos (extiende `Cubit`, no `Bloc`). Sin suscripción activa del listener, `eventEndedController.add(null)` no dispara nada.

#### 3b — Setup del stream de `eventEnded` en el test

En el archivo de test, declarar e inicializar el `StreamController` para `eventEnded`:

```dart
late MockStopTrackingUseCase stopTrackingUseCase;
late StreamController<void> eventEndedController;

setUp(() {
  stopTrackingUseCase = MockStopTrackingUseCase();
  eventEndedController = StreamController<void>.broadcast();
  // ... resto de mocks ...
  when(() => repo.eventEnded).thenAnswer((_) => eventEndedController.stream);
});

tearDown(() async {
  await cubit.close();
  await eventEndedController.close();
  // ... otros controllers ...
});
```

`stopTrackingUseCase` se captura como field de test para poder usar `verify` y `verifyNever` en todos los casos, incluyendo el Caso C donde se debe verificar que NO se invocó. Sin este field capturado, los casos no pueden hacer aserciones de conteo sobre el use case.

Sin el stub de `eventEnded`, el mock de `TrackingRepository` lanzará `MissingStubError` al intentar suscribirse.

#### 3c — Stub de `_stopTrackingUseCase` por caso

Para los Casos A, B y C:

```dart
when(
  () => stopTrackingUseCase(
    eventId: any(named: 'eventId'),
    userId: any(named: 'userId'),
  ),
).thenAnswer((_) async => const Right(Nothing()));
```

Para el Caso D:

```dart
when(
  () => stopTrackingUseCase(
    eventId: any(named: 'eventId'),
    userId: any(named: 'userId'),
  ),
).thenAnswer(
  (_) async => const Left(DomainException(message: 'evento ya FINISHED')),
);
```

El tipo de retorno de `StopTrackingUseCase.call` es `Future<Either<DomainException, Nothing>>`. El implementador debe importar `package:rideglory/core/domain/nothing.dart` y usar `const Nothing()` de ese paquete para el valor del `Right`. Usar `Right` y `Left` de `dartz` (el paquete de Either del proyecto) para construir los valores. La clase `Nothing` del proyecto vive en `lib/core/domain/nothing.dart` — no hay ninguna clase `Nothing` en `dartz`.

### Paso 4 — Implementar los 4 casos de test

**Caso A — Path principal (rider activo):**
- Setup: `cubit.debugPrimeForEventEndedTest('rider-1')`.
- Stub: `stopTrackingUseCase` retorna `Right(Nothing())` (ver Paso 3c).
- Acción: `eventEndedController.add(null)` y `await Future.microtask(() {})` para dejar que el listener async complete.
- Verificar:
  - `verify(() => stopTrackingUseCase(eventId: 'evt-1', userId: 'rider-1')).called(1)`.
  - `verify(() => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, any())).called(1)`.
  - Estado final: `cubit.state.isTracking == false` y `cubit.state.isFinished == true`.
- Nota: la cancelación de GPS (`_positionSubscription?.cancel()`) NO se verifica directamente en este test unitario porque `_positionSubscription` es un campo privado sin seam de inyección. La cobertura de este side effect queda fuera del alcance unitario; el orden de código en la implementación es la garantía.

**Caso B — Doble-disparo de `eventEnded` (guard `_sessionEndLogged`):**
- Setup: igual al Caso A.
- Stub: `stopTrackingUseCase` retorna `Right(Nothing())`.
- Acción: `eventEndedController.add(null)` dos veces, con `await Future.microtask(() {})` entre cada una y después de la segunda.
- Verificar:
  - `verify(() => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, any())).called(1)` — exactamente 1, no 2.
  - `verify(() => stopTrackingUseCase(eventId: 'evt-1', userId: 'rider-1')).called(1)` — exactamente 1, no 2.
- Explicación del guard: tras el primer disparo, el listener ejecuta el emit `state.copyWith(isTracking: false, isFinished: true)`. Cuando llega el segundo disparo, `state.isTracking` ya es `false`, por lo que el guard `state.isTracking && uid != null` es `false` y `_stopTrackingUseCase` NO se invoca por segunda vez. Adicionalmente, `_sessionEndLogged` fue seteado a `true` en el primer disparo, por lo que `_logSessionEnded` tampoco registra el analytics una segunda vez.

**Caso C — Rider no activo (`state.isTracking == false` / `_userId == null`):**
- Setup: construir el cubit normalmente (estado inicial: `isTracking: false`, `_userId == null`), luego llamar `cubit.debugSubscribeEventEndedForTest()` para activar el listener SIN establecer sesión.
- No se llama `debugPrimeForEventEndedTest`. No se stubbea `stopTrackingUseCase` con un retorno (porque no debe invocarse; si se invocara sin stub, mocktail lanzaría `MissingStubError`, lo que fallaría el test correctamente).
- Acción: `eventEndedController.add(null)` y `await Future.microtask(() {})`.
- Verificar:
  - `verifyNever(() => stopTrackingUseCase(eventId: any(named: 'eventId'), userId: any(named: 'userId')))`.
  - Estado emitido: `cubit.state.isFinished == true` (el emit del paso 4 ocurre igualmente; solo el guard del paso 3 es condicional).
  - `verifyNever(() => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, any()))`.

**Caso D — Use case retorna `Left` (HTTP fallo, evento ya FINISHED):**
- Setup: `cubit.debugPrimeForEventEndedTest('rider-1')`.
- Stub: `stopTrackingUseCase` retorna `Left(DomainException(...))` (ver Paso 3c).
- Acción: `eventEndedController.add(null)` y `await Future.microtask(() {})`.
- Verificar:
  - No lanza excepción (el fold absorbe el Left).
  - Estado final: `cubit.state.isTracking == false` y `cubit.state.isFinished == true`.
  - `verify(() => stopTrackingUseCase(eventId: 'evt-1', userId: 'rider-1')).called(1)`.

### Paso 5 — Verificar gate

```bash
dart analyze
flutter test test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart
flutter test  # suite completa
```

Ambos deben pasar sin nuevas violaciones.

---

## Archivos a crear/modificar (rutas reales)

| Operación | Ruta | Que cambia |
|-----------|------|------------|
| **Modificar** | `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | `_subscribeToEventEnded()`: listener pasa a `async`; agrega cancel GPS, invocación de `_stopTrackingUseCase` con fold, guard de `isClosed` antes del emit; emit mueve al final con `isTracking: false`. Dos métodos nuevos `@visibleForTesting`: `debugPrimeForEventEndedTest(String userId)` y `debugSubscribeEventEndedForTest()`. |
| **Crear** | `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` | Nuevo archivo de test unitario con 4 casos cubriendo el path principal, doble-disparo, rider inactivo, y fallo HTTP en use case. |

---

## Contratos / API rideglory-api

Ninguno. Esta fase es puramente Flutter. No se agregan endpoints HTTP, MessagePatterns, ni DTOs nuevos. `TrackingRepository` (interfaz de dominio) no recibe métodos nuevos.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion

1. `dart analyze` sobre el proyecto completo no reporta nuevas violaciones introducidas por esta fase.
2. `flutter test` (suite completa) pasa en verde.
3. El nuevo test `live_tracking_cubit_event_ended_test.dart` tiene exactamente 4 casos de test que pasan.
4. `_stopTrackingUseCase` es verificado como invocado exactamente 1 vez en el Caso A y exactamente 1 vez en el Caso B (el segundo disparo del stream no genera una segunda invocación porque `state.isTracking` ya es `false` tras el primer emit).
5. `analyticsService.logEvent` con `AnalyticsEvents.trackingSessionEnded` es verificado como invocado exactamente 1 vez en el Caso B (doble-disparo), gracias al flag `_sessionEndLogged`.
6. El estado final emitido en los Casos A, B y D contiene `isTracking: false` e `isFinished: true`.
7. En el Caso D (use case retorna `Left`), el cubit no lanza excepción y emite el estado correcto.
8. En el Caso C (sin sesión), `verifyNever` pasa para `stopTrackingUseCase` y para `analytics.logEvent` con `trackingSessionEnded`.
9. La lógica de `close()` y `_handleAuthSignedOut()` no es modificada por esta fase, y la suite existente (incluyendo `live_tracking_cubit_analytics_test.dart`) continúa en verde.

---

## Pruebas

### Unitarias (nuevas)

**Archivo:** `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart`

Setup base (aplicado antes de cada caso con `setUp`):

```dart
late MockTrackingRepository repo;
late MockAnalyticsService analytics;
late MockStopTrackingUseCase stopTrackingUseCase;
late StreamController<void> eventEndedController;
late StreamController<SosAlertModel> sosAlertsController;
late StreamController<String> sosClearedController;
late LiveTrackingCubit cubit;

setUp(() {
  repo = MockTrackingRepository();
  analytics = MockAnalyticsService();
  stopTrackingUseCase = MockStopTrackingUseCase();
  eventEndedController = StreamController<void>.broadcast();
  sosAlertsController = StreamController<SosAlertModel>.broadcast();
  sosClearedController = StreamController<String>.broadcast();

  when(() => repo.eventEnded).thenAnswer((_) => eventEndedController.stream);
  when(() => repo.sosAlerts).thenAnswer((_) => sosAlertsController.stream);
  when(() => repo.sosCleared).thenAnswer((_) => sosClearedController.stream);
  when(() => analytics.logEvent(any())).thenAnswer((_) async {});
  when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});

  cubit = LiveTrackingCubit(
    eventId: 'evt-1',
    eventOwnerId: 'owner-1',
    stopTrackingUseCase: stopTrackingUseCase,
    // ... demás dependencias mockeadas ...
    trackingRepository: repo,
    analyticsService: analytics,
  );
  // NOTA: NO se llama ningún seam de prime aquí. Cada caso lo invoca de forma
  // diferente según el escenario que ejercita.
});

tearDown(() async {
  await cubit.close();
  await eventEndedController.close();
  await sosAlertsController.close();
  await sosClearedController.close();
});
```

`stopTrackingUseCase` se captura como field para que todos los casos puedan hacer `verify` y `verifyNever` sobre él. Esto incluye el Caso C, que usa `verifyNever` para confirmar que el use case no fue invocado.

Los casos de test:

- **Caso A** (`eventEnded con rider activo`): llama `cubit.debugPrimeForEventEndedTest('rider-1')`, hace `eventEndedController.add(null)`, verifica conteos exactos de use case y analytics, estado final `isTracking: false / isFinished: true`. La cancelación de GPS no se verifica directamente (campo privado sin seam; limitación documentada).
- **Caso B** (`eventEnded doble-disparo, _sessionEndLogged guard`): llama `cubit.debugPrimeForEventEndedTest('rider-1')`, hace `eventEndedController.add(null)` dos veces. Verifica que analytics y `_stopTrackingUseCase` se invocan exactamente 1 vez aunque el stream emita dos veces. El segundo disparo llega con `state.isTracking == false`, por lo que el guard falla y `_stopTrackingUseCase` no se invoca una segunda vez.
- **Caso C** (`eventEnded sin sesión activa`): llama `cubit.debugSubscribeEventEndedForTest()` (sin prime de sesión), hace `eventEndedController.add(null)`. Verifica `verifyNever` tanto para `stopTrackingUseCase` como para `analytics.logEvent` con `trackingSessionEnded`. Verifica que el estado emitido tiene `isFinished: true`.
- **Caso D** (`_stopTrackingUseCase retorna Left`): llama `cubit.debugPrimeForEventEndedTest('rider-1')` con stub que retorna `Left`. Verifica que el fold absorbe el error sin relanzar y el emit ocurre correctamente con `isTracking: false / isFinished: true`.

### Unitarias existentes (no modificadas)

- `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart`: cubre SOS y analytics generales. No se toca; debe continuar verde.

### Widget / Integración

No se requieren para esta fase. El cambio es en lógica de cubit pura (no en widgets), y los 4 casos de test unitario cubren todos los paths de control relevantes.

---

## Riesgos y mitigaciones

| ID | Severidad | Descripcion | Mitigacion |
|----|-----------|-------------|------------|
| R4 | Baja | `_stopTrackingUseCase` retorna `Left` si el evento ya es `FINISHED` en backend (HTTP 4xx). Si el fold no captura el Left, el cleanup de UI nunca ocurre. | `fold((_) => null, (_) => null)` captura Left sin relanzar. `leaveSession` del WS ya ocurrió dentro de `stopTracking` antes del fallo HTTP (línea 100 de `tracking_repository_impl.dart` es anterior a línea 101). Cubierto por Caso D del test. |
| R5 | Baja | Doble-conteo de analytics si `eventEnded` stream emite y `close()` es llamado justo después, antes de que `_sessionEndLogged` sea seteado a `true`. | El flag `_sessionEndLogged` es seteado dentro de `_logSessionEnded()` de forma síncrona al inicio. `close()` también llama `_logSessionEnded` con su propia razón; el flag previene el doble-log. Cubierto por Caso B del test. |
| RS | Baja | El listener se vuelve `async`; si el cubit es cerrado mientras el listener awaita (entre el cancel GPS y el stop use case), el emit del paso 4 se llama en un cubit cerrado. | Guard `if (!isClosed)` antes del emit final. El `flutter_bloc` ignora emits de cubits cerrados, pero es mejor práctica verificar explícitamente. |
| RO | Baja | Orden de pasos: si el emit ocurre antes del cancel GPS (orden invertido), la UI de `RideFinishedOverlay` aparece pero el GPS continúa enviando ubicaciones hasta que el use case resuelve. | El orden del plan es prescriptivo y la implementación debe respetarlo exactamente: GPS cancel → use case → emit. El implementador debe seguir el orden del código literalmente. |

---

## Dependencias

**Fases prerequisito:** Ninguna. Esta es la fase 1 y no depende de ninguna otra fase del plan `event-tracking-fixes`.

**Nota de despliegue:** La Fase 3 (Auto-End Events After 24 Hours, Backend) tiene prerrequisito funcional sobre esta fase. El cron de Fase 3 emite `broadcastEventEnded`, que dispara el stream `eventEnded` en los clientes Flutter. Sin esta fase, los riders recibirían el broadcast pero no cancelarían GPS ni cerrarían el WS, continuando con pings de ubicación a un evento FINISHED. Por tanto el orden de despliegue obligatorio es: **Fase 1 → Fase 2 → Fase 3**.

---

## Ejecucion recomendada

**Nivel rg-exec: normal**

**Por que ese nivel:** Esta fase toca lógica crítica de lifecycle en `LiveTrackingCubit` donde el orden exacto de operaciones importa operacionalmente: GPS cancelado antes del emit evita pings al backend durante el tiempo de resolución del use case HTTP. Un orden incorrecto es una regresión silenciosa difícil de detectar en QA manual porque el efecto (pings a evento FINISHED) ocurre en el backend sin señal visible en UI. El nivel `normal` es apropiado porque: (a) el cambio de código es quirúrgico (un método, ~10 líneas) más dos seams de test, (b) requiere un archivo de test nuevo con 4 casos que cubren paths de doble-conteo y verificación de conteos exactos de invocaciones, (c) no hay contratos API nuevos ni migraciones, y (d) el riesgo es medio — no alto — porque los mecanismos de guard (`_sessionEndLogged`, `isClosed`, `state.isTracking`) ya existen en el cubit y el implementador solo necesita usarlos correctamente. El nivel `lite` sería insuficiente por la exigencia de los tests de conteo exacto y el análisis de doble-disparo; el nivel `full` sería excesivo dado que no hay cambios cross-repo ni contratos nuevos.
