# PRD normalizado — eliminacion-cuenta-phase-01

_Normalizado: 2026-07-10T15:19:05Z_
_Fuente: `docs/plans/eliminacion-cuenta/phases/phase-01-eliminacion-de-cuenta-nucleo-de-identidad.md` (fase 1 de un plan de 3+ fases)_

## 1 Objetivo

Como rider, puedo pedir la eliminación de mi cuenta desde el perfil y, tras confirmar en una
pantalla dedicada que entiendo que es irreversible, la app borra mi identidad (perfil,
credenciales Firebase Auth, token de notificaciones) y me regresa a la pantalla de login. Esta
fase fija el contrato definitivo `DELETE /users/me` y el orden de los 5 pasos de orquestación
backend que las fases 2 y 3 extenderán sin reordenar.

## 2 Por que

Es la primera fase de un plan de eliminación de cuenta multi-fase. Fija el contrato de API y el
orden de orquestación (con Firebase Auth `deleteUser` siempre como último paso irreversible) para
que las fases 2 (borrado de dominio: vehículos/documentos/mantenimientos) y 3 (anonimización de
registros de eventos, bloqueo por organizador) puedan extender el mismo endpoint sin reordenar ni
invalidar trabajo ya probado. Alto blast radius (dato irreversible, PII central) — requiere fijar
bien el núcleo desde el día uno.

## 3 Alcance

**Entra:**
- Ítem "Eliminar cuenta" en `ProfileActionsList`, estilo destructivo (mismo patrón visual que
  "Cerrar sesión").
- Pantalla dedicada `DeleteAccountConfirmationPage` (diseñada en Pencil sobre `rideglory.pen`) con
  lista completa de qué se borra (incluyendo ítems de fases 2 y 3 desde el día uno), `AppSwitchTile`
  de "entiendo que es irreversible" que habilita el botón de confirmación, y estados
  `idle`/`confirming`/`loading`/`error`/`success`.
- Endpoint nuevo `DELETE /users/me` en `api-gateway` (`UsersController`).
- Nuevo `MessagePattern` `hardDeleteUser` en `users-ms` (no se muta `removeUser`).
- Método `deleteUser(uid)` en `FirebaseAuthService` (Admin SDK, `api-gateway`).
- Orquestación síncrona de 5 pasos en el `api-gateway`, con los pasos 2 y 3 como no-ops explícitos
  (`// TODO fase 2` / `// TODO fase 3`) hasta que esas fases los implementen.
- Grep y verificación de todos los llamadores existentes de `removeUser` antes de decidir su
  destino.
- Limpieza de estado local Flutter tras éxito (mismo bloque que `_logout`).
- Manejo de error simple (retry manual desde el mismo botón, sin loop automático).

**No entra:**
- Borrado de vehículos, fotos, mantenimientos, documentos SOAT/RTM (fase 2).
- Anonimización de `EventRegistration` y bloqueo por organizador con eventos activos (fase 3).
- Reintentos automáticos, idempotencia ante cierre de app a mitad de operación, polling de estado
  (fase 4).
- Subir el timeout de Dio (se evalúa en fase 4).

## 4 Areas afectadas (best-effort)

**rideglory-api** (`api-gateway`, `users-ms`):
- `api-gateway/src/users/users.controller.ts` — `DELETE /users/me`, orquestación de 5 pasos.
- `api-gateway/src/users/users.service.ts` (o equivalente) — orquestador si no vive en el
  controller.
- `api-gateway/src/auth/firebase-auth.service.ts` — `deleteUser(uid)`.
- `users-ms/src/users/users.controller.ts` — `@MessagePattern('hardDeleteUser')`.
- `users-ms/src/users/users.service.ts` — `hardDelete(id)` (Prisma `delete()`).
- Tests `.spec.ts` junto a cada archivo modificado.

**Flutter (`Rideglory`)**:
- `lib/features/users/data/service/user_service.dart` — `@DELETE(ApiRoutes.me) deleteMyAccount()`.
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` — nuevo.
- `lib/features/users/domain/repository/user_repository.dart` (o el repo real que exista) —
  `deleteMyAccount()`.
- `lib/features/users/data/repository/*_repository_impl.dart` — implementación vía `UserService` +
  `executeService`.
- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` (o ruta equivalente en
  `users`) — `Cubit<ResultState<Nothing>>`.
- `lib/features/profile/presentation/delete_account_confirmation_page.dart` — nueva página.
- `lib/features/profile/presentation/widgets/delete_account_*` — widgets hijos (uno por archivo).
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — nuevo `ProfileMenuItem`.
- `lib/shared/router/app_routes.dart` y `app_router.dart` — ruta `deleteAccount`.
- `lib/l10n/app_es.arb` — nuevas claves de copy.
- `lib/core/services/analytics/analytics_events.dart` — eventos nuevos si aplica.
- `docs/features/profile.md` — documentar el flujo nuevo.

## 5 Criterios de aceptacion

1. Desde `ProfileActionsList`, el ítem "Eliminar cuenta" navega a `DeleteAccountConfirmationPage`
   (no abre un `ConfirmationDialog` directo).
2. `DeleteAccountConfirmationPage` muestra la lista completa de qué se borra, incluyendo ítems que
   aún no están implementados (vehículos/documentos de fase 2, historial de eventos de fase 3).
3. El botón de confirmación final está deshabilitado hasta que el `AppSwitchTile` de "entiendo que
   es irreversible" está activado.
4. Al confirmar, la UI entra en estado `loading`: muestra spinner, deshabilita el botón, y un
   segundo tap durante `loading` no dispara una segunda llamada HTTP (verificable con mock/spy en
   test).
5. En éxito (`204`), la app limpia `AuthCubit`, `VehicleCubit`, `ProfileCubit` y navega a
   `AppRoutes.login` vía `context.goAndClearStack`, sin dejar la pantalla de eliminación en el
   stack de navegación.
6. En error (`502`/`401`/excepción de red), la UI vuelve a estado `error` con mensaje user-facing
   en español y opción de reintentar manualmente (nuevo tap), sin loop automático de reintentos.
7. `DELETE /users/me` en `api-gateway` ejecuta los 5 pasos en el orden fijo documentado, con
   Firebase Auth `deleteUser` siempre como último paso — verificable con test unitario de secuencia
   de llamadas mockeadas.
8. `hardDeleteUser` en `users-ms` borra la fila del usuario (`prisma.user.delete`); `removeUser`
   (soft-delete existente) permanece sin modificar y sigue funcionando para sus llamadores actuales
   verificados en el paso de grep.
9. Tras un `hardDeleteUser` + `deleteUser` de Firebase Auth exitosos, un intento posterior de login
   con las mismas credenciales falla (usuario ya no existe en Firebase Auth ni en `users-ms`).
10. Todas las cadenas de texto visibles en `DeleteAccountConfirmationPage` están en `app_es.arb` y
    se acceden vía `context.l10n.<key>`; cero strings hardcodeados.
11. `dart analyze` no reporta violaciones nuevas; cada widget nuevo vive en su propio archivo sin
    métodos `_buildX()` que retornen `Widget`.

## 6 Guardrails de regresion

- `removeUser` (soft-delete existente en `users-ms`) NO se modifica ni se elimina; sus llamadores
  actuales (confirmados vía grep obligatorio) deben seguir pasando sin cambios — cubrir con test de
  regresión explícito.
- `hardDeleteUser` es un `MessagePattern` nuevo y separado; nunca reemplaza `removeUser`.
- El orden de los 5 pasos de orquestación es fijo desde esta fase: Firebase Auth `deleteUser` debe
  ser siempre el último paso (paso 5), nunca antes — un fallo en el paso 4 no debe invocar el paso
  5; verificar con test unitario de secuencia, no solo revisión de código.
- Los pasos 2 y 3 (dominio, anonimización) quedan como no-ops explícitos y comentados
  (`// TODO fase 2` / `// TODO fase 3`) — no lógica placeholder que falle ni que bloquee el flujo.
- El `uid` para `DELETE /users/me` se resuelve siempre del token vía interceptor Firebase existente,
  nunca de un parámetro de la petición.
- No ejecutar ninguna prueba del flujo de hard-delete contra los ~10 usuarios reales en producción
  ni contra `qa1@gmail.com`/`qa2@gmail.com` (usuarios QA reutilizables del proyecto); usar solo
  cuentas de prueba desechables.
- Prevención de doble-tap durante `loading`: un segundo tap no debe disparar una segunda llamada
  HTTP concurrente — guard explícito en cubit/UI, cubierto con test dedicado.
- `dart analyze` sin violaciones nuevas; un widget por archivo, sin métodos `_buildX()` que retornen
  `Widget` (regla de arquitectura del proyecto, tolerancia cero).
- Todo el copy visible va en `app_es.arb` vía `context.l10n.<key>`; cero strings hardcodeados.

## 7 Constraints heredados

- Diseño de la pantalla nueva es **bloqueante**: debe diseñarse en Pencil sobre `rideglory.pen`
  (nunca un mockup HTML alternativo); si el MCP de Pencil está caído, se detiene la fase y se
  avisa — no se inventan specs alternativas; se espera aprobación explícita del diseño antes de
  implementar.
- Arquitectura Clean (domain/data/presentation) y patrones existentes del repo: DTO Pattern B donde
  aplique, `ResultState<T>` para operaciones async simples (`DeleteAccountCubit extends
  Cubit<ResultState<Nothing>>`), Cubits `@injectable` con `BlocProvider` local (no singleton en el
  árbol raíz, ya que este es un flujo de una sola pantalla), navegación con
  `context.pushNamed`/`context.goAndClearStack` según convención.
- `AppSwitchTile` es el único patrón de switch permitido (nunca Material/FormBuilderSwitch).
- Localización: todo texto nuevo en `app_es.arb`, regenerar con `flutter gen-l10n`/`build_runner`.
- Analítica: eventos nuevos sin PII, validados contra `analytics_taxonomy_no_pii_test.dart`.
- `hardDelete` es un borrado físico real (`prisma.user.delete`) — es la promesa ya publicada en
  `docs/web/delete-account.html`; no se agregan columnas ni migraciones de esquema en esta fase.
- Nivel de ejecución recomendado por la fuente: **full** (alto blast radius, PII central, orden de
  paso irreversible difícil de revertir si queda mal fijado).
- Sin dependencias previas (fase 1 de 3+); las fases 2 y 3 dependen de que el orden de 5 pasos y el
  contrato `DELETE /users/me` fijados aquí no se reordenen.
