# Tech Lead handoff — Phase 03: Auto-End Events Backend

**Date:** 2026-07-01T03:35:03Z
**Status:** needs_changes

---

## Veredicto

**needs_changes** — Un blocker real (BUG-01) requiere fix antes de commitear. El núcleo funcional de Phase 03 está correctamente implementado.

---

## Hallazgos

### BUG-01 — BLOCKER

**Archivo:** `api-gateway/src/tracking/tracking-http.controller.ts`
**Método:** `endTracking` (líneas 72-100)

La implementación cambió la autenticación fuera de scope:

**Antes (correcto):**
```typescript
const authUserId = request.user?.uid;
if (!authUserId) { throw new UnauthorizedException(); }
```

**Después (BUG-01):**
```typescript
const email = request.user?.email;
if (!email) { throw new UnauthorizedException(); }
const dbUser = await firstValueFrom<UserResult>(
  this.usersService.send('findUserByEmail', { email }).pipe(timeout(RPC_TIMEOUT_MS)),
);
const authUserId = dbUser.id;
```

**Por qué es blocker:**
1. Viola PRD §6 guardrail explícito: "El endpoint POST /api/events/:eventId/tracking/end (manual) no debe verse alterado en comportamiento ni en firma."
2. Es inconsistente con `startTracking` (mismo controller, línea 54 usa `uid` directamente).
3. Introduce nuevo failure mode: tokens Firebase sin campo `email` (e.g., phone auth) recibirán 401.
4. Añade latencia y un punto de falla extra (RPC a users-ms) en el happy path.
5. Está fuera del change map definido por el architect para este archivo.

**Fix requerido:** Revertir `endTracking` auth al patrón `uid`. Los tests `tracking-http.controller.spec.ts` deberán actualizarse consecuentemente.

---

### OUT-SCOPE-EVENTS-MS — Informativo (no es un bug de código)

En el working tree de events-ms hay archivos de otro feature que no son de Phase 03:
- `prisma/migrations/20260701014208_add_medical_consent_risk_fields/`
- `prisma/schema.prisma` (agrega campos de consentimiento médico)
- `src/registrations/registrations.service.ts`

El backend handoff ya documenta esto con instrucciones de `git add` selectivo. No se deben incluir en el commit de Phase 03.

---

## Seguridad

| Check | Estado |
|-------|--------|
| `forceEndTracking` sin endpoint HTTP | PASS — solo `@MessagePattern` TCP, comentario `// INTERNAL ONLY` en controller |
| Sin secretos en código nuevo | PASS |
| Sin SQL concatenado / injection risk | PASS — Prisma ORM con tipado |
| Sin PII en logs | PASS — solo se loggea `eventId` |
| Auth/CORS | PASS para Phase 03 core. BUG-01 cambia auth de `endTracking` — ver hallazgos |
| No nuevas dependencias circulares NestJS | PASS — `TrackingModule` exporta servicios; `NotificationSchedulerModule` importa `TrackingModule` (unidireccional) |

---

## Arquitectura

| Check | Estado |
|-------|--------|
| Clean Architecture: sin HTTP en events-ms | PASS |
| Env vars (no URLs hardcodeadas) | PASS — todos los TCP configs ya existentes en `config/envs` |
| Shape API vs contrato architect | PASS — `{ cutoffDate: string }`, `{ eventId: string }`, respuestas `Array<{id}>` y `{id, state}` correctas |
| ERD vs migración | N/A — sin migración en Phase 03 (campos ya existían) |
| Idempotencia de `forceEndTracking` | PASS — verifica `state !== IN_PROGRESS` antes de UPDATE |
| NULL-safety en `startDate` | PASS — Prisma `lte` con NULL excluye automáticamente registros con `startDate = null` |
| Guard `_autoEndRunning` | PASS — flag booleano, finally-reset correcto |
| Orden de operaciones en cron | PASS — `forceEndTracking` → `broadcastEventEnded` → `sendEventEndedNotifications` (best-effort) |
| FCM best-effort | PASS — `void .catch(() => undefined)` |
| Timeout RPC | PASS — 10_000ms en cron, 5_000ms en `TrackingNotificationsService` |

---

## Tests

| Suite | Antes | Después | Estado |
|-------|-------|---------|--------|
| `events-ms/events.service.spec` | 6 total (3 fail) | 13 total (13 pass) | PASS |
| `api-gateway/notification-scheduler` | 34 pass | 42 pass | PASS |
| `api-gateway/tracking-notifications.service.spec` (nuevo) | — | 5 pass | PASS |
| `api-gateway/tracking-http.controller.spec` (nuevo) | — | 6 pass | PASS (cubre BUG-01 con nueva auth, deberá actualizarse tras revert) |

Todos los ACs tienen cobertura de test. El test AC2 (exclusión explícita 23h) verifica matemáticamente que el filtro `lte` es correcto.

---

## Pruebas manuales

1. **Fix BUG-01 primero** — revertir auth de `endTracking` a `uid`.
2. **Commit selectivo en events-ms** — excluir los 3 archivos de otro feature.
3. **Prueba cron en staging:**
   - Crear evento → `POST /api/events/:id/tracking/start`
   - UPDATE en BD: `startDate = NOW() - INTERVAL '25 hours'`
   - Invocar `autoEndStalledEvents()` directamente (o esperar tick horario)
   - Verificar: estado `FINISHED`, log `AUTO_END: closed event`, FCM a riders aprobados, WS `tracking.event.ended`
4. **Confirmar Phase 01 en producción** antes de desplegar Phase 03.
5. **Verificar `endTracking` manual** sigue funcionando tras revert BUG-01.
