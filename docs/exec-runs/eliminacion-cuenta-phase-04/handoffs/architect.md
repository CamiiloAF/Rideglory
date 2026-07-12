# Architect handoff — eliminacion-cuenta-phase-04

**Date:** 2026-07-11T17:23:32Z
**Status:** done

## 0. Corrección de §4 del PRD contra el código real

El PRD normalizado enumera archivos "best-effort" que **no coinciden exactamente** con el código
real. Correcciones verificadas leyendo el código (no asumidas):

| PRD decía | Realidad verificada | Impacto |
|---|---|---|
| `lib/features/profile/data/repository/account_repository_impl.dart` | **No existe.** El repositorio real es `lib/features/users/data/repository/user_repository_impl.dart` (`deleteMyAccount()`, línea 42), invocado por `DeleteAccountUseCase` (`lib/features/users/domain/use_cases/delete_account_use_case.dart`) y `DeleteAccountCubit` (`lib/features/profile/presentation/cubits/delete_account_cubit.dart`). | El comentario de timeout (criterio 6) va en el archivo real. |
| `api-gateway/src/users/users.controller.ts` (o "service orquestador") | El orquestador real es **`api-gateway/src/users/account-deletion.service.ts`** (`AccountDeletionService.deleteAccount`), inyectado en `UsersController.deleteMe`. El controller no tiene lógica propia. | El fix de idempotencia del **paso 1** (ver §1 abajo) vive en `account-deletion.service.ts`, no mencionado en el PRD original — es el hallazgo más importante de esta fase. |
| Wiring de `AbortController`/`req.on('close')` "verificar y remover si existe" | **Confirmado ausente.** `grep` en `api-gateway/src` no encuentra ninguna referencia. Express/Nest no aborta el handler por defecto cuando el socket del cliente se cierra — el código ya continúa ejecutándose tras un `firstValueFrom` en curso. Ningún cambio necesario; solo test de regresión que lo confirme. | Reduce alcance: 0 archivos que tocar aquí. |
| 5 pasos "1-3" de orquestación | La orquestación real tiene **8 pasos** documentados en el JSDoc de `deleteAccount()` (resolver usuario → precondición organizador → hardDeleteAllByOwner → storage cleanup best-effort → softDeleteMaintenancesByUserId → anonymizeRegistrationsByUserId → hardDeleteUser → firebaseAuthService.deleteUser). El PRD linkeaba a los "pasos 1-3" de fases previas de forma genérica; el detalle real ya está en el código y no se reordena. | Ninguno — solo aclara para Backend. |

## 1. Hallazgo crítico: `findUserByEmail` es el eslabón no-idempotente que el PRD no vio

`AccountDeletionService.deleteAccount(uid, email)` resuelve `user.id` en su **primera línea**
llamando a `usersService.send('findUserByEmail', { email })`. `UsersService.findByEmail` (en
`users-ms/src/users/users.service.ts`) hace `findFirst({ where: { email, isDeleted: false } })` y
lanza `RpcException({ status: 404, ... })` si no hay match.

Si una ejecución previa ya completó los 8 pasos (incluido `hardDeleteUser`, que **borra la fila**),
un reintento posterior — el cliente reabre la app, no recibió el `204` por corte de red, y repite
`DELETE /users/me` — falla en el **paso 1**, antes de siquiera llegar a la protección P2025 que el
PRD pedía en `hardDeleteUser`. `RpcCustomExceptionFilter` traduce ese `RpcException` a un **HTTP
404** con el mensaje interno de Prisma/Nest — un código de respuesta **no documentado** en el
contrato de `DELETE /users/me` (`204/409/401/502`), violando el guardrail "no cambiar el contrato
de error existente" y el criterio de aceptación 4 ("nunca... un estado parcial distinto a una
ejecución exitosa").

**Decisión (ADR-1):** `AccountDeletionService.deleteAccount` debe distinguir "usuario no
encontrado porque ya fue borrado por completo" de cualquier otro fallo real:

```ts
let user: { id: string };
try {
  user = await firstValueFrom(
    this.usersService.send<{ id: string }>('findUserByEmail', { email }),
  );
} catch (error) {
  if (isNotFoundRpcError(error)) {
    // Idempotencia: una corrida previa ya completó los 8 pasos (incluido
    // hardDeleteUser + Firebase Auth). No hay nada más que hacer — éxito.
    return;
  }
  throw error; // fallo real (timeout, DB caída, etc.) — no se enmascara.
}
```

`isNotFoundRpcError(error)` es un helper nuevo y pequeño (compartido con el paso 7, ver §2) que
reconoce la forma `{ status: 404, ... }` que produce `RpcException` al cruzar el transporte de
microservicios de Nest. Backend debe verificar la forma exacta del error serializado en el límite
`ClientProxy` (puede diferir de un `RpcException` local — usualmente llega como el objeto plano
pasado al constructor). Cubrir con test explícito de la forma real, no solo asumida.

**Por qué `return` y no propagar un 204 "falso":** el controller ya responde `204` por defecto
(`@HttpCode(HttpStatus.NO_CONTENT)` + retorno `void`), así que un `return` temprano en el service
basta — no se toca el controller.

## 2. Idempotencia paso por paso (contra el código real, no el PRD genérico)

| Paso | Servicio | Estado real hoy | Acción |
|---|---|---|---|
| 1. `findUserByEmail` | users-ms | **No idempotente** (404 si ya borrado) — hallazgo nuevo, ver §1 | Backend: catch específico en `account-deletion.service.ts` |
| 2. `ensureNoActiveEventsAsOrganizer` (`findEventsByOwnerId`) | events-ms | Ya idempotente — solo lee, no muta | Ninguna |
| 3. `hardDeleteAllByOwner` | vehicles-ms | **Ya idempotente** — `findMany` + early-return `{ deletedVehicleCount: 0, imageUrls: [] }` si no hay vehículos (línea 284) | Ninguna — solo test de regresión |
| 4. Storage cleanup | api-gateway (`StorageCleanupService`) | Ya best-effort, no aborta el flujo (`try/catch` con `logger.warn`) | Ninguna |
| 5. `softDeleteMaintenancesByUserId` | maintenances-ms | **Ya idempotente** — `updateMany({ where: { userId, isDeleted: false }, data: {...} })`; segunda llamada actualiza 0 filas sin error | Ninguna — solo test de regresión |
| 6. `anonymizeRegistrationsByUserId` | events-ms | **Ya idempotente** — `updateMany({ where: { userId }, ... })`; reescribir los mismos valores anonimizados no falla | Ninguna — solo test de regresión |
| 7. `hardDeleteUser` | users-ms | **No idempotente HOY, y el fix del PRD original es incompleto.** `hardDelete(id)` llama primero a `this.findOne(id)`, que lanza 404 **antes** de llegar al `this.user.delete()` — nunca se alcanza el código P2025 de Prisma que el PRD pedía envolver. | Backend: quitar el precondition `findOne` de `hardDelete`, intentar `delete` directo envuelto en `try/catch` de `Prisma.PrismaClientKnownRequestError` código `P2025` → no-op idempotente (log + return sin lanzar). **Reescribir** el test existente `users.service.spec.ts` ("throws RpcException 404... without calling delete") que hoy afirma lo contrario. |
| 8. `firebaseAuthService.deleteUser` | api-gateway (Admin SDK) | **No idempotente** — cualquier error se relanza tal cual (`catch { throw error }`) | Backend: catch específico de `error.code === 'auth/user-not-found'` (Admin SDK expone `.code`, no solo `.message`) → no-op idempotente. Verificar la forma real del error del Admin SDK (no asumir `new Error('auth/user-not-found')` como el spec actual simula) |

**Regla dura para 3, 5 y 6:** son idempotentes por diseño (`updateMany`/`findMany`-condicional) —
**no tocar su código**, solo agregar tests que lo demuestren (doble llamada, mismo resultado, sin
error). Tocar código que ya es correcto es riesgo sin beneficio.

## 3. Concurrencia (AC5 — carrera de dos llamadas superpuestas)

Con los fixes de §1 y §2, dos llamadas concurrentes al mismo `uid`:
- Ambas resuelven `user.id` en el paso 1 (ninguna ha completado aún el paso 7).
- Pasos 2-6: idempotentes por diseño, ninguna falla.
- Paso 7 (`hardDeleteUser`): una gana la carrera de Postgres, la otra recibe `P2025` → no-op.
- Paso 8 (Firebase Auth `deleteUser`): una gana, la otra recibe `auth/user-not-found` → no-op.
- Ambas responden `204`.

No se requiere ningún lock/mutex adicional — la idempotencia a nivel de cada paso basta porque el
orden de pasos ya es fijo y cada paso downstream tolera "ya hecho". No introducir semáforos ni
tablas de estado de borrado (fuera de alcance, guardrail "no polling/no nuevo estado").

## 4. Cliente cierra la app / pierde conexión

- **Antes de que la petición llegue al backend (AC1):** no hay nada que hacer en backend — nunca
  se ejecutó nada. Al reabrir, `AuthCubit.checkAuthState()` (ya existe, se llama en `main.dart`
  línea 172) ve `FirebaseAuth.instance.currentUser != null` y el usuario sigue autenticado. Sin
  cambios.
- **Durante la petición en vuelo (AC2):** Node/Express/Nest **no** aborta el handler HTTP por
  defecto cuando el socket del cliente se cierra a media petición (confirmado: no hay
  `req.on('close')`/`AbortController` en el código, y no se necesita agregar ninguno). El
  `ClientProxy.send(...)` hacia cada microservicio sigue en curso en el proceso del gateway
  independientemente del socket HTTP original. **Ninguna acción de código** — solo un test que lo
  demuestre (desconectar el socket del cliente a mitad de la llamada, verificar en BD que los 8
  pasos igual se completaron).
- **Borrado ya completo al reabrir (AC3):** ver §5.

## 5. Logout forzado por sesión inválida (Flutter)

`lib/core/http/firebase_auth_interceptor.dart` hoy: en `onError`, si `statusCode == 401`, intenta
`_firebaseAuth.currentUser?.getIdToken(true)` (refresh forzado) y reintenta la petición original.
Si el refresh lanza cualquier excepción, el `catch (_) {}` la traga en silencio y el 401 original
se propaga sin que nadie cierre la sesión local.

**Decisión (ADR-2):** cuando el refresh forzado (`getIdToken(true)`) lanza un
`FirebaseAuthException` cuyo `.code` está en `{'user-not-found', 'user-disabled',
'user-token-expired'}` (exactamente la lista del guardrail — **no** `network-request-failed` ni
otros códigos de conectividad), el interceptor:
1. Obtiene `AuthCubit` de forma defensiva vía el patrón ya usado en `_crashReporter()`
   (`try { GetIt.instance<AuthCubit>() } catch (_) { return null; }` — ver
   `lib/core/http/rest_client_functions.dart` líneas 23-29).
2. Si lo obtiene, llama a `authCubit.signOut()` (método ya existente, línea ~247 de
   `auth_cubit.dart` — hace `_authService.signOut()` + `emit(AuthState.unauthenticated())`).
3. Muestra el snackbar vía `AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(...)` (mismo
   patrón que `lib/features/events/presentation/form/widgets/event_form_view.dart:56`) con el
   texto de la nueva key `auth_sessionEndedSnackbar` = **"Tu sesión terminó, inicia sesión de
   nuevo."** (copy neutral fijado por el guardrail — no afirma que la cuenta fue eliminada).
4. Deja que `handler.next(err)` propague el 401 original (no lo resuelve como si fuera éxito).

El redirect a login ya es automático: `AppRouter.appRouter` tiene
`refreshListenable: GoRouterRefreshStream(getIt.get<AuthCubit>().stream)` (línea 143) y su
`redirect` callback (línea 102) comprueba `FirebaseAuth.instance.currentUser != null` — como
`AuthService.signOut()` llama a `_firebaseAuth.signOut()`, el redirect dispara solo sin tocar
`app_router.dart`.

**Por qué NO se necesita un nuevo guard/listener global:** el mecanismo ya existe end-to-end
(AuthCubit stream → GoRouterRefreshStream → redirect). El único hueco es que el interceptor nunca
llama a `signOut()` — cerrar ese hueco es todo el cambio de Flutter en esta fase (fuera del l10n y
del test nuevo).

**Riesgo de doble-disparo:** si dos llamadas 401 llegan casi simultáneamente, ambas intentarían
`signOut()` — es idempotente (`AuthCubit.signOut()` no falla si ya no hay sesión;
`FirebaseAuth.signOut()` en un usuario ya deslogueado no lanza). No se requiere guard adicional,
pero el snackbar podría mostrarse dos veces — aceptable, no es un guardrail violado; si Backend/QA
lo ve como ruido, usar `ScaffoldMessenger.of(context).clearSnackBars()` antes de mostrar (decisión
de implementación, no bloqueante).

## 6. Timeout del cliente (AC6)

`lib/core/http/app_dio.dart`: `receiveTimeout: const Duration(seconds: 60)` (global, ya existe,
línea 20). `connectTimeout`/`sendTimeout`: 20s. `deleteMyAccount()` en
`lib/features/users/data/repository/user_repository_impl.dart` no tiene ningún override de
`Options` — usa el Dio global tal cual.

**Conclusión (sin cambio funcional):** 60s de `receiveTimeout` > 30-45s estimado para la
orquestación de 8 pasos. **No se necesita override.** Backend/Frontend deja un comentario en
`user_repository_impl.dart` documentando esta conclusión (criterio 6 del PRD), no en el archivo de
`profile/` que no existe.

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
| ------- | -------------- | ------------ | -------------------- |
| Flutter — auth interceptor | Ninguno | `firebase_auth_interceptor.dart`: logout defensivo en `onError` | Ninguno (snackbar vía `scaffoldMessengerKey`, no un widget nuevo) |
| Flutter — users repo | Ninguno | Comentario de conclusión de timeout en `user_repository_impl.dart` | Ninguno |
| Backend — account deletion | N/A (NestJS, no domain/data/presentation) | `account-deletion.service.ts` (catch idempotente paso 1), `users.service.ts` (hardDelete sin precondition, catch P2025), `firebase-auth.service.ts` (catch `auth/user-not-found`) | N/A |

## API contracts (rideglory-api changes)

Ningún endpoint nuevo ni cambio de firma. `DELETE /users/me` mantiene exactamente
`204` (éxito, incluyendo el caso "ya estaba borrado") / `409 ACTIVE_EVENTS_AS_ORGANIZER` / `401` /
`502` (fallo downstream real). El único cambio de comportamiento observable es que un `404`
espurio por reintento-tras-éxito-completo ahora se colapsa a `204`.

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|-------------|---------|--------|
| DELETE | /users/me | Firebase ID token | — | 204 (idempotente, incluye reintento tras borrado completo) | 409 `ACTIVE_EVENTS_AS_ORGANIZER`, 401, 502 |

## New models and DTOs

Ninguno. Esta fase no agrega campos ni tablas — solo endurece manejo de errores en handlers
existentes.

## Environment variables

Ninguna nueva. No hay `analysis/ENV_DELTA.md` que producir.

## Datos / migraciones

Ninguna migración de Prisma. No hay `analysis/MIGRATION_PLAN.md` que producir — no cambia el
esquema en ningún microservicio.

## Change map

| file | action | reason | risk |
|---|---|---|---|
| `rideglory-api/api-gateway/src/users/account-deletion.service.ts` | modify | Catch idempotente en `findUserByEmail` (404 → return temprano = éxito); no reordenar los 8 pasos | med |
| `rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts` | modify | Agregar tests: retry tras éxito completo (404 en paso 1 → resuelve sin error), carrera concurrente | low |
| `rideglory-api/users-ms/src/users/users.service.ts` | modify | `hardDelete`: quitar precondition `findOne`, intentar `delete` directo con catch específico de Prisma `P2025` → no-op idempotente | high |
| `rideglory-api/users-ms/src/users/users.service.spec.ts` | modify | Reescribir el test existente que afirma "throws 404 without calling delete" — ahora debe afirmar no-op idempotente | med |
| `rideglory-api/api-gateway/src/auth/firebase-auth.service.ts` | modify | `deleteUser`: catch específico `error.code === 'auth/user-not-found'` → no-op idempotente; cualquier otro código se relanza | high |
| `rideglory-api/api-gateway/src/auth/firebase-auth.service.spec.ts` | modify | Test existente ya simula error con mensaje `'auth/user-not-found'` — verificar/ajustar a la forma real de error del Admin SDK (`.code`) y agregar caso no-op | med |
| `rideglory-api/*-ms` tests de concurrencia (`vehicles-ms`, `maintenances-ms`, `events-ms`) | modify (tests only) | Agregar test de regresión que confirme que los pasos 3/5/6 ya son idempotentes (doble llamada, mismo resultado) — **no tocar el código de producción de estos tres** | low |
| `Rideglory/lib/core/http/firebase_auth_interceptor.dart` | modify | Logout defensivo: en `onError`, si el refresh forzado de token lanza `FirebaseAuthException` con código en `{user-not-found, user-disabled, user-token-expired}`, llamar `GetIt.instance<AuthCubit>().signOut()` (patrón defensivo try/catch) + mostrar snackbar; nunca ante `network-request-failed` u otros | high |
| `Rideglory/lib/l10n/app_es.arb` | modify | Nueva key `auth_sessionEndedSnackbar` = "Tu sesión terminó, inicia sesión de nuevo." | low |
| `Rideglory/lib/l10n/app_localizations.dart` + `app_localizations_es.dart` | modify (generado) | Regenerar tras el cambio de ARB (`flutter gen-l10n` / build_runner) | low |
| `Rideglory/lib/features/users/data/repository/user_repository_impl.dart` | modify | Comentario documentando la conclusión del timeout (60s > 30-45s estimado) en `deleteMyAccount()` — **sin cambio funcional** | low |
| `Rideglory/test/core/http/firebase_auth_interceptor_test.dart` | create | Nuevo — cubre: 401 con refresh exitoso (retry, sin logout), 401 con `user-not-found`/`user-disabled`/`user-token-expired` (logout + snackbar), 401 con `network-request-failed` (sin logout) | med |
| `Rideglory/docs/architecture/DIAGRAMS.md` | modify | Agregar diagrama de secuencia de idempotencia de `DELETE /users/me` (carrera + reintento) — opcional pero recomendado para agentes futuros | low |

**Build (Backend/Frontend) solo toca lo que aparece en esta tabla.** No archivos adicionales, no
refactors oportunistas.

## Riesgos y preguntas abiertas

- **Riesgo alto — forma real del error serializado por `RpcException` al cruzar `ClientProxy`:**
  el helper `isNotFoundRpcError` (§1) y el catch de `hardDelete` (§2) dependen de la forma exacta
  del objeto de error tal como lo recibe el consumidor tras cruzar el transporte de
  microservicios de Nest (TCP/Redis, verificar cuál usa cada `ClientProxy` en
  `config/services.ts`). Backend **debe escribir un test que ejercite el transporte real** (o al
  menos inspeccionar cómo otros catches ya existentes en `account-deletion.service.ts` acceden a
  `error?.message`/`error?.status`) antes de asumir la forma — mitigación: usar el mismo patrón
  duck-typing que ya usan los `catchError` existentes (`error?.message`, revisar si también
  exponen `status`/`statusCode`).
- **Riesgo alto — Prisma `P2025` en `users-ms`:** requiere importar `Prisma` desde
  `../generated/prisma` (ya se importa `Prisma` en el archivo) y usar
  `error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025'`. Verificar que
  el adapter `PrismaPg` propague el mismo tipo de error (no debería cambiar, pero confirmar con un
  test).
- **Riesgo medio — Firebase Admin SDK real vs. el mock del spec actual:** el spec existente simula
  el error como `new Error('auth/user-not-found')` (mensaje plano). El SDK real de
  `firebase-admin` lanza objetos con `.code` (`'auth/user-not-found'`) y `.message`. Backend debe
  verificar contra la documentación del Admin SDK (`FirebaseAuthError`) y ajustar el mock del spec
  para reflejar la forma real, no solo el mensaje.
- **Riesgo medio — doble snackbar/doble `signOut()` en llamadas 401 simultáneas** (§5): aceptado
  como no-bloqueante; documentado para que QA no lo reporte como bug.
- **Abierto — ¿el token cacheado del cliente puede seguir pasando `verifyIdToken` en el gateway
  incluso después de que Firebase Auth borre al usuario?** Sí: un ID token firmado sigue siendo
  criptográficamente válido hasta su expiración (≤1h) salvo que se llame a
  `revokeRefreshTokens`/`checkRevoked: true` en `verifyIdToken`, que **no** se usa hoy en
  `firebase-auth.service.ts`. Esto significa que, en el peor caso, un cliente con un token
  cacheado válido podría seguir pasando el guard del gateway hasta por 1h tras el borrado, y
  cualquier llamada downstream (p. ej. `GET /users/me`) fallaría con 404/500 en vez de 401 porque
  el usuario ya no existe en `users-ms`. **Fuera de alcance de esta fase** (el PRD no pide
  `checkRevoked`, y agregarlo cambiaría el costo/latencia de cada verificación de token) — se deja
  documentado como riesgo residual conocido, no como bug de esta fase. El mecanismo de logout de
  esta fase depende de que **algún** endpoint responda 401 primero (lo cual ocurrirá igual en la
  práctica vía `getIdToken(true)` fallando client-side en el próximo refresh natural del SDK,
  típicamente antes de 1h).

## Next agent needs to know

- **Backend (rideglory-api):**
  - Tocar exactamente los 6 archivos de producción/test listados en el change map (2 servicios +
    sus specs, + specs de regresión en vehicles/maintenances/events-ms). No tocar
    `hardDeleteAllByOwner`, `softDeleteAllByUserId`, `anonymizeByUserId` — ya son idempotentes.
  - El fix de `hardDelete` en users-ms reemplaza el precondition `findOne`, no lo envuelve — leer
    §2 fila 7 antes de escribir código.
  - Escribir el test de "cliente corta el socket a mitad de la petición, backend completa igual"
    contra `account-deletion.service.ts` o como test de integración si existe infraestructura para
    ello; si no existe, documentarlo como test manual/QA en vez de forzarlo.
  - No crear tabla de estado de borrado, no agregar polling, no reordenar los 8 pasos.
- **Frontend (Rideglory):**
  - Un solo archivo de producción real a tocar:
    `lib/core/http/firebase_auth_interceptor.dart`. Reusar el patrón defensivo de
    `_crashReporter()` para `GetIt.instance<AuthCubit>()`.
  - Nueva key ARB `auth_sessionEndedSnackbar`, regenerar l10n.
  - Comentario (no código) en `lib/features/users/data/repository/user_repository_impl.dart`.
  - Test nuevo en `test/core/http/firebase_auth_interceptor_test.dart` — usar mocktail, mockear
    `FirebaseAuth`/`User` y `GetIt`.
  - No tocar `DeleteAccountConfirmationPage` ni sus widgets — cero cambios de UI en esta fase.
- **DevOps:** sin cambios de CI, sin env vars nuevas. Standdown.
- **QA:** ver `handoffs/architect-for-qa.md` — trazabilidad completa de los 7 criterios de
  aceptación, incluyendo cuáles requieren prueba manual/staging (AC2, AC5, AC6 evidencia).

## Fuera de alcance

- UI de loading/spinner/doble-tap/retry (fase 1, no se toca).
- Polling de estado del backend.
- Reordenar los 8 pasos de la orquestación.
- Lógica de negocio de transferencia/cancelación de eventos activos ni anonimización campo por
  campo de `EventRegistration` (fase 3) — solo se verifica que ya son idempotentes, no se
  modifican.
- Notificación por correo/push de cuenta eliminada.
- `checkRevoked: true` en `verifyIdToken` (ver riesgo abierto arriba) — cambiaría el costo de cada
  verificación de token en cada request de la app, no solo en el flujo de borrado; requiere su
  propia fase si se decide abordar.
- Subir el timeout global de `AppDio` (no se necesita evidencia lo justifique).

## Change log

- 2026-07-11: Architect phase complete. Corregidas 3 rutas de archivo del PRD contra el código
  real (account_repository_impl.dart no existe; orquestador real es
  `account-deletion.service.ts`; AbortController confirmado ausente). Hallazgo crítico no
  contemplado en el PRD original: `findUserByEmail` es el primer eslabón no-idempotente de la
  cadena — ADR-1 (catch 404 → return temprano). Confirmado que pasos 3/5/6
  (`hardDeleteAllByOwner`/`softDeleteMaintenancesByUserId`/`anonymizeRegistrationsByUserId`) ya son
  idempotentes por diseño (`updateMany`/`findMany`-condicional) — no tocar su código. Corregido el
  fix de `hardDeleteUser`: el precondition `findOne` lanza 404 antes de llegar al P2025 que el PRD
  pedía envolver — hay que quitar el precondition, no solo envolver el `delete`. ADR-2: logout
  defensivo en el interceptor reutilizando `AuthCubit.signOut()` ya existente + redirect automático
  ya cableado vía `GoRouterRefreshStream` — no se toca `app_router.dart`. Confirmado
  `receiveTimeout` de 60s ya cubre el estimado de 30-45s — sin cambio de timeout. Change map de 12
  archivos (6 backend, 6 frontend/docs). 3 slim handoffs escritos.
