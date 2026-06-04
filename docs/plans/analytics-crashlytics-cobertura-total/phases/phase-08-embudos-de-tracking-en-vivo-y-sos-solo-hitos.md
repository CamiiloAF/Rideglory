# Fase 8 — Embudos de tracking en vivo y SOS (solo hitos)

> Slug del plan: `analytics-crashlytics-cobertura-total`
> Esquema de IDs: 1..11 (ver `05-sintesis.md`). Esta es la **fase 8**.
> Fecha de redacción (UTC): 2026-06-04T01:06:50Z
> Sesión: PLANEACIÓN. Este archivo NO modifica código; describe qué deberá hacer la fase de ejecución.
> Estado de captura: **sin UI nueva / sin regresión de comportamiento**. Activa en release, off en `kDebugMode`, no-op en tests (gating heredado de la fase 1).

## Objetivo

El equipo mide **adopción y abandono del tracking en vivo** y el **contexto de las activaciones de SOS**, instrumentando **solo hitos** del ciclo de vida — nunca volumen (pings de ubicación, mensajes WebSocket) ni PII (coordenadas, nombres, ids dinámicos). Al cerrar la fase, DebugView muestra exactamente los hitos enumerados al iniciar/terminar una sesión y al disparar un SOS de prueba, y **cero** eventos al navegar una sesión activa.

## Alcance (entra / no entra)

### Entra

- Instrumentar en `LiveTrackingCubit` los **hitos de ciclo de sesión**:
  - `tracking_session_started` — al confirmar el arranque de mi tracking (callback de éxito de `_startTrackingUseCase`, ver `live_tracking_cubit.dart` L208–223).
  - `tracking_session_ended` — al detener mi tracking de forma efectiva (en `_handleAuthSignedOut` L345–347 y en `close()` L375–378, donde se llama `_stopTrackingUseCase`; y/o cuando llega `eventEnded` en `_subscribeToEventEnded` L451–454, fin de la sesión por el organizador). Se dispara **una sola vez por sesión** (anti-doble-conteo, ver más abajo).
  - `tracking_snapshot_received` — al recibir el **primer** snapshot de la sesión activa (señal de "el mapa se pobló"). El snapshot se origina en `tracking_repository_impl.dart` L45–46 / `tracking_ws_client.dart` `_handleSnapshot` L230–246; el hito se emite **una sola vez por sesión**, no por cada snapshot.
- Instrumentar los **hitos de SOS** en `LiveTrackingCubit`:
  - `sos_activated` — en `triggerSos()` (L383–394), cuando el usuario publica un SOS propio.
  - `sos_confirmed` — cuando este cliente recibe la confirmación de su propio SOS (alerta de SOS cuyo `userId == _userId`) en `_subscribeToSosAlerts` (L415–425). Es el hito "el sistema confirmó/propagó mi SOS".
  - `sos_cleared` — cuando se cierra/cancela un SOS: en `cancelSos()` (L398–404) y/o en `_subscribeToSosCleared` (L427–447) cuando `clearsOwnSos`.
- Definir las **constantes** de eventos y de params en la taxonomía centralizada de la fase 2 (`core/services/analytics/`), prefijo `tracking_` / `sos_`, snake_case, ≤40 chars.
- **Prohibición escrita** (comentario en código + doc): nunca emitir un evento de analítica por cada ping de ubicación (`_listenPosition` L226–288, `publishLocation`) ni por cada mensaje WebSocket entrante (`_onMessage` L190–228). Las coordenadas (`latitude`/`longitude`/`currentUserLatitude`/`currentUserLongitude`) **nunca** van como param.
- WebSocket: instrumentación **opcional** de **ciclo de vida** (conectar/reconectar/fallo), nunca por mensaje. Si se incluye, vive en `TrackingWsClient` (`_connect`, `_onDisconnected`) como señal de salud agregada, sin coordenadas ni ids de evento como param de alta cardinalidad.
- Test unitario con mock de `AnalyticsService` que verifica que `triggerSos()` dispara exactamente 1 `sos_activated` y **ningún** evento de ubicación.

### No entra

- Cualquier evento por ping de ubicación, por mensaje WS, o por emisión de la lista de riders.
- Coordenadas (lat/lng), nombres de rider, teléfono o ids de usuario/evento como **valor** de param.
- Cambios de UI: `live_map_page.dart`, `participants_*` y diálogos NO cambian de comportamiento; solo, si fuese estrictamente necesario, se enrutan callbacks hacia el cubit (preferencia: instrumentar **dentro del cubit**, no en la página).
- Backend / `rideglory-api`: sin cambios de contrato. El tracking ya es client-side; la analítica también.
- Métricas de rendimiento/latencia del WS o del GPS (fuera de alcance del plan).
- Persistencia de consentimiento / opt-out (vive en la fase 11).

## Qué se debe hacer (pasos concretos y ordenados)

1. **Confirmar prerequisitos** (fases 1 y 2 cerradas): existe `AnalyticsService` ampliado con `logEvent`, gating por no-op + `setEnabled(false)`, y la taxonomía centralizada con la convención de límites GA4 (≤40/≤40/≤100, params `Object`, sin bool→0/1).
2. **Añadir constantes a la taxonomía** (fase 2, en `core/services/analytics/`): nombres de evento `tracking_session_started`, `tracking_session_ended`, `tracking_snapshot_received`, `sos_activated`, `sos_confirmed`, `sos_cleared`, y los params no-PII permitidos (ver tabla de params abajo). No definir literales sueltos en el cubit (regla G1: 0 `logEvent(` con literal directo).
3. **Inyectar `AnalyticsService` en `LiveTrackingCubit`** vía su constructor (campo `final AnalyticsService _analyticsService`), respetando que el cubit es `@injectable` y se construye por factory (`live_tracking_cubit_factory.dart`) — añadir el parámetro en el factory. Abstracción core pura (regla de capa G0 de la fase 1): el cubit ya es presentation, consume la abstracción, nunca el SDK.
4. **Emitir `tracking_session_started`** en el callback de éxito de `_startTrackingUseCase` (L208), una sola vez por arranque exitoso.
5. **Emitir `tracking_snapshot_received`** la **primera vez** que la sesión recibe riders desde el snapshot inicial. Implementación recomendada: un flag de instancia `bool _snapshotLogged = false` en el cubit; al primer `ResultState.data` de `ridersResult` con datos (en `_subscribeToRiders` L469–490), si `!_snapshotLogged` → loguear y marcar `true`. Resetear el flag al iniciar una nueva sesión.
6. **Emitir `tracking_session_ended`** exactamente una vez por sesión cuando el tracking se detiene de verdad: guardar un flag `bool _sessionEndLogged = false`; loguear en el primer punto que efectivamente para (`_handleAuthSignedOut` tras `_stopTrackingUseCase`, `close()` tras `_stopTrackingUseCase`, o `eventEnded`). Param `end_reason` ∈ {`user_left`, `event_ended`, `signed_out`} (enum cerrado, no dinámico).
7. **Emitir `sos_activated`** en `triggerSos()` (después de `_trackingRepository.publishSos(...)`), con params no-PII (ver tabla). **No** incluir `latitude`/`longitude` aunque estén en `state`.
8. **Emitir `sos_confirmed`** en `_subscribeToSosAlerts` solo cuando la alerta recibida sea la propia (`alert.userId == _userId`), una vez por activación.
9. **Emitir `sos_cleared`** en `cancelSos()` y en `_subscribeToSosCleared` cuando `clearsOwnSos`, con `clear_reason` ∈ {`user_cancel`, `remote_clear`}; evitar doble-conteo si ambos caminos coinciden (flag por activación de SOS).
10. **Escribir la prohibición** como comentario explícito en `_listenPosition`/`publishLocation` y en `TrackingWsClient._onMessage`: "no analytics por ping/mensaje WS; coordenadas fuera de params". Reflejarlo también en el doc de taxonomía (fase 2/10).
11. **(Opcional) WS lifecycle**: si se instrumenta, en `TrackingWsClient` inyectar `AnalyticsService` y emitir `tracking_ws_connected` / `tracking_ws_reconnect` en `_connect`/`_onDisconnected` (agregado, sin coords, sin id de evento como valor). Marcar claramente como opcional/salud.
12. **Tests unitarios** con `bloc_test` + mock de `AnalyticsService` (ver sección Pruebas).
13. **`dart format` + `dart analyze` limpios**; correr `build_runner` si el factory/DI cambia.
14. **Actualizar docs del feature** si aplica: `docs/features/events.md` (mención de los hitos de tracking/SOS, sin pings).

### Params permitidos (no-PII, agregados o enum cerrado)

| Evento | Params permitidos | Prohibido |
|---|---|---|
| `tracking_session_started` | `role` (`lead`/`rider`, enum) | uid, eventId como valor, coords |
| `tracking_snapshot_received` | `rider_count` (entero agregado) | ids de rider, coords, nombres |
| `tracking_session_ended` | `end_reason` (enum) | coords, distancia con uid, duración con PII |
| `sos_activated` | `role` (enum) | lat/lng, nombre, teléfono, uid |
| `sos_confirmed` | (ninguno requerido) | lat/lng, uid |
| `sos_cleared` | `clear_reason` (enum) | lat/lng, uid |

> `rider_count` es un agregado de baja cardinalidad (número), no un id. El `role` ya existe en el cubit (`RiderTrackingRole.lead/.rider`, L167–169) y no es PII.

## Archivos a crear/modificar (rutas reales, una línea de "qué cambia")

- `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` — inyectar `AnalyticsService`; emitir los 6 hitos en los call sites indicados; flags anti-doble-conteo; comentario de prohibición en `_listenPosition`.
- `lib/features/events/presentation/tracking/cubit/live_tracking_cubit_factory.dart` — pasar `AnalyticsService` al construir el cubit.
- `lib/core/services/analytics/<archivo de constantes de tracking/sos>.dart` — **añadir** (no crear semántica nueva si la fase 2 ya tiene un único archivo de taxonomía) las constantes `tracking_*` / `sos_*` y sus param keys.
- `lib/features/events/data/service/tracking_ws_client.dart` — (opcional) instrumentación de ciclo de vida del WS + comentario "no analytics por mensaje" en `_onMessage`.
- `test/features/events/presentation/tracking/live_tracking_cubit_analytics_test.dart` — **crear**: test de hitos con mock de `AnalyticsService`.
- `docs/features/events.md` — actualizar mención de instrumentación de tracking/SOS (solo hitos) si el doc describe estos flujos.

> Confirmado en código: `triggerSos()` L383, `cancelSos()` L398, `_subscribeToSosAlerts` L415, `_subscribeToSosCleared` L427, `_subscribeToEventEnded` L449, éxito de start L208, `_stopTrackingUseCase` en `_handleAuthSignedOut` L346 y `close()` L377, snapshot en `tracking_repository_impl.dart` L45 / `tracking_ws_client.dart` L230. SOS UI en `live_map_page.dart` L107–125 (delega en el cubit; **no** se instrumenta en la página).

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la instrumentación es client-side. Los endpoints de tracking (`POST :eventId/tracking/start|end`, `session/start|stop`, `snapshot`, WebSocketGateway) **no cambian de contrato**. El WS de `TrackingWsClient` se consume tal cual; no se añaden tipos de mensaje.

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Sin migraciones de BD, sin nuevas claves en `UserStorageService` (el opt-out vive en la fase 11), sin DTOs nuevos (la analítica no serializa modelos de API). Re-correr `build_runner` solo si cambia la firma del factory/DI.

## Criterios de aceptación (numerados, observables, testeables)

1. **DebugView muestra exactamente los hitos enumerados.** Iniciar una sesión de tracking de prueba emite `tracking_session_started` (1x) y, al poblarse el mapa, `tracking_snapshot_received` (1x); terminarla emite `tracking_session_ended` (1x) con `end_reason` válido. No aparece ningún otro evento de tracking en ese flujo.
2. **SOS de prueba emite sus hitos.** Disparar SOS emite `sos_activated` (1x); al confirmarse, `sos_confirmed` (1x); al cancelarlo/cerrarlo, `sos_cleared` (1x) con `clear_reason` válido.
3. **Cero eventos por volumen.** Navegando una sesión activa (moviéndose, recibiendo updates de riders, mensajes WS), DebugView muestra **0** eventos por ping de ubicación y **0** eventos por mensaje WebSocket. (Verificable observando DebugView durante ≥1 minuto de sesión activa.)
4. **Sin coordenadas en params.** Ningún evento de esta fase lleva `latitude`/`longitude` (ni `currentUserLatitude`/`currentUserLongitude`) en sus params. Grep + inspección de DebugView lo confirman.
5. **Sin PII ni alta cardinalidad.** Ningún param lleva uid de usuario, id de evento como valor, nombre de rider, teléfono ni id de otro rider. Solo enums cerrados (`role`, `end_reason`, `clear_reason`) y agregados (`rider_count`).
6. **Anti-doble-conteo.** `tracking_session_ended` se emite **una sola vez por sesión** aunque concurran `signOut`/`close`/`eventEnded`; `tracking_snapshot_received` una sola vez por sesión; `sos_cleared` una sola vez por activación de SOS aunque coincidan `cancelSos()` y el evento remoto.
7. **G1 — sin literales.** `grep -n "logEvent('"` en `live_tracking_cubit.dart` y `tracking_ws_client.dart` = 0; todos los nombres salen de las constantes de taxonomía.
8. **Regla de capa (G0).** El cubit consume `AnalyticsService` (abstracción core pura); 0 imports de `package:firebase_analytics`/`firebase_crashlytics` en `lib/features/events/`.
9. **Gating.** En `kDebugMode`/tests no se envían eventos reales (no-op impl + `setEnabled(false)`); `flutter test` no intenta enviar.
10. **Test de SOS.** El test unitario verifica que `triggerSos()` dispara exactamente 1 `sos_activated` (con mock) y **cero** eventos de ubicación.
11. **Sin regresión.** El comportamiento de tracking/SOS (mapa, riders, banners, fin de ride) es idéntico al previo; `dart analyze` limpio, `flutter test` verde.

## Pruebas (unitarias/widget/integración)

**Unitarias (obligatorias) — `test/.../live_tracking_cubit_analytics_test.dart`:**

- Mock `MockAnalyticsService` (mocktail) + mocks de los use cases / `TrackingRepository` / `AuthService` ya existentes.
- `triggerSos()` → verifica `analytics.logEvent('sos_activated', ...)` llamado **exactamente 1 vez** y **ningún** `logEvent` con nombre de ubicación/ping. (Criterio principal de la fase.)
- `cancelSos()` → 1 `sos_cleared` con `clear_reason = user_cancel`; segunda llamada o evento remoto coincidente no duplica (anti-doble-conteo).
- Recepción de SOS propio en `sosAlerts` (`userId == _userId`) → 1 `sos_confirmed`; SOS de otro rider → **0** `sos_confirmed`.
- Arranque exitoso (mock de `_startTrackingUseCase` que retorna `Right`) → 1 `tracking_session_started`; arranque fallido (`Left`) → 0.
- Primer `ResultState.data` con riders → 1 `tracking_snapshot_received` con `rider_count`; emisiones siguientes → 0 adicionales.
- `_stopTrackingUseCase` efectivo (vía signOut/`close`/`eventEnded`) → 1 `tracking_session_ended` con `end_reason`; caminos concurrentes → no duplica.

**Negativas (no-volumen):**

- Simular múltiples updates de posición / múltiples emisiones de `watchActiveRidersUseCase` → verificar **cero** `logEvent` adicionales (más allá del único `tracking_snapshot_received`).

**Manual / DebugView (verificación e2e, no automatizable en CI):**

- Sesión real de prueba en build no-debug: observar en GA4 DebugView que aparecen solo los hitos y ninguno por ping/mensaje WS; confirmar ausencia de lat/lng en cada evento.

**Widget/integración:** no se requieren nuevos tests de widget (sin UI nueva); los tests existentes de `live_map_page`/`participants_*` deben seguir verdes (no-regresión).

## Riesgos y mitigaciones

1. **Doble-conteo de fin de sesión** (concurren `signOut`, `close`, `eventEnded`). *Mitigación:* flag de instancia `_sessionEndLogged`; loguear en el primer camino que efectivamente para el tracking.
2. **Doble-conteo de `sos_cleared`** (cancel local + evento remoto del mismo SOS). *Mitigación:* flag por activación de SOS; el segundo camino no re-emite.
3. **Fuga de PII por copiar params del estado.** El estado tiene `currentUserLatitude/Longitude` y los riders traen nombre/teléfono. *Mitigación:* lista blanca de params (tabla), revisión en fase 10, prohibición escrita en código.
4. **Volumen/costo GA4 si alguien instrumenta el stream de posiciones o `_onMessage`.** *Mitigación:* comentario explícito en `_listenPosition`/`publishLocation`/`_onMessage`; test negativo de no-volumen; criterio 3 verificado en DebugView.
5. **`tracking_snapshot_received` emitido por cada snapshot/reconexión.** *Mitigación:* flag `_snapshotLogged` por sesión, reseteado al re-arrancar.
6. **Instrumentar en la página en vez del cubit** (riesgo de eventos sin gating o duplicados al reconstruir el widget). *Mitigación:* instrumentar **dentro del cubit**, fuente única de verdad de los hitos; la página solo delega callbacks (ya lo hace, `live_map_page.dart` L107–125).
7. **WS lifecycle opcional generando ruido.** *Mitigación:* mantenerlo opcional, agregado, sin id de evento como valor; reconexiones throttled si se incluye.

## Dependencias (fases prerequisito y por qué)

- **Fase 1 — Fundaciones, captura, gating y regla de capa (G0).** Provee `AnalyticsService` ampliado, la no-op impl + `setEnabled(false)` para tests, los handlers no-report en debug y la regla de capa que legitima inyectar la abstracción core en el cubit (presentation). Sin ella no hay gating ni abstracción que consumir.
- **Fase 2 — Taxonomía, mapa de rutas y límites GA4.** Provee las constantes centralizadas y la convención de límites (≤40/≤40/≤100, params `Object`, sin bool→0/1) que esta fase reutiliza para definir `tracking_*` / `sos_*`. Sin ella se reintroducirían literales mágicos (viola G1).

> Esta fase **no** depende de la 3 (screen_view) ni de la 6/7 (núcleo de eventos): los hitos viven en el cubit de tracking, no en la navegación ni en los flujos de creación/registro. `dependsOn: [1, 2]`.
