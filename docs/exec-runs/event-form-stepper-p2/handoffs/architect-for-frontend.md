> Slim handoff — lee esto antes de docs/exec-runs/event-form-stepper-p2/handoffs/architect.md

# Architect → Frontend — event-form-stepper-p2

**Fecha:** 2026-06-11T22:53:34Z

## Contexto rápido

Fase 100% Flutter. Sin cambios en backend, dominio, ni DI. El `EventFormCubit` ya tiene todos los métodos necesarios: `nextStep`, `prevStep`, `goToStep`, `validateStep`, `isCurrentStepValid`, `saveDraft`, `buildEventToSave`. El `shimmer: ^3.0.0` ya está en `pubspec.yaml`.

## Decisiones críticas

**D-14 (bloqueante):** El `FormBuilder(key: cubit.formKey, initialValue: ...)` NO puede vivir en `EventFormStep1`. Debe vivir en un widget wrapper que sea ancestro de todos los 4 steps en el `IndexedStack`. Si el `FormBuilder` está dentro de un solo step, `validateStep()` falla en los otros pasos porque `formKey.currentState` es null. Patrón correcto:

```dart
// En EventFormView (modo creación)
body: FormBuilder(
  key: cubit.formKey,
  initialValue: _getInitialValues(cubit),
  child: IndexedStack(
    index: state.currentStep,
    children: const [
      EventFormStep1(),
      EventFormStep2(),
      EventFormStep3(),
      EventFormStep4Review(),
    ],
  ),
),
```

## Nuevos archivos a crear (`lib/features/events/presentation/form/widgets/steps/`)

| Archivo | Descripción |
|---------|-------------|
| `event_step_indicator.dart` | 4 círculos: completado=naranja+check+`AppColors.darkBgPrimary`, activo=naranja+número+`AppColors.darkBgPrimary`, futuro=`colorScheme.surfaceContainerHighest`+número+`colorScheme.onSurfaceVariant` |
| `event_step_nav_bar.dart` | Steps 1-3: botón "Atrás" (step 0 oculto) + "Continuar" (llama `cubit.validateStep` antes de `nextStep`). Step 4: `AppButton` "Publicar" + `AppTextButton` "Guardar borrador" |
| `cover_picker_sheet.dart` | Bottom sheet: solo botón "Subir desde galería" → `context.read<FormImageCubit>().pickImageFromGallery()`. Sin IA. |
| `event_form_step1.dart` | Cover (`BlocBuilder<FormImageCubit>` + `CoverPickerSheet`) + `EventFormBasicInfoSection` + `EventFormDateTimeSection` |
| `event_form_step2.dart` | `EventFormDifficultySection` + `EventFormEventTypeSection` + `EventFormMultiBrandSection` + `EventFormMaxParticipantsSection` + `EventFormPriceSection` |
| `event_form_step3.dart` | `EventFormLocationsSection` |
| `event_form_step4_review.dart` | 3 cards de resumen (Básico, Configuración, Ruta); cada card con botón "Editar" → `cubit.goToStep(n)`; dificultad con llamas naranja (`AppColors.primary`); sin `flutter_quill` ni `MapboxMap` |
| `search_skeleton_list.dart` | 3 filas shimmer; `Shimmer.fromColors(baseColor: Color(0xFF383838), highlightColor: Color(0xFF505050), ...)` |
| `pulsing_map_dot.dart` | `StatefulWidget` con `AnimationController`; ring pulsante 44 px + dot 14 px naranja. `dispose()` obligatorio. Visible solo cuando 0 waypoints. |

## Archivos existentes a modificar

| Archivo | Qué cambiar |
|---------|-------------|
| `event_form_view.dart` | Body: branch `isEditing`. Creación → `FormBuilder` + `AnimatedSwitcher(key: ValueKey(state.currentStep))` sobre `IndexedStack`. Edición → `EventFormContent` + `// TODO(stepper-edit)`. AppBar: step indicator en `bottom` slot; "Cancelar" `AppTextButton` derecha en creación. Eliminar `EventFormBottomBar`. |
| `lib/design_system/atoms/buttons/app_circle_icon_button.dart` | `_size`: 36 → 40 (B-5) |
| `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` | Botón eliminar: wrap en `SizedBox(44, 44)` centrado (B-3) |
| `lib/features/events/presentation/form/screens/route_map_area.dart` | Recenter container: `width: 36, height: 36` → `width: 44, height: 44` (B-4) |
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` | Rama `isLoading`: spinner → `SearchSkeletonList`. Ítem activo (i==0): añadir `border: const Border(left: BorderSide(color: AppColors.primary, width: 4))` y fondo `Color(0xFF1C1C24)` (S-2) |

## ARB keys a agregar en `lib/l10n/app_es.arb`

Todos con prefijo `event_step_review_*` o `event_cover_*`. Ejemplos mínimos necesarios:

```
"event_step_review_basicSection": "Información básica"
"event_step_review_detailsSection": "Configuración"
"event_step_review_routeSection": "Ruta"
"event_step_review_editButton": "Editar"
"event_cover_picker_title": "Portada del evento"
"event_cover_picker_gallery": "Subir desde galería"
```

(Agregar los que falten para cubrir todo el texto visible en Step 4 y `CoverPickerSheet`.)

## Código muerto a eliminar (verificar `grep` imports = vacío antes de borrar)

1. `event_form_content.dart`
2. `event_form_bottom_bar.dart`
3. `draft_link.dart`
4. `publish_button.dart`

## Colores / tokens

- Sobre acento naranja (`AppColors.primary`): texto e íconos siempre `AppColors.darkBgPrimary` — NUNCA `Colors.white`.
- Skeleton: `baseColor: Color(0xFF383838)`, `highlightColor: Color(0xFF505050)`.
- Ítem activo autocomplete: borde izquierdo naranja 4 px + fondo `Color(0xFF1C1C24)`.

## Reglas de arquitectura activas

- 1 widget por archivo (sin excepciones en `steps/`).
- Prohibidos métodos `Widget _buildXxx()`.
- Todo texto visible en ARB + `context.l10n.<key>`.
- `AnimationController` → `dispose()` obligatorio.

> Full detail: docs/exec-runs/event-form-stepper-p2/handoffs/architect.md
