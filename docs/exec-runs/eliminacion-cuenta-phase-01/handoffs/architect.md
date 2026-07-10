# Architect handoff — eliminacion-cuenta-phase-01

**Date:** 2026-07-10T16:28:52Z
**Status:** done
**Nota:** Re-verificación de una corrida previa (handoff anterior fechado 2026-07-10T15:21:57Z).
Se releyó el código real de `rideglory-api` y `Rideglory` de punta a punta (no se asumió nada del
handoff anterior) y **el estado no cambió**: backend completo, capa domain/data/cubit de Flutter
completa, UI (`DeleteAccountConfirmationPage` + 4 widgets + `ProfileActionsList` + `GoRoute`) sigue
sin implementar. Las decisiones y el change map de abajo confirman los del run anterior porque
siguen siendo correctos contra el código actual; se documentan de nuevo aquí para que esta corrida
tenga su propio artefacto verificado.

## §4 corregido contra el código real (verificado de nuevo en esta corrida)

- **Backend YA implementado end-to-end** (contradice el §4 original del PRD, que lo describe como
  "por fijar"):
  - `api-gateway/src/users/account-deletion.service.ts` existe, orquesta los 5 pasos exactos:
    `findUserByEmail` → TODO fase 2 → TODO fase 3 → `hardDeleteUser` → `firebaseAuthService.deleteUser(uid)`.
    Verificado leyendo el archivo completo — coincide al carácter con el contrato fijado.
  - `api-gateway/src/users/users.controller.ts` tiene `DELETE /users/me` (`@HttpCode(204)`),
    resuelve `uid`/`email` exclusivamente de `request.user` (nunca params/body) y delega a
    `AccountDeletionService`.
  - `api-gateway/src/auth/firebase-auth.service.ts` tiene `deleteUser(uid)` vía Admin SDK,
    reutiliza `this.firebaseApp`.
  - `users-ms/src/users/users.controller.ts` tiene `@MessagePattern('hardDeleteUser')` separado de
    `@MessagePattern('removeUser')` (línea 41, sin tocar).
  - `users-ms/src/users/users.service.ts` tiene `hardDelete(id)` → `findOne(id)` (404 guard) +
    `this.user.delete({ where: { id } })`. `remove()` (soft-delete, `isDeleted: true`) intacto.
  - Specs ya existen y pasan la verificación de secuencia exacta que pide AC7: `account-deletion.service.spec.ts`
    prueba `callOrder === ['findUserByEmail', 'hardDeleteUser', 'firebaseDeleteUser']`, corte en
    404 del paso 1, y corte cuando el paso 4 lanza (paso 5 nunca se invoca). `users.controller.spec.ts`
    (api-gateway) prueba que `uid`/`email` "envenenados" en params/body se ignoran. `users-ms`
    tiene specs de `hardDelete` + regresión explícita de `remove()`.
  - Grep repetido en esta corrida (`grep -rn "removeUser" --include="*.ts" .` en todo
    `rideglory-api`, excluyendo `node_modules`/`dist`/`coverage`): únicos hits son la definición del
    `MessagePattern` y su propio test de regresión — **cero callers activos** hoy.
- **Flutter — domain/data/cubit YA implementados, UI NO**:
  - `lib/features/users/data/service/user_service.dart` ya tiene `@DELETE(ApiRoutes.me)
    Future<void> deleteMyAccount();`.
  - `lib/features/users/domain/repository/user_repository.dart` +
    `lib/features/users/data/repository/user_repository_impl.dart` ya tienen `deleteMyAccount()` →
    `Either<DomainException, Nothing>` vía `executeService`.
  - `lib/features/users/domain/use_cases/delete_account_use_case.dart` ya existe, patrón idéntico a
    `DeleteMaintenanceUseCase`.
  - `lib/features/profile/presentation/cubits/delete_account_cubit.dart` ya existe:
    `@injectable class DeleteAccountCubit extends Cubit<ResultState<Nothing>>` con guard de
    doble-tap (`if (state is Loading<Nothing>) return;`) antes de emitir `loading`.
  - `lib/shared/router/app_routes.dart` ya tiene `deleteAccount = '/profile/delete-account'`, pero
    **no hay `GoRoute` correspondiente** en `app_router.dart` — confirmado leyendo el archivo
    completo (solo existe la rama `edit` bajo `AppRoutes.profile`, líneas 336-351).
  - `lib/l10n/app_es.arb` ya tiene 13 claves `profile_deleteAccount_*` con copy en español, sin
    ningún call site en widgets (no hay widgets que las usen).
  - `lib/core/services/analytics/analytics_events.dart` ya tiene `accountDeletionStarted`,
    `accountDeletionConfirmed`, `accountDeletionFailed` (≤40 chars, sin PII), sin call sites.
  - `lib/features/profile/presentation/widgets/profile_actions_list.dart` **no tiene** el ítem
    "Eliminar cuenta" — confirmado leyendo el archivo completo (solo Inscripciones, Mantenimientos,
    opt-out de analítica, Cerrar sesión).
  - **No existe ningún archivo** `delete_account_confirmation_page.dart` ni sus 4 widgets hijos en
    todo el árbol (`find lib -iname "*delete_account*"` solo devuelve el use case y el cubit).
- `docs/features/profile.md` ya documenta el estado parcial en una sección §7.1 "EN PROGRESO" con
  el mismo diagnóstico (bloqueo de diseño Pencil) — consistente con lo verificado aquí.
- `docs/exec-runs/eliminacion-cuenta-phase-01/handoffs/design.md` documenta 3 intentos fallidos de
  abrir `rideglory.pen` vía Pencil MCP (`MCP error -32603: Failed to access file`), todos en la
  fecha de hoy. No hay ningún frame en Pencil para `DeleteAccountConfirmationPage` ni para el ítem
  destructivo en `ProfileActionsList` — confirmado en ese mismo handoff, no re-verificado aquí (el
  Architect no tiene acceso a Pencil MCP en este rol; el gate de diseño lo ejecuta el agente
  Design).

## Decisiones (confirmadas, sin cambios respecto al run anterior)

- **ADR-1 (orquestación en servicio nuevo):** el orquestador de 5 pasos vive en
  `AccountDeletionService`, no inline en `UsersController` — ya implementado así. Las fases 2/3
  solo tocan este archivo (líneas de los pasos 2 y 3).
- **ADR-2 (resolución de identidad por email):** el `id` interno de `users-ms` se resuelve vía
  `findUserByEmail(request.user.email)` — mismo patrón que `GET /users/me`. El `uid` de Firebase
  para el paso 5 sale directo de `request.user.uid`.
- **ADR-3 (5 pasos fijos, irreversibles al final):** ya implementado y probado con test de
  secuencia — ver arriba.
- **ADR-4 (sin nueva tabla/columna):** confirmado, ningún cambio de esquema Prisma en este run.
- **ADR-5 (Flutter — cubit de una sola pantalla):** `DeleteAccountCubit` ya es `@injectable`, sin
  registro en el `MultiBlocProvider` raíz — debe proveerse con `BlocProvider` local en
  `DeleteAccountConfirmationPage` cuando se cree.
- **ADR-6 (doble-tap guard):** ya implementado en el cubit, cubierto por
  `test/features/profile/presentation/cubit/delete_account_cubit_test.dart` (existente).
- **ADR-7 (ruta de entrada):** constante ya existe; falta el `GoRoute` hijo de `AppRoutes.profile`
  con `parentNavigatorKey: _rootNavigatorKey` (mismo patrón que `editProfile`).
- **ADR-8 (nuevo, este run — sin badges "próximamente"):** confirmado en `design.md`: los ítems de
  fases 2/3 en la lista de "qué se borra" se muestran igual que los que sí se borran hoy, sin
  distinción visual de fase. No reabre ninguna decisión previa, solo la deja explícita aquí para
  que Frontend no la reinvente.

## Change map

Solo se listan los archivos que **todavía requieren trabajo**. Los ya completos (ver §4) no
aparecen — Build no debe volver a tocarlos salvo que rompan tests.

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `Rideglory/lib/features/profile/presentation/delete_account_confirmation_page.dart` | create | Página nueva. `StatefulWidget`/`StatelessWidget` (a decidir por Frontend), provee `BlocProvider<DeleteAccountCubit>` local, mapea `ResultState<Nothing>` a `idle/loading/error/success`, orquesta navegación de éxito (limpieza `AuthCubit`/`VehicleCubit`/`ProfileCubit` + `goAndClearStack`). **Bloqueada hasta aprobación de diseño en Pencil.** | high |
| `Rideglory/lib/features/profile/presentation/widgets/delete_account_warning_list.dart` | create | Widget hijo: lista de qué se borra (incluye ítems de fases 2/3, sin badges "próximamente" — ADR-8). Un widget por archivo. | med |
| `Rideglory/lib/features/profile/presentation/widgets/delete_account_irreversible_switch.dart` | create | Widget hijo: envoltorio de `AppSwitchTile` para "entiendo que es irreversible". | low |
| `Rideglory/lib/features/profile/presentation/widgets/delete_account_confirm_button.dart` | create | Widget hijo: `AppButton` con estados `idle/loading`, deshabilitado si el switch está off o `state is Loading`. | low |
| `Rideglory/lib/features/profile/presentation/widgets/delete_account_error_banner.dart` | create | Widget hijo: mensaje de error + retry manual (un tap = una llamada). | low |
| `Rideglory/lib/features/profile/presentation/widgets/profile_actions_list.dart` | modify | Nuevo `ProfileMenuItem` "Eliminar cuenta" (estilo destructivo, mismo patrón visual que "Cerrar sesión") que navega con `context.pushNamed(AppRoutes.deleteAccount)` — **no** abre `ConfirmationDialog` (AC1). | med |
| `Rideglory/lib/shared/router/app_router.dart` | modify | Nueva `GoRoute` hija de `AppRoutes.profile`, `parentNavigatorKey: _rootNavigatorKey` (mismo patrón que `editProfile`, sin `extra` requerido). | low |
| `Rideglory/test/features/profile/presentation/delete_account_confirmation_page_test.dart` (o ruta equivalente) | create | Widget tests: AC1-AC6, AC10, AC11 — estados, guard de doble-tap visible en UI, cero strings hardcodeados. | med |
| `Rideglory/test/features/profile/presentation/widgets/profile_actions_list_test.dart` | create/modify | Verifica que el ítem "Eliminar cuenta" navega con `pushNamed`, no abre `ConfirmationDialog` (AC1). | low |
| `Rideglory/docs/features/profile.md` | modify | Reemplazar la sección §7.1 "EN PROGRESO" por la versión final una vez la UI exista: estructura de la pantalla, rutas de navegación, referencias cruzadas. | low |

**No tocar en este run** (ya completos y verificados, cualquier cambio no listado aquí es fuera de
alcance): todo `rideglory-api` (backend), `user_service.dart`, `user_repository.dart`,
`user_repository_impl.dart`, `delete_account_use_case.dart`, `delete_account_cubit.dart`,
`app_routes.dart`, `app_es.arb` (claves ya existen), `analytics_events.dart` (eventos ya
declarados, solo faltan call sites que se agregan al crear la página).

## Contratos (rideglory-api) — ya fijados, sin cambios

### `DELETE /users/me`

| | |
|---|---|
| Auth | Firebase ID token (Bearer), vía `FirebaseAuthGuard` |
| Request body | ninguno |
| uid/email | resueltos de `request.user`, nunca de params/body |
| Success | `204 No Content` |
| Errors | `401` (token inválido/ausente); `404` (usuario no encontrado en `users-ms`); `502`/`500` (fallo en cualquier paso de la orquestación) |

Orden de pasos (`account-deletion.service.ts`, ya implementado y probado):
1. `findUserByEmail(email)` → `id` interno (propaga 404 si no existe).
2. `// TODO fase 2` (no-op).
3. `// TODO fase 3` (no-op).
4. `hardDeleteUser({ id })` → `prisma.user.delete()`.
5. `firebaseAuthService.deleteUser(uid)` — siempre último, irreversible.

### `hardDeleteUser` (MessagePattern, `users-ms`) — ya implementado

Payload `{ id: string }` (UUID interno). Efecto: `prisma.user.delete()`. 404 vía `RpcException` si
`findOne(id)` no encuentra el usuario. Independiente de `removeUser` (soft-delete, sin tocar).

## Datos / migraciones

**Ninguna.** Confirmado de nuevo: `hardDeleteUser` usa `prisma.user.delete()` sobre el esquema
`User` existente, sin columnas nuevas. No se escribe `analysis/MIGRATION_PLAN.md`.

## Env

**Ninguna variable nueva.** Firebase Admin ya configurado (`FIREBASE_SERVICE_ACCOUNT_JSON` /
`FIREBASE_PROJECT_ID`), reutilizado por `deleteUser(uid)`. No se escribe `analysis/ENV_DELTA.md`.

## Riesgos

- **Gate de diseño sigue bloqueado.** `docs/exec-runs/eliminacion-cuenta-phase-01/handoffs/design.md`
  documenta 3 intentos fallidos hoy de abrir `rideglory.pen` vía Pencil MCP. Mientras no se
  desbloquee, Frontend no puede crear `delete_account_confirmation_page.dart` ni sus widgets, ni
  Build puede tocar `profile_actions_list.dart`/`app_router.dart` con el layout final — solo se
  puede avanzar wiring de router/tests si Design entrega spec aprobada primero.
- **Working tree con ~80 archivos no relacionados sin commitear** (confirmado en `git status`:
  borrado de `my_drafts_*`, cambios en tracking/login social, etc.). Riesgo de que un commit
  arrastre trabajo de otras fases — el humano debe commitear solo los archivos del change map de
  esta fase.
- **Puente `email` en vez de `uid`** para resolver el usuario interno — deuda conocida, documentada
  desde el run anterior, sin acción en esta fase.
- **Doble-tap**: ya mitigado en el cubit (ADR-6, probado), pero falta la parte de UI (deshabilitar
  visualmente el switch/botón durante `loading`) — a implementar junto con los widgets.

## Orden

1. **Design (bloqueante, sigue pendiente):** `DeleteAccountConfirmationPage` en Pencil sobre
   `rideglory.pen` — esperar que un humano abra el archivo en la app de escritorio de Pencil y
   relanzar el agente Design. Sin esto, no se avanza a los pasos 2-4.
2. **Frontend — presentation:** `delete_account_confirmation_page.dart` + 4 widgets hijos, una vez
   exista diseño aprobado.
3. **Frontend — router y menú:** `GoRoute` nueva en `app_router.dart`, ítem en
   `profile_actions_list.dart`.
4. **QA:** widget tests de la página nueva (estados, guard doble-tap visible, AC1, AC10, AC11) +
   verificación manual end-to-end con cuenta desechable (AC9, nunca `qa1@gmail.com`/`qa2@gmail.com`).
5. **Docs:** actualizar `docs/features/profile.md` §7.1 con la estructura final de la pantalla.

(Los pasos de backend del run anterior — `users-ms`, `firebase-auth.service`, `account-deletion.service`,
controller — ya están completos y no se repiten aquí.)

## Superficie de regresión

- `GET /users/me`, `PATCH /users/:id`, `POST /users/sign-up` — no tocados en este run (ya no hay
  cambios pendientes en `users.controller.ts` de `api-gateway`).
- `removeUser` (`users-ms`) — sin callers activos hoy (re-confirmado por grep); su test de
  regresión ya existe y pasa.
- `_logout` en `ProfileActionsList` — el bloque de limpieza de estado se replica (no se extrae a
  helper compartido) en la página nueva cuando se implemente.
- `analytics_taxonomy_no_pii_test.dart` — ya pasa con los 3 eventos declarados; no debe romperse al
  agregar los call sites en la página nueva.
- Router: la nueva `GoRoute` es hija de `AppRoutes.profile` con `parentNavigatorKey:
  _rootNavigatorKey` — no debe alterar el `redirect` global ni las rutas del shell
  (`StatefulShellRoute.indexedStack`).
- `EditProfilePage`/`AppRoutes.editProfile` — código huérfano ya documentado en `profile.md` (sin
  entry point desde la UI desde el commit `6607bee`); no forma parte de esta fase, no tocar.

## Fuera de alcance

- Borrado de vehículos/fotos/mantenimientos/documentos SOAT-RTM (fase 2 — paso 2 no-op, ya en
  código).
- Anonimización de `EventRegistration` y bloqueo por organizador con eventos activos (fase 3 —
  paso 3 no-op, ya en código).
- Reintentos automáticos, idempotencia ante cierre de app a mitad de operación, polling de estado
  (fase 4).
- Subir el timeout de Dio (fase 4).
- Agregar `firebaseUid` como columna de `User` en `users-ms` (deuda documentada, no acción).
- Reactivar `EditProfilePage`/botón "Editar info" (fuera de alcance, no relacionado).
- Cambiar el diseño de `ConfirmationDialog` (logout) — no se toca.

## Next agent needs to know

- **Design**: sigue siendo el único bloqueante real de esta fase. No hay ningún frame de
  `DeleteAccountConfirmationPage` en `rideglory.pen` todavía. Requiere acción humana (abrir el
  archivo en la app de escritorio de Pencil) antes de que el MCP funcione.
- **Frontend**: todo el domain/data/cubit ya existe y está probado — no reimplementar, solo
  construir sobre eso. `DeleteAccountCubit` es local (`BlocProvider` en la página nueva, no root).
- **QA**: backend ya cubierto (AC7, AC8 verificados con tests existentes). Falta cobertura completa
  de AC1-AC6, AC9-AC11 del lado Flutter, condicionada a que exista la UI.

## Change log

- 2026-07-10T16:28:52Z: Re-verificación completa del Architect. Releído todo el código real de
  `rideglory-api` y `Rideglory` relevante a esta fase (no se asumió el handoff anterior). Confirmado:
  backend 100% implementado y probado (5 pasos, orden fijo, `removeUser` intacto sin callers);
  Flutter domain/data/cubit 100% implementado y probado; UI (`DeleteAccountConfirmationPage`, 4
  widgets, ítem en `ProfileActionsList`, `GoRoute`) sigue sin existir, bloqueada por Pencil MCP
  (`rideglory.pen` no abierto en el editor de escritorio — 3 intentos fallidos documentados en
  `handoffs/design.md`, todos hoy). Change map reducido a solo los archivos pendientes. Sin
  migraciones ni env vars nuevas (confirmado de nuevo).
