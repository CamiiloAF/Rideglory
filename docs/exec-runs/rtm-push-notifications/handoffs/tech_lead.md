# Tech Lead handoff — rtm-push-notifications

**Generado:** 2026-06-05T00:24:38Z
**Tech Lead:** rg-exec (Sonnet 4.6)

---

## Veredicto

**READY** — sin blockers. Listo para commit humano tras checklist manual.

---

## Hallazgos

### Backend (en scope)

Implementación correcta y completa contra todos los AC del PRD:

- AC1: `TECNOMECANICA_30D | TECNOMECANICA_7D | TECNOMECANICA_DAY_OF` en ambos paquetes, strings idénticos.
- AC2: Helper único `sendDocumentExpiryReminders(kind, days, type)`. `sendSoatReminders` eliminado.
- AC3: 3 crons SOAT vivos, reapuntados al helper genérico. Payload observable idéntico.
- AC4: 3 crons RTM, `0 9 * * *`, `America/Bogota`, RPC `findTecnomecanicasExpiringIn` con days 30/7/0.
- AC5: `route: 'rideglory://garage'` + type RTM correcto en `createNotification` y `sendFcm`.
- AC6: Copy RTM propio (`revisión técnico-mecánica`), distinto de SOAT, varía por umbral.
- AC7: `notifications.service.spec.ts` cubre payload RTM + assertions SOAT semánticamente preservadas.
- AC8: Spec extendida (reescritura completa, pero semántica preservada y fortalecida — clasificado aceptable por QA).
- AC9: 71/71 tests verde; `tsc --noEmit` limpio.

### Flutter (fuera de scope del PRD, en scope del branch)

Los cambios Flutter son correctos y no tienen blockers. Pertenecen al corte `tecnomecanica-rtm` del branch. `dart analyze` limpio. Ver SUMMARY.md para detalle.

---

## Seguridad

- Sin secretos, tokens ni credenciales en el diff.
- Sin URLs HTTP hardcodeadas (RPC patterns usados, no URLs).
- Sin SQL concatenado (ORM Prisma).
- Sin PII en logs (vehicleId/vehicleName, no datos personales sensibles).
- CORS: no aplica (cambios internos de scheduler/RPC, no nuevos endpoints HTTP).
- Auth: no aplica (crons internos sin endpoint público).

---

## Arquitectura

- El helper genérico usa discriminación por `kind: 'soat' | 'tecnomecanica'` con tabla declarativa `messages`. Limpio y extensible.
- `TecnomecanicaRecord` interface es paridad exacta de `SoatRecord`. Correcto.
- El mapa `messages` se reconstruye en cada invocación (cosmético; es un cron diario, sin impacto de performance).
- Flutter: `getIt<TecnomecanicaCubit>()` como factory transiente para cubit de pantalla de captura es aceptable (mismo patrón que SOAT). `getIt<SaveTecnomecanicaUseCase>()` en `_savePendingRtmAndPop` sigue el patrón existente del codebase.
- `_savePendingRtmAndPop` realiza async sin estado de loading en la UI — watchlist para siguiente iteración.

---

## Tests

| Suite | Pre | Post | Estado |
|-------|-----|------|--------|
| `notifications.service.spec.ts` | 9 | 15 | PASS |
| `notification-scheduler.service.spec.ts` | 0 | 34 | PASS |
| Otras suites api-gateway | 24 | 22 | PASS |
| **Total api-gateway** | **33** | **71** | **VERDE** |
| notifications-ms | N/A | N/A | Pre-existente sin specs |

Sabotaje confirmado: RPC BROKEN → 4 tests rojo; revertido → 71 verde.

BUG-QA-01 (`notifications.service.spec.ts` reescrito vs. extendido) — aceptado como mejora, semántica preservada.
BUG-QA-02 (`notifications-ms` sin specs) — pre-existente, no bloqueante.

---

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` para pasos detallados.

Puntos críticos:
1. Staging: poblar `Tecnomecanica` a 30/7/0 días, invocar crons, verificar `Notification.type` y FCM.
2. Staging: invocar crons SOAT, verificar que payload no cambió (regresión cero).
3. App: notificación RTM → deep-link → Garage.
4. App Flutter: flujo creación vehículo con RTM pending, flujo edición con slot live.
