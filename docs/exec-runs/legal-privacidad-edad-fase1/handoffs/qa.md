# QA → Human

**Fecha:** 2026-07-01T01:56:45Z
**Alcance:** Fase 1 (`legal-privacidad-edad-fase1`) — 100% backend, repo `rideglory-api` (`/Users/cami/Developer/Personal/rideglory-api`). No hay cambios en `lib/` de este worktree Flutter (confirmado: `git diff --stat` en el worktree solo muestra el directorio nuevo `docs/exec-runs/legal-privacidad-edad-fase1/`, sin código Dart tocado).

## Catálogo — AC (PRD_NORMALIZED §5) → cobertura

| # | AC | Cobertura | Evidencia |
|---|----|-----------|-----------|
| 1 | Migración `events-ms` aplicada, 5 columnas nuevas | existente (verificación directa) | `npx prisma migrate status` → "up to date"; `\d "EventRegistration"` y `\d "Event"` en psql confirman `shareMedicalInfo boolean not null default false`, `allowOrganizerContact boolean not null default false`, `riskAcceptedAt timestamp nullable`, `riskAcceptanceVersion text nullable`, `organizerAcceptedResponsibilityAt timestamp nullable` |
| 2 | Migración `users-ms` aplicada, columna `medicalConsentAcceptedAt` | existente (verificación directa) | `npx prisma migrate status` → "up to date"; `\d "User"` confirma `medicalConsentAcceptedAt timestamp nullable` |
| 3 | `rideglory-contracts` compila sin errores | existente (verificación directa) | `npm run build` → exit 0, sin output de error |
| 4 | Los 3 MS levantan sin `MODULE_NOT_FOUND` | existente (verificación indirecta) | `pnpm run start:dev` de `events-ms`/`users-ms`/`api-gateway` ya corrían en background (puertos 3000-3004) tomando el código nuevo (backend confirmó `pnpm install` ya ejecutado); `nest build` limpio en los 3 (proxy fuerte); gateway responde `GET /api/health` 200 |
| 5 | `POST /events/:id/registrations` con 4 campos nuevos → 201 y persiste (crítico) | nuevo (unitario) | `events-ms/src/registrations/registrations.service.spec.ts` — 2 tests verifican el payload exacto enviado a `prisma.eventRegistration.upsert()` (create y update) incluye los 4 campos nuevos, y que se omiten con defaults correctos (`false`/`false`/`null`/`null`) cuando no vienen en el request. Este es el hallazgo crítico del architect (objeto `registrationData` construido campo-por-campo sin spread) — el test lo ejercita contra el código real, no solo el DTO. **Gap:** no hay smoke E2E HTTP real contra un servidor corriendo con auth Firebase válida (ver Pruebas manuales) |
| 6 | `GET /events/:id/registrations` retorna los 4 campos, defaults correctos pre-migración | gap (parcial) | Cubierto indirectamente por el esquema de DB (columnas con `DEFAULT false` para booleanos, `NULL` para fecha/versión) y por `EventRegistrationDto` no-opcional con los 4 campos — pero no hay test que ejercite el endpoint `GET` completo end-to-end sirviendo un registro pre-migración |
| 7 | `POST/PATCH events` acepta `organizerAcceptedResponsibilityAt` | gap | Campo existe en DTO y schema (verificado por compilación TS + columna DB), pero no hay test unitario ni smoke que ejercite el endpoint con este campo específico |
| 8 | `POST /users/me/medical-consent` → 201 `{ medicalConsentAcceptedAt }`, persistido | nuevo (unitario) | `users-ms/src/users/users.service.spec.ts` (2 tests: persiste y retorna el valor; lanza `RpcException` si no existe el usuario) + `api-gateway/src/users/users.controller.spec.ts` (2 tests: reenvía email+consentVersion, 401 si no hay email en JWT). Smoke manual: `curl -X POST http://localhost:3000/api/users/me/medical-consent` sin auth → `401` (confirma que la ruta existe y aplica el guard, no `404`) |
| 9 | `GET /users/me` incluye `medicalConsentAcceptedAt` | existente (por diseño) | `findByEmail` retorna el objeto Prisma completo sin selección de campos — no requiere cambio de código; columna confirmada en schema/DB. Sin test explícito nuevo, pero riesgo de regresión bajo (no se tocó lógica de selección) |
| 10 | `NOT_SHARED_SENTINEL` exportado desde contratos | existente (verificación directa) | `grep` en `dist/users/dto/medical-consent.dto.js` confirma `exports.NOT_SHARED_SENTINEL = '__NOT_SHARED__'`; `npm run build` en `rideglory-contracts` exit 0 (incluye este archivo) |

## Matriz de regresión — guardrails (PRD_NORMALIZED §6)

| Guardrail | Mecanismo de verificación | Resultado |
|---|---|---|
| No implementar `422 RISK_NOT_ACCEPTED` ni ofuscación `UNDERAGE_RIDER` en esta fase | Revisión de diff: `registrations.service.ts` solo agrega los 4 campos al objeto de persistencia, sin validación de negocio nueva; `riskAcceptedAt` es `@IsOptional()` | OK |
| No tocar modelos/DTOs/UI Flutter | `git diff --stat` en worktree Flutter vacío (solo `docs/exec-runs/`) | OK |
| No romper `sosTriggeredAt` existente | `grep` en `schema.prisma` confirma `sosTriggeredAt` intacto en línea 77, `organizerAcceptedResponsibilityAt` agregado como campo nuevo en línea 79 | OK |
| Defaults `false` explícitos en booleanos nuevos | `\d "EventRegistration"` en psql: `shareMedicalInfo boolean not null default false`, `allowOrganizerContact boolean not null default false` | OK |
| `riskAcceptedAt`/`riskAcceptanceVersion` nullable sin default | `\d "EventRegistration"`: ambas columnas nullable, sin default | OK |
| Cambio de tipo `bloodType` no rompe compilación | Revisado `event-registration.dto.ts`: `bloodType` sigue siendo `BloodType` (no se cambió el tipo en esta fase, el guardrail no aplicó); `npm run build` de contracts exit 0; `events-ms` compila (`tsc --noEmit` y `npx jest` sin errores de tipo) | OK (guardrail no ejercido porque el cambio de tipo no se hizo) |
| Orden gotcha contracts (`build` antes de `pnpm install`) | Confirmado en handoff de backend; los 3 MS arrancan sin `MODULE_NOT_FOUND` | OK |
| `POST /users/me/medical-consent` sigue patrón auth Firebase existente | Smoke manual: `curl` sin token → `401` (no `404`, no `500`); test unitario del gateway confirma `UnauthorizedException` si no hay email en JWT | OK |
| No commitear (working tree sucio) | `git status --short` en `rideglory-api` muestra cambios sin commitear en submódulos afectados + cambios ajenos preexistentes documentados por backend | OK |
| No modificar docs/PRD.md, PLAN.md, PRODUCT_STATUS.md, handoffs/**, .claude/**, nota fuente | No tocados por QA ni reportados como tocados por backend | OK |

## Ejecución

Comandos corridos en `/Users/cami/Developer/Personal/rideglory-api`:

```
cd rideglory-contracts && npm run build            → exit 0
cd events-ms && npx prisma migrate status            → "Database schema is up to date!"
cd users-ms && npx prisma migrate status             → "Database schema is up to date!"
psql \d "EventRegistration" / \d "Event" / \d "User"  → columnas confirmadas (ver Catálogo #1/#2)
cd events-ms && npx jest                              → 1 failed suite, 2 passed suites; 3 failed, 23 passed (26 total)
cd users-ms && npx jest                               → 1 passed suite; 2 passed (2 total)
cd api-gateway && npx jest                             → 1 failed suite, 11 passed suites; 8 failed, 103 passed (111 total)
curl -X POST /api/users/me/medical-consent (sin auth)  → 401
curl /api/health                                        → 200 {"status":"ok"}
```

**Nota — `flutter test` / `dart analyze`:** no aplica a esta fase (confirmado por `architect-for-qa.md` y por el diff vacío de `lib/` en este worktree). No se corrió.

### Comparación antes/después (baseline documentado por backend, re-verificado por QA)

| Repo | Antes (baseline) | Después (QA re-corrió) | Match |
|---|---|---|---|
| `rideglory-contracts` build | exit 0 | exit 0 | sí |
| `events-ms` jest | 3 failed, 21 passed (24) | 3 failed, 23 passed (26) | sí — mismos 3 rojos preexistentes en `events.service.spec.ts` (TC-6/7/8 sobre `findUpcoming`), +2 verdes nuevos |
| `users-ms` jest | "No tests found" | 1 suite, 2 passed | sí |
| `api-gateway` jest | 8 failed, 101 passed (109) | 8 failed, 103 passed (111) | sí — mismos 8 rojos preexistentes en `places.service.iter3.spec.ts`, +2 verdes nuevos |

Confirmado con `npx jest` en `api-gateway` que la única suite roja es `FAIL src/places/places.service.iter3.spec.ts` (geocoding, no relacionado con esta fase).

## Bugs

Ninguno encontrado. No hay regresiones: los conteos de fallos preexistentes se mantienen idénticos antes/después en los 3 microservicios, y todos los tests nuevos (6 en total: 2 `events-ms`, 2 `users-ms`, 2 `api-gateway`) pasan en verde.

## Pruebas manuales

- Verificación de columnas de DB vía `psql \d` en `events` (puerto 5432) y `users` (puerto 5433): todas las 6 columnas nuevas presentes con tipos/nullability/defaults correctos.
- `curl -X POST http://localhost:3000/api/users/me/medical-consent` sin token → `401 Unauthorized` (confirma que la ruta existe, aplica el guard de auth, y no da `404`).
- `curl http://localhost:3000/api/health` → `200 {"status":"ok"}` (gateway corriendo con el código nuevo, sin `MODULE_NOT_FOUND` al arrancar — los procesos en 3000-3004 ya estaban activos con `pnpm install` corrido según handoff de backend).
- **No realizado** (mismo motivo que documentó backend: no reiniciar servidores activos de otra sesión de desarrollo para no interrumpirla): smoke HTTP end-to-end completo de `POST /events/:id/registrations` y `POST /users/me/medical-consent` con un JWT Firebase válido, verificando persistencia real vía `GET` posterior. La persistencia de AC #5 (el hallazgo crítico) queda cubierta por el test unitario que ejercita `registrations.service.ts::create()` real con Prisma mockeado y verifica el payload exacto de `upsert()` — considerado suficiente para esta fase dado que es lógica pura sin I/O real de red/auth involucrada. AC #6 y #7 quedan con cobertura solo indirecta (schema + DTO), sin test unitario ni E2E dedicado — riesgo bajo (son extensiones de objetos existentes que ya se serializan completos), pero es un gap real de test coverage a tener en cuenta si Fase 2 no lo cubre.

## Sign-off

**Estado: green** (con gap de cobertura documentado, no bloqueante)

Todos los criterios de aceptación verificables sin infraestructura de auth E2E están confirmados (schema, contratos, compilación, arranque, endpoint existe y aplica auth). El criterio más crítico de la fase (persistencia real de los 4 campos en `registrations.service.ts::create()`, el hallazgo del architect sobre el objeto sin spread) está cubierto por test unitario dedicado que ejercita el código real. No hay regresiones: mismos tests rojos preexistentes antes/después en los 3 microservicios, todos los tests nuevos (6) pasan.

Gaps no bloqueantes para el humano:
- AC #6 (`GET registrations` con defaults pre-migración) y AC #7 (`organizerAcceptedResponsibilityAt` en `POST/PATCH events`) no tienen test dedicado, solo cobertura indirecta vía schema/DTO.
- No se hizo smoke E2E HTTP con auth Firebase real para AC #5 y #8 (limitación operativa: no reiniciar servidores activos de otra sesión — mismo criterio que aplicó backend).
