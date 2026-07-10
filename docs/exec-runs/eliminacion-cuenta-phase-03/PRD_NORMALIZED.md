# PRD Normalizado — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T19:27:43Z_ · _Fuente: docs/plans/eliminacion-cuenta/phases/phase-03-eliminacion-de-cuenta-historial-de-eventos-y-org.md_

## 1 Objetivo

Extender el flujo de eliminación de cuenta (`DELETE /users/me`, fases 1 y 2 ya entregadas) para que:
- El historial de participación en eventos (`EventRegistration`) de un rider que elimina su cuenta
  quede **anonimizado** (PII borrada) preservando la **evidencia legal** de aceptación de
  consentimientos de riesgo y salud (timestamp + versión, sin nombre asociado).
- Un organizador con eventos activos (`DRAFT`, `SCHEDULED`, `IN_PROGRESS`) sea bloqueado con un
  mensaje accionable **antes** de invertir esfuerzo en la pantalla de confirmación de fase 1, no
  después de confirmar.

## 2 Por qué

- Cumplimiento legal: hay que poder demostrar que un usuario aceptó los consentimientos de riesgo/
  salud en su momento, incluso después de borrar su cuenta, sin retener PII innecesaria.
- UX: bloquear tarde (después de que el organizador ya completó la pantalla de confirmación) es
  frustrante y genera esfuerzo desperdiciado; bloquear en el primer tap con un CTA accionable evita
  ese desperdicio.
- Consistencia de datos: sin este paso, borrar una cuenta dejaría registros de eventos con PII
  huérfana o el sistema permitiría borrar cuentas de organizadores con eventos en curso, dejando
  esos eventos sin dueño gestionable.

## 3 Alcance

**Entra:**
- Nuevo `MessagePattern anonymizeRegistrationsByUserId` en `events-ms`, integrado como paso 3 de la
  orquestación de `DELETE /users/me` (después de fase 2 — borrado de vehículos/documentos —, antes
  de `hardDeleteUser` de fase 1).
- Especificación campo por campo de qué se anonimiza vs. qué se preserva en `EventRegistration`
  (ver tabla en la fuente, sección "Cambios de datos").
- Definición formal de "evento activo" (`state IN (DRAFT, SCHEDULED, IN_PROGRESS)`) y contrato
  `409 ACTIVE_EVENTS_AS_ORGANIZER` en `DELETE /users/me`.
- Precondición de organizador ejecutada en el primer tap de "Eliminar cuenta" en Flutter, reusando
  `GetMyEventsUseCase`/`findEventsByOwnerId` ya existentes (sin endpoint de chequeo nuevo).
- Estado de bloqueo dedicado en la UI (bottom sheet, no `ConfirmationDialog` genérico) con CTA a
  `AppRoutes.myEvents`.
- Ajuste de vistas de terceros (`RegistrationDetailPage`) para manejar campos ahora nulables tras
  la anonimización, con placeholder dedicado `registration_deletedAccountFieldPlaceholder`.
- Migración Prisma aditiva: relajar a nullable las columnas PII de `EventRegistration` en
  `events-ms/prisma/schema.prisma`.

**No entra (recortado explícitamente):**
- Transferencia de `ownerId` de un evento a otro usuario como alternativa a cancelar.
- Cancelación automática de eventos activos como side-effect del borrado de cuenta.
- Retención/expiración a 3 años de los registros anonimizados (TTL).
- Migrar `EventRegistration.bloodType` a nulo (se preserva el enum; sigue protegido por el masking
  `FULL_MASK` existente en runtime, independiente de esta fase).

## 4 Áreas afectadas (best-effort)

**Backend (`rideglory-api`):**
- `events-ms/src/registrations/registrations.controller.ts` — nuevo `@MessagePattern('anonymizeRegistrationsByUserId')`.
- `events-ms/src/registrations/registrations.service.ts` — nuevo método `anonymizeByUserId(userId)` (`updateMany` campo por campo + constante `ANONYMIZED_FULL_NAME`).
- `events-ms/src/registrations/registrations.service.*.spec.ts` — nuevo spec de anonimización.
- `events-ms/prisma/schema.prisma` — migración de nulabilidad en columnas PII de `EventRegistration`.
- `rideglory-contracts/src/events/dto/` — posible `AnonymizeRegistrationsPayloadDto` + rebuild del paquete (gotcha de contracts conocido).
- `api-gateway/src/users/users.controller.ts` (o donde viva el handler `DELETE me` de fase 1) — precondición 409 + paso 3 de orquestación.
- `api-gateway/src/users/users.module.ts` — registrar `EVENTS_SERVICE` como cliente TCP si aún no está.

**Flutter (`Rideglory`):**
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — `onTap` de "Eliminar cuenta" corre la validación de organizador antes de navegar.
- `lib/features/profile/presentation/widgets/active_events_block_sheet.dart` — nuevo widget de bloqueo con CTA a "Mis eventos".
- `lib/features/authentication/domain/exceptions/active_events_as_organizer_exception.dart` (ruta a confirmar según ubicación real de `DeleteAccountUseCase` de fase 1) — excepción tipada con `activeEvents`.
- Repositorio/mapeo de errores del `DeleteAccountUseCase` de fase 1 — mapeo del 409 `ACTIVE_EVENTS_AS_ORGANIZER`.
- `lib/features/event_registration/domain/model/event_registration_model.dart` — nulabilidad de `identificationNumber`/`phone`/`email`/`residenceCity`/`eps`/`emergencyContactName`/`emergencyContactPhone`/`birthDate`.
- DTO 1:1 de `EventRegistrationModel` (Patrón B) en `lib/features/event_registration/data/dto/` — mismo cambio de nulabilidad en `fromJson`.
- `lib/features/event_registration/presentation/registration_detail_page.dart` — fallback `?? context.l10n.registration_deletedAccountFieldPlaceholder` en campos nulables.
- `lib/l10n/app_es.arb` (+ regenerar `app_localizations*.dart`) — nuevas keys `profile_deleteAccountBlocked*` y `registration_deletedAccountFieldPlaceholder`.

## 5 Criterios de aceptación (numerados, observables, testeables)

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
5. Llamar `DELETE /users/me` para un `userId` con eventos activos como organizador responde `409`
   con `error: "ACTIVE_EVENTS_AS_ORGANIZER"` y la lista `activeEvents` no vacía, **sin** ejecutar
   ningún paso de borrado de dominio (verificar en BD que ni vehículos, ni `EventRegistration`, ni
   el usuario en `users-ms` cambiaron).
6. Tras un `DELETE /users/me` exitoso (sin eventos activos), cada `EventRegistration` del usuario
   en `events-ms` tiene: `fullName = 'Usuario eliminado'`, `identificationNumber`, `birthDate`,
   `phone`, `email`, `residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone` en
   `null`, `shareMedicalInfo = false`, `allowOrganizerContact = false` — verificado directamente en
   la base de datos de `events-ms`, no solo en la UI.
7. Tras el mismo borrado exitoso, `riskAcceptedAt`, `riskAcceptanceVersion`,
   `medicalConsentAcceptedAt`, `medicalConsentVersion` de cada `EventRegistration` afectada **no
   cambiaron** respecto a sus valores antes del borrado (evidencia legal preservada) — verificado
   en BD.
8. Llamar `anonymizeRegistrationsByUserId` dos veces seguidas para el mismo `userId` (reintento) no
   lanza error; el `count` devuelto en ambas llamadas es igual a `N`, y el estado resultante de las
   filas tras la segunda llamada es **idéntico** al de la primera (idempotencia de efecto, no de
   conteo — no se afirma `count: 0` en el reintento).
9. En la lista de asistentes de un evento (`AttendeesList`/`AttendeesView`) donde uno de los
   inscritos eliminó su cuenta, el nombre mostrado es `Usuario eliminado`, sin excepción ni crash
   por campos nulos.
10. En `RegistrationDetailPage` (vista del organizador sobre un inscrito con cuenta eliminada), los
    campos de documento, fecha de nacimiento, teléfono, email, ciudad de residencia, EPS y contacto
    de emergencia muestran `context.l10n.registration_deletedAccountFieldPlaceholder`
    (`"Cuenta eliminada"`, key nueva — **no** se reusa `notAvailable`/`"N/A"`) en vez de un string
    vacío, `null` renderizado literalmente, o un crash — incluyendo `birthDate` vía
    `birthDate?.formattedDate ?? context.l10n.registration_deletedAccountFieldPlaceholder`.
11. `dart analyze` no reporta errores tras el cambio de nulabilidad de
    `EventRegistrationModel`/DTO.
12. La validación de organizador en el primer tap no realiza ninguna llamada de red nueva más allá
    de la que ya usa la pantalla "Mis eventos" (verificable inspeccionando las llamadas HTTP
    disparadas al tocar el ítem "Eliminar cuenta").

## 6 Guardrails de regresión

- No confundir el enmascarado por privacidad reversible (`FULL_MASK '••••'`, condicional en
  runtime según `shareMedicalInfo`) con la anonimización permanente de esta fase (irreversible):
  usar constante nueva y distinta `ANONIMYZED_FULL_NAME`/`ANONYMIZED_FULL_NAME`, no tocar la lógica
  de `FULL_MASK` existente. Un registro anonimizado con `shareMedicalInfo=false` debe seguir
  mostrando `••••` en campos médicos vía el masking existente.
- No excluir/afectar por error al `ownerId` del propio evento al anonimizar: el filtro es por
  `userId` en `EventRegistration`, no por `Event.ownerId`; si se llegó a este paso es porque el
  usuario ya no tiene eventos activos como organizador (bloqueado antes).
- No registrar dos veces `ClientsModule.registerAsync` para `EVENTS_SERVICE` en `users.module.ts`
  si fase 1/2 ya lo hicieron de otra forma — verificar en código antes de duplicar.
- No romper el orden de orquestación ya fijado: dominio (fase 2) → eventos (esta fase) → PII de
  usuario → Firebase Auth (fase 1, siempre al final).
- No introducir un endpoint de "chequeo" nuevo en el cliente Flutter — reusar `findEventsByOwnerId`/
  `GetMyEventsUseCase` ya existentes; el 409 del backend sigue siendo el guardián autoritativo para
  condiciones de carrera.
- No reusar `context.l10n.notAvailable` (`"N/A"`) para el placeholder de cuenta eliminada — key
  dedicada `registration_deletedAccountFieldPlaceholder` para no confundir "dato no diligenciado"
  con "usuario eliminado" en soporte/QA.
- La migración de nulabilidad de Prisma es aditiva (relaja `NOT NULL`, no la impone); correr y
  verificar localmente antes de cualquier despliegue (ver guardrail global de deploy), y confirmar
  contra datos reales que no rompe filas existentes.
- Tras el cambio de nulabilidad de `EventRegistrationModel`/DTO, correr `dart analyze` y una
  búsqueda amplia adicional de usos de estos campos que puedan asumir no-nulidad en sitios no
  detectados en el scan original.
- No migrar `EventRegistration.bloodType` a nullable ni tocar `bloodTypeRaw` (campo derivado en
  Flutter) al hacer el cambio de nulabilidad de los demás campos.

## 7 Constraints heredados

- Un endpoint/una pantalla: esta fase **extiende** el mismo `DELETE /users/me` y la misma
  `DeleteAccountConfirmationPage` de fase 1 — no crea rutas ni pantallas paralelas.
- Orden de orquestación fijado por el Architect: dominio (fase 2) → eventos (esta fase) → PII de
  usuario → Firebase Auth (fase 1, siempre al final) — no alterable sin coordinación.
- Arquitectura Clean (domain/data/presentation) y DTO Pattern B obligatorio (`XDto extends XModel`)
  para `EventRegistrationModel`/DTO — ver CLAUDE.md raíz.
- Reglas de widgets cero-tolerancia: un widget por archivo, prohibidos métodos que retornan
  widgets — aplica al nuevo `active_events_block_sheet.dart`.
- Strings de UI siempre vía `lib/l10n/app_es.arb` + `context.l10n.<key>`, prefijo por feature
  (`profile_`, `registration_`) — cero tolerancia a hardcodeo.
- Gotcha de `rideglory-contracts`: tras editar el paquete, `npm run build` + reinstalar en
  `events-ms`/`api-gateway`.
- Migraciones: correr y verificar localmente primero, esperar verificación humana antes de
  desplegar (flujo de deploy ya establecido del proyecto).
- Working tree queda sucio a propósito para revisión humana — este agente y los que ejecuten esta
  fase no deben commitear.
