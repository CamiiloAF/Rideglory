# 04-plan-review.md — Plan Reviewer (UX + Calidad)

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:08:48Z
**Verdict:** ok_con_ajustes

---

## UX por fase

### Fase 1 — WS Cleanup on Event End (Flutter)

**Clasificación de pantalla:** EXTEND (estado existente `isFinished` en `LiveTrackingState`)

**Flujos de UI afectados:**
- El overlay `RideFinishedOverlay` ya se renderiza cuando `state.isFinished == true`. No hay pantalla nueva.
- El bug vive exclusivamente en el cubit (`_subscribeToEventEnded()`). El usuario ve el overlay pero el GPS y el WS siguen vivos en background.

**Estados UX:**
| Estado | Comportamiento actual (bug) | Comportamiento correcto (post-fix) |
|---|---|---|
| `tracking.event.ended` recibido | Overlay visible, GPS drenando batería, WS activo | Overlay visible, GPS cancelado, WS cerrado sin reconexión |
| Rider toca "Salir" en overlay | Cubit cierra, `close()` llama stop (redundante) | Cubit cierra, `close()` detecta `!state.isTracking` (ya false), sin doble stop |

**UX notes:**
- El fix debe emitir `isFinished: true` DESPUÉS de cancelar las suscripciones, no antes, para que el overlay no se renderice con estado inconsistente.
- `_logSessionEnded` ya verifica `_sessionEndLogged` flag — el fix debe llamarlo antes del cleanup para no perder el hito de analytics.
- Touch targets: no hay impacto. Sin nueva UI.

**Resultado:** sin cambios de UI; sin mockup requerido.

---

### Fase 2 — Event List Date Filter (Flutter)

**Clasificación de pantalla:** EXTEND (listado existente `EventsPage` / `EventsPageView`)

**Flujos de UI afectados:**
- `EventsPage` crea el cubit con `..fetchEvents()`. El fix va en `EventsCubit.fetchEvents()` — sin cambio visual en la pantalla.
- El usuario no ve ningún control nuevo; simplemente los eventos pasados desaparecen del listado inicial.

**Estados UX:**
| Estado | Pre-fix | Post-fix |
|---|---|---|
| Lista vacía (sin eventos futuros) | `ResultState.data([])` con lista que puede contener pasados mezclados | `ResultState.empty()` o `ResultState.data([])` limpio — solo futuros |
| Con filtro manual de fecha | Sin cambio — el usuario ya puede ajustar `startDate` | Sin cambio — el filtro manual sobreescribe el piso automático |
| `myEvents` (mis eventos) | Sin filtro de fecha | Sin cambio — la propuesta no altera `EventsCubit.myEvents` |

**UX concern — timezone:**
El PO señala el riesgo de timezone: si `dateFrom` se calcula como UTC midnight mientras el rider está en UTC-5, ve 5 horas de eventos "pasados de hoy". La implementación debe usar `DateTime.now()` local truncado a medianoche local, luego convertido a ISO8601 con offset: `DateTime(now.year, now.month, now.day).toIso8601String()`. Dado que la API ya acepta `dateFrom` como string de fecha (`YYYY-MM-DD` por como el cubit lo formatea: `.toIso8601String().substring(0, 10)`), la conversión local es trivial y correcta.

**Estados adicionales a cubrir en test:**
- Sin filtros de usuario: se pasa `dateFrom = startOfToday` al backend.
- Con `filters.startDate != null` (filtro manual): se pasa `filters.startDate`, NO el piso automático.
- `myEvents`: no se pasa `dateFrom` (sin cambio).

**Impacto en `_applyFiltersAndEmit`:**
El filtro local de `_filters.startDate` se aplica sobre los eventos ya devueltos por el backend. Con el piso automático en el backend, el filtro local de `startDate == null` nunca devuelve pasados. El plan debe aclarar que el filtro local NO se modifica — solo el `dateFrom` enviado al backend.

**Touch targets / mobile 375px:** ningún cambio visual. Sin mockup requerido.

---

### Fase 3 — Auto-End Events After 24 Hours (Backend)

**Clasificación:** sin UI nueva en Flutter. El impacto de UX es indirecto: los riders ven `tracking.event.ended` por WS (Fase 1) y reciben FCM.

**Flujo de UX de la notificación FCM:**
- El cron envía FCM al cerrar el evento. La notificación llega al rider con el app en background o foreground.
- No se diseña pantalla nueva para esta fase. Sin mockup requerido.
- Si el rider está en pantalla de live tracking, Fase 1 maneja el cleanup automáticamente.

**Estados que Fase 3 dispara en Flutter:**
| Canal | Evento | Acción en app |
|---|---|---|
| WebSocket | `tracking.event.ended` | `LiveTrackingCubit._subscribeToEventEnded()` → cleanup (Fase 1) |
| FCM push | Notificación "El evento terminó" | Dependiente de la infraestructura existente de notificaciones |

---

## Gates de calidad

### Fase 1 — WS Cleanup

| Regla | Estado | Detalle |
|---|---|---|
| Un widget por archivo | N/A | No se crean widgets nuevos |
| No métodos que retornen widgets | N/A | No aplica |
| `ResultState<T>` para async | OK | `LiveTrackingState` es `@freezed`; no hay `bool isLoading` nuevo |
| AppButton/AppTextField | N/A | No aplica |
| Texto oscuro sobre primario | N/A | No aplica |
| dart analyze | Gate obligatorio | Debe pasar antes de entregar la fase |
| Test unitario | REQUERIDO | Cubit test: `eventEnded → GPS cancelado, WS cerrado, isFinished: true`. Verificar que `_logSessionEnded` se llama con reason `trackingEndReasonEventEnded` y que el flag `_sessionEndLogged` previene doble-conteo si `close()` llama después. |

**Orden de operaciones en `_subscribeToEventEnded` (crítico):**
```
1. if (isClosed) return
2. if (state.isTracking) _logSessionEnded(...)   ← antes de mutar estado
3. await _positionSubscription?.cancel()
4. _positionSubscription = null
5. await _stopTrackingUseCase(eventId, userId)    ← respetar isClosed check después
6. await _wsClient.leaveSession(...)              ← o usar el repo; verificar cuál expone el cubit
7. emit(state.copyWith(isFinished: true, isTracking: false))
```

El cubit NO tiene `_wsClient` inyectado directamente — usa `_trackingRepository`. Verificar que `_trackingRepository` expone `leaveSession` o equivalente, o si el arquitecto de fase debe inyectar `TrackingWsClient` directamente. El scan confirma que `leaveSession` vive en `TrackingWsClient` (`@lazySingleton`), no en el repositorio abstracto. La fase debe decidir si: (a) exponer `leaveSession` como método del repositorio abstracto (limpio, respeta Clean Architecture), o (b) inyectar `TrackingWsClient` directamente en el cubit (viola la regla de no exponer data en presentation directamente). **La opción (a) es mandatoria.** El plan de fase debe incluir añadir `leaveSession(String eventId, String userId)` a `TrackingRepository` como interfaz.

### Fase 2 — Date Filter

| Regla | Estado | Detalle |
|---|---|---|
| `EventFilters.startDate` nullable usado correctamente | VERIFICAR | El piso automático solo aplica cuando `_filters.startDate == null` |
| `myEvents` sin cambio | REQUERIDO | El constructor `EventsCubit.myEvents` ignora `dateFrom`; no tocar |
| Strings | N/A | No hay UI nueva; pero si se agrega un label o tooltip, usar ARB |
| dart analyze | Gate obligatorio | — |
| Test unitario | REQUERIDO | Test: `fetchEvents()` sin filtros envía `dateFrom` con fecha de hoy. Test: `fetchEvents()` con `filters.startDate` manual envía `filters.startDate`, no el piso automático. |

**Riesgo de regresión:** El método `clearFilters()` llama `fetchEvents()` después de resetear `_filters`. Al resetear, `_filters.startDate` queda `null`, por lo que el piso automático se vuelve a aplicar — comportamiento correcto. Verificar que el test de `clearFilters` también cubre este path.

### Fase 3 — Backend Cron

| Regla | Estado | Detalle |
|---|---|---|
| Clean Architecture backend | VERIFICAR | `forceEndTracking` no debe tener ruta HTTP expuesta; solo MessagePattern interno. |
| Owner-check bypass | RIESGO ALTO | `forceEndTracking` en `events-ms` debe ser solo invocable via RPC desde `api-gateway`; sin endpoint HTTP. Debe documentarse en el PR. |
| Stale in-memory rooms | REQUERIDO | El plan debe incluir llamada a `TrackingService.removeRoom(eventId)` después de `broadcastEventEnded` en el cron. Si no existe `removeRoom`, crearlo. |
| FCM extracción | REQUERIDO | `sendEventEndedNotifications` debe extraerse a un servicio compartido (`EventNotificationsService` o similar) para que el cron lo invoque sin duplicar lógica. Alternativa inline aceptable solo si se documenta como deuda técnica con un TODO explícito. |
| Idempotencia del cron | REQUERIDO | Verificar estado IN_PROGRESS antes de proceder. Un evento que ya pasó a FINISHED por el endpoint normal no debe procesarse dos veces. |
| Tests backend | REQUERIDO | Test unitario del cron: mock de `findActiveEventsOlderThan`, verificar que llama `forceEndTracking` + `broadcastEventEnded` + FCM por cada evento. |

---

## Riesgos de scope

### Riesgo 1 — `leaveSession` no está en `TrackingRepository` (Fase 1)

**Severidad:** Alta — puede forzar una violación de Clean Architecture si el implementador inyecta `TrackingWsClient` directamente en el cubit.

**Mitigación:** Agregar `leaveSession(String eventId, String userId)` a la interfaz `TrackingRepository` (domain) y en `TrackingRepositoryImpl` (data) que delega a `TrackingWsClient`. Esto es un cambio de contrato de dominio de 2-3 líneas pero debe estar en el plan de Fase 1.

### Riesgo 2 — Orden de operaciones en cleanup (Fase 1)

**Severidad:** Media — si `emit(isFinished: true)` ocurre antes de cancelar `_positionSubscription`, el GPS puede entregar un ping más que intenta llamar `_updateLocationUseCase` con `state.isTracking == false`, causando una llamada innecesaria al backend.

**Mitigación:** Cancelar suscripciones ANTES de emitir.

### Riesgo 3 — `_applyFiltersAndEmit` emite `ResultState.initial()` (Fase 2)

**Severidad:** Media — `_applyFiltersAndEmit` emite `ResultState.initial()` al inicio de cada llamada. Si `fetchEvents` llama a `_applyFiltersAndEmit` y este emite `initial` + `data` en secuencia rápida, el UI puede parpadear brevemente. Esto es un bug preexistente no introducido por esta fase, pero el plan debe documentarlo para no confundir al revisor.

**Mitigación:** No tocar en esta fase. Documenter como deuda técnica existente.

### Riesgo 4 — `forceEndTracking` como vector de escalada de privilegios (Fase 3)

**Severidad:** Alta — si por error se agrega una ruta HTTP a `forceEndTracking` (como pasa a veces al copiar el patrón del controller), cualquier usuario puede finalizar cualquier evento.

**Mitigación:** Fase 3 debe incluir un test de integración o al menos una aserción de que no existe ruta HTTP para el nuevo endpoint. El MessagePattern debe ser distinguible (`'events.forceEndTracking'`) y no mezclarse con los patterns expuestos al cliente.

### Riesgo 5 — Cron concurrencia (Fase 3)

**Severidad:** Baja — señalada por el PO. Agregar un flag booleano `_isRunning` al método del cron es suficiente para v1.

### Riesgo 6 — `startDate` vs `startDate >= now - 24h` en el cron (Fase 3)

**Severidad:** Media — el cron usa `startDate <= now - 24h` como cutoff. Pero si un evento empieza a las 22:00 y el cron corre a las 22:30 del día siguiente (25.5h después), el evento se finaliza correctamente. Si el cron corre a las 21:30 (23.5h después), el evento sobrevive otra hora. Esto es comportamiento esperado para v1 pero debe estar documentado en el plan.

---

## Ajustes mandatorios al plan

### A1 — Fase 1: Agregar `leaveSession` a `TrackingRepository` (dominio)

El plan de Fase 1 debe incluir explícitamente:
- Agregar `Future<void> leaveSession({required String eventId, required String userId})` a `lib/features/events/domain/repository/tracking_repository.dart`.
- Implementar en `TrackingRepositoryImpl` delegando a `TrackingWsClient.leaveSession()`.
- Inyectar el repositorio (no el cliente WS) en `LiveTrackingCubit` — ya está inyectado como `_trackingRepository`; solo falta el método en la interfaz.

### A2 — Fase 1: Orden de operaciones crítico

El plan debe especificar el orden exacto en `_subscribeToEventEnded`:
1. `_logSessionEnded` (analytics, solo si `state.isTracking`)
2. `await _positionSubscription?.cancel()` + `_positionSubscription = null`
3. `await _stopTrackingUseCase(eventId, userId)` (solo si `state.isTracking && _userId != null`)
4. `await _trackingRepository.leaveSession(eventId, userId)` (solo si `_userId != null`)
5. `emit(state.copyWith(isFinished: true, isTracking: false))`

### A3 — Fase 1: Test debe cubrir doble-conteo analytics

El test unitario de Fase 1 debe verificar que si `_eventEndedSubscription` dispara y luego `close()` se llama, `_logSessionEnded` se invoca exactamente una vez (el flag `_sessionEndLogged` lo previene).

### A4 — Fase 2: Documentar que `myEvents` no recibe el piso automático

El plan de Fase 2 debe especificar explícitamente que el constructor `EventsCubit.myEvents` no envía `dateFrom` — esto es intencional porque el usuario necesita ver sus propios eventos pasados en "Mis eventos".

### A5 — Fase 2: Timezone — usar fecha local, no UTC

Especificar en el plan de Fase 2: `dateFrom` se calcula como `DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10)` donde `now = DateTime.now()` (local). No usar `DateTime.now().toUtc()` para este cálculo.

### A6 — Fase 3: Incluir `TrackingService.removeRoom` en el alcance

El plan de Fase 3 debe listar explícitamente la limpieza de in-memory rooms como parte del cron: después de `broadcastEventEnded(eventId)`, llamar `this.trackingService.removeRoom(eventId)`. Si `removeRoom` no existe en `TrackingService`, debe crearse.

### A7 — Fase 3: Extraer FCM a servicio compartido

El plan debe especificar si se extrae `sendEventEndedNotifications` a un servicio compartido o se acepta inline con deuda técnica documentada. Ambas son aceptables; lo inaceptable es dejar la decisión al implementador sin guía.

---

## Resumen de veredicto

El plan está bien fundamentado, el scan es exhaustivo, y los tres fixes están correctamente identificados y dimensionados. Las fases son independientes y verificables. Los ajustes A1–A7 son requeridos antes de que los agentes de ejecución escriban el código; ninguno requiere replantear las fases.

**Orden de ejecución recomendado (sin cambio respecto al PO):** 1 → 2 → 3.

**Bloqueos pre-ejecución:**
- A1 y A2 deben estar resueltos en el plan de Fase 1 antes de que el implementador toque el cubit.
- A6 y A7 deben estar resueltos en el plan de Fase 3.
