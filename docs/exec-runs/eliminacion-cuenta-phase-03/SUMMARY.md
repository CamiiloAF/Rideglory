# SUMMARY — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T20:22:30Z_

## Objetivo

Extender el flujo de eliminacion de cuenta (`DELETE /users/me`, fases 1-2 ya entregadas) para:
1. Bloquear en el primer tap de "Eliminar cuenta" a un organizador con eventos activos
   (`DRAFT`/`SCHEDULED`/`IN_PROGRESS`), antes de llegar a la pantalla de confirmacion de fase 1.
2. Anonimizar (no borrar) el historial de `EventRegistration` de un rider que elimina su cuenta,
   preservando la evidencia legal de aceptacion de consentimientos de riesgo/salud.

## Que cambio por area

### Backend (rideglory-api, submodulos)

- **rideglory-contracts**: nuevo `AnonymizeRegistrationsPayloadDto` (`userId: string @IsUUID`),
  exportado desde `src/events/dto/index.ts`.
- **events-ms**:
  - `prisma/schema.prisma` + migracion `20260710194244_registration_nullable_pii`: 8 columnas de
    `EventRegistration` (`identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`,
    `eps`, `emergencyContactName`, `emergencyContactPhone`) pasan a nullable. `bloodType` y
    `fullName` intactos (`NOT NULL`). Aditiva (`DROP NOT NULL`), aplicada y verificada localmente,
    no desplegada.
  - Nuevo `@MessagePattern('anonymizeRegistrationsByUserId')` en `registrations.controller.ts` ->
    `RegistrationsService.anonymizeByUserId(userId)`: `updateMany` por `userId` (nunca
    `Event.ownerId`), escribe `fullName = 'Usuario eliminado'` (`ANONYMIZED_FULL_NAME`, constante
    distinta de `FULL_MASK`), pone en `null` los 8 campos PII, `shareMedicalInfo = false`,
    `allowOrganizerContact = false`. No toca `bloodType`, evidencia legal
    (`riskAcceptedAt`/`riskAcceptanceVersion`/`medicalConsentAcceptedAt`/`medicalConsentVersion`),
    `vehicleId`, `status`, `eventId`, `userId`, `id`. Idempotente.
  - Ajustes de tipos derivados de la nulabilidad: `persistRiderProfile()` acepta los campos
    ahora-opcionales; `applyPrivacyMask<T>` amplia sus tipos a `string | null` (el masking ya
    toleraba `null` en runtime).
- **api-gateway**:
  - `users.module.ts`: registra `EVENTS_SERVICE` en `ClientsModule` (TCP, no existia antes;
    verificado que no duplica un registro previo).
  - `account-deletion.service.ts`: `deleteAccount()` reescrito a 8 pasos: `findUserByEmail` ->
    `ensureNoActiveEventsAsOrganizer` (409 `ACTIVE_EVENTS_AS_ORGANIZER`) -> `hardDeleteAllByOwner`
    -> `deleteFilesByUrls` (best-effort) -> `softDeleteMaintenancesByUserId` ->
    `anonymizeRegistrationsByUserId` -> `hardDeleteUser` -> `firebaseAuthService.deleteUser`. La
    precondicion reusa `findEventsByOwnerId` (ya existente en events-ms, sin endpoint nuevo) y
    filtra por `DRAFT`/`SCHEDULED`/`IN_PROGRESS`.
  - `rpc-custom-exception.filter.ts`: cambio no listado en el change map original, necesario para
    el AC5 — el filtro global descartaba cualquier propiedad extra del error RPC (`error`,
    `activeEvents`); se extendio `normalizeError()`/`catch()` para propagarlas en el body JSON via
    un campo `extra` que se spreadea. Aditivo y retrocompatible (8 tests preexistentes del filtro
    siguen pasando sin tocarlos).

### Frontend (Rideglory, Flutter)

- `EventRegistrationModel` / `EventRegistrationDto` (Patron B): los 8 campos PII pasan a nullable
  (`String?`/`DateTime?`); `fullName`/`bloodType` siguen requeridos. `toJson()` de
  `EventRegistrationDto` se simplifica: al ser `birthDate` ahora `DateTime?`, el converter global
  `apiJsonDateTimeConverters` ya lo serializa en UTC ISO — se retira el override manual con
  `apiEncodeRequiredDateTime` que solo aplicaba a campos `DateTime` no-nulos.
- `RegistrationDetailPage`: cada uno de los 8 campos ahora-nulables cae a
  `context.l10n.registration_deletedAccountFieldPlaceholder` ("Cuenta eliminada") — key dedicada,
  no reusa `notAvailable`/"N/A".
- `RegistrationContactTrigger`: guarda temprana `if (phone == null) return;` antes de abrir
  WhatsApp/llamada, evita crash/URL invalida con `phone` anonimizado.
- `ProfileActionsList`: el `onTap` de "Eliminar cuenta" ahora ejecuta `_handleDeleteAccountTap()`
  — llama `getIt<GetMyEventsUseCase>()` (mismo patron que `events_page.dart`, sin endpoint nuevo),
  re-evaluado en cada tap (no cacheado). Sin eventos activos -> navega a
  `AppRoutes.deleteAccount`. Con al menos uno -> abre `ActiveEventsBlockSheet`. Si falla la
  consulta -> `SnackBar`, sin navegar (evita bypass silencioso de la precondicion).
- Nuevo `lib/features/profile/presentation/widgets/active_events_block_sheet.dart`: un widget por
  archivo, construido sobre `AppModal` (mismo building block que `ConfirmationDialog`), CTA
  navega a `AppRoutes.myEvents`.
- `lib/l10n/app_es.arb` (+ regenerado `app_localizations*.dart`): nuevas keys
  `profile_deleteAccountBlocked_title/body/cta/checkError` y
  `registration_deletedAccountFieldPlaceholder`.

## Archivos

**Backend** (`rideglory-api`, repos separados):
- `rideglory-contracts/src/events/dto/anonymize-registrations-payload.dto.ts` (nuevo), `index.ts`
- `events-ms/prisma/schema.prisma`, `prisma/migrations/20260710194244_registration_nullable_pii/`
  (nuevo)
- `events-ms/src/registrations/registrations.controller.ts`, `registrations.service.ts`
- `events-ms/src/registrations/registrations.service.anonymization.spec.ts` (nuevo, 7 tests)
- `api-gateway/src/users/users.module.ts`, `account-deletion.service.ts`,
  `account-deletion.service.spec.ts`
- `api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts`

**Frontend** (`Rideglory`):
- `lib/features/event_registration/domain/model/event_registration_model.dart`
- `lib/features/event_registration/data/dto/event_registration_dto.dart`
- `lib/features/event_registration/presentation/registration_detail_page.dart`
- `lib/features/event_registration/presentation/widgets/registration_contact_trigger.dart`
- `lib/features/profile/presentation/widgets/profile_actions_list.dart`
- `lib/features/profile/presentation/widgets/active_events_block_sheet.dart` (nuevo)
- `lib/l10n/app_es.arb`, `app_localizations.dart`, `app_localizations_es.dart`
- `test/features/event_registration/presentation/registration_detail_page_test.dart`
- `test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart`
- `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart`
  (nuevo)
- `test/features/profile/presentation/widgets/active_events_block_sheet_test.dart` (nuevo)

## Pruebas

- `events-ms`: `npm test` -> **7 suites / 55 tests pass** (verificado por Tech Lead:
  `npm test -- registrations.service.anonymization` -> 7/7 y suite completa -> 55/55).
- `api-gateway`: `npm test -- account-deletion` -> **11/11 pass** (verificado por Tech Lead);
  `npm test -- rpc-custom-exception` -> 8/8 sin regresion (segun handoff de Backend, no
  re-ejecutado por Tech Lead).
- Flutter: `dart analyze lib/features/event_registration lib/features/profile lib/l10n` ->
  **0 issues nuevos** (1 lint preexistente y ajeno en `profile_page.dart`, verificado por Tech
  Lead). `flutter test` de los 4 archivos de test tocados/nuevos -> **24/24 pass** (verificado
  por Tech Lead).
- Busqueda ampliada de usos de los 8 campos ahora-nulables fuera de los archivos tocados -> sin
  resultados (ningun sitio no detectado asume no-nulidad).
- Migracion Prisma aplicada y verificada localmente contra datos reales (5 filas existentes, 0
  con PII nula tras aplicar — confirma aditividad); no desplegada.

## Riesgos / watchlist

- **Migracion Prisma escrita a mano, no generada por `prisma migrate dev`** (drift preexistente
  en 2 migraciones ajenas bloqueo el flujo estandar). El SQL es el `ALTER TABLE ... DROP NOT
  NULL` x8 estandar que Prisma habria generado, pero quien despliegue a produccion debe
  verificarlo explicitamente antes de aplicar (ver guardrail global de deploy — correr y
  verificar localmente primero, esperar verificacion humana).
- El cambio en `rpc-custom-exception.filter.ts` (propagar `extra` en el body de error) no estaba
  en el change map original del PRD pero es necesario para el AC5; es aditivo y no rompe
  comportamiento existente — documentado explicitamente por Backend, verificado por Tech Lead
  (8 tests preexistentes del filtro siguen en verde).
- El 409 `ACTIVE_EVENTS_AS_ORGANIZER` es la unica verdad autoritativa contra condiciones de
  carrera (Flutter no cachea ni confia unicamente en la precondicion del primer tap) — correcto
  segun diseno, pero vale la pena que QA intente el caso de carrera real (crear evento activo
  justo despues del check y antes de confirmar en fase 1) para confirmar que el 409 de fase 1
  tambien se maneja en la UI de confirmacion (fuera del alcance de esta fase, pero relevante
  para UX).
- No se automatizaron pruebas end-to-end contra un entorno desplegado; toda la verificacion de
  BD fue local (`localhost:5432/events`).

## Mensaje de commit sugerido

```
feat(account-deletion): bloquear organizadores con eventos activos y anonimizar historial de inscripciones

Extiende DELETE /users/me (fases 1-2) con una precondicion 409
ACTIVE_EVENTS_AS_ORGANIZER (bloqueo temprano en Flutter, primer tap) y un
paso de anonimizacion permanente de EventRegistration en events-ms que
preserva la evidencia legal de consentimientos de riesgo/salud.
```
