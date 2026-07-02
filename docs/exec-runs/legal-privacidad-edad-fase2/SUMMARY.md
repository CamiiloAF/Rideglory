# SUMMARY — legal-privacidad-edad-fase2

**Fecha:** 2026-07-01T04:34:00Z
**Nivel:** full (ejecutado; QA lo evaluó a nivel de esfuerzo "normal" en su handoff)
**Repos afectados:** `rideglory-api`, submódulo `events-ms` únicamente. No se tocó `rideglory-contracts`, `users-ms`, `api-gateway` ni el worktree Flutter (`lib/`).

**Nota de reconstrucción:** el workflow `rg-exec` completó `Normalize → Architect → Build → Verify` (architect.md, backend.md, qa.md, QA_CHECKLIST.md quedaron escritos correctamente) pero la fase final `Review` (Tech Lead) no persistió sus artefactos (`SUMMARY.md`, `REVIEW_CHECKLIST.md`, `handoffs/tech_lead.md`) pese a que el resultado del workflow reportó `techLeadVerdict: "ready"`. Este documento fue reconstruido manualmente a partir de los handoffs reales que sí quedaron en disco (`architect.md`, `backend.md`, `qa.md`) y de una verificación independiente del diff y de la suite de tests (`npx jest registrations.service*` → 3 suites, 11 tests, 0 failures, re-ejecutado fuera del workflow).

## Objetivo

Garantizar en `events-ms` que ningún menor de 18 años pueda inscribirse a un evento, y que el organizador solo vea datos médicos/PII de los riders cuando las reglas de privacidad de Fase 1 lo permiten.

## Que cambio

### `src/registrations/registrations.service.ts`

- **`create()`**: nuevo guard privado `ensureRiderIsAdult(birthDate)` insertado inmediatamente después de `ensureUserHasNoActiveRegistration()` y antes de `ensureVehicleIdForNonOwner()` — fail-fast antes de `persistRiderProfile()`. Calcula edad exacta (año/mes/día) y lanza `RpcException({ status: 422, message: 'UNDERAGE_RIDER' })` si `age < 18`.
- **`findByEvent()`**: ahora captura el `event` retornado por `ensureEventExists()` (antes se descartaba) y aplica `applyPrivacyMask(registration, event)` a cada registro **después** de `enrichRegistrationsWithVehicle()`, preservando `vehicleSummary`.
- **`applyPrivacyMask()`** (nuevo, privado, genérico): aplica 4 capas de ofuscación condicional:
  - `eps` / `medicalInsurance` / `bloodType` → `"__NOT_SHARED__"` salvo `event.state === IN_PROGRESS && shareMedicalInfo === true`.
  - `emergencyContactName` / `emergencyContactPhone` → `"••••"` salvo `event.state === IN_PROGRESS`.
  - `phone` → `"••••"` salvo `allowOrganizerContact === true`.
  - `identificationNumber` / `email` / `residenceCity` → `"••••"` salvo `sosTriggeredAt !== null`.
  - `bloodType` tipado como `string` genérico en la firma (no el enum Prisma `BloodType`), para aceptar el sentinela sin error de tipos.
- `findMyRegistrationForEvent` y `findMyRegistrations` **no** invocan `applyPrivacyMask` (confirmado por grep — son la vista propia del rider, sin ofuscación).

### Archivos nuevos

- `src/registrations/registrations.service.age-validation.spec.ts` — 4 tests: rechaza 17a364d, acepta exactamente 18 hoy, casos claramente mayor/menor.
- `src/registrations/registrations.service.privacy-mask.spec.ts` — 5 tests: SCHEDULED enmascara médicos aunque `shareMedicalInfo=true`; IN_PROGRESS+`shareMedicalInfo=true` revela médicos; IN_PROGRESS+`shareMedicalInfo=false` enmascara; `allowOrganizerContact` true/false sobre `phone`; `sosTriggeredAt` null/con-fecha sobre PII.

## Pruebas

- `npx tsc --noEmit` en `events-ms` → 0 errores.
- `npx jest` completo en `events-ms` → 5 test suites, 42 tests, 0 failures (9 nuevos + 2 preexistentes de `registrations.service.spec.ts` de Fase 1 + resto de la suite sin tocar).
- Re-verificado independientemente por esta reconstrucción: `npx jest registrations.service` → 3 suites, 11 tests, 0 failures.
- QA (`handoffs/qa.md`) confirma los 12 criterios del PRD §5 cubiertos (11 por test automatizado, 1 por lectura de código) y los 10 guardrails de regresión del §6 verificados contra el diff real.

## Gaps / riesgos (documentados por QA, no bloqueantes)

- Criterio "GET .../registrations/me NO enmascarado" se verifica por lectura de código (grep, cero invocaciones de `applyPrivacyMask` en esos métodos), no por un test automatizado dedicado. Riesgo bajo — el código de esos métodos no cambió en esta fase.
- `QA_CHECKLIST.md` es la plantilla de casos manuales/exploratorios entregada para verificación humana o `/qa-auto` — queda sin marcar (blanco) a propósito hasta que se ejecute.

## Mensaje de commit sugerido

```
feat(registrations): validar edad mínima y ofuscar PII/datos médicos en findByEvent

Rechaza inscripciones de menores de 18 años con 422 UNDERAGE_RIDER (fail-fast
antes de persistir el perfil del rider). Aplica ofuscación condicional de 4
capas (médicos, contacto de emergencia, teléfono, PII) en findByEvent según
estado del evento, shareMedicalInfo, allowOrganizerContact y sosTriggeredAt.
findMyRegistrationForEvent/findMyRegistrations quedan sin enmascarar (vista
propia del rider).
```
