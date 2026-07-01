# QA Handoff — Phase 02: Event List Date Filter

**Date:** 2026-06-20T02:10:25Z
**Status:** done

---

## Catalogo de tests

| ID | Criterio AC (PRD §5) | Tipo | Archivo | Estado |
|----|----------------------|------|---------|--------|
| TC-df-1 | CA-1: sin filtro → `dateFrom` = hoy local `yyyy-MM-dd` | Unit | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | PASS |
| TC-df-2 | CA-2: filtro manual `startDate = 2026-07-15` → `dateFrom = "2026-07-15"` | Unit | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | PASS |
| TC-df-3 | CA-3: `clearFilters()` seguido de `fetchEvents()` → piso automático restaurado | Unit | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | PASS |
| TC-df-4 | CA-4: `EventsCubit.myEvents.fetchEvents()` no llama `GetEventsUseCase` (dateFrom = null irrelevante) | Unit | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | PASS |
| CA-5 | `dart analyze` 0 errores y 0 warnings | Static | `dart analyze` | PASS |
| CA-6 | `flutter test` al 100% incluyendo tests nuevos y modificados | Suite | `flutter test` | PASS — 1006 tests |
| TC-2-1 | Test existente: fetch sin filtros devuelve eventos (stub actualizado) | Unit | `events_filter_cubit_test.dart` | PASS |
| TC-2-2 | Test existente: fetch con tipo de evento (stub actualizado) | Unit | `events_filter_cubit_test.dart` | PASS |
| TC-2-6 | Test existente: fetch con error de red (stub actualizado) | Unit | `events_filter_cubit_test.dart` | PASS |
| TC-evlist-a1 | Analytics: `fetchEvents()` success → `events_list_viewed` con `list_scope=all` | Unit | `events_cubit_analytics_test.dart` | PASS |
| TC-evlist-a3 | Analytics: `fetchEvents()` con filtro tipo | Unit | `events_cubit_analytics_test.dart` | PASS |
| TC-evlist-a4 | Analytics: `fetchEvents()` error → no emite `events_list_viewed` | Unit | `events_cubit_analytics_test.dart` | PASS |
| TC-evlist-a5 | Analytics: `clearFilters()` no emite `events_list_viewed` | Unit | `events_cubit_analytics_test.dart` | PASS |
| TC-evlist-a6 | Analytics: mutations (`addEvent`, `updateEvent`, `removeEvent`) no emiten `events_list_viewed` | Unit | `events_cubit_analytics_test.dart` | PASS |

---

## Matriz de regresion

| Guardrail (PRD §6) | Mecanismo de verificación | Estado |
|--------------------|--------------------------|--------|
| `EventsCubit.myEvents` sigue enviando `dateFrom: null` | TC-df-4: `verifyNever` sobre `GetEventsUseCase`; myEvents usa `GetMyEventsUseCase` sin parámetros de fecha | PASS |
| Filtros manuales del usuario tienen prioridad absoluta sobre el piso | TC-df-2: `startDate = DateTime(2026,7,15)` → captura `"2026-07-15"`, no la fecha de hoy | PASS |
| `clearFilters()` restaura piso automático (no deja `null`) | TC-df-3: segundo capture después de `clearFilters()` == fecha de hoy | PASS |
| Formato de fecha sigue siendo `yyyy-MM-dd` | TC-df-1: `capturedDateFrom == DateTime.now().toIso8601String().substring(0,10)` | PASS |
| No usar `.toUtc()` | Diff de `events_cubit.dart` revisado: usa `DateTime.now()` (local) sin `.toUtc()` | PASS |
| No introducir imports nuevos en `events_cubit.dart` | Diff: solo 4 líneas cambiadas en la expresión ternaria, sin nuevas importaciones | PASS |
| No modificar `_applyFiltersAndEmit()` ni filtros in-memory | Diff: solo `_fetchFn()` cambia; `_applyFiltersAndEmit` intacto | PASS |

---

## Ejecucion

### Análisis estático

```
dart analyze
→ No issues found!
```

### Tests de la fase (nuevo + modificados)

```
flutter test test/features/events/presentation/list/events_cubit_date_filter_test.dart
→ +4: All tests passed!

flutter test test/features/events/presentation/cubit/events_filter_cubit_test.dart \
  test/features/events/presentation/list/events_cubit_analytics_test.dart
→ +15: All tests passed!
```

### Suite completa

```
flutter test (JSON reporter)
→ Passed: 1006, Failed: 0
```

### Scope del diff verificado

| Archivo | En scope | Tipo de cambio |
|---------|----------|----------------|
| `lib/features/events/presentation/list/events_cubit.dart` | SI | Lógica `dateFrom` floor — 4 líneas, sin imports nuevos |
| `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | SI (nuevo) | 4 tests nuevos TC-df-1..TC-df-4 |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | SI | Stubs `dateFrom: null` → `any(named: 'dateFrom')` |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | SI | Stubs `dateFrom: null` → `any(named: 'dateFrom')` |
| `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | NO — fuera de alcance | Mejora `_subscribeToEventEnded` + helpers `@visibleForTesting` (de otra fase/fix) |
| `integration_test/test_bundle.dart` | NO — fuera de alcance | Agrega imports patrol para app/events/home/profile tests (generado automáticamente) |
| `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` | NO — fuera de alcance | Linting fix: agrega llaves a `if` sin `else` |
| `test/features/home/presentation/widgets/home_garage_section_test.dart` | NO — fuera de alcance | Sintaxis Dart 3: `(_, __)` → `(_, _)` en builders de GoRoute |
| `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | NO — fuera de alcance | Sintaxis Dart 3: `(_, __)` → `(_, _)` en builders de GoRoute |

Los archivos fuera de alcance son cambios independientes que existían en el árbol de trabajo y no afectan los criterios de aceptación de esta fase. No se detectaron regresiones en ninguno de ellos; todos los 1006 tests pasan.

---

## Bugs

Ningún bug identificado.

---

## Pruebas manuales recomendadas

Para validar en app real (simulador/dispositivo):

1. **Sin filtros (CA-1):** Abrir lista de eventos → verificar que no aparecen eventos con fecha anterior a hoy. En dev con Charles/Proxyman: request a `GET /api/events?dateFrom=YYYY-MM-DD` donde `YYYY-MM-DD` = fecha local de hoy.
2. **Filtro manual pasado (CA-2):** Aplicar filtro de fecha `2025-01-01` → eventos de 2025 deben aparecer (filtro manual sobrescribe el piso).
3. **Clear filters (CA-3):** Después de limpiar filtros → lista vuelve a mostrar solo eventos desde hoy.
4. **Mis eventos (CA-4):** Navegar a "Mis rodadas" → eventos pasados SÍ deben aparecer (piso no aplica).

---

## Sign-off

- Todos los criterios de aceptación CA-1 a CA-6 de la fase: **PASSED**
- Bugs bloqueantes pendientes: **ninguno**
- `dart analyze`: **0 issues**
- `flutter test`: **1006 / 1006 passed, 0 failed**
- Calidad: **green — listo para review del tech lead**

## Next agent needs to know

- **Tech lead:** Implementación limpia. 4 tests nuevos cubren exactamente los 4 ACs de comportamiento. Los stubs existentes se actualizaron correctamente con `any(named: 'dateFrom')` para no falsificar el contrato. El diff de producción es mínimo (4 líneas en un archivo, sin imports nuevos, sin `.toUtc()`). Hay 5 archivos fuera de alcance en el árbol de trabajo (tracking cubit, integration test bundle, un linting fix y 2 tests con sintaxis Dart 3); son cambios independientes que no afectan esta fase.
- **DevOps:** `dart analyze && flutter test` — 0 errores, 1006 tests verdes. No requiere `build_runner`.

## Change log

- 2026-06-20T02:10:25Z: QA inicial completado.
