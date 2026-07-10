# Scan — Eliminación de cuenta

_Generado: 2026-07-07T15:51:12Z_

## Inventario Flutter

- **`profile`** (`lib/features/profile/`): `ProfileActionsList` (widget objetivo del ítem
  "Eliminar cuenta") ya contiene el patrón de referencia `_logout()` + `ConfirmationDialog` tipo
  `danger` para "Cerrar sesión". `ProfileCubit` (`Cubit<ResultState<...>>`) con `reset()`.
  `GetMyProfileUseCase` es el único use case de dominio del feature; no hay repositorio de
  eliminación. No hay página/cubit propios de "settings" fuera de `ProfileActionsList`.
- **`authentication`** (`lib/features/authentication/application/`): `AuthCubit.signOut()` en
  `auth_cubit.dart` (línea 264) delega en `_authService.signOut()`. Es el único punto de
  interacción con Firebase Auth desde la app; no expone hoy ningún método de borrado de cuenta
  (`deleteUser`/reauth) — coherente con la decisión del intake de hacer el borrado vía Admin SDK en
  backend, no cliente.
- **`users`** (`lib/features/users/data/service/user_service.dart`): Retrofit `UserService` con
  `@POST(signUp)`, `@GET(me)`, `@GET('/users/{id}')`, `@PATCH('/users/{id}')`. **No existe
  `@DELETE('/users/me')`** — hay que añadirlo aquí (o en un servicio nuevo del feature `profile`,
  a definir en fase de arquitectura).
- **`vehicles`**: `VehicleRepository`/`VehicleService` ya tienen
  `permanently_delete_vehicle_usecase.dart` y endpoint `hard-delete/:id` (ver backend) — patrón de
  hard-delete ya resuelto en la app, reusable como referencia de UX/cubit para "acción destructiva
  irreversible con confirmación".
- **`soat`/`tecnomecanica`/`vehicle_documents`**: cada uno tiene `delete_*_usecase.dart` propio;
  documentos ya se pueden borrar individualmente hoy (por vehículo), pero no hay barrido "todos los
  documentos de todos mis vehículos" a nivel de cuenta.
- **`maintenance`**: `delete_maintenance_use_case.dart` + `maintenance_delete_cubit.dart` (soft
  delete individual); no hay bulk-delete por usuario.
- **`notifications`**: `register_fcm_token_usecase.dart` (registrar), no hay use case para
  eliminar/limpiar token FCM.
- **`events`**: feature más grande, con `event_registration` como consumidor de datos de
  perfil/salud (`fullName`, `bloodType`, contacto de emergencia, etc. — ver DTO backend). No hay
  ningún concepto de "anonimizar mi historial" del lado Flutter (es 100% responsabilidad backend;
  la app solo lista/consulta).
- No existe ninguna página/cubit "Settings" ni "DeleteAccount" en ningún feature — el ítem hay que
  crearlo desde cero siguiendo el patrón `_logout`.

## Dependencias (pubspec.yaml)

Relevantes para esta fase: `firebase_auth: ^6.1.2` (sesión activa, no borra usuario — se asume
Admin SDK backend), `dio`/`retrofit` (llamada HTTP nueva), `go_router` (`goAndClearStack`),
`flutter_bloc`/`bloc` (nuevo cubit o extensión de uno existente), `firebase_storage` (ya en uso
para imágenes; el borrado de Storage es responsabilidad backend, no de la app), `sentry_flutter`
(captura de error si el borrado falla), `firebase_analytics` (posible evento
`account_deleted`/opt-out). No se requieren dependencias nuevas.

## Superficie rideglory-api

**Estructura**: super-repo con 7 submódulos independientes (`api-gateway`, `users-ms`,
`vehicles-ms`, `events-ms`, `maintenances-ms`, `notifications-ms`) + 2 libs compartidas
(`rideglory-contracts`, `rideglory-common-lib`). Comunicación gateway→MS vía `MessagePattern`
(microservicios NestJS, no HTTP directo).

- **`api-gateway/src/users`**: `UsersController` (`@Controller('users')`) expone `POST sign-up`,
  `GET me`, `GET :id`, `PATCH :id`. **No existe `DELETE me` ni `DELETE :id`** — endpoint a crear.
- **`api-gateway/src/auth/firebase-auth.service.ts`**: ya inicializa `firebase-admin` (App +
  `getAuth()`) para `verifyToken`. Añadir un método `deleteUser(uid)` aquí es trivial (SDK ya
  disponible, evita el problema de reauth reciente del client SDK).
- **`api-gateway/src/vehicles`**: `VehiclesController` ya tiene `DELETE my/:vehicleId` (soft) y
  `DELETE hard-delete/:id` (permanente) — **patrón de hard-delete de referencia** ya validado en
  producción de código; también `DELETE :vehicleId/soat` y `DELETE :vehicleId/tecnomecanica`
  (endpoints existentes por vehículo, no por cuenta completa).
- **`api-gateway/src/ai/storage-cleanup.service.ts`**: precedente de barrido de Firebase Storage
  (`file.delete()` en loop) — reusable como patrón para limpiar todas las imágenes de un usuario
  (perfil, vehículos, SOAT, RTM) en el borrado de cuenta.
- **`users-ms/src/users`**: `UsersController` (microservicio, `@MessagePattern`) ya tiene
  `removeUser` → `UsersService.remove(id)` que hace **soft delete** (`isDeleted: true`), NO hard
  delete ni limpieza de PII (nombre, email, datos médicos siguen en la fila). Esto **contradice**
  la promesa de "eliminación inmediata" del `delete-account.html` — hay que decidir si se
  reemplaza por hard delete real o se extiende para anonimizar/limpiar los campos PII.
- **`vehicles-ms`**: modelos `Vehicle` (con `isDeleted`), `Soat`, `Tecnomecanica` — **SOAT y RTM
  viven aquí, como sub-recursos 1:1 de `Vehicle` (`vehicleId @unique`), no en microservicio propio**
  (resuelve la pregunta abierta #2 del intake). No hay endpoint "borrar todos los vehículos de un
  usuario" — solo por `vehicleId` individual.
- **`maintenances-ms`**: modelo `Maintenance` con `userId` directo y `isDeleted` (soft delete ya
  soportado a nivel de fila individual); no hay endpoint bulk por `userId`.
- **`notifications-ms`**: modelo `Notification` con `userId`; el token FCM en realidad vive en
  `users-ms.User.fcmToken` (no en `notifications-ms`) — el intake asume erróneamente que
  `notifications-ms` limpia el token; en la implementación real el borrado del token FCM es parte
  de `users-ms` (mismo update que limpia PII), y `notifications-ms` solo necesitaría borrar/anonimizar
  el historial de notificaciones del `userId` si aplica retención.
- **`events-ms`**: `EventRegistration` tiene el bloque completo de PII/salud
  (`fullName`, `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`,
  `medicalInsurance`, `bloodType`, contacto de emergencia) ligado a `userId` — este es el modelo
  que requiere **anonimización** (no borrado) según la promesa pública. `Event.ownerId` es el
  campo que determina "organizador" — no hay hoy ningún flag ni lógica de "cancelar eventos activos
  del organizador al borrar cuenta" (pregunta abierta #1 del intake sigue sin resolver en código).
- Ningún microservicio expone hoy un endpoint de borrado "por `userId`" cross-recurso — todo el
  borrado existente es por recurso individual (`vehicleId`, `id` de maintenance, etc.), confirmando
  que la orquestación cross-MS (pregunta abierta #3) es 100% trabajo nuevo.
- No hay ningún mecanismo de cola/eventos (Kafka/RabbitMQ/outbox) en el repo — la comunicación
  gateway↔MS es siempre síncrona vía `MessagePattern` (TCP/Redis transporter de Nest). Un enfoque
  "evento `user.deletion.requested`" requeriría introducir infraestructura de mensajería nueva; un
  enfoque síncrono orquestado desde `api-gateway` o `users-ms` es consistente con el patrón
  arquitectónico ya existente en todo el repo.

## Gap analysis

| Pieza | Estado | Detalle |
|---|---|---|
| UI "Eliminar cuenta" en `ProfileActionsList` | **not started** | Patrón de referencia (`_logout`) existe; falta el ítem, el diálogo doble de confirmación, cubit/repo y strings `.arb`. |
| `DELETE /users/me` en `api-gateway` | **not started** | Controller existe pero sin este endpoint; falta guard de auth (ya hay interceptor Firebase reusable). |
| Borrado/limpieza PII en `users-ms` | **partial** | Ya existe `removeUser`→soft delete, pero deja PII intacta; no cumple la promesa de "eliminación inmediata" del doc público. |
| Borrado de vehículos + fotos | **partial** | Ya existe hard-delete por vehículo individual (`hard-delete/:id`) y limpieza de Storage (`storage-cleanup.service.ts` como patrón); falta invocarlo en bulk por `ownerId` y confirmar limpieza de imagen de vehículo en Storage dentro de ese flujo. |
| Borrado de SOAT/RTM + imágenes | **partial** | CRUD y `DELETE` individuales ya existen en `vehicles-ms`; falta bulk por usuario (vía sus vehículos) y confirmar limpieza de Storage de esos documentos. |
| Borrado de historial de mantenimientos | **partial** | Soft delete individual ya existe; falta bulk por `userId`. |
| Borrado de token FCM | **not started** | Vive en `users-ms.User.fcmToken`; se resuelve como parte del mismo update que limpia PII de usuario, no en `notifications-ms`. |
| Anonimización de `EventRegistration` | **not started** | No existe ningún mecanismo de anonimización; requiere nueva lógica en `events-ms` (limpiar campos PII, conservar fila para agregados hasta 3 años). |
| Manejo de organizador con eventos activos | **not started** | Sin flag ni lógica; decisión de producto pendiente (bloquear/avisar/cancelar automático) — pregunta abierta #1 del intake sigue abierta. |
| Borrado de usuario en Firebase Auth (Admin SDK) | **not started** | `firebase-admin` ya inicializado en `api-gateway`; falta solo el método `deleteUser(uid)`. |
| Orquestación cross-MS | **not started** | No hay precedente de "borrado por `userId`" transversal; todo el repo usa `MessagePattern` síncrono — approach síncrono orquestado es el que encaja sin nueva infraestructura. |
| Retención de logs técnicos (30 días) | **not started** (o inexistente) | No se encontró ningún mecanismo de expiración/TTL de logs en el repo escaneado — probablemente solo promesa de copy sin implementación; confirmar con el equipo de observabilidad (Sentry/pino) si existe fuera del código de negocio. |
| UX de estado "borrado en progreso" si se cierra la app | **not started** | No hay precedente de operación larga con estado persistente en la app (todas las llamadas HTTP actuales son de corta duración); a diseñar. |

## Patrones

- **UI destructiva con confirmación**: `_logout()` en `profile_actions_list.dart` +
  `ConfirmationDialog.show(confirmType: DialogActionType.danger)` es el patrón exacto a replicar
  para "Eliminar cuenta" (mismo archivo, mismo estilo de `ProfileMenuItem` con `iconColor`/
  `labelColor` de error).
- **Reset de estado local tras acción de cuenta**: `AuthCubit.signOut()` + `VehicleCubit
  .clearVehicles()` + `ProfileCubit.reset()` + `context.goAndClearStack(AppRoutes.login)` — mismo
  bloque de limpieza a reusar tras un borrado exitoso (posiblemente sin necesidad de `signOut`
  explícito si el backend ya invalidó el usuario, pero el bloque de limpieza de cubits/routing
  aplica igual).
- **Hard-delete backend**: `vehicles-ms`/`api-gateway` ya resolvieron "borrado permanente
  irreversible" para vehículos (`hard-delete/:id`) — mismo patrón de Prisma `delete()` (no solo
  `update isDeleted: true`) a reusar para el borrado real de cuenta, dado que "no hay usuarios
  reales" habilita hard-delete simple según el intake.
- **Limpieza de Storage por lote**: `storage-cleanup.service.ts` (`ai` module) ya hace `file.delete()`
  en loop sobre un listado de Storage — patrón directo para limpiar imágenes de perfil/vehículos/
  documentos de un usuario.
- **Admin SDK ya inicializado**: `FirebaseAuthService` en `api-gateway` ya tiene la `App` de
  `firebase-admin` lista; solo falta agregar `getAuth(this.firebaseApp).deleteUser(uid)`.
- **Comunicación gateway↔MS**: siempre `MessagePattern` síncrono (Nest microservices), nunca
  eventos/colas — cualquier diseño de orquestación debe respetar este estilo salvo decisión
  explícita de introducir mensajería nueva.

## Implicaciones para el plan

- La fase de **arquitectura/backend** debe decidir explícitamente: (a) reemplazar `removeUser`
  soft-delete en `users-ms` por hard-delete real de PII (para cumplir la promesa de "inmediato"),
  (b) diseño de orquestación síncrona desde `api-gateway` o `users-ms` llamando a `vehicles-ms`,
  `maintenances-ms`, `events-ms` (anonimización) en secuencia, con manejo explícito de fallos
  parciales (pregunta abierta #4), y (c) confirmar si el fan-out de borrado de vehículos reusa
  literalmente el endpoint `hard-delete/:id` existente en loop, o si conviene un método interno
  `deleteAllByOwner(ownerId)` más eficiente en Prisma (`deleteMany`).
- **SOAT/RTM ya resuelto de ubicación** (viven en `vehicles-ms`): la fase de backend no necesita
  investigarlo más, solo diseñar el bulk-delete incluyendo estos sub-recursos al borrar cada
  vehículo del usuario.
- El **token FCM** debe removerse de la lista de "microservicios afectados" tal como la enmarcó el
  intake (`notifications-ms`) y reencuadrarse como parte del update/hard-delete de `users-ms.User`
  — evita una llamada cross-MS innecesaria.
- La **decisión de organizador con eventos activos** (pregunta abierta #1) es un bloqueador de
  diseño de producto, no solo de arquitectura — debe resolverse antes de escribir la fase de
  `events-ms`, porque determina si el endpoint de borrado de cuenta debe poder devolver un error
  de precondición (`409` "tienes eventos activos, cancela o transfiere primero") o si el borrado
  cancela automáticamente esos eventos como side-effect.
- **No hay artefactos de diseño Pencil ni HTML mockups relacionados** con eliminación de cuenta —
  la fase de UI parte de cero visualmente (aunque el patrón de interacción/copy ya está acotado por
  `_logout` y por `delete-account.html`), así que si hay pantallas nuevas más allá del ítem en
  `ProfileActionsList` + `ConfirmationDialog` (p. ej. una pantalla dedicada con detalle de qué se
  borra), deben pasar por Pencil según la regla del proyecto.
- **Retención de logs técnicos de 30 días**: no se encontró implementación — el plan debe marcarlo
  explícitamente como fuera de alcance/deuda documentada, o como ítem nuevo si el equipo decide
  implementarlo aquí, para no dejar una promesa de copy sin respaldo técnico.
- El **estado "borrado en progreso" tras cierre de app** (pregunta abierta #8) es un caso nuevo de
  UX para Rideglory (no hay precedente de operación larga con persistencia de estado); la fase de
  Flutter debe diseñar explícitamente qué pasa si el usuario reabre con sesión aún válida pero
  cuenta parcialmente borrada en backend (probable: token ya inválido tras el hard-delete de
  Firebase Auth, forzando logout natural vía el interceptor existente).
