# Frontend handoff — waiver-inscripcion-registro

**Date:** 2026-07-02T04:05:43Z
**Status:** done

---

## Corrección Tech Lead — 2 hallazgos (2026-07-02T04:33:00Z)

El Tech Lead (modo fix) reportó 2 hallazgos sobre desviaciones no documentadas respecto al PRD/
handoffs previos. Ambos corregidos alineando el código al copy/componente que el PRD y el
sign-off de UX Review ya exigían (no se optó por la alternativa de "documentar la desviación").

1. **Copy del CTA no coincidía con AC#4/#6 literal del PRD.** `registration_waiverCtaButton`
   decía `"Confirmar inscripción"`; el PRD (`PRD_NORMALIZED.md` líneas 28/59/61) exige literalmente
   `"Entiendo, inscribirme"`. Corregido en `lib/l10n/app_es.arb` y regenerado con `flutter
   gen-l10n` (`app_localizations.dart` / `app_localizations_es.dart`).
2. **Fix de UX Review sobre el botón "Cancelar" no estaba aplicado en código.** `design.md`
   (sección "Fix pass", 2026-07-02T03:51:11Z) y `ux-review.md` (ronda 2, `approved_with_notes`)
   dan por resuelto el cambio de `AppTextButton` a `AppButton` (`style: outlined`, `shape: pill`,
   mismo componente que "Atrás" en `RegistrationWizardNavigationBar`), pero
   `registration_waiver_step.dart` seguía usando `AppTextButton` para "Cancelar". Corregido:
   ahora usa `AppButton(style: AppButtonStyle.outlined, shape: AppButtonShape.pill, height: 52)`,
   igual que el botón "Atrás" de los pasos 2-4 del wizard. El texto sigue siendo
   `registration_waiverCancelButton` = "Cancelar" (sin cambios, el PRD lo exige literal en AC#4/#5).

   Nota: `design.md`/`ux-review.md` son handoffs legado de esta misma corrida (no
   `docs/handoffs/**` protegidos por las reglas del Tech Lead) y no se tocaron — el fix se aplicó
   al código para que coincida con lo que esos documentos ya afirmaban verificado.

**Tests actualizados** (`registration_waiver_step_test.dart`, sin nuevos casos, solo ajustados a
la nueva estructura del árbol de widgets — ahora hay 2 `AppButton` en vez de 1 `AppButton` + 1
`AppTextButton`):
- Render test: `findsNWidgets(2)` para `AppButton`, `findsNothing` para `AppTextButton` (el único
  `AppTextButton` restante en el archivo es "Ir a mi perfil", solo visible en el caso de error de
  `birthDate` faltante, no en el render por defecto).
- Todos los taps sobre el CTA cambian a `find.byType(AppButton).first` (CTA es el primer
  `AppButton` en el `Column`, Cancelar el segundo).
- El tap de "Cancelar" cambia de `find.byType(AppTextButton)` a `find.byType(AppButton).last`.

**Resultado:** `dart analyze` (repo completo) sin issues; `flutter test
test/features/event_registration/` **78/78 pass** (0 fail), incluyendo los 10 tests de
`registration_waiver_step_test.dart` con la nueva estructura.

### Archivos tocados en esta corrección

- `lib/l10n/app_es.arb` — `registration_waiverCtaButton`: `"Confirmar inscripción"` →
  `"Entiendo, inscribirme"`.
- `lib/l10n/app_localizations.dart` / `lib/l10n/app_localizations_es.dart` — regenerados.
- `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` —
  botón "Cancelar" cambia de `AppTextButton` a `AppButton` outlined pill.
- `test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart`
  — ajustes de selectores (`AppButton` x2) descritos arriba.

---

## Corrección post-auditoría (2026-07-02T04:12:43Z)

El Auditor Opus exigió 4 cambios; se aplicaron los 4 (uno ya estaba resuelto):

1. **`registration_waiver_step.dart`** — `isUnderage` ahora es un OR: `errorOrNull.message ==
   RegistrationFormCubit.underageErrorMessage || errorOrNull.message.contains('UNDERAGE_RIDER')`.
   Antes solo comparaba por igualdad exacta con el mensaje local, así que un 422 real del backend
   con `message: 'UNDERAGE_RIDER'` caía en la rama genérica (mensaje crudo sin título), violando
   AC#7. Ahora ambos casos (guardia local Y respuesta del backend) renderizan
   `registration_underageTitle` + `registration_underageMessage`, nunca el texto crudo del servidor.
2. **`registration_form_cubit_age_validation_test.dart`** — el test del caso `UNDERAGE_RIDER` del
   backend ya no dice "passed through unchanged" (frase que contradecía AC#7). Se reescribió el
   docstring para dejar explícito que el cubit legítimamente no reescribe el mensaje (solo
   propaga el `Either` del use case), y que la discriminación real hacia el título/mensaje de
   "no cumples la edad mínima" ocurre en la capa de UI (`RegistrationWaiverStep`), verificada en
   el nuevo test del widget. La aserción de comportamiento del cubit no cambió (sigue siendo
   correcta: el cubit no debe mutar mensajes de error del backend).
3. **`registration_waiver_step_test.dart`** — nuevo test `'backend UNDERAGE_RIDER error shows the
   dedicated underage title/message, never the raw server text (AC#7)'`: mockea
   `mockAdd` devolviendo `Left(DomainException(message: 'UNDERAGE_RIDER'))` y verifica que se
   muestra `registration_underageTitle`/`registration_underageMessage` y **no** el texto
   `'UNDERAGE_RIDER'` crudo ni el botón "Ir a mi perfil". Este test fallaba con el código pre-fix
   (mostraba el texto crudo) y pasa tras el fix del punto 1. El test genérico de las líneas
   317-343 ya usaba un mensaje sin `'UNDERAGE_RIDER'` (`'Error genérico del servidor'`), así que no
   requirió cambios.
4. **`app_switch_tile.dart:62`** — verificado: el working tree YA tenía `textOnDarkSecondary` (no
   `textOnDarkTertiary`); el `git diff` contra `HEAD` confirma que el color global del subtitle de
   `AppSwitchTile` ya estaba revertido a su valor original antes de esta corrección. No se requirió
   ninguna edición adicional.

Resultado tras la corrección: `dart analyze` sin issues (repo completo); `flutter test` **937/937
pass** (936 previos + 1 test nuevo de UNDERAGE_RIDER en `registration_waiver_step_test.dart`).

---

## Baseline

`flutter test` antes de tocar código: **918/918 pass** (0 fail). Estado del repo limpio salvo por
los artefactos ya presentes en `docs/exec-runs/waiver-inscripcion-registro/`.

## Archivos cambiados

Producción:
- `lib/l10n/app_es.arb` — +14 claves bajo `registration_` (privacidad, waiver, edad, `goToProfile`).
- `lib/l10n/app_localizations.dart` / `lib/l10n/app_localizations_es.dart` — regenerados con `flutter gen-l10n`.
- `lib/core/services/analytics/analytics_params.dart` — `+stepNameWaiver = 'waiver'`.
- `lib/features/event_registration/constants/registration_form_fields.dart` — 5º elemento `<String>[]` en `RegistrationWizardSteps.fieldsByStep` (paso waiver sin campos FormBuilder). No se tocaron las constantes `shareMedicalInfo`/`allowOrganizerContact`, ya existentes.
- `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`:
  - Guardia de edad al inicio de `saveRegistration()` (antes de `_buildRegistration()`): lee `birthDate` vía `birthDateOverrideForTesting` o `formKey.currentState?.fields[RegistrationFormFields.birthDate]?.value` (ver nota de bug abajo — **no** `formKey.currentState?.value[...]`).
  - `_calculateAge(DateTime)` — mismo algoritmo (forma) que `registrations.service.ts#ensureRiderIsAdult`.
  - Seam `DateTime? birthDateOverrideForTesting` (no `@visibleForTesting`, ver nota de diseño abajo).
  - Constantes `missingBirthDateErrorMessage` / `underageErrorMessage` (no `@visibleForTesting`, consumidas por el widget del paso waiver — ver nota).
  - `_buildRegistration()` ahora inyecta `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt: DateTime.now()`, `riskAcceptanceVersion: 'v0.1-2026-06'` en el `EventRegistrationModel(...)`.
- `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` — +`ProfileFormSectionHeader` (label `registration_privacySectionTitle`) + 2 `AppSwitchTile` (`shareMedicalInfo`, `allowOrganizerContact`), ambos con `subtitle` no nulo, `initialValue: false`.
- `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` — **nuevo**. `RegistrationWaiverStep` (1 archivo, 1 widget público + 1 widget privado auxiliar `_RegistrationWaiverError` para el bloque de error condicional, ambos `StatelessWidget`). `BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>` envuelve todo el `Column`. `ConstrainedBox(maxHeight: 280) + SingleChildScrollView` para el texto legal (nunca `Expanded`). CTA/Cancel solo delegan a `onSubmit`/`onBack` del padre.
- `lib/features/event_registration/presentation/registration_form_content.dart` — import + `RegistrationWaiverStep` como 5º hijo del `IndexedStack` (index 4); `AnalyticsParams.stepNameWaiver` agregado a `_stepNameFor`; nav bar envuelta en `if (!_wizard.isLastStep)`.

Tests:
- `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` — **nuevo**.
- `test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart` — **nuevo**.
- `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart` — **nuevo**.
- `test/features/event_registration/presentation/cubit/registration_form_cubit_analytics_test.dart` — **modificado** (no estaba en el change map original, pero fue necesario): se agregó `cubit.birthDateOverrideForTesting = DateTime(1990);` en el `setUp()` compartido. Sin esto, la nueva guardia de edad intercepta `saveRegistration()` antes de que el seam `buildRegistrationOverride` (ya usado por varios tests preexistentes de este archivo) llegue a ejecutarse, rompiendo `CA1b_positive` y `CA3c_real`. Es un ajuste mínimo y aditivo, no cambia ninguna aserción existente.

## Desviaciones de diseño respecto al handoff del architect (documentadas, justificadas)

1. **`missingBirthDateErrorMessage` / `underageErrorMessage` NO son `@visibleForTesting`.**
   El architect sugirió exponerlas como alternativa "más robusta" a la comparación por substring,
   sin especificar visibilidad. Como el propio `RegistrationWaiverStep` (código de producción, no
   solo tests) las necesita para discriminar el error por **igualdad exacta** (`errorOrNull.message
   == RegistrationFormCubit.underageErrorMessage`), marcarlas `@visibleForTesting` producía el lint
   `invalid_use_of_visible_for_testing_member` en el widget de producción. Se dejaron como
   constantes públicas normales de la clase. `birthDateOverrideForTesting` sí conserva
   `@visibleForTesting` porque ese seam nunca se usa desde producción.

2. **Estrategia de detección elegida: igualdad exacta, no substring.** Tal como sugería el architect
   como alternativa preferida. El widget compara `errorOrNull.message ==
   RegistrationFormCubit.underageErrorMessage` / `...missingBirthDateErrorMessage` en vez de
   `.contains(...)`. El caso `UNDERAGE_RIDER` del backend (formato de mensaje distinto, fuera del
   control del frontend) sigue mostrándose como mensaje genérico (tercera rama, sin título, sin
   botón de perfil) — el architect no pidió una rama dedicada para el `UNDERAGE_RIDER` remoto en el
   widget, solo que el mensaje viaje sin alterar (verificado en el test
   `registration_form_cubit_age_validation_test.dart`).

3. **`registration_missingBirthDateMessage` (l10n) SÍ se usa en la UI**, a diferencia de la
   redacción literal del architect ("muestra `errorOrNull.message` tal cual"). Por la regla de
   proyecto de cero strings hardcodeados en UI, el texto visible para el caso "falta birthDate" usa
   `context.l10n.registration_missingBirthDateMessage` (cuyo valor en `app_es.arb` es idéntico al
   `missingBirthDateErrorMessage` que emite el cubit para la detección). El caso genérico/servidor
   sigue mostrando `errorOrNull.message` crudo (es contenido dinámico del backend, no un string de
   UI estático).

4. **Fix de bug descubierto durante implementación (no en el change map):** la guardia de edad
   originalmente leía `formKey.currentState?.value[RegistrationFormFields.birthDate]`. Se comprobó
   (test ad-hoc, ver historial) que `FormBuilderState.value` solo refleja los valores "guardados"
   (tras `save()`/`saveAndValidate()`), no el valor en vivo de cada campo. Como la guardia corre
   **antes** de `_buildRegistration()` (que sí llama `saveAndValidate()`), leer `.value` directamente
   siempre devolvía un mapa vacío y disparaba el error "falta fecha de nacimiento" incluso con el
   campo diligenciado. Corregido a `formKey.currentState?.fields[RegistrationFormFields.birthDate]
   ?.value`, que lee el valor en vivo del campo sin depender de `save()`. Esto se detectó porque
   rompía `test/features/event_registration/presentation/cubit/registration_form_cubit_preload_test.dart`
   (test preexistente con `FormBuilder` real).

## Resultado final

- `dart analyze` (repo completo): **No issues found!**
- `flutter test` (repo completo): **936/936 pass** (0 fail) — 918 baseline + 18 tests nuevos
  (5 age-guard + 9 waiver-step + 4 medical-step).
- `dart format` aplicado a todos los archivos `.dart` tocados (el `.arb` no es formateable por
  `dart format`, se dejó tal cual — JSON válido, verificado con `flutter gen-l10n`).

## Verificación manual

No se ejecutó `flutter run` real (sin dispositivo/simulador disponible en este entorno). Verificado
por lectura de código + tests:
- Wizard pasa de 4 a 5 pasos; `RegistrationWizardSteps.stepCount` (usado por
  `RegistrationWizardController`) refleja automáticamente 5 vía `fieldsByStep.length`.
- Nav bar (`RegistrationWizardNavigationBar`) deja de renderizarse en el paso waiver (índice 4,
  ahora el último) — sus propios botones (`AppButton` CTA + `AppButton` outlined pill Cancelar,
  este último corregido en la sección "Corrección Tech Lead" arriba) toman el relevo.
- El texto legal usa `ConstrainedBox(maxHeight: 280) + SingleChildScrollView`, nunca `Expanded`,
  evitando el crash documentado como riesgo R3 por el architect (verificado indirectamente: los
  tests de widget pumpean el árbol completo sin excepciones de layout).
- El botón "Ir a mi perfil" navega a `AppRoutes.editProfile` vía `context.pushNamed` (test con
  `GoRouter` real confirma la navegación).
- El payload de la inscripción ahora lleva `shareMedicalInfo`/`allowOrganizerContact`/
  `riskAcceptedAt`/`riskAcceptanceVersion` con valores reales del form (antes viajaban con default
  `false`/`null`) — confirmado por el test de "legal fields present in built registration".

## Notas para QA

- El wizard de inscripción ahora tiene **5 pasos** (antes 4): Personal → Médico (+ switches de
  privacidad) → Emergencia → Vehículo → **Waiver** (nuevo, último).
- Casos a verificar manualmente en dispositivo/simulador (no cubiertos por widget tests por
  requerir el árbol completo de la wizard real con `EventModel`/`VehicleCubit` reales):
  1. Flujo feliz completo: llenar los 5 pasos, aceptar el waiver, confirmar que la inscripción se
     envía con `shareMedicalInfo`/`allowOrganizerContact` según lo marcado en el paso médico.
  2. Rider menor de 18 años (fecha de nacimiento en paso Personal) → al llegar al paso waiver y
     tocar "Entiendo, inscribirme", debe verse el título "No cumples la edad mínima" + mensaje fijo,
     **sin** botón "Ir a mi perfil".
  3. Editar una inscripción existente: los switches de privacidad deben precargar su valor real
     (ya lo hacía `_preloadFromExistingRegistration`, sin cambios en esta fase).
  4. Confirmar visualmente que la barra de navegación inferior **no** aparece duplicada ni superpuesta
     en el paso waiver (el `RegistrationWizardNavigationBar` genérico se oculta ahí).
  5. Mensaje `UNDERAGE_RIDER` real del backend (422) — requiere un rider con fecha de nacimiento
     que pase la guardia local pero falle en backend (edge case de reloj/zona horaria); debería
     mostrarse como mensaje genérico (sin título dedicado), ya que el architect no pidió una rama
     UI específica para ese caso remoto.
- Textos definitivos del abogado para `registration_waiverBodyV0` siguen pendientes (placeholder
  v0, fuera de alcance de esta fase — documentado también por el architect).
