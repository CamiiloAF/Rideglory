# 00-intake.md

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:03:21Z

---

## Fuente

Objetivo ingresado directamente como texto literal por el usuario (sin archivo existente).

---

## Objetivo

Tres correcciones relacionadas con eventos y tracking en vivo:

1. **Fix WebSocket al finalizar evento (Flutter):** Cuando llega `tracking.event.ended` en `LiveTrackingCubit._subscribeToEventEnded`, actualmente solo emite `isFinished: true` pero no detiene el GPS ni cierra el socket. El auto-reconnect del `TrackingWsClient` (Timer de 2s en `_onDisconnected`) queda activo. Fix: al recibir `event.ended`, el cubit debe: cancelar `_positionSubscription`, llamar `_stopTrackingUseCase`, y llamar `leaveSession` en el WsClient.

2. **Auto-finalización de eventos tras 24 horas (Backend):** Si el organizador olvida finalizar una rodada, el evento queda activo indefinidamente. Implementar un job/cron en `rideglory-api` que busque eventos con `startDate` >= 24 horas en el pasado y aún en estado activo, los finalice automáticamente (misma lógica que el endpoint manual, incluyendo broadcast `tracking.event.ended` y FCM a participantes).

3. **Filtro de eventos por fecha (Flutter):** Se cargan todos los eventos sin importar la fecha, incluyendo eventos pasados. Filtrar para que solo se carguen eventos con `startDate` >= inicio del día actual. Buscar en `lib/features/events/` y `lib/features/home/`.

---

## Alcance percibido

### Flutter (Rideglory app)

- **Fase 1 – Fix LiveTrackingCubit (WebSocket cleanup):**
  - `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart`: modificar `_subscribeToEventEnded` para cancelar `_positionSubscription`, invocar `_stopTrackingUseCase.call()`, y llamar `_wsClient.leaveSession()` antes de emitir `isFinished: true`.
  - `lib/features/events/data/service/tracking_ws_client.dart`: verificar que `leaveSession` ya setea `_manualDisconnect = true` y cierra el canal correctamente.
  - `lib/features/events/domain/use_cases/stop_tracking_use_case.dart`: revisar contrato del use case.
  - Tests unitarios del cubit si existen.

- **Fase 3 – Filtro de eventos por fecha:**
  - `lib/features/events/`: identificar repositorio, use case y cubit que carga la lista de eventos.
  - `lib/features/home/`: identificar dónde se llama la carga de eventos para el home.
  - Determinar si el backend soporta parámetro de fecha en el endpoint de listado; si no, filtrar en la capa de presentación o repositorio.
  - Agregar parámetro `startDateFrom` (inicio del día actual) o filtrar localmente con `where((e) => e.startDate.isAfter(startOfToday))`.

### Backend (rideglory-api)

- **Fase 2 – Auto-finalización de eventos (cron):**
  - Identificar el microservicio responsable de estado de eventos (probablemente `events-ms`).
  - Verificar si existe un scheduler NestJS (`@nestjs/schedule`) o si hay que añadirlo.
  - Implementar `@Cron` que corre cada hora, busca eventos activos con `startDate` <= now - 24h, los finaliza con la misma lógica que el endpoint manual.
  - Incluir: broadcast `tracking.event.ended` a rooms de WS conectados y notificación FCM a participantes.
  - Considerar idempotencia (no finalizar eventos ya finalizados) y manejo de errores por evento.

---

## Preguntas abiertas

1. **Endpoint de filtro por fecha en el backend:** ¿El endpoint de listado de eventos ya soporta un query param de fecha (`startDateFrom` o similar)? Si no existe, ¿se prefiere agregar el parámetro al backend (requiere coordinación con rideglory-api) o filtrar en el cliente Flutter?

2. **Estado "activo" de eventos:** ¿Qué valores exactos tiene el campo de estado de un evento en el backend (enum/string)? Por ejemplo: `active`, `in_progress`, `started`, etc. Esto afecta la query del cron.

3. **Microservicio del cron:** ¿El cron de auto-finalización debe vivir en `events-ms` o existe un microservicio dedicado a tareas programadas? ¿Ya hay `@nestjs/schedule` instalado en ese MS?

4. **FCM en el cron:** ¿El MS de eventos tiene acceso directo a FCM/notificaciones, o debe delegar a un notifications-ms via mensajería interna?

5. **Ventana de 24 horas:** ¿La ventana de 24 horas es fija o debe ser configurable (env var)? ¿Hay eventos de varios días que no deben auto-finalizarse?

6. **Tests:** ¿Se requieren tests unitarios para el cubit modificado (fix WS) y para el cron (backend)? ¿Existen tests existentes que cubran estos paths?
