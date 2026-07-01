# Architect Audit — Phase 02: Event List Date Filter

**Auditor:** Opus
**Fecha:** 2026-06-20T01:55:58Z
**Rol auditado:** architect (planning)
**Veredicto:** CHANGES REQUESTED

---

## Resumen

El plan del architect es casi correcto: la decisión técnica (piso `dateFrom` local en
`fetchEvents()` cuando `!_isMyEvents && filters.startDate == null`), el edit propuesto, el
formato `yyyy-MM-dd`, la ausencia de imports nuevos y la no-modificación de `myEvents`
están todos validados contra el código real (`events_cubit.dart` L97-127, L139-142).

**Pero el inventario de stubs de test a actualizar está incompleto y contiene una
afirmación falsa**, lo que haría fallar `flutter test` (viola AC-6) si Frontend sigue el
plan al pie de la letra.

---

## Validado contra código real (correcto)

- `events_cubit.dart` L102: `dateFrom: filters.startDate?.toIso8601String().substring(0, 10)` — confirmado.
- `_isMyEvents` (L88) y `filters.startDate` existen y se usan tal como el plan describe.
- `clearFilters()` (L139-142) resetea `_filters` y llama `fetchEvents()` → el piso se re-aplica (CA-3 OK).
- `EventsCubit.myEvents` no se toca; sigue pasando `dateFrom: null` (CA-4 OK).
- Analytics handoff (a1, a3, a4, a5, a6): los cinco stubs `dateFrom: null` existen y
  rompen tras el cambio. Lista correcta y completa para ese archivo.
- TC-2-3 (L113), TC-2-4 (L140), TC-2-5 (L168) ya usan `any(named: 'dateFrom')` → no rompen. Correcto.

---

## Defecto bloqueante

**TC-2-2 omitido del inventario de stubs.**

`test/features/events/presentation/cubit/events_filter_cubit_test.dart` L84-105:
TC-2-2 (`updateFilters() with type filter`) aplica un filtro de SOLO tipo
(`EventFilters(types: {EventType.onRoad})`, `startDate == null`). Su stub en L89 es
`dateFrom: null`. Tras el cambio, `fetchEvents()` pasará `dateFrom` = piso de hoy
(no-nulo), por lo que el stub no coincidirá → `MissingStubError` → test falla → viola AC-6.

- El frontend handoff (`architect-for-frontend.md` L36-38) lista solo TC-2-1 y TC-2-6 de
  este archivo; **omite TC-2-2**.
- Peor: la tabla de riesgos de `architect.md` L57 afirma explícitamente *"TC-2-2 y TC-2-3
  ya usan `any(named: 'dateFrom')` → no rompen"*. Esto es **falso para TC-2-2** (usa
  `null` en L89). Solo TC-2-3 usa `any`.

---

## Cambios requeridos

1. `architect-for-frontend.md` §"Tests a modificar" — agregar **TC-2-2** a la lista del
   archivo `events_filter_cubit_test.dart`: stub L89 `dateFrom: null` →
   `dateFrom: any(named: 'dateFrom')`.
2. `architect.md` tabla de riesgos L57 — corregir la afirmación: TC-2-2 SÍ rompe (usa
   `dateFrom: null` en L89, con filtro de solo-tipo y `startDate == null`); solo TC-2-3 usa `any`.
3. `architect.md` "Orden de implementación" paso 2 — incluir TC-2-2 junto a TC-2-1 y TC-2-6.
4. `architect-for-qa.md` tabla "Tests existentes que se modifican" — agregar TC-2-2 a la fila
   de `events_filter_cubit_test.dart`.

Tras esos ajustes el plan queda completo y ejecutable sin romper la suite.
