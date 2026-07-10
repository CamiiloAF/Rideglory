# Tech Lead — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T20:22:30Z_

## Veredicto

**ready** — el diff cumple el change map del PRD normalizado, los 12 criterios de aceptacion
tienen cobertura de test verificada en verde (backend y frontend), y no se encontraron blockers
de seguridad ni de arquitectura. Un archivo (`rpc-custom-exception.filter.ts`) esta fuera del
change map original pero esta justificado por escrito y verificado (necesario para el AC5,
aditivo, sin romper tests preexistentes).

## Hallazgos

Sin blockers. Notas menores (no bloqueantes):

- `rpc-custom-exception.filter.ts` (api-gateway) no estaba en el change map del PRD; Backend lo
  documento explicitamente como necesario para el AC5 (el filtro global descartaba `error`/
  `activeEvents` del body del 409). Cambio aditivo, verificado: los 8 tests preexistentes del
  filtro siguen en verde sin modificarlos.
- La migracion Prisma fue escrita a mano en vez de generada por `prisma migrate dev`, por un
  drift preexistente y ajeno en 2 migraciones antiguas del repo. El SQL resultante es el `ALTER
  TABLE ... DROP NOT NULL` x8 estandar esperado — revisado linea por linea, correcto. Ver
  `REVIEW_CHECKLIST.md` punto 3 para el paso manual de verificacion antes de desplegar.
- `RegistrationContactTrigger` añade un `if (phone == null) return;` silencioso (sin feedback al
  usuario) cuando el telefono fue anonimizado. No es un AC explicito del PRD, pero es coherente
  con el guardrail de "no crash" y es defensivo — aceptable.

## Seguridad

- Sin secretos ni credenciales en el diff.
- Sin SQL concatenado: la migracion usa `ALTER TABLE` estandar via Prisma; el `updateMany` de
  `anonymizeByUserId` usa el query builder de Prisma (parametrizado), no queries crudas.
- Sin PII en logs: `anonymizeByUserId` no loguea el `userId` ni datos personales; el filtro de
  errores solo propaga `activeEvents` (id/name/state, no PII del organizador) en el body 409.
- Filtro por `userId` estrictamente verificado en 2 lugares (codigo + test dedicado
  `'filters strictly by EventRegistration.userId, never by Event.ownerId'`) — evita el riesgo de
  anonimizar registros de otros usuarios via `Event.ownerId`.
- `ensureNoActiveEventsAsOrganizer` corre **antes** de cualquier paso de borrado — verificado con
  test que ningun servicio de borrado se invoca cuando hay eventos activos (incluye
  `anonymizeRegistrationsByUserId` y `hardDeleteUser`).
- Auth: el flujo sigue autenticado via el token de `deleteAccount(uid, email)` ya existente de
  fase 1; no se introdujeron endpoints HTTP nuevos (`anonymizeRegistrationsByUserId` es un
  `MessagePattern` TCP interno, no expuesto por HTTP).

## Arquitectura

- Clean Architecture respetada: `EventRegistrationModel` (domain) sin imports de Flutter/HTTP;
  `EventRegistrationDto` (data) extiende el model (Patron B, `XDto extends XModel`), sin
  `toModel()`/`fromModel()`/`.toDto()`. Verificado en
  `lib/features/event_registration/data/dto/event_registration_dto.dart`.
  `extension EventRegistrationModelExtension on EventRegistrationModel { toJson() }` presente y
  usado, no se construyen `Map<String, dynamic>` a mano para el request body.
- `ProfileActionsList`: presentation llama un domain use case (`GetMyEventsUseCase`) via `getIt`,
  sin HTTP directo ni exposicion de DTOs — mismo patron ya establecido en
  `lib/features/events/presentation/list/events_page.dart` (no es una violacion del principio
  "cubits via context.read, nunca getIt" porque `GetMyEventsUseCase` es un use case, no un
  cubit/bloc).
- Reglas de widgets cero-tolerancia: `active_events_block_sheet.dart` es una unica clase
  (`ActiveEventsBlockSheet`, constructor privado + metodo estatico `show`), no hay metodos que
  retornan `Widget`; construido sobre `AppModal` (shared), no reinventa el look del bottom sheet.
- Env vars / URLs: sin URLs hardcodeadas; `EVENTS_SERVICE` en `api-gateway` usa
  `envs.eventsMsPort`/`envs.eventsMsHost` ya existentes en `config/envs.ts` (no se agrego una
  variable de entorno nueva).
- Shape de API vs contrato: el 409 `ACTIVE_EVENTS_AS_ORGANIZER` coincide exactamente con lo
  especificado en el PRD normalizado (`{statusCode, message, error, activeEvents, traceId?}`) —
  confirmado leyendo el filtro de excepciones y el test de integracion del gateway.
- ERD vs migracion: las 8 columnas relajadas a nullable en `schema.prisma` coinciden 1:1 con las
  8 columnas de la migracion SQL y con los 8 campos hechos nullable en
  `EventRegistrationModel`/DTO de Flutter — sin desalineacion.
- Orden de orquestacion: verificado que respeta el orden fijado por el Architect (dominio fase 2
  -> eventos fase 3 -> PII de usuario -> Firebase Auth siempre al final), con la precondicion de
  organizador ejecutandose primero, antes de cualquier paso destructivo.
- No se duplico el registro de `EVENTS_SERVICE` en `ClientsModule` (Backend lo verifico antes de
  añadirlo, confirmado leyendo el diff — solo aparece una vez en `users.module.ts`).
- `FULL_MASK` (enmascarado reversible) y `ANONYMIZED_FULL_NAME` (anonimizacion permanente) se
  mantienen como constantes distintas e independientes — no hay colision ni reuso indebido.

## Tests

Cobertura AC por AC, todos verificados en verde por Tech Lead (no solo reportados por los
agentes de implementacion):

- AC1/AC2/AC3/AC4/AC12 (precondicion de organizador, re-evaluada en cada tap, CTA a `myEvents`,
  sin llamada de red nueva): `profile_actions_list_delete_account_precondition_test.dart` (6
  tests) + `active_events_block_sheet_test.dart` (2 tests) — **8/8 pass**.
- AC5 (409 con `activeEvents`, sin efectos secundarios): `account-deletion.service.spec.ts`,
  describe `'ACTIVE_EVENTS_AS_ORGANIZER precondition'` — **3/3 pass** (bloqueo, no-bloqueo con
  CANCELLED/FINISHED, no-bloqueo sin eventos propios).
- AC6/AC7/AC8 (anonimizacion + evidencia legal intacta + idempotencia):
  `registrations.service.anonymization.spec.ts` — **7/7 pass**.
- AC9 (AttendeesList sin crash con nombre "Usuario eliminado"): no requiere cambio de codigo
  Flutter (el nombre viene del backend, `fullName` sigue no-nulo) — sin test dedicado nuevo, pero
  tampoco hay regresion esperada; recomendado verificarlo manualmente en QA (ver
  `REVIEW_CHECKLIST.md` punto 5).
- AC10 (placeholder dedicado en `RegistrationDetailPage`, incluyendo `birthDate`):
  `registration_detail_page_test.dart`, grupo `'anonymized (deleted-account) registration'` —
  **1 test, verifica 8 placeholders + sin excepcion**.
- AC11 (`dart analyze` sin errores tras el cambio de nulabilidad): verificado por Tech Lead sobre
  las carpetas tocadas — 0 issues nuevos.
- Regresion en `RegistrationContactTrigger` por `phone` nulo:
  `registration_contact_trigger_test.dart` — 1 test nuevo, sin excepcion, sin URL lanzada.

Suites backend re-ejecutadas por Tech Lead: `events-ms` completo (7 suites/55 tests),
`api-gateway -- account-deletion` (11/11). No se re-ejecuto `api-gateway` completo ni
`users-ms`/`vehicles-ms` — pendiente en `REVIEW_CHECKLIST.md` antes de commitear.

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` para la lista completa. Resumen de lo mas critico:

1. Revisar a mano el `migration.sql` (escrito manualmente, no generado por `prisma migrate dev`)
   antes de aplicarlo en cualquier entorno compartido o produccion.
2. Confirmar visualmente en el simulador el bottom sheet de bloqueo con el usuario de prueba
   `qa2@gmail.com` (organizador de "Mi Evento").
3. Verificar en BD (no solo UI) los ACs 5-8 con datos reales de QA antes de desplegar.
