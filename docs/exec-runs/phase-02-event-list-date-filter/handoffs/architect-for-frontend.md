> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend (Flutter)

**Phase:** 02 — Event List Date Filter
**Scope:** Solo presentación. Sin cambios de dominio, datos, o UI widgets.

---

## El cambio en `events_cubit.dart`

En `fetchEvents()`, reemplaza la línea:

```dart
dateFrom: filters.startDate?.toIso8601String().substring(0, 10),
```

con:

```dart
dateFrom: _isMyEvents
    ? filters.startDate?.toIso8601String().substring(0, 10)
    : (filters.startDate ?? DateTime.now()).toIso8601String().substring(0, 10),
```

**Reglas críticas:**
- NO usar `.toUtc()` — la fecha debe ser local.
- NO introducir imports nuevos.
- El bloque `_isMyEvents` ya existe; solo cambia el valor del `dateFrom` calculado.
- `_applyFiltersAndEmit()` NO se toca.

---

## Tests a modificar (stubs `dateFrom: null` → `any(named: 'dateFrom')`)

### `test/features/events/presentation/cubit/events_filter_cubit_test.dart`
- **TC-2-1** (`fetchEvents() with no filters`): stub `mockGetEventsUseCase(type: null, dateFrom: null, dateTo: null)` → usar `dateFrom: any(named: 'dateFrom')`. Misma actualización en el `verify` del mismo test.
- **TC-2-2** (`updateFilters() with type filter`): stub L89 tiene `dateFrom: null` con filtro de solo-tipo (`startDate == null`); tras el cambio el cubit pasa `dateFrom = hoy` → actualizar a `dateFrom: any(named: 'dateFrom')`.
- **TC-2-6** (`fetchEvents() error state`): stub con `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.

### `test/features/events/presentation/list/events_cubit_analytics_test.dart`
- **TC-evlist-a1**: stub `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.
- **TC-evlist-a3**: stub `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.
- **TC-evlist-a4**: stub `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.
- **TC-evlist-a5**: stub `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.
- **TC-evlist-a6**: stub `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.

---

## Nuevo archivo de tests

**Path:** `test/features/events/presentation/list/events_cubit_date_filter_test.dart`

Cuatro tests obligatorios:

| ID | Descripción | Verificación |
|----|-------------|-------------|
| TC-df-1 | `fetchEvents()` sin filtros → `dateFrom` = hoy local `yyyy-MM-dd` | `verify` que `GetEventsUseCase` fue llamado con `dateFrom` igual a `DateTime.now().toIso8601String().substring(0,10)` |
| TC-df-2 | `fetchEvents()` con filtro manual `startDate: DateTime(2026, 7, 15)` → `dateFrom: '2026-07-15'` | Filtro manual tiene prioridad; el piso automático NO aplica |
| TC-df-3 | `clearFilters()` seguido de `fetchEvents()` → `dateFrom` = hoy local (no null) | El piso se restablece tras limpiar filtros |
| TC-df-4 | `EventsCubit.myEvents.fetchEvents()` → `dateFrom: null` | El owner ve historial completo |

**Nota para TC-df-1 y TC-df-3:** el test puede calcular `DateTime.now().toIso8601String().substring(0, 10)` en el mismo test para comparar, ya que la ejecución es síncrona a efectos del string de fecha.

---

## No tocar

- `lib/features/events/domain/` — sin cambios.
- `lib/features/events/data/` — sin cambios.
- Cualquier widget de la pantalla de eventos.
- `EventsCubit.myEvents` constructor — sin cambios; solo el comportamiento de `fetchEvents()` diferencia los paths.

---

## Verificación final

```bash
dart analyze
flutter test test/features/events/presentation/
```

Ambos deben pasar con 0 errores.

> Full detail: handoffs/architect.md
