# Frontend Handoff — Phase 02: Event List Date Filter

**Agent:** Frontend (Flutter lib/)
**Timestamp:** 2026-06-20T02:03:47Z
**Status:** DONE — all tests green

---

## Baseline

Before any changes, ran:
```
flutter test test/features/events/presentation/cubit/events_filter_cubit_test.dart \
  test/features/events/presentation/list/events_cubit_analytics_test.dart
```
Result: **15 tests, all passed.**

Zero FAILED, zero ERROR in the full `test/features/events/presentation/` suite.

---

## Archivos cambiados

### Producción

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `lib/features/events/presentation/list/events_cubit.dart` | modify | Agrega piso `dateFrom = hoy local` en `fetchEvents()` cuando `!_isMyEvents && _filters.startDate == null` |

**Cambio exacto en `events_cubit.dart` (línea 102):**

```dart
// Antes
dateFrom: filters.startDate?.toIso8601String().substring(0, 10),

// Después
dateFrom: _isMyEvents
    ? filters.startDate?.toIso8601String().substring(0, 10)
    : (filters.startDate ?? DateTime.now()).toIso8601String().substring(0, 10),
```

### Tests modificados

| Archivo | Cambio |
|---------|--------|
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | TC-2-1, TC-2-2, TC-2-6: stubs `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`. También actualizado el `verify` de TC-2-1. |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | TC-evlist-a1, a3, a4, a5, a6: stubs `dateFrom: null` → `dateFrom: any(named: 'dateFrom')` |

---

## Pruebas nuevas

**Archivo creado:** `test/features/events/presentation/list/events_cubit_date_filter_test.dart`

| ID | Descripción | Criterio verificado |
|----|-------------|---------------------|
| TC-df-1 | `fetchEvents()` sin filtros → `dateFrom` = hoy local `yyyy-MM-dd` | `capturedDateFrom == DateTime.now().toIso8601String().substring(0,10)` |
| TC-df-2 | `fetchEvents()` con filtro manual `startDate: DateTime(2026,7,15)` → `dateFrom: '2026-07-15'` | Filtro manual tiene prioridad; piso no aplica |
| TC-df-3 | `clearFilters()` seguido de `fetchEvents()` → `dateFrom` = hoy local | Segunda captura (post-clear) == fecha de hoy |
| TC-df-4 | `EventsCubit.myEvents.fetchEvents()` → `GetEventsUseCase` nunca llamado | `verifyNever` sobre `GetEventsUseCase`; myEvents usa `GetMyEventsUseCase` sin fechas |

---

## Resultado final

```
dart analyze lib/features/events/presentation/list/events_cubit.dart
→ No issues found!

flutter test test/features/events/presentation/cubit/events_filter_cubit_test.dart \
  test/features/events/presentation/list/events_cubit_analytics_test.dart \
  test/features/events/presentation/list/events_cubit_date_filter_test.dart
→ +19: All tests passed!

flutter test test/features/events/presentation/ (full suite)
→ 0 FAILED, 0 ERROR
```

---

## Verificacion manual

Para confirmar en app:
1. Abrir lista de eventos (pantalla principal — scope=all).
2. Sin filtros activos: los eventos mostrados son solo del día de hoy en adelante (ningún evento pasado visible).
3. Aplicar filtro de fecha con fecha pasada (ej. 2025-01-01): la lista sí muestra eventos de esa fecha (filtro manual sobrescribe el piso).
4. Limpiar filtros ("Clear"): la lista vuelve a mostrar solo eventos desde hoy.
5. Navegar a "Mis eventos" (scope=myEvents): los eventos pasados SÍ aparecen (piso no aplica).

---

## Notas para QA

- El piso es **fecha local** (no UTC). Si el dispositivo está en una zona horaria diferente al servidor, la fecha enviada al backend refleja el día local del usuario — esto es el comportamiento correcto por diseño (ver PRD).
- TC-df-4 verifica indirectamente que `EventsCubit.myEvents` no pasa `dateFrom` al backend ya que usa `GetMyEventsUseCase` (sin parámetros de fecha).
- No hay cambios en DTOs, dominio, data layer, ni widgets de UI. El árbol de trabajo solo tiene modificaciones en presentación y tests.
- `dart run build_runner` no fue necesario (sin cambios en código generado).
