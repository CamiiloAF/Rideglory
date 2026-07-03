# PRD Normalizado — Fase 5: Consentimientos legales (responsabilidad del organizador + autorización Ley 1581)

**Slug:** `legal-consentimientos-fase5`
**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-05-aceptacion-de-responsabilidad-del-organizador.md`
**Timestamp normalización:** 2026-07-03T02:27:42Z
**Nivel rg-exec:** normal

---

## 1 Objetivo

Implementar dos consentimientos legales independientes que la app requiere antes de habilitar acciones sensibles:

1. **Responsabilidad del organizador** — un organizador no puede publicar un evento nuevo sin leer y aceptar explícitamente una declaración de responsabilidad legal; el timestamp de aceptación (`organizerAcceptedResponsibilityAt`) viaja en el payload de creación del evento.
2. **Autorización Ley 1581** — el rider da consentimiento expreso (Ley 1581 de 2012, protección de datos personales) antes de que sus datos médicos sean tratados en el contexto de una inscripción a un evento; se persiste en backend (fuente de verdad) y localmente en `FlutterSecureStorage` (offline-first) para no volver a interrumpir el wizard una vez otorgado.

## 2 Por qué

- Cumplimiento legal/regulatorio: la Ley 1581 exige autorización expresa e informada para tratar datos sensibles de salud.
- Mitigación de riesgo para Rideglory como plataforma de coordinación: deslindar responsabilidad del organizador frente a incidentes durante la rodada requiere evidencia de aceptación explícita, con timestamp, antes de publicar el evento.
- Ambas fases 5 y 6 originales del plan se fusionaron porque entregan el mismo patrón (pantalla de consentimiento + interceptor en un flujo existente), dependen solo de las Fases 1 y 3, y no se bloquean entre sí.

## 3 Alcance

### Entra

**Bloque A — Responsabilidad del organizador**
- Pantalla nueva `EventOrganizerResponsibilityPage`.
- Clase de transporte `OrganizerResponsibilityExtra` (cubits + evento a guardar + imagen de portada) entre `PublishRow` y el router.
- Interceptor en el botón "Publicar evento" de `PublishRow`, solo cuando `cubit.isEditing == false`.
- Método `setOrganizerResponsibility(DateTime)` en `EventFormCubit`.
- Constante de ruta `AppRoutes.organizerResponsibility` + `GoRoute` en la lista raíz (path absoluto, `parentNavigatorKey: _rootNavigatorKey`).

**Bloque B — Autorización Ley 1581**
- Pantalla nueva `MedicalConsentPage`.
- Cubit nuevo `MedicalConsentCubit` (`@injectable`, no singleton).
- Métodos nuevos `acceptMedicalConsent` en `UserRepository` / `UserRepositoryImpl` / `UserService` (Retrofit).
- Métodos nuevos `getMedicalConsentAcceptedAt()` / `setMedicalConsentAcceptedAt(DateTime)` en `UserStorageService` (respaldados por `FlutterSecureStorage`).
- DTO response-only `MedicalConsentResponseDto` (excepción documentada a Pattern B — sin modelo de dominio par).
- Constante `ApiRoutes.meMedicalConsent`.
- Interceptor en `RegistrationFormContent._onNext()` al avanzar del paso Personal (0) al paso Médico (1).
- Constante de ruta `AppRoutes.medicalConsent` + `GoRoute` en la lista raíz.

**Compartido (tocar una sola vez)**
- `lib/shared/router/app_routes.dart` — 2 constantes nuevas.
- `lib/shared/router/app_router.dart` — 2 `GoRoute` nuevos en la lista raíz.
- `lib/l10n/app_es.arb` — 10 strings nuevos (5 por bloque) + regeneración de `app_localizations*.dart`.

### No entra
- Pantalla de responsabilidad del organizador en modo edición (el flujo de edición no cambia).
- Cambios a contratos backend o DTOs (responsabilidad de Fases 1 y 3, ya completadas — ver pre-flight).
- Lógica de validación en backend (Fase 1).
- Consentimiento Ley 1581 dentro de `EditProfilePage`.
- Migración Prisma (Fase 1).
- Pantalla de revocación de consentimiento.
- Texto legal definitivo — se usan placeholders v0 en el ARB, pendientes de revisión legal.

## 4 Áreas afectadas (best-effort)

- `lib/shared/router/app_routes.dart`, `lib/shared/router/app_router.dart` (routing raíz)
- `lib/features/events/presentation/form/` — `organizer_responsibility_extra.dart` (nuevo), `event_organizer_responsibility_page.dart` (nuevo), `cubit/event_form_cubit.dart`, `widgets/steps/publish_row.dart`
- `lib/core/http/api_routes.dart`
- `lib/features/users/data/service/user_service.dart` (+ regeneración `user_service.g.dart`)
- `lib/features/users/data/dto/medical_consent_response_dto.dart` (nuevo)
- `lib/core/services/user_storage_service.dart`
- `lib/features/users/domain/repository/user_repository.dart`
- `lib/features/users/data/repository/user_repository_impl.dart`
- `lib/features/event_registration/presentation/cubit/medical_consent_cubit.dart` (nuevo)
- `lib/features/event_registration/presentation/wizard/medical_consent_page.dart` (nuevo)
- `lib/features/event_registration/presentation/registration_form_content.dart`
- `lib/l10n/app_es.arb` (+ regeneración `app_localizations.dart` / `app_localizations_es.dart`)
- Tests: `test/features/events/presentation/form/cubit/event_form_cubit_test.dart`, `test/features/events/presentation/form/widgets/steps/publish_row_test.dart`, `test/features/events/presentation/form/event_organizer_responsibility_page_test.dart`, `test/features/event_registration/presentation/cubit/medical_consent_cubit_test.dart`, `test/features/event_registration/presentation/wizard/medical_consent_page_test.dart`, `test/core/services/user_storage_service_test.dart`

Nota: el `git status` actual del repo ya muestra trabajo en progreso relacionado (p.ej. `registration_waiver_step.dart`, cambios en `registration_form_cubit.dart`, `registration_form_content.dart`, `app_switch_tile.dart`, ARB) que puede solaparse parcialmente con el Bloque B — verificar contra el estado real del árbol antes de implementar para evitar duplicar/pisar trabajo ya iniciado.

## 5 Criterios de aceptación

**Bloque A — Responsabilidad del organizador**
1. En modo creación, al pulsar "Publicar evento", la app navega a `EventOrganizerResponsibilityPage` en lugar de guardar directamente.
2. En modo edición (`cubit.isEditing == true`), el flujo no cambia.
3. Si el formulario tiene campos inválidos, `buildEventToSave()` retorna `null`, aparece SnackBar con `event_formIncompleteMessage` y la pantalla de responsabilidad no se abre.
4. Al pulsar "Acepto y publico el evento", el botón pasa a `isLoading: true`; `cubit.saveEvent` recibe un `EventModel` con `organizerAcceptedResponsibilityAt` igual al `DateTime.now()` capturado en `_onAccept` (mismo objeto, no dos capturas distintas).
5. En éxito: `EventOrganizerResponsibilityPage` hace un pop; `EventFormView` hace el segundo pop protegido con `if (context.canPop())`. Stack de navegación queda limpio (sin pantallas huérfanas).
6. En error: se muestra `Text` inline con `colorScheme.error`; la pantalla no hace pop; botones quedan habilitados para reintentar.
7. Al pulsar "Revisar evento", la pantalla hace `context.pop()` sin guardar nada.

**Bloque B — Autorización Ley 1581**
8. Primera vez en el wizard: al pulsar "Siguiente" en el paso Personal (índice 0), la app navega a `MedicalConsentPage` antes de mostrar el paso Médico.
9. Al pulsar "Autorizar": `AppButton` muestra spinner, se llama `POST /users/me/medical-consent`, se persiste en `FlutterSecureStorage` bajo la clave `medical_consent_accepted_at`, la pantalla se cierra y el wizard avanza al paso Médico.
10. Al pulsar "No autorizar": aparece SnackBar con `registration_law1581DeclinedMessage`, la pantalla se cierra, el wizard NO avanza y no se realiza ninguna llamada HTTP.
11. En una segunda sesión con caché existente (`medical_consent_accepted_at` ya presente), el wizard no vuelve a interrumpir con `MedicalConsentPage`.
12. Ante error de red al autorizar: aparece SnackBar con mensaje de error y el botón queda habilitado de nuevo para reintentar.

**Compartido**
13. `MedicalConsentCubit` está anotado `@injectable` (no singleton) y nunca se accede a él vía `getIt` directamente en widgets (se inyecta por `BlocProvider`).
14. Un widget por archivo en todas las pantallas nuevas; cero métodos que retornan `Widget` (`Widget _buildX()` prohibido).
15. Los 10 strings nuevos existen en `app_es.arb` y se consumen exclusivamente vía `context.l10n`; cero strings hardcodeados en la UI nueva.
16. `dart analyze` no introduce errores nuevos respecto a la línea base capturada en pre-flight; `flutter test` pasa al 100% (incluyendo los tests nuevos listados en la fuente).
17. `user_service.g.dart` queda regenerado e incluye `acceptMedicalConsent`.

## 6 Guardrails de regresión

- No modificar contratos backend ni DTOs existentes de Fases 1/3 (`organizerAcceptedResponsibilityAt` en `CreateEventDto`, `MedicalConsentDto`/`MedicalConsentResponseDto`, `UserModel.medicalConsentAcceptedAt`) — son de solo lectura para esta fase; si faltan, la fase se detiene en pre-flight, no se improvisa el contrato.
- No tocar el flujo de edición de eventos (`cubit.isEditing == true` debe seguir publicando/guardando directo, sin pasar por la pantalla de responsabilidad).
- No agregar el `GoRoute` de `medicalConsent` u `organizerResponsibility` dentro del `StatefulShellRoute` — deben ir en la lista raíz del `GoRouter` con `parentNavigatorKey: _rootNavigatorKey` y path absoluto (riesgo R6 documentado en la fuente).
- Evitar doble pop / pop faltante: el mecanismo es determinístico — la pantalla de consentimiento hace un pop en su `listener` al detectar `Data`; el caller (`EventFormView` en Bloque A) hace el segundo pop siempre protegido con `if (context.canPop())`.
- `_onNext()` en `RegistrationFormContent` debe protegerse contra doble tap con el flag `_isNavigating` + `isLoading` visual en el botón "Siguiente" mientras el await está en curso.
- No usar `SharedPreferences` para el consentimiento médico — debe ser `FlutterSecureStorage` vía `UserStorageService` (dato sensible de salud/consentimiento).
- No modificar `app_routes.dart`, `app_router.dart` ni `app_es.arb` más de la única vez planificada (2 rutas + 10 strings) para minimizar conflictos con otras fases en curso.
- Verificar el estado actual del árbol de trabajo (`git status`) antes de tocar `registration_form_content.dart`, `registration_form_cubit.dart` y el ARB — ya hay cambios sin commitear en esos archivos de un trabajo previo (posible waiver de inscripción) que no debe pisarse ni revertirse accidentalmente.

## 7 Constraints heredados

- Clean Architecture: domain sin imports de Flutter ni HTTP; data sin `BuildContext`; presentation sin llamadas HTTP directas ni exposición de DTOs.
- Pattern B obligatorio para DTOs 1:1 con modelo de dominio (`XDto extends XModel` + `XModelExtension.toJson()`); `MedicalConsentResponseDto` es una excepción documentada (response-only, sin modelo par) — debe quedar anotada como tal en el código.
- Cubits: `Cubit<ResultState<T>>` para operaciones simples; `MedicalConsentCubit` sigue este patrón. `@injectable` (no `@singleton`/`getIt` en widgets), instanciado por `BlocProvider` en el árbol — excepción histórica solo para `AuthCubit`.
- Un widget por archivo; cero métodos `Widget _build...()`; usar siempre los widgets compartidos de `lib/shared/widgets/form/` (`AppButton`, `AppTextButton`, etc.) antes de crear alternativas.
- Toda la UI nueva vía `context.l10n.<key>`; cero strings hardcodeados; ejecutar `flutter gen-l10n` tras editar el ARB.
- Sobre el color de acento naranja (`AppColors.primary`), texto/iconos/knob deben ser oscuros, nunca blancos (regla `feedback_dark_text_on_primary`), aplicable si `MedicalConsentPage`/`EventOrganizerResponsibilityPage` usan estilo primario.
- Un solo estilo de switch (`AppSwitch`/`AppSwitchTile`) si aplica en estas pantallas — no crear alternativas.
- Navegación: `context.pushNamed()` para transiciones normales (usado por ambos interceptores); no usar `goNamed()` para este flujo (no es cambio de auth state).
- No ejecutar comandos git de escritura (add/commit/push/merge/rebase/reset/restore) ni `gh pr create/merge/review`; el árbol de trabajo queda sucio para revisión humana.
- No modificar `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`, ni la nota fuente original de esta fase.
- Ejecutar `dart run build_runner build --delete-conflicting-outputs` tras tocar `UserService` (Retrofit) para regenerar `user_service.g.dart`.
- Pre-flight obligatorio de la fuente (bloqueante si falla): confirmar que `EventModelExtension.toJson()` incluye `organizerAcceptedResponsibilityAt`; confirmar `UserModel.medicalConsentAcceptedAt: DateTime?`; confirmar que `POST /users/me/medical-consent` existe en backend; capturar línea base de `dart analyze`.
