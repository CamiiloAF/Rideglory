# QA handoff — legal-consentimientos-fase5

**Date:** 2026-07-03T03:20:24Z
**Status:** approved (post-auditor pass — see "Cambios en esta pasada")

## Cambios en esta pasada (auditor Opus)

El auditor exigió 4 pruebas adicionales antes de aprobar. Las 4 se agregaron y
la suite completa vuelve a pasar al 100%:

1. **AC#3** — `publish_row_test.dart`, nuevo test *"shows a SnackBar with
   event_formIncompleteMessage when buildEventToSave returns null"*. Este test
   fallaba antes de implementar el fix (comportamiento inexistente + clave
   ausente del ARB), tal como predijo el auditor. Se implementó el fix real:
   - `lib/l10n/app_es.arb` — nueva clave `event_formIncompleteMessage`
     ("Completa los campos obligatorios antes de publicar el evento.");
     regenerado `app_localizations.dart` / `app_localizations_es.dart` vía
     `flutter gen-l10n`.
   - `lib/features/events/presentation/form/widgets/steps/publish_row.dart` —
     `_onPublish` ahora muestra un `SnackBar` con esa clave cuando
     `buildEventToSave()` retorna `null`, en vez de un `return` silencioso.
   - Esto **cierra el Bug #1** reportado en la pasada anterior de este mismo
     archivo (ver `## Bugs`, ahora marcado `fixed`).
2. **AC#8** — nuevo archivo
   `test/features/event_registration/presentation/registration_form_content_test.dart`,
   test *"pushes medicalConsent before the Medical step when consent is not
   cached"*: monta `RegistrationFormView` real (con `RegistrationFormCubit`
   real + mocks de casos de uso, `MedicalConsentCubit` y `VehicleCubit`
   mockeados) sobre un `GoRouter` con 2 rutas, llena el step Personal
   directamente en el `FormBuilder` compartido (mismo seam que usan los tests
   de `RegistrationFormCubit`), y confirma que tocar "Siguiente" navega a la
   pantalla de consentimiento (`AppRoutes.medicalConsent`) **antes** de que se
   vea el step Médico ("Información Médica" ausente mientras la pantalla de
   consentimiento está montada).
3. **AC#11** — mismo archivo, test *"skips medicalConsent and advances
   directly to the Medical step when consent is cached"*: con
   `hasCachedConsent()` mockeado a `true`, confirma que el wizard avanza
   directo al step Médico sin que la pantalla de consentimiento aparezca
   nunca.
4. **Guardrail doble-tap (opcional, agregado)** — mismo archivo, test
   *"double-tapping Siguiente while the consent check is in flight only
   checks once"*: con un `Completer<bool>` controlando cuándo resuelve
   `hasCachedConsent()`, se tocan dos veces seguidas mientras la primera
   llamada sigue pendiente y se verifica `hasCachedConsent()` invocado
   exactamente 1 vez (protegido tanto por el flag `_isCheckingConsent` como
   por el `AppButton` deshabilitado en `isLoading`).

Nota técnica: para poder montar `RegistrationFormContent` completo (no solo
`MedicalConsentView`/`MedicalConsentCubit` en aislamiento, que ya estaban
cubiertos) hubo que registrar un `MockPlaceService` en `GetIt` porque
`AppCityAutocomplete` (usado por `RegistrationPersonalStep`) lo resuelve
incondicionalmente en `build()`; se registra/desregistra en `setUp`/`tearDown`
del nuevo archivo de test, sin tocar el DI de producción.

## Catalogo (AC §5 → cobertura)

### Bloque A — Responsabilidad del organizador

| AC | Descripción | Cobertura |
|---|---|---|
| 1 | Creación: "Publicar evento" navega a `EventOrganizerResponsibilityPage` en vez de guardar directo | existente — `publish_row_test.dart` "tapping publish navigates..." |
| 2 | Edición: flujo no cambia | existente — `publish_row_test.dart` group "Edit mode" |
| 3 | Form inválido → `buildEventToSave()` null → SnackBar `event_formIncompleteMessage`, no abre pantalla | **nuevo, implementado en esta pasada** — `publish_row_test.dart` "shows a SnackBar with event_formIncompleteMessage..."; fix real en `publish_row.dart` + clave nueva en `app_es.arb` |
| 4 | Mismo `DateTime` capturado una sola vez en `_onAccept`, usado en `setOrganizerResponsibility` y en `copyWith` | `event_organizer_responsibility_page_test.dart` "accept: calls setOrganizerResponsibility + saveEvent..."; confirmado también por lectura de código (`final acceptedAt = DateTime.now();` reusado en ambas llamadas) |
| 5 | Doble-pop: `EventOrganizerResponsibilityPage` hace pop, `EventFormView` hace el segundo protegido con `canPop()` | parcial (unitario) — el test de éxito confirma el primer pop; el segundo pop de `EventFormView` (`if (context.canPop()) context.pop(event);`, `event_form_view.dart:60`) queda cubierto por lectura de código, sin test de integración con 3 pantallas apiladas — riesgo residual bajo, mecanismo simple y ya usado en otros flujos |
| 6 | Error: texto inline `colorScheme.error`, sin pop, botones reactivados | `event_organizer_responsibility_page_test.dart` "error: shows inline error text..." |
| 7 | "Revisar evento": pop sin guardar | `event_organizer_responsibility_page_test.dart` "review: pops without calling saveEvent" |

### Bloque B — Autorización Ley 1581

| AC | Descripción | Cobertura |
|---|---|---|
| 8 | Primera vez: "Siguiente" en step Personal (0) navega a `MedicalConsentPage` antes del step Médico | **nuevo en esta pasada** — `registration_form_content_test.dart` "pushes medicalConsent before the Medical step when consent is not cached", drives el interceptor REAL de `RegistrationFormContent._onNext()`, no solo el cubit/vista en aislamiento |
| 9 | "Autorizar": spinner, `POST /users/me/medical-consent` con `consentVersion`, persiste en `FlutterSecureStorage`, cierra y avanza | `medical_consent_cubit_test.dart` "emits [loading, data] and caches..." + `medical_consent_page_test.dart` "authorize: calls accept() and pops(true)..." + `user_storage_service_test.dart` |
| 10 | "No autorizar": SnackBar, cierra, NO avanza, cero llamadas HTTP | `medical_consent_page_test.dart` "decline: shows SnackBar, pops(false), never calls accept()" |
| 11 | Segunda sesión con caché: no interrumpe con `MedicalConsentPage` | **nuevo en esta pasada** — `registration_form_content_test.dart` "skips medicalConsent and advances directly to the Medical step when consent is cached", drives el interceptor real (antes solo `MedicalConsentCubit.hasCachedConsent()` unitario) |
| 12 | Error de red: SnackBar, botón reactivado, reintentar funciona | `medical_consent_page_test.dart` "error: shows SnackBar, does not pop, button re-enabled" |

### Compartido

| AC | Descripción | Cobertura |
|---|---|---|
| 13 | `MedicalConsentCubit` `@injectable` (no singleton), sin `getIt` en widgets | verificado por lectura: `@injectable` en el cubit; `getIt<MedicalConsentCubit>()` solo en `MedicalConsentPage` (wrapper), nunca en `MedicalConsentView` |
| 14 | Un widget por archivo, cero `Widget _build...()` | verificado — grep sin resultados en los 4 archivos nuevos de UI |
| 15 | 11 strings nuevos en ARB (10 originales + `event_formIncompleteMessage` agregado en esta pasada), cero hardcodeados | verificado — grep sin resultados de `Text('...')`/`Text("...")` literales en las vistas nuevas; las claves existen en `app_es.arb` |
| 16 | `dart analyze` sin issues nuevos; `flutter test` 100% | verificado — ver `## Ejecucion` |
| 17 | `user_service.g.dart` regenerado con `acceptMedicalConsent` | verificado — presente en el diff generado |

## Matriz de regresion (guardrails §6)

| Guardrail | Mecanismo verificado |
|---|---|
| No tocar contratos backend/DTOs de Fases 1/3 | Sin cambios en `rideglory-api`; `MedicalConsentResponseDto` es nuevo, response-only, documentado como excepción Pattern B |
| Modo edición de eventos sin cambios | `publish_row.dart`: rama `if (cubit.isEditing)` intacta; test "Edit mode" confirma cero navegación/cero llamada a `buildEventToSave()` |
| `GoRoute`s nuevos como hermanos del `StatefulShellRoute`, no anidados | Confirmado por lectura de `app_router.dart`: `organizerResponsibility`/`medicalConsent` fuera del bloque `StatefulShellRoute.indexedStack`, con `parentNavigatorKey: _rootNavigatorKey` |
| Doble-pop determinístico (`canPop()`) | `event_form_view.dart:60` — `if (context.canPop()) context.pop(event);`; ver AC#5 arriba |
| `_onNext()` protegido contra doble-tap (`_isCheckingConsent`) | **Ahora con test dedicado** — `registration_form_content_test.dart` "double-tapping Siguiente..." confirma `hasCachedConsent()` invocado exactamente 1 vez tras dos taps consecutivos |
| `FlutterSecureStorage`, no `SharedPreferences`, para consentimiento médico | Confirmado — `UserStorageService` usa `FlutterSecureStorage` para `medical_consent_accepted_at`; test explícito en `user_storage_service_test.dart` |
| ARB/router/api_routes tocados una sola vez (salvo el ajuste de esta pasada) | El ARB recibió una edición adicional en esta pasada de QA para agregar `event_formIncompleteMessage` (requerida por el auditor para cerrar AC#3); es la única excepción documentada a la regla de "una sola vez" |
| No pisar el trabajo en progreso de `registration_form_content.dart`/`registration_form_cubit.dart` (waiver/edad) | Confirmado: los tests de esa área siguen en el árbol y pasan; el nuevo test de `registration_form_content_test.dart` no toca `_onFinishPressed`/waiver sheet |

## Ejecucion

- `dart analyze`: **sin issues** (limpio antes y después de los cambios de esta pasada).
- `flutter test`: **970/970 pass** (966 de la pasada anterior + 4 tests nuevos exigidos por el auditor: 1 en `publish_row_test.dart`, 3 en `registration_form_content_test.dart`).
- No se corrieron pruebas de backend (`rideglory-api`) — esta fase no toca ese repo.

## Bugs

1. **[frontend] `lib/features/events/presentation/form/widgets/steps/publish_row.dart`** — AC#3 (SnackBar `event_formIncompleteMessage` ausente). **Estado: fixed en esta pasada.** Se agregó el `SnackBar` en `_onPublish` cuando `event == null` y la clave `event_formIncompleteMessage` a `lib/l10n/app_es.arb` (con regeneración de `app_localizations*.dart`). Test de regresión agregado en `publish_row_test.dart`.

## Pruebas manuales

Pendientes (requieren emulador/dispositivo, no se pudo levantar el app en este entorno):

1. Bloque A: crear evento nuevo → "Publicar evento" → pantalla de responsabilidad → "Acepto y publico el evento" → confirmar loading → SnackBar de éxito del wizard → cierre por doble pop (sin pantallas huérfanas al usar back después). Repetir con formulario incompleto para confirmar visualmente el SnackBar `event_formIncompleteMessage` recién implementado.
2. Bloque A, error de red forzado (airplane mode) durante "Acepto y publico el evento" → texto inline de error, sin pop, reintentar funciona.
3. Modo edición de evento: confirmar que "Cerrar" en step 4 sigue funcionando igual que antes, sin pasar por la pantalla nueva.
4. Bloque B: primera inscripción en el dispositivo → step Personal → "Siguiente" → debe interrumpir con `MedicalConsentPage` → "Autorizar" → avanza a step Médico.
5. Bloque B, segunda sesión (mismo dispositivo, consentimiento ya cacheado) → "Siguiente" en step Personal NO debe interrumpir.
6. Bloque B: "No autorizar" → SnackBar + wizard se queda en step 0, sin llamada HTTP (verificar con proxy/logs).
7. Bloque B, error de red forzado en "Autorizar" → SnackBar de error, botón reactivado, reintentar funciona.
8. Doble-tap en "Siguiente" del step Personal mientras `MedicalConsentPage` está cargando/navegando → no debe disparar dos navegaciones ni dos POST (ahora también cubierto por test automatizado, ver arriba).
9. Multi-cuenta en el mismo dispositivo: loguear con cuenta A, autorizar consentimiento médico; hacer logout y loguear con cuenta B → verificar que el wizard SÍ vuelve a pedir autorización a la cuenta B (fuera de alcance documentado, pero vale confirmar el comportamiento real).
10. Confirmar visualmente que ninguna de las dos pantallas nuevas usa texto blanco sobre el acento naranja.
11. Bottom nav / navegación de tabs sigue funcionando con normalidad tras visitar cualquiera de las 2 pantallas nuevas.

## Sign-off

**Aprobado.** Los 4 tests exigidos por el auditor se agregaron y pasan; el
gap de AC#3 (SnackBar/ARB faltante) se implementó y quedó guardado por test;
los gaps de AC#8/#11 (interceptor real de `RegistrationFormContent._onNext()`
sin cobertura) quedaron cerrados con `registration_form_content_test.dart`; el
guardrail de doble-tap ahora tiene test dedicado. Suite completa **970/970**,
`dart analyze` **limpio**. No quedan bugs abiertos ni gaps de cobertura
identificados sobre los 17 AC. Único punto de riesgo residual (bajo, no
bloqueante): AC#5 (doble-pop de 3 pantallas apiladas) sigue verificado solo
por lectura de código + test unitario parcial, sin test de integración de pila
completa — candidato a Patrol e2e vía `qa-auto`, no bloquea el merge.
