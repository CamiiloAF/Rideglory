# QA-Auto handoff — legal-privacidad-edad-fase1

**Fecha:** 2026-07-01T05:10:38Z
**Agente:** qa-automator (qa-auto)
**Alcance:** 21 casos del checklist (20 backend en `rideglory-api`, 1 `na` sobre el worktree Flutter de esta fase). Ningún caso Flutter/Dart aplicó (esta fase es 100% backend). Se escribieron 2 tests unitarios nuevos (casos 3.1 y 4.3, marcados como gap por el handoff de QA de la fase) y se re-ejecutaron todos los comandos "run-existing".

## Archivos de test escritos

- `/Users/cami/Developer/Personal/rideglory-api/events-ms/src/events/events.service.spec.ts` — agregado describe `EventsService — organizerAcceptedResponsibilityAt persistence` (2 tests nuevos, caso 3.1). También se agregó `mockCreate` al mock de `PrismaClient.event` (necesario para ejercitar `create()`).
- `/Users/cami/Developer/Personal/rideglory-api/users-ms/src/users/users.service.spec.ts` — agregado describe `UsersService — findByEmail() medicalConsentAcceptedAt passthrough` (1 test nuevo, caso 4.3).

Ambos archivos son specs de backend (`*.spec.ts` dentro de `rideglory-api`), permitido por las reglas duras. No se tocó ningún archivo de `src/` de producción ni de `lib/` Flutter.

## Comandos ejecutados

```bash
cd rideglory-api/rideglory-contracts && npm run build                    # exit 0
cd rideglory-api/events-ms && pnpm install                               # exit 0 (prisma generate ok)
cd rideglory-api/users-ms && pnpm install                                # exit 0 (prisma generate ok)
cd rideglory-api/api-gateway && pnpm install                             # exit 0
cd rideglory-api/events-ms && npx jest src/events/events.service.spec.ts # 15 passed, 15 total
cd rideglory-api/events-ms && npx jest                                    # 5 suites, 44 passed, 44 total (0 failed)
cd rideglory-api/users-ms && npx jest src/users/users.service.spec.ts    # 3 passed, 3 total
cd rideglory-api/users-ms && npx jest                                     # 3 passed, 3 total
cd rideglory-api/api-gateway && npx jest                                  # 130 total, 122 passed, 8 failed (mismo FAIL preexistente: places.service.iter3.spec.ts)
cd rideglory-api/api-gateway && npx jest src/users/users.controller.spec.ts  # 2 passed, 2 total
cd rideglory-api/events-ms && npx jest src/registrations/registrations.service.spec.ts  # 2 passed, 2 total
cd rideglory-api/events-ms && npx tsc --noEmit                            # exit 0
cd rideglory-api/users-ms && npx tsc --noEmit                             # exit 0
cd rideglory-api/events-ms && npx eslint src/events/events.service.spec.ts  # 21 problems (16 errors, 5 warnings) — 14 errores/3 warnings ya preexistían antes de mi edición (verificado con git stash); mi bloque nuevo agrega 2 errores "no-unsafe-assignment" de la MISMA categoría/patrón que el resto del archivo (mocks tipados `any`, consistente con el estilo preexistente del archivo, no arreglable sin refactor amplio fuera de alcance)
cd rideglory-api/users-ms && npx eslint src/users/users.service.spec.ts   # 0 problemas
cd rideglory-api/events-ms && npx prisma migrate status                  # "Database schema is up to date!"
cd rideglory-api/users-ms && npx prisma migrate status                   # "Database schema is up to date!"
psql -h localhost -p 5432 -d events -c '\d "EventRegistration"'          # columnas confirmadas
psql -h localhost -p 5432 -d events -c '\d "Event"'                      # columnas confirmadas
psql -h localhost -p 5433 -d users -c '\d "User"'                        # columna confirmada
grep -rn "NOT_SHARED_SENTINEL" rideglory-contracts/dist rideglory-contracts/src
grep -n "shareMedicalInfo|allowOrganizerContact|riskAcceptedAt|riskAcceptanceVersion" rideglory-api/events-ms/src/registrations/registrations.service.ts
git -C rideglory-api status --short (super-repo + 4 submódulos)
git -C .claude/worktrees/legal-privacidad-edad-fase1 diff --stat
```

## Hallazgos importantes (para tech lead / humano)

### Caso 6.7 y 6.9 — el estado del repo avanzó desde que backend/QA de esta fase escribieron sus handoffs

Al re-ejecutar `npx jest` en `events-ms`, los 3 tests antes "rojos preexistentes" (TC-6/7/8 de `findUpcoming`) **ahora pasan** (44/44, 0 failed) — no por nada relacionado con esta fase, sino porque hay commits *posteriores* en el repo (`a6de8b1 fix(events): eliminar hardcode UTC-5 en findUpcoming`, y otros de fases 2/3 aparentemente distintas: cron de auto-cierre, endpoint `acceptMedicalConsent`, etc.) que ya corrigieron ese drift. No es una regresión introducida por mí ni por esta fase; documentado para que no sorprenda si el conteo no coincide byte a byte con `backend.md`/`qa.md`.

En `api-gateway` los 8 tests rojos preexistentes (`places.service.iter3.spec.ts`) siguen exactamente igual — sin regresión.

Para el caso **6.9** (`git status --short` en `rideglory-api`): a día de hoy los submódulos `events-ms` (4 commits), `users-ms` (1 commit) y `api-gateway` (3 commits) están **adelante de `origin/main` con commits locales ya creados** — incluyendo commits que corresponden textualmente al alcance de esta fase (`aa6065c feat(registrations): persistir campos de consentimiento médico y riesgo`, `d76c226 feat(users): endpoint interno acceptMedicalConsent`, `754f74c feat(users): exponer POST /users/me/medical-consent`). Esto contradice el resultado esperado literal del caso ("no hay commits nuevos creados por esta fase"): en el momento en que backend/QA de fase1 terminaron su trabajo, el árbol estaba sucio sin commitear (así lo documentaron); en algún punto posterior (probablemente revisión humana o ejecución de fases 2/3 sobre el mismo repo compartido) esos cambios sí se commitearon. Marcado `auto-fail` con esta nota — no es un bug de código, es una discrepancia de timing/proceso que el humano debe decidir si es aceptable.

### Casos 2.1–2.4, 4.1, 5A.1, 5B.1 — confirmado que la cobertura señalada en los handoffs es real y pasa

Re-ejecuté explícitamente `registrations.service.spec.ts` (cubre 2.1/2.2/2.3/2.4/5B.1) y `users.controller.spec.ts` + `users.service.spec.ts` (cubren 4.1/5A.1) — todos verdes, con asserts literales sobre el payload/valores (no solo "no crashea"). El gap real documentado por backend/QA (falta de smoke HTTP 201/JWT real) sigue siendo un gap; no intenté forzarlo sin servidor vivo con auth Firebase.

### Casos 3.1 y 4.3 — tests nuevos escritos, gap cerrado a nivel unitario

Ambos casos estaban señalados como gaps explícitos en `handoffs/qa.md` ("AC #7 ... no tiene test dedicado" y no existía cobertura de `findByEmail` con consentimiento nulo). Escribí y verifiqué:
- `create()`/`update()` de `EventsService` persisten `organizerAcceptedResponsibilityAt` en el payload real enviado a Prisma (mock de `$transaction`/`event.create`/`event.update`).
- `findByEmail()` de `UsersService` retorna `medicalConsentAcceptedAt: null` sin lanzar error para un usuario existente que nunca aceptó el consentimiento.

## Resultado global

- 18/21 casos: auto-pass (comandos re-ejecutados o tests nuevos, todos en verde, sin regresiones).
- 1/21 caso (6.9): auto-fail — discrepancia de timing entre "no se debía commitear" y el estado real del repo hoy (commits ya creados por el flujo posterior). No bloqueante para el código de esta fase, sí para el proceso.
- 2/21 casos (3.1, 4.3): auto-pass gracias a los 2 tests nuevos escritos en esta corrida (antes eran gaps).

Ver `caseResults` estructurado en el reporte del agente para detalle completo por id.
