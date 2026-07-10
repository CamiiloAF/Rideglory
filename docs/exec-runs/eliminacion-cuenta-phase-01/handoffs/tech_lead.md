# Tech Lead handoff — eliminacion-cuenta-phase-01

_2026-07-10T17:06:49Z (re-revisión tras solicitud de correcciones; reemplaza la corrida anterior
de este mismo archivo, 2026-07-10T17:01:49Z, que ya veredicteó "needs_changes" — ver
`architect.md`/`backend.md`/`frontend.md`/`qa.md`/`audit_frontend.md`). **Resultado de esta
re-verificación: no se detectó ningún cambio de código ni de artefactos desde la revisión
anterior** (`git diff --stat` en `Rideglory` idéntico; `git status`/`git diff` en
`rideglory-api/api-gateway` y `rideglory-api/users-ms` idénticos; `find lib -iname
"*delete_account*"` sigue devolviendo únicamente el cubit y el use case, cero página/widgets; no
existe `docs/plans/eliminacion-cuenta/` con nueva fase de corrección). Ambos blockers de la
revisión anterior siguen presentes sin resolver, así que el veredicto se mantiene._

## Veredicto

**needs_changes** (sin cambios respecto a la revisión anterior — los dos blockers siguen abiertos)

El código que sí se escribió (backend completo, domain/data/cubit de Flutter) está limpio,
correcto y bien testeado — no tiene defectos de seguridad ni arquitectura. Pero la fase no puede
cerrarse ni commitearse "tal cual" por dos razones concretas y accionables:

1. La pieza central del PRD (UI de eliminación de cuenta) **no existe** — 5 de 11 criterios de
   aceptación (AC1, AC2, AC3, AC5, AC9) son gaps totales, no parciales. El propio equipo (Design,
   Frontend, QA, Auditor Opus) documentó 8 intentos bloqueados por Pencil MCP y correctamente no
   inventó un mockup alternativo. Es un bloqueo externo legítimo, no un defecto de ingeniería —
   pero significa que esta fase, como está, no es demostrable end-to-end y no debería mergearse
   presentándose como "hecha".
2. El working tree mezcla ~80 archivos de otras fases/trabajo no relacionado (borrado de
   `my_drafts_*`, `event_card_draft_badge.dart`, cambios en `tracking_ws_client.dart`,
   `tracking_repository_impl.dart`, `login_social_section.dart`, `event_form_cubit.dart`,
   `rideglory.pen` con ±11k líneas de diff, decenas de archivos de test/Patrol sin trackear,
   `docs/features/*.md`). Un `git add -A` accidental commitearía trabajo de fases distintas bajo
   el mensaje de esta fase. Esto es un riesgo real de higiene de repo, no solo cosmético.

Ninguno de los dos puntos es un bug en el código nuevo de esta fase; ambos son condiciones que
deben resolverse (desbloquear Pencil + separar el commit) antes de que un humano pueda commitear
con confianza.

## Hallazgos

1. **Blocker (frontend) — UI no implementada, 5 ACs en gap total.** `AC1` (item en
   `ProfileActionsList` → página dedicada), `AC2` (lista completa de qué se borra), `AC3` (botón
   deshabilitado hasta activar el switch), `AC5` (limpieza de cubits + `goAndClearStack` en éxito),
   `AC9` (login post-borrado falla) no tienen ningún código que los implemente. Confirmado con grep
   directo: `profile_actions_list.dart` sin mención a "Eliminar cuenta"/`deleteAccount`;
   `app_router.dart` sin `GoRoute` para `deleteAccount`; `find lib -iname "*delete_account*"` solo
   encuentra el cubit y el use case (domain/data), cero archivos de página o widgets. No es una
   omisión — está causado por un bloqueo externo (Pencil MCP inaccesible, documentado en
   `handoffs/design.md` con 6+ intentos independientes), pero sigue siendo un blocker para cerrar
   la fase.
2. **Blocker (frontend) — working tree contaminado con ~80 archivos de otras fases.** Ver
   `git diff --stat` de esta corrida: incluye borrado de `my_drafts_page.dart`/`my_drafts_view.dart`/
   `event_card_draft_badge.dart`, cambios en `tracking_ws_client.dart`,
   `tracking_repository_impl.dart`, `login_social_section.dart`, `event_form_cubit.dart`,
   `event_step_nav_bar.dart`, `events_cubit.dart`, `live_tracking_cubit.dart`,
   `tecnomecanica_empty_state.dart`, `garage_archived_section.dart`, `rideglory.pen` (11333 líneas
   de diff), y decenas de archivos de test/Patrol sin trackear (`??` en `git status`). Además,
   `lib/core/services/analytics/analytics_events.dart` y `lib/l10n/app_es.arb` mezclan, en el mismo
   diff, los agregados legítimos de esta fase (3 eventos, 14 claves `profile_deleteAccount_*`) con
   una eliminación no relacionada (`eventsDraftSaved`, `event_saveDraft`, claves de "Mis
   borradores"). Verificado que `eventsDraftSaved` ya no tiene referencias activas (no rompe
   compilación), pero es trabajo de otra fase en el mismo archivo — requiere separación manual
   antes de commitear (ver `REVIEW_CHECKLIST.md`).
3. **Watchlist (no bloquea) — `AccountDeletionService.deleteAccount` resuelve el usuario interno
   vía `findUserByEmail(email)`, no por `uid`.** Si el email de Firebase Auth y el de `users-ms`
   divergieran, el paso 1 fallaría con 404 aunque el `uid` fuera válido. Mismo patrón que ya usa
   `GET /users/me` (confirmado por Backend); no es una regresión de esta fase, vale evaluarlo si
   `users-ms` llega a indexar por `uid`.
4. **Watchlist (no bloquea) — AC9 (login post-borrado falla) sin cobertura automatizada.** Depende
   de stack local + cuenta desechable real; correctamente diferido por Backend/QA y documentado,
   pero es una brecha real antes de dar el contrato por "verificado en producción".

## Seguridad

- `uid`/`email` para `DELETE /users/me` se resuelven exclusivamente de `request.user`, poblado por
  `FirebaseAuthGuard` a partir del token verificado (`decodedToken.uid`/`.email`) — confirmado
  leyendo `firebase-auth.guard.ts` directamente. Nunca vienen de params/body. Test explícito en
  `api-gateway/src/users/users.controller.spec.ts` con params/body "envenenados" lo verifica.
- Sin secretos ni credenciales hardcodeadas en el diff. `FirebaseAuthService.deleteUser` reutiliza
  `this.firebaseApp` ya inicializado (Admin SDK).
- Sin SQL concatenado — `hardDelete` usa Prisma `delete({ where: { id } })` parametrizado.
- Sin PII nueva en logs: `console.error('[FirebaseAuth] deleteUser failed:', error)` loguea el
  objeto de error del SDK, no `uid`/email directamente — mismo patrón que el método existente en el
  mismo archivo, no es un patrón nuevo introducido por esta fase.
- Los 3 eventos de analytics (`accountDeletionStarted/Confirmed/Failed`) pasan
  `analytics_taxonomy_no_pii_test.dart` sin params, cero PII.
- Irreversibilidad: `hardDelete` es un borrado físico real (`prisma.user.delete`), coherente con la
  promesa publicada en `docs/web/delete-account.html`. No hay endpoint de "deshacer" — correcto
  para el contrato que se está fijando.

## Arquitectura

- Clean Architecture respetada en Flutter para lo entregado: `UserService` (data/service) →
  `UserRepositoryImpl` (data/repository, `executeService`) → `UserRepository` (domain/repository) →
  `DeleteAccountUseCase` (domain/use_cases) → `DeleteAccountCubit` (presentation, `@injectable`,
  cubit de una sola pantalla, sin registrar en el `MultiBlocProvider` raíz). Sin `BuildContext` en
  domain/data, sin DTOs expuestos a presentation.
- `ResultState<T>` usado correctamente (`Cubit<ResultState<Nothing>>`), sin flags booleanos.
- Guard de doble-tap: `if (state is Loading<Nothing>) return;` al inicio del método del cubit,
  verificado con test de dos llamadas concurrentes.
- Backend: orquestación de 5 pasos vive en `AccountDeletionService`, separado del controller. Los
  pasos 2/3 son literalmente comentarios `// TODO fase X`, sin código placeholder que pueda fallar
  o bloquear, tal como exige el guardrail.
- `hardDeleteUser` es un `MessagePattern` nuevo y separado de `removeUser`; no hay mutación del
  soft-delete existente (confirmado por lectura directa + grep, cero callers activos de
  `removeUser` en todo el monorepo).
- No hay URLs hardcodeadas nuevas; usa `ApiRoutes.me` existente. Sin migraciones de esquema nuevas
  (correcto, el PRD las prohíbe explícitamente para esta fase).
- Nota de higiene de Backend (imports absolutos → relativos en 3 archivos de `api-gateway` para que
  `ts-jest` resuelva) está fuera del change map original pero es necesaria y de cero impacto en
  comportamiento — mismo patrón que `maintenances.controller.ts`; no lo considero violación.
- Lo que **no** se puede evaluar arquitectónicamente porque no existe: `DeleteAccountConfirmationPage`
  y sus 4 widgets hijos, el `GoRoute`, el item en `ProfileActionsList`.

## Tests

Verificado de forma independiente (no solo leyendo los handoffs):

- `flutter test` sobre los archivos nuevos/relevantes de esta fase → verdes, incluye el guard de
  doble-tap (`verify(() => mockUseCase()).called(1)` tras dos llamadas concurrentes).
- `dart analyze` acotado a los paths tocados → 0 issues.
- `api-gateway`: `npx jest --silent` → 16 suites/129 tests pasan; la única suite que falla
  (`places.service.iter3.spec.ts`, 8 tests) es preexistente y no relacionada (mismo conteo de
  fallos que el baseline documentado por Backend).
- `users-ms`: `npx jest --silent` → 2 suites, 6 tests, todos verdes.
- AC7 (orden fijo de 5 pasos, fallo en paso 4 nunca invoca paso 5) tiene el test más importante de
  la fase: `account-deletion.service.spec.ts`, 3 casos con orden observable y dos cortes de cadena
  distintos (404 en paso 1, error en paso 4). Código fuente leído: sin try/catch que trague el
  error del paso 4.
- Cada AC implementado tiene un test que fallaría sin el cambio correspondiente. Los AC que
  dependen de la UI bloqueada (AC1, AC2, AC3, AC5, AC9, AC10-parcial) **no tienen test porque no
  hay código que ejercitar** — correctamente catalogados como GAP (no oculto) en `handoffs/qa.md` y
  en `audit_frontend.md`, no como "cubierto".

## Pruebas manuales

Pendientes, listadas en `REVIEW_CHECKLIST.md`:
- `DELETE /api/users/me` end-to-end contra stack local con cuenta desechable (204, hard delete real
  en BD, login posterior falla, segundo DELETE con mismo token inválido) — cubre AC9, sin
  automatizar todavía.
- Confirmar que `rideglory.pen` vuelve a ser accesible vía Pencil MCP antes de relanzar Design → UX
  Review → Frontend para completar la pieza de UI bloqueada de esta fase.
