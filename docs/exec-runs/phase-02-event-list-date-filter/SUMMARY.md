# SUMMARY — Phase 02: Event List Date Filter

**Generado:** 2026-06-20T02:14:08Z
**Tech Lead:** Revisión del working tree (sin commit)

---

## Objetivo

Agregar un piso automático de "medianoche local de hoy" en `EventsCubit.fetchEvents()` para que la pantalla de descubrimiento de eventos muestre únicamente eventos de hoy en adelante cuando el usuario no ha aplicado ningún filtro manual de fecha. `EventsCubit.myEvents` no se toca: el owner sigue viendo su historial completo.

---

## Qué cambió por área

### Frontend (Flutter lib/)

- **`lib/features/events/presentation/list/events_cubit.dart`** — 4 líneas cambiadas en `fetchEvents()`. Expresión ternaria: si `_isMyEvents` → comportamiento original; si no → `(filters.startDate ?? DateTime.now()).toIso8601String().substring(0,10)`. Sin imports nuevos. Sin `.toUtc()`.

### Tests (nuevo)

- **`test/features/events/presentation/list/events_cubit_date_filter_test.dart`** — 4 tests nuevos (TC-df-1 a TC-df-4) cubriendo exactamente los criterios de aceptación CA-1 a CA-4.

### Tests (modificados — stubs)

- **`test/features/events/presentation/cubit/events_filter_cubit_test.dart`** — TC-2-1, TC-2-2, TC-2-6: stubs `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`.
- **`test/features/events/presentation/list/events_cubit_analytics_test.dart`** — TC-evlist-a1, a3, a4, a5, a6: mismo patrón.

### Archivos fuera de alcance (preexistentes en el working tree)

| Archivo | Naturaleza |
|---------|------------|
| `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | Mejora `_subscribeToEventEnded` + helpers `@visibleForTesting`; de otra fase |
| `integration_test/test_bundle.dart` | Agrega imports patrol para tests de app/events/home/profile; generado automáticamente |
| `lib/features/events/presentation/form/widgets/sections/custom_route_builder_section.dart` | Lint fix: llaves en `if` |
| `test/features/home/presentation/widgets/home_garage_section_test.dart` | Sintaxis Dart 3: `(_, __)` → `(_, _)` |
| `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` | Sintaxis Dart 3: `(_, __)` → `(_, _)` |

---

## Archivos

| Archivo | En scope | Tipo |
|---------|----------|------|
| `lib/features/events/presentation/list/events_cubit.dart` | SI | Producción |
| `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | SI | Test nuevo |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | SI | Test modificado |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | SI | Test modificado |
| `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | NO | Fuera de alcance |
| `integration_test/test_bundle.dart` | NO | Fuera de alcance |
| `lib/.../custom_route_builder_section.dart` | NO | Fuera de alcance |
| `test/.../home_garage_section_test.dart` | NO | Fuera de alcance |
| `test/.../garage_archived_section_test.dart` | NO | Fuera de alcance |

---

## Pruebas

| Suite | Resultado |
|-------|-----------|
| `flutter test ...events_cubit_date_filter_test.dart` | +4: All tests passed! |
| `flutter test` (3 archivos de la fase) | +19: All tests passed! |
| `dart analyze events_cubit.dart` | No issues found! |
| Suite completa (QA) | 1006 / 1006 passed |

---

## Riesgos / watchlist

1. **`live_tracking_cubit.dart` fuera de alcance:** Cambio sustancial en `_subscribeToEventEnded` (GPS cancel + stop use case async + isClosed guard). Sin regresión para esta fase, pero el commit debería separar ambas fases si el humano lo prefiere.
2. **`integration_test/test_bundle.dart`:** Agrega 4 imports patrol nuevos. No afecta `flutter test` unitario pero podría afectar corridas de integración si alguno de esos archivos falla en compilación.
3. **TC-df-1 time sensitivity:** Riesgo teórico de false negative si el test corre justo en el cambio de día local.
4. **Piso fecha local vs UTC backend:** Documentado en PRD como comportamiento deseado; vigilar en QA con dispositivos en zonas UTC distintas.

---

## Mensaje de commit sugerido

```
feat(events): piso automático de fecha hoy en listado de rodadas

fetchEvents() envía dateFrom=hoy-local cuando el usuario no aplica
filtros manuales, eliminando eventos pasados de la pantalla de
descubrimiento. EventsCubit.myEvents no se ve afectado.

Incluye 4 tests nuevos (TC-df-1..TC-df-4) y actualización de stubs
en events_filter_cubit_test y events_cubit_analytics_test.
```
