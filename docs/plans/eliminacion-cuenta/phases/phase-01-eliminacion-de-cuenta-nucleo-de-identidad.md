# Fase 1 — Eliminación de cuenta — núcleo de identidad

_Generado: 2026-07-07T16:00:00Z_

## Objetivo

Como rider, puedo pedir la eliminación de mi cuenta desde el perfil y, tras confirmar en una
pantalla dedicada que entiendo que es irreversible, la app borra mi identidad (perfil, credenciales
Firebase Auth, token de notificaciones) y me regresa a la pantalla de login. Esta fase fija el
contrato definitivo `DELETE /users/me` y el orden de los 5 pasos de orquestación backend que las
fases 2 y 3 extenderán sin reordenar.

## Alcance (entra / no entra)

**Entra:**
- Ítem "Eliminar cuenta" en `ProfileActionsList`, estilo destructivo (mismo patrón visual que
  "Cerrar sesión").
- Pantalla dedicada `DeleteAccountConfirmationPage` (diseñada en Pencil sobre `rideglory.pen`) con:
  - Lista completa de qué se borra, incluyendo ítems de fases 2 (vehículos, fotos, mantenimientos,
    documentos SOAT/RTM) y 3 (historial de eventos anonimizado) desde el día uno.
  - `AppSwitchTile` de "Entiendo que esta acción es irreversible" que habilita el botón de
    confirmación final (deshabilitado por defecto).
  - Estados `idle` / `confirming` / `loading` (spinner, botón deshabilitado, sin doble-tap) /
    `error` / `success`.
- Endpoint nuevo `DELETE /users/me` en `api-gateway` (`UsersController`).
- Nuevo `MessagePattern` `hardDeleteUser` en `users-ms` (no se muta `removeUser`).
- Método `deleteUser(uid)` en `FirebaseAuthService` (Admin SDK, `api-gateway`).
- Orquestación síncrona de 5 pasos en el `api-gateway` (ver sección siguiente), con los pasos 2 y 3
  como **no-ops explícitos** hasta que las fases 2 y 3 los implementen (llamadas comentadas/TODO
  con referencia a la fase, no lógica placeholder que falle).
- Grep y verificación de todos los llamadores existentes de `removeUser` en `api-gateway` antes de
  decidir si se conserva sin cambios o se deja en desuso.
- Limpieza de estado local Flutter tras éxito (mismo bloque que `_logout`).
- Manejo de error simple (retry manual desde el mismo botón, sin loop automático) como criterio
  base de esta fase — no delegado a fase 4.

**No entra:**
- Borrado de vehículos, fotos, mantenimientos, documentos SOAT/RTM (fase 2).
- Anonimización de `EventRegistration` y bloqueo por organizador con eventos activos (fase 3).
- Reintentos automáticos, idempotencia ante cierre de app a mitad de operación, polling de estado
  (fase 4).
- Subir el timeout de Dio (se evalúa en fase 4 si hace falta tras medir con las 5 fases completas).

## Que se debe hacer (pasos concretos y ordenados)

1. **Diseño Pencil (bloqueante):** diseñar `DeleteAccountConfirmationPage` en `rideglory.pen`
   (nunca HTML mockup). Si el MCP de Pencil está caído, detener la fase y avisar — no inventar
   specs alternativas. Esperar aprobación explícita del diseño antes de implementar.
2. **Backend — auditoría de `removeUser`:** `grep -rn "removeUser"` en `api-gateway` y `users-ms`;
   documentar en el PR/handoff todos los llamadores encontrados y confirmar que ninguno se rompe al
   dejar `removeUser` intacto y agregar `hardDeleteUser` como patrón nuevo y separado.
3. **Backend — `FirebaseAuthService.deleteUser(uid)`:** agregar el método usando
   `getAuth(this.firebaseApp).deleteUser(uid)` junto al `verifyToken` ya existente.
4. **Backend — `users-ms`:** agregar `@MessagePattern('hardDeleteUser')` en `UsersController`
   (microservicio) → `UsersService.hardDelete(id)` que hace `prisma.user.delete({ where: { id } })`
   (hard-delete real; es la promesa ya publicada en `docs/web/delete-account.html` — con ~10
   usuarios reales en producción hoy, ninguna prueba de este flujo debe ejecutarse contra ellos,
   solo contra cuentas QA desechables). Verificar que
   no rompe relaciones FK pendientes de otros modelos en `users-ms` (si las hay, documentarlas como
   riesgo, no bloquear la fase si no existen).
5. **Backend — `api-gateway.UsersController`:** agregar `DELETE /users/me`, `uid` resuelto del
   token del interceptor Firebase existente (nunca de parámetro). Orquesta en este orden fijo:
   1. Precondición organizador con eventos activos → **TODO fase 3**, hoy no-op (no bloquea nada).
   2. Dominio (vehículos+docs+mantenimientos) → **TODO fase 2**, hoy no-op.
   3. Anonimización de registros de eventos → **TODO fase 3**, hoy no-op.
   4. `usersService.send('hardDeleteUser', { id: uid })`.
   5. `firebaseAuthService.deleteUser(uid)` — último paso, irreversible.
   Responde `204 No Content` en éxito; `502 Bad Gateway` si algún paso downstream falla (mensaje
   genérico, `retryable: true`); `401` vía interceptor estándar si el token es inválido.
6. **Backend — tests:** unit test del controller/orquestador que verifique el orden exacto de
   llamadas (mock de cada dependencia, assert de secuencia) y que Firebase Auth se llama al final
   incluso si se agregan más pasos luego.
7. **Flutter — contrato de consumo:** agregar `@DELETE(ApiRoutes.me)` a `UserService` (Retrofit,
   `lib/features/users/data/service/user_service.dart`), regenerar con `build_runner`.
8. **Flutter — dominio:** nuevo `DeleteAccountUseCase` en
   `lib/features/users/domain/use_cases/delete_account_use_case.dart` que invoca un método nuevo
   del repositorio de usuarios (extender `UserRepository`/`UserRepositoryImpl` si existen con ese
   alcance, o confirmar en código el repo correcto antes de escribir — el scan no encontró un
   repositorio de eliminación existente).
9. **Flutter — cubit:** nuevo `DeleteAccountCubit extends Cubit<ResultState<Nothing>>` (operación
   simple, sin estado compuesto) en `lib/features/profile/presentation/cubits/` o
   `lib/features/users/presentation/cubit/` (decidir según dónde vive `DeleteAccountUseCase`);
   `@injectable`, con `BlocProvider` local en `DeleteAccountConfirmationPage` (no singleton en el
   árbol raíz — este flujo es de una sola pantalla).
10. **Flutter — UI:** implementar `DeleteAccountConfirmationPage` (un widget por archivo, sin
    métodos que retornen widgets — cada bloque de la lista "qué se borra", el `AppSwitchTile`, y el
    botón final son sus propias clases/archivos) siguiendo el diseño aprobado en Pencil. Estados
    `idle`/`confirming` se resuelven con `ConfirmationDialog` (patrón de `_logout`) antes de invocar
    el cubit; `loading` deshabilita el botón y muestra spinner (prevención de doble-tap: guardar
    bandera local o verificar `state is Loading` antes de permitir el tap); `error` muestra mensaje
    con opción de reintentar manualmente; `success` ejecuta el bloque de limpieza y navega.
11. **Flutter — ítem en perfil:** agregar `ProfileMenuItem` "Eliminar cuenta" en
    `profile_actions_list.dart` bajo el ítem de logout (mismo estilo `iconColor`/`labelColor` de
    error), que hace `context.pushNamed(AppRoutes.deleteAccount)` (nueva ruta) en vez de abrir un
    diálogo directo — la confirmación vive en la pantalla dedicada, no en un `ConfirmationDialog`
    lanzado desde la lista.
12. **Flutter — ruta:** agregar `AppRoutes.deleteAccount` y su `GoRoute` en `app_router.dart`.
13. **Flutter — limpieza post-éxito:** en el manejador de `success` del cubit, ejecutar
    `context.read<AuthCubit>().signOut()` (defensivo, aunque el backend ya invalidó el usuario),
    `context.read<VehicleCubit>().clearVehicles()`, `context.read<ProfileCubit>().reset()`, y
    `context.goAndClearStack(AppRoutes.login)` — mismo bloque que `_logout`.
14. **Flutter — manejo de 409/502 mapeado:** aunque el bloqueo de organizador (409) es
    funcionalmente fase 3, el mapeo de errores HTTP genéricos (`DomainException`) para 502/401 debe
    quedar listo en esta fase para que fase 3 solo añada el caso específico 409, no rediseñe el
    manejo de errores del cubit.
15. **Localización:** agregar todas las claves nuevas a `app_es.arb` (prefijo `profile_deleteAccount`
    o `account_delete`, a decidir consistentemente durante la implementación) y correr
    `flutter gen-l10n` / `build_runner`.
16. **Analítica:** agregar evento(s) nuevos a `analytics_events.dart` si el patrón del feature lo
    exige (p. ej. `account_deletion_started`, `account_deletion_succeeded`,
    `account_deletion_failed`) sin PII, siguiendo `analytics_taxonomy_no_pii_test.dart`.
17. **Documentación:** actualizar `docs/features/profile.md` (o `authentication.md`, según dónde
    quede documentado el flujo) con el nuevo flujo de eliminación de cuenta.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

**rideglory-api (submódulos relevantes: `api-gateway`, `users-ms`):**
- `api-gateway/src/users/users.controller.ts` — agrega `DELETE /users/me` con orquestación de 5
  pasos (pasos 2-3 no-op con `// TODO fase 2/3`).
- `api-gateway/src/users/users.service.ts` (o equivalente) — método orquestador si no vive
  directo en el controller.
- `api-gateway/src/auth/firebase-auth.service.ts` — agrega `deleteUser(uid: string): Promise<void>`.
- `users-ms/src/users/users.controller.ts` — agrega `@MessagePattern('hardDeleteUser')`.
- `users-ms/src/users/users.service.ts` — agrega `hardDelete(id: string)` (Prisma `delete()` real).
- Tests unitarios nuevos junto a cada archivo modificado (`.spec.ts`, convención del repo).

**Flutter (`Rideglory`):**
- `lib/features/users/data/service/user_service.dart` — agrega `@DELETE(ApiRoutes.me) Future<void> deleteMyAccount();`.
- `lib/features/users/domain/use_cases/delete_account_use_case.dart` — nuevo, orquesta la llamada al repo.
- `lib/features/users/domain/repository/user_repository.dart` (o el repo que exista en ese path) — agrega `deleteMyAccount()`.
- `lib/features/users/data/repository/*_repository_impl.dart` — implementa `deleteMyAccount()` vía `UserService` + `executeService`.
- `lib/features/profile/presentation/cubits/delete_account_cubit.dart` (o ruta equivalente en `users`) — nuevo `Cubit<ResultState<Nothing>>`.
- `lib/features/profile/presentation/delete_account_confirmation_page.dart` — nueva página (un widget por archivo).
- `lib/features/profile/presentation/widgets/delete_account_*` — widgets hijos de la página (lista de qué se borra, switch de entendimiento, botón, cada uno su propio archivo).
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — agrega el `ProfileMenuItem` "Eliminar cuenta".
- `lib/shared/router/app_routes.dart` — agrega `deleteAccount`.
- `lib/shared/router/app_router.dart` — agrega el `GoRoute` correspondiente.
- `lib/l10n/app_es.arb` — nuevas claves de copy.
- `lib/core/services/analytics/analytics_events.dart` — nuevos eventos si aplica.
- `docs/features/profile.md` — documenta el flujo nuevo.

## Contratos / API rideglory-api

### `DELETE /users/me` (api-gateway, `UsersController`)
- **Auth:** Firebase ID token vía interceptor existente; `uid` resuelto del token, nunca de parámetro.
- **Orquestación interna (síncrona, orden fijo desde esta fase):**
  1. Precondición organizador con eventos activos — no-op en esta fase (fase 3 lo implementa).
  2. Borrado de dominio (vehículos+docs+mantenimientos) — no-op en esta fase (fase 2 lo implementa).
  3. Anonimización de registros de eventos — no-op en esta fase (fase 3 lo implementa).
  4. `usersService.send('hardDeleteUser', { id: uid })`.
  5. `firebaseAuthService.deleteUser(uid)` — último paso, irreversible.
- **Éxito:** `204 No Content`.
- **Errores:** `502 Bad Gateway` (fallo downstream, `retryable: true`), `401` (token inválido, vía
  interceptor estándar). El `409 ACTIVE_EVENTS_AS_ORGANIZER` se agrega en fase 3, no en esta.

### `MessagePattern` nuevo
| MS | Pattern | Payload | Nota |
|----|---------|---------|------|
| `users-ms` | `hardDeleteUser` | `{ id }` | Nuevo; NO reemplaza `removeUser` (se conserva intacto tras verificar sus llamadores). |

### Firebase Auth
- `FirebaseAuthService.deleteUser(uid: string): Promise<void>` — nuevo, usa `getAuth(this.firebaseApp).deleteUser(uid)`.

## Cambios de datos / migraciones

Ninguno. `hardDelete` usa `prisma.user.delete()` sobre el schema existente de `users-ms`; no se
agregan columnas ni tablas en esta fase.

## Criterios de aceptacion

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
   Firebase Auth `deleteUser` siempre como último paso — verificable con test unitario de
   secuencia de llamadas mockeadas.
8. `hardDeleteUser` en `users-ms` borra la fila del usuario (`prisma.user.delete`); `removeUser`
   (soft-delete existente) permanece sin modificar y sigue funcionando para sus llamadores
   actuales verificados en el paso de grep.
9. Tras un `hardDeleteUser` + `deleteUser` de Firebase Auth exitosos, un intento posterior de login
   con las mismas credenciales falla (usuario ya no existe en Firebase Auth ni en `users-ms`).
10. Todas las cadenas de texto visibles en `DeleteAccountConfirmationPage` están en `app_es.arb`
    y se acceden vía `context.l10n.<key>`; cero strings hardcodeados.
11. `dart analyze` no reporta violaciones nuevas; cada widget nuevo vive en su propio archivo sin
    métodos `_buildX()` que retornen `Widget`.

## Pruebas (unitarias/widget/integracion)

**Backend (rideglory-api):**
- Unit test de `UsersController.deleteMe` (api-gateway): verifica orden exacto de llamadas a los 5
  pasos (mocks), que Firebase Auth se invoca al final, y que un fallo en el paso 4 no invoca el
  paso 5.
- Unit test de `UsersService.hardDelete` (users-ms): verifica `prisma.user.delete` con el `id`
  correcto.
- Unit test de `FirebaseAuthService.deleteUser`: verifica invocación de `getAuth().deleteUser(uid)`.
- Test de regresión: los llamadores existentes de `removeUser` (encontrados en el grep del paso 2)
  siguen pasando sin cambios.

**Flutter:**
- Unit test de `DeleteAccountUseCase` (éxito y error mapeado a `DomainException`).
- Unit test de `DeleteAccountCubit`: transición `initial → loading → data/error`; verificar que un
  segundo `call()` durante `loading` no dispara una segunda invocación del use case (mock con
  `verify(...).called(1)`).
- Widget test de `DeleteAccountConfirmationPage`: botón deshabilitado sin el switch activo, se
  habilita al activarlo, tap dispara `loading` (spinner visible, botón deshabilitado), tap repetido
  no duplica la llamada, error muestra mensaje y permite reintentar, éxito navega y limpia stack
  (verificar con `GoRouter` de test o mock de navegación).
- Widget test de `ProfileActionsList`: el ítem "Eliminar cuenta" navega a la ruta nueva (no abre
  diálogo directo).
- Test de `analytics_taxonomy_no_pii_test.dart`: los eventos nuevos no contienen PII.
- Test Patrol e2e (si aplica en esta fase, o diferido a `qa-auto`): flujo completo desde perfil
  hasta login tras eliminación exitosa, usando un usuario de prueba desechable (no `qa1`/`qa2`
  reales, para no destruir los usuarios de prueba QA del proyecto).

## Riesgos y mitigaciones

1. **`removeUser` con llamadores no auditados** — mitigado por el grep obligatorio del paso 2
   antes de decidir el patrón final; si aparece un llamador con expectativas distintas, se
   confirma `hardDeleteUser` como patrón separado (ya es la decisión por defecto de esta fase).
2. **Orden de orquestación incorrecto deja usuario sin sesión pero con datos vivos** — mitigado
   fijando Firebase Auth `deleteUser` como el paso 5 (último), nunca antes; test unitario de
   secuencia lo verifica de forma automatizada, no solo por revisión de código.
3. **Pasos no-op de fases 2/3 olvidados o mal marcados** — mitigado dejando `// TODO fase 2` /
   `// TODO fase 3` explícitos y comentados en el orquestador, con referencia al número de fase,
   para que el auditor de esas fases los encuentre por grep.
4. **Copy de "qué se borra" desactualizado si fases 2/3 cambian de alcance** — mitigado
   documentando en el handoff de esta fase que el copy de la pantalla depende de la síntesis del
   plan completo (`05-sintesis.md`) y debe revisarse si cambia el alcance de fases 2/3.
5. **Doble-tap durante `loading` dispara dos llamadas HTTP concurrentes** — mitigado exigiendo el
   guard explícito en el cubit/UI y cubriéndolo con test unitario dedicado (criterio de aceptación
   4).
6. **Diseño Pencil bloqueado o MCP caído** — mitigado deteniendo la fase por completo y avisando;
   no se implementa con mockup HTML alternativo bajo ninguna circunstancia.

## Dependencias (fases prerequisito y por que)

Ninguna — esta es la fase 1, primera del plan. Las fases 2 y 3 dependen de esta fase porque
extienden el mismo endpoint `DELETE /users/me` y el mismo orden de 5 pasos fijado aquí, sin poder
reordenar sin invalidar el trabajo ya probado.

## Ejecucion recomendada

**Nivel rg-exec: full** — Introduce el contrato nuevo `DELETE /users/me` en `rideglory-api` y
decide si se reemplaza un `MessagePattern` existente (`removeUser`); fija desde el día uno el
orden del único paso irreversible del sistema (Firebase Auth `deleteUser`). Alto blast radius, PII
central, difícil de revertir si el orden queda mal — no califica para lite ni normal aunque la
superficie de UI visible sea pequeña.
