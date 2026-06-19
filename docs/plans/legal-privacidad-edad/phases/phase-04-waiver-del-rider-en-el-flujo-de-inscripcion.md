# Fase 4 — Waiver del rider en el flujo de inscripción

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:59:51Z
**Nivel rg-exec:** full
**dependsOn:** [2, 3]

---

## Objetivo

Un rider no puede completar una inscripción sin aceptar explícitamente los riesgos de la rodada y elegir sus preferencias de privacidad médica y de contacto. El waiver se integra como paso 5 del wizard existente (Opción A del Architect Review). La validación de edad mínima (≥18) se aplica tanto localmente en el cubit como en el backend, y el error semántico `UNDERAGE_RIDER` se mapea a un mensaje l10n específico mediante `error.message.contains('UNDERAGE_RIDER')` en el widget (mecanismo único — `DomainException` solo tiene `message: String`, sin campo `code`).

---

## Alcance (entra / no entra)

### Entra

- **Pre-flight verificable:** confirmar que `RegistrationStepIndicator` recibe `stepCount` como parámetro (ya confirmado: `required this.stepCount`); confirmar que el controller se instancia con `stepCount: RegistrationWizardSteps.stepCount` (ya confirmado en `registration_form_content.dart` líneas 54-57). La única edición de `stepCount` es agregar la lista vacía `[]` del paso waiver a `RegistrationWizardSteps.fieldsByStep`; con eso `fieldsByStep.length` sube de 4 a 5 y el getter `stepCount` propaga el cambio automáticamente al controller y al `RegistrationStepIndicator` sin tocar ningún otro archivo.
- **`RegistrationFormFields`:** agregar constantes `shareMedicalInfo` y `allowOrganizerContact`.
- **`RegistrationWizardSteps.fieldsByStep`:** agregar la lista del paso waiver: `<String>[]` (el waiver no tiene campos `FormBuilder` — la aceptación la maneja el cubit al submit).
- **`AnalyticsParams`:** agregar constante `stepNameWaiver = 'waiver'`.
- **`_stepNameFor` en `registration_form_content.dart`:** registrar el índice 4 con `AnalyticsParams.stepNameWaiver`.
- **`registration_medical_step.dart`:** agregar al final, bajo un separador visual de sección (`ProfileFormSectionHeader`), dos `AppSwitchTile` (`shareMedicalInfo` y `allowOrganizerContact`), ambos con subtítulo obligatorio.
- **Nuevo archivo `registration_waiver_step.dart`** en `lib/features/event_registration/presentation/wizard/steps/`: paso waiver con `RegistrationStepHeader` (con `subtitle` obligatorio provisto via l10n), texto legal scrollable dentro de `ConstrainedBox`, error inline, botones CTA y Cancelar como callbacks del padre.
- **`registration_form_content.dart`:** agregar `RegistrationWaiverStep` al `IndexedStack` en el índice 4; ocultar `RegistrationWizardNavigationBar` cuando `_wizard.isLastStep`; emitir analytics `registrationStepAdvanced` al avanzar al paso waiver desde `_onNext()`.
- **`RegistrationFormCubit`:** validación de edad local en `saveRegistration()` leyendo `birthDate` de `formKey.currentState!.value` **antes** de llamar a `_buildRegistration()`; `_calculateAge()`; inyección de `riskAcceptedAt` y `riskAcceptanceVersion` en `_buildRegistration()`; patch de `shareMedicalInfo` y `allowOrganizerContact` en `_preloadFromExistingRegistration()`. El cubit emite mensajes de error en español directamente (no claves ARB) para los errores locales.
- **`app_es.arb`:** todos los strings de la fase (ver sección Strings más abajo).
- **`dart analyze`** sin errores al finalizar; `flutter gen-l10n` regenerado.

### No entra

- Modificaciones al router (`app_router.dart`): el waiver es un paso del wizard existente, no una ruta separada.
- Cambios al backend (cubiertos por Fases 1 y 2).
- Cambios a modelos/DTOs Flutter (cubiertos por Fase 3).
- Texto legal definitivo del abogado: se usa placeholder `v0` en el ARB.
- Hacer `subtitle` opcional en `RegistrationStepHeader` — está fuera de scope; se pasa un subtítulo l10n concreto.
- Pantalla de autorización Ley 1581 (Fase 6).
- Vista del organizador (Fase 7).

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 0 — Pre-flight (gates verificables, no avanzar si fallan)

1. Abrir `lib/features/event_registration/presentation/wizard/registration_step_indicator.dart` y confirmar que `stepCount` es un parámetro del constructor (`required this.stepCount`). **Confirmado en el scan**: no está hardcodeado. No se requiere cambio.
2. Abrir `lib/features/event_registration/presentation/registration_form_content.dart` y confirmar que `RegistrationWizardController` se instancia con `stepCount: RegistrationWizardSteps.stepCount`. **Confirmado en el scan**: líneas 54-57. No se requiere cambio en el controller.
3. Confirmar que `RegistrationWizardSteps.fieldsByStep` es la fuente única: el getter `stepCount` devuelve `fieldsByStep.length`. **Confirmado en el scan**: `registration_form_fields.dart` línea 37.
4. Confirmar que `DomainException` solo tiene `message: String` (sin campo `code`). **Confirmado en el scan**: `lib/core/exceptions/domain_exception.dart` — `const DomainException({required this.message})`. El mecanismo de discriminación de `UNDERAGE_RIDER` es `error.message.contains('UNDERAGE_RIDER')` en el widget. Documentar este mecanismo en el handoff.
5. Confirmar que `RegistrationStepHeader` tiene `required this.subtitle` en su constructor. **Confirmado en el scan**: `registration_step_header.dart` línea 13. El paso waiver DEBE pasar `subtitle:` con la clave l10n `registration_waiverSubtitle`; no se puede omitir ni se modifica el constructor en esta fase.
6. Confirmar que Fase 2 implementó `UNDERAGE_RIDER` como texto del error del backend y que Fase 3 extendió `EventRegistrationModel` con `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`. Sin estas dependencias, los pasos 6 y 7 no pueden completarse — **bloquear y avisar**.

### Paso 1 — Strings l10n en `lib/l10n/app_es.arb`

Agregar las siguientes claves en la sección `registration_`:

```arb
"registration_privacySectionTitle": "Privacidad",
"registration_shareMedicalInfoTitle": "Compartir información médica",
"registration_shareMedicalInfoSubtitle": "El organizador podrá ver tu grupo sanguíneo y EPS durante el evento",
"registration_allowContactTitle": "Permitir contacto del organizador",
"registration_allowContactSubtitle": "El organizador podrá llamarte o escribirte por WhatsApp",
"registration_waiverTitle": "Antes de inscribirte",
"registration_waiverSubtitle": "Lee y acepta los términos antes de continuar",
"registration_waiverBodyV0": "Al inscribirte a esta rodada, reconoces y aceptas que la conducción de motocicletas conlleva riesgos inherentes. Participas de forma voluntaria y bajo tu propia responsabilidad. El organizador y Rideglory no son responsables por accidentes, lesiones o daños que puedan ocurrir durante el evento. Se recomienda contar con póliza de seguro vigente y conducir siempre con el equipo de protección adecuado.",
"registration_waiverCtaButton": "Entiendo, inscribirme",
"registration_waiverCancelButton": "Cancelar",
"registration_underageTitle": "Edad mínima no cumplida",
"registration_underageMessage": "Debes tener al menos 18 años para inscribirte en una rodada.",
"registration_missingBirthDateMessage": "Debes ingresar tu fecha de nacimiento para continuar.",
"registration_goToProfile": "Ir a mi perfil"
```

**Decisión sobre `registration_underageTitle` y `registration_goToProfile`:** ambas claves se usan activamente:
- `registration_underageTitle` se usa como título del error inline en el paso waiver cuando la edad no cumple (en el `Text` de título del error, separado del mensaje de cuerpo). Ver Paso 5.
- `registration_goToProfile` se usa como texto del botón de acción secundaria que aparece en el error de `birthDate` faltante (navega a `AppRoutes.editProfile`), tal como especifica `05-sintesis` línea 172. Ver Paso 5.

No hay claves muertas. Si se decide no implementar la acción de "Ir a mi perfil", eliminar `registration_goToProfile` del ARB antes de cerrar la fase.

Ejecutar `flutter gen-l10n` después de agregar las claves.

### Paso 2 — Constantes en `RegistrationFormFields` y `RegistrationWizardSteps`

En `lib/features/event_registration/constants/registration_form_fields.dart`:

1. Agregar a `RegistrationFormFields`:
   ```dart
   static const String shareMedicalInfo = 'shareMedicalInfo';
   static const String allowOrganizerContact = 'allowOrganizerContact';
   ```

2. Agregar la lista del paso waiver a `RegistrationWizardSteps.fieldsByStep` como quinto elemento:
   ```dart
   <String>[], // Paso 5: Waiver — sin campos FormBuilder; la aceptación la maneja el cubit
   ```
   Con este cambio, `fieldsByStep.length == 5` y el getter `stepCount` retorna 5 automáticamente. El controller y el `RegistrationStepIndicator` lo reflejan sin más cambios.

### Paso 3 — Constante analytics en `AnalyticsParams`

En `lib/core/services/analytics/analytics_params.dart`, bajo los valores canónicos de `step_name` (wizard de registro), agregar:

```dart
/// Paso de aceptación de waiver de riesgos.
static const String stepNameWaiver = 'waiver';
```

### Paso 4 — Switches de privacidad en `registration_medical_step.dart`

En `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart`, al final del `Column` (después de `RegistrationBloodTypeSelector`), agregar:

1. `AppSpacing.gapLg`
2. `ProfileFormSectionHeader(label: context.l10n.registration_privacySectionTitle)` — usar `ProfileFormSectionHeader` de `lib/features/profile/presentation/widgets/profile_form_section_header.dart`. No existe un widget de sección compartido bajo `lib/shared/widgets/form/`, por lo que se importa directamente del feature de perfil.
3. `AppSpacing.gapSm`
4. `AppSwitchTile` con:
   - `name: RegistrationFormFields.shareMedicalInfo`
   - `title: context.l10n.registration_shareMedicalInfoTitle`
   - `subtitle: context.l10n.registration_shareMedicalInfoSubtitle` (obligatorio — cumplimiento WCAG/ajuste A3)
   - `initialValue: false`
5. `AppSwitchTile` con:
   - `name: RegistrationFormFields.allowOrganizerContact`
   - `title: context.l10n.registration_allowContactTitle`
   - `subtitle: context.l10n.registration_allowContactSubtitle` (obligatorio — cumplimiento WCAG/ajuste A3)
   - `initialValue: false`

Regla: usar `AppSwitchTile` (nunca `FormBuilderSwitch` ni `Switch` de Material). El campo `subtitle` de `AppSwitchTile` es `String?` (opcional en la firma del widget), pero esta fase lo hace **obligatorio** pasando siempre un valor no nulo para cumplir WCAG 2.1 AA.

### Paso 5 — Nuevo widget `registration_waiver_step.dart`

Crear `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart`.

**Problema crítico de layout resuelto:**

El `IndexedStack` vive dentro de un `SingleChildScrollView` externo en `RegistrationFormContent`. Usar `Expanded` dentro de `RegistrationWaiverStep` lanzaría una excepción en tiempo de ejecución (`Expanded` requiere un padre `Flex` con altura acotada, pero el `SingleChildScrollView` externo no la tiene). La solución: el texto del waiver se envuelve en `ConstrainedBox(constraints: const BoxConstraints(maxHeight: 280))` con un `SingleChildScrollView` interno. Los botones van como hijos normales de la `Column`.

**Sobre `RegistrationStepHeader`:** el constructor requiere `subtitle` (campo `required` en `registration_step_header.dart`). El paso waiver DEBE pasar `subtitle: context.l10n.registration_waiverSubtitle`. No se elimina ni hace opcional el campo en esta fase.

**Estrategia de mensajes de error (única, sin ambigüedad):**

El cubit emite siempre el texto en español directamente en `error.message` (no claves ARB). Esto garantiza que el widget puede mostrar `error.message` sin necesidad de un mapa de traducción. Excepción: el error `UNDERAGE_RIDER` del backend llega en el `message` tal cual retorna el servicio HTTP — el widget lo detecta con `error.message.contains('UNDERAGE_RIDER')` y reemplaza el mensaje crudo por `context.l10n.registration_underageMessage`. Para los errores locales (edad y fecha faltante), el cubit emite el texto en español directamente, por lo que el widget los muestra con `error.message` sin mapeo adicional.

**Sobre `registration_underageTitle` y `registration_goToProfile`:**
- El error inline se compone de dos `Text`: uno con el título (naranja/`colorScheme.error`) usando `registration_underageTitle`, y uno con el cuerpo (gris/`onSurfaceVariant`) usando el mensaje. Se usan SOLO cuando el error es de edad.
- El botón `AppTextButton(label: context.l10n.registration_goToProfile)` aparece ÚNICAMENTE cuando el error es de `birthDate` faltante. Al pulsarlo, navega a `AppRoutes.editProfile` con `context.pushNamed(AppRoutes.editProfile)`. Esto implementa la acción descrita en `05-sintesis` línea 172. Si `AppRoutes.editProfile` no existe como ruta nominada, el implementador debe verificar el nombre real en `app_router.dart` y documentarlo en el handoff.

**Estructura del widget (clase única, archivo único — regla cero tolerancia):**

```dart
class RegistrationWaiverStep extends StatelessWidget {
  const RegistrationWaiverStep({
    super.key,
    required this.event,
    required this.onSubmit,
    required this.onBack,
  });

  final EventModel event;
  final VoidCallback onSubmit; // Invoca _submitRegistration() del padre
  final VoidCallback onBack;  // Invoca _onBack() del padre

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
      builder: (context, state) {
        final isLoading = state is Loading;
        final errorOrNull = state.mapOrNull(error: (e) => e.error);
        final isUnderage = errorOrNull != null &&
            errorOrNull.message.contains('UNDERAGE_RIDER');
        final isMissingBirthDate = errorOrNull != null &&
            errorOrNull.message.contains('fecha de nacimiento'); // texto español emitido por el cubit

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrationStepHeader(
              icon: Icons.gavel_rounded,
              title: context.l10n.registration_waiverTitle,
              subtitle: context.l10n.registration_waiverSubtitle,
            ),
            AppSpacing.gapMd,
            // Nombre del organizador para contexto (ownerName es String? — omitir si null)
            if (event.ownerName != null) ...[
              Text(
                event.ownerName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,
            ],
            // Texto legal scrollable — acotado por ConstrainedBox para evitar
            // conflicto con el SingleChildScrollView externo de RegistrationFormContent
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Text(context.l10n.registration_waiverBodyV0),
              ),
            ),
            AppSpacing.gapMd,
            // Error inline
            if (errorOrNull != null) ...[
              // Título de error solo para el caso UNDERAGE
              if (isUnderage)
                Text(
                  context.l10n.registration_underageTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                // Para UNDERAGE_RIDER del backend se muestra el texto l10n;
                // para errores locales el cubit ya emitió texto en español.
                isUnderage
                    ? context.l10n.registration_underageMessage
                    : errorOrNull.message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
              // Acción "Ir a mi perfil" solo cuando falta birthDate
              if (isMissingBirthDate)
                AppTextButton(
                  label: context.l10n.registration_goToProfile,
                  onPressed: () => context.pushNamed(AppRoutes.editProfile),
                ),
              AppSpacing.gapSm,
            ],
            // Botón principal CTA
            AppButton(
              label: context.l10n.registration_waiverCtaButton,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              shape: AppButtonShape.pill,
              height: 52,
            ),
            AppSpacing.gapSm,
            // Botón cancelar — usa callback del padre para retroceder al paso anterior
            AppTextButton(
              label: context.l10n.registration_waiverCancelButton,
              onPressed: onBack,
            ),
          ],
        );
      },
    );
  }
}
```

**Notas importantes de la implementación:**

- `onBack` es un callback provisto por el padre (`_onBack()` de `RegistrationFormContent`). El widget NO llama a `context.pop()` ni invoca métodos del cubit directamente para retroceder. La lógica de `_onBack()` en el padre ya maneja `_wizard.previous()` y emite el evento de analytics `registrationStepBack`. Este es el mecanismo ÚNICO de retroceso — no existe otra ruta de back en el waiver.
- `onSubmit` es un callback provisto por el padre (`_submitRegistration()` de `RegistrationFormContent`), que incluye la validación de marcas de vehículos permitidas antes de llamar a `cubit.saveRegistration()`. El widget no llama a `cubit.saveRegistration()` directamente.
- `isMissingBirthDate`: el cubit emite en español `"Debes ingresar tu fecha de nacimiento para continuar."` — el widget puede detectar la condición por contener `'fecha de nacimiento'`. Alternativa más robusta: el implementador puede exponer una constante interna en el cubit para el texto del error de fecha, y el widget importa esa constante para la comparación. Documentar la estrategia elegida en el handoff.
- El `BlocBuilder` envuelve todo el `Column` para que loading, error y disponibilidad del botón CTA se actualicen de forma coherente con un único `build`.

### Paso 6 — Lógica en `RegistrationFormCubit`

En `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart`:

**6a — Validación de edad local en `saveRegistration()`:**

El flujo real de `saveRegistration()` (línea 246+) arranca llamando a `_buildRegistration()` en la línea 247. `_buildRegistration()` a su vez verifica el seam `buildRegistrationOverride` en su línea 310 como primera instrucción, y después llama a `formKey.currentState?.saveAndValidate()`. La guardia de edad DEBE ir en `saveRegistration()`, **antes de la llamada a `_buildRegistration()`**, leyendo `formKey.currentState!.value` directamente sin ejecutar `saveAndValidate()` aún (para dar el mensaje de UX específico de edad antes de activar todos los validators del form).

Punto de inserción exacto: entre la línea 247 (`final registration = _buildRegistration()`) y el inicio de `saveRegistration()`, agregar el bloque de validación de edad:

```dart
Future<void> saveRegistration() async {
  // Guardia de edad: leer birthDate del estado actual del form SIN saveAndValidate().
  // Esto da al rider un error de UX específico antes de activar el resto de validators.
  // Se ejecuta solo si el form existe — si rawState es null, _buildRegistration()
  // retornará null por su propio saveAndValidate(), lo cual es comportamiento correcto.
  final rawState = formKey.currentState;
  if (rawState != null) {
    final formValues = rawState.value;
    final birthDate = formValues[RegistrationFormFields.birthDate] as DateTime?;
    if (birthDate == null) {
      emit(ResultState.error(
        error: const DomainException(
          // Texto en español directamente: el widget muestra error.message tal cual.
          message: 'Debes ingresar tu fecha de nacimiento para continuar.',
        ),
      ));
      return;
    }
    if (_calculateAge(birthDate) < 18) {
      emit(ResultState.error(
        error: const DomainException(
          // Texto en español directamente: el widget muestra error.message tal cual.
          message: 'Debes tener al menos 18 años para inscribirte en una rodada.',
        ),
      ));
      return;
    }
  }

  // Construcción del modelo (incluye saveAndValidate() interno en _buildRegistration())
  final registration = _buildRegistration();
  if (registration == null) return;

  // Analytics + loading + use cases (flujo existente sin cambios)
  _analytics.logEvent(AnalyticsEvents.registrationSubmitAttempted, {
    AnalyticsParams.formMode: isEditing
        ? AnalyticsParams.formModeEdit
        : AnalyticsParams.formModeCreate,
  }).ignore();
  emit(const ResultState.loading());

  final result = isEditing
      ? await _updateRegistrationUseCase(registration.copyWith(), saveToProfile: _saveToProfile)
      : await _addRegistrationUseCase(registration, saveToProfile: _saveToProfile);

  result.fold(
    (error) {
      // El error UNDERAGE_RIDER del backend llega aquí tal cual.
      // El widget lo detecta con error.message.contains('UNDERAGE_RIDER').
      _analytics.logEvent(AnalyticsEvents.registrationSubmitFailed, { ... }).ignore();
      emit(ResultState.error(error: error));
    },
    (saved) async {
      _terminalEventEmitted = true;
      _analytics.logEvent(AnalyticsEvents.registrationSubmitted, { ... }).ignore();
      await _saveRiderProfileUseCase(_buildRiderProfile(registration));
      emit(ResultState.data(data: saved));
    },
  );
}
```

**Sobre el seam `buildRegistrationOverride` y las pruebas unitarias:**

El seam vive en `_buildRegistration()` (línea 310), no en `saveRegistration()`. La guardia de edad está en `saveRegistration()` y lee `formKey.currentState!.value`. Esto crea una tensión con los tests unitarios: los tests no pueden proveer un `FormBuilderState` real. Las estrategias disponibles:

- **Seam de birthDate (recomendado):** exponer `@visibleForTesting DateTime? birthDateOverrideForTesting`. Si no es null, `saveRegistration()` usa este valor en lugar de leer `formKey.currentState`. Permite ejercitar la guardia de edad sin un árbol de widgets.
- **Alternativa:** mockear `formKey.currentState` usando un `MockFormBuilderState` (requiere más setup). Menos idiomático en este codebase.

El implementador elige una estrategia y la documenta en el handoff. El criterio de aceptación 6 y las pruebas unitarias de la guardia de edad DEBEN ser satisfacibles con la estrategia elegida.

**6b — Método `_calculateAge()`:**

```dart
int _calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}
```

**6c — `UNDERAGE_RIDER` del backend:**

El cubit emite `emit(ResultState.error(error: error))` tal cual. No hay transformación del mensaje en el cubit — el widget discrimina con `error.message.contains('UNDERAGE_RIDER')`. Mecanismo único.

**6d — Inyección de campos legales en `_buildRegistration()`:**

En el `EventRegistrationModel(...)` construido al final de `_buildRegistration()` (después del seam, línea 316+), agregar:

```dart
return EventRegistrationModel(
  // ... todos los campos existentes ...
  shareMedicalInfo: formData[RegistrationFormFields.shareMedicalInfo] as bool? ?? false,
  allowOrganizerContact: formData[RegistrationFormFields.allowOrganizerContact] as bool? ?? false,
  riskAcceptedAt: DateTime.now(),
  riskAcceptanceVersion: 'v0.1-2026-06',
);
```

Estos campos nuevos provienen de Fase 3 (`EventRegistrationModel` extendido). Confirmar en pre-flight Paso 0.6 que Fase 3 está completa.

**6e — Patch de switches en `_preloadFromExistingRegistration()` (modo edición):**

```dart
formKey.currentState?.patchValue({
  // ... campos existentes ...
  RegistrationFormFields.shareMedicalInfo: existingRegistration.shareMedicalInfo,
  RegistrationFormFields.allowOrganizerContact: existingRegistration.allowOrganizerContact,
});
```

### Paso 7 — Integración en `registration_form_content.dart`

En `lib/features/event_registration/presentation/registration_form_content.dart`:

**7a — Import del nuevo paso:**
```dart
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart';
```

**7b — Agregar al `IndexedStack`:**
```dart
IndexedStack(
  index: _wizard.currentStep,
  sizing: StackFit.loose,
  children: [
    RegistrationPersonalStep(focusChain: _focusChain),
    RegistrationMedicalStep(focusChain: _focusChain),
    RegistrationEmergencyStep(focusChain: _focusChain),
    RegistrationVehicleStep(onCreateVehicle: _openCreateVehicle),
    RegistrationWaiverStep(           // Paso 5 — índice 4
      event: widget.event,
      onSubmit: _submitRegistration,  // Preserva validación de marca de vehículo
      onBack: _onBack,                // Mismo callback que usa la nav bar para retroceder
    ),
  ],
),
```

**Por qué `onSubmit: _submitRegistration`:** `_submitRegistration()` en `RegistrationFormContent` valida las marcas de vehículos permitidas antes de llamar a `cubit.saveRegistration()`. Si `RegistrationWaiverStep` llamara a `cubit.saveRegistration()` directamente, se omitiría esa validación y se introduciría una regresión. El callback `onSubmit` preserva el flujo completo.

**Por qué `onBack: _onBack`:** `_onBack()` en `RegistrationFormContent` llama a `_wizard.previous()` y emite el evento de analytics `registrationStepBack`. Usar el mismo callback que usa la `RegistrationWizardNavigationBar` garantiza coherencia. No se duplica lógica. Este es el mecanismo ÚNICO de retroceso del wizard — no hay otra ruta de back en el waiver.

**7c — Registrar `stepNameWaiver` en `_stepNameFor()`:**
```dart
static String _stepNameFor(int stepIndex) {
  const names = [
    AnalyticsParams.stepNamePersonal,
    AnalyticsParams.stepNameMedical,
    AnalyticsParams.stepNameEmergency,
    AnalyticsParams.stepNameVehicle,
    AnalyticsParams.stepNameWaiver, // índice 4
  ];
  if (stepIndex < 0 || stepIndex >= names.length) return 'unknown';
  return names[stepIndex];
}
```

**7d — Ocultar `RegistrationWizardNavigationBar` en el paso waiver:**

```dart
// Antes:
BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
  builder: (context, state) {
    return RegistrationWizardNavigationBar( ... );
  },
),

// Después:
if (!_wizard.isLastStep)
  BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
    builder: (context, state) {
      return RegistrationWizardNavigationBar( ... );
    },
  ),
```

No se agrega parámetro nuevo a `RegistrationWizardNavigationBar`. El widget existente no cambia.

**7e — Analytics al avanzar al paso waiver (criterio 12):**

`registrationStepAdvanced(step_index: 4, step_name: 'waiver')` se emite en `_onNext()` del padre (`registration_form_content.dart`), el cual es el único mecanismo por el que el rider avanza de un paso al siguiente. Cuando el rider está en el paso 4 (índice 3, vehículo) y presiona "Siguiente" en la `RegistrationWizardNavigationBar`, `_onNext()` llama a `_wizard.next()` (que mueve a `currentStep == 4`) y luego llama a `cubit.onStepAdvanced(4, _stepNameFor(4))`, donde `_stepNameFor(4) == AnalyticsParams.stepNameWaiver == 'waiver'`. El evento analytics es emitido por `cubit.onStepAdvanced()` (línea 82-86 actual) que llama a `_analytics.logEvent(AnalyticsEvents.registrationStepAdvanced, ...)`. No se requiere ningún cambio adicional en la emisión de analytics — solo registrar el índice 4 en `_stepNameFor()` (Paso 7c) es suficiente.

La barra de navegación se oculta en el PASO WAIVER (índice 4), no en el paso vehículo (índice 3). Al avanzar desde el paso vehículo al waiver, la `RegistrationWizardNavigationBar` está visible y su "Siguiente" dispara `_onNext()`. Una vez en el waiver, la barra se oculta (`if (!_wizard.isLastStep)`). Los botones del waiver (CTA y Cancelar) no emiten `registrationStepAdvanced` — solo el submit final o el retroceso emiten sus eventos correspondientes.

### Paso 8 — Verificación final

1. Ejecutar `dart analyze` — cero errores.
2. Ejecutar `flutter gen-l10n` — sin advertencias.
3. Hot restart en simulador — confirmar que el wizard muestra 5 puntos en el `RegistrationStepIndicator`.
4. Navegar hasta el paso médico — confirmar que los dos `AppSwitchTile` con subtítulos aparecen bajo el encabezado "PRIVACIDAD".
5. Navegar al paso 5 (waiver) — confirmar texto scrollable dentro de `ConstrainedBox`, botón "Entiendo, inscribirme" y botón "Cancelar". Confirmar que la `RegistrationWizardNavigationBar` **no** aparece.
6. Tocar "Cancelar" en el waiver — confirmar que vuelve al paso 4 (vehículo), no cierra la página.
7. Ingresar una fecha de nacimiento con edad < 18, llegar al waiver y tocar "Entiendo, inscribirme" — debe mostrar el mensaje de edad inline, sin llamar al backend.
8. Verificar con curl/log que el body del POST contiene `riskAcceptedAt`, `riskAcceptanceVersion`, `shareMedicalInfo` y `allowOrganizerContact`.

---

## Archivos a crear/modificar (rutas reales)

| Ruta | Acción | Qué cambia |
|------|--------|------------|
| `lib/l10n/app_es.arb` | Modificar | +14 claves l10n de la fase (waiver, subtitle del header, switches de privacidad, mensajes de edad, goToProfile, underageTitle) |
| `lib/features/event_registration/constants/registration_form_fields.dart` | Modificar | +2 constantes en `RegistrationFormFields` (`shareMedicalInfo`, `allowOrganizerContact`); +1 lista vacía `[]` en `RegistrationWizardSteps.fieldsByStep` como paso 5 |
| `lib/core/services/analytics/analytics_params.dart` | Modificar | +1 constante `stepNameWaiver = 'waiver'` bajo los valores de step_name del wizard de registro |
| `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` | Modificar | +sección "Privacidad" con `ProfileFormSectionHeader` + 2 `AppSwitchTile` (`shareMedicalInfo`, `allowOrganizerContact`) con subtítulos obligatorios al final del step |
| `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` | **Crear** | Nuevo paso 5 del wizard: `RegistrationStepHeader` con `subtitle` l10n, nombre del organizador condicional (`event.ownerName`), texto legal en `ConstrainedBox(maxHeight: 280)+SingleChildScrollView`, error inline con manejo diferenciado de `UNDERAGE_RIDER` vs errores locales, acción "Ir a mi perfil" para error de fecha, botón CTA con `onSubmit` callback, botón "Cancelar" con `onBack` callback |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | Modificar | +guardia de edad en `saveRegistration()` antes de `_buildRegistration()` (lee `birthDate` de `formKey.currentState!.value`), +`_calculateAge()`, +seam de `birthDateOverrideForTesting` para pruebas unitarias, +campos legales en `_buildRegistration()` (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`), +patch de booleanos en `_preloadFromExistingRegistration()` |
| `lib/features/event_registration/presentation/registration_form_content.dart` | Modificar | +import `RegistrationWaiverStep`, +`RegistrationWaiverStep(event, onSubmit: _submitRegistration, onBack: _onBack)` al `IndexedStack`, +`AnalyticsParams.stepNameWaiver` en `_stepNameFor()` en índice 4, +condición `if (!_wizard.isLastStep)` envolviendo el `BlocBuilder` de `RegistrationWizardNavigationBar` |

---

## Contratos / API rideglory-api

Ninguno nuevo en esta fase. Los contratos (campos `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` en `CreateRegistrationDto` / `UpdateRegistrationDto` / `EventRegistrationDto`) y el código de error `UNDERAGE_RIDER` (422) son prerequisito de las Fases 1 y 2 respectivamente. Esta fase solo consume lo que Fases 1-3 ya establecieron.

---

## Cambios de datos / migraciones

Ninguno en esta fase. Las columnas de DB (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) fueron creadas en la Fase 1.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Wizard de 5 pasos visible:** el `RegistrationStepIndicator` muestra 5 puntos en todos los dispositivos. El cambio de 4 a 5 se produjo únicamente por agregar `<String>[]` a `RegistrationWizardSteps.fieldsByStep`; `registration_wizard_controller.dart` y `registration_step_indicator.dart` no fueron modificados.

2. **Switches de privacidad con subtítulos:** en el paso médico (paso 2), al hacer scroll hasta el final, se ven dos `AppSwitchTile` bajo el encabezado "PRIVACIDAD". Cada switch muestra su subtítulo explicativo (campo `subtitle` no nulo en ambos). Los switches son instancias de `AppSwitchTile`, nunca `Switch`, `SwitchListTile` ni `FormBuilderSwitch`.

3. **Valores por defecto correctos:** al abrir el wizard en modo creación, ambos switches (`shareMedicalInfo`, `allowOrganizerContact`) inician en `false`. En modo edición, se precargan con los valores de la inscripción existente.

4. **Paso waiver como último paso:** el paso 5 (índice 4) muestra el título `registration_waiverTitle`, el subtítulo `registration_waiverSubtitle`, el texto scrollable `registration_waiverBodyV0` dentro de un `ConstrainedBox`, el botón "Entiendo, inscribirme" y el botón "Cancelar". La `RegistrationWizardNavigationBar` no aparece en este paso.

5. **Cancelar en el waiver retrocede al paso anterior:** tocar "Cancelar" en el paso waiver lleva al paso 4 (vehículo, índice 3). No cierra la página de inscripción. El mecanismo es el callback `onBack` del padre, que invoca `_onBack()` de `RegistrationFormContent`.

6. **Validación de edad local:** si el rider ingresa una `birthDate` con edad < 18 y llega al waiver, al tocar "Entiendo, inscribirme" el cubit emite un error con el texto en español sin llamar al backend. El mensaje aparece inline en el paso waiver. El cubit emite el texto directamente (no una clave ARB) para que el widget muestre `error.message` sin mapeo adicional.

7. **Error `UNDERAGE_RIDER` del backend:** si el backend retorna un error cuyo `message` contiene el string `UNDERAGE_RIDER`, el paso waiver muestra `registration_underageTitle` como título y `registration_underageMessage` como cuerpo (no el mensaje crudo del servidor). Mecanismo: `error.message.contains('UNDERAGE_RIDER')` en `RegistrationWaiverStep`. No existe campo `error.code`.

8. **`birthDate` faltante con acción de perfil:** si `birthDate` es nulo en el form, `saveRegistration()` emite error con el mensaje de `registration_missingBirthDateMessage` sin llamar al backend. El paso waiver muestra el error y un botón `AppTextButton` "Ir a mi perfil" que navega a `AppRoutes.editProfile`.

9. **`riskAcceptedAt` en el payload:** en una inscripción exitosa, el body del `POST /events/:id/registrations` contiene `riskAcceptedAt` (timestamp ISO) y `riskAcceptanceVersion: 'v0.1-2026-06'`. Verificable con curl o log.

10. **`shareMedicalInfo` y `allowOrganizerContact` en el payload:** el body del POST contiene los campos con el valor seleccionado por el rider. Verificable con curl o log (prerequisito de C1 de Fase 3 — `toJson()` correcto).

11. **Validación de marca de vehículo preservada:** el CTA del waiver invoca `_submitRegistration()` del padre (via `onSubmit` callback), no `cubit.saveRegistration()` directamente. La lógica de marcas permitidas (`availableBrands`) no es bypasseada.

12. **Analítica al avanzar al paso waiver:** al navegar desde el paso vehículo (índice 3) al paso waiver (índice 4) usando el botón "Siguiente" de la `RegistrationWizardNavigationBar`, se emite `registrationStepAdvanced` con `step_index: 4` y `step_name: 'waiver'`. Origen del evento: `_onNext()` en `RegistrationFormContent` → `cubit.onStepAdvanced(4, _stepNameFor(4))`. No se requiere lógica adicional en el widget del waiver ni en sus botones para este criterio.

13. **`event.ownerName` nullable manejado:** si `event.ownerName` es `null`, el `Text` del organizador no se renderiza. No aparece un string vacío ni un error de null.

14. **Cero strings hardcodeados:** todos los textos visibles al rider vienen de `context.l10n`. `dart analyze` no reporta strings literales de UI en los archivos modificados.

15. **`dart analyze` limpio:** cero errores y cero warnings de lint (excluyendo archivos `.g.dart` y `.freezed.dart`).

---

## Pruebas

### Unitarias (`registration_form_cubit_test.dart`)

- **Edad < 18 local:** dado `birthDateOverrideForTesting` con 17 años 364 días, `saveRegistration()` emite `ResultState.error()` con el texto en español sin llegar a llamar al use case. El seam `birthDateOverrideForTesting` aísla la prueba del árbol de widgets.
- **Edad exactamente 18:** dado `birthDateOverrideForTesting` con 18 años cumplidos hoy, el cubit NO rechaza localmente (avanza al use case — verificar con `buildRegistrationOverride` que `_buildRegistration()` se llama).
- **`birthDate` nulo:** cuando `birthDateOverrideForTesting` es `null` explícito (o el seam retorna null), `saveRegistration()` emite `ResultState.error()` con el mensaje de fecha faltante en español.
- **`_buildRegistration()` incluye campos legales:** verificar que el modelo construido tiene `riskAcceptedAt != null`, `riskAcceptanceVersion == 'v0.1-2026-06'`, y los valores de `shareMedicalInfo` / `allowOrganizerContact` correctos. Ejercitar via `buildRegistrationOverride`.
- **Error backend emitido tal cual:** cuando el use case retorna `Left(DomainException(message: '...UNDERAGE_RIDER...'))`, el cubit emite `ResultState.error()` con ese mismo error sin transformarlo.

### Widget (`registration_waiver_step_test.dart`)

- Renderiza el título, subtítulo (via `RegistrationStepHeader`), texto del waiver y los dos botones.
- Cuando `event.ownerName == null`, no hay widget `Text` con el nombre del organizador.
- Cuando el cubit está en `Loading`, el `AppButton` muestra `isLoading: true` y está deshabilitado.
- Cuando el cubit emite `Error` con mensaje que contiene `UNDERAGE_RIDER`, el widget muestra `registration_underageTitle` y `registration_underageMessage` (no el mensaje crudo). No aparece el botón "Ir a mi perfil".
- Cuando el cubit emite `Error` con mensaje que contiene `'fecha de nacimiento'` (error local de fecha faltante), el widget muestra el mensaje y el botón "Ir a mi perfil".
- Cuando el cubit emite `Error` con otro mensaje (error genérico), muestra el mensaje crudo inline. No aparece `registration_underageTitle` ni el botón "Ir a mi perfil".
- El botón "Cancelar" invoca el callback `onBack` (no `context.pop()` ni método del cubit).
- El botón "Entiendo, inscribirme" invoca el callback `onSubmit`.

### Widget (`registration_medical_step_test.dart`)

- El paso médico renderiza exactamente 2 `AppSwitchTile` (para `shareMedicalInfo` y `allowOrganizerContact`).
- Cada `AppSwitchTile` tiene `subtitle` no nulo (campos `registration_shareMedicalInfoSubtitle` y `registration_allowContactSubtitle`).

### Integración (manual en simulador)

- Flujo completo: Personal → Medical → Emergency → Vehicle → Waiver → submit exitoso → pop de la página de inscripción.
- Flujo de cancelación desde el waiver: botón "Cancelar" retrocede al paso Vehicle (índice 3), no cierra la página.
- Modo edición: los switches de privacidad se precargan con los valores guardados.
- Verificar con log/curl que el body del POST incluye los 4 campos legales.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|-----------|
| R1 | `RegistrationWizardNavigationBar` renderiza botones duplicados en el paso waiver | Alta si no se aplica la corrección | UX rota — dos botones de submit en pantalla | Solución concreta en Paso 7d: envolver el `BlocBuilder` de la nav bar con `if (!_wizard.isLastStep)`. No agregar parámetro nuevo a `RegistrationWizardNavigationBar`. |
| R2 | `error.message.contains('UNDERAGE_RIDER')` es frágil si el backend cambia el formato del mensaje | Baja en esta iteración (sin usuarios reales) | El rider ve el mensaje crudo del servidor en lugar del mensaje l10n | Documentar el contrato en el handoff: Fase 2 debe incluir `UNDERAGE_RIDER` literalmente en el mensaje del error 422. Si en el futuro se agrega campo `code` a `DomainException`, migrar a `error.code == 'UNDERAGE_RIDER'`. |
| R3 | `Expanded + SingleChildScrollView` dentro del `IndexedStack` lanza excepción en runtime | Confirmado — el `IndexedStack` está en un `SingleChildScrollView` sin altura acotada | Pantalla en blanco o excepción de layout en el paso waiver | Solución concreta en Paso 5: `ConstrainedBox(maxHeight: 280) + SingleChildScrollView` interno. No usar `Expanded`. |
| R4 | `_submitRegistration()` con validación de marca bypasseada si el widget llama a `cubit.saveRegistration()` directamente | Alta si no se usa el callback | Regresión: riders con marcas no permitidas pueden inscribirse desde el waiver | Solución concreta en Pasos 5 y 7b: `onSubmit: _submitRegistration` (callback del padre). Criterio de aceptación 11 cubre este caso. |
| R5 | El botón "Cancelar" cierra la página completa en lugar de retroceder al paso anterior | Alta si se usa `context.pop()` directamente | UX inconsistente — el rider pierde todo el progreso del wizard | Solución concreta en Pasos 5 y 7b: `onBack: _onBack` (callback del padre). Criterio de aceptación 5 y prueba widget correspondiente cubren este caso. |
| R6 | `event.ownerName` nullable no manejado — null check exception en `RegistrationWaiverStep` | Media — el campo es `String?` en `EventModel` | Crash en el paso waiver | Solución concreta en Paso 5: `if (event.ownerName != null) ... Text(event.ownerName!)`. Criterio 13 y prueba widget cubren el caso null. |
| R7 | Fases 2 y 3 no completadas cuando se ejecuta esta fase | Alta como bloqueo de coordinación | `EventRegistrationModel` no tiene los campos nuevos; backend no retorna `UNDERAGE_RIDER` | Gate en Paso 0.6: confirmar explícitamente antes de modificar `_buildRegistration()`. Si no están listos, bloquear y avisar. |
| R8 | Guardia de edad en `saveRegistration()` no ejercitable en tests unitarios sin árbol de widgets | Media — los tests del cubit no tienen `FormBuilderState` | Las pruebas de la guardia de edad no pueden ejercitar la ruta de producción | Solución en Paso 6a: seam `birthDateOverrideForTesting` (análogo a `buildRegistrationOverride`). El implementador elige y documenta la estrategia en el handoff. |
| R9 | `registration_goToProfile` como clave muerta si la ruta `AppRoutes.editProfile` no existe nominadamente | Media | Error de navegación en runtime al pulsar "Ir a mi perfil" | Verificar el nombre real de la ruta de edición de perfil en `app_router.dart` antes de implementar. Si la ruta no tiene nombre nominado, agregarlo o navegar de otra forma. |

---

## Dependencias (fases prerequisito y por qué)

**Fase 2 — Validación de edad y ofuscación condicional en backend:**
- Provee el código de error semántico `UNDERAGE_RIDER` embebido en el mensaje del error 422. Sin esto, el string `'UNDERAGE_RIDER'` no aparece en `error.message` y el widget no puede discriminar el error de edad de otros errores de validación.
- El campo `riskAcceptedAt` es validado en backend (rechaza si null en nuevas inscripciones) — definido en Fase 1 y aplicado en Fase 2.

**Fase 3 — Modelos y DTOs Flutter:**
- Provee `EventRegistrationModel` con `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`.
- Provee `EventRegistrationModelExtension.toJson()` actualizado con los 4 campos — sin esto, los campos legales no viajan en el payload del POST.
- Provee las constantes de campo que esta fase reutiliza en `_buildRegistration()` y `_preloadFromExistingRegistration()`.

---

## Ejecucion recomendada

**Nivel: `full`**

**Por qué este nivel:**

1. **UI cross-cutting sobre wizard existente con tres artefactos a reconciliar:** `RegistrationWizardSteps.fieldsByStep` (fuente única de `stepCount`), `_stepNameFor()` en `registration_form_content.dart` (analytics), y `RegistrationStepIndicator` (visualización) deben mantenerse coherentes. Un cambio incorrecto en cualquiera puede romper el wizard completo o producir discrepancias en analytics.

2. **Consentimientos WCAG con subtítulos obligatorios:** los `AppSwitchTile` de privacidad deben tener subtítulos (ajuste A3 del Plan Review). El nivel `full` garantiza que el auditor Opus verifica este requisito de accesibilidad antes de aprobar.

3. **Doble validación de edad (local + backend) con mapeo explícito de código de error semántico:** la lógica de `_calculateAge()` tiene edge cases (fecha de cumpleaños hoy) y el mecanismo `error.message.contains('UNDERAGE_RIDER')` es un contrato informal entre backend (Fase 2) y widget (esta fase). El auditor verifica la consistencia del contrato y que el seam de testing está correctamente implementado.

4. **Múltiples archivos nuevos con regla de cero tolerancia de widget por archivo:** `RegistrationWaiverStep` debe ser un archivo independiente con su clase única. El nivel `full` incluye revisión de que no se colaron métodos `_buildXxx()` que retornan widgets.

5. **Strings l10n extensos (14 claves nuevas):** el auditor verifica que ningún string visible al usuario quedó hardcodeado, que todas las claves declaradas en el ARB se usan activamente, y que ninguna clave queda muerta.

6. **Pre-flight con gates verificables agrega complejidad de coordinación:** el implementador debe confirmar el estado de Fases 2 y 3 antes de proceder. Si alguna dependencia no está lista, la fase debe bloquearse. El auditor verifica que el implementador no omitió este gate.

7. **Decisiones de layout y callback con impacto en corrección:** el `ConstrainedBox` en lugar de `Expanded`, la condición `if (!_wizard.isLastStep)` para ocultar la nav bar, y los callbacks `onSubmit`/`onBack` (mecanismo único de retroceso desde el waiver) son decisiones con impacto en la corrección del wizard. El nivel `full` permite iterar hasta un resultado correcto.
