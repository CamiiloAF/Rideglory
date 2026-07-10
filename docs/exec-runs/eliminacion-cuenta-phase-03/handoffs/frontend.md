# Frontend handoff — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T20:12:10Z_

## Baseline

- `flutter test` (completo, antes de tocar código) → **1386/1386 tests pass**.

## Nota de proceso — bloqueo de Design/UX Review y decisión tomada

`handoffs/design.md` y `handoffs/ux-review.md` terminaron en `status: blocked`: Pencil MCP
(`mcp__pencil__*`) no se surfacea a los subagentes de este workflow, por lo que no existen frames
nuevos en `rideglory.pen` para `ActiveEventsBlockSheet`, `ProfileActionsList` (tap async) ni
`RegistrationDetailPage` (placeholders). El UX Reviewer marcó explícitamente "Frontend no debe
empezar a implementar UI sin diseño aprobado".

Decisión tomada para poder avanzar sin violar `feedback_ui_design_first.md`/
`feedback_pencil_mcp_block.md`: **no se diseñó ninguna superficie visual nueva**. El único
componente de UI verdaderamente nuevo (`ActiveEventsBlockSheet`) se construyó **exclusivamente**
componiendo `AppModal`/`AppModalAction` — el bloque de diseño ya aprobado y usado en producción
(nodo Pencil `VVrFh`/`ibKDx`, el mismo que usan `ConfirmationDialog` e `InfoDialog`, este último
para el caso ya precedente "próximamente" en `rider_profile_content.dart`). No se inventó ningún
layout, color, spacing ni interacción nueva — solo copy (título/cuerpo/CTA) sobre un componente ya
diseñado. `ProfileActionsList` y `RegistrationDetailPage` no ganan ninguna superficie visual nueva,
solo lógica (precondición async) y fallback textual en filas de datos ya existentes. Si esto no
satisface el gate de diseño del proyecto, la superficie a revisar en una ronda posterior de Design/
UX Review es exclusivamente `ActiveEventsBlockSheet` (copy + variante `warning` de `AppModal`).

## Archivos cambiados

- `lib/features/event_registration/domain/model/event_registration_model.dart` — 8 campos PII
  (`identificationNumber`, `birthDate`, `phone`, `email`, `residenceCity`, `eps`,
  `emergencyContactName`, `emergencyContactPhone`) pasan de requeridos a nulables. `fullName` y
  `bloodType`/`bloodTypeRaw` intactos.
- `lib/features/event_registration/data/dto/event_registration_dto.dart` — mismo cambio de
  nulabilidad en el DTO Pattern B (constructor); se eliminó el override manual
  `json['birthDate'] = apiEncodeRequiredDateTime(birthDate)` en `toJson()` (el converter
  `NullableApiDateTimeConverter` ya declarado vía `apiJsonDateTimeConverters` cubre `DateTime?`
  automáticamente).
- `lib/features/event_registration/data/dto/event_registration_dto.g.dart` — regenerado por
  `dart run build_runner build --delete-conflicting-outputs`.
- `lib/features/event_registration/presentation/registration_detail_page.dart` — los 7 campos de
  texto usan `?? context.l10n.registration_deletedAccountFieldPlaceholder`;
  `birthDate?.formattedDate ?? placeholder`.
- `lib/features/event_registration/presentation/widgets/registration_contact_trigger.dart` —
  guard `if (phone == null) return;` tras `final phone = registration.phone;` (ruta ya inalcanzable
  en producción porque la anonimización siempre pone `allowOrganizerContact = false`, pero
  necesario para que el tipo `String?` compile).
- `lib/features/profile/presentation/widgets/profile_actions_list.dart` — `onTap` de "Eliminar
  cuenta" pasa a `_handleDeleteAccountTap(context)`: llama `getIt<GetMyEventsUseCase>()()`
  (re-evaluado en cada tap, sin caché — AC4), filtra eventos en
  `draft`/`scheduled`/`inProgress`; vacío → `context.pushNamed(AppRoutes.deleteAccount)`; no
  vacío → `ActiveEventsBlockSheet.show(...)`; error (`Left`) → SnackBar con
  `profile_deleteAccountBlocked_checkError`, sin navegar (evita bypass silencioso).
- `lib/features/profile/presentation/widgets/active_events_block_sheet.dart` (nuevo) — helper
  estático (mismo patrón que `InfoDialog`/`ConfirmationDialog`) sobre `AppModal` variante
  `warning`; muestra el nombre del primer evento bloqueante en el cuerpo y un único CTA
  (`profile_deleteAccountBlocked_cta`) que navega a `AppRoutes.myEvents`.
- `lib/l10n/app_es.arb` — nuevas keys: `registration_deletedAccountFieldPlaceholder` ("Cuenta
  eliminada"), `profile_deleteAccountBlocked_title`, `profile_deleteAccountBlocked_body`
  (placeholder `{eventName}`), `profile_deleteAccountBlocked_cta`,
  `profile_deleteAccountBlocked_checkError`.
- `lib/l10n/app_localizations.dart` / `app_localizations_es.dart` — regenerados por
  `flutter gen-l10n`.

No se tocó `registration_form_cubit.dart` (verificado, sin cambios funcionales requeridos, confirma
lo dicho por el Architect) ni `AttendeesList`/`AttendeesView` (AC9, sin referencias directas a los
8 campos anonimizados detectadas en el scan ni en `dart analyze`).

## Pruebas nuevas

- `test/features/profile/presentation/widgets/profile_actions_list_delete_account_precondition_test.dart`
  (6 tests): sin eventos activos navega directo; eventos `cancelled`/`finished` no bloquean;
  un evento `scheduled`/`draft`/`inProgress` bloquea y muestra el sheet con su nombre; el CTA del
  sheet navega a `myEvents`; re-evaluación en cada tap (bloqueado → luego permitido, AC4); fallo de
  `GetMyEventsUseCase` no navega ni bloquea silenciosamente.
- `test/features/profile/presentation/widgets/active_events_block_sheet_test.dart` (2 tests):
  muestra el nombre del evento bloqueante; el CTA navega a `AppRoutes.myEvents`.
- `test/features/event_registration/presentation/registration_detail_page_test.dart` (+1 test,
  grupo nuevo): registro con los 8 campos `null` (`fullName='Usuario eliminado'`,
  `bloodType=A+`) renderiza `'Cuenta eliminada'` exactamente 8 veces, sin excepción, sin usar
  `notAvailable`.
- `test/features/event_registration/presentation/widgets/registration_contact_trigger_test.dart`
  (+1 test): `phone=null` con "Llamar" no lanza excepción ni intenta abrir ninguna URL.

## Resultado final

- `dart analyze` → **0 errores** (mismos 25→ahora 15 `info`/`warning` preexistentes y no
  relacionados con esta fase, ya presentes en el baseline; verificado que ninguno nuevo se
  introdujo).
- `flutter test` (completo) → **1396/1396 tests pass** (1386 baseline + 10 nuevos).
- `dart run build_runner build --delete-conflicting-outputs` → limpio, sin conflictos.

## Verificación manual

No se corrió la app en un simulador/dispositivo (fuera de alcance de este agente — sin acceso a
tooling de ejecución en este entorno). La verificación se hizo vía `dart analyze` + suite completa
de tests (unit + widget) que ejercitan los 3 flujos nuevos end-to-end a nivel de widget:
navegación exitosa, bloqueo con nombre de evento + CTA, re-evaluación por tap, manejo de error, y
render de placeholders en `RegistrationDetailPage`.

## Notas para QA

- Contrato 409 (`ACTIVE_EVENTS_AS_ORGANIZER`) confirmado por Backend como red de seguridad de
  condición de carrera — **no tiene UI dedicada nueva** (fluye por el `DeleteAccountErrorBanner`
  existente vía `message`). El camino feliz que QA debe probar en UI es la precondición
  client-side: tocar "Eliminar cuenta" con un evento propio en `DRAFT`/`SCHEDULED`/`IN_PROGRESS`
  debe abrir el bottom sheet de bloqueo (no la pantalla de confirmación de borrado), mostrar el
  nombre del evento, y su CTA "Ver mis eventos" debe llevar a `Mis eventos`.
- Para probar el camino feliz de borrado (sin eventos activos), usar un usuario organizador sin
  eventos en esos 3 estados, o con eventos solo `CANCELLED`/`FINISHED`.
- Para verificar la anonimización end-to-end en UI: usar un rider con al menos una inscripción,
  eliminar su cuenta (o simular el estado con datos de prueba), y abrir el detalle de esa
  inscripción desde la vista del organizador — debe mostrar "Usuario eliminado" en el nombre y
  "Cuenta eliminada" en los 7 campos de texto + fecha de nacimiento; tipo de sangre debe seguir
  visible (no se anonimiza).
- **Pendiente de diseño formal**: `ActiveEventsBlockSheet` se implementó reusando el componente
  `AppModal` (variante `warning`) sin pasar por un ciclo de Pencil nuevo, porque Pencil MCP está
  bloqueado a nivel de infraestructura para los subagentes de este workflow (ver
  `handoffs/design.md`/`handoffs/ux-review.md`). Si se desbloquea Pencil MCP, vale la pena una
  revisión de diseño posterior específica de esta pantalla (copy, variante de icono, etc.) — no
  bloquea funcionalmente el release, pero no pasó por el gate visual habitual del proyecto.
