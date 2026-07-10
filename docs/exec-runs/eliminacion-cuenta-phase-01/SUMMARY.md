# SUMMARY — eliminacion-cuenta-phase-01

_Tech Lead review: 2026-07-10T16:09:26Z (contenido); veredicto actualizado 2026-07-10T17:01:49Z a
**needs_changes**; re-verificado 2026-07-10T17:06:49Z sin cambios en el código ni en el working
tree desde entonces — ver `handoffs/tech_lead.md` para el detalle. El backend y el scaffolding
Flutter descritos abajo siguen siendo correctos tal como se documentan; lo que sigue pendiente es
que la fase no se considera lista para cerrar mientras la UI (AC1/2/3/5/9) y la limpieza del
working tree sigan sin resolverse._

## Objetivo

Fijar el contrato definitivo `DELETE /users/me` y el orden de los 5 pasos de orquestación
backend (hard-delete en `users-ms` + `deleteUser` de Firebase Auth siempre último) para que las
fases 2 y 3 puedan extenderlo sin reordenar. En Flutter, dejar lista la capa domain/data/cubit
para que una fase de seguimiento solo tenga que construir la UI.

**Resultado de la corrida: PARCIAL, según lo previsto por el propio equipo.** El backend está
completo. La UI de Flutter (`DeleteAccountConfirmationPage` y sus widgets, el ítem en
`ProfileActionsList`, el `GoRoute`) **no se implementó** porque el Pencil MCP no pudo abrir
`rideglory.pen` en las 3 corridas (Design, corrección de Auditor, y Frontend re-verificando
directamente) — todas documentaron el mismo error (`MCP error -32603: Failed to access file`).
Esto es exactamente lo que manda la regla cero-tolerancia del proyecto
(`feedback_pencil_mcp_block.md`): detenerse, no inventar mockups HTML ni specs alternativas. No es
un incumplimiento del equipo de ejecución; es el comportamiento correcto ante un bloqueo externo.

## Que cambio por area

### Backend (`rideglory-api`, repo separado, working tree sucio, sin commit)

**`api-gateway`:**
- `src/auth/firebase-auth.service.ts` — nuevo `deleteUser(uid)` vía Admin SDK.
- `src/users/account-deletion.service.ts` (nuevo) — orquestador `deleteAccount(uid, email)`: 1)
  `findUserByEmail` (propaga 404 tal cual) → 2) TODO fase 2 (no-op) → 3) TODO fase 3 (no-op) → 4)
  `hardDeleteUser` → 5) `firebaseAuthService.deleteUser(uid)`, siempre último, sin try/catch que
  trague el error del paso 4.
- `src/users/users.controller.ts` — `DELETE /users/me` (`204`), `uid`/`email` resueltos
  exclusivamente de `request.user` (poblado por `FirebaseAuthGuard` desde el token verificado —
  confirmado leyendo `firebase-auth.guard.ts`, nunca de params/body).
- `src/users/users.module.ts` — registra `AccountDeletionService`, importa `AuthModule`.
- Higiene no listada en el change map original pero necesaria y de cero impacto en
  comportamiento: cambio de imports absolutos (`from 'config'`) a relativos en 3 archivos, porque
  `ts-jest` no resolvía el `paths` de `tsconfig.json` — mismo patrón que ya usa
  `maintenances.controller.ts`.

**`users-ms`:**
- `src/users/users.service.ts` — nuevo `hardDelete(id)`: `findOne(id)` (404 si no existe) +
  `prisma.user.delete()`. `remove()` (soft-delete) intacto.
- `src/users/users.controller.ts` — nuevo `@MessagePattern('hardDeleteUser')`, coexiste con
  `@MessagePattern('removeUser')` sin tocarlo.

**Tests nuevos (backend):** `account-deletion.service.spec.ts` (orden exacto de 3 pasos
observables + corte en 404 del paso 1 + corte en error del paso 4 antes del paso 5 — cubre AC7, el
criterio más importante de la fase), `firebase-auth.service.spec.ts`, `users.controller.spec.ts`
(api-gateway, incluye test explícito de params/body "envenenados"), `users.service.spec.ts` y
`users.controller.spec.ts` (users-ms, con regresión explícita de `remove()`/`removeUser`).

### Frontend (Rideglory, working tree sucio, sin commit)

Solo domain/data/cubit/l10n/analytics scaffolding — **sin ningún punto de entrada visible en la
app**:
- `lib/features/users/data/service/user_service.dart` — `@DELETE(ApiRoutes.me) deleteMyAccount()`.
- `lib/features/users/domain/repository/user_repository.dart` +
  `lib/features/users/data/repository/user_repository_impl.dart` — `deleteMyAccount()` vía
  `executeService`, retorna `Either<DomainException, Nothing>`.
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` (nuevo).
- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` (nuevo) —
  `Cubit<ResultState<Nothing>>` `@injectable`, con guard de doble-tap
  (`if (state is Loading<Nothing>) return;`).
- `lib/shared/router/app_routes.dart` — constante `deleteAccount`, **sin `GoRoute` todavía**.
- `lib/l10n/app_es.arb` (+ generados) — 14 claves `profile_deleteAccount*`, sin call site.
- `lib/core/services/analytics/analytics_events.dart` — 3 eventos nuevos sin PII
  (`accountDeletionStarted/Confirmed/Failed`), sin call site.
- `docs/features/profile.md` (§7.1 nueva) y `docs/features/users.md` (tabla de endpoints) —
  documentan el estado parcial explícitamente.

**No tocado (correctamente, por el bloqueo):**
`delete_account_confirmation_page.dart`, sus 4 widgets hijos, `app_router.dart` (`GoRoute`),
`profile_actions_list.dart` (ítem "Eliminar cuenta").

### Fuera del alcance de esta fase (dirty tree preexistente, no tocar al commitear)

El working tree tiene una cantidad grande de cambios **no relacionados con esta fase** (borrado de
`my_drafts_page.dart`/`my_drafts_view.dart`/`event_card_draft_badge.dart`, cambios en
`tracking_repository_impl.dart`, `tracking_ws_client.dart`, `login_social_section.dart`,
`event_form_cubit.dart`, etc., y ~80 archivos sin trackear de otros features). Confirmado con
`git diff` acotado a los archivos del change map de esta fase: por ejemplo `analytics_events.dart`
y `app_es.arb` tienen, en el mismo diff, tanto las 3 claves nuevas de esta fase como la
eliminación de `eventsDraftSaved`/`event_saveDraft` (feature de borradores, fase distinta).
Verificado que `eventsDraftSaved` ya no tiene referencias en el árbol (no rompe compilación), pero
es trabajo de otra fase mezclado en el mismo archivo. Ver `REVIEW_CHECKLIST.md` para cómo
commitear sin arrastrar esto.

## Archivos

**rideglory-api:**
- `api-gateway/src/auth/firebase-auth.service.ts` (+spec)
- `api-gateway/src/users/account-deletion.service.ts` (nuevo, +spec)
- `api-gateway/src/users/users.controller.ts` (+spec)
- `api-gateway/src/users/users.module.ts`
- `users-ms/src/users/users.service.ts` (+spec)
- `users-ms/src/users/users.controller.ts` (+spec)

**Rideglory:**
- `lib/features/users/data/service/user_service.dart`
- `lib/features/users/domain/repository/user_repository.dart`
- `lib/features/users/data/repository/user_repository_impl.dart`
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` (nuevo)
- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` (nuevo)
- `lib/shared/router/app_routes.dart`
- `lib/l10n/app_es.arb` (+ `app_localizations*.dart` generados)
- `lib/core/services/analytics/analytics_events.dart`
- `docs/features/profile.md`, `docs/features/users.md`
- `test/features/users/domain/use_cases/delete_account_use_case_test.dart` (nuevo)
- `test/features/users/data/repository/user_repository_impl_delete_account_test.dart` (nuevo)
- `test/features/profile/presentation/cubit/delete_account_cubit_test.dart` (nuevo)

## Pruebas

Verificado de forma independiente por este Tech Lead (no solo confiando en los handoffs):

- `flutter test` (4 archivos objetivo: cubit, use case, repo, taxonomía analytics) → **todos en
  verde**, incluye el test de guard de doble-tap.
- `dart analyze` acotado a `lib/features/users`, `lib/features/profile/presentation/cubits`,
  `app_routes.dart`, `analytics_events.dart` → **0 issues**.
- `api-gateway`: `npx jest --silent` → 16 suites/129 tests pasan, 1 suite/8 tests fallan
  (`places.service.iter3.spec.ts`) — **confirmado preexistente y no relacionado** (feature
  `places`, no tocado en esta fase).
- `users-ms`: `npx jest --silent` → **2 suites, 6 tests, todos verdes**.
- Grep de `removeUser` en todo `rideglory-api` → única aparición es la definición del
  `@MessagePattern` en `users-ms/src/users/users.controller.ts:41`; **cero callers activos** en
  todo el monorepo (ni siquiera en `api-gateway`). El guardrail "no romper llamadores existentes"
  se cumple trivialmente por ausencia de callers — correctamente anotado también en `qa.md`.
- Leído `firebase-auth.guard.ts`: confirma que `request.user.uid`/`.email` provienen siempre del
  token verificado (`decodedToken`), nunca de params/body — refuerza el guardrail del PRD.

## Riesgos/watchlist

1. **Fase incompleta por diseño, no por decisión de ingeniería** — no hay ningún punto de entrada
   end-to-end todavía. AC1, AC2, AC3, AC5, AC9, AC10 (parcial de página) quedan sin cobertura
   hasta una fase de seguimiento. Esto es aceptado y documentado explícitamente en
   `handoffs/qa.md`.
2. **`account-deletion.service.ts` resuelve el usuario interno por email, no por `uid`.** Si el
   email de Firebase Auth y el email en `users-ms` llegaran a divergir (ej. usuario cambió su
   email en Firebase pero `users-ms` no se sincronizó), `findUserByEmail` podría fallar con 404
   aunque el `uid` sea válido. No es un blocker de esta fase (mismo patrón que ya usa
   `GET /users/me` según nota de Backend), pero vale la pena que una fase futura evalúe resolver
   por `uid` si `users-ms` llega a indexarlo.
3. **Working tree con ~80 archivos no relacionados sin commitear.** Alto riesgo de que un
   `git add -A` accidental mezcle esta fase con trabajo de otras fases (borradores de eventos,
   tracking, login social, etc.). Ver checklist.
4. **AC9 (login post-borrado falla) no se verificó de punta a punta** — depende del stack local +
   una cuenta desechable real; correctamente diferido por Backend/QA, pero queda pendiente antes
   de dar por cerrado el contrato en producción.

## Mensaje de commit sugerido

Dos commits separados (repos distintos):

**rideglory-api** (`api-gateway` + `users-ms`):
```
feat(users): DELETE /users/me con orquestacion de 5 pasos y hard-delete

Fija el contrato definitivo de eliminacion de cuenta: nuevo endpoint DELETE
/users/me en api-gateway que orquesta 5 pasos fijos (resolver usuario, dos
no-ops reservados para fases 2/3, hard-delete en users-ms, y borrado en
Firebase Auth siempre como ultimo paso irreversible). Nuevo MessagePattern
hardDeleteUser en users-ms (removeUser soft-delete queda intacto).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```

**Rideglory** (solo los archivos listados en "Archivos" arriba, NUNCA `git add -A`):
```
feat(users): domain/data/cubit para eliminacion de cuenta (sin UI aun)

Agrega la capa domain/data/cubit para DELETE /users/me: UserService,
UserRepository, DeleteAccountUseCase y DeleteAccountCubit (con guard de
doble-tap). La UI (DeleteAccountConfirmationPage y el item en
ProfileActionsList) queda bloqueada hasta que rideglory.pen este accesible
via Pencil MCP - ver docs/exec-runs/eliminacion-cuenta-phase-01/.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
