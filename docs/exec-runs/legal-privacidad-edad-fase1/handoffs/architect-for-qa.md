> Slim handoff — read this before handoffs/architect.md

# Architect → QA

Fase 100% backend (`rideglory-api`), nada en `lib/` de este worktree Flutter cambia. No aplica `flutter test`/`dart analyze` en esta fase.

## Comandos de verificación (en `/Users/cami/Developer/Personal/rideglory-api`)

```bash
# Contratos
cd rideglory-contracts && npm run build   # exit 0, sin errores TS

# Migraciones
cd events-ms && npx prisma migrate status   # "Database schema is up to date"
cd users-ms && npx prisma migrate status    # "Database schema is up to date"

# Arranque sin MODULE_NOT_FOUND
cd events-ms && pnpm run start:dev
cd users-ms && pnpm run start:dev
cd api-gateway && pnpm run start:dev
```

## Trazabilidad de criterios de aceptación (PRD §5)

1. `events-ms prisma migrate status` "up to date"; verificar columnas `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` en `EventRegistration` y `organizerAcceptedResponsibilityAt` en `Event` vía `\d "EventRegistration"` / `\d "Event"` en psql, o Prisma Studio.
2. `users-ms prisma migrate status` "up to date"; columna `medicalConsentAcceptedAt` en `User`.
3. `npm run build` en `rideglory-contracts`, exit code 0.
4. `pnpm install` sin errores en `events-ms`, `users-ms`, `api-gateway`; los 3 arrancan con `start:dev` sin `MODULE_NOT_FOUND`.
5. **Crítico:** `POST /events/:id/registrations` con los 4 campos nuevos → 201 (no 400) Y los valores realmente persistidos en la tabla (no solo aceptados por validación). Este es el hallazgo de mayor riesgo de la fase — `registrations.service.ts::create()` requiere una edición explícita para persistir, no basta con el DTO. Verificar con una query directa a DB o `GET`/`findByEvent` después del POST.
6. `GET /events/:id/registrations` retorna los 4 campos; para registros pre-migración: booleanos `false`, fecha/versión `null`.
7. `POST /events` o `PATCH /events/:id` con `organizerAcceptedResponsibilityAt` → 201/200, persistido.
8. `POST /users/me/medical-consent` autenticado con `{ consentVersion }` → 201 `{ medicalConsentAcceptedAt }`, persistido.
9. `GET /users/me` incluye `medicalConsentAcceptedAt` (puede ser `null`).
10. `NOT_SHARED_SENTINEL` importable desde `@rideglory/contracts` sin error de compilación en `events-ms` y `users-ms` (verificar con un import de prueba o revisando que `npm run build` de contracts lo exporte).

## Fuera de alcance — no reportar como bug si falta

- Validación `422 RISK_NOT_ACCEPTED`, ofuscación `UNDERAGE_RIDER` → Fase 2.
- Cualquier UI o modelo Flutter → Fases 3-6.
- Tests unitarios de lógica de negocio de inscripciones → Fase 2.

> Full detail: handoffs/architect.md
