# Architect — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T19:31:56Z_

## Decisiones

1. **Orquestación backend**: el paso 3 (anonimización de eventos) se inserta en
   `AccountDeletionService.deleteAccount` **entre** el paso 2 (hard-delete vehículos, ya
   existente) y el hard-delete de `users-ms` (ya existente como paso 3 actual → pasa a ser
   paso 4). La precondición de organizador activo (409) se valida **antes** de llamar a
   `usersService.send('findUserByEmail', …)` — en cuanto se resuelve `user.id`, primero se
   consulta `findEventsByOwnerId` en `events-ms` vía `EVENTS_SERVICE` y si hay eventos
   `DRAFT|SCHEDULED|IN_PROGRESS` se lanza `RpcException` con `status: 409` **antes** de tocar
   vehículos/mantenimientos/usuario — cumple AC5 ("sin ejecutar ningún paso de borrado").
2. **`EVENTS_SERVICE` no está registrado en `users.module.ts`** (verificado en código — el
   `ClientsModule.registerAsync` actual solo tiene `USERS_SERVICE`, `VEHICLES_SERVICE`,
   `MAINTENANCES_SERVICE`). Hay que añadirlo con el mismo patrón que `events.module.ts`
   (`envs.eventsMsPort`/`envs.eventsMsHost`, ya existen en `config/envs.ts` — no hay delta de
   `.env`). Sin duplicar registro — no existe otro lugar en `UsersModule` que lo registre.
3. **Contrato 409**: el gateway responde `HttpStatus.CONFLICT` con body
   `{ error: 'ACTIVE_EVENTS_AS_ORGANIZER', message: '<texto humano ES>', activeEvents: [{id, name, state}] }`.
   El campo `message` (no solo `error`) es deliberado: el mapeo de errores HTTP existente en
   Flutter (`rest_client_functions.dart` → `_extractResponseMessage`) ya prioriza
   `responseData['message']` sobre `responseData['error']`; así el `DeleteAccountErrorBanner`
   genérico (ya existente de fase 1) muestra un mensaje legible en el caso residual de carrera
   sin necesitar una excepción tipada nueva ni un archivo
   `active_events_as_organizer_exception.dart`. **Decisión: NO crear ese archivo** — el PRD lo
   marcaba "ruta a confirmar"; se confirma que no aplica porque el bloqueo real ocurre
   client-side antes de llegar a esta pantalla (AC2), y el 409 es solo la red de seguridad de
   condición de carrera (AC5), ya cubierta por el manejo de error genérico existente.
4. **Precondición client-side (AC1/AC2/AC3/AC4/AC12)**: `ProfileActionsList` no es un Cubit —
   es un `StatelessWidget`. Se resuelve `GetMyEventsUseCase` vía `getIt<GetMyEventsUseCase>()`
   (patrón ya usado en otros widgets stateless: `vehicle_rtm_form_slot.dart`,
   `attendees_page.dart`, etc. — no es el anti-patrón de Cubit-singleton, es un caso de uso sin
   estado). En el `onTap` de "Eliminar cuenta": `await getIt<GetMyEventsUseCase>()()`, filtrar
   eventos con `state == EventState.draft || scheduled || inProgress`, y:
   - Lista vacía → `context.pushNamed(AppRoutes.deleteAccount)` (comportamiento actual, sin
     cambios — AC1).
   - Lista no vacía → mostrar `ActiveEventsBlockSheet` (bottom sheet nuevo) con al menos el
     nombre del primer evento bloqueante y CTA a `AppRoutes.myEvents` (AC3), sin navegar a
     `DeleteAccountConfirmationPage` (AC2).
   - Error de red al listar eventos → fallback conservador: no bloquear silenciosamente ni
     navegar como si no hubiera eventos; usar el mismo mecanismo que `EventsPage` para mostrar
     el estado de error, pero como esto es un `onTap` sin builder, la implementación mínima es
     un `SnackBar` genérico y no navegar (evita bypass de la validación EN CASO de error, sin
     inventar un estado nuevo). Frontend agent decide el copy exacto (l10n) al implementar; no
     hay AC que lo especifique, así que se documenta como decisión de bajo riesgo, no como
     bloqueador.
   - No se llama a `deleteMyAccount()`/`DeleteAccountUseCase` en este flujo — solo
     `GetMyEventsUseCase`, que es exactamente la llamada que ya dispara `EventsPage(showMyEvents:
     true)` — cumple AC12 (ninguna llamada de red nueva).
5. **Reutilización de `GetMyEventsUseCase`**: confirmado en código que mapea a
   `findEventsByOwnerId` en el gateway (`event_repository_impl.dart` → `_eventService.getMyEvents()`
   → Retrofit → gateway `events.controller.ts:57` → `'findEventsByOwnerId'`), exactamente el
   mismo endpoint que el backend usará server-side para el 409 — mismo criterio de "evento
   activo" en ambos lados (fuente única de verdad: enum `EventState` de Prisma vs. el enum
   Dart `EventState` en `event_model.dart`, ya idénticos en nombres).
6. **`EventRegistrationModel` — Pattern B intacto**: `EventRegistrationDto extends
   EventRegistrationModel` se mantiene. Cambiar `identificationNumber`, `birthDate`, `phone`,
   `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` de
   requeridos a nulables en el modelo Y en el DTO simultáneamente (mismo commit lógico) —
   `bloodType`/`bloodTypeRaw` NO se tocan (ya son nulables, guardrail explícito de no tocar
   `bloodTypeRaw`). `fullName` **NO** se vuelve nulable — el backend siempre escribe
   `'Usuario eliminado'`, nunca `null` (confirmado: AC6 especifica `fullName = 'Usuario
   eliminado'`, no `null`).
7. **`birthDate` nulable + serialización**: al pasar de requerido a `DateTime?`, el DTO ya no
   necesita el override manual `apiEncodeRequiredDateTime(birthDate)` en `toJson()` — el
   `NullableApiDateTimeConverter` de `apiJsonDateTimeConverters` (ya declarado en el
   `@JsonSerializable` de la clase) cubre `DateTime?` automáticamente según el comentario en
   `lib/core/http/api_date_time.dart`. Eliminar esa línea especial evita doble-encoding.
8. **`registration_contact_trigger.dart` requiere ajuste no listado explícitamente en el §4
   original del PRD** — corrección de área afectada: `registration.phone` (línea 75) pasa de
   `String` a `String?`; `UrlLauncherHelper.openPhone(String phone)` exige no-nulo. Aunque el
   guardrail confirma que este widget ya está oculto cuando `allowOrganizerContact == false`
   (que la anonimización siempre fuerza a `false`), el cambio de tipo igual rompe la
   compilación si no se añade un guard `if (phone == null) return;` antes de usarlo — cambio
   defensivo de bajo riesgo, no de comportamiento visible (código muerto en la práctica, pero
   necesario para `dart analyze`/compilación, AC11).
9. **Ningún otro call site de estos 8 campos** fue encontrado en `lib/` o `test/` fuera de
   `registration_detail_page.dart`, `registration_contact_trigger.dart` y el propio
   modelo/DTO/`registration_form_cubit.dart` (búsqueda amplia con grep confirmada). En
   `registration_form_cubit.dart`: `_preloadFromExistingRegistration` asigna estos campos a un
   `patchValue` (`Map<String, dynamic>`, acepta `null` sin error de tipo) y el builder que
   construye un `EventRegistrationModel` nuevo desde el formulario los castea `as String`/`as
   DateTime` (no nulables) — son valores que vienen de un formulario validado (siempre
   completos), compatibles con los parámetros ahora nulables sin cambios (asignar no-nulo a
   nulable es válido). `_buildRiderProfile` ya recibe campos hacia un `RiderProfileModel` que ya
   son todos nulables — sin cambios.
10. **`RegistrationDetailPage`**: cada uno de los 7 campos + `birthDate` usa
    `?? context.l10n.registration_deletedAccountFieldPlaceholder` en el sitio de renderizado
    (AC10), incluyendo `birthDate?.formattedDate ?? …` explícito por el PRD.

## Change map

| file | action | reason | risk |
|---|---|---|---|
| `rideglory-api/rideglory-contracts/src/events/dto/anonymize-registrations-payload.dto.ts` | create | Payload `{ userId: string }` con `@IsUUID()` para `anonymizeRegistrationsByUserId` | low |
| `rideglory-api/rideglory-contracts/src/events/dto/index.ts` | modify | Exportar el nuevo DTO | low |
| `rideglory-api/events-ms/src/registrations/registrations.controller.ts` | modify | Nuevo `@MessagePattern('anonymizeRegistrationsByUserId')` | low |
| `rideglory-api/events-ms/src/registrations/registrations.service.ts` | modify | Nuevo método `anonymizeByUserId(userId)`: `updateMany({ where: { userId }, data: {...} })` + constante `ANONYMIZED_FULL_NAME`; no tocar `FULL_MASK` ni lógica de `maskRegistration` | med |
| `rideglory-api/events-ms/src/registrations/registrations.service.anonymization.spec.ts` | create | Spec: campos anonimizados, evidencia legal preservada, idempotencia (2 llamadas seguidas mismo `count`/estado), no toca `ownerId` de eventos | low |
| `rideglory-api/events-ms/prisma/schema.prisma` | modify | Relajar a nullable: `identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` en `EventRegistration`. NO tocar `bloodType`. Migración aditiva. | high |
| `rideglory-api/events-ms/prisma/migrations/<timestamp>_registration_nullable_pii/migration.sql` | create | Migración generada por Prisma (`prisma migrate dev`) — correr y verificar localmente, NO desplegar desde este agente | high |
| `rideglory-api/api-gateway/src/users/account-deletion.service.ts` | modify | Precondición 409 `ACTIVE_EVENTS_AS_ORGANIZER` (antes de paso 2) + nuevo paso "anonimizar eventos" entre hard-delete vehículos y hard-delete usuario; inyectar `EVENTS_SERVICE` | high |
| `rideglory-api/api-gateway/src/users/users.module.ts` | modify | Registrar `EVENTS_SERVICE` en `ClientsModule.registerAsync` (mismo patrón que `events.module.ts`, usa `envs.eventsMsPort/Host` ya existentes) | med |
| `rideglory-api/api-gateway/src/users/account-deletion.service.spec.ts` (o equivalente si no existe, crear) | modify/create | Cubrir: 409 sin efectos secundarios, orden de orquestación, propagación de `activeEvents` | med |
| `Rideglory/lib/features/profile/presentation/widgets/profile_actions_list.dart` | modify | `onTap` de "Eliminar cuenta" pasa a async: `getIt<GetMyEventsUseCase>()`, filtra activos, bifurca a bottom sheet o navegación | med |
| `Rideglory/lib/features/profile/presentation/widgets/active_events_block_sheet.dart` | create | Nuevo bottom sheet (un widget por archivo) — nombre de evento bloqueante + CTA a `AppRoutes.myEvents` | med |
| `Rideglory/lib/features/event_registration/domain/model/event_registration_model.dart` | modify | 8 campos PII de requeridos a nulables (`identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone`); actualizar constructor, `copyWith` sin cambios de firma (siguen `?`, ya opcionales por posición nombrada) | high |
| `Rideglory/lib/features/event_registration/data/dto/event_registration_dto.dart` | modify | Mismos 8 campos nulables en `EventRegistrationDto`/`fromJson`/extensión `toJson()`; quitar el override manual de `apiEncodeRequiredDateTime(birthDate)` en `toJson()` (ya cubierto por converter nulable) | high |
| `Rideglory/lib/features/event_registration/data/dto/event_registration_dto.g.dart` | modify | Regenerado por `build_runner build --delete-conflicting-outputs` tras el cambio de nulabilidad — no editar a mano | low |
| `Rideglory/lib/features/event_registration/presentation/registration_detail_page.dart` | modify | Fallback `?? context.l10n.registration_deletedAccountFieldPlaceholder` en los 7 campos de texto + `birthDate?.formattedDate ?? …` | med |
| `Rideglory/lib/features/event_registration/presentation/widgets/registration_contact_trigger.dart` | modify | Guard `if (phone == null) return;` antes de `UrlLauncherHelper.openPhone/openWhatsApp` (requerido por el cambio de tipo, ruta ya inalcanzable en la práctica) | low |
| `Rideglory/lib/l10n/app_es.arb` | modify | Nuevas keys: `registration_deletedAccountFieldPlaceholder`, `profile_deleteAccountBlocked_title`, `profile_deleteAccountBlocked_body`, `profile_deleteAccountBlocked_cta` (nombres exactos a definir por Frontend siguiendo el prefijo por feature) | low |
| `Rideglory/lib/l10n/app_localizations.dart` / `app_localizations_es.dart` | modify | Regenerado por `flutter gen-l10n` / `build_runner` tras editar el `.arb` — no editar a mano | low |
| `Rideglory/test/features/event_registration/**` | modify | Ajustar fixtures/tests existentes que construyen `EventRegistrationModel`/`EventRegistrationDto` con los 8 campos ahora nulables (siguen compilando si pasan `String`/`DateTime` no-nulos; solo revisar si algún test asume no-nulidad explícita del tipo) | med |
| `Rideglory/test/features/profile/**` | create/modify | Tests del nuevo flujo de precondición en `ProfileActionsList` y `ActiveEventsBlockSheet` | med |

## Contratos

- **Nuevo `MessagePattern('anonymizeRegistrationsByUserId')`** en `events-ms`:
  - Payload: `AnonymizeRegistrationsPayloadDto { userId: string }` (UUID).
  - Respuesta: `{ count: number }` (número de filas de `EventRegistration` afectadas).
  - Implementación: `prisma.eventRegistration.updateMany({ where: { userId }, data: { fullName: ANONYMIZED_FULL_NAME, identificationNumber: null, birthDate: null, phone: null, email: null, residenceCity: null, eps: null, emergencyContactName: null, emergencyContactPhone: null, shareMedicalInfo: false, allowOrganizerContact: false } })`. NO tocar `bloodType`, `medicalInsurance`, `riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion`, `vehicleId`, `status`, `eventId`.
  - Constante `ANONYMIZED_FULL_NAME = 'Usuario eliminado'` (nombre distinto y explícito de `FULL_MASK` — no reusar `'••••'`).
- **`DELETE /users/me` (api-gateway) — contrato extendido**:
  - Nuevo caso `409 Conflict` con body `{ error: 'ACTIVE_EVENTS_AS_ORGANIZER', message: '<texto ES accionable>', activeEvents: [{ id, name, state }] }` — se evalúa **antes** de cualquier paso de borrado de dominio.
  - Camino exitoso sin cambios de firma (sigue `204`/`void`), pero la orquestación interna gana un paso: eventos (nuevo) entre vehículos (fase 2) y usuario (fase 1).
- **Orden de orquestación final en `AccountDeletionService.deleteAccount`**:
  1. Resolver `user.id` desde email.
  2. **Precondición 409**: `findEventsByOwnerId` en `EVENTS_SERVICE`, si hay `DRAFT|SCHEDULED|IN_PROGRESS` → lanzar 409 y salir (ningún paso posterior se ejecuta).
  3. Hard-delete vehículos (`hardDeleteAllByOwner`, ya existente).
  4. Limpieza de imágenes en Storage (best-effort, ya existente).
  5. Soft-delete mantenimientos (ya existente).
  6. **Nuevo**: `anonymizeRegistrationsByUserId` en `EVENTS_SERVICE`.
  7. Hard-delete usuario en `users-ms` (ya existente).
  8. Eliminar usuario en Firebase Auth (ya existente, siempre último).

## Datos/migraciones

- Ver `docs/exec-runs/eliminacion-cuenta-phase-03/analysis/MIGRATION_PLAN.md` (a escribir por
  Backend) — resumen aquí: migración Prisma **aditiva** (`ALTER COLUMN ... DROP NOT NULL`) sobre
  8 columnas de `EventRegistration`. No afecta `bloodType` (se mantiene `NOT NULL`, tipo enum). No
  requiere backfill — las filas existentes ya tienen valores no-nulos; el `DROP NOT NULL` no
  rompe filas existentes. Ejecutar con `prisma migrate dev` localmente contra la BD de
  `events-ms`, verificar que las filas existentes no cambian, **no desplegar** sin verificación
  humana (guardrail global de deploy).

## Env

- Sin delta de `.env`. `EVENTS_MS_PORT`/`EVENTS_MS_HOST` ya existen en `api-gateway/src/config/envs.ts`
  y se usan en `events.module.ts` — el nuevo `ClientsModule.registerAsync` en `users.module.ts`
  reutiliza los mismos valores. No se escribe `analysis/ENV_DELTA.md` (no aplica).

## Riesgos

- **Alto**: la migración Prisma toca 8 columnas de una tabla con datos de producción reales
  (usuarios reales desde 2026-07-10, ver memoria `project_no_real_users` OBSOLETO). Aunque es
  aditiva (relaja `NOT NULL`), correr y verificar localmente antes de cualquier despliegue es
  obligatorio.
- **Alto**: el orden de orquestación en `account-deletion.service.ts` es crítico — si la
  precondición 409 se evalúa después de cualquier paso de borrado, se viola AC5
  irreversiblemente (no hay rollback). El Backend debe implementar la validación como el
  **primer** paso tras resolver `user.id`, antes de `hardDeleteAllByOwner`.
- **Medio**: `EventRegistrationModel`/DTO cambian nulabilidad de 8 campos — riesgo de
  regresión silenciosa en tests que construyen fixtures asumiendo no-nulidad implícita del tipo
  (compilan igual, pero un test que hacía `registration.phone.someStringMethod()` sin `!`/`?.`
  ahora sí puede fallar en tiempo de compilación si el campo se propaga a otra variable tipada
  `String`). Correr `dart analyze` + búsqueda amplia adicional (guardrail ya en el PRD).
- **Medio**: `ProfileActionsList.onTap` ahora hace una llamada de red antes de navegar — riesgo
  de latencia percibida si `events-ms` está lento. No hay AC que exija un loading indicator,
  pero es una consideración de UX que Frontend debe resolver sin bloquear indefinidamente (usar
  el mismo timeout/manejo de error que `executeService` ya aplica).
- **Bajo**: `registration_contact_trigger.dart` — el guard de `phone == null` es código
  defensivo sobre una ruta ya inalcanzable en producción (protegida por
  `allowOrganizerContact == false`), pero si un futuro cambio relaja esa condición sin querer,
  el guard previene un crash real en vez de solo un error de compilación.

## Orden

1. **Backend — contratos**: `rideglory-contracts` (`AnonymizeRegistrationsPayloadDto`) → `npm run
   build` → reinstalar en `events-ms`/`api-gateway` (gotcha conocido).
2. **Backend — `events-ms`**: migración Prisma (nullable) → `anonymizeByUserId` en
   `registrations.service.ts` → `@MessagePattern` en `registrations.controller.ts` → specs.
3. **Backend — `api-gateway`**: registrar `EVENTS_SERVICE` en `users.module.ts` → precondición
   409 + paso de anonimización en `account-deletion.service.ts` → specs.
4. **Frontend — dominio/datos**: `EventRegistrationModel` → `EventRegistrationDto` →
   `build_runner build --delete-conflicting-outputs` → `dart analyze`.
5. **Frontend — presentación**: `registration_detail_page.dart` + `registration_contact_trigger.dart`
   (placeholders/guards) → `active_events_block_sheet.dart` (nuevo) → `profile_actions_list.dart`
   (precondición) → `app_es.arb` + regenerar l10n.
6. **QA**: specs backend (idempotencia, orquestación, 409 sin efectos) + tests Flutter
   (`dart analyze`, widget tests del bottom sheet, tests de `registration_detail_page` con
   campos nulos) + verificación manual en BD real (guardrail del proyecto).

## Superficie de regresión

- `DELETE /users/me` completo (fases 1+2+3): cualquier regresión en el orden de orquestación
  rompe borrados ya en producción para riders sin eventos activos.
- `RegistrationDetailPage`/`AttendeesList` para **todas** las inscripciones existentes (no solo
  las anonimizadas) — el cambio de nulabilidad del modelo/DTO afecta el tipo en cada sitio que
  lo consume, aunque el valor siga siendo no-nulo en el caso normal.
- `registration_form_cubit.dart` (creación/edición de inscripción activa) — mismos campos,
  pasan de requeridos a opcionales en el modelo; el formulario en sí no cambia (sigue
  validando como requerido en el `FormBuilder`), pero cualquier código que dependa del tipo
  estricto del modelo debe revisarse.
- Masking existente (`FULL_MASK`/`shareMedicalInfo`) en `registrations.service.ts` — no se
  toca, pero corre en el mismo archivo que el nuevo método; riesgo de colisión de nombres o de
  que un refactor accidental mezcle ambas lógicas.
- `users.module.ts` en `api-gateway` — cualquier otro handler del controlador (`GET /users/me`,
  etc.) comparte el módulo; verificar que añadir `EVENTS_SERVICE` no rompe la inyección de los
  clientes existentes.

## Fuera de alcance

- Transferencia de `ownerId` de un evento a otro usuario.
- Cancelación automática de eventos activos como side-effect del borrado.
- TTL/retención a 3 años de registros anonimizados.
- Migrar `EventRegistration.bloodType`/`bloodTypeRaw` a nulo.
- Endpoint de "chequeo" nuevo en Flutter (se reusa `GetMyEventsUseCase`).
- Cualquier cambio a `FULL_MASK`/lógica de enmascarado condicional por `shareMedicalInfo`.
