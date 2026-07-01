# Tech Lead Handoff — ws-cleanup-on-event-end

**Generado:** 2026-06-20T02:08:22Z  
**Modelo:** claude-sonnet-4-6  
**Nivel de esfuerzo:** normal

---

## Veredicto

**READY** — todos los ACs del PRD están cumplidos. El cambio core es correcto, limpio y bien cubierto por tests. Hay cambios colaterales fuera del scope del PRD que son benignos pero requieren atención manual antes de commitear.

---

## Hallazgos

### Cambios en scope (PRD §4)

1. **`live_tracking_cubit.dart` — `_subscribeToEventEnded()`:** Implementación correcta. Los 4 pasos en orden exacto según PRD §5 AC8. Guards `isClosed` presentes en inicio del listener y antes del emit final.
2. **Test `live_tracking_cubit_event_ended_test.dart`:** 4 casos exactos (Casos A-D). Verificaciones de conteo exacto, `verifyNever`, doble-disparo e idempotencia. Usan `Nothing` del proyecto (`lib/core/domain/nothing.dart`), no de `dartz`. El frontend documentó que corrigió `await useCase(...).fold(...)` → `final result = await useCase(...); result.fold(...)` — esto es una corrección válida y necesaria.

### Cambios fuera de scope (colaterales benignos)

3. **`events_cubit.dart`:** `dateFrom` para eventos públicos usa `DateTime.now()` cuando `filters.startDate == null`. Cambia comportamiento de la vista de eventos públicos (no muestra históricos por defecto). **No es regresión** — es una mejora de UX, pero fue hecha fuera de scope del PRD. Requiere revisión manual de la lista de eventos públicos.
4. **`custom_route_builder_section.dart`:** Agrega `{}` al bloque `if`. Fix de lint menor. Benigno.
5. **`integration_test/test_bundle.dart`:** Registra 4 integration tests adicionales. Verificar que estén listos para CI.
6. **Tests de widget (`home_garage_section_test.dart`, `garage_archived_section_test.dart`):** `__` → `_` wildcard. Dart 3.x lint fix. Benigno.
7. **Tests de cubit (`events_filter_cubit_test.dart`, `events_cubit_analytics_test.dart`):** Expectativas de `dateFrom: null` → `dateFrom: any(named: 'dateFrom')`. Consecuencia necesaria del cambio #3. Correctos.

---

## Seguridad

- Sin secretos expuestos.
- Sin SQL concatenado ni XSS.
- Sin PII en logs: el cubit usa `eventId` y `userId` solo para llamadas de dominio; no se loggean en analytics.
- Sin cambios de auth/CORS.
- `@visibleForTesting` correcto — no expone seams en producción.

---

## Arquitectura

- Clean Architecture respetada: el cubit (presentación) delega a `_stopTrackingUseCase` (dominio); no llama directamente al repo ni al WS.
- `TrackingRepository` interface no modificada (constraint §7 cumplido).
- Flag `_sessionEndLogged` existente no fue removido ni alterado — idempotencia de analytics preservada.
- Doble guard: `_sessionEndLogged` para analytics, `state.isTracking` para stop use case. Ambos son necesarios y correctos.
- `_positionSubscription` se cancela incondicionalmente en paso 2 (correcto — si hay GPS activo aunque `isTracking` sea false por alguna inconsistencia de estado).

---

## Tests

| AC PRD | Test | Estado |
|--------|------|--------|
| AC3: 4 casos exactos | Confirmado por `grep -c "test("` = 4 | PASS |
| AC4: Caso A | `live_tracking_cubit_event_ended_test.dart` líneas 95-116 | PASS |
| AC5: Caso B doble-disparo | líneas 118-142 | PASS |
| AC6: Caso C sin sesión | líneas 144-164 | PASS |
| AC7: Caso D Left | líneas 166-191 | PASS |
| AC9: analytics test no modificado | git diff vacío en ese archivo | PASS |
| Suite completa | 897/897 según QA | PASS |

---

## Pruebas manuales

Antes de commitear:

1. **Lista de eventos públicos:** Abrir la pantalla de eventos (vista pública, no "mis eventos"). Verificar que muestra solo eventos desde hoy en adelante — no eventos pasados.
2. **Integration tests:** Si `events_patrol_test.dart`, `home_patrol_test.dart`, `profile_patrol_test.dart`, `app_test.dart` no son estables en CI, revertir los 4 lines del `test_bundle.dart` o excluirlos del pipeline antes de mergear.
3. **Tracking E2E (opcional):** Rider activo + organizador termina evento → rider ve pantalla finalizada → no más pings GPS en logs del backend.
