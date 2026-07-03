# Frontend → QA — legal-consentimientos-fase5

## Baseline

- `flutter test` (antes de tocar código): **946/946 pass**.
- `dart analyze`: limpio antes de empezar.
- Nota: el árbol ya traía cambios sin commitear de otra fase concurrente
  (`waiver-inscripcion-registro`) tocando `registration_form_content.dart`,
  `registration_medical_step.dart`, `app_es.arb`, tests de
  `registration_form_cubit_*`, etc. No se revirtió nada de eso; los cambios de
  esta fase se aplicaron encima, coordinando las claves nuevas del ARB para no
  pisar las ya en progreso.

## Archivos cambiados

### Routing (compartido)
- `lib/shared/router/app_routes.dart` — 2 constantes nuevas:
  `organizerResponsibility` (`/events/organizer-responsibility`),
  `medicalConsent` (`/events/registration/medical-consent`).
- `lib/core/http/api_routes.dart` — `meMedicalConsent = '/users/me/medical-consent'`.
- `lib/shared/router/app_router.dart` — 2 `GoRoute` nuevos, hermanos del
  `StatefulShellRoute`, `parentNavigatorKey: _rootNavigatorKey`.

### Bloque B — datos (Ley 1581)
- `lib/features/users/data/dto/medical_consent_response_dto.dart` (nuevo) —
  DTO response-only, excepción documentada a Pattern B (sin modelo de dominio
  1:1; solo transporta `medicalConsentAcceptedAt`).
- `lib/features/users/data/service/user_service.dart` +
  `user_service.g.dart` (regenerado) — `acceptMedicalConsent(body)`.
- `lib/features/users/domain/repository/user_repository.dart` +
  `lib/features/users/data/repository/user_repository_impl.dart` —
  `acceptMedicalConsent(consentVersion)` → `Either<DomainException, DateTime>`.
- `lib/core/services/user_storage_service.dart` — `getMedicalConsentAcceptedAt()`
  / `setMedicalConsentAcceptedAt(DateTime)`, clave `medical_consent_accepted_at`
  sin prefijo de uid (mismo patrón que `_analyticsEnabledKey`), en
  `FlutterSecureStorage`.

### Bloque B — presentación
- `lib/features/event_registration/presentation/cubit/medical_consent_cubit.dart`
  (nuevo) — `@injectable Cubit<ResultState<DateTime>>`; `accept()` llama al
  repo y cachea en éxito; `hasCachedConsent()` lee el storage. Constante
  `medicalConsentVersion = 'v0.1-2026-06'`.
- `lib/features/event_registration/presentation/wizard/medical_consent_page.dart`
  (nuevo) — wrapper `BlocProvider(create: getIt<MedicalConsentCubit>())`.
- `lib/features/event_registration/presentation/wizard/medical_consent_view.dart`
  (nuevo) — contenido real (separado del wrapper para respetar la regla de
  "un widget por archivo"; el wrapper y la vista no pueden coexistir como dos
  clases `Widget` en el mismo archivo). "Autorizar" (`AppButton`, `isLoading`)
  → `accept()` → éxito `pop(true)`; "No autorizar" (`AppTextButton`) → SnackBar
  `registration_law1581DeclinedMessage` + `pop(false)`, sin HTTP; error → SnackBar,
  sin pop, botón reactivado.
- `lib/features/event_registration/presentation/event_registration_page.dart` —
  ahora provee también `MedicalConsentCubit` (antes solo `RegistrationFormCubit`)
  vía `MultiBlocProvider`, para que `RegistrationFormContent` pueda leerlo con
  `context.read`.
- `lib/features/event_registration/presentation/registration_form_content.dart` —
  `_onNext()` ahora es `async`; al avanzar del step 0 al 1, si
  `!hasCachedConsent()`, hace `pushNamed<bool>(AppRoutes.medicalConsent)` y solo
  continúa si `authorized == true`. Flag `_isCheckingConsent` bloquea doble-tap
  y se refleja en `isLoading` de la barra de navegación.

### Bloque A — presentación (responsabilidad del organizador)
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` —
  campo `organizerResponsibilityAcceptedAt` en `EventFormState` +
  `setOrganizerResponsibility(DateTime)` (solo registra el timestamp en state,
  no dispara guardado).
- `lib/features/events/presentation/form/organizer_responsibility_extra.dart`
  (nuevo) — clase de transporte `{cubit, imageCubit, eventToSave}` para
  `state.extra`.
- `lib/features/events/presentation/form/event_organizer_responsibility_page.dart`
  (nuevo) — wrapper que reprovee `EventFormCubit`/`FormImageCubit` (mismas
  instancias, vía `BlocProvider.value`) para no romper el doble-pop de
  `EventFormView`.
- `lib/features/events/presentation/form/widgets/event_organizer_responsibility_view.dart`
  (nuevo) — contenido real (mismo motivo de separación que en Bloque B).
  "Acepto y publico el evento" captura `DateTime.now()` una sola vez, llama
  `setOrganizerResponsibility` + `saveEvent(eventToSave.copyWith(...))`; en
  éxito (`saveResult.data`) hace **un solo** `context.pop()` — el segundo pop
  (cierre del wizard) lo sigue haciendo `EventFormView`, sin tocar ese archivo.
  En error: texto inline `colorScheme.error`, sin pop, botones reactivados.
  "Revisar evento": `context.pop()` sin llamar `saveEvent`.
- `lib/features/events/presentation/form/widgets/steps/publish_row.dart` —
  en modo creación, `_onPublish` ya no llama `saveEvent` directo: navega a
  `AppRoutes.organizerResponsibility` con `OrganizerResponsibilityExtra`. Modo
  edición sin cambios (rama separada, no pasa por `_onPublish`).

### l10n
- `lib/l10n/app_es.arb` — 10 claves nuevas: 5 `event_organizerResponsibility_*`
  (title/body/acceptButton/reviewButton/errorGeneric) y 5
  `registration_law1581_*` (title/body/authorizeButton/declineButton) +
  `registration_law1581DeclinedMessage`. Regenerado con `flutter gen-l10n`
  (`app_localizations.dart` / `app_localizations_es.dart`).

### Generado
- `dart run build_runner build --delete-conflicting-outputs` — regeneró
  `user_service.g.dart`, `medical_consent_response_dto.g.dart`,
  `injection.config.dart` (registro de `MedicalConsentCubit`),
  `event_form_cubit.freezed.dart` (campo nuevo en el state).

## Pruebas nuevas

- `test/features/events/presentation/form/cubit/event_form_cubit_organizer_responsibility_test.dart`
  (nuevo, 3 tests) — `setOrganizerResponsibility` guarda el timestamp, no
  toca `saveResult`, sobrescribe valor previo.
- `test/features/events/presentation/form/widgets/steps/publish_row_test.dart`
  (nuevo, 3 tests) — creación: navega a `organizerResponsibility` en vez de
  guardar (con `GoRouter` real + extra tipado); no navega si el form es
  inválido; edición: sin cambios, sin navegación.
- `test/features/events/presentation/form/event_organizer_responsibility_page_test.dart`
  (nuevo, 3 tests) — aceptar (setOrganizerResponsibility + saveEvent con
  `organizerAcceptedResponsibilityAt` capturado + pop en éxito), error (texto
  inline, sin pop, botón reactivado — se reintenta), revisar (pop sin guardar).
- `test/features/event_registration/presentation/cubit/medical_consent_cubit_test.dart`
  (nuevo, 4 tests, `bloc_test`) — accept éxito (`[loading, data]` + cachea),
  accept error (`[loading, error]`, no cachea), `hasCachedConsent` true/false.
- `test/features/event_registration/presentation/wizard/medical_consent_page_test.dart`
  (nuevo, 3 tests) — autorizar (accept() + pop(true)), no autorizar (SnackBar +
  pop(false), sin HTTP), error (SnackBar, sin pop, botón reactivado — se
  reintenta).
- `test/core/services/user_storage_service_test.dart` (nuevo, 4 tests) —
  get/set de `medical_consent_accepted_at` (ausente, vacío, parseo ISO8601,
  escritura sin prefijo de uid).

Total: **20 tests nuevos**. Suite completa tras los cambios: **966/966 pass**
(946 baseline + 20 nuevos), `dart analyze` limpio.

## Resultado final

- `flutter test`: 966/966 pass.
- `dart analyze`: sin issues.
- `flutter gen-l10n` y `dart run build_runner build --delete-conflicting-outputs`
  ejecutados sin errores tras los cambios de ARB/DTO/DI/freezed.

## Verificación manual

Pendiente de un humano con emulador/dispositivo (no se pudo levantar el app en
este entorno de agente):

1. **Bloque A (organizador):** crear un evento nuevo hasta el step de revisión,
   tocar "Publicar evento" → debe aparecer la pantalla de responsabilidad del
   organizador (no debe guardar todavía). Tocar "Acepto y publico el evento":
   loading → SnackBar de éxito del wizard original → wizard se cierra (doble
   pop). Repetir forzando un error de red (airplane mode) para confirmar texto
   inline y que el evento NO se publica. Tocar "Revisar evento" para confirmar
   que vuelve al step de revisión sin publicar nada.
2. **Modo edición de evento:** confirmar que el botón "Cerrar" del step 4 sigue
   funcionando igual que antes (sin pasar por la pantalla nueva).
3. **Bloque B (Ley 1581):** iniciar una inscripción nueva, llenar el step de
   datos personales, tocar "Siguiente" → debe aparecer la pantalla de
   autorización (solo la primera vez en el dispositivo). "Autorizar" → avanza
   al step médico. Cerrar la app y reabrir inscripción: no debe volver a pedir
   autorización (queda cacheada en `FlutterSecureStorage`). Desinstalar/limpiar
   storage para verificar que sí vuelve a pedirla.
4. **Declinar autorización:** tocar "No autorizar" → SnackBar + el wizard se
   queda en el step 0 (no avanza).
5. **Error de red en autorización:** forzar error → SnackBar de error, botón
   reactivado, reintentar debe funcionar.
6. Confirmar visualmente que ninguna de las dos pantallas nuevas usa texto
   blanco sobre el acento naranja (regla de contraste del proyecto) — ambas
   usan `AppButton`/`AppTextButton` estándar, no fondos custom con `primary`.

## Notas para QA

- **Diseño (Pencil) bloqueado en esta corrida** — ver `handoffs/design.md`. Las
  dos pantallas nuevas (`EventOrganizerResponsibilityPage`,
  `MedicalConsentPage`) se implementaron siguiendo el patrón visual existente
  del wizard de inscripción (mismo estilo que `registration_waiver_sheet.dart`
  y los step widgets: `AppButton`/`AppTextButton`, tipografía y colores
  `AppColors.textOnDarkSecondary`/`context.colorScheme.error`) porque no había
  mockups disponibles. **Recomendado**: correr `ux-review` sobre estas dos
  pantallas en cuanto Pencil se desbloquee, ya que no pasaron por el gate de
  diseño/UX de esta fase.
- **No hay test de widget para el interceptor completo de
  `RegistrationFormContent._onNext()`** (el que decide si empujar
  `medicalConsent` antes de avanzar del step 0). Se cubrió indirectamente vía
  `MedicalConsentCubit` (unit) y `MedicalConsentPage`/`MedicalConsentView`
  (widget), pero no hay una prueba end-to-end del wizard completo saltando al
  step 1 tras autorizar. El harness de `RegistrationFormContent` requiere
  proveer `RegistrationFormCubit` + `VehicleCubit` + `MyRegistrationsCubit` +
  `MedicalConsentCubit` + un `FormBuilder` ancestro real — se dejó fuera de
  esta fase por costo/beneficio; recomendado como caso Patrol e2e en
  `qa-auto` (step 0 → autorizar → step 1; step 0 → declinar → se queda en
  step 0).
- La versión de consentimiento está hardcodeada
  (`medicalConsentVersion = 'v0.1-2026-06'`, mismo esquema que
  `RegistrationFormCubit.riskAcceptanceVersion`). Si el texto legal de
  `registration_law1581_body` cambia en el futuro, hay que bumpear esta
  constante para que las aceptaciones sigan siendo auditables.
- El campo `medical_consent_accepted_at` es **de dispositivo**, no de usuario
  (no lleva prefijo de uid). Si el mismo dispositivo se usa para dos cuentas
  distintas, la segunda cuenta no volverá a pedir autorización aunque nunca la
  haya dado explícitamente en el backend — esto replica exactamente el patrón
  ya existente de `analytics_enabled` y fue una decisión explícita del
  architect handoff, pero vale la pena que QA lo valide con un caso de
  multi-cuenta en el mismo dispositivo.
- `event_organizerResponsibility_errorGeneric` es un mensaje genérico (no
  interpola `error.message` del backend), a diferencia de otros flujos del
  wizard de eventos que sí muestran el mensaje del backend
  (`context.l10n.errorMessage(error.message)`). Fue una decisión deliberada
  para mantener el nombre de la clave literal ("genérico") pedido por el
  architect handoff; si QA prefiere mostrar el mensaje real del backend, es un
  cambio de una línea en `event_organizer_responsibility_view.dart`.
