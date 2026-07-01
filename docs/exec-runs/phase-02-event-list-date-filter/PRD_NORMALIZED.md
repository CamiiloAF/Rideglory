# PRD Normalizado — Phase 02: Event List Date Filter (Flutter)

**Slug:** phase-02-event-list-date-filter
**Generado:** 2026-06-20T01:52:08Z
**Fuente:** docs/plans/event-tracking-fixes/phases/phase-02-event-list-date-filter-flutter.md
**Nivel rg-exec:** lite

---

## 1 Objetivo

Agregar un piso automático de "medianoche local de hoy" en `EventsCubit.fetchEvents()` de modo que la pantalla de descubrimiento de rodadas muestre solo eventos de hoy en adelante cuando el usuario no aplica ningún filtro manual de fecha. El comportamiento de `EventsCubit.myEvents` no cambia: el owner ve su historial completo incluyendo rodadas pasadas.

---

## 2 Por que

El listado público de eventos muestra eventos pasados porque `fetchEvents()` envía `dateFrom: null` cuando el usuario no aplica ningún filtro. Esto produce una experiencia confusa: el usuario ve rodadas que ya ocurrieron en la pantalla de descubrimiento. El fix es un cambio puntual en la capa de presentación Flutter sin tocar contratos de API ni backend.

---

## 3 Alcance

### Entra
- Modificación de `EventsCubit.fetchEvents()` para calcular `dateFrom` como medianoche local cuando `_filters.startDate == null` y `_isMyEvents == false`.
- Tests unitarios nuevos que cubren los cuatro escenarios obligatorios (TC-df-1 a TC-df-4).
- Actualización de stubs en tests existentes que asumen `dateFrom: null` en el path sin filtros (TC-2-1, TC-2-6 en `events_filter_cubit_test.dart`; TC-evlist-a1, TC-evlist-a4 en `events_cubit_analytics_test.dart`).

### No entra
- Cambios en `EventsCubit.myEvents` ni en `GetMyEventsUseCase`.
- Cambios en `_applyFiltersAndEmit()` (filtros locales in-memory).
- Cambios de contrato en `GetEventsUseCase`, `EventRepository`, o cualquier endpoint del backend.
- UI nueva o cambios en widgets de la pantalla de eventos.
- Manejo especial de eventos `IN_PROGRESS` en el listado general.
- Migraciones de base de datos o cambios en `rideglory-api`.

---

## 4 Areas afectadas

| Capa | Archivo | Naturaleza del cambio |
|------|---------|----------------------|
| Presentation / Cubit | `lib/features/events/presentation/list/events_cubit.dart` | Lógica `dateFrom` floor en `fetchEvents()` |
| Test | `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | Actualizar stubs TC-2-1 y TC-2-6 |
| Test | `test/features/events/presentation/list/events_cubit_analytics_test.dart` | Actualizar stubs TC-evlist-a1 y TC-evlist-a4 |
| Test (nuevo) | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | Cuatro tests nuevos del piso de fecha |

**No afecta:** backend/rideglory-api, UI widgets, dominio, data layer, contratos de API.

---

## 5 Criterios de aceptacion

1. Al abrir la pantalla de eventos sin aplicar ningún filtro, `GetEventsUseCase` es invocado con `dateFrom` igual a la fecha de hoy en formato `yyyy-MM-dd` (hora local del dispositivo, nunca UTC). Si hoy es `2026-06-20` en la zona local, el valor enviado es `"2026-06-20"`.

2. Al abrir la pantalla de eventos con un filtro manual de fecha de inicio `2026-07-15`, `GetEventsUseCase` es invocado con `dateFrom: "2026-07-15"` (el valor del filtro del usuario, no el piso automático).

3. Después de llamar `clearFilters()`, el siguiente `fetchEvents()` envía nuevamente el piso automático (`dateFrom` = hoy local), no `null`.

4. `EventsCubit.myEvents.fetchEvents()` envía `dateFrom: null` sin importar la fecha actual. El usuario ve todas sus rodadas incluyendo las pasadas.

5. `dart analyze` reporta 0 errores y 0 warnings nuevos introducidos por este cambio.

6. `flutter test` pasa al 100%, incluyendo los tests nuevos (TC-df-1 a TC-df-4) y los tests existentes modificados.

---

## 6 Guardrails de regresion

- `EventsCubit.myEvents` no debe cambiar su comportamiento: debe seguir enviando `dateFrom: null` siempre.
- Los filtros manuales del usuario (`_filters.startDate != null`) deben tener prioridad absoluta sobre el piso automático.
- `clearFilters()` debe restablecer el piso automático (hoy local), no dejar `dateFrom: null`.
- El formato de fecha enviado al backend debe seguir siendo `yyyy-MM-dd` (mismo que el filtro manual existente via `.substring(0, 10)`).
- No usar `.toUtc()` — la fecha debe ser local para respetar la zona horaria del dispositivo.
- No introducir imports nuevos en `events_cubit.dart` (el cambio es puro Dart sin dependencias adicionales).
- No modificar `_applyFiltersAndEmit()` ni la lógica de filtros locales in-memory.

---

## 7 Constraints heredados

- **Arquitectura Clean:** el cambio solo toca la capa de presentación; la capa de dominio (`GetEventsUseCase`, `EventRepository`) y la capa de datos no se modifican.
- **Sin commits:** el árbol de trabajo queda sucio; el humano commitea al revisar.
- **Nivel lite:** cambio mecánico en una sola expresión; no requiere diseño en Pencil (no hay UI nueva).
- **Sin cambios de contrato API:** el parámetro `dateFrom` ya existe en el endpoint `GET /api/events?dateFrom=`; solo cambia cuándo el cliente lo pasa con valor vs. `null`.
- **Strings en l10n:** no aplica — no hay strings de UI nuevos en este cambio.
- **`dart analyze` limpio** antes de considerar la fase completa.
