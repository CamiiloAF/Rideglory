# PRD Normalizado — Waiver del rider en el flujo de inscripción

**Slug:** `waiver-inscripcion-registro`
**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-04-waiver-del-rider-en-el-flujo-de-inscripcion.md` (Fase 4 del plan `legal-privacidad-edad`)
**Normalizado:** 2026-07-02T03:33:53Z
**Nivel rg-exec recomendado por la fuente:** `full`
**dependsOn (fases prerequisito del plan origen):** Fase 2 (backend — error semántico `UNDERAGE_RIDER`), Fase 3 (modelos/DTOs Flutter con campos legales)

---

## 1 Objetivo

Un rider no puede completar una inscripción a una rodada sin aceptar explícitamente los riesgos del evento y elegir sus preferencias de privacidad médica y de contacto. El waiver se integra como el paso 5 (último paso) del wizard de inscripción existente. La validación de edad mínima (≥18 años) se aplica tanto localmente en el cubit (antes de tocar el backend) como en el backend (Fase 2, ya prerequisito); el error semántico `UNDERAGE_RIDER` retornado por el backend se mapea a un mensaje l10n específico en el widget mediante `error.message.contains('UNDERAGE_RIDER')` — único mecanismo disponible porque `DomainException` solo expone `message: String` (sin campo `code`).

## 2 Por qué

- Cumplimiento legal/responsabilidad: la rodada conlleva riesgos inherentes; el rider debe aceptar explícitamente un waiver de riesgos antes de inscribirse.
- Privacidad médica y de contacto: el rider debe decidir de forma consciente (opt-in, default `false`) si comparte su información médica y si permite que el organizador lo contacte.
- Seguridad de menores: se impide la inscripción de riders menores de 18 años, con doble guardia (cliente + servidor) para evitar bypass.
- Accesibilidad (WCAG 2.1 AA): los switches de privacidad requieren subtítulo explicativo obligatorio (ajuste A3 del Architect/Plan Review previo).

## 3 Alcance

### Entra
- Agregar el paso 5 "waiver" al wizard de inscripción existente (`RegistrationWizardSteps.fieldsByStep` pasa de 4 a 5 elementos mediante una lista vacía `<String>[]`, ya que el waiver no tiene campos `FormBuilder`).
- Nuevas constantes: `RegistrationFormFields.shareMedicalInfo`, `RegistrationFormFields.allowOrganizerContact`, `AnalyticsParams.stepNameWaiver`.
- Dos `AppSwitchTile` de privacidad (`shareMedicalInfo`, `allowOrganizerContact`) al final del paso médico existente, bajo un `ProfileFormSectionHeader` ("Privacidad"), ambos con `subtitle` obligatorio.
- Nuevo widget de un solo archivo `registration_waiver_step.dart` (`RegistrationWaiverStep`): header con subtítulo, nombre del organizador condicional, texto legal scrollable en `ConstrainedBox(maxHeight: 280)` + `SingleChildScrollView` interno (nunca `Expanded`), error inline diferenciado (`UNDERAGE_RIDER` backend vs. errores locales del cubit), botón CTA "Entiendo, inscribirme" y botón "Cancelar", ambos como callbacks del padre (`onSubmit`, `onBack`).
- `RegistrationFormCubit`: guardia de edad local en `saveRegistration()` (antes de `_buildRegistration()`), método `_calculateAge()`, seam de testing `birthDateOverrideForTesting`, inyección de `riskAcceptedAt`/`riskAcceptanceVersion` en `_buildRegistration()`, patch de los dos booleanos en `_preloadFromExistingRegistration()` (modo edición).
- Integración en `registration_form_content.dart`: import y uso de `RegistrationWaiverStep` en el `IndexedStack` (índice 4), registro de `stepNameWaiver` en `_stepNameFor()`, ocultar `RegistrationWizardNavigationBar` cuando `_wizard.isLastStep`.
- 14 claves nuevas en `lib/l10n/app_es.arb` (sección `registration_`) y regeneración con `flutter gen-l10n`.
- `dart analyze` sin errores/warnings al finalizar.

### No entra
- Cambios al router (`app_router.dart`) — el waiver es un paso del wizard, no una ruta nueva.
- Cambios al backend (cubiertos por Fases 1 y 2 del plan `legal-privacidad-edad`).
- Cambios a modelos/DTOs Flutter (cubiertos por Fase 3).
- Texto legal definitivo (se usa placeholder `v0` / `registration_waiverBodyV0` en el ARB; el texto final del abogado queda pendiente).
- Hacer `subtitle` opcional en `RegistrationStepHeader`.
- Pantalla de autorización Ley 1581 (Fase 6 del plan) y vista del organizador (Fase 7 del plan).

## 4 Áreas afectadas (best-effort)

- `lib/l10n/app_es.arb` (+ regeneración de `app_localizations*.dart`)
- `lib/features/event_registration/constants/registration_form_fields.dart`
- `lib/core/services/analytics/analytics_params.dart`
- `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart`
- `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` (nuevo)
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`
- `lib/features/event_registration/presentation/registration_form_content.dart`
- Tests: `registration_form_cubit_test.dart`, `registration_waiver_step_test.dart`, `registration_medical_step_test.dart` (nuevos/modificados)
- Sin cambios en `rideglory-api` (contratos y código de error `UNDERAGE_RIDER` son prerequisito ya cubierto por Fases 1-2 del plan origen).

## 5 Criterios de aceptación (numerados, observables, testeables)

1. **Wizard de 5 pasos visible:** el `RegistrationStepIndicator` muestra 5 puntos en todos los dispositivos. El cambio de 4 a 5 se produce únicamente por agregar `<String>[]` a `RegistrationWizardSteps.fieldsByStep`; `registration_wizard_controller.dart` y `registration_step_indicator.dart` no se modifican.
2. **Switches de privacidad con subtítulos:** en el paso médico, al hacer scroll hasta el final, se ven dos `AppSwitchTile` bajo el encabezado "PRIVACIDAD", cada uno con `subtitle` no nulo. Nunca `Switch`, `SwitchListTile` ni `FormBuilderSwitch`.
3. **Valores por defecto correctos:** en modo creación, ambos switches inician en `false`; en modo edición, se precargan con los valores de la inscripción existente.
4. **Paso waiver como último paso:** el paso 5 (índice 4) muestra título `registration_waiverTitle`, subtítulo `registration_waiverSubtitle`, texto scrollable `registration_waiverBodyV0` dentro de un `ConstrainedBox`, botón "Entiendo, inscribirme" y botón "Cancelar". La `RegistrationWizardNavigationBar` no aparece en este paso.
5. **Cancelar en el waiver retrocede al paso anterior:** tocar "Cancelar" lleva al paso 4 (vehículo, índice 3) vía el callback `onBack` → `_onBack()` del padre. No cierra la página de inscripción.
6. **Validación de edad local:** con `birthDate` de edad < 18, al tocar "Entiendo, inscribirme" el cubit emite un error en español sin llamar al backend; el mensaje aparece inline en el waiver.
7. **Error `UNDERAGE_RIDER` del backend:** si `error.message` contiene el string `UNDERAGE_RIDER`, el paso waiver muestra `registration_underageTitle` como título y `registration_underageMessage` como cuerpo (no el mensaje crudo del servidor).
8. **`birthDate` faltante con acción de perfil:** si `birthDate` es nulo, `saveRegistration()` emite el mensaje de `registration_missingBirthDateMessage` sin llamar al backend; el waiver muestra el error y un `AppTextButton` "Ir a mi perfil" que navega a `AppRoutes.editProfile` (verificar nombre real de la ruta si no existe nominada).
9. **`riskAcceptedAt` en el payload:** en inscripción exitosa, el body del `POST /events/:id/registrations` contiene `riskAcceptedAt` (ISO timestamp) y `riskAcceptanceVersion: 'v0.1-2026-06'`.
10. **`shareMedicalInfo` y `allowOrganizerContact` en el payload:** el body del POST contiene ambos campos con el valor seleccionado por el rider.
11. **Validación de marca de vehículo preservada:** el CTA del waiver invoca `_submitRegistration()` del padre (via `onSubmit`), nunca `cubit.saveRegistration()` directamente; la validación de `availableBrands` no se bypasea.
12. **Analítica al avanzar al paso waiver:** al navegar del paso vehículo (índice 3) al waiver (índice 4) con "Siguiente", se emite `registrationStepAdvanced` con `step_index: 4` y `step_name: 'waiver'`.
13. **`event.ownerName` nullable manejado:** si `event.ownerName` es `null`, el `Text` del organizador no se renderiza; no hay string vacío ni null-check exception.
14. **Cero strings hardcodeados:** todos los textos visibles vienen de `context.l10n`; ninguna clave ARB nueva queda muerta (o se elimina `registration_goToProfile` si no se implementa la acción).
15. **`dart analyze` limpio:** cero errores y cero warnings (excluyendo `.g.dart`/`.freezed.dart`).

## 6 Guardrails de regresión

- No modificar `app_router.dart` ni agregar rutas nuevas — el waiver vive dentro del wizard existente.
- No introducir métodos `_buildXxx()` que retornan widgets ni más de una clase de widget por archivo (regla cero tolerancia); `RegistrationWaiverStep` debe ser archivo único.
- No usar `Expanded` dentro de `RegistrationWaiverStep` (el `IndexedStack` vive en un `SingleChildScrollView` sin altura acotada) — usar `ConstrainedBox(maxHeight: 280)` + `SingleChildScrollView` interno.
- No permitir botones duplicados de submit: envolver el `BlocBuilder` de `RegistrationWizardNavigationBar` con `if (!_wizard.isLastStep)`; no agregar parámetro nuevo a `RegistrationWizardNavigationBar`.
- El botón "Cancelar" del waiver nunca debe llamar `context.pop()` directamente ni invocar métodos del cubit — solo el callback `onBack` (`_onBack()` del padre), único mecanismo de retroceso.
- El botón CTA del waiver nunca debe llamar `cubit.saveRegistration()` directamente — solo `onSubmit` (`_submitRegistration()` del padre), para no bypasear la validación de marca de vehículo.
- No modificar `RegistrationStepHeader` para hacer `subtitle` opcional — fuera de scope.
- No hardcodear ningún string visible al usuario; todo vía `app_es.arb` + `context.l10n`.
- No usar `Switch`, `SwitchListTile`, `FormBuilderSwitch` ni `CupertinoSwitch` — únicamente `AppSwitchTile`.
- El mensaje de error de `UNDERAGE_RIDER` del backend debe seguir detectándose por `error.message.contains('UNDERAGE_RIDER')` — no inventar campo `code` en `DomainException` (no existe en esta fase).
- Verificar en pre-flight que Fases 2 y 3 (backend y modelos/DTOs) están completas antes de tocar `_buildRegistration()`; si no lo están, bloquear y avisar en vez de improvisar contratos.
- No tocar código de backend (`rideglory-api`) en esta fase — los contratos y el error `UNDERAGE_RIDER` son prerequisito ya resuelto en Fases 1-2.
- Ejecutar `dart analyze` y `flutter gen-l10n` al finalizar; ambos deben quedar limpios.

## 7 Constraints heredados

- Arquitectura limpia: Presentation no debe hacer llamadas HTTP directas ni exponer DTOs; Cubits siguen el patrón `Cubit<ResultState<T>>` (o estado freezed compuesto para casos complejos); no se usan flags booleanos para loading/error.
- Un widget por archivo; prohibidos métodos que retornan widgets (regla cero tolerancia del proyecto).
- Siempre usar widgets compartidos existentes (`AppSwitchTile`, `AppButton`, `AppTextButton`, `ProfileFormSectionHeader`) antes de crear nuevos.
- Localización obligatoria: todo string de UI en `app_es.arb`, sin literales hardcodeados, con prefijo de feature (`registration_`).
- Sobre el color primario naranja, texto/iconos deben ser oscuros, nunca blancos (no aplica directamente a esta fase, pero es constraint global del design system).
- `dart analyze` debe pasar sin errores antes de considerar la fase completa.
- No ejecutar comandos git de escritura (add/commit/push/merge/rebase/restore/reset) ni `gh pr create/merge/review` durante la ejecución de esta fase — el árbol de trabajo queda intencionalmente sucio para revisión humana.
- No modificar `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**` (legado), `.claude/**`, ni la nota fuente original (`docs/plans/legal-privacidad-edad/...`).
