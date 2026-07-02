# Tech Lead → Human

**Fecha:** 2026-07-01T02:00:34Z
**Alcance:** Fase 1 (`legal-privacidad-edad-fase1`) — 100% backend, repo `rideglory-api`. Sin cambios en `lib/` del worktree Flutter.

## Veredicto

**ready** — sin blockers. Fase ejecutada correctamente contra el change map del architect, migraciones additivas y seguras, contratos correctos, endpoint sigue el patrón de auth existente, tests nuevos ejercitan el hallazgo crítico de forma real (no solo tipos).

## Hallazgos

Ningún hallazgo bloqueante. Notas menores (ya documentadas por backend/QA, confirmadas en esta revisión):

1. **Cada hunk contra el change map:** todos los archivos tocados por esta fase (`rideglory-contracts`: 4 modificados + 1 nuevo; `events-ms`: 2 modificados + 2 nuevos; `users-ms`: 3 modificados + 2 nuevos; `api-gateway`: 1 modificado + 1 nuevo) están en el change map del architect. Confirmado archivo por archivo con `git diff`.
2. **Archivos fuera del change map presentes en el working tree** (`events-ms/src/events/events.service.ts` + `events.controller.ts`, `rideglory-contracts/src/events/dto/event-filter.dto.ts`, `api-gateway/src/home/home.controller.ts`, `api-gateway/src/tracking/tracking-http.controller.ts`): verificado que pertenecen a otra fase/sesión en curso sobre el mismo super-repo compartido, no fueron tocados por el backend de esta fase (diff no los referencia desde ningún archivo de esta fase), y backend/QA lo documentaron explícitamente. **Acción para el humano:** separar estos archivos al commitear (ver `REVIEW_CHECKLIST.md` §1) para no mezclar dos fases en un commit.
3. **Hallazgo crítico del architect verificado correcto en código:** `registrations.service.ts::create()` ahora incluye explícitamente los 4 campos nuevos en `registrationData` (no había spread del DTO en ese objeto, a diferencia de `update()`). Sin este cambio, el DTO habría aceptado los campos (201) pero nunca se habrían persistido — exactamente el riesgo "high" señalado por el architect. Confirmado con test unitario dedicado que verifica el payload exacto de `upsert()`.
4. **Gap de cobertura no bloqueante (ya señalado por QA):** AC #6 (`GET /events/:id/registrations` con defaults correctos para registros pre-migración) y AC #7 (`organizerAcceptedResponsibilityAt` vía `POST/PATCH /events`) tienen solo cobertura indirecta (schema con defaults SQL + DTOs con spread completo, verificado por lectura de código), sin test dedicado. Riesgo bajo: ambos son extensiones de objetos que ya se serializan completos vía spread (`enrichRegistrationWithVehicle`, `events.service.ts` create/update), verificado por el architect y por esta revisión. Recomendado (no bloqueante) cerrar el gap en Fase 2.

## Seguridad

- Sin secretos, credenciales ni tokens hardcodeados en el diff.
- Sin SQL concatenado — todas las migraciones son DDL Prisma generado (`ALTER TABLE ... ADD COLUMN`, additivo, verificado en `migration.sql` de ambos MS).
- `POST /users/me/medical-consent` sigue el patrón de auth Firebase existente en `api-gateway`: usa `request.user?.email` (guard global `APP_GUARD`, mismo mecanismo que `GET /users/me`/`findMe`), lanza `UnauthorizedException` (401) si no hay email — sin `@Public()`. Verificado en el diff y en el test `users.controller.spec.ts` (caso sin email → throw).
- No hay PII (datos médicos, `bloodType`, etc.) en ningún `Logger.log`/`console.log` del diff — el único log nuevo (`users.service.ts::acceptMedicalConsent`) registra `user.id` y `consentVersion` (un string de versión, no dato médico), no contenido médico sensible.
- `shareMedicalInfo`/`allowOrganizerContact` tienen `DEFAULT false` explícito en SQL — comportamiento seguro por defecto para registros pre-migración (no compartir datos médicos ni contacto sin consentimiento explícito). Verificado en `migration.sql` y en el schema.
- `NOT_SHARED_SENTINEL` es una constante de dominio (`'__NOT_SHARED__'`), no un secreto — correctamente ubicada en contratos compartidos.

## Arquitectura

- Clean Architecture / capas backend: cambios respetan la separación DTO (contracts) → schema/persistencia (MS) → exposición HTTP (gateway); ningún MS expone lógica de otro.
- Contratos: `CreateRegistrationDto` con los 4 campos `@IsOptional()` (booleanos `@IsBoolean()`, fecha `@Type(() => Date) @IsDate()`, versión `@IsString()`) — correcto para no bloquear la validación de negocio de Fase 2. `EventRegistrationDto` de respuesta con los mismos campos no-opcionales — correcto, ya que tras la migración todo registro (nuevo o histórico) tiene valores (default o null).
- `CreateRegistrationPayloadDto extends CreateRegistrationDto` (composite DTO usado internamente por `events-ms`) hereda los campos nuevos automáticamente — verificado, sin necesidad de tocarlo.
- Shape API vs contrato: `POST /users/me/medical-consent` → `{ consentVersion }` → `{ medicalConsentAcceptedAt }`, coincide con el contrato documentado por el architect y con `MedicalConsentDto`/`MedicalConsentResponseDto`.
- ERD vs migración: schema Prisma y `migration.sql` coinciden 1:1 en ambos MS (`events-ms`: 5 columnas; `users-ms`: 1 columna). No se tocó `sosTriggeredAt` (verificado intacto en `schema.prisma`).
- Sin variables de entorno nuevas ni URLs hardcodeadas introducidas por esta fase.
- Orden del gotcha de contratos (`npm run build` en `rideglory-contracts` antes de `pnpm install` en cada MS) fue seguido según el handoff de backend; confirmado indirectamente por `nest build` limpio en los 3 MS (falla con `MODULE_NOT_FOUND` si el orden es incorrecto).

## Tests

- Cada AC crítico tiene un test que falla sin el cambio:
  - AC #5 (persistencia de los 4 campos en `registrations.service.ts::create()`): `registrations.service.spec.ts` — sin el fix del architect (agregar los campos al objeto `registrationData`), el `expect(mockUpsert).toHaveBeenCalledWith(...)` con `shareMedicalInfo: true` etc. habría fallado (el objeto real no los incluiría). Verificado leyendo el test contra el código real: el test asertúa el payload exacto, no solo que no lance error.
  - AC #8 (`acceptMedicalConsent` persiste y retorna): `users.service.spec.ts` — sin el método nuevo, la importación/instanciación fallaría en compilación.
  - Endpoint gateway: `users.controller.spec.ts` — verifica forward de payload y 401 sin email; sin el endpoint nuevo, `controller.acceptMedicalConsent` no existiría (fallo de compilación).
- Gaps documentados (no bloqueantes, ver Hallazgos #4): AC #6 y AC #7 sin test dedicado.
- Conteos antes/después re-verificados por QA, coinciden con lo reportado por backend: mismos rojos pre-existentes en los 3 MS (no relacionados con esta fase), +6 tests nuevos en verde (2 por MS/gateway tocado).
- `npm run build` (contracts) y `nest build`/`tsc --noEmit` (los 3 MS) sin errores.

## Pruebas manuales

- No se realizó smoke E2E HTTP con JWT Firebase real contra `POST /events/:id/registrations` ni `POST /users/me/medical-consent` — documentado y justificado por backend/QA (evitar reiniciar servidores activos de otra sesión de desarrollo en los mismos puertos). Aceptable para esta fase dado que el AC crítico (persistencia real, #5) está cubierto por test unitario que ejercita el código real (`create()` con Prisma mockeado, sin mockear la lógica de construcción del payload).
- Verificado manualmente (por QA) `curl -X POST /api/users/me/medical-consent` sin token → 401 (confirma que la ruta existe y aplica el guard, no 404/500).
- Verificado manualmente `psql \d "EventRegistration"`, `\d "Event"`, `\d "User"` — columnas presentes con tipos/nullability/defaults correctos, coincidiendo con `analysis/MIGRATION_PLAN.md`.
- **Pendiente recomendado para el humano antes de mergear a un ambiente compartido:** smoke E2E real de `POST /events/:id/registrations` con un JWT Firebase válido, seguido de `GET /events/:id/registrations`, para cerrar el gap de AC #6 con evidencia end-to-end (no solo unitaria).
