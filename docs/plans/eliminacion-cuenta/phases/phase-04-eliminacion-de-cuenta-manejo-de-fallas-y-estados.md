# Fase 4 — Eliminación de cuenta — manejo de fallas y estados intermedios

_Generado: 2026-07-07T16:02:37Z_

## Objetivo

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

## Alcance (entra / no entra)

**Entra:**
- Verificación (con evidencia de código) de si el interceptor de Firebase Auth existente detecta
  hoy un token inválido tras el hard-delete y fuerza logout — y, si no lo hace (como confirma el
  análisis de esta fase, ver más abajo), el código nuevo mínimo para lograrlo.
- Garantizar que cada paso de la orquestación backend de `DELETE /users/me` (fases 1-3) es
  **idempotente**: repetir la llamada completa (por reintento del cliente, por dos lanzamientos de
  la app, o por una llamada duplicada en vuelo) no lanza error ni duplica efectos si un paso ya se
  ejecutó antes.
- Confirmar que el backend completa la operación de extremo a extremo **aunque el cliente cierre
  la app / pierda la conexión a mitad de la llamada** (el proceso del backend no debe abortarse por
  desconexión del socket HTTP del cliente).
- Confirmar/fijar el timeout del cliente (Dio) para esta llamada específica y documentar si el
  valor global actual ya es suficiente o si hace falta uno específico.
- Mensaje al usuario cuando se fuerza el logout por sesión inválida (p. ej. tras reabrir la app con
  la cuenta ya eliminada en el paso de Firebase Auth).
- Pruebas de concurrencia/idempotencia (dos llamadas superpuestas al mismo endpoint para el mismo
  `uid`).

**No entra (ya cubierto o explícitamente fuera):**
- UI de loading/spinner/doble-tap/botón de reintentar simple de la pantalla de confirmación
  (criterio base de fase 1, `DeleteAccountConfirmationPage` + su cubit).
- Polling de estado del backend — se descarta explícitamente salvo que pruebas reales (ver
  Riesgos) demuestren que 30-45s no alcanza; el diseño de esta fase asume una única llamada
  síncrona de extremo a extremo.
- Rediseño del orden de los 5 pasos de orquestación (ya fijado en fase 1: dominio → PII de usuario
  → Firebase Auth al final) — esta fase solo asegura que cada paso, en ese orden ya fijado, sea
  repetible sin efecto secundario.
- Transferencia/cancelación de eventos activos como organizador (fase 3) y anonimización campo por
  campo de `EventRegistration` (fase 3) — esta fase solo exige que esos pasos, tal como fase 3 los
  implemente, sean idempotentes (updateMany ya lo es por diseño; ver verificación abajo).
- Notificar al usuario por correo/push que su cuenta fue eliminada — no está en el alcance del plan
  (no mencionado en ninguna síntesis previa); no se agrega aquí.

## Qué se debe hacer (pasos concretos y ordenados)

### 1. Verificar el comportamiento actual del interceptor (hallazgo, no suposición)

Se revisó `lib/core/http/firebase_auth_interceptor.dart` y `lib/shared/router/app_router.dart`.
Hallazgo: **el interceptor NO fuerza logout hoy.** Su `onError` solo reacciona a `401` intentando
refrescar el token (`getIdToken(true)`) y reintentar la request una vez; si ese refresco falla
(p. ej. porque Firebase Auth ya no tiene el usuario — `FirebaseAuthException(code:
'user-not-found')` tras un hard-delete), el error se traga en un `catch (_) {}` vacío y la
excepción **original** (`401`) simplemente se propaga (`handler.next(err)`) al call site que la
originó. Nada fuerza `AuthCubit` a emitir `unauthenticated`, nada limpia la sesión local de
Firebase, y nada redirige a login. Además, `AuthCubit.checkAuthState()` solo se llama una vez, al
crear el cubit en `main.dart`/`splash_screen.dart` (no hay `authStateChanges()`/`idTokenChanges()`
suscrito en ningún punto de la app) — por lo que reabrir la app con una cuenta ya eliminada en
Firebase Auth no dispara ninguna revalidación hasta que **algún** call site autenticado reciba un
`401` y su `FirebaseAuthException` de refresco falle.

Conclusión: **hace falta código nuevo** (no es un caso ya cubierto). El punto de enganche correcto
es exactamente ese `catch` vacío de `onError`.

### 2. Forzar logout local cuando el refresco de token confirma sesión inválida

- En `FirebaseAuthInterceptor.onError`, cuando `getIdToken(true)` lanza una
  `FirebaseAuthException` con código en `{'user-not-found', 'user-disabled',
  'user-token-expired'}`, invocar un logout defensivo antes de propagar el error original:
  buscar `AuthCubit` vía `GetIt.instance<AuthCubit>()` (mismo patrón defensivo ya usado por
  `_crashReporter()` en `lib/core/http/rest_client_functions.dart`: `try { ... } catch (_) {
  return null; }`) y llamar a su `signOut()` existente (ya limpia la sesión de Firebase local y
  emite `AuthState.unauthenticated()` — no hace falta un método nuevo en `AuthCubit`).
- `AuthState.unauthenticated()` ya dispara `GoRouterRefreshStream` (suscrito a
  `AuthCubit.stream`, ver `lib/shared/router/app_router.dart:142`), que reevalúa el `redirect` y
  manda a login porque `FirebaseAuth.instance.currentUser` ya es `null` tras el `signOut()` local.
- Mostrar un mensaje breve vía `AppRouter.scaffoldMessengerKey` (ya global, usado en
  `main.dart:179`) indicando que la sesión terminó — mensaje genérico (no se puede afirmar con
  certeza al 100% que la causa es un borrado de cuenta vs. otra invalidación de sesión, así que el
  copy debe ser neutral tipo "Tu sesión terminó, inicia sesión de nuevo.", nueva clave en
  `app_es.arb`).
- No se dispara el logout forzado ante otros códigos de `FirebaseAuthException` (p. ej.
  `network-request-failed`) para no cerrar sesión por un simple problema de conectividad
  transitorio — solo ante señales explícitas de que el usuario/sesión ya no existe.

### 3. Verificar/asegurar idempotencia de cada paso de la orquestación backend (`rideglory-api`)

Repetir la llamada completa a `DELETE /users/me` para el mismo `uid` (por reintento manual, por
relanzar la app y volver a tocar "Eliminar cuenta" antes de que el estado se resuelva, o por una
llamada duplicada en vuelo) debe converger al mismo estado final sin lanzar error ni duplicar
efectos:

- **`vehicles-ms.hardDeleteAllByOwner`** (fase 2): `deleteMany`/borrado por `ownerId` — ya es
  idempotente por naturaleza (si no quedan filas, no hace nada). Confirmar en la implementación de
  fase 2 que no lanza si el owner ya no tiene vehículos.
- **`maintenances-ms.softDeleteMaintenancesByUserId`** (fase 2): `updateMany` — idempotente igual.
- **`events-ms.anonymizeRegistrationsByUserId`** (fase 3): `updateMany` con un `SET` que asigna
  valores fijos (`fullName: '[usuario eliminado]'`, etc.) — idempotente por diseño; confirmar que
  no falla si los campos ya están anonimizados de una corrida anterior.
- **`users-ms.hardDeleteUser`** (fase 1): **requiere ajuste**. Si la fila del usuario ya no existe
  (borrada por una corrida anterior), el `MessagePattern` debe devolver éxito en vez de lanzar
  `NotFoundException`/error de Prisma (`P2025 Record to delete does not exist`) — envolver el
  `delete()` para tratar "ya no existe" como resultado exitoso (idempotente), no como fallo.
- **`FirebaseAuthService.deleteUser(uid)`** (fase 1, `api-gateway`): **requiere ajuste**. El Admin
  SDK lanza `auth/user-not-found` si el `uid` ya fue borrado (p. ej. por una corrida anterior que sí
  llegó a este último paso). Envolver la llamada para tratar ese código específico como éxito
  (idempotente) en vez de propagar el error al orquestador.
- Con estos dos ajustes, si dos llamadas al endpoint se solapan para el mismo `uid` (carrera), la
  primera que llegue a cada paso lo ejecuta y la segunda lo encuentra ya hecho — ambas terminan en
  `204` sin error y sin doble efecto.

### 4. Confirmar que el backend no depende de que el cliente siga conectado

- Verificar en `api-gateway` (el handler de `DELETE /users/me`) que no hay ningún wiring de
  cancelación atado al cierre del socket HTTP del cliente (p. ej. `req.on('close', …)` con
  `AbortController` que interrumpa la ejecución) para esta ruta específica. Si el handler es un
  `async` normal que simplemente sigue sus `await` en secuencia, Nest/Express no aborta la
  ejecución del lado del servidor solo porque el cliente cerró la conexión — la respuesta HTTP
  fallará al intentar escribirse, pero los efectos (borrados/anonimizaciones ya invocados) ya se
  aplicaron. Documentar esto explícitamente como comportamiento esperado y verificado (no asumido).
- Si existe algún middleware/proxy (load balancer, Nginx, timeout de Cloud Run/ALB, etc.) con un
  idle-timeout menor a los 30-45s previstos, señalarlo como riesgo operativo a verificar con quien
  administre la infraestructura (fuera del código de este repo).

### 5. Confirmar/fijar el timeout del cliente

- `AppDio` (`lib/core/http/app_dio.dart`) ya configura `receiveTimeout: Duration(seconds: 60)`
  globalmente — **mayor** que el rango de 30-45s que el Architect recomienda para esta operación.
  Verificado: no hace falta subir ningún timeout global ni añadir un override específico para
  `DELETE /users/me`; el valor global ya es suficiente. Documentar esta conclusión en el código
  (comentario en el repositorio de la fase 1, p. ej. `AccountRepositoryImpl`) para que no se
  reabra la duda en el futuro sin evidencia nueva.
- Si, al ejecutar pruebas reales de la orquestación completa (fase 1+2+3 integradas) contra
  entornos de staging, el tiempo real excede ~55s de forma consistente, esta fase debe entonces
  subir el override específico de esta llamada (`Options(receiveTimeout: ...)` en el método del
  repositorio) — documentado como condicional a evidencia, no implementado preventivamente.

### 6. Pruebas de concurrencia/idempotencia end-to-end

- Ejecutar (manual o vía test de integración en `rideglory-api`) dos llamadas `DELETE /users/me`
  superpuestas para el mismo usuario de prueba y verificar que ambas responden `204` (o la segunda
  responde `204` de forma inmediata si la primera ya terminó) sin ningún error 500 ni estado
  parcial visible en las tablas de `users-ms`/`vehicles-ms`/`events-ms`.
- Ejecutar el escenario "cerrar la app a mitad de la llamada": iniciar el borrado, matar el proceso
  de la app (o cancelar la request desde el cliente) antes de recibir respuesta, y verificar en
  base de datos que el backend igual completó todos los pasos.

## Archivos a crear/modificar

**Flutter (`Rideglory`):**
- `lib/core/http/firebase_auth_interceptor.dart` — en `onError`, ante
  `FirebaseAuthException` con código de sesión inválida al refrescar el token, invocar logout
  defensivo vía `GetIt.instance<AuthCubit>().signOut()` antes de propagar el error original.
- `lib/l10n/app_es.arb` (+ regenerar `app_localizations.dart`/`app_localizations_es.dart` con
  `flutter gen-l10n`) — nueva clave para el mensaje de sesión terminada (p. ej.
  `auth_sessionEndedSnackbar`).
- `lib/features/profile/data/repository/account_repository_impl.dart` (creado en fase 1) —
  comentario que documenta por qué no hace falta override de timeout (punto 5), sin cambio
  funcional salvo que las pruebas reales lo exijan.
- Test nuevo: `test/core/http/firebase_auth_interceptor_test.dart` (crear si no existe) — casos del
  punto 2.

**Backend (`rideglory-api`, repo separado en `/Users/cami/Developer/Personal/rideglory-api`):**
- `users-ms/src/users/users.service.ts` (`hardDeleteUser`, creado en fase 1) — tratar "registro ya
  no existe" (Prisma `P2025`) como éxito idempotente.
- `api-gateway/src/auth/firebase-auth.service.ts` (`deleteUser`, creado en fase 1) — tratar
  `auth/user-not-found` del Admin SDK como éxito idempotente.
- `api-gateway/src/users/users.controller.ts` (o el service que orquesta `DELETE /users/me`,
  fase 1) — sin cambio de firma; solo se apoya en la idempotencia de los pasos anteriores.
- Confirmar (sin necesariamente modificar código) que no hay wiring de `AbortController`/
  `req.on('close')` en la ruta `DELETE /users/me` — si existe, removerlo para esta ruta
  específica.
- Tests nuevos en `users-ms` y `api-gateway` para los dos ajustes de idempotencia (ver Pruebas).

## Contratos / API rideglory-api

Ninguno nuevo. Esta fase no agrega rutas ni `MessagePattern`s — solo hace que los ya definidos en
fases 1-3 (`DELETE /users/me`, `hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`,
`anonymizeRegistrationsByUserId`, `hardDeleteUser`, `FirebaseAuthService.deleteUser`) sean
idempotentes y resilientes a desconexión del cliente. El contrato de respuesta (`204` éxito, `409`
precondición organizador, `401` auth, `502` fallo downstream) fijado en fase 1 no cambia.

## Cambios de datos / migraciones

Ninguno.

## Criterios de aceptación

1. Si el cliente pierde conexión o se cierra la app **antes** de que la petición
   `DELETE /users/me` llegue al backend, al reabrir la app el usuario sigue autenticado con su
   cuenta intacta y puede iniciar el borrado de nuevo desde cero (comportamiento ya natural, sin
   código nuevo — verificado, no solo asumido).
2. Si el cliente cierra la app **durante** la ejecución de `DELETE /users/me` (petición ya en
   vuelo), el backend completa igualmente todos los pasos de la orquestación sin depender de que
   el socket del cliente siga abierto (verificado con prueba de desconexión forzada).
3. Si al reabrir la app el borrado ya se completó por completo (incluido el paso de Firebase
   Auth), la primera llamada autenticada que dispare un `401` fuerza logout local automático
   (`AuthCubit.signOut()`), muestra el mensaje de sesión terminada, y redirige a la pantalla de
   login — sin intervención manual del usuario y sin necesidad de matar/reabrir la app de nuevo.
4. Repetir `DELETE /users/me` para la misma cuenta (ya sea porque el usuario reintentó tras un
   error, o porque dos llamadas quedaron en vuelo) nunca produce un error 500 ni un estado parcial
   distinto al de una sola ejecución exitosa: cada paso downstream (`hardDeleteAllByOwner`,
   `softDeleteMaintenancesByUserId`, `anonymizeRegistrationsByUserId`, `hardDeleteUser`,
   `firebaseAuthService.deleteUser`) es un no-op seguro si ya se ejecutó antes.
5. Dos llamadas `DELETE /users/me` superpuestas en el tiempo para el mismo `uid` (carrera) ambas
   terminan en `204`, sin ninguna quedar en error, y el estado final en base de datos es idéntico
   al de una sola ejecución (no hay filas duplicadas, huérfanas, ni parcialmente anonimizadas).
6. El timeout efectivo del cliente para esta llamada (60s, heredado de `AppDio`) es mayor al rango
   de 30-45s estimado para la orquestación completa — verificado sin necesidad de subirlo; si
   pruebas reales contra staging demuestran lo contrario, se documenta la evidencia y se sube el
   override específico de esta llamada (no el timeout global).
7. El interceptor de Firebase Auth no dispara el logout forzado ante errores de red transitorios
   (`network-request-failed` u otros no relacionados con invalidez de sesión) — solo ante códigos
   que confirman que el usuario/sesión ya no existe.

## Pruebas

**Unitarias/widget (Flutter):**
- `firebase_auth_interceptor_test.dart`: dado un `401` y `getIdToken(true)` lanzando
  `FirebaseAuthException(code: 'user-not-found')`, verificar que se invoca `AuthCubit.signOut()`
  (mock/spy vía `GetIt` de test) exactamente una vez, y que el `DioException` original sigue
  propagándose al llamador (no se cambia el contrato de error existente).
- Mismo test con código `network-request-failed`: verificar que **no** se invoca `signOut()`.
- Test de regresión: el camino feliz de refresco de token exitoso (`getIdToken(true)` no lanza)
  sigue reintentando la request y resolviendo normalmente, sin tocar `AuthCubit`.
- Cubit test (extendiendo el de fase 1, `delete_account_cubit_test.dart` o equivalente): dos
  invocaciones consecutivas de `deleteAccount()` mientras la primera sigue `loading` no disparan
  una segunda llamada HTTP (regresión de la prevención de doble-tap de fase 1, re-verificada aquí
  porque es parte del criterio de idempotencia del reintento).

**Integración/Patrol (Flutter, opcional si el entorno de prueba lo permite):**
- Simular backend devolviendo `502` en el primer intento y `204` en el reintento; verificar que la
  UI de fase 1 permite reintentar y termina en el estado de éxito único (sin doble navegación a
  login, sin doble reset de cubits).

**Backend (`rideglory-api`, a coordinar y ejecutar en ese repo):**
- `users-ms`: `hardDeleteUser` invocado dos veces para el mismo `id` — segunda invocación no lanza
  y responde éxito.
- `api-gateway`: `FirebaseAuthService.deleteUser(uid)` invocado dos veces para el mismo `uid` —
  segunda invocación no lanza y responde éxito.
- Integración: dos requests `DELETE /users/me` concurrentes para el mismo `uid` de prueba (usar
  `qa2@gmail.com` u otro usuario de prueba dedicado, nunca `qa1`/`qa2` reales de QA compartidos sin
  coordinar) — ambas responden `204`, estado final en BD consistente con una sola ejecución.
- Integración: cancelar la conexión del cliente a mitad de la request (p. ej. cerrar el socket
  manualmente desde un test de bajo nivel) y verificar que el backend completa todos los pasos
  igual (consultar BD después, no la respuesta HTTP que ya no se pudo entregar).

## Riesgos y mitigaciones

1. **El mensaje de "sesión terminada" puede confundirse con una expiración normal de sesión** (no
   necesariamente causada por borrado de cuenta) — *mitigación*: copy neutral ("Tu sesión terminó,
   inicia sesión de nuevo.") en vez de afirmar "tu cuenta fue eliminada", ya que el mismo código de
   Firebase (`user-not-found`/`user-disabled`) puede darse por otras causas (p. ej. cuenta
   deshabilitada por soporte).
2. **Logout forzado disparado por falsos positivos de red** — *mitigación*: la lista de códigos
   que disparan el logout forzado es explícita y acotada (`user-not-found`, `user-disabled`,
   `user-token-expired`); errores de conectividad genéricos no la disparan (criterio de aceptación
   7, prueba dedicada).
3. **Idle-timeout de infraestructura (load balancer/proxy) menor al timeout de aplicación** — no
   es código de este repo; *mitigación*: documentar el riesgo explícitamente para quien administre
   despliegue/infraestructura de `rideglory-api`, a verificar antes de considerar cerrado el punto
   4 del alcance.
4. **Falso sentido de seguridad por asumir que Nest/Express no aborta el handler al desconectar el
   cliente** sin haberlo verificado en código real — *mitigación*: paso 4 exige verificación
   explícita en el handler real de `api-gateway`, no una suposición; si se encuentra wiring de
   cancelación, removerlo para esta ruta antes de cerrar la fase.
5. **Cambiar el comportamiento de `hardDeleteUser`/`deleteUser` para "tragar" el caso "ya no
   existe" podría enmascarar un bug real** (p. ej. un `uid` incorrecto que nunca existió, no uno ya
   borrado) — *mitigación*: el guard debe ser específico al código de error de "no encontrado"
   (`P2025` en Prisma, `auth/user-not-found` en Firebase Admin), no un catch genérico que oculte
   cualquier excepción.
6. **Pruebas de concurrencia/desconexión son inherentemente flaky en CI** — *mitigación*: ejecutar
   estas pruebas específicas como pruebas de integración manuales/documentadas en el
   `QA_CHECKLIST.md` de la corrida si resultan poco confiables en el runner automático, en vez de
   forzarlas a un test unitario determinista que no las representa fielmente.

## Dependencias (fases prerequisito y por qué)

- **Fase 1** (núcleo de identidad): define `DELETE /users/me`, el orden de los 5 pasos de
  orquestación, `hardDeleteUser`, `FirebaseAuthService.deleteUser`, y la pantalla/cubit de
  confirmación con su loading/retry base — esta fase extiende esos mismos artefactos, no puede
  empezar sin ellos.
- **Fase 2** (vehículos y documentos): agrega `hardDeleteAllByOwner` y
  `softDeleteMaintenancesByUserId` — esta fase verifica su idempotencia, así que deben existir
  primero.
- **Fase 3** (historial de eventos): agrega `anonymizeRegistrationsByUserId` y el contrato `409` de
  organizador con eventos activos — esta fase verifica que la re-evaluación de esa precondición en
  cada reintento sea consistente (si el usuario cancela sus eventos entre un intento fallido y un
  reintento, el reintento debe pasar la precondición sin error espurio).

## Ejecución recomendada (nivel rg-exec: full)

**Por qué ese nivel:** Reclasificada explícitamente de media a alta por el Architect: no hay
precedente en el repo de operación multi-paso con manejo de fallo parcial; el endpoint que orquesta
es el mismo de alto riesgo con un paso irreversible — un diseño erróneo de idempotencia puede dañar
cuentas de forma permanente.
