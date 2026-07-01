# Architect handoff — Phase 02: Event List Date Filter

**Date:** 2026-06-20T01:53:25Z
**Status:** done

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| 1 | El cambio vive únicamente en `EventsCubit.fetchEvents()` | El PRD es explícito: solo capa de presentación. El parámetro `dateFrom` ya existe en `GetEventsUseCase`; solo cambia el valor que el cubit le pasa. |
| 2 | La fecha piso se calcula con `DateTime.now()` local (sin `.toUtc()`) | El criterio de aceptación exige hora local del dispositivo. Usar UTC desplazaría la fecha en zonas negativas. |
| 3 | El piso se aplica únicamente cuando `_isMyEvents == false` y `_filters.startDate == null` | `myEvents` no debe filtrar; el filtro manual del usuario tiene prioridad absoluta. |
| 4 | Formato de fecha: `.toIso8601String().substring(0, 10)` | Patrón idéntico al usado ya para `startDate` y `endDate` en la misma función. Consistencia garantizada sin imports nuevos. |
| 5 | No se introduce ningún import nuevo en `events_cubit.dart` | El tipo `DateTime` es core Dart; no se requiere ningún paquete adicional. |
| 6 | Los tests TC-2-1, TC-2-2 y TC-2-6 en `events_filter_cubit_test.dart` deben cambiar su stub de `dateFrom: null` a `dateFrom: any(named: 'dateFrom')` | Tras el cambio, el cubit siempre pasará una fecha string no nula cuando `_isMyEvents == false`; el stub `null` causaría `MissingStubError`. TC-2-2 filtra solo por tipo (startDate == null), por lo que también recibe el piso automático `dateFrom = hoy`. |
| 7 | Los tests TC-evlist-a1 y TC-evlist-a4 en `events_cubit_analytics_test.dart` deben actualizar su stub por la misma razón. | Mismo escenario: cubit llama `GetEventsUseCase` con `dateFrom != null`. |
| 8 | Nuevo archivo `test/features/events/presentation/list/events_cubit_date_filter_test.dart` con TC-df-1 a TC-df-4 | Cubre los cuatro escenarios del criterio de aceptación de forma aislada. |

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `lib/features/events/presentation/list/events_cubit.dart` | modify | Agregar piso `dateFrom` = hoy local en `fetchEvents()` cuando `!_isMyEvents && _filters.startDate == null` | low |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | modify | Actualizar stub TC-2-1, TC-2-2 y TC-2-6: `dateFrom: null` → `dateFrom: any(named: 'dateFrom')` | low |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | modify | Actualizar stub TC-evlist-a1, TC-evlist-a3, TC-evlist-a4, TC-evlist-a5, TC-evlist-a6: `dateFrom: null` → `dateFrom: any(named: 'dateFrom')` | low |
| `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | create | Cuatro tests nuevos TC-df-1 a TC-df-4 | low |

---

## Contratos

No hay cambios de contrato en rideglory-api. El parámetro `dateFrom` ya existe en `GET /api/events?dateFrom=yyyy-MM-dd`. El cliente Flutter simplemente pasará el valor siempre (en lugar de `null`) para el path de descubrimiento público.

---

## Datos / migraciones

Ninguno. No hay cambios de schema ni migraciones.

---

## Env

Ninguna variable de entorno nueva o modificada.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `MissingStubError` en tests existentes por el nuevo valor no-nulo de `dateFrom` | Actualizar stubs TC-2-1, TC-2-6, TC-evlist-a1 y TC-evlist-a4 a `any(named: 'dateFrom')`. Detallado en Change map. |
| TC-2-2 usa `dateFrom: null` en L89 con filtro de solo-tipo (`startDate == null`) → SÍ rompe | Verificado en código existente: L89 tiene `dateFrom: null`; tras el cambio, el cubit pasa `dateFrom = hoy`. Actualizar a `any(named: 'dateFrom')`. TC-2-3 usa `any(named: 'dateFrom')` → no rompe. |
| TC-2-5 (`clearFilters`) usa `any` en todos los params → no rompe | Verificado; no requiere cambio. |
| TC-evlist-a3 ya usa `dateFrom: null` con filtro de tipo → después del cambio, el cubit pasará `dateFrom` = hoy (no null) incluso con filtro de tipo | Actualizar stub de TC-evlist-a3 también a `any(named: 'dateFrom')`. Build debe incluirlo. |
| TC-evlist-a5 y TC-evlist-a6 usan `dateFrom: null` → rompen | Actualizar stubs a `any(named: 'dateFrom')`. Build debe incluirlos. |

> **Nota:** Tras revisión completa del código de `events_cubit_analytics_test.dart`, los tests TC-evlist-a3, TC-evlist-a5 y TC-evlist-a6 también tienen el stub con `dateFrom: null`. El Build debe actualizarlos todos.

---

## Orden de implementación

1. Modificar `events_cubit.dart` (lógica del piso de fecha).
2. Actualizar stubs en `events_filter_cubit_test.dart` (TC-2-1, TC-2-2, TC-2-6).
3. Actualizar stubs en `events_cubit_analytics_test.dart` (TC-evlist-a1, TC-evlist-a3, TC-evlist-a4, TC-evlist-a5, TC-evlist-a6).
4. Crear `events_cubit_date_filter_test.dart` (TC-df-1 a TC-df-4).
5. `dart analyze` + `flutter test` → 0 errores.

---

## Superficie de regresión

- `EventsCubit.fetchEvents()` en modo descubrimiento (no `myEvents`): ahora siempre envía `dateFrom != null`.
- `EventsCubit.myEvents.fetchEvents()`: sin cambio; sigue enviando `dateFrom: null`.
- `clearFilters()`: ahora el siguiente fetch envía hoy local, no null.
- Todos los tests de `events_filter_cubit_test.dart` y `events_cubit_analytics_test.dart` que stubbaban `dateFrom: null` para el path sin filtros.

---

## Fuera de alcance

- `_applyFiltersAndEmit()` — no se modifica.
- `GetEventsUseCase`, `EventRepository`, capa de datos — no se modifican.
- Backend `rideglory-api` — no se modifica.
- UI widgets de la pantalla de eventos — no se modifican.
- `EventsCubit.myEvents` — no cambia comportamiento.
- Manejo especial de `IN_PROGRESS` en listado general.
