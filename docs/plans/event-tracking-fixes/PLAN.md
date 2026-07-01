# Plan: event-tracking-fixes
> Estado: BORRADOR — revision humana pendiente. Generado: 2026-06-20T00:34:32Z

## Overview

Tres fixes coordinados para cerrar brechas en el ciclo de vida de las rodadas en vivo. La corrección de Auditor Opus resolvió cuatro discrepancias entre el plan y la implementación real: (C1) `stopTracking` ya llama `leaveSession` internamente — no se agrega ningún método nuevo al dominio; (C2) el orden de cleanup se reduce a 4 pasos, no 5; (C3) el edge case R7 de eventos `IN_PROGRESS` iniciados ayer queda resuelto declarando que el listado general no es el punto de entrada para rodadas en curso (esa ruta es `/events/:id/tracking` via FCM); (C4) `removeRoom` explícito no es necesario porque `removeClient` ya auto-limpia rooms vacíos. Orden de despliegue obligatorio: Fase 1 → Fase 2 → Fase 3.

## Fases

- Fase 1 [NORMAL]: [Fase 1 — WS Cleanup on Event End (Flutter)](phases/phase-01-ws-cleanup-on-event-end-flutter.md)
- Fase 2 [LITE]: [Fase 2 — Event List Date Filter (Flutter)](phases/phase-02-event-list-date-filter-flutter.md)
- Fase 3 [FULL]: [Fase 3 — Auto-End Events After 24 Hours (Backend)](phases/phase-03-auto-end-events-after-24-hours-backend.md)

## Supuestos

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

## Riesgos

| ID | Fase | Severidad | Descripción | Mitigación |
|----|------|-----------|-------------|------------|
| R1 | 3 | Alta | `forceEndTracking` expuesto accidentalmente por HTTP — cualquier usuario autenticado podría finalizar la rodada de otro. | Comentario `// INTERNAL ONLY`, sin ruta HTTP en api-gateway, verificación en code review. |
| R2 | 3 | Media | Fase 3 desplegada sin Fase 1: riders siguen enviando ubicaciones a eventos FINISHED. | Orden de despliegue obligatorio: 1 → 2 → 3. Documentado en handoff de QA de Fase 3. |
| R3 | 2 | Baja | Si se usa UTC en `dateFrom`, un rider en UTC-5 ve hasta 5 horas de eventos pasados. | `DateTime.now()` local + `DateTime(y, m, d)`. Especificado explícitamente en el plan de Fase 2. |
| R4 | 1 | Baja | `_stopTrackingUseCase` puede retornar `Left` si el evento ya es FINISHED en backend. | `leaveSession` del WS ya ocurre dentro de `stopTracking` ANTES de la llamada HTTP. El fold captura el Left; cleanup WS y emit de UI ocurren correctamente. |
| R5 | 1 | Baja | Doble-conteo de analytics si `eventEnded` dispara y `close()` llama después en la misma ejecución. | Flag `_sessionEndLogged` ya existe. Test unitario verifica este path explícitamente (A3). |
| R6 | 3 | Baja | Cron concurrente si un run tarda >1h. | Flag `_autoEndRunning: boolean` en la instancia para v1. |
| R7 | 2 | Baja | Edge case: evento `IN_PROGRESS` iniciado justo antes de medianoche no aparece en el listado con `dateFrom = hoy`. | UX aceptable: el rider accede via notificación FCM o detalle directo. El listado general es para descubrimiento de rodadas futuras. Documentado como comportamiento esperado (no deuda). |
| R8 | 2 | Media | `_applyFiltersAndEmit` emite `ResultState.initial()` al inicio causando parpadeo breve en UI. | Bug preexistente no introducido por esta fase. No tocar en Fase 2. Deuda técnica existente. |

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):

```
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-tracking-fixes/phases/phase-01-ws-cleanup-on-event-end-flutter.md', mode: 'normal' } })
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-tracking-fixes/phases/phase-02-event-list-date-filter-flutter.md', mode: 'lite' } })
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/event-tracking-fixes/phases/phase-03-auto-end-events-after-24-hours-backend.md', mode: 'full' } })
```

> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
