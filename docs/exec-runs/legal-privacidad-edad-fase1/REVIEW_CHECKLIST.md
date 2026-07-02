# REVIEW_CHECKLIST — legal-privacidad-edad-fase1

Pasos manuales antes de commitear (working tree de `rideglory-api` queda sucio a propósito).

## 1. Separar cambios ajenos antes de commitear

El working tree de `rideglory-api` tiene, además de esta fase, cambios sin commitear de otra fase/sesión no relacionada. **No commitear junto con esta fase:**
- `events-ms/src/events/events.service.ts` y `events.controller.ts` (cron `findActiveEventsOlderThan`/`forceEndTracking`)
- `rideglory-contracts/src/events/dto/event-filter.dto.ts` (`authUserId`)
- `api-gateway/src/home/home.controller.ts`
- `api-gateway/src/tracking/tracking-http.controller.ts`

Usar `git add` selectivo por archivo (no `git add -A`) en cada submódulo para no mezclar ambos trabajos en el mismo commit.

## 2. Revisar diffs por submódulo

- [ ] `rideglory-contracts`: revisar `create-registration.dto.ts`, `event-registration.dto.ts`, `create-event.dto.ts`, `src/users/dto/medical-consent.dto.ts` (nuevo), `src/users/dto/index.ts`.
- [ ] `events-ms`: revisar `prisma/schema.prisma`, la migración nueva, y especialmente `registrations.service.ts::create()` (el hallazgo crítico — confirmar que los 4 campos están en el objeto `registrationData`).
- [ ] `users-ms`: revisar `prisma/schema.prisma`, la migración nueva, `users.service.ts` (`acceptMedicalConsent`), `users.controller.ts`.
- [ ] `api-gateway`: revisar `users.controller.ts` (`POST /users/me/medical-consent`).

## 3. Verificar migraciones antes de aplicar en un entorno distinto a dev local

- [ ] `events-ms` tiene drift pre-existente no relacionado (migración `20260611000000_remove_event_city`). Antes de correr `prisma migrate deploy` en cualquier entorno (staging/prod), investigar y resolver ese drift — no solo la migración de esta fase.
- [ ] Confirmar que ambas migraciones nuevas (`events-ms`, `users-ms`) son additivas (`ALTER TABLE ... ADD COLUMN`), sin `DROP`/`ALTER TYPE` destructivo — ya verificado en esta revisión, pero re-confirmar antes de aplicar contra una DB con datos reales.

## 4. Re-correr suites antes de commitear (opcional pero recomendado)

```
cd rideglory-contracts && npm run build
cd ../events-ms && npx jest src/registrations/registrations.service.spec.ts
cd ../users-ms && npx jest
cd ../api-gateway && npx jest src/users/users.controller.spec.ts
```

Confirmar que los conteos de rojos pre-existentes (3 en `events-ms`, 8 en `api-gateway`) no cambiaron, y que los 6 tests nuevos siguen en verde.

## 5. Commits sugeridos

Un commit por submódulo (ver `SUMMARY.md` → "Mensaje de commit sugerido"). Recordar: `rideglory-api` es super-repo con submódulos independientes — cada uno necesita su propio commit en su propio repo Git, y luego actualizar el puntero del super-repo si aplica.

## 6. Gaps de cobertura a considerar (no bloqueantes)

- [ ] Evaluar si vale la pena agregar, antes de Fase 2, un test dedicado para AC #6 (`GET /events/:id/registrations` con defaults pre-migración) y AC #7 (`organizerAcceptedResponsibilityAt` vía `POST/PATCH /events`).
- [ ] Si se necesita smoke E2E HTTP real (con JWT Firebase válido), reiniciar `events-ms`/`users-ms`/`api-gateway` con `pnpm run start:dev` — no se hizo en esta fase para no interrumpir servidores activos de otra sesión.

## 7. Confirmar que el worktree Flutter sigue limpio

```
cd /Users/cami/Developer/Personal/Rideglory/.claude/worktrees/legal-privacidad-edad-fase1
git status --porcelain
```

Debe mostrar únicamente `docs/exec-runs/legal-privacidad-edad-fase1/` como no rastreado — sin cambios en `lib/`.
