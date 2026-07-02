# PRD Normalizado — Fase 2: Validación de edad y ofuscación condicional en backend

**Slug:** `legal-privacidad-edad-fase2`
**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-02-validacion-de-edad-y-ofuscacion-condicional-en-b.md`
**Fase id (plan origen):** 2 — dependsOn [1]
**Nivel rg-exec recomendado por el plan:** `full`
**Generado:** 2026-07-01T04:17:40Z

---

## 1 Objetivo

Garantizar, a nivel de backend (`events-ms`), que ningún menor de edad pueda inscribirse a un evento, y que el organizador solo vea datos médicos o PII (identificación, contacto) de los riders cuando las reglas de privacidad definidas en Fase 1 lo permitan — sin que Flutter necesite implementar lógica de ofuscación propia.

## 2 Por que

- Cumplimiento legal/privacidad: menores de edad no deben poder inscribirse a rodadas motociclísticas (riesgo de responsabilidad legal para el organizador y la plataforma).
- Protección de datos médicos y PII de los riders: solo deben exponerse al organizador bajo condiciones específicas (evento en curso + consentimiento explícito, o SOS activo) para minimizar exposición innecesaria de datos sensibles.
- Es la fase que cierra la lógica de servidor de la que dependen las fases de Flutter (3-7): centraliza la validación y la ofuscación en un único punto (`RegistrationsService`) para evitar que cada cliente reimplemente estas reglas.

## 3 Alcance

### Entra
- Pre-flight gate: confirmar que `Event.sosTriggeredAt DateTime?` existe en `events-ms/prisma/schema.prisma` (ya existía en scan, línea 77); si no, agregarlo + migración Prisma antes de tocar 2b.
- Confirmar que los 4 campos de Fase 1 (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) existen en `EventRegistration`. Bloqueo duro si Fase 1 no está completa.
- **2a — Validación de edad** en `RegistrationsService.create()`: calcular edad desde `birthDate`; rechazar con `RpcException({ status: 422, message: 'UNDERAGE_RIDER' })` si el rider tiene menos de 18 años. Insertar inmediatamente después de `ensureUserHasNoActiveRegistration()` y antes de `ensureVehicleIdForNonOwner()` (fail-fast, antes de `persistRiderProfile`).
- **2b — Ofuscación condicional** en `RegistrationsService.findByEvent()`: capturar el retorno de `ensureEventExists()`, y aplicar un método privado `applyPrivacyMask(registration, event)` a cada registro **después** de `enrichRegistrationsWithVehicle` (para no perder `vehicleSummary`), con 4 capas de reglas (ver tabla abajo).
- Ajuste del mapper de respuesta para que `bloodType` se tipe/asigne como `string` (no como enum `BloodType`) cuando está ofuscado.
- Tests unitarios obligatorios: 4 casos límite de edad (`registrations.service.age-validation.spec.ts`) + 5 combinaciones de ofuscación (`registrations.service.privacy-mask.spec.ts`).
- Verificación de tipado: `npx tsc --noEmit` en `events-ms` sin errores.

### No entra
- Cambios en Flutter (Fases 3-7 del plan; fuera de esta fase).
- Ofuscación en `findMyRegistrationForEvent` (vista del rider sobre su propia inscripción — no aplica ofuscación).
- Ofuscación en `findMyRegistrations` (vista propia del rider).
- Validación de `riskAcceptedAt` al crear inscripción (ya cerrada en Fase 1 como `422 RISK_NOT_ACCEPTED`).
- Validación de `organizerAcceptedResponsibilityAt` al publicar evento (Fase 1 y Fase 5).
- Cambios en `rideglory-contracts` (ya cerrados en Fase 1, incluyendo `bloodType: BloodType | string`).

## 4 Areas afectadas (best-effort)

- `rideglory-api` (submódulo `events-ms`):
  - `events-ms/src/registrations/registrations.service.ts` — método `create()` (validación de edad), método `findByEvent()` (captura de `event`, aplicación de `applyPrivacyMask`), nuevo método privado `applyPrivacyMask()`.
  - `events-ms/prisma/schema.prisma` — solo si `sosTriggeredAt` no existe (contingencia).
  - `events-ms/prisma/migrations/` — solo si aplica la contingencia anterior.
  - Nuevos archivos de test: `events-ms/src/registrations/registrations.service.age-validation.spec.ts`, `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts`.
- No afecta código Flutter (`lib/`) en esta fase.
- Depende de contratos ya cerrados en `rideglory-contracts` por Fase 1 (no se modifican aquí).

## 5 Criterios de aceptacion (numerados, observables, testeables)

Preservados literalmente de la fuente (fase 2 del plan):

1. **(Unitario)** `RegistrationsService.create()` lanza `RpcException` con `status: 422` y `message: 'UNDERAGE_RIDER'` cuando `birthDate` corresponde a 17 años 364 días antes de hoy.
2. **(Unitario)** `RegistrationsService.create()` retorna la inscripción sin lanzar excepción cuando `birthDate` corresponde a exactamente 18 años antes de hoy (cumpleaños hoy).
3. Un `GET /events/:eventId/registrations` con evento en estado `SCHEDULED` retorna los campos `eps`, `medicalInsurance`, `bloodType` con valor `"__NOT_SHARED__"`, independientemente de `shareMedicalInfo`.
4. Un `GET /events/:eventId/registrations` con evento en `IN_PROGRESS` y `registration.shareMedicalInfo = true` retorna `eps`, `bloodType` con valores reales del rider.
5. Un `GET /events/:eventId/registrations` con evento en `IN_PROGRESS` y `registration.shareMedicalInfo = false` retorna `eps`, `bloodType` con valor `"__NOT_SHARED__"`.
6. Un `GET /events/:eventId/registrations` con `registration.allowOrganizerContact = false` retorna `phone` con valor `"••••"`.
7. Un `GET /events/:eventId/registrations` con `registration.allowOrganizerContact = true` retorna `phone` con el número real del rider.
8. Un `GET /events/:eventId/registrations` con `event.sosTriggeredAt = null` retorna `identificationNumber`, `email`, `residenceCity` con valor `"••••"`.
9. Un `GET /events/:eventId/registrations` con `event.sosTriggeredAt` distinto de `null` retorna `identificationNumber`, `email`, `residenceCity` con valores reales.
10. El campo `bloodType` nunca lanza excepción de tipado TypeScript en el mapper cuando retorna `"__NOT_SHARED__"` (verificado con `npx tsc --noEmit`).
11. `GET /events/:eventId/registrations/me` (endpoint del rider) NO aplica ofuscación — retorna todos los campos con valores reales del rider sobre su propia inscripción.
12. Todos los tests unitarios pasan: `npx jest registrations.service.age-validation registrations.service.privacy-mask` → 0 failures.

### Tabla de reglas de ofuscación (referencia para criterios 3-9)

| Campo(s) | Condición para mostrar valor real | Centinela si ofuscado |
|---|---|---|
| `eps`, `medicalInsurance`, `bloodType` | `event.state === 'IN_PROGRESS' && registration.shareMedicalInfo === true` | `"__NOT_SHARED__"` |
| `emergencyContactName`, `emergencyContactPhone` | `event.state === 'IN_PROGRESS'` | `"••••"` |
| `phone` | `registration.allowOrganizerContact === true` | `"••••"` |
| `identificationNumber`, `email`, `residenceCity` | `event.sosTriggeredAt !== null` (SOS activo) | `"••••"` |

## 6 Guardrails de regresion

- No romper el flujo actual de inscripción: `create()` debe seguir validando en el mismo orden pre-existente (`ensureEventExists` → guard owner → `ensureUserHasNoActiveRegistration` → [NUEVO: validación de edad] → `ensureVehicleIdForNonOwner` → `validateAllowedBrands` → `persistRiderProfile` → `registrationData` → `upsert`). La validación de edad debe ser fail-fast, antes de `persistRiderProfile` y de construir `registrationData`.
- No romper `findMyRegistrationForEvent` ni `findMyRegistrations`: estos endpoints NO deben pasar por `applyPrivacyMask` (ofuscación es exclusiva de `findByEvent`, vista del organizador).
- `applyPrivacyMask` debe aplicarse DESPUÉS de `enrichRegistrationsWithVehicle` (no antes), para no perder el campo `vehicleSummary` en la respuesta — riesgo R5 explícito en la fuente.
- `bloodType` debe tiparse como `string` en la firma de `applyPrivacyMask` (no como enum `BloodType`) para evitar fallos de compilación TypeScript — riesgo R1 explícito.
- `medicalInsurance` (nullable en Prisma) debe pasar el centinela `"__NOT_SHARED__"` como string cuando está ofuscado, nunca `null` en ese caso.
- No modificar `rideglory-contracts` en esta fase (ya cerrados por Fase 1); si el build de contratos falla con `MODULE_NOT_FOUND`, es un gotcha conocido (`project_contracts_rebuild_gotcha.md`) — no indica que haya que tocar contratos aquí.
- El error de validación de edad debe llevar el código semántico en el campo `message` (`'UNDERAGE_RIDER'`), no en un campo `code` — consistente con el patrón existente de `RpcException` en este servicio (nota de coordinación cross-fase A5, relevante para Fase 4 de Flutter que consumirá este contrato).
- No tocar `riskAcceptedAt` / `organizerAcceptedResponsibilityAt` (fuera de alcance, ya definidos en Fase 1/5).
- No avanzar a la sub-tarea 2b sin confirmar que los campos de Fase 1 (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) existen en Prisma — bloqueo duro documentado en la fuente (riesgo R6).
- Los tests deben instanciar `RegistrationsService` con **dos** `ClientProxy` mock (`usersService`, `vehiclesService`) — no copiar el patrón de un solo mock usado en `events.service.spec.ts` (riesgo R3 explícito).
- Correr `npx tsc --noEmit` en `events-ms` antes de dar por cerrada la fase.

## 7 Constraints heredados

- Arquitectura del backend: `rideglory-api` es un super-repo de submódulos independientes (uno por microservicio); esta fase toca únicamente `events-ms`.
- Cambios de contrato en `@rideglory/contracts` requieren `npm run build` en el paquete + `pnpm install` en cada microservicio consumidor (gotcha documentado); esta fase NO debería necesitar tocar contratos, pero si algo falla con `MODULE_NOT_FOUND`, aplicar ese remedio antes de asumir que faltan cambios de contrato.
- No hay usuarios reales en producción todavía — refactors agresivos son aceptables, pero los tests SÍ deben pasar (constraint explícito del proyecto).
- DTO write payloads deben usar `.toJson()` cuando aplique (no relevante directamente en este backend TypeScript, pero es la convención espejo del lado Flutter que consumirá este contrato en fases posteriores).
- Esta fase depende duro de Fase 1 (migraciones Prisma de `EventRegistration` + contrato `EventRegistrationDto` con `bloodType: BloodType | string` + centinelas `"__NOT_SHARED__"` / `"••••"` acordados). Si Fase 1 no está completa, esta fase no puede implementarse — gate de pre-flight obligatorio antes de escribir código de 2b.
- Nivel de ejecución recomendado por el plan original: `full` (lógica de seguridad/privacidad sensible, requiere auditor Opus verificando fórmula de edad, precedencia de condiciones de ofuscación, y tipado `bloodType`). Este normalizer no fuerza el nivel; el runner rg-exec decide el nivel real de ejecución.
