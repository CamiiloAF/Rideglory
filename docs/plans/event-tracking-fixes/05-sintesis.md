# 05-sintesis.md — Plan Consolidado (PO)

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:16:19Z
**Veredicto de entradas:** Architect → ok_con_ajustes | Plan Reviewer → ok_con_ajustes
**Corrección Auditor Opus:** aplicada (ver sección "Correcciones de segunda ronda")

---

## Overview

Tres fixes coordinados para cerrar brechas en el ciclo de vida de las rodadas en vivo:

1. **Fase 1 (Flutter):** Cuando el backend emite `tracking.event.ended`, el cubit de tracking no cancela el GPS ni cierra la conexión WS — emite `isFinished: true` de inmediato sin hacer ningún cleanup. La corrección modifica `_subscribeToEventEnded()` para ejecutar el cleanup completo (GPS + stop via use case + emit) en el orden correcto. **No se agrega un método `leaveSession` al dominio:** `TrackingRepositoryImpl.stopTracking` (líneas 94-105) ya llama `_trackingWsClient.leaveSession(eventId, userId)` antes de `stopSession`, por lo que invocar `_stopTrackingUseCase` en el cleanup es suficiente para cerrar el WS. Incluye test unitario cubriendo el path y el doble-conteo de analytics.

2. **Fase 2 (Flutter):** El listado público de eventos muestra eventos pasados porque `EventsCubit.fetchEvents()` no envía `dateFrom`. Se agrega un piso automático de "medianoche local de hoy" cuando el usuario no aplica filtro manual. `EventsCubit.myEvents` permanece sin cambio (intencional, ver supuestos). Incluye tests unitarios.

3. **Fase 3 (Backend):** Rodadas que el organizador olvidó cerrar permanecen `IN_PROGRESS` indefinidamente. Se agrega un cron horario en `NotificationSchedulerService` (api-gateway) que encuentra eventos `IN_PROGRESS` con `startDate <= now - 24h`, los cierra via RPC interno a events-ms (`forceEndTracking`), hace broadcast WS y envía FCM. `forceEndTracking` es idempotente, no tiene endpoint HTTP, y `sendEventEndedNotifications` se extrae a `TrackingNotificationsService` compartido.

**Orden de despliegue obligatorio: Fase 1 → Fase 2 → Fase 3.** Fase 3 depende de Fase 1 para que los riders se desconecten limpiamente cuando reciben el broadcast del cron. Fases 1 y 2 son mutuamente independientes pero se ejecutan en este orden por nivel de riesgo ascendente.

---

## Correcciones de segunda ronda (Auditor Opus)

El Auditor Opus identificó cuatro discrepancias entre el plan y la implementación real. Quedan resueltas así:

### C1 — Fase 1: `stopTracking` ya llama `leaveSession` internamente

**Hallazgo:** `TrackingRepositoryImpl.stopTracking()` (líneas 94-105 de `tracking_repository_impl.dart`) ya invoca `_trackingWsClient.leaveSession(eventId, userId)` ANTES de llamar `stopSession`. El plan anterior proponía agregar `leaveSession` como método nuevo en `TrackingRepository` (dominio) y llamarlo como paso 4 independiente del cleanup. Esto crearía una segunda llamada a `leaveSession` innecesaria — y la primera ya ocurre dentro de `_stopTrackingUseCase`.

**Decisión adoptada — Opción A:** NO se agrega `leaveSession` al contrato de dominio. Se confía en que `_stopTrackingUseCase` ya cierra el WS como parte de su contrato (`stopTracking = leaveSession WS + stopSession HTTP`). El orden de cleanup se reduce a 4 pasos (ver Fase 1 detalle). Esto elimina los ajustes arch-1, A1 del plan anterior.

**Justificación:** `leaveSession` en `TrackingWsClient` setea `_manualDisconnect = true` y cierra el canal. Si `_stopTrackingUseCase` falla (evento ya FINISHED → HTTP 4xx), `executeService` devuelve `Left` pero el `leaveSession` WS YA fue ejecutado antes del fallo HTTP (línea 100 antes de línea 101). Por tanto, el WS se cierra correctamente incluso cuando el use case retorna `Left`. No hay gap de cleanup.

**Sobre idempotencia de `leaveSession`:** el cliente WS ya verifica `_manualDisconnect` antes de intentar reconexión. Llamadas extra no rompen nada, pero son innecesarias y deben evitarse para mantener el código legible.

### C2 — Fase 1: Orden de cleanup corregido a 4 pasos

El orden anterior (5 pasos) incluía un paso 4 redundante (`_trackingRepository.leaveSession`). El orden correcto es:

```
1. _logSessionEnded(endReasonEventEnded)   // solo si state.isTracking
2. await _positionSubscription?.cancel(); _positionSubscription = null
3. if (state.isTracking && _userId != null)
     await _stopTrackingUseCase(eventId: _eventId, userId: _userId!)
       .fold((_) => null, (_) => null)    // fold sin relanzar; WS ya cerrado en paso 3a
4. emit(state.copyWith(isTracking: false, isFinished: true))
```

El test unitario debe verificar que en el path `eventEnded` el WS client (`leaveSession`) se invoca exactamente 1 vez — vía `_stopTrackingUseCase` internamente — y no más.

### C3 — Fase 2: Edge case R7 resuelto explícitamente

**Hallazgo:** El plan anterior mencionaba "una ruta distinta" para ver eventos `IN_PROGRESS` iniciados ayer, sin nombrarla. Esto deja al implementador sin criterio verificable.

**Decisión adoptada:** El listado general de eventos (`EventsPage` via `EventsCubit.fetchEvents()`) **no debe mostrar rodadas en progreso ajenas al rider**. El backend ya filtra `IN_PROGRESS` para no-participantes. Para el rider participante de una rodada que comenzó ayer, el punto de entrada correcto es la **pantalla de live tracking** accesible desde la notificación FCM o desde el detalle del evento (ruta existente: `/events/:id/tracking`). El listado general no es la ruta para entrar a una rodada en curso; es un descubrimiento de rodadas futuras. Por tanto, excluir esos eventos del listado via `dateFrom = hoy` es UX correcta. No se requiere mitigación client-side en `_applyFiltersAndEmit`.

### C4 — Fase 3: `removeRoom` vs auto-limpieza de `removeClient`

**Hallazgo:** `TrackingRoomsService.removeClient()` ya borra el `Set` cuando `set.size === 0` (línea 23-24 del servicio). No existe ningún método `removeRoom` en la clase. El ajuste A6 del Plan Reviewer pedía crearlo; el Architect (Gap 4) concluía que no era necesario.

**Decisión adoptada:** **`removeRoom` explícito NO se incluye en el alcance de Fase 3.** Su ausencia no rompe nada: cuando el cron llama `broadcastEventEnded(eventId)`, los riders WS reciben el evento y (gracias a Fase 1) se desconectan, disparando `handleDisconnect → removeClient()`, que auto-limpia el room cuando el último cliente se va. El A6 del Plan Reviewer queda descartado porque su premisa ("si `removeRoom` no existe, crearlo") es innecesaria dado el comportamiento existente. Si en un futuro se requiere limpieza sincrónica inmediata del room sin esperar desconexiones individuales, ese es el momento de agregar `removeRoom`; no ahora.

---

## Cambios aplicados (ajustes vigentes post corrección)

Los siguientes ajustes del Architect (03) y Plan Reviewer (04) quedan integrados, con las correcciones de segunda ronda aplicadas:

| ID | Origen | Estado | Ajuste integrado |
|----|--------|--------|-----------------|
| arch-1 | Architect | **DESCARTADO (C1)** | ~~Fase 1: `leaveSession` se agrega como método abstracto a `TrackingRepository`~~ — ya ocurre dentro de `stopTracking`. |
| arch-2 | Architect | **MODIFICADO (C2)** | Fase 1: Orden de cleanup en `_subscribeToEventEnded` reducido a 4 pasos. La emisión de UI va al final. |
| arch-3 | Architect | VIGENTE | Fase 2: `dateFrom` usa `DateTime.now()` local truncado a medianoche local. Nunca `.toUtc()`. |
| arch-4 | Architect | VIGENTE | Fase 3: `sendEventEndedNotifications` se extrae a `TrackingNotificationsService` inyectable. |
| arch-5 | Architect | VIGENTE | Fase 3: `forceEndTracking` en events-ms es idempotente. |
| arch-6 | Architect | VIGENTE | Fase 3: MessagePattern `forceEndTracking` sin endpoint HTTP; comentario `// INTERNAL ONLY`. |
| arch-7 | Architect | VIGENTE | Orden de despliegue obligatorio: Fase 1 → Fase 2 → Fase 3. |
| A1 | Plan Reviewer | **DESCARTADO (C1)** | ~~Agregar `leaveSession` a la interfaz de dominio~~ — ya cubierto por `stopTracking`. |
| A2 | Plan Reviewer | **MODIFICADO (C2)** | Orden de operaciones en `_subscribeToEventEnded`: 4 pasos (no 5). Guards: `state.isTracking`, `_userId != null`. |
| A3 | Plan Reviewer | VIGENTE | Test unitario verifica que `_logSessionEnded` se invoca exactamente una vez aunque `eventEnded` dispare y luego `close()` sea llamado. Test también verifica que `leaveSession` del WS client es invocado exactamente 1 vez (via `_stopTrackingUseCase`). |
| A4 | Plan Reviewer | VIGENTE | `EventsCubit.myEvents` NO recibe el piso automático de `dateFrom`. UX intencional. |
| A5 | Plan Reviewer | VIGENTE | `DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10)` donde `now = DateTime.now()` (local). |
| A6 | Plan Reviewer | **DESCARTADO (C4)** | ~~`TrackingService.removeRoom(eventId)` después de `broadcastEventEnded`~~ — `removeClient` auto-limpia rooms vacíos; `removeRoom` no es necesario. |
| A7 | Plan Reviewer | VIGENTE | Decisión explícita: extraer `sendEventEndedNotifications` a `TrackingNotificationsService` (no inline con TODO). |

---

## Lista final de fases

| # | Título | Dependencias | Nivel | Por qué ese nivel |
|---|--------|-------------|-------|-------------------|
| 1 | WS Cleanup on Event End (Flutter) | — | **normal** | Toca lógica crítica de cleanup en el cubit con orden de operaciones exacto que importa (GPS post-emit vs. pre-emit). Requiere test unitario cubriendo paths de doble-conteo y verificación de llamadas al WS client. Sin contratos nuevos ni migraciones. Riesgo medio: un orden incorrecto causa pings GPS al backend de eventos FINISHED. |
| 2 | Event List Date Filter (Flutter) | — | **lite** | Cambio mecánico en una sola expresión en `EventsCubit.fetchEvents()`. Sin cambios de contrato API, sin UI nueva, sin migraciones. El riesgo de timezone está mitigado explícitamente. Reversible inmediatamente. |
| 3 | Auto-End Events After 24 Hours (Backend) | 1 | **full** | Cambios cross-repo (api-gateway + events-ms), nuevos MessagePatterns RPC, nuevo servicio inyectable (`TrackingNotificationsService`), cron con efectos secundarios sobre FCM y estado de base de datos. Riesgo de seguridad real (`forceEndTracking` sin owner check). Requiere idempotencia, guard de concurrencia, y coordinación de despliegue. Alto blast radius si el cron procesa mal un evento. |

### Detalle por fase

#### Fase 1 — WS Cleanup on Event End (Flutter)

**Goal:** Cuando `tracking.event.ended` llega via WS, el cubit de tracking cancela el GPS, invoca `_stopTrackingUseCase` (que internamente cierra el WS via `leaveSession`), y emite `isFinished: true`, en ese orden, sin fugas de recursos.

**Premisa verificada en código:**
`TrackingRepositoryImpl.stopTracking()` (líneas 94-105) ejecuta `_trackingWsClient.leaveSession(eventId, userId)` ANTES de `_trackingService.stopSession(...)`. Si `stopSession` falla (evento ya FINISHED), el WS ya fue cerrado en el paso anterior. No se agrega ningún método nuevo al contrato de dominio.

**Summary:**
- Modificar `LiveTrackingCubit._subscribeToEventEnded()` (línea 546) con el siguiente orden exacto:
  1. `if (state.isTracking) _logSessionEnded(AnalyticsParams.trackingEndReasonEventEnded)` — analytics antes de mutar estado.
  2. `await _positionSubscription?.cancel(); _positionSubscription = null` — cancelar GPS.
  3. `if (state.isTracking && _userId != null) { await _stopTrackingUseCase(eventId: _eventId, userId: _userId!).fold((_) => null, (_) => null); }` — cierra WS + HTTP stop; fold sin relanzar si el evento ya es FINISHED.
  4. `emit(state.copyWith(isTracking: false, isFinished: true))` — UI al final, después de todo el cleanup.
- Nuevo archivo de test `live_tracking_cubit_event_ended_test.dart` verificando:
  - Cleanup ejecutado en el orden correcto (GPS cancelado antes del emit).
  - `_stopTrackingUseCase` llamado exactamente 1 vez; el mock de `TrackingWsClient` interno verifica que `leaveSession` se llama exactamente 1 vez via ese use case.
  - `_logSessionEnded` llamado exactamente 1 vez aunque `eventEnded` dispare y luego `close()` sea llamado (path de doble-disparo via `_sessionEndLogged`).
  - Estado emitido: `isTracking: false, isFinished: true`.
- Gate: `dart analyze` sin nuevas violaciones; `flutter test` verde.

**Nivel:** normal — lógica de orden crítico + test de doble-path + riesgo medio de regresión en flujo de GPS.

---

#### Fase 2 — Event List Date Filter (Flutter)

**Goal:** El listado público de eventos muestra solo eventos de hoy en adelante por defecto, usando la hora local del dispositivo.

**Summary:**
- En `EventsCubit.fetchEvents()`, cuando `_filters.startDate == null`, calcular:
  ```dart
  final now = DateTime.now(); // hora local del dispositivo — NUNCA .toUtc()
  final dateFrom = DateTime(now.year, now.month, now.day)
      .toIso8601String()
      .substring(0, 10); // "YYYY-MM-DD" medianoche local
  ```
  Pasar `dateFrom` al backend solo cuando no hay filtro manual del usuario.
- El constructor `EventsCubit.myEvents` NO se modifica: muestra todos los eventos del owner incluyendo pasados (UX intencional — el organizador necesita su historial completo).
- El filtro local `_applyFiltersAndEmit` no se modifica: el piso aplica solo al parámetro enviado al backend, no al filtrado en memoria.
- Sobre eventos `IN_PROGRESS` iniciados ayer (edge case R7): el listado general no es el punto de entrada para rodadas en curso. El rider accede a una rodada en progreso desde la notificación FCM o desde el detalle del evento (`/events/:id/tracking`). Excluir esos eventos del listado via `dateFrom = hoy` es UX correcta; no se requiere mitigación client-side adicional.
- Tests unitarios: (a) sin filtro manual → `dateFrom` = hoy local; (b) con `filters.startDate` manual → `dateFrom` = filtro del usuario, no el piso; (c) `clearFilters()` → piso automático se restablece; (d) `EventsCubit.myEvents.fetchEvents()` → no envía `dateFrom`.
- Gate: `dart analyze` sin nuevas violaciones; `flutter test` verde.

**Nivel:** lite — cambio mecánico en una sola función, sin contratos API nuevos, sin UI, reversible.

---

#### Fase 3 — Auto-End Events After 24 Hours (Backend)

**Goal:** Rodadas `IN_PROGRESS` con `startDate <= now - 24h` son cerradas automáticamente por un cron horario; los riders reciben FCM y el WS broadcast desconecta los clientes activos.

**Summary:**

**events-ms:**
- Nuevo método `findActiveEventsOlderThan(cutoffDate: Date)` en `EventsService`: query Prisma `state == IN_PROGRESS && startDate <= cutoffDate`. Nuevo MessagePattern `'findActiveEventsOlderThan'` en `EventsController` (campo `cutoffDate` como string ISO en payload).
- Nuevo método `forceEndTracking(eventId: string)` en `EventsService`: verifica `state !== IN_PROGRESS`, retorna `{ id, state }` sin error si ya es FINISHED (idempotente), de lo contrario hace UPDATE a `FINISHED`. Nuevo MessagePattern `'forceEndTracking'` en `EventsController` con comentario `// INTERNAL ONLY — no HTTP endpoint`. Usar `startDate` como criterio de antigüedad en `findActiveEventsOlderThan` (no `createdAt` ni `updatedAt`).

**api-gateway:**
- Nuevo `TrackingNotificationsService` (`@Injectable`): extrae la lógica de `sendEventEndedNotifications` de `TrackingHttpController`. Firma: `async sendEventEndedNotifications(eventId: string): Promise<void>`. Inyectado en `TrackingHttpController` (reemplaza el método privado actual) y en `NotificationSchedulerService` (nuevo uso).
- En `NotificationSchedulerService`, nuevo método `autoEndStalledEvents()` decorado con `@Cron('0 * * * *', { timeZone: 'America/Bogota' })`. Flujo por cada evento encontrado:
  1. `forceEndTracking(eventId)` via events-ms client (RPC interno).
  2. `broadcastEventEnded(eventId)` via `TrackingBroadcaster`.
  3. `trackingNotificationsService.sendEventEndedNotifications(eventId)`.
  4. Log del resultado por evento.
- Guard de concurrencia: flag `_autoEndRunning: boolean` en la instancia para v1 (proceso single-instance; no se necesita lock distribuido).

**Sobre limpieza de rooms en memoria:** `TrackingRoomsService.removeClient()` ya auto-limpia el room cuando `set.size === 0` (comportamiento existente, línea 23-24). Cuando el cron llama `broadcastEventEnded`, los riders se desconectan via Fase 1, disparando `removeClient()` que elimina el room. No se requiere `removeRoom` explícito. Si en el futuro se necesita limpieza inmediata sin esperar desconexiones individuales, ese es el momento de agregar ese método.

**Restricción de seguridad:** Ningún endpoint HTTP en `TrackingHttpController` para `forceEndTracking`. El MessagePattern es TCP-only entre api-gateway y events-ms. Verificar en code review que no existe ruta HTTP para este pattern. Agregar test de integración o aserción que verifique ausencia de ruta HTTP.

**Tests:** Test unitario del cron con mocks de `findActiveEventsOlderThan`, `forceEndTracking`, `broadcastEventEnded`, y FCM. Verificar idempotencia (`forceEndTracking` con evento ya FINISHED no hace UPDATE). Verificar guard de concurrencia (`_autoEndRunning` previene solapamiento).

**Gate:** Tests backend verdes. El gate de Fase 1 (`flutter test` verde) debe estar cumplido antes de desplegar Fase 3.

**Prerrequisito de despliegue:** Fase 1 debe estar desplegada antes de Fase 3. Sin Fase 1, el cron emite el broadcast pero los riders no cancelan GPS ni cierran WS.

**Nivel:** full — cambios cross-repo, RPC interno nuevo, servicio nuevo inyectable, riesgo de seguridad (owner-check bypass), efectos sobre FCM y DB, coordinación de despliegue.

---

## Supuestos y riesgos

### Supuestos

- `EventState.IN_PROGRESS` es el único estado de rodada activa. Eventos en `SCHEDULED`, `DRAFT`, `CANCELLED` o `FINISHED` nunca son tocados por el cron de auto-cierre.
- La ventana de 24 horas es decisión de producto fija para v1. No requiere configuración via env-var.
- Todos los eventos son de un solo día. No existen rodadas multi-día que deban sobrevivir más de 24 h desde su `startDate`.
- La home screen `findUpcoming` ya filtra eventos futuros correctamente y no requiere cambio.
- El backend `GET /api/events?dateFrom=` ya aplica el filtro server-side y es estable. No es un cambio de contrato para Fase 2.
- `TrackingWsClient.leaveSession()` ya setea `_manualDisconnect = true` y cierra el canal correctamente — confirmado en scan previo.
- `TrackingRoomsService.removeClient()` ya borra el `Set` del room cuando `size === 0`. `removeRoom` explícito no es necesario y no se implementa en esta iteración.
- El cron corre en un proceso single-instance (no hay réplicas del scheduler). El flag `_autoEndRunning` es suficiente para v1; no se necesita lock distribuido.
- `EventsCubit.myEvents` usa `GetMyEventsUseCase` que no acepta `dateFrom`. La decisión de no filtrar "mis eventos" por fecha es intencional: el organizador debe ver su historial completo.
- El listado general de eventos no es el punto de entrada para rodadas `IN_PROGRESS` en curso. El acceso a una rodada activa iniciada ayer ocurre via notificación FCM o detalle de evento (`/events/:id/tracking`).

### Riesgos

| ID | Fase | Severidad | Descripción | Mitigación |
|----|------|-----------|-------------|------------|
| R1 | 3 | Alta | `forceEndTracking` expuesto accidentalmente por HTTP — cualquier usuario autenticado podría finalizar la rodada de otro. | Comentario `// INTERNAL ONLY`, sin ruta HTTP en api-gateway, verificación en code review. |
| R2 | 3 | Media | Fase 3 desplegada sin Fase 1: riders siguen enviando ubicaciones a eventos FINISHED. | Orden de despliegue obligatorio: 1 → 2 → 3. Documentado en handoff de QA de Fase 3. |
| R3 | 2 | Baja | Si se usa UTC en `dateFrom`, un rider en UTC-5 ve hasta 5 horas de eventos pasados. | `DateTime.now()` local + `DateTime(y, m, d)`. Especificado explícitamente en el plan de Fase 2. |
| R4 | 1 | Baja | `_stopTrackingUseCase` puede retornar `Left` si el evento ya es FINISHED en backend. | `leaveSession` del WS ya ocurre dentro de `stopTracking` ANTES de la llamada HTTP. El fold captura el Left; cleanup WS y emit de UI ocurren correctamente. |
| R5 | 1 | Baja | Doble-conteo de analytics si `eventEnded` dispara y `close()` llama después en la misma ejecución. | Flag `_sessionEndLogged` ya existe. Test unitario verifica este path explícitamente (A3). |
| R6 | 3 | Baja | Cron concurrente si un run tarda >1h. | Flag `_autoEndRunning: boolean` en la instancia para v1. |
| R7 | 2 | Bajo | Edge case: evento `IN_PROGRESS` iniciado justo antes de medianoche no aparece en el listado con `dateFrom = hoy`. | UX aceptable: el rider accede via notificación FCM o detalle directo. El listado general es para descubrimiento de rodadas futuras. Documentado como comportamiento esperado (no deuda). |
| R8 | 2 | Media | `_applyFiltersAndEmit` emite `ResultState.initial()` al inicio causando parpadeo breve en UI. | Bug preexistente no introducido por esta fase. No tocar en Fase 2. Deuda técnica existente. |
