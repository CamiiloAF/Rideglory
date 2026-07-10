# Architect review — Eliminación de cuenta

_Generado: 2026-07-07T15:54:33Z_

Basado en `01-scan.md`, `02-po-proposal.md` y verificación directa contra `rideglory-api`
(`users-ms`, `vehicles-ms`, `maintenances-ms`, `events-ms`, `api-gateway`) y contra
`lib/features/profile/presentation/widgets/profile_actions_list.dart`.

## Validación por fase

### Fase 1 — núcleo de identidad
**Viable. Complejidad: media.**

Confirmado en código:
- `ProfileActionsList._logout()` es el patrón exacto a extender (mismo archivo, mismo
  `ConfirmationDialog(confirmType: danger)`, mismo bloque de limpieza de cubits +
  `context.goAndClearStack(AppRoutes.login)`).
- `users-ms.User` (Prisma) ya tiene todos los campos PII a limpiar en una sola fila
  (`fullName`, `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`,
  `medicalInsurance`, `bloodType`, `emergencyContact*`, `fcmToken`) y ya tiene `isDeleted`.
  `UsersService.remove(id)` hoy solo hace `update({ isDeleted: true })` — **no limpia PII**. Esto
  es el gap real a cerrar en fase 1, no solo "un endpoint nuevo".
- `FirebaseAuthService` en `api-gateway` ya inicializa `firebase-admin` con `getAuth()`; agregar
  `getAuth(this.firebaseApp).deleteUser(uid)` es trivial y de bajo riesgo.
- No existe `DELETE /users/me` en `UsersController` (api-gateway) ni `@MessagePattern` equivalente
  más allá de `removeUser` (que hoy hace soft delete parcial). Hay que decidir: ¿se reemplaza
  `removeUser` por un hard-delete/anonimización completa, o se agrega un `MessagePattern` nuevo
  (`deleteUserAccount`) para no romper otros llamadores de `removeUser`? **Ajuste necesario** (ver
  sección Ajustes).
- Riesgo real de complejidad "media" (no "baja"): el orden de operaciones importa. Si se borra el
  usuario de Firebase Auth **antes** de que el backend termine de limpiar PII/relaciones, y esa
  limpieza falla, queda un usuario sin sesión válida pero con datos parcialmente vivos en Postgres
  — exactamente el escenario que la fase 4 debe cubrir, así que fase 1 debe fijar el orden correcto
  desde el día uno (ver Riesgos).

### Fase 2 — vehículos y documentos
**Viable. Complejidad: media.**

Confirmado en código:
- `Vehicle.ownerId`, `Soat.vehicleId` (único, 1:1), `Tecnomecanica.vehicleId` (único, 1:1) en
  `vehicles-ms/prisma/schema.prisma` — confirma que SOAT/RTM son sub-recursos del vehículo, no
  entidades de cuenta independientes.
- Ya existe el flujo `DELETE hard-delete/:id` en `vehicles.controller.ts` que, antes de borrar el
  vehículo, hace RPC síncrono a `maintenances-ms` (`softDeleteMaintenancesByVehicleId`) — **este es
  el patrón de orquestación cross-MS de referencia** que la fase 2 debe replicar, no inventar desde
  cero.
- Sin embargo, `hard-delete/:id` es **por vehículo individual**, no por `ownerId`. La ruta más
  simple no es "loopear el endpoint HTTP existente N veces" (introduce N round-trips HTTP internos,
  N transacciones separadas, fallos parciales más probables), sino un método interno nuevo
  `vehiclesService.hardDeleteAllByOwner(ownerId)` que:
  1. Obtiene los `vehicleId`s del owner.
  2. Llama una sola vez a `maintenances-ms` con la lista completa de `vehicleId`s (requiere
     extender `softDeleteMaintenancesByVehicleId` a aceptar array, o agregar
     `softDeleteMaintenancesByUserId` directo por `userId` — más simple, dado que `Maintenance.
     userId` ya existe).
  3. Ejecuta `prisma.vehicle.deleteMany({ where: { ownerId } })` (cascada implícita a `Soat`/
     `Tecnomecanica` si se agregan `onDelete: Cascade` en el schema — **hoy no existen relaciones
     explícitas `Vehicle -> Soat/Tecnomecanica` en Prisma**, son solo `vehicleId` sueltos sin
     `@relation`; sin `onDelete: Cascade` un `deleteMany` de `Vehicle` NO borra automáticamente
     filas huérfanas de `Soat`/`Tecnomecanica`). **Esto es un hallazgo nuevo no capturado en el
     scan**: hay que borrar `Soat`/`Tecnomecanica` explícitamente por `vehicleId IN (...)` antes o
     junto con el `deleteMany` de `Vehicle`, o agregar la relación+cascade en una migración.
- Limpieza de Storage: `storage-cleanup.service.ts` limpia por `prefix` de carpeta
  (`pending/`), pero `ImageStorageService.uploadImage` en Flutter sube a `storagePath` y guarda
  la **download URL completa** (`ref.getDownloadURL()`), no el path relativo, en `Vehicle.imageUrl`
  / `Soat.documentUrl` / `Tecnomecanica.documentUrl`. Para borrar por lote hace falta que el
  backend derive el Storage path desde la URL guardada (parseable, pero frágil) o que la fase
  confirme/estandarice una convención de carpeta por `ownerId` (`vehicles/{ownerId}/{vehicleId}/...`)
  consultable con `bucket.getFiles({ prefix })` como hace `storage-cleanup.service.ts`. **Ajuste
  necesario.**

### Fase 3 — historial de eventos y organizadores activos
**Viable. Complejidad: alta.**

Confirmado en código:
- `EventRegistration` (events-ms) tiene exactamente el bloque PII descrito en el scan, más dos
  campos de consentimiento no mencionados en la PO proposal: `riskAcceptedAt`/
  `riskAcceptanceVersion` y `medicalConsentAcceptedAt`/`medicalConsentVersion`. **Estos son
  registros legales de consentimiento** (aceptación de riesgo, consentimiento médico) — anonimizar
  el registro completo sin preservar evidencia de que el consentimiento fue dado en su momento
  puede ser un problema legal/de auditoría distinto al de privacidad. Definir explícitamente si
  estos campos se anonimizan igual que el resto o se preservan como evidencia de auditoría
  (probablemente sí se pueden anonimizar el nombre/versión asociada sin perder el timestamp, pero
  debe ser una decisión explícita de la fase, no un efecto colateral de un `UPDATE ... SET fullName
  = NULL` genérico).
- `Event.ownerId` existe y `EventState` tiene `DRAFT | SCHEDULED | IN_PROGRESS | CANCELLED |
  FINISHED`. "Eventos activos" para efectos de bloqueo de borrado de cuenta debe definirse como
  `state IN (DRAFT, SCHEDULED, IN_PROGRESS)` (todo lo que no es terminal). Esto es una decisión de
  producto que la fase debe fijar explícitamente en el contrato del endpoint (409 con el conteo/
  lista de eventos bloqueantes), no dejarlo implícito.
- No existe hoy ningún mecanismo de "transferir" propiedad de un evento (`ownerId` reasignable) —
  la opción "transferir" mencionada en la propuesta de PO **no tiene soporte de datos ni de API
  hoy**. Si la fase 3 la promete como alternativa a "cancelar", es trabajo nuevo no trivial
  (¿a quién se transfiere? ¿requiere que el nuevo owner acepte?). **Ajuste necesario**: la fase 3
  debe, o (a) recortar el alcance a solo "cancelar" (más simple, consistente con lo que ya existe:
  `EventState.CANCELLED`), o (b) incluir explícitamente el diseño de transferencia de ownership
  como sub-historia con su propio endpoint.
- Anonimización cross-MS: como `EventRegistration.userId` no tiene FK a `users-ms.User` (son
  microservicios separados sin relación de base de datos), la orquestación es: `api-gateway` (o
  `users-ms` como orquestador) llama a `events-ms` con un nuevo `MessagePattern`
  (`anonymizeRegistrationsByUserId`) que hace `updateMany({ where: { userId }, data: { fullName:
  '[usuario eliminado]', identificationNumber: null, phone: null, email: null, ... } })` —
  consistente con el patrón síncrono ya usado en `hard-delete/:id`→`maintenances-ms`.

### Fase 4 — manejo de fallas y estados intermedios
**Viable. Complejidad: alta** (no "media" implícita en la propuesta — es la fase que más
depende de decisiones arquitectónicas que aún no existen en el repo).

- No hay ningún precedente en el repo de "operación larga con estado persistente" ni de patrón
  saga/outbox — todo el borrado existente (`hard-delete/:id`) es una sola llamada HTTP síncrona
  que, si falla a mitad de camino (p. ej. `maintenances-ms` no responde en el timeout de 15s),
  deja el vehículo sin borrar en absoluto porque el `RpcException` aborta antes del
  `prisma.vehicle.delete()`. Ese es el patrón "todo o nada por paso, con excepción propagada" —
  aceptable como base, pero **no cubre el caso multi-paso de borrado de cuenta** (identidad →
  vehículos → eventos → Firebase Auth), donde un fallo en el paso 3 de 4 deja pasos 1-2 ya
  aplicados de forma irreversible.
- Recomendación de diseño (a decidir explícitamente en fase de arquitectura de fase 4, no aquí):
  orden de operaciones que minimice el "punto de no retorno":
  1. Validar precondición (fase 3: sin eventos activos como organizador) — solo lectura, no falla
     nunca a mitad.
  2. Borrar/anonimizar datos de dominio (vehículos+docs+mantenimientos, luego anonimizar
     registros de eventos) — reversible en el sentido de que el usuario sigue autenticado y puede
     reintentar si algo falla aquí (mismo `userId`, operaciones idempotentes con `deleteMany`/
     `updateMany` que no fallan si ya no hay filas).
  3. **Borrar el usuario de `users-ms` (PII) al final de los pasos de dominio**, no al principio.
  4. **Borrar el usuario de Firebase Auth (Admin SDK) como el ÚLTIMO paso, no el primero** — es
     la única operación verdaderamente irreversible y la que invalida la sesión del cliente. Si se
     hace primero (como sugeriría un diseño ingenuo "cerrar sesión ya"), un fallo posterior en el
     borrado de dominio deja al usuario sin poder reautenticarse para reintentar, sin exponer
     ningún mecanismo de soporte alterno.
  Este orden hace que "reintentar" en el cliente sea seguro: mientras el token de Firebase siga
  vivo, reintentar el mismo endpoint reejecuta pasos idempotentes sin duplicar efectos.
- Estado "cierro la app mientras está en curso": dado que no hay mecanismo de cola/estado
  persistente, el diseño realista es que el endpoint de borrado sea **una sola llamada HTTP
  síncrona de extremo a extremo** (con timeout generoso, p. ej. 30-45s) ejecutada enteramente en
  el backend; si el cliente cierra la app a mitad, el backend igual termina la operación (no
  depende de que el cliente siga conectado). Al reabrir, `AuthCubit`/interceptor detecta el token
  inválido (si el borrado ya llegó al paso de Firebase Auth) y fuerza logout natural — coherente
  con lo que el scan ya identificó. Si el cierre ocurre antes de que el backend reciba la
  petición, simplemente no pasó nada y el usuario puede reintentar desde cero.

## Contratos

### `DELETE /users/me` (api-gateway, `UsersController`)
- **Auth**: Firebase ID token (interceptor existente), `uid` resuelto del token, no de parámetro.
- **Precondición (409)**: si el usuario tiene eventos activos como organizador
  (`Event.ownerId = userId AND state IN (DRAFT, SCHEDULED, IN_PROGRESS)`), responde
  `409 Conflict` con `{ message, statusCode: 409, error: 'ACTIVE_EVENTS_AS_ORGANIZER', activeEvents:
  [{ id, name, state }] }` — el cliente Flutter usa esto para el mensaje accionable de fase 3.
- **Orquestación interna (síncrona, en este orden)**:
  1. `vehiclesService.send('hardDeleteAllByOwner', { ownerId })` → borra `Vehicle`+`Soat`+
     `Tecnomecanica` del owner y dispara `maintenancesService.send('softDeleteMaintenancesByUserId',
     { userId })` internamente (mismo patrón que `hard-delete/:id` ya usa hoy, extendido a bulk).
  2. Limpieza de Storage: nuevo `deleteAllFilesForUser(ownerId)` (reusa el patrón de
     `storage-cleanup.service.ts`, requiere convención de carpeta por `ownerId` — ver Ajustes).
  3. `eventsService.send('anonymizeRegistrationsByUserId', { userId })` → `updateMany` en
     `EventRegistration`.
  4. `usersService.send('hardDeleteUser', { id })` → reemplaza el `remove()` actual: limpia PII
     completa (no solo `isDeleted: true`) o hace `delete()` real de la fila (dado "no hay usuarios
     reales", hard-delete real es aceptable y más simple que mantener PII nula).
  5. `firebaseAuthService.deleteUser(uid)` — último paso, irreversible.
- **Éxito**: `204 No Content`.
- **Errores**: `409` (precondición organizador, ver arriba), `502 Bad Gateway` (fallo de algún MS
  downstream, mensaje genérico + `retryable: true` para que fase 4 renderice "reintentar"),
  `401` (token inválido/expirado — interceptor estándar).

### Nuevos `MessagePattern` internos
| MS | Pattern | Payload | Reemplaza/extiende |
|----|---------|---------|---------------------|
| `vehicles-ms` (via api-gateway) | `hardDeleteAllByOwner` | `{ ownerId }` | Nuevo; reusa lógica de `hard-delete/:id` en bulk (`deleteMany`) |
| `maintenances-ms` | `softDeleteMaintenancesByUserId` | `{ userId }` | Nuevo (hoy solo existe por `vehicleId`) |
| `events-ms` | `anonymizeRegistrationsByUserId` | `{ userId }` | Nuevo |
| `users-ms` | `hardDeleteUser` (o extender `removeUser`) | `{ id }` | Reemplaza el soft-delete parcial de `remove()` |

### Firebase Auth
- `FirebaseAuthService.deleteUser(uid: string): Promise<void>` — nuevo método, usa
  `getAuth(this.firebaseApp).deleteUser(uid)`. Ya hay precedente de `getAuth()` en el mismo archivo.

### Flutter — contrato de consumo
- Nuevo `DeleteAccountUseCase` (domain) + método en un repo nuevo o extendido (`UserRepository`
  si existe, si no, nuevo `AccountRepository` en `lib/features/profile/` o `lib/features/
  authentication/`) que llama `UserService` (Retrofit) con `@DELETE('users/me')`.
- Manejo de `409`: mapear a un `DomainException` tipado (`ActiveEventsAsOrganizerException` con la
  lista de eventos) para que la UI de fase 3 pueda mostrar el mensaje específico, no un error
  genérico.
- Tras éxito (`204`): mismo bloque de limpieza de `_logout()` (`AuthCubit`, `VehicleCubit.
  clearVehicles()`, `ProfileCubit.reset()`, `context.goAndClearStack(AppRoutes.login)`) — no se
  necesita `signOut()` explícito de Firebase porque el backend ya invalidó el usuario, pero
  llamarlo igual es inofensivo y más defensivo (evita depender de que el token cacheado localmente
  expire por su cuenta).

## Riesgos

1. **Cascada de borrado incompleta en `vehicles-ms`** (nuevo hallazgo): `Soat`/`Tecnomecanica` no
   tienen `@relation`/`onDelete: Cascade` hacia `Vehicle` en el schema actual — un `deleteMany` de
   `Vehicle` no los borra solo. *Mitigación*: borrar explícitamente `Soat`/`Tecnomecanica` por
   `vehicleId IN (...)` antes del `deleteMany` de `Vehicle`, o agregar la relación+cascade en una
   migración de la fase 2 (preferible a largo plazo, pero cambia el schema — coordinar con
   Backend/DBA de la fase).
2. **Orden de operaciones borra-primero-pregunta-después**: si Firebase Auth se borra antes que el
   dominio, un fallo posterior dañado deja al usuario sin forma de reintentar autenticado.
   *Mitigación*: contrato fijado arriba — Firebase Auth siempre el último paso.
3. **Convención de Storage path vs. download URL**: hoy se guarda la URL completa de descarga, no
   el path; un borrado por lote de Storage necesita derivar el path o requiere una convención de
   carpeta por `ownerId` confirmable con `bucket.getFiles({ prefix })`. *Mitigación*: la fase 2
   debe fijar explícitamente la convención de carpeta (`vehicles/{ownerId}/...`,
   `profile/{ownerId}/...`) antes de implementar el bulk-delete; si hoy no sigue esa convención, es
   una migración de nomenclatura, no solo un endpoint nuevo.
4. **"Transferir evento" sin soporte de datos**: la propuesta de PO menciona transferir eventos
   como alternativa a cancelar, pero no existe ningún mecanismo de reasignación de `ownerId`.
   *Mitigación*: ver Ajustes — recortar a solo "cancelar" en fase 3, o crear sub-historia explícita.
5. **Consentimientos legales anonimizados sin distinción**: anonimizar `EventRegistration` en bloque
   podría borrar evidencia de aceptación de riesgo/consentimiento médico junto con la PII.
   *Mitigación*: la fase 3 debe especificar campo por campo qué se anonimiza (nombre, documento,
   contacto) vs. qué se preserva (timestamps y versión de consentimiento, sin el nombre asociado).
6. **Timeout de orquestación síncrona de 4-5 pasos**: cada paso ya tiene timeouts individuales
   (15s en el patrón existente); una cadena de 4 pasos síncronos puede acercarse a 60s+ en el peor
   caso, arriesgando el timeout HTTP del cliente Dio (20s configurados en `AppDio`). *Mitigación*:
   la fase 4 debe o (a) subir el timeout de Dio específicamente para este endpoint, o (b) que el
   backend responda rápido con un estado "en progreso" y el cliente consulte estado — esto último
   es más complejo y debe decidirse explícitamente, no asumirse.
7. **`removeUser` ya en uso por otros llamadores**: cambiar su comportamiento de soft-delete a
   hard-delete/anonimización completa podría afectar código existente que invoque ese
   `MessagePattern` esperando el comportamiento actual. *Mitigación*: grep de todos los
   `usersService.send('removeUser', ...)` en `api-gateway` antes de tocarlo; si hay más de un
   llamador con expectativas distintas, preferir un `MessagePattern` nuevo (`hardDeleteUser`) en
   vez de mutar el existente.

## Ajustes

1. **Fase 1**: no asumir que "agregar el endpoint" es el trabajo — el trabajo real es decidir y
   documentar si `users-ms.removeUser` se reemplaza por hard-delete/anonimización completa o si se
   agrega un `MessagePattern` nuevo separado (`hardDeleteUser`) para no romper otros llamadores.
   Verificar usos existentes de `removeUser` antes de tocarlo.
2. **Fase 1**: fijar explícitamente el orden de los 5 pasos de orquestación (dominio → PII →
   Firebase Auth al final) desde esta fase, no dejarlo implícito para que fase 4 lo "arregle"
   después — cambiar el orden a mitad de plan obliga a rehacer trabajo ya probado.
3. **Fase 2**: agregar explícitamente al alcance (a) el borrado de `Soat`/`Tecnomecanica` por
   `vehicleId` antes/junto al `deleteMany` de `Vehicle` (no asumir cascada automática), y (b) fijar
   la convención de carpeta de Storage por `ownerId` (o el mecanismo de derivar el path desde la
   URL guardada) como prerequisito del bulk-delete de imágenes.
4. **Fase 2**: extender `maintenancesService` con un `MessagePattern` por `userId` directo
   (`softDeleteMaintenancesByUserId`) en vez de loopear el existente por `vehicleId` — más simple y
   consistente dado que `Maintenance.userId` ya existe como campo directo.
5. **Fase 3**: recortar el alcance de "organizador con eventos activos" a **solo bloquear con
   mensaje de cancelar** (sin "transferir") salvo que el equipo decida explícitamente invertir en
   diseñar transferencia de ownership como sub-historia propia — hoy no hay ningún soporte de datos
   para reasignar `Event.ownerId`.
6. **Fase 3**: especificar campo por campo qué se anonimiza vs. qué se preserva en
   `EventRegistration`, distinguiendo PII de contacto/salud (anonimizable) de metadata de
   consentimiento legal (`riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`,
   `medicalConsentVersion` — probablemente se preserva el timestamp/versión sin el nombre).
7. **Fase 3 → 4, dependencia de orden**: la fase 3 debe cerrar la definición de "evento activo"
   (`state IN (DRAFT, SCHEDULED, IN_PROGRESS)`) y el contrato `409` antes de que la fase 4 diseñe
   reintentos, porque el reintento debe re-evaluar la misma precondición cada vez.
8. **Fase 4**: reclasificar complejidad de "media" (implícita en la propuesta) a **alta** — no hay
   precedente de operación multi-paso con manejo de fallo parcial en el repo; el diseño de "qué
   paso es reversible/reintenable" es trabajo de arquitectura nuevo, no solo UI de error/loading.
   Fijar explícitamente si el endpoint es una sola llamada síncrona de extremo a extremo (recomendado,
   consistente con el resto del repo) o si se introduce polling de estado (evitar salvo que el
   timeout de 30-45s resulte insuficiente en pruebas reales).
9. **Todas las fases**: no reordenar el trabajo backend vs. frontend dentro de cada fase — cada
   fase que toca `DELETE /users/me` (1, 2, 3) extiende el MISMO endpoint/orquestación en el
   backend en vez de crear endpoints paralelos; el contrato de arriba es el contrato final desde
   la fase 1, y las fases 2-3 solo añaden pasos a la orquestación existente, no rutas nuevas.
