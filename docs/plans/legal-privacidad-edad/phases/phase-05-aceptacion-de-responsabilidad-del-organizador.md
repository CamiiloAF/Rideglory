# Fase 5 — Consentimientos legales: responsabilidad del organizador y autorización Ley 1581

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T20:06:03Z
**Nivel:** normal
**dependsOn:** [1, 3]

> Esta fase fusiona las anteriores Fases 5 y 6 del plan original. Ambas entregan una pantalla de consentimiento legal con interceptor en un flujo existente, dependen solo de [1] y [3], y no se bloquean entre sí. Los archivos `app_routes.dart`, `app_router.dart` y `app_es.arb` se tocan una sola vez al final.

---

## Objetivo

Implementar los dos consentimientos legales que la app requiere:

1. **Responsabilidad del organizador:** Un organizador no puede publicar un evento sin leer y aceptar una declaración de responsabilidad legal. El timestamp (`organizerAcceptedResponsibilityAt`) viaja en el payload de creación. Solo aplica en creación nueva; la edición no cambia.

2. **Autorización Ley 1581:** El rider da consentimiento expreso bajo la Ley 1581 (protección de datos personales) antes de que sus datos médicos sean tratados en el contexto de una inscripción. Se persiste en backend (fuente de verdad) y en `FlutterSecureStorage` via `UserStorageService` (offline-first). Una vez dado, el wizard no vuelve a interrumpirse.

---

## Alcance

### Entra

**Bloque A — Responsabilidad del organizador**
- Nueva pantalla `EventOrganizerResponsibilityPage` en `lib/features/events/presentation/form/`.
- Clase `OrganizerResponsibilityExtra` como contrato de transporte entre `PublishRow` y el router.
- Intercepción del botón "Publicar evento" en `PublishRow` (solo `cubit.isEditing == false`).
- Método `setOrganizerResponsibility(DateTime)` en `EventFormCubit`.
- Constante `AppRoutes.organizerResponsibility` y su `GoRoute` (raíz, path absoluto).

**Bloque B — Autorización Ley 1581**
- Nueva pantalla `MedicalConsentPage` en `lib/features/event_registration/presentation/wizard/`.
- Nuevo cubit `MedicalConsentCubit` (`@injectable`, no singleton).
- Nuevos métodos `acceptMedicalConsent` en `UserRepository`, `UserRepositoryImpl` y `UserService` (Retrofit).
- Nuevos métodos `getMedicalConsentAcceptedAt()` y `setMedicalConsentAcceptedAt(DateTime)` en `UserStorageService`.
- Nuevo DTO `MedicalConsentResponseDto` (response-only, sin modelo de dominio par).
- Nueva constante `ApiRoutes.meMedicalConsent`.
- Intercepción en `RegistrationFormContent._onNext()` al avanzar al paso médico (índice 0→1).
- Constante `AppRoutes.medicalConsent` y su `GoRoute` (raíz, path absoluto).

**Compartido (tocar una sola vez)**
- `lib/shared/router/app_routes.dart` — 2 constantes nuevas.
- `lib/shared/router/app_router.dart` — 2 `GoRoute` nuevos en lista raíz.
- `lib/l10n/app_es.arb` — 10 strings nuevos (5 por bloque).

### No entra
- Pantalla de responsabilidad en modo edición.
- Cambios a contratos backend o DTOs (Fases 1 y 3).
- Lógica de validación backend (Fase 1).
- Consentimiento Ley 1581 en `EditProfilePage`.
- Migración Prisma (Fase 1).
- Pantalla de revocación de consentimiento.
- Texto legal definitivo: placeholders v0 en ARB.

---

## Pre-flight obligatorio

1. Confirmar que `EventModelExtension.toJson()` incluye `organizerAcceptedResponsibilityAt` en el body del `POST /events`. Si no: **detener** — exigir que Fase 3 lo agregue.
2. Confirmar que `UserModel.medicalConsentAcceptedAt: DateTime?` existe (Fase 3 completada). Si no: **detener**.
3. Confirmar que `POST /users/me/medical-consent` existe en el backend (Fase 1 completada). Si no: **detener**.
4. `dart analyze` en estado limpio — registrar línea base de warnings.

---

## Qué se debe hacer

### BLOQUE A — Responsabilidad del organizador

#### A1 — Constante de ruta en `AppRoutes`

En `lib/shared/router/app_routes.dart`:
```dart
static const String organizerResponsibility = '/events/organizer-responsibility';
```

#### A2 — Clase `OrganizerResponsibilityExtra`

Crear `lib/features/events/presentation/form/organizer_responsibility_extra.dart`:

```dart
class OrganizerResponsibilityExtra {
  const OrganizerResponsibilityExtra({
    required this.eventFormCubit,
    required this.formImageCubit,
    required this.eventToSave,
    this.localCoverImagePath,
    this.remoteCoverImageUrl,
  });

  final EventFormCubit eventFormCubit;
  final FormImageCubit formImageCubit;
  final EventModel eventToSave;
  final String? localCoverImagePath;
  final String? remoteCoverImageUrl;
}
```

Los cubits se pasan del contexto de `PublishRow` — no se extraen con `getIt`.

#### A3 — Método en `EventFormCubit`

En `lib/features/events/presentation/form/cubit/event_form_cubit.dart`:

```dart
DateTime? _organizerAcceptedResponsibilityAt;

void setOrganizerResponsibility(DateTime acceptedAt) {
  _organizerAcceptedResponsibilityAt = acceptedAt;
}
```

No modificar `buildEventToSave()` — el campo llega al `EventModel` via `copyWith` en `_onAccept`.

#### A4 — Modificar `PublishRow._onPublish()`

```dart
Future<void> _onPublish(BuildContext context) async {
  final imageCubit = context.read<FormImageCubit>();
  final event = await cubit.buildEventToSave(); // una sola vez
  if (!context.mounted) return;

  if (event == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.event_formIncompleteMessage),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  final imageState = imageCubit.state;
  final imageData = imageState.whenOrNull(data: (data) => data);

  await context.pushNamed(
    AppRoutes.organizerResponsibility,
    extra: OrganizerResponsibilityExtra(
      eventFormCubit: cubit,
      formImageCubit: imageCubit,
      eventToSave: event,
      localCoverImagePath:
          imageData?.hasLocalImage == true ? imageData?.localImagePath : null,
      remoteCoverImageUrl:
          imageData?.hasLocalImage != true ? imageData?.remoteImageUrl : null,
    ),
  );
}
```

#### A5 — Crear `EventOrganizerResponsibilityPage`

Archivo: `lib/features/events/presentation/form/event_organizer_responsibility_page.dart`

`StatefulWidget` con `BlocConsumer<EventFormCubit, ResultState<EventModel>>`.

Estructura:
```
Scaffold
└── AppBar (back: AppTextButton "Revisar evento")
└── SafeArea
    └── Column
        ├── Expanded > SingleChildScrollView > Text(bodyV0)
        ├── [si Error] Text(error.message, colorScheme.error)
        ├── AppButton("Acepto y publico el evento", isLoading, _onAccept)
        └── AppTextButton("Revisar evento", context.pop)
```

Lógica `_onAccept`:
```dart
Future<void> _onAccept(BuildContext context) async {
  final cubit = context.read<EventFormCubit>();
  final now = DateTime.now(); // única fuente de verdad
  cubit.setOrganizerResponsibility(now);
  await cubit.saveEvent(
    widget.eventToSave.copyWith(organizerAcceptedResponsibilityAt: now),
    localCoverImagePath: widget.localCoverImagePath,
    remoteCoverImageUrl: widget.remoteCoverImageUrl,
  );
  // El BlocConsumer.listener hace el pop en éxito — no hacer pop aquí.
}
```

Mecanismo de cierre: la pantalla de responsabilidad hace **un** pop en su `listener` al detectar `Data`; `EventFormView` hace el segundo pop protegido con `if (context.canPop())`.

---

### BLOQUE B — Autorización Ley 1581

#### B1 — `ApiRoutes` y `UserService`

En `lib/core/http/api_routes.dart`:
```dart
static const meMedicalConsent = '/users/me/medical-consent';
```

En `lib/features/users/data/service/user_service.dart`:
```dart
@POST(ApiRoutes.meMedicalConsent)
Future<MedicalConsentResponseDto> acceptMedicalConsent(
  @Body() Map<String, dynamic> body,
);
```

Ejecutar `dart run build_runner build --delete-conflicting-outputs` para regenerar `user_service.g.dart`.

#### B2 — DTO de respuesta

Crear `lib/features/users/data/dto/medical_consent_response_dto.dart`:

```dart
class MedicalConsentResponseDto {
  const MedicalConsentResponseDto({required this.medicalConsentAcceptedAt});
  final DateTime medicalConsentAcceptedAt;

  factory MedicalConsentResponseDto.fromJson(Map<String, dynamic> json) {
    return MedicalConsentResponseDto(
      medicalConsentAcceptedAt: DateTime.parse(
        json['medicalConsentAcceptedAt'] as String,
      ),
    );
  }
}
```

> **Excepción a Pattern B:** DTO response-only sin modelo de dominio par — el dato se extrae directamente como `DateTime`. Excepción documentada en `.claude/rules/rideglory-coding-standards.mdc`.

#### B3 — `UserStorageService`

En `lib/core/services/user_storage_service.dart`:

```dart
static const _medicalConsentKey = 'medical_consent_accepted_at';

Future<DateTime?> getMedicalConsentAcceptedAt() async {
  final raw = await _storage.read(key: _medicalConsentKey);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

Future<void> setMedicalConsentAcceptedAt(DateTime acceptedAt) {
  return _storage.write(
    key: _medicalConsentKey,
    value: acceptedAt.toIso8601String(),
  );
}
```

`_storage` es `FlutterSecureStorage` (campo existente) — no usar `SharedPreferences`.

#### B4 — `UserRepository` y `UserRepositoryImpl`

En `lib/features/users/domain/repository/user_repository.dart`:
```dart
Future<Either<DomainException, DateTime>> acceptMedicalConsent({
  required String consentVersion,
});
```

En `lib/features/users/data/repository/user_repository_impl.dart`:
```dart
@override
Future<Either<DomainException, DateTime>> acceptMedicalConsent({
  required String consentVersion,
}) {
  return executeService(
    function: () async {
      final response = await _userService.acceptMedicalConsent({
        'consentVersion': consentVersion,
      });
      return response.medicalConsentAcceptedAt;
    },
  );
}
```

#### B5 — `MedicalConsentCubit`

Crear `lib/features/event_registration/presentation/cubit/medical_consent_cubit.dart`:

```dart
@injectable
class MedicalConsentCubit extends Cubit<ResultState<DateTime>> {
  MedicalConsentCubit(this._userRepository, this._storage)
      : super(const ResultState.initial());

  final UserRepository _userRepository;
  final UserStorageService _storage;

  Future<void> acceptConsent(String consentVersion) async {
    emit(const ResultState.loading());
    final result = await _userRepository.acceptMedicalConsent(
      consentVersion: consentVersion,
    );
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (acceptedAt) async {
        await _storage.setMedicalConsentAcceptedAt(acceptedAt);
        emit(ResultState.data(data: acceptedAt));
      },
    );
  }
}
```

`@injectable` (no singleton). El `GoRoute` lo instancia via `BlocProvider(create: (_) => getIt<MedicalConsentCubit>())`.

#### B6 — `MedicalConsentPage`

Crear `lib/features/event_registration/presentation/wizard/medical_consent_page.dart`:

`StatelessWidget` con `BlocConsumer<MedicalConsentCubit, ResultState<DateTime>>`:
- `listener`: `Data` → `context.pop()`; `Error` → SnackBar con `state.error.message`.
- `builder`: propaga `isLoading: state is Loading` al `AppButton`.

Estructura:
```
Scaffold
└── AppBar(title: registration_law1581Title)
└── Column
    ├── Expanded > SingleChildScrollView > Text(registration_law1581BodyV0)
    └── SafeArea > Padding
        ├── AppButton("Autorizar", isLoading, acceptConsent('v0.1-2026-06'))
        └── AppTextButton("No autorizar", SnackBar + context.pop)
```

Texto oscuro sobre acento naranja si se usa estilo primario (regla `feedback_dark_text_on_primary`).

#### B7 — Intercepción en `RegistrationFormContent`

En `lib/features/event_registration/presentation/registration_form_content.dart`:

1. Convertir `_onNext()` a `Future<void>`.
2. Agregar `bool _isNavigating = false` en el `State`.
3. En la transición 0→1 (Personal → Médico):

```dart
Future<void> _onNext() async {
  if (_isNavigating) return;
  // ... validación del step actual
  if (_wizard.currentStep == 0 && isStepValid) {
    setState(() => _isNavigating = true);
    try {
      final consentedAt =
          await getIt<UserStorageService>().getMedicalConsentAcceptedAt();
      if (!mounted) return;
      if (consentedAt == null) {
        await context.pushNamed(AppRoutes.medicalConsent);
        if (!mounted) return;
        final consentedAfterReturn =
            await getIt<UserStorageService>().getMedicalConsentAcceptedAt();
        if (!mounted || consentedAfterReturn == null) return; // Rider declinó
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
    _wizard.next();
    return;
  }
  // ... lógica normal para otros steps
}
```

4. Pasar `isLoading: _isNavigating` al botón "Siguiente" para feedback visual durante el await.

---

### COMPARTIDO — Router y l10n

#### C1 — Dos `GoRoute` en `app_router.dart`

Agregar en la lista raíz del `GoRouter` (con `parentNavigatorKey: _rootNavigatorKey`, fuera del `StatefulShellRoute`), siguiendo el patrón de `createVehicle` / `vehicleDetail`:

```dart
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: AppRoutes.organizerResponsibility,
  name: AppRoutes.organizerResponsibility,
  builder: (context, state) {
    final extra = state.extra as OrganizerResponsibilityExtra;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: extra.eventFormCubit),
        BlocProvider.value(value: extra.formImageCubit),
      ],
      child: EventOrganizerResponsibilityPage(
        eventToSave: extra.eventToSave,
        localCoverImagePath: extra.localCoverImagePath,
        remoteCoverImageUrl: extra.remoteCoverImageUrl,
      ),
    );
  },
),
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: AppRoutes.medicalConsent,
  name: AppRoutes.medicalConsent,
  builder: (context, state) => BlocProvider<MedicalConsentCubit>(
    create: (_) => getIt<MedicalConsentCubit>(),
    child: const MedicalConsentPage(),
  ),
),
```

#### C2 — Strings l10n en `app_es.arb`

```json
"event_organizerResponsibilityTitle": "Responsabilidad del organizador",
"event_organizerResponsibilityBodyV0": "Al publicar este evento, aceptas que eres el organizador responsable de la actividad y que te comprometes a garantizar las condiciones mínimas de seguridad para los participantes. Rideglory actúa exclusivamente como plataforma de coordinación y no asume responsabilidad por incidentes durante la rodada.\n\n(Texto definitivo pendiente de revisión legal — versión 0.1).",
"event_organizerResponsibilityCtaButton": "Acepto y publico el evento",
"event_organizerResponsibilityBackButton": "Revisar evento",
"event_formIncompleteMessage": "Completa todos los campos requeridos antes de publicar.",
"registration_law1581Title": "Autorización de datos personales",
"registration_law1581BodyV0": "Conforme a la Ley 1581 de 2012 y el Decreto 1377 de 2013, Rideglory te solicita autorización para tratar tus datos de salud (grupo sanguíneo, EPS y seguro médico) con el único propósito de facilitar atención de emergencia durante el evento. Estos datos serán compartidos únicamente con el organizador del evento y únicamente cuando el evento esté en curso. Puedes revocar esta autorización en cualquier momento desde tu perfil.",
"registration_law1581AuthorizeButton": "Autorizar",
"registration_law1581DeclineButton": "No autorizar",
"registration_law1581DeclinedMessage": "Puedes continuar sin autorizar. Los campos médicos serán opcionales y el organizador no tendrá acceso a ellos."
```

Ejecutar `flutter gen-l10n` tras editar el ARB.

---

## Archivos a crear/modificar

| Acción | Archivo | Bloque |
|--------|---------|--------|
| Modificar | `lib/shared/router/app_routes.dart` | A+B |
| Modificar | `lib/shared/router/app_router.dart` | A+B |
| Modificar | `lib/l10n/app_es.arb` | A+B |
| Crear | `lib/features/events/presentation/form/organizer_responsibility_extra.dart` | A |
| Modificar | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | A |
| Modificar | `lib/features/events/presentation/form/widgets/steps/publish_row.dart` | A |
| Crear | `lib/features/events/presentation/form/event_organizer_responsibility_page.dart` | A |
| Modificar | `lib/core/http/api_routes.dart` | B |
| Modificar | `lib/features/users/data/service/user_service.dart` | B |
| Regenerar | `lib/features/users/data/service/user_service.g.dart` | B |
| Crear | `lib/features/users/data/dto/medical_consent_response_dto.dart` | B |
| Modificar | `lib/core/services/user_storage_service.dart` | B |
| Modificar | `lib/features/users/domain/repository/user_repository.dart` | B |
| Modificar | `lib/features/users/data/repository/user_repository_impl.dart` | B |
| Crear | `lib/features/event_registration/presentation/cubit/medical_consent_cubit.dart` | B |
| Crear | `lib/features/event_registration/presentation/wizard/medical_consent_page.dart` | B |
| Modificar | `lib/features/event_registration/presentation/registration_form_content.dart` | B |
| Regenerar | `lib/l10n/app_localizations.dart` + `app_localizations_es.dart` | A+B |

---

## Contratos / API rideglory-api

Ninguno nuevo en esta fase. Todos los contratos son responsabilidad de Fase 1:
- `organizerAcceptedResponsibilityAt` en `CreateEventDto`
- `POST /users/me/medical-consent` + `MedicalConsentDto` / `MedicalConsentResponseDto`
- `GET /users/me` retorna `medicalConsentAcceptedAt: Date | null`

---

## Criterios de aceptación

**Bloque A**

1. En modo creación, al pulsar "Publicar evento", la app navega a `EventOrganizerResponsibilityPage` en lugar de guardar directamente.
2. En modo edición (`cubit.isEditing == true`), el flujo no cambia.
3. Si el formulario tiene campos inválidos, `buildEventToSave()` retorna `null`, aparece SnackBar con `event_formIncompleteMessage` y la pantalla de responsabilidad no se abre.
4. Al pulsar "Acepto y publico el evento", el botón pasa a `isLoading: true`; `cubit.saveEvent` recibe un `EventModel` con `organizerAcceptedResponsibilityAt` igual al `DateTime.now()` capturado en `_onAccept` (mismo objeto, no dos).
5. En éxito: `EventOrganizerResponsibilityPage` hace un pop; `EventFormView` hace el segundo pop con `if (context.canPop())`. Stack de navegación limpio.
6. En error: Text inline con `colorScheme.error`; pantalla no hace pop; botones habilitados para reintentar.
7. Al pulsar "Revisar evento", la pantalla hace `context.pop()` sin guardar.

**Bloque B**

8. Primera vez en el wizard: al pulsar "Siguiente" en paso Personal (índice 0), la app navega a `MedicalConsentPage` antes del paso Médico.
9. Al pulsar "Autorizar": `AppButton` muestra spinner, se llama `POST /users/me/medical-consent`, se persiste en `FlutterSecureStorage` bajo `medical_consent_accepted_at`, se cierra la pantalla y el wizard avanza.
10. Al pulsar "No autorizar": SnackBar con `registration_law1581DeclinedMessage`, pantalla se cierra, wizard NO avanza. Sin llamada HTTP.
11. Segunda sesión con caché existente: el wizard no interrumpe.
12. Error de red al autorizar: SnackBar con mensaje de error, botón habilitado de nuevo.

**Compartido**

13. `MedicalConsentCubit` tiene `@injectable` (no singleton); nunca accedido via `getIt` en widgets.
14. Un widget por archivo en todas las pantallas nuevas. Cero métodos que retornan `Widget`.
15. 10 strings nuevos en `app_es.arb`, todos via `context.l10n`. Cero hardcoded.
16. `dart analyze` sin errores nuevos. `flutter test` al 100%.
17. `user_service.g.dart` regenerado con `acceptMedicalConsent`.

---

## Pruebas

### Unitarias

| Qué | Archivo |
|-----|---------|
| `EventFormCubit.setOrganizerResponsibility` + consistencia de timestamp | `test/features/events/presentation/form/cubit/event_form_cubit_test.dart` |
| `MedicalConsentCubit.acceptConsent` — éxito y error | `test/features/event_registration/presentation/cubit/medical_consent_cubit_test.dart` |
| `UserStorageService` — métodos de consentimiento | `test/core/services/user_storage_service_test.dart` |

### Widget

| Qué | Archivo |
|-----|---------|
| `PublishRow` con form inválido → SnackBar, sin push | `test/features/events/presentation/form/widgets/steps/publish_row_test.dart` |
| `PublishRow` con form válido → `pushNamed` con extra correcto | mismo archivo |
| `EventOrganizerResponsibilityPage` — inicial, loading, éxito, error, back | `test/features/events/presentation/form/event_organizer_responsibility_page_test.dart` |
| `MedicalConsentPage` — inicial, loading, éxito, "No autorizar" | `test/features/event_registration/presentation/wizard/medical_consent_page_test.dart` |

---

## Riesgos

| # | Riesgo | Prob. | Mitigación |
|---|--------|-------|-----------|
| R1 | `ProviderNotFoundException` en `EventOrganizerResponsibilityPage` | Media | Builder del router inyecta cubits con `BlocProvider.value`; CA-4 verifica con widget test |
| R2 | Double-pop en el wizard de creación | Baja | Mecanismo determinístico: pantalla superior primero, `EventFormView` con `if (context.canPop())` |
| R3 | `organizerAcceptedResponsibilityAt` no llega al payload | Media | Gate de pre-flight A1 bloquea si falta |
| R4 | `_onNext()` asíncrono sin feedback → doble tap | Media | Flag `_isNavigating` + `isLoading` en botón |
| R5 | Reinstalación borra caché; rider ve pantalla Ley 1581 de nuevo | Media | No riesgo de compliance (re-consent válido); documentar como deuda en handoff |
| R6 | `medicalConsent` GoRoute registrado dentro del shell en lugar de la lista raíz | Baja | Seguir patrón `createVehicle` / `vehicleDetail`; path absoluto + `parentNavigatorKey: _rootNavigatorKey` |

---

## Dependencias

- **Fase 1** — migraciones Prisma, endpoint `POST /users/me/medical-consent`, contratos `organizerAcceptedResponsibilityAt` y `MedicalConsentDto`.
- **Fase 3** — `EventModel.organizerAcceptedResponsibilityAt`, `EventModelExtension.toJson()` con ese campo, `UserModel.medicalConsentAcceptedAt`.

No depende de Fase 2, Fase 4 ni Fase 6 (ahora renumerada).

---

## Ejecución recomendada

**Nivel rg-exec: normal**

Dos pantallas de consentimiento con interceptores en flujos existentes. Sin migraciones ni contratos nuevos (Fases 1 y 3 los cubren). El principal punto de complejidad es el scoping de cubits en `EventOrganizerResponsibilityPage` y el mecanismo de dos pops, ambos con patrones claros y tests de widget que los verifican. El bloque B agrega persistencia offline-first (`FlutterSecureStorage` + backend) y un cubit nuevo, pero sin edge cases de seguridad transversal.
