# Architect → Frontend — eliminacion-cuenta-phase-03

Contrato completo: `handoffs/architect.md`. Este archivo es el resumen accionable para
`Rideglory` (Flutter).

**Nota de proceso**: `active_events_block_sheet.dart` es una pantalla/componente nuevo — por la
regla del proyecto ("UI: diseñar antes de implementar"), diseñar primero en Pencil
(`rideglory.pen`, el único archivo de diseño), esperar aprobación explícita, y solo entonces
implementar. Si el gate de UX Review / Pencil ya corrió en una fase previa de este pipeline y
aprobó este componente, seguir esa aprobación; si no, no lo saltes.

## 1. Precondición en `ProfileActionsList` (AC1, AC2, AC4, AC12)

`lib/features/profile/presentation/widgets/profile_actions_list.dart` — el `onTap` del ítem
"Eliminar cuenta" pasa de `() => context.pushNamed(AppRoutes.deleteAccount)` a un método
async local (mismo patrón que `_logout`):

```dart
Future<void> _handleDeleteAccountTap(BuildContext context) async {
  final result = await getIt<GetMyEventsUseCase>()();
  // result: Either<DomainException, List<EventModel>>
  // filtrar eventos con state == draft | scheduled | inProgress
  // si vacío → context.pushNamed(AppRoutes.deleteAccount)
  // si no vacío → mostrar ActiveEventsBlockSheet.show(context, activeEvents: [...])
  // si Left (error) → no navegar, no bloquear silenciosamente (evita bypass);
  //   feedback exacto (SnackBar u otro) a tu criterio, no hay AC que lo especifique
}
```

`getIt<GetMyEventsUseCase>()` es el patrón correcto aquí (no es un Cubit, es un caso de uso sin
estado — mismo patrón que `vehicle_rtm_form_slot.dart`/`attendees_page.dart`). **No** llames a
`DeleteAccountUseCase`/`deleteMyAccount()` en este flujo — solo `GetMyEventsUseCase`. Esto es
exactamente la misma llamada que dispara `EventsPage(showMyEvents: true)` (AC12).

La re-evaluación es en cada `onTap`, no cachear el resultado entre taps (AC4).

## 2. `ActiveEventsBlockSheet` (nuevo widget, un archivo, sin métodos que retornan widgets)

`lib/features/profile/presentation/widgets/active_events_block_sheet.dart` — bottom sheet
dedicado (NO `ConfirmationDialog` genérico, PRD explícito). Debe mostrar al menos el nombre de
un evento bloqueante (AC3) y un CTA que navegue a `AppRoutes.myEvents` al tocarlo (AC3). Revisa
`lib/shared/widgets/modals/` para el patrón de bottom sheet existente en el proyecto antes de
crear uno desde cero (p.ej. estructura de `AppModalVariant`/bottom sheets ya usados en
`VehicleSelectionBottomSheet`).

## 3. `EventRegistrationModel` / DTO — nulabilidad (AC6, AC10, AC11)

`lib/features/event_registration/domain/model/event_registration_model.dart` — cambiar de
requeridos a nulables (`?`): `identificationNumber`, `birthDate`, `phone`, `email`,
`residenceCity`, `eps`, `emergencyContactName`, `emergencyContactPhone`. **NO** tocar
`fullName` (sigue requerido — el backend siempre escribe `'Usuario eliminado'`, nunca `null`).
**NO** tocar `bloodType`/`bloodTypeRaw` (guardrail explícito).

`lib/features/event_registration/data/dto/event_registration_dto.dart` — mismo cambio en
`EventRegistrationDto` (constructor, `fromJson`, extensión `toJson()`). Al hacer `birthDate`
nulable, **elimina** la línea `json['birthDate'] = apiEncodeRequiredDateTime(birthDate);` del
`toJson()` override — el converter `NullableApiDateTimeConverter` (ya declarado vía
`apiJsonDateTimeConverters` en el `@JsonSerializable` de la clase) cubre `DateTime?`
automáticamente sin código extra.

Después: `dart run build_runner build --delete-conflicting-outputs` (regenera `.g.dart`),
luego `dart analyze` (debe salir limpio, AC11).

## 4. Sitios de uso a actualizar (búsqueda amplia ya hecha por Architect, confírmala tú también)

- `lib/features/event_registration/presentation/registration_detail_page.dart`: cada uno de los
  7 campos de texto (`identificationNumber`, `phone`, `email`, `residenceCity`, `eps`,
  `emergencyContactName`, `emergencyContactPhone`) necesita
  `?? context.l10n.registration_deletedAccountFieldPlaceholder` en el `value:` del
  `RegistrationDetailDataRow` correspondiente. `birthDate` es el caso especial explícito del
  PRD: `registration.birthDate?.formattedDate ?? context.l10n.registration_deletedAccountFieldPlaceholder`.
  **No reuses `context.l10n.notAvailable`** — key nueva y dedicada (guardrail explícito, AC10).

- `lib/features/event_registration/presentation/widgets/registration_contact_trigger.dart`:
  línea `final phone = registration.phone;` (ahora `String?`) — añade
  `if (phone == null) return;` justo después, antes de usarlo en
  `UrlLauncherHelper.openPhone(phone)`/`openWhatsApp(phone)`. Esta ruta ya está protegida en la
  práctica por `!registration.allowOrganizerContact` en `build()` (la anonimización siempre
  pone `allowOrganizerContact = false`), pero el guard es necesario para que el tipo compile.

- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`: revisado
  por Architect — no requiere cambios funcionales (el formulario sigue construyendo/validando
  como requerido; los campos ahora nulables del modelo son compatibles con valores no-nulos
  asignados). Verifica igual con `dart analyze` tras el cambio.

- **AC9** (`AttendeesList`/`AttendeesView`): `fullName` **no** cambia de tipo — no debería
  requerir cambios, pero verifica que no haya ningún crash al renderizar una fila con los otros
  campos nulos si algún widget de esa lista los toca indirectamente (no detectado en el scan,
  pero confírmalo).

## 5. Localización

`lib/l10n/app_es.arb` — nuevas keys (prefijo por feature, cero hardcodeo):
- `registration_deletedAccountFieldPlaceholder`: `"Cuenta eliminada"` (texto exacto del PRD,
  AC10).
- `profile_deleteAccountBlocked_*` (título, cuerpo con al menos el nombre del evento, CTA) —
  nombres exactos a tu criterio siguiendo la convención ya usada
  (`profile_deleteAccount_introTitle`, etc.).

Luego `flutter gen-l10n` (o `build_runner build`) para regenerar
`app_localizations.dart`/`app_localizations_es.dart` — no editar a mano.

## 6. Manejo del 409 residual (condición de carrera, AC5 lado cliente)

**No crear** `active_events_as_organizer_exception.dart` ni ningún manejo especial nuevo en
`DeleteAccountUseCase`/`user_repository_impl.dart`/`DeleteAccountCubit`. El backend responderá
el 409 con `{ error, message, activeEvents }`, y el `message` humano ya fluye por el manejo
genérico existente (`rest_client_functions.dart` → `_extractResponseMessage` prioriza
`message`) hasta el `DeleteAccountErrorBanner` que ya existe en
`DeleteAccountConfirmationPage`. Esto es intencional — la precondición client-side (punto 1)
ya cubre el camino feliz; este 409 es solo la red de seguridad de la condición de carrera y no
necesita UI dedicada nueva.

## Guardrails específicos

- Cero widgets-que-retornan-widgets en `active_events_block_sheet.dart` — clase propia, un
  archivo.
- Cero strings hardcodeados — todo vía `context.l10n.<key>`.
- No introducir ningún endpoint de "chequeo" nuevo — solo `GetMyEventsUseCase`.
- Verifica con `flutter test test/features/event_registration/` y
  `flutter test test/features/profile/` tras los cambios.
