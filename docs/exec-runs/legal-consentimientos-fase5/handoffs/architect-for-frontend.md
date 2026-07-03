> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend — legal-consentimientos-fase5

## Pre-flight ya verificado (no repetir)
- `EventModel.organizerAcceptedResponsibilityAt: DateTime?` y `UserModel.medicalConsentAcceptedAt: DateTime?` ya existen. NO tocar `EventDto`/`UserDto`/`event_model.dart`/`user_model.dart`.
- `POST /users/me/medical-consent` ya existe en backend. Body requerido: `{ "consentVersion": string }` (no vacío). Respuesta: `{ "medicalConsentAcceptedAt": "<ISO8601>" }`. Usa una constante versionada, p.ej. `const medicalConsentVersion = 'v0.1-2026-06'` (mismo esquema que `RegistrationFormCubit.riskAcceptanceVersion` que ya existe en el árbol).

## Bloque A — Responsabilidad del organizador

1. `EventFormCubit` (modify): agrega `void setOrganizerResponsibility(DateTime acceptedAt)` — guarda el timestamp en el state (o simplemente úsalo directo en el `copyWith` del `EventModel`, ver punto 3). No reemplaza `saveEvent`.
2. `organizer_responsibility_extra.dart` (create) en `lib/features/events/presentation/form/`: clase de transporte con `EventFormCubit cubit`, `FormImageCubit imageCubit`, `EventModel eventToSave`.
3. `event_organizer_responsibility_page.dart` (create): recibe `OrganizerResponsibilityExtra` vía `state.extra`. Envuelve el contenido en `MultiBlocProvider` con `BlocProvider.value` para AMBOS cubits (crítico: reusar instancias, no `getIt<EventFormCubit>()`). Botón "Acepto y publico el evento":
   ```dart
   final acceptedAt = DateTime.now(); // captura ÚNICA, se reusa abajo
   cubit.saveEvent(
     eventToSave.copyWith(organizerAcceptedResponsibilityAt: acceptedAt),
     localCoverImagePath: ...,
     remoteCoverImageUrl: ...,
   );
   ```
   Escucha `saveResult`: en `data`, esta pantalla hace `context.pop()` (un solo pop, en el listener). En `error`, `Text` inline `colorScheme.error`, sin pop, botones re-habilitados. Botón "Revisar evento": `context.pop()` sin llamar `saveEvent`.
4. `publish_row.dart` (modify): en `_onPublish`, si `event == null` mantén el SnackBar `event_formIncompleteMessage` (verifica si ya existe esa lógica antes de duplicarla). Si `event != null` y `!cubit.isEditing`, en vez de `cubit.saveEvent(...)` directo: `context.pushNamed(AppRoutes.organizerResponsibility, extra: OrganizerResponsibilityExtra(cubit: cubit, imageCubit: imageCubit, eventToSave: event))`. Modo edición: SIN CAMBIOS (rama `if (cubit.isEditing)` intacta).
5. `EventFormView` YA tiene el listener que hace el segundo pop protegido con `if (context.canPop()) context.pop(event)` en la rama no-editing — no lo toques, es el mecanismo de doble-pop (AC#5), depende de que ambos widgets compartan el mismo cubit (punto 3).

## Bloque B — Autorización Ley 1581

1. `medical_consent_response_dto.dart` (create) en `lib/features/users/data/dto/`: response-only, un campo `medicalConsentAcceptedAt: DateTime` no-nullable. Comentar como excepción documentada a Pattern B.
2. `UserService` (modify): `@POST(ApiRoutes.meMedicalConsent) Future<MedicalConsentResponseDto> acceptMedicalConsent(@Body() Map<String, dynamic> body);`. Regenerar `user_service.g.dart` con `dart run build_runner build --delete-conflicting-outputs`.
3. `UserRepository`/`UserRepositoryImpl` (modify): `Future<Either<DomainException, DateTime>> acceptMedicalConsent(String consentVersion)` → `executeService(function: () => _userService.acceptMedicalConsent({'consentVersion': consentVersion}))`, mapea a `.medicalConsentAcceptedAt`.
4. `UserStorageService` (modify): `getMedicalConsentAcceptedAt()` / `setMedicalConsentAcceptedAt(DateTime)` bajo clave `medical_consent_accepted_at` SIN prefijo de uid (dato de dispositivo, mismo patrón que `_analyticsEnabledKey`). Usa `FlutterSecureStorage` — nunca `SharedPreferences`.
5. `medical_consent_cubit.dart` (create) en `lib/features/event_registration/presentation/cubit/`: `@injectable`, `Cubit<ResultState<DateTime>>`. Método `accept()`: llama `UserRepository.acceptMedicalConsent(medicalConsentVersion)`, en éxito persiste con `UserStorageService.setMedicalConsentAcceptedAt`. Método `Future<bool> hasCachedConsent()`: `UserStorageService.getMedicalConsentAcceptedAt() != null`.
6. `medical_consent_page.dart` (create) en `lib/features/event_registration/presentation/wizard/`: `AppButton` "Autorizar" (`isLoading` mientras el POST está en curso) → en éxito `context.pop(true)`. `AppTextButton` "No autorizar" → SnackBar `registration_law1581DeclinedMessage`, `context.pop(false)`, SIN llamar HTTP. Error de red → SnackBar de error, botón re-habilitado.
7. `registration_form_content.dart` (modify, archivo YA con diff sin commitear de otra fase — no revertir esos cambios): en `_onNext()`, si `_wizard.currentStep == 0` y el step es válido, ANTES de `_wizard.next()`:
   ```dart
   if (_wizard.currentStep == 0 && isStepValid) {
     final consentCubit = context.read<MedicalConsentCubit>();
     if (!await consentCubit.hasCachedConsent()) {
       final authorized = await context.pushNamed<bool>(AppRoutes.medicalConsent);
       if (authorized != true) return; // no avanza, no doble-tap
     }
   }
   _wizard.next();
   ```
   Usa un flag `_isNavigating` (o reusa el patrón `isLoading` visual del botón "Siguiente") para bloquear doble-tap mientras el `await` está en curso.

## Routing (compartido, tocar UNA vez)
- `app_routes.dart`: `static const String organizerResponsibility = '/events/organizer-responsibility';` y `static const String medicalConsent = '/events/registration/medical-consent';` (o el path que prefieras, mientras sea absoluto y único).
- `app_router.dart`: 2 `GoRoute` NUEVOS, hermanos del `StatefulShellRoute` (mismo nivel que `AppRoutes.createVehicle`), `parentNavigatorKey: _rootNavigatorKey`. NUNCA anidados dentro del shell — riesgo R6 explícito en la fuente.
- `api_routes.dart`: `static const meMedicalConsent = '/users/me/medical-consent';`.

## l10n
10 claves nuevas en `app_es.arb` (coordinar con el diff ya en progreso, no pisar claves existentes): 5 Bloque A (ej. `event_organizerResponsibility_title/body/acceptButton/reviewButton/errorGeneric`), 5 Bloque B (ej. `registration_law1581_title/body/authorizeButton/declineButton`, `registration_law1581DeclinedMessage`). Ejecutar `flutter gen-l10n` después.

## Orden sugerido
1. Routing + api_routes constants → 2. Capa datos Bloque B (DTO → Service → build_runner → Repository → Storage) → 3. Bloque A completo → 4. Bloque B presentación completo → 5. ARB + gen-l10n → 6. build_runner final → 7. tests.

> Full detail: handoffs/architect.md
