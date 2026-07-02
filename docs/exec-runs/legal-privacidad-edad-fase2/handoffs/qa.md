# QA — legal-privacidad-edad-fase2

**Date:** 2026-07-01T04:27:59Z
**Scope:** Backend-only phase (`rideglory-api` / `events-ms`). No Flutter/UI changes — Patrol e2e not applicable, `flutter test`/`dart analyze` not applicable (no `lib/` diff).
**Repo under test:** `/Users/cami/Developer/Personal/rideglory-api` (submodule `events-ms`), working tree dirty (not committed, per convention).

## Catalogo (PRD §5 → test)

| # | Criterio | Cobertura | Estado |
|---|----------|-----------|--------|
| 1 | 17y364d → `422 UNDERAGE_RIDER` | `registrations.service.age-validation.spec.ts` — "rejects a rider who is 17 years and 364 days old" | existente (nuevo, verificado) |
| 2 | Exactamente 18 hoy → no lanza | `registrations.service.age-validation.spec.ts` — "accepts a rider whose 18th birthday is exactly today" | nuevo, verificado |
| 3 | SCHEDULED → campos médicos `"__NOT_SHARED__"` sin importar `shareMedicalInfo` | `registrations.service.privacy-mask.spec.ts` — case 1 (usa `shareMedicalInfo: true` a propósito, para probar que igual se enmascara) | nuevo, verificado |
| 4 | IN_PROGRESS + `shareMedicalInfo=true` → médicos reales | `privacy-mask.spec.ts` — case 2 | nuevo, verificado |
| 5 | IN_PROGRESS + `shareMedicalInfo=false` → médicos `"__NOT_SHARED__"` | `privacy-mask.spec.ts` — case 3 | nuevo, verificado |
| 6 | `allowOrganizerContact=false` → `phone="••••"` | `privacy-mask.spec.ts` — case 4 (dos registros en un `findMany`) | nuevo, verificado |
| 7 | `allowOrganizerContact=true` → `phone` real | `privacy-mask.spec.ts` — case 4 | nuevo, verificado |
| 8 | `sosTriggeredAt=null` → PII `"••••"` | `privacy-mask.spec.ts` — case 5 (primera mitad) | nuevo, verificado |
| 9 | `sosTriggeredAt≠null` → PII real | `privacy-mask.spec.ts` — case 5 (segunda mitad, re-mock + segunda llamada a `findByEvent`) | nuevo, verificado |
| 10 | `bloodType` nunca causa error TS cuando `"__NOT_SHARED__"` | `npx tsc --noEmit` (0 errores) — firma de `applyPrivacyMask` tipa `bloodType: string`, no el enum Prisma `BloodType` | verificado directamente |
| 11 | `GET .../registrations/me` NO enmascarado | Lectura de código: `applyPrivacyMask` solo se invoca en `findByEvent` (línea 216); `findMyRegistrationForEvent` (219) y `findMyRegistrations` (232) no la llaman — confirmado por grep, sin test dedicado (gap menor, aceptado por el architect) | gap (aceptado, no bloqueante) |
| 12 | Todos los tests nuevos pasan, 0 failures | `npx jest registrations.service.age-validation registrations.service.privacy-mask` → 2 suites, 9 tests, 0 failures | verificado |

Nota: las specs también cubren 2 casos extra no numerados en el PRD (age-validation: "comfortably over 18" y "comfortably under 18" con 1990-01-01 / 15 años) — buena cobertura adicional, no requerida pero sin daño.

## Matriz de regresion (PRD §6 guardrail → mecanismo)

| Guardrail | Mecanismo de verificación | Resultado |
|---|---|---|
| Orden de validación en `create()` sin alterar, edad insertada entre `ensureUserHasNoActiveRegistration` y `ensureVehicleIdForNonOwner`, antes de `persistRiderProfile`/`registrationData` | Lectura del diff (`git diff` líneas 60-63) + `registrations.service.spec.ts` (existente) sigue en verde | OK — orden preservado exactamente |
| `findMyRegistrationForEvent`/`findMyRegistrations` no pasan por `applyPrivacyMask` | grep confirma única invocación en `findByEvent`; sin test dedicado | OK, con gap de test (ver Bugs/Notas) |
| `applyPrivacyMask` se aplica DESPUÉS de `enrichRegistrationsWithVehicle` | Diff: `enriched = await this.enrichRegistrationsWithVehicle(...)` seguido de `.map(applyPrivacyMask)`; spec case 1 afirma `vehicleSummary` presente tras el mask | OK, verificado explícitamente por test |
| `bloodType` tipado `string` en `applyPrivacyMask`, no enum `BloodType` | Firma genérica `T extends { ... bloodType: string ... }`; `tsc --noEmit` limpio | OK |
| `medicalInsurance` enmascarado = string `"__NOT_SHARED__"`, nunca `null` | Código: `medicalInsurance: medicalVisible ? registration.medicalInsurance : '__NOT_SHARED__'`; spec case 1 y 3 verifican `.toBe('__NOT_SHARED__')` (nunca `null`) | OK |
| No se toca `rideglory-contracts` en esta fase | `git diff --stat` en `events-ms` únicamente; no hay diff fuera del submodule | OK |
| Mensaje de error de edad en campo `message` (no `code`) | Spec: `error: expect.objectContaining({ status: 422, message: 'UNDERAGE_RIDER' })`; código usa `RpcException({ status, message })` | OK |
| No se toca `riskAcceptedAt`/`organizerAcceptedResponsibilityAt` | No aparecen en el diff | OK |
| Pre-flight: campos de Fase 1 y `sosTriggeredAt` ya existían (bloqueo duro si no) | Confirmado por el architect handoff; `schema.prisma` no aparece en el diff (no fue necesario tocarlo) | OK |
| Tests instancian `RegistrationsService` con dos `ClientProxy` mock separados (`usersService`, `vehiclesService`) | Ambas specs: `new RegistrationsService(mockUsersService as any, mockVehiclesService as any)` — dos mocks distintos | OK |
| `npx tsc --noEmit` limpio antes de cerrar la fase | Ejecutado en esta corrida QA: 0 errores | OK |

## Ejecucion

```
cd events-ms
npx tsc --noEmit
→ 0 errors

npx jest
Test Suites: 5 passed, 5 total
Tests:       42 passed, 42 total
```

Desglose relevante dentro de esos 42: 9 tests nuevos (4 age-validation + 5 privacy-mask) + 2 tests preexistentes en `registrations.service.spec.ts` (siguen en verde, no regresión) + resto de la suite `events-ms` (otros servicios, no tocados por esta fase) también en verde.

No se corrió `flutter test`/`dart analyze` — no hay diff en `lib/` (fase confirmada backend-only, sin cambios Flutter).

## Bugs

Ninguno encontrado. El diff implementa exactamente lo especificado en PRD §5/§6 y el handoff del architect; los 4 archivos de guardrail (orden de validación, post-`enrichRegistrationsWithVehicle`, tipado `bloodType`, mocks duales) se verificaron línea por línea contra el código real, no solo contra el reporte del backend agent.

## Pruebas manuales

No aplica — fase 100% backend/lógica de servicio sin superficie HTTP nueva expuesta en este alcance (controller/módulo no tocados) y sin UI. El architect y el backend agent coinciden en que la cobertura unitaria + `tsc --noEmit` es suficiente; QA lo confirma tras re-ejecutar ambos comandos de forma independiente.

Gap menor no bloqueante: criterio 11 (`GET .../registrations/me` sin enmascarar) se verifica por lectura de código (grep + diff), no por un test automatizado dedicado que instancie `findMyRegistrationForEvent`/`findMyRegistrations` y afirme ausencia de sentinelas. El propio architect handoff ya señalaba esto como aceptable ("no test currently exists... consider a quick assertion"). Dado que el código no toca esos métodos en absoluto (cero líneas de diff en ellos), el riesgo de regresión futura silenciosa es bajo pero no cero si alguien refactoriza más adelante.

## Sign-off

**green** — Los 12 criterios de aceptación del PRD §5 están cubiertos (11 por test automatizado verificado en esta corrida, 1 por lectura directa de código confirmando cero cambios en los métodos afectados). Los 10 guardrails de regresión del §6 se verificaron explícitamente contra el diff real. `npx tsc --noEmit` limpio, `npx jest` en `events-ms` completo: 42/42 tests, 0 fallos, sin regresiones. No hay cambios en Flutter (`lib/`), por lo que no aplican `flutter test`/`dart analyze`/Patrol e2e. Único hallazgo es un gap de cobertura menor y ya conocido (criterio 11 sin test dedicado), no bloqueante para el sign-off dado que el código correspondiente no fue modificado.
