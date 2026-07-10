# QA — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T20:17:31Z_

## Catalogo

AC (PRD_NORMALIZED.md §5) → cobertura de test:

| AC | Descripción (resumen) | Cobertura |
|----|------------------------|-----------|
| 1 | Rider sin eventos activos → navega directo a confirmación | **Existente/nuevo** — `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart` ("No active organizer events... navigates straight to AppRoutes.deleteAccount") |
| 2 | Organizador con evento `DRAFT`/`SCHEDULED`/`IN_PROGRESS` ve bloqueo antes de llegar a la confirmación (nunca ve el switch/botón final) | **Nuevo** — mismo archivo, casos de bloqueo por cada estado; verifica que navega al sheet y no a `AppRoutes.deleteAccount`. No hay assertion explícita de "el switch/botón final nunca se monta" porque la navegación al sheet ya excluye el push de la ruta de confirmación (suficiente a nivel widget) |
| 3 | Sheet muestra nombre del evento bloqueante + CTA a `AppRoutes.myEvents` | **Nuevo** — `active_events_block_sheet_test.dart` (2 tests: nombre del evento, CTA navega a `myEvents`) |
| 4 | Precondición se re-evalúa en cada tap, no se cachea | **Nuevo** — caso "Re-evaluated on every tap (AC4): first tap blocked, second tap... navigates through" |
| 5 | `DELETE /users/me` con eventos activos → 409 `ACTIVE_EVENTS_AS_ORGANIZER`, sin ejecutar ningún paso de borrado (verificado en BD) | **Nuevo (unit) + gap manual-BD** — `account-deletion.service.spec.ts` cubre el 409 y cero llamadas a los pasos de borrado a nivel de mocks (unit, no BD real). La verificación literal "en BD que nada cambió" (`events-ms`, `vehicles-ms`, `users-ms`) es un **gap** — no se ejecutó contra una BD real en esta corrida (ver `## Pruebas manuales`) |
| 6 | Tras borrado exitoso, `EventRegistration` anonimizado (`fullName='Usuario eliminado'`, 8 campos PII `null`, ambos booleanos de consentimiento en `false`) — verificado en BD | **Nuevo (unit) + gap manual-BD** — `registrations.service.anonymization.spec.ts` cubre el efecto exacto vía mocks de Prisma (`updateMany` con los campos correctos). No se corrió un `DELETE /users/me` end-to-end contra Postgres real en esta corrida QA (Backend sí lo hizo para la migración, no para el flujo completo con datos de un rider real) |
| 7 | Evidencia legal (`riskAcceptedAt`, `riskAcceptanceVersion`, `medicalConsentAcceptedAt`, `medicalConsentVersion`) no cambia | **Nuevo** — spec "does not touch bloodType, legal-evidence fields, vehicleId, status, eventId or userId" (unit, asserts sobre el payload de `updateMany`, no BD real) |
| 8 | Llamada doble a `anonymizeRegistrationsByUserId` es idempotente (mismo `count`, mismo estado) | **Nuevo** — spec "is idempotent: a second call for the same userId does not throw and yields the same effect" (unit, mock-based) |
| 9 | `AttendeesList`/`AttendeesView` con inscrito de cuenta eliminada muestra "Usuario eliminado" sin crash | **Gap** — no se encontró un test nuevo o existente que ejercite `AttendeesList`/`AttendeesView` con `fullName='Usuario eliminado'` y los 8 campos `null`; Frontend documenta en su handoff que no tocó estos archivos "sin referencias directas a los 8 campos anonimizados detectadas en el scan". Dado que `fullName` sigue no-nulable y el bloque de datos nulos no se propaga a esa vista (solo se usa `fullName`), el riesgo de crash es bajo, pero no hay test que lo confirme explícitamente |
| 10 | `RegistrationDetailPage` — 7 campos de texto + `birthDate` muestran `registration_deletedAccountFieldPlaceholder` ("Cuenta eliminada"), nunca "N/A"/vacío/crash | **Nuevo** — `registration_detail_page_test.dart` línea 302: `findsNWidgets(8)` para "Cuenta eliminada"; comentario explícito en línea 280 confirmando que no se usa `context.l10n.notAvailable` |
| 11 | `dart analyze` limpio tras cambio de nulabilidad | **Verificado en esta corrida** — 0 errores, 15 issues `info` preexistentes (mismos del baseline reportado por Frontend, ninguno nuevo) |
| 12 | Precondición del primer tap no dispara ninguna llamada de red nueva más allá de la que ya usa "Mis eventos" | **Nuevo (parcial)** — el widget test mockea `GetMyEventsUseCase` (el mismo use case que "Mis eventos" usa) y verifica que se llama exactamente una vez por tap; no hay una inspección de tráfico HTTP real (proxy/logs) en esta corrida — cobertura a nivel de código (mismo use case, no un cliente nuevo) es suficiente para el AC tal como está redactado, pero la verificación "de caja negra" con proxy queda como gap manual |

## Matriz de regresion (guardrails §6)

| Guardrail | Mecanismo de verificación |
|---|---|
| No confundir `FULL_MASK` con anonimización permanente; constante nueva distinta | Spec "does not reuse or reference FULL_MASK — anonymization writes a distinct literal name" (unit) + tipo `ANONYMIZED_FULL_NAME` revisado en código (`registrations.service.ts`) |
| Anonimizar por `EventRegistration.userId`, nunca `Event.ownerId` | Spec "filters strictly by EventRegistration.userId, never by Event.ownerId" (unit) |
| No duplicar `ClientsModule.registerAsync` de `EVENTS_SERVICE` en `users.module.ts` | Confirmado por Backend en su handoff ("verificado antes de añadir, sin duplicado"); no re-verificado línea por línea en esta corrida, pero `npm run build`/`npm test` de `api-gateway` no reportan error de DI duplicado |
| Orden de orquestación fijo: dominio → eventos → PII usuario → Firebase Auth | Spec "calls the 8 steps in order..." (unit, orden explícito) |
| No introducir endpoint de chequeo nuevo en Flutter | Confirmado por lectura de `profile_actions_list.dart`/handoff Frontend — usa `GetMyEventsUseCase` existente; sin nuevo endpoint en el diff |
| No reusar `notAvailable`/"N/A" para el placeholder de cuenta eliminada | Test explícito verifica ausencia de `notAvailable` (comentario + `findsNWidgets(8)` de "Cuenta eliminada" exacto) |
| Migración Prisma aditiva, no rompe filas existentes | Verificación manual de Backend documentada en su handoff (`\d`, conteo de filas, `IS NULL` = 0) — no re-ejecutada en esta corrida QA (mismo entorno local del agente Backend, no compartido) |
| `dart analyze` limpio + búsqueda de usos que asuman no-nulidad | `dart analyze` verificado limpio en esta corrida; búsqueda amplia adicional de usos no-null-safe no se re-ejecutó en esta corrida más allá de lo que ya cubre `dart analyze` (que atraparía nulls no manejados vía flow analysis en la mayoría de casos, no en todos — p.ej. no detecta un `AttendeesList` que asuma no-nulidad de un campo que sigue siendo no-nulable como `fullName`) |
| No migrar `bloodType`/`bloodTypeRaw` a nullable | Spec "does not touch bloodType..." (unit) + `prisma/schema.prisma` revisado (Backend handoff: "`bloodType` y `fullName` intactos") |

## Ejecucion

- `dart analyze` (Rideglory) → **0 errores**, 15 `info` preexistentes (mismos del baseline, ninguno nuevo introducido por esta fase).
- `flutter test` (completo) → **1396/1396 pass**. Coincide con lo reportado por Frontend (1386 baseline + 10 nuevos).
- `events-ms`: `npm test` (completo) → **7 suites / 55 tests pass**.
- `api-gateway`: `npm test -- account-deletion` → **11/11 pass**. `npm test -- rpc-custom-exception` → **8/8 pass**. `npm test` completo → **16/17 suites pass, 143/151 tests pass**; la única suite roja es `places/places.service.iter3.spec.ts` (8 tests), fallando por `MAPBOX_ACCESS_TOKEN` no cargado en el entorno de Jest — **pre_existing**, confirmado no relacionado con esta fase (no toca `places/`, contratos ni env vars de Mapbox; mismo resultado reportado como baseline por Backend).

No se encontraron regresiones nuevas en ninguna suite.

## Bugs

Ninguno encontrado en esta corrida (ver gaps documentados arriba en `## Catalogo`, que son ausencia de cobertura, no defectos observados).

## Pruebas manuales

Estado: **no ejecutadas en esta corrida** (este agente QA no tiene acceso a un simulador/dispositivo Flutter ni a una BD Postgres compartida en este entorno — mismo límite que reportó Frontend). Pendientes, a ejecutar por un humano o en un entorno con app corriendo + BD real antes de considerar la fase completamente cerrada:

1. **AC1-AC4 (UI, dos usuarios)**: con un organizador de prueba, mover un evento a `DRAFT`/`SCHEDULED`/`IN_PROGRESS`, tocar "Eliminar cuenta" → confirmar que se ve `ActiveEventsBlockSheet` con el nombre del evento y que **nunca** se llega a `DeleteAccountConfirmationPage` (ni al switch ni al botón final). Cambiar el evento a `CANCELLED`/`FINISHED` y repetir el tap → debe navegar directo a la confirmación (AC4, no cacheado).
2. **AC5 (BD real)**: `DELETE /users/me` para un organizador con evento activo → confirmar 409 y que, consultando directamente `vehicles-ms`, `events-ms` (`EventRegistration`) y `users-ms`, **nada** cambió.
3. **AC6-AC7 (BD real)**: borrado exitoso de un rider con al menos una `EventRegistration` → consultar `events-ms` directamente y confirmar `fullName='Usuario eliminado'`, los 8 campos PII en `null`, `shareMedicalInfo=false`, `allowOrganizerContact=false`, y que `riskAcceptedAt`/`riskAcceptanceVersion`/`medicalConsentAcceptedAt`/`medicalConsentVersion` son idénticos a los valores pre-borrado (snapshot antes/después).
4. **AC8 (BD real)**: invocar `anonymizeRegistrationsByUserId` dos veces seguidas para el mismo `userId` (vía MessagePattern directo, TCP) → mismo `count`, mismo estado de filas tras la segunda llamada.
5. **AC9 (UI)**: como organizador, abrir la lista de asistentes de un evento con un inscrito de cuenta eliminada → confirmar "Usuario eliminado" sin crash (gap de cobertura automatizada — ver Catálogo AC9).
6. **AC10 (UI)**: `RegistrationDetailPage` sobre ese mismo inscrito → confirmar visualmente "Cuenta eliminada" en los 7 campos de texto + fecha de nacimiento, tipo de sangre sigue visible.
7. **AC12 (tráfico de red)**: con proxy/logs, tocar "Eliminar cuenta" y confirmar que la única llamada HTTP disparada es la misma que ya usa "Mis eventos" (`GET` de eventos propios), ninguna nueva.
8. **Regresión de masking**: un registro anonimizado con `shareMedicalInfo=false` (forzado por la anonimización) debe seguir mostrando `••••` en campos médicos vía `FULL_MASK` existente — confirmar visualmente que no se mezcló con "Usuario eliminado"/"Cuenta eliminada".
9. **Migración Prisma en el entorno compartido**: la migración solo fue aplicada y verificada en el Postgres local del agente Backend (`localhost:5432/events`). Antes de cualquier despliegue, debe aplicarse y verificarse (conteo de filas, columnas nullable) contra la BD compartida/real, con verificación humana explícita — no cubierto por esta corrida QA.

## Sign-off

**Conditional.**

Justificación: toda la suite automatizada disponible pasa limpio (`dart analyze` 0 errores, `flutter test` 1396/1396, `events-ms` 55/55, `api-gateway` foco 19/19, suite completa de `api-gateway` sin regresiones nuevas — la única suite roja es pre-existente y ajena al alcance). La cobertura unit/widget de los 12 AC es fuerte para lógica de negocio y UI aislada, pero **AC5, AC6, AC7, AC8, AC9 y AC12 requieren verificación contra BD real / dispositivo real / tráfico de red que este agente QA no pudo ejecutar en este entorno** (sin acceso a simulador Flutter ni a una BD Postgres compartida). Estos puntos están listados en `## Pruebas manuales` y deben cerrarse por un humano (o un QA con acceso a esos recursos) antes de dar luz verde completa a producción, especialmente antes de desplegar la migración Prisma.
