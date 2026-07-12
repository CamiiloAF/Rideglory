# PRD Normalizado — eliminacion-cuenta-phase-04

_Generado: 2026-07-11T17:13:35Z_
_Fuente: `docs/plans/eliminacion-cuenta/phases/phase-04-eliminacion-de-cuenta-manejo-de-fallas-y-estados.md`_

## 1 Objetivo

Como rider, si cierro la app mientras la eliminación de mi cuenta está en curso, al reabrir
entiendo el estado real de mi cuenta (sigo autenticado y puedo reintentar, o mi sesión ya terminó
porque el borrado se completó) y puedo reintentar sin duplicar efectos ni quedar en un estado
ambiguo.

Esta fase **no** rediseña el flujo de eliminación de cuenta (pantalla, `ConfirmationDialog`,
loading/spinner, prevención de doble-tap y manejo de error/retry simple ya son criterio base de la
fase 1). Su único trabajo es cerrar dos huecos concretos que la fase 1 no cubre: (a) qué pasa
cuando el usuario cierra la app a mitad del borrado y la reabre, y (b) que reintentar la misma
operación (una o varias veces, desde uno o varios lanzamientos de la app) converja siempre al mismo
estado final correcto sin duplicar ni corromper datos.

## 2 Por qué

El endpoint `DELETE /users/me` orquesta un paso **irreversible** (Firebase Auth) al final de una
secuencia multi-servicio. Sin garantías de idempotencia y sin manejo del estado de sesión tras un
borrado que se completó mientras la app estaba cerrada, un usuario puede quedar en un estado
ambiguo (cree seguir teniendo cuenta, o reintenta y provoca errores 500/estados parciales). Un
diseño erróneo de idempotencia puede dañar cuentas de forma permanente — de ahí que el Architect
reclasificara esta fase de riesgo medio a alto.

## 3 Alcance

**Entra:**
- Verificar (con evidencia de código) si el interceptor de Firebase Auth detecta hoy un token
  inválido tras el hard-delete y fuerza logout; si no lo hace, agregar el código mínimo necesario.
- Garantizar idempotencia de cada paso de la orquestación backend de `DELETE /users/me` (fases
  1-3): repetir la llamada completa no lanza error ni duplica efectos si un paso ya se ejecutó.
- Confirmar que el backend completa la operación de extremo a extremo aunque el cliente cierre la
  app / pierda conexión a mitad de la llamada.
- Confirmar/fijar el timeout del cliente (Dio) para esta llamada específica y documentar la
  conclusión.
- Mensaje al usuario cuando se fuerza el logout por sesión inválida.
- Pruebas de concurrencia/idempotencia (dos llamadas superpuestas al mismo endpoint, mismo `uid`).

**No entra (ya cubierto o explícitamente fuera):**
- UI de loading/spinner/doble-tap/botón de reintentar simple (criterio base de fase 1).
- Polling de estado del backend (descartado salvo evidencia real de que 30-45s no alcanza).
- Rediseño del orden de los 5 pasos de orquestación (ya fijado en fase 1).
- Transferencia/cancelación de eventos activos como organizador y anonimización de
  `EventRegistration` (fase 3) — esta fase solo exige que esos pasos sean idempotentes tal como
  fase 3 los implemente.
- Notificar al usuario por correo/push que su cuenta fue eliminada.

## 4 Áreas afectadas (best-effort)

**Flutter (`Rideglory`):**
- `lib/core/http/firebase_auth_interceptor.dart` — logout defensivo en `onError`.
- `lib/l10n/app_es.arb` (+ regenerar `app_localizations.dart`/`app_localizations_es.dart`) — nueva
  clave `auth_sessionEndedSnackbar` (o similar).
- `lib/features/profile/data/repository/account_repository_impl.dart` — comentario documentando
  la conclusión del timeout (sin cambio funcional salvo evidencia).
- `test/core/http/firebase_auth_interceptor_test.dart` (nuevo).

**Backend (`rideglory-api`, repo separado en `/Users/cami/Developer/Personal/rideglory-api`):**
- `users-ms/src/users/users.service.ts` (`hardDeleteUser`) — tratar `P2025` (Prisma "record to
  delete does not exist") como éxito idempotente.
- `api-gateway/src/auth/firebase-auth.service.ts` (`deleteUser`) — tratar `auth/user-not-found`
  del Admin SDK como éxito idempotente.
- `api-gateway/src/users/users.controller.ts` (o service orquestador) — sin cambio de firma.
- Verificar (y remover si existe) wiring de `AbortController`/`req.on('close')` en la ruta
  `DELETE /users/me`.
- Tests nuevos en `users-ms` y `api-gateway` para los ajustes de idempotencia.

## 5 Criterios de aceptación

1. Si el cliente pierde conexión o se cierra la app **antes** de que la petición
   `DELETE /users/me` llegue al backend, al reabrir la app el usuario sigue autenticado con su
   cuenta intacta y puede iniciar el borrado de nuevo desde cero (verificado, no solo asumido).
2. Si el cliente cierra la app **durante** la ejecución de `DELETE /users/me` (petición ya en
   vuelo), el backend completa igualmente todos los pasos de la orquestación sin depender de que
   el socket del cliente siga abierto (verificado con prueba de desconexión forzada).
3. Si al reabrir la app el borrado ya se completó por completo (incluido el paso de Firebase
   Auth), la primera llamada autenticada que dispare un `401` fuerza logout local automático
   (`AuthCubit.signOut()`), muestra el mensaje de sesión terminada, y redirige a la pantalla de
   login — sin intervención manual del usuario y sin necesidad de matar/reabrir la app de nuevo.
4. Repetir `DELETE /users/me` para la misma cuenta (por reintento tras error, o por dos llamadas
   en vuelo) nunca produce un error 500 ni un estado parcial distinto al de una sola ejecución
   exitosa: cada paso downstream (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`,
   `anonymizeRegistrationsByUserId`, `hardDeleteUser`, `firebaseAuthService.deleteUser`) es un
   no-op seguro si ya se ejecutó antes.
5. Dos llamadas `DELETE /users/me` superpuestas en el tiempo para el mismo `uid` (carrera) ambas
   terminan en `204`, sin ninguna quedar en error, y el estado final en base de datos es idéntico
   al de una sola ejecución (no hay filas duplicadas, huérfanas, ni parcialmente anonimizadas).
6. El timeout efectivo del cliente para esta llamada (60s, heredado de `AppDio`) es mayor al
   rango de 30-45s estimado para la orquestación completa — verificado sin necesidad de subirlo;
   si pruebas reales contra staging demuestran lo contrario, se documenta la evidencia y se sube
   el override específico de esta llamada (no el timeout global).
7. El interceptor de Firebase Auth no dispara el logout forzado ante errores de red transitorios
   (`network-request-failed` u otros no relacionados con invalidez de sesión) — solo ante códigos
   que confirman que el usuario/sesión ya no existe.

## 6 Guardrails de regresión

- No modificar la UI de loading/spinner/doble-tap/retry simple de `DeleteAccountConfirmationPage`
  (criterio base de fase 1, fuera de alcance de esta fase).
- No introducir polling de estado del backend.
- No reordenar los 5 pasos de la orquestación de `DELETE /users/me` fijados en fase 1 (dominio →
  PII de usuario → Firebase Auth al final).
- No tocar la lógica de transferencia/cancelación de eventos activos como organizador ni la
  anonimización campo por campo de `EventRegistration` (fase 3) — solo verificar que ya son
  idempotentes.
- No agregar notificación por correo/push de cuenta eliminada.
- El guard de idempotencia en `hardDeleteUser`/`FirebaseAuthService.deleteUser` debe ser
  específico al código de error de "no encontrado" (`P2025` en Prisma, `auth/user-not-found` en
  Firebase Admin) — nunca un catch genérico que oculte cualquier otra excepción real.
- La lista de códigos de `FirebaseAuthException` que disparan logout forzado debe permanecer
  acotada a `{'user-not-found', 'user-disabled', 'user-token-expired'}` — no ampliar a errores de
  conectividad genéricos (p. ej. `network-request-failed`).
- El copy del mensaje de sesión terminada debe ser neutral ("Tu sesión terminó, inicia sesión de
  nuevo."), sin afirmar que la cuenta fue eliminada.
- No cambiar el contrato de error/respuesta existente de `DELETE /users/me` (`204` éxito, `409`
  precondición organizador, `401` auth, `502` fallo downstream).
- No subir el timeout global de `AppDio`; cualquier ajuste de timeout debe ser un override
  específico de esta llamada, y solo si hay evidencia real de staging que lo justifique.
- Todo string visible en UI debe ir en `app_es.arb` vía `context.l10n.<key>` (cero hardcodeo).

## 7 Constraints heredados

- Clean Architecture: domain sin imports de Flutter ni I/O; data sin `BuildContext`; presentation
  sin llamadas HTTP directas ni exposición de DTOs.
- Cubits: `Cubit<ResultState<T>>` para operaciones simples; sin flags booleanos de
  loading/error.
- Backend (`rideglory-api`) es un repo separado (super-repo de submódulos); cambios ahí no se
  commitean desde esta corrida — el humano coordina el commit en cada repo.
- Patrón defensivo de acceso a `GetIt` fuera del árbol de widgets ya usado en
  `_crashReporter()` (`lib/core/http/rest_client_functions.dart`): `try { ... } catch (_) { return
  null; }` — reusar ese mismo patrón para `GetIt.instance<AuthCubit>()` en el interceptor.
- No crear una segunda ruta/`MessagePattern` nueva; esta fase solo endurece los contratos ya
  fijados en fases 1-3.
- Nunca ejecutar git add/commit/push/merge/rebase/restore/reset ni gh pr create/merge/review
  durante esta corrida — el árbol de trabajo queda sucio para revisión humana.
- No modificar `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**` (legado),
  `.claude/**`, ni la nota fuente original de esta fase.
