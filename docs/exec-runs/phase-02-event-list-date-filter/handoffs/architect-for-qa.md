> Slim handoff — read this before handoffs/architect.md

# Architect → QA

**Phase:** 02 — Event List Date Filter

---

## Comandos de verificación

```bash
# Análisis estático (debe dar 0 errores y 0 warnings nuevos)
dart analyze

# Suite completa de tests
flutter test

# Solo los tests de eventos (más rápido)
flutter test test/features/events/
```

---

## Criterios de aceptación — trazabilidad

| Criterio (PRD §5) | Test que lo cubre | Estado esperado |
|-------------------|-------------------|-----------------|
| CA-1: sin filtro → `dateFrom` = hoy local | TC-df-1 (nuevo) | PASS |
| CA-2: filtro manual `startDate` → `dateFrom` del filtro | TC-df-2 (nuevo) | PASS |
| CA-3: `clearFilters()` → piso automático restaurado | TC-df-3 (nuevo) | PASS |
| CA-4: `myEvents.fetchEvents()` → `dateFrom: null` | TC-df-4 (nuevo) | PASS |
| CA-5: `dart analyze` limpio | `dart analyze` | 0 errores |
| CA-6: `flutter test` al 100% | `flutter test` | 0 failures |

---

## Tests existentes que se modifican (deben seguir en PASS)

| Archivo | Tests | Cambio aplicado |
|---------|-------|----------------|
| `events_filter_cubit_test.dart` | TC-2-1, TC-2-2, TC-2-6 | Stub `dateFrom: null` → `any(named: 'dateFrom')` |
| `events_cubit_analytics_test.dart` | TC-evlist-a1, TC-evlist-a3, TC-evlist-a4, TC-evlist-a5, TC-evlist-a6 | Stub `dateFrom: null` → `any(named: 'dateFrom')` |

---

## Guardrails de regresión a verificar

- `EventsCubit.myEvents` sigue enviando `dateFrom: null` → TC-df-4.
- El filtro manual del usuario (`startDate != null`) tiene prioridad sobre el piso → TC-df-2.
- `clearFilters()` no deja `dateFrom: null` → TC-df-3.
- Formato de fecha sigue siendo `yyyy-MM-dd` → verificar en TC-df-1.
- No se usó `.toUtc()` → revisar el diff de `events_cubit.dart`.
- No se introdujeron imports nuevos en `events_cubit.dart` → revisar el diff.

---

## Archivos fuera de alcance (no deben tener diff)

- Cualquier archivo en `lib/features/events/domain/`
- Cualquier archivo en `lib/features/events/data/`
- Cualquier widget de presentación (solo `events_cubit.dart` cambia en `lib/`)
- `rideglory-api/` — ningún cambio backend

> Full detail: handoffs/architect.md
