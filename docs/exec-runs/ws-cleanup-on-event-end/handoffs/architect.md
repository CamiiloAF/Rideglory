# Architect handoff — ws-cleanup-on-event-end

**Date:** 2026-06-20T01:53:36Z
**Status:** done

---

## Decisiones

| # | Decisión | Fundamento |
|---|----------|------------|
| D1 | Cambio puramente en Presentation layer (`live_tracking_cubit.dart`) | El bug vive en `_subscribeToEventEnded()` — solo capa presentación necesita modificación |
| D2 | No se toca `TrackingRepository` (interfaz ni implementación) | `stopTracking` ya hace `leaveSession` antes de `stopSession` (líneas 100-101 de `tracking_repository_impl.dart`); agregar `leaveSession` explícito crearía doble-llamada |
| D3 | El listener se convierte a `async` | Necesario para `await _positionSubscription?.cancel()` y `await _stopTrackingUseCase(...)` en orden prescriptivo |
| D4 | Dos seams `@visibleForTesting` separados | `debugPrimeForEventEndedTest(userId)` (estado con rider activo: fija `_userId`, emite `isTracking: true`) y `debugSubscribeEventEndedForTest()` (activa solo el listener, sin sesión activa) — son estados mutuamente excluyentes, no unificables |
| D5 | `Nothing` viene de `lib/core/domain/nothing.dart` | Confirmado; `dartz` no provee `Nothing`; el fold del use case usa este tipo |
| D6 | No cambia `pubspec.yaml` | Mocktail ya está como dev dependency (confirmado por `live_tracking_cubit_analytics_test.dart`) |
| D7 | No se modifica `live_tracking_cubit_analytics_test.dart` | PRD lo prohíbe explícitamente (§3 No entra) |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/events/presentation/tracking/cubit/live_tracking_cubit.dart` | modify | Refactor `_subscribeToEventEnded()` con 4 pasos de cleanup + 2 seams `@visibleForTesting` | med |
| `test/features/events/presentation/tracking/live_tracking_cubit_event_ended_test.dart` | create | 4 casos de test: A (path principal), B (doble-disparo), C (sin sesión), D (use case Left) | low |

Solo 2 archivos. El árbol de trabajo queda sucio para revisión humana.

---

## Contratos rideglory-api

**Ninguno.** El PRD establece explícitamente: "No se modifican archivos de backend". No hay endpoints nuevos ni cambios de contrato.

---

## Datos / migraciones

Ninguna. Sin cambios de esquema. Sin `analysis/MIGRATION_PLAN.md`.

---

## Env

Sin cambios. Sin `analysis/ENV_DELTA.md`.

---

## Riesgos

| Riesgo | Severidad | Mitigación |
|--------|-----------|------------|
| `_handleAuthSignedOut` y `_subscribeToEventEnded` pueden concurrir — ambos cancelan GPS y llaman `stopTracking` | med | El flag `_sessionEndLogged` ya protege analytics; el guard `state.isTracking == false` en el segundo disparo del eventEnded protege `stopTrackingUseCase`. `_handleAuthSignedOut` pone `_positionSubscription = null` antes que el eventEnded listener llegue — `cancel()` sobre null es no-op. No se requiere mutex adicional. |
| `close()` y `eventEnded` concurrentes | low | Guard `isClosed` antes del emit final y `_sessionEndLogged` antes del analytics ya cubren la carrera |
| Tests flaky por `await Future.delayed(Duration.zero)` | low | Patrón ya validado en `live_tracking_cubit_analytics_test.dart`; reutilizar el mismo patrón |

---

## Orden de implementación

1. Modificar `live_tracking_cubit.dart` — refactorizar `_subscribeToEventEnded()` y agregar los 2 seams
2. Crear `live_tracking_cubit_event_ended_test.dart` — 4 casos en orden A → B → C → D
3. Verificar con `dart analyze` (cero violaciones nuevas)
4. Verificar con `flutter test` (suite completa verde)

---

## Superficie de regresión

- `live_tracking_cubit_analytics_test.dart` (5 tests de SOS — no tocar, deben pasar sin cambios)
- `close()` y `_handleAuthSignedOut()` — no modificados pero usan los mismos flags/subscriptions; verificar que sus tests pasen
- El stream `eventEnded` en `TrackingRepositoryImpl` no cambia — regresión en capa data es imposible
- Suite completa de events (`flutter test test/features/events/`) debe pasar en verde

---

## Fuera de alcance

- Modificar `TrackingRepository` (interfaz de dominio)
- Backend (`rideglory-api`) — cualquier cambio
- Otros cubits o pantallas
- Fases 2 y 3 del plan `event-tracking-fixes`
- Nuevas dependencias en `pubspec.yaml`
- Localization / l10n (no hay texto visible al usuario)
