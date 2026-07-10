# Fase 3 — Eliminación de cuenta — historial de eventos y organizadores activos

_Generado: 2026-07-07T16:02:33Z_ · _Corregido: 2026-07-07T16:11:04Z_

## Objetivo

Como rider que elimina su cuenta, mi historial de participación en eventos (`EventRegistration`)
queda anonimizado preservando evidencia legal de que acepté los consentimientos de riesgo y de
salud en su momento (timestamp + versión, sin mi nombre asociado). Como organizador con eventos
activos, la app me bloquea con un mensaje accionable **antes** de que invierta esfuerzo
completando la pantalla de confirmación de fase 1, no después de confirmar.

Esta fase **extiende** el mismo endpoint `DELETE /users/me` y la misma pantalla de confirmación
entregados en fase 1 (no crea rutas ni pantallas paralelas) y se apoya en el bulk-delete de
vehículos/documentos de fase 2 ya integrado en la orquestación.

## Alcance (entra / no entra)

**Entra:**
- Nuevo `MessagePattern` `anonymizeRegistrationsByUserId` en `events-ms`, invocado como paso nuevo
  de la orquestación de `DELETE /users/me` (después de fase 2, antes de `hardDeleteUser`).
- Especificación campo por campo de qué se anonimiza vs. qué se preserva en `EventRegistration`
  (ver sección de datos).
- Definición formal de "evento activo" (`state IN (DRAFT, SCHEDULED, IN_PROGRESS)`) y contrato
  `409 ACTIVE_EVENTS_AS_ORGANIZER` en `DELETE /users/me`.
- Precondición ejecutada en el **primer tap** del ítem "Eliminar cuenta" en Flutter, reusando el
  `MessagePattern` `findEventsByOwnerId` que **ya existe** (no se crea un endpoint nuevo solo para
  esto) — ver justificación en "Qué se debe hacer".
- Estado dedicado de bloqueo en la UI (no un `ConfirmationDialog` de error genérico) con CTA a
  gestión de eventos (`AppRoutes.myEvents`).
- Verificación explícita de si las vistas de terceros (lista de asistentes, detalle de registro)
  necesitan manejo especial tras la anonimización, y ajuste de esas vistas si aplica.

**No entra (explícitamente recortado por el Architect):**
- Transferir la propiedad (`ownerId`) de un evento a otro usuario como alternativa a cancelar — no
  hay soporte de datos hoy (`Event.ownerId` no es reasignable); si se decide invertir en esto, es
  una sub-historia futura con su propio endpoint.
- Cancelación automática de eventos activos como side-effect del borrado de cuenta — el usuario
  debe cancelarlos/gestionarlos él mismo antes de reintentar.
- Retención/expiración a 3 años de los registros anonimizados (mencionada en el intake) — fuera de
  alcance de esta fase, no hay mecanismo de TTL en el repo.
- Migrar `EventRegistration.bloodType` a nulo — el enum permanece en la fila anonimizada (ver
  justificación abajo); no se toca el enfoque de enmascarado por privacidad ya existente
  (`FULL_MASK '••••'` en `registrations.service.ts`), que sigue aplicando en runtime para vistas de
  terceros con `shareMedicalInfo=false` independientemente de esta fase.

## Que se debe hacer (pasos concretos y ordenados)

1. **Confirmar el estado real de la orquestación de fase 1/2** en
   `api-gateway/src/users/users.controller.ts` (y su servicio orquestador) antes de tocarla: leer
   el handler `DELETE me` ya implementado por esas fases para insertar el paso nuevo en el punto
   correcto de la cadena (después del paso de vehículos/documentos de fase 2, antes de
   `hardDeleteUser`). No asumir el nombre exacto del archivo/método si fase 1 lo llamó distinto a
   lo documentado aquí — verificar en código antes de editar.

2. **Backend — `events-ms`: nuevo `MessagePattern anonymizeRegistrationsByUserId`.**
   - `events-ms/src/registrations/registrations.controller.ts`: agregar
     `@MessagePattern('anonymizeRegistrationsByUserId') anonymize(@Payload('userId') userId: string)`
     que delega a `registrationsService.anonymizeByUserId(userId)`.
   - `events-ms/src/registrations/registrations.service.ts`: nuevo método
     `anonymizeByUserId(userId: string)` que ejecuta un único
     `this.eventRegistration.updateMany({ where: { userId }, data: { ... } })`. **Nota de
     idempotencia (corregida):** el `where` filtra por `userId`, campo que **se preserva** (no se
     anonimiza — ver tabla más abajo), así que una segunda llamada con el mismo `userId` vuelve a
     matchear exactamente las mismas `N` filas y las reescribe con los mismos valores; **no**
     devuelve `count: 0` en el reintento. Lo que se garantiza (y lo que debe probarse) es
     **idempotencia de efecto**: la segunda llamada no lanza error y el estado resultante de las
     filas es idéntico al de la primera llamada (mismos valores, mismo `count: N`) — es decir, es
     seguro reintentar, coordinado con fase 4, aunque el contador no baje a cero. Si en el futuro se
     quisiera además que el reintento reporte `count: 0` (para distinguir "ya estaba anonimizado" de
     "se anonimizó ahora"), habría que añadir un guard adicional al `where` (p. ej.
     `where: { userId, fullName: { not: ANONYMIZED_FULL_NAME } }`) — **no entra en el alcance de
     esta fase**; se deja como nota para no mezclar ambas semánticas en el mismo criterio.
   - Campo por campo (ver tabla en "Cambios de datos" más abajo) — **no** un `SET fullName = NULL`
     genérico.
   - Reusar la constante de estilo existente en el mismo archivo (`FULL_MASK = '••••'`) como
     precedente de nomenclatura, pero definir una constante nueva y semánticamente distinta para el
     valor de reemplazo de `fullName` (p. ej. `const ANONYMIZED_FULL_NAME = 'Usuario eliminado'`),
     porque `FULL_MASK` hoy comunica "dato oculto por privacidad, visible más tarde según
     configuración" y este caso es "dato borrado permanentemente" — semántica distinta, no
     reutilizar el mismo literal para no confundir los dos mecanismos en tests futuros.

3. **Backend — `rideglory-contracts`**: si el payload de `anonymizeRegistrationsByUserId` necesita
   tipado compartido, agregar `AnonymizeRegistrationsPayloadDto` en
   `rideglory-contracts/src/events/dto/` (junto a los demás DTOs de `registrations`); recordar
   `npm run build` en `rideglory-contracts` + reinstalar en `events-ms`/`api-gateway` tras el
   cambio (gotcha ya conocido del proyecto).

4. **Backend — `api-gateway`: contrato `DELETE /users/me` — precondición 409.**
   - En el handler orquestador (fase 1), **antes** de disparar cualquier paso destructivo, agregar
     una llamada de solo lectura a `eventsService.send('findEventsByOwnerId', { ownerId: userId })`
     (patrón ya existente — ver `EventsController.findByOwnerId` en `events-ms`, ya expone todos los
     eventos del organizador con su `state`).
   - Filtrar en `api-gateway` los eventos con
     `state IN (DRAFT, SCHEDULED, IN_PROGRESS)`. Si la lista no está vacía, abortar el resto de la
     orquestación (no se corre nada de fase 2/3) y responder
     `409 Conflict` con cuerpo
     `{ message, statusCode: 409, error: 'ACTIVE_EVENTS_AS_ORGANIZER', activeEvents: [{ id, name, state }] }`.
   - Registrar `EVENTS_SERVICE` como cliente TCP en `api-gateway/src/users/users.module.ts` si fase
     1/2 no lo hicieron ya (hoy ese módulo solo registra `USERS_SERVICE`; confirmar en código antes
     de duplicar el registro).
   - Insertar la llamada a `anonymizeRegistrationsByUserId` como paso 3 de la orquestación (después
     del paso de vehículos/documentos de fase 2, antes de `hardDeleteUser`), siguiendo el mismo
     patrón `firstValueFrom(...pipe(timeout(15_000), catchError(...RpcException BAD_GATEWAY)))` ya
     usado en `vehicles.controller.ts` (`hard-delete/:id`).

5. **Flutter — dominio: excepción tipada para el 409.**
   - `lib/core/exceptions/domain_exception.dart`: no se modifica.
   - Nuevo archivo `lib/features/authentication/domain/exceptions/active_events_as_organizer_exception.dart`
     (o en el feature dueño de `DeleteAccountUseCase` de fase 1 — verificar dónde vive ese use case
     antes de decidir la carpeta; seguir el mismo patrón de `lib/core/exceptions/ai_domain_exceptions.dart`,
     que extiende `DomainException` con campos adicionales) con
     `ActiveEventsAsOrganizerException extends DomainException` y un campo
     `final List<ActiveEventSummary> activeEvents` (modelo simple `{id, name, state}`).
   - Mapear el `409` con `error: 'ACTIVE_EVENTS_AS_ORGANIZER'` a esta excepción en el punto donde se
     parsean errores HTTP de este endpoint (revisar si fase 1 centralizó esto en
     `rest_client_functions.dart` o en un mapeo local del repositorio del feature; no duplicar el
     mapeo genérico de `DioException` ya existente ahí).

6. **Flutter — precondición en el primer tap (sin endpoint nuevo dedicado).**
   - En el `onTap` del ítem "Eliminar cuenta" agregado en `ProfileActionsList` por fase 1: antes de
     navegar a `DeleteAccountConfirmationPage`, invocar el `GetMyEventsUseCase` ya existente
     (`lib/features/events/domain/use_cases/get_my_events_use_case.dart`, ya usado por la pantalla
     "Mis eventos" en `AppRoutes.myEvents`) y filtrar localmente los eventos con
     `ownerId == currentUser.id` (siempre true, es "mis eventos") y
     `state IN {EventState.draft, EventState.scheduled, EventState.inProgress}`.
   - Justificación de reusar este use case en vez de crear un endpoint de "chequeo" dedicado: es la
     misma fuente de datos que ya alimenta la pantalla "Mis eventos", evita una llamada de red
     nueva, y el `409` de `DELETE /users/me` (paso 4) sigue siendo el guardián autoritativo del
     lado servidor para condiciones de carrera (p. ej. el usuario crea un evento en la ventana
     entre el chequeo local y la confirmación, o tiene dos dispositivos abiertos).
   - Si la lista filtrada NO está vacía: mostrar el estado de bloqueo (paso 8) y **no navegar** a la
     pantalla de confirmación de fase 1.
   - Si está vacía: navegar a `DeleteAccountConfirmationPage` como hoy (fase 1).
   - El flujo de confirmación de fase 1, al llamar `DeleteAccountUseCase` y recibir un `409`
     (condición de carrera), debe mostrar el mismo estado de bloqueo (paso 8) en vez de un error
     genérico — reusar el widget, no duplicar copy.

7. **Flutter — loading del chequeo del primer tap.** Mientras se resuelve `GetMyEventsUseCase`, el
   ítem "Eliminar cuenta" debe mostrar un estado de carga breve (spinner inline en el
   `ProfileMenuItem`, sin bloquear el resto de la pantalla) y prevenir doble-tap — mismo criterio de
   "sin doble-tap" que fase 1 fijó para el botón de confirmación final.

8. **Flutter — estado dedicado de bloqueo por organizador.**
   - Nuevo widget (un archivo, una clase, regla cero-tolerancia de widgets) p. ej.
     `lib/features/profile/presentation/widgets/active_events_block_sheet.dart` — un
     `AppModal`/bottom sheet (verificar el patrón de modales existente en
     `lib/shared/widgets/modals/`) con: título explicando que no puede borrar su cuenta mientras
     tenga eventos activos como organizador, la lista (o conteo) de esos eventos, y un
     `AppButton` con CTA que navega a `AppRoutes.myEvents` (`context.pushNamed`) para que el
     usuario los cancele o los gestione.
   - Todo el copy nuevo va en `lib/l10n/app_es.arb` con prefijo `profile_deleteAccount*` (o el
     prefijo que fase 1 haya fijado para la pantalla de confirmación — mantener consistencia,
     confirmar en código antes de elegir un prefijo nuevo).

9. **Flutter — vistas de terceros: verificación de placeholder "Usuario eliminado".**
   - Confirmado en código: `AttendeeProcessedItem`, `EventDetailParticipantsSection` y
     `RegistrationDetailPage` **solo leen `registration.fullName`** (y campos PII adicionales solo
     en `RegistrationDetailPage`, vista exclusiva del organizador sobre un registro aprobado) — no
     hay ningún componente Flutter que construya su propio texto "Usuario eliminado"; el placeholder
     lo produce el backend escribiendo el valor literal en `fullName` (paso 2). **Conclusión: no se
     requiere ningún cambio de UI para que el nombre se vea anonimizado** — se hereda gratis.
   - Sí requiere cambio de UI: `RegistrationDetailPage` (organizador viendo el detalle de un
     inscrito) renderiza `identificationNumber`, `phone`, `email`,
     `emergencyContactName`/`emergencyContactPhone` como `String` no-nulos hoy. Tras la
     anonimización (paso 2), estos campos llegan como `null` desde el backend. Por lo tanto:
     - `lib/features/event_registration/domain/model/event_registration_model.dart`: cambiar
       `identificationNumber`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`,
       `emergencyContactPhone` a `String?` y `birthDate` a `DateTime?` (ya son de por sí datos que
       hoy pueden llegar enmascarados con `'••••'` según `shareMedicalInfo`, así que el modelo ya
       convive con valores "no reales" en estos campos — pasar a nulable es una extensión natural,
       no una ruptura de un contrato estricto).
     - DTO correspondiente (`lib/features/event_registration/data/dto/*.dart` — localizar el DTO
       1:1 de `EventRegistrationModel`, Patrón B) refleja el mismo cambio de nulabilidad en
       `fromJson`.
     - **Decisión de copy (resuelta en esta corrección):** `context.l10n.notAvailable` (`"N/A"`) es
       genérico y hoy comunica "este dato no fue diligenciado" (p. ej. `vehicleSummary` ausente en
       `AttendeeProcessedItem`). El caso de esta fase es semánticamente distinto: el dato existió,
       fue capturado, y se borró **porque la cuenta fue eliminada** — no es lo mismo "dato ausente"
       que "usuario eliminado", y mezclar ambos bajo el mismo string genérico dificultaría a
       soporte/QA distinguir un bug de captura de un borrado intencional. Por lo tanto: **no
       reusar** `notAvailable`; crear una key dedicada `registration_deletedAccountFieldPlaceholder`
       (prefijo `registration_`, consistente con el resto de keys del feature
       `event_registration`) con texto `"Cuenta eliminada"` en `lib/l10n/app_es.arb`.
     - `lib/features/event_registration/presentation/registration_detail_page.dart`: cada
       `RegistrationDetailDataRow` que consume un campo `String?` (`identificationNumber`, `phone`,
       `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone`) usa
       `value ?? context.l10n.registration_deletedAccountFieldPlaceholder`. El campo `birthDate` es
       `DateTime?`, no `String?`, y hoy se renderiza vía un getter/formateador (`.formattedDate`) —
       por lo tanto su fallback es distinto:
       `birthDate?.formattedDate ?? context.l10n.registration_deletedAccountFieldPlaceholder`
       (encadenar el `?.` sobre el `DateTime?` **antes** de formatear, no formatear primero y
       comparar el string resultante), para que el archivo siga compilando tras el cambio de
       nulabilidad.
   - Confirmar con `dart analyze` que no queda ningún otro sitio del código que asuma no-nulidad de
     estos campos (los usos ya localizados arriba son los únicos hallados en el scan de este
     archivo; una búsqueda amplia adicional en la fase de implementación debe re-confirmar esto por
     si el scan quedó desactualizado).

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

**Backend (`rideglory-api`):**
- `events-ms/src/registrations/registrations.controller.ts` — agrega `@MessagePattern('anonymizeRegistrationsByUserId')`.
- `events-ms/src/registrations/registrations.service.ts` — nuevo método `anonymizeByUserId(userId)` con `updateMany` campo por campo + nueva constante `ANONYMIZED_FULL_NAME`.
- `events-ms/src/registrations/registrations.service.*.spec.ts` — nuevo spec para el método (crear si no hay uno cubriendo anonimización).
- `rideglory-contracts/src/events/dto/` — nuevo DTO de payload si se decide tipar (`AnonymizeRegistrationsPayloadDto`) + rebuild del paquete.
- `api-gateway/src/users/users.controller.ts` (o el archivo donde fase 1 puso el handler `DELETE me`) — agrega precondición 409 (`findEventsByOwnerId` + filtro de estados) y el paso 3 de orquestación (`anonymizeRegistrationsByUserId`).
- `api-gateway/src/users/users.module.ts` — registra `EVENTS_SERVICE` como cliente TCP si aún no está.

**Flutter (`Rideglory`):**
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — el `onTap` de "Eliminar cuenta" (agregado por fase 1) ahora primero corre la validación de organizador antes de navegar.
- `lib/features/profile/presentation/widgets/active_events_block_sheet.dart` — nuevo widget del estado de bloqueo con CTA a "Mis eventos".
- `lib/features/authentication/domain/exceptions/active_events_as_organizer_exception.dart` (ruta a confirmar según dónde fase 1 ubicó `DeleteAccountUseCase`) — nueva excepción tipada con `activeEvents`.
- El repositorio/mapeo de errores del `DeleteAccountUseCase` de fase 1 — agrega el mapeo del `409 ACTIVE_EVENTS_AS_ORGANIZER`.
- `lib/features/event_registration/domain/model/event_registration_model.dart` — nulabilidad de `identificationNumber`/`phone`/`email`/`residenceCity`/`eps`/`emergencyContactName`/`emergencyContactPhone`/`birthDate`.
- DTO 1:1 de `EventRegistrationModel` en `lib/features/event_registration/data/dto/` — mismo cambio de nulabilidad en el `fromJson`.
- `lib/features/event_registration/presentation/registration_detail_page.dart` — fallback `?? context.l10n.registration_deletedAccountFieldPlaceholder` en los campos ahora nulables.
- `lib/l10n/app_es.arb` + regenerar `app_localizations*.dart` — nuevas keys `profile_deleteAccountBlockedTitle`, `profile_deleteAccountBlockedMessage`, `profile_deleteAccountBlockedCta` (nombres exactos a alinear con el prefijo que fase 1 haya fijado) y `registration_deletedAccountFieldPlaceholder` (`"Cuenta eliminada"`, key dedicada — no se reusa `notAvailable`).

## Contratos / API rideglory-api

**`DELETE /users/me`** (extiende el contrato ya fijado en fase 1, no crea ruta nueva):
- **Nueva precondición (evaluada primero, antes de cualquier paso destructivo):** si
  `Event.ownerId = userId AND state IN (DRAFT, SCHEDULED, IN_PROGRESS)` tiene resultados →
  `409 Conflict`:
  ```json
  {
    "statusCode": 409,
    "error": "ACTIVE_EVENTS_AS_ORGANIZER",
    "message": "Tienes eventos activos como organizador. Cancélalos antes de eliminar tu cuenta.",
    "activeEvents": [{ "id": "uuid", "name": "string", "state": "DRAFT|SCHEDULED|IN_PROGRESS" }]
  }
  ```
- **Nuevo paso de orquestación (paso 3, después de fase 2, antes de `hardDeleteUser` de fase 1):**
  `eventsService.send('anonymizeRegistrationsByUserId', { userId })`.

**Nuevo `MessagePattern` interno:**
| MS | Pattern | Payload | Respuesta |
|----|---------|---------|-----------|
| `events-ms` | `anonymizeRegistrationsByUserId` | `{ userId: string }` | `{ count: number }` (filas afectadas, para logging/observabilidad, no expuesto al cliente) |

**Reuso (sin cambios de contrato):** `findEventsByOwnerId` (`events-ms`, ya existe) — usado tanto
por el chequeo local de Flutter (paso 6) como por la precondición del backend (paso 4); mismo
contrato, dos consumidores.

## Cambios de datos / migraciones

**Sí se requiere una migración de schema Prisma**, aditiva y de bajo riesgo: relajar a nullable
(`String` → `String?`, `DateTime` → `DateTime?`) las columnas `identificationNumber`, `birthDate`,
`phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` de
`EventRegistration` en `events-ms/prisma/schema.prisma`. Hoy esas columnas son no nulables, y
`anonymizeByUserId` necesita poder escribir `null` en ellas — sin esta migración, el `updateMany`
del paso 2 fallaría en runtime. El resto de campos tocados por la anonimización (`fullName`,
`shareMedicalInfo`, `allowOrganizerContact`) no cambian de nulabilidad, solo de valor. Ver detalle
y justificación de la migración más abajo.

Especificación campo por campo de `anonymizeByUserId(userId)`:

| Campo | Acción | Justificación |
|---|---|---|
| `fullName` | `'Usuario eliminado'` (constante `ANONYMIZED_FULL_NAME`) | Columna no nulable; placeholder legible en listas de asistentes/detalle. |
| `identificationNumber` | `null` | PII directa, columna ya `String` no nula hoy → **requiere** que el DTO/servicio la trate como opcional en la respuesta (Prisma permite `null` en `updateMany` solo si la columna es nullable; forma parte de la migración de nulabilidad descrita arriba y detallada abajo). |
| `birthDate` | `null` | Igual que arriba — requiere columna nullable. |
| `phone` | `null` | PII de contacto. |
| `email` | `null` | PII de contacto. |
| `residenceCity` | `null` | PII de contacto. |
| `eps` | `null` | Dato de salud. |
| `medicalInsurance` | `null` | Ya es nullable hoy — sin cambio de columna. |
| `bloodType` | **sin cambio** (se preserva el valor real) | Enum no nulable; no se migra a nullable en esta fase (fuera de alcance, ver sección Alcance). El enmascarado por privacidad en runtime (`FULL_MASK`) ya oculta este campo a terceros según `shareMedicalInfo`/estado del evento, independientemente de si la cuenta fue eliminada. |
| `bloodTypeRaw` (campo **solo del modelo Flutter** `EventRegistrationModel`, línea 64, ya `String?` hoy — no existe como columna en `events-ms/prisma/schema.prisma`; el DTO lo deriva en `fromJson` a partir del mismo valor crudo de `bloodType` cuando este no matchea el enum `BloodType`) | **sin cambio, explícito** | No forma parte del `updateMany` de `anonymizeByUserId` (no hay columna de backend que tocar); es un campo derivado en cliente del mismo dato que `bloodType`, ya cubierto por el enmascarado `FULL_MASK` en runtime y ya nullable en el modelo Flutter hoy — no hay ambigüedad de nulabilidad que resolver en el paso 9, a diferencia de los campos de contacto/documento de la fila de abajo. El implementador **no** debe anularlo ni tocarlo al hacer el cambio de nulabilidad de ese paso. |
| `emergencyContactName` | `null` | Contacto de un tercero, PII. |
| `emergencyContactPhone` | `null` | Contacto de un tercero, PII. |
| `shareMedicalInfo` | `false` | El titular ya no puede dar/revocar consentimiento; se cierra a "no compartir" por defecto. |
| `allowOrganizerContact` | `false` | Ídem — no tiene sentido permitir contacto a un usuario eliminado. |
| `riskAcceptedAt` | **sin cambio** | Evidencia legal de consentimiento — se preserva el timestamp. |
| `riskAcceptanceVersion` | **sin cambio** | Evidencia legal — versión del texto aceptado. |
| `medicalConsentAcceptedAt` | **sin cambio** | Evidencia legal — timestamp del consentimiento médico. |
| `medicalConsentVersion` | **sin cambio** | Evidencia legal — versión del texto aceptado. |
| `vehicleId` / `vehicleSummary` (derivado) | **sin cambio** en `EventRegistration.vehicleId`; el vehículo real ya fue borrado en fase 2, por lo que la resolución del summary debe degradar a "no disponible" (patrón ya existente en `AttendeeProcessedItem`) | No hay campo que anonimizar aquí; es un efecto colateral esperado de fase 2, no de esta fase. |

**Migración de Prisma requerida (ajuste a la tabla de arriba):** dado que `identificationNumber`,
`birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`,
`emergencyContactPhone` son hoy columnas no nulables en `events-ms/prisma/schema.prisma`, se
necesita **una migración que las marque como nullable** (agregar `?` en el schema +
`prisma migrate dev`) antes de poder escribir `null` en `anonymizeByUserId`. Es una migración
aditiva y de bajo riesgo (relajar una restricción `NOT NULL`, no añadir una nueva); dado que no hay
usuarios reales en producción hoy, no requiere backfill de filas existentes. Coordinar esta
migración con el equipo de backend/DBA antes de aplicarla, siguiendo el mismo criterio que la
migración de `Vehicle → Soat/Tecnomecanica` de fase 2.

**Flutter:** cambio de nulabilidad equivalente en `EventRegistrationModel` (dominio) y su DTO 1:1
(Pattern B), sin migración de almacenamiento local (no hay persistencia local de este modelo más
allá de caché en memoria — verificar `attendees_cache.dart` no dependa de no-nulidad).

## Criterios de aceptacion (numerados, observables, testeables)

1. Un rider sin eventos activos como organizador que hace tap en "Eliminar cuenta" navega
   directamente a `DeleteAccountConfirmationPage` (fase 1) sin demora perceptible ni pantalla de
   bloqueo.
2. Un organizador con al menos un evento en estado `DRAFT`, `SCHEDULED` o `IN_PROGRESS` que hace
   tap en "Eliminar cuenta" ve el estado de bloqueo dedicado **antes** de llegar a la pantalla de
   confirmación de fase 1 — nunca llega a ver el switch de "entiendo lo que se borra" ni el botón
   final de confirmar.
3. El estado de bloqueo muestra al menos el nombre de un evento bloqueante y un CTA que, al
   tocarlo, navega a `AppRoutes.myEvents`.
4. Un organizador cuyo único evento activo pasa a `CANCELLED` o `FINISHED` deja de ver el bloqueo
   en un tap posterior al ítem "Eliminar cuenta" (la precondición se re-evalúa en cada tap, no se
   cachea).
5. Llamar `DELETE /users/me` para un `userId` con eventos activos como organizador responde
   `409` con `error: "ACTIVE_EVENTS_AS_ORGANIZER"` y la lista `activeEvents` no vacía, **sin**
   ejecutar ningún paso de borrado de dominio (verificar en BD que ni vehículos, ni
   `EventRegistration`, ni el usuario en `users-ms` cambiaron).
6. Tras un `DELETE /users/me` exitoso (sin eventos activos), cada `EventRegistration` del usuario
   en `events-ms` (único MS donde vive esta entidad, según el scan) tiene:
   `fullName = 'Usuario eliminado'`, `identificationNumber`, `birthDate`, `phone`, `email`,
   `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` en `null`,
   `shareMedicalInfo = false`, `allowOrganizerContact = false` — verificado directamente en la base
   de datos de `events-ms`, no solo en la UI.
7. Tras el mismo borrado exitoso, `riskAcceptedAt`, `riskAcceptanceVersion`,
   `medicalConsentAcceptedAt`, `medicalConsentVersion` de cada `EventRegistration` afectada
   **no cambiaron** respecto a sus valores antes del borrado (evidencia legal preservada) —
   verificado en BD.
8. Llamar `anonymizeRegistrationsByUserId` dos veces seguidas para el mismo `userId` (simulando un
   reintento) no lanza error; el `count` devuelto en ambas llamadas es igual a `N` (el número de
   `EventRegistration` de ese usuario, ya que `userId` se preserva y por tanto el `where` vuelve a
   matchear las mismas filas), y el estado resultante de las filas tras la segunda llamada es
   **idéntico** al de la primera (mismos valores en cada campo anonimizado/preservado) —
   idempotencia de efecto, no de conteo. **No** se afirma `count: 0` en el reintento con el `where`
   actual (ver nota corregida en el paso 2).
9. En la lista de asistentes de un evento (`AttendeesList`/`AttendeesView`) donde uno de los
   inscritos eliminó su cuenta, el nombre mostrado es `Usuario eliminado`, sin excepción ni crash
   por campos nulos.
10. En `RegistrationDetailPage` (vista del organizador sobre un inscrito con cuenta eliminada), los
    campos de documento, fecha de nacimiento, teléfono, email, ciudad de residencia, EPS y contacto
    de emergencia muestran el texto dedicado `context.l10n.registration_deletedAccountFieldPlaceholder`
    (`"Cuenta eliminada"`, key nueva — **no** se reusa `context.l10n.notAvailable`/`"N/A"`, que
    queda reservado para el caso distinto de "dato no diligenciado", ver justificación en el paso 9)
    en vez de un string vacío, `null` renderizado literalmente, o un crash — incluyendo
    específicamente `birthDate` vía
    `birthDate?.formattedDate ?? context.l10n.registration_deletedAccountFieldPlaceholder` (paso 9),
    no solo los campos `String?`.
11. `dart analyze` no reporta errores tras el cambio de nulabilidad de
    `EventRegistrationModel`/DTO.
12. La validación de organizador en el primer tap no realiza ninguna llamada de red nueva más allá
    de la que ya usa la pantalla "Mis eventos" (verificable inspeccionando las llamadas HTTP
    disparadas al tocar el ítem "Eliminar cuenta").

## Pruebas (unitarias/widget/integracion)

**Backend (`rideglory-api`, Jest):**
- `events-ms/src/registrations/registrations.service.anonymize.spec.ts` (nuevo): casos de la tabla
  de campo por campo (anonimiza PII, preserva consentimiento, preserva `bloodType`, `shareMedicalInfo`/
  `allowOrganizerContact` a `false`), idempotencia (segunda llamada no falla), `userId` sin
  registros (0 filas afectadas, no error).
- `api-gateway/src/users/*.spec.ts` (extender el spec del handler `DELETE me` de fase 1): caso
  `409 ACTIVE_EVENTS_AS_ORGANIZER` con eventos en cada uno de los 3 estados activos; caso sin
  eventos activos avanza a los pasos de fase 2/3; caso con eventos `CANCELLED`/`FINISHED` no
  bloquea (confirma que el filtro de estados es correcto, no "cualquier evento del owner").

**Flutter (`flutter test`):**
- Widget test de `ProfileActionsList`: tap en "Eliminar cuenta" con `GetMyEventsUseCase` mockeado
  devolviendo eventos activos → verifica que se muestra `ActiveEventsBlockSheet` y **no** se navega
  a `DeleteAccountConfirmationPage`; con lista vacía o solo eventos terminales → navega a la
  confirmación.
- Widget test de `ActiveEventsBlockSheet`: tap en el CTA navega a `AppRoutes.myEvents`.
- Test del cubit/repositorio que mapea el `409` a `ActiveEventsAsOrganizerException` con la lista
  de `activeEvents` correctamente parseada.
- Widget test de `RegistrationDetailPage` con un `EventRegistrationModel` con los campos nulos
  (simulando un registro anonimizado): verifica fallback a
  `registration_deletedAccountFieldPlaceholder` (`"Cuenta eliminada"`, no `notAvailable`/`"N/A"`)
  en cada campo, sin excepción de tipo ni renderizado de la palabra `"null"`.
- Widget test de `AttendeeProcessedItem`/`AttendeesList` con `fullName = 'Usuario eliminado'`:
  renderiza sin error, iniciales calculadas a partir del placeholder (`Initials.buildFromFullName`)
  sin excepción.
- Test del DTO de `EventRegistrationModel` (`fromJson`) con los campos nuevos en `null` en el JSON
  de origen — deserializa sin lanzar.

**No automatizable / manual (dejar explícito en QA_CHECKLIST al cerrar la fase):**
- Verificación visual en BD real (Postgres de `events-ms`) tras un borrado end-to-end con el
  usuario de prueba `qa2@gmail.com` (owner de "Mi Evento", ver `project_qa_test_users`), incluyendo
  confirmar que campos de consentimiento no cambiaron.
- Reproducción de la condición de carrera (crear un evento entre el chequeo local y la confirmación
  final) para validar que el `409` del backend actúa como respaldo cuando la validación local del
  cliente quedó desactualizada.

## Riesgos y mitigaciones

1. **Migración de nulabilidad en `EventRegistration` toca columnas con datos reales de prueba
   (`qa1`/`qa2`) y con los ~10 usuarios reales existentes en producción.** *Mitigación*: es aditiva
   (relaja `NOT NULL`, no la impone), no requiere backfill; correr y verificar localmente antes de
   cualquier despliegue, siguiendo el flujo ya establecido del proyecto (migraciones locales
   primero, verificación humana antes de desplegar), y confirmar explícitamente contra una copia/
   snapshot de los datos reales que la migración no rompe filas existentes antes de aplicar en prod.
2. **Cambiar la nulabilidad de `EventRegistrationModel` puede romper código que asuma no-nulidad en
   un lugar no detectado en este scan** (p. ej. exportes a PDF/reportes si existieran). *Mitigación*:
   `dart analyze` tras el cambio detecta la mayoría de los sitios que dejan de compilar por tipo;
   además correr `grep` amplio de usos de estos campos antes de tocar el modelo.
3. **Confundir el enmascarado por privacidad (`FULL_MASK '••••'`, reversible/condicional en runtime)
   con la anonimización permanente de esta fase (irreversible).** *Mitigación*: usar una constante
   nueva y distinta (`ANONYMIZED_FULL_NAME`) y no tocar la lógica de `FULL_MASK` existente; test
   explícito que verifica que ambos mecanismos coexisten sin interferirse (un registro anonimizado
   con `shareMedicalInfo=false` sigue mostrando `••••` en campos médicos vía el masking existente,
   no depende de esta fase).
4. **La validación local del primer tap (reuso de `GetMyEventsUseCase`) queda desactualizada si el
   usuario crea/edita un evento en otro dispositivo entre el chequeo y la confirmación.**
   *Mitigación*: el `409` del backend (paso 4) es el guardián autoritativo; la validación local es
   solo una optimización de UX para no hacer confirmar dos veces al caso común, no la única
   defensa — criterio de aceptación #5 verifica explícitamente que el backend bloquea incluso si el
   cliente no lo detectó.
5. **Registrar `EVENTS_SERVICE` en `UsersModule` puede chocar si fase 1/2 ya lo hicieron de otra
   forma (p. ej. un módulo compartido de clientes en vez de registrarlo por módulo).**
   *Mitigación*: verificar el estado real de `users.module.ts` tras completar fases 1/2 antes de
   escribir este registro; no duplicar `ClientsModule.registerAsync` para el mismo servicio.
6. **Olvidar excluir al `ownerId` del propio evento al anonimizar** (un organizador inscrito
   automáticamente en su propio evento, patrón ya visto en `AttendeesList._isPending`/`visible`)
   podría anonimizar una fila que en realidad pertenece a un evento que sigue existiendo con datos
   inconsistentes. *Mitigación*: el filtro es por `userId` en `EventRegistration`, no por
   `Event.ownerId` — no aplica aquí (el borrado de cuenta ya bloquea si el usuario es organizador
   de un evento activo antes de llegar a este paso; si llegó aquí es porque no tiene eventos
   activos como organizador, así que cualquier `EventRegistration` propia que se anonimice es
   segura de tocar).

## Dependencias (fases prerequisito y por que)

- **Fase 1** — entrega el endpoint `DELETE /users/me`, la orquestación base de 5 pasos (con
  Firebase Auth siempre al final), la pantalla `DeleteAccountConfirmationPage`, el ítem "Eliminar
  cuenta" en `ProfileActionsList`, y el `DeleteAccountUseCase`/repositorio que esta fase extiende
  con el manejo del `409`. Sin fase 1, no hay endpoint ni pantalla que interceptar en el primer tap.
- **Fase 2** — fija el paso de borrado de dominio (vehículos, documentos, mantenimientos) que debe
  ejecutarse **antes** del paso de anonimización de esta fase en la orquestación síncrona (mismo
  orden ya fijado por el Architect: dominio → eventos → PII de usuario → Firebase Auth). Sin fase
  2, el paso 3 de esta fase quedaría en el orden equivocado de la cadena.

## Ejecucion recomendada (nivel rg-exec: full)

Por que ese nivel: cambio de contrato de API (409 nuevo) con impacto de negocio y auditoría legal
(distinguir PII de consentimiento), más una precondición nueva que afecta la UX de terceros — no
es un cambio mecánico ni de un área única, y errores aquí tienen consecuencias legales/de
confianza. Toca 3 capas de dos repos distintos (`events-ms` con migración de schema, `api-gateway`
con contrato nuevo, Flutter con cambio de nulabilidad de un modelo de dominio usado en múltiples
pantallas), requiere una decisión explícita de qué campo se anonimiza vs. se preserva que no puede
delegarse a un patrón mecánico existente, y el Architect ya clasificó esta fase como complejidad
alta en `03-architect-review.md`.
