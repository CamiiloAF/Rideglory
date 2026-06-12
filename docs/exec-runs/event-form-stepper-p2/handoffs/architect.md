# Architect handoff — event-form-stepper-p2

**Date:** 2026-06-11T22:53:34Z
**Status:** done

---

## Decisiones

| # | Decisión | Razonamiento |
|---|----------|-------------|
| D-1 | **No hay cambios en rideglory-api.** Esta fase es 100% Flutter — presentación y UX. El cubit ya tiene `nextStep`, `prevStep`, `goToStep`, `validateStep`, `saveDraft`, `buildEventToSave`. No hay nuevos endpoints ni modelos de dominio. | El PRD §3 lo declara explícitamente; los métodos de navegación ya existen en `EventFormCubit` (Fase 1). |
| D-2 | **`shimmer ^3.0.0` ya está en `pubspec.yaml` (línea 102).** No hay que tocar `pubspec.yaml`. | Verificado en el árbol de trabajo actual. |
| D-3 | **`AppCircleIconButton` mide 36×36 px (hardcoded `_size = 36`).** Para cumplir B-5 (40 px back button) el Frontend debe aumentar `_size` a 40 en el átomo, o usar un `SizedBox(40, 40)` wrapper en el AppBar únicamente para este contexto. Decisión: ampliar `_size` a 40 en `AppCircleIconButton` ya que el PRD especifica 40×40 y el átomo es la fuente de verdad para todos los botones circulares. | Revisado `app_circle_icon_button.dart` línea 43. |
| D-4 | **`AppPlaceSuggestionsDropdown` muestra un spinner cuando `isLoading = true`.** Para `SearchSkeletonList` (S-5): el Frontend debe modificar `AppPlaceSuggestionsDropdown` para reemplazar el spinner por 3 filas skeleton cuando `isLoading` es `true`. `SearchSkeletonList` es el nuevo widget de skeleton (1 widget por archivo), importado por `AppPlaceSuggestionsDropdown`. | Revisado `app_place_suggestions_dropdown.dart` — la rama `if (isLoading)` hoy renderiza un `CircularProgressIndicator`. |
| D-5 | **`EventFormView` usa el scaffold actual con `AppFormNavHeader` + `EventFormContent` + `EventFormBottomBar`.** El refactor convierte el `body` a un `IndexedStack` con 4 hijos (Steps 1-4); el `AppBar` evoluciona para mostrar el `EventStepIndicator` en el slot `bottom`; `EventFormBottomBar` se elimina; la barra de navegación de pasos (`EventStepNavBar`) vive dentro de cada step o en un slot bajo el `IndexedStack`. | Análisis de `event_form_view.dart`, `event_form_content.dart`, `event_form_bottom_bar.dart`. |
| D-6 | **`CoverPickerSheet` va en `steps/` no en `sections/`.** La portada cambia del formulario plano (`FormImageSection` inline) a un bottom-sheet que se abre desde Step 1. | PRD §3 lo sitúa en `widgets/steps/`. |
| D-7 | **`EventFormBasicInfoSection` no tiene `AppCityAutocomplete` ni `EventFormFields.city` hoy.** El PRD dice "eliminar `AppCityAutocomplete`" — verificado que no existe en la sección actual. Ningún cambio requerido en el campo ciudad; `meetingPointName` ya se usa como proxy. | `grep` en el árbol retorna vacío. |
| D-8 | **`PulsingMapDot` requiere `AnimationController` — `dispose()` obligatorio.** Es un `StatefulWidget` con `AnimationController`. El lifecycle de disposal debe estar explícito en el código. | Constraint §7 del PRD. |
| D-9 | **`EventRouteConfigScreen` recenter button (B-4) mide 36×36 px.** Confirmado en `route_map_area.dart` líneas 88-93 (`width: 36, height: 36`). Debe subir a 44×44. | Leído `route_map_area.dart`. |
| D-10 | **Delete waypoint button (B-3) usa `GestureDetector` + `Padding(all: 4)`.** Touch target efectivo ≈ 24 px (icono 16 + padding 8). Debe ser 44×44. Frontend debe usar `SizedBox(44, 44)` + `Center` o `GestureDetector(behavior: HitTestBehavior.opaque)` con `SizedBox` mínimo 44. | `waypoint_item_card.dart` líneas 43-54. |
| D-11 | **Step4 necesita ARB keys nuevos.** Los keys del stepper (`event_step_*`) existen (Fase 1). Los keys de contenido del Step 4 (secciones de revisión, labels "Editar", llamas de dificultad, título portada) no existen aún — deben añadirse al `app_es.arb`. | `grep` sobre el ARB muestra `event_step_reviewAndPublish` pero ningún key de tarjetas de revisión. |
| D-12 | **`EventFormContent` se elimina; su lógica `_getInitialValues` se mueve a `EventFormStep1`.** Step1 necesita construir el `FormBuilder` con los valores iniciales. La lógica de initialValues ya está en `EventFormContent` — debe migrar a `EventFormStep1` (o a un helper). | Analizado `event_form_content.dart`. |
| D-13 | **`EventFormView` modo edición: branch `isEditing`.** Cuando `isEditing == true`, el body sigue siendo `EventFormContent` (scroll plano) con `// TODO(stepper-edit)`. El `IndexedStack` solo se activa en creación. | Criterio de aceptación 9 del PRD. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | modify | Refactorizar: body → `IndexedStack` con 4 steps en creación; `AppFormNavHeader` con `bottom: EventStepIndicator`; modo edición conserva `EventFormContent`; `AppTextButton` "Cancelar" en modo creación; eliminar referencias a `EventFormBottomBar`/`EventFormContent` (en modo creación) | med |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | delete | Código muerto tras mover lógica a `EventFormStep1`; verificar cero imports antes de eliminar | med |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | delete | Código muerto — reemplazado por `EventStepNavBar` en Step4 | low |
| `lib/features/events/presentation/form/widgets/draft_link.dart` | delete | Código muerto — funcionalidad migrada a `EventFormStep4Review` | low |
| `lib/features/events/presentation/form/widgets/publish_button.dart` | delete | Código muerto — funcionalidad migrada a `EventFormStep4Review` | low |
| `lib/features/events/presentation/form/widgets/steps/event_step_indicator.dart` | create | Nuevo widget: círculos de progreso (completado con check naranja, activo naranja, futuro gris) | low |
| `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` | create | Nuevo widget: barra inferior con botones "Atrás"/"Continuar" o "Publicar"/"Borrador" en Step 4 | low |
| `lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` | create | Nuevo widget: bottom sheet con solo "Subir desde galería"; sin IA | low |
| `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` | create | Step 1: Cover + Básico (`EventFormBasicInfoSection` + `EventFormDateTimeSection`); hereda `_getInitialValues` | med |
| `lib/features/events/presentation/form/widgets/steps/event_form_step2.dart` | create | Step 2: Detalles (`EventFormDifficultySection` + `EventFormEventTypeSection` + `EventFormMultiBrandSection` + `EventFormMaxParticipantsSection` + `EventFormPriceSection`) | low |
| `lib/features/events/presentation/form/widgets/steps/event_form_step3.dart` | create | Step 3: Ruta (`EventFormLocationsSection`) | low |
| `lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` | create | Step 4: Resumen con cards Básico/Configuración/Ruta; botones "Editar" por card; difficulty llamas naranja; `AppButton` "Publicar" + `AppTextButton` "Guardar borrador" | med |
| `lib/features/events/presentation/form/widgets/steps/search_skeleton_list.dart` | create | 3 filas shimmer — `Shimmer.fromColors` con colores dark (`0xFF383838`/`0xFF505050`) | low |
| `lib/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart` | create | Ring pulsante 44 px + dot 14 px naranja — `StatefulWidget` con `AnimationController` + `dispose()` | low |
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` | modify | Reemplazar spinner con `SearchSkeletonList` cuando `isLoading == true`; añadir borde naranja 4 px izquierdo al resultado activo (S-2) | low |
| `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` | modify | Touch target del botón eliminar: `SizedBox(44, 44)` con ícono centrado (B-3) | low |
| `lib/features/events/presentation/form/screens/route_map_area.dart` | modify | Recenter button: de 36×36 a 44×44 (B-4) | low |
| `lib/design_system/atoms/buttons/app_circle_icon_button.dart` | modify | `_size` de 36 a 40 (B-5 — back button 40 px) | low |
| `lib/l10n/app_es.arb` | modify | Añadir ARB keys para Step 4 review (tarjetas de revisión, "Editar" contextual, portada), `CoverPickerSheet` y texto de llamas de dificultad | low |

---

## Contratos rideglory-api

**Ninguno.** Esta fase es Flutter-only — cero cambios en el backend.

---

## Datos / migraciones

**Ninguno.** Sin cambios en modelos de dominio, DTOs, ni base de datos.

---

## Env deltas

**Ninguno.**

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `IndexedStack` mantiene Mapbox (Step 3) y Quill (Step 1) vivos simultáneamente — posible presión de memoria | Aceptado en §3 "No entra" — perfilado diferido. Frontend debe comentar `// NOTE: IndexedStack keeps MapboxMap + QuillEditor alive simultaneously.` |
| `FormBuilder` key compartido entre steps: si el `FormBuilder` vive en `EventFormStep1` y otras secciones leen `FormBuilder.of(context)`, pueden no encontrar el estado cuando están en Step 2/3/4 | El `FormBuilder` y su `key` deben vivir en el nodo ancestro común (probablemente `EventFormView` o un wrapper sobre el `IndexedStack`), no en `EventFormStep1`. Ver D-14 abajo. |
| Modificar `AppCircleIconButton._size` (36→40) afecta todos los back buttons de la app | Riesgo low: el cambio es +4 px y mejora accesibilidad. Visual regression en pantallas con leading tight. |
| Modificar `AppPlaceSuggestionsDropdown` afecta búsqueda de lugares en todos los features | Riesgo low: solo cambia la rama `isLoading` (spinner → skeleton). Comportamiento exterior idéntico. |
| ARB keys de Step 4 ausentes: si Frontend los omite, habrá errores de compilación en `app_localizations` | Frontend debe añadir todos los keys en `app_es.arb` antes de usar `context.l10n.<key>` en los nuevos widgets. |

**D-14 (riesgo crítico):** El `FormBuilder` con `key: cubit.formKey` DEBE estar envuelto en un `Widget` que sea ancestro de todos los 4 steps en el `IndexedStack`. Si `FormBuilder` vive solo en `EventFormStep1`, los otros steps no pueden validar ni leer campos. **Solución:** `FormBuilder` (con `initialValue` y `key`) permanece en un widget wrapper alrededor del `IndexedStack`, igual que hoy en `EventFormContent`. La diferencia es que dicho wrapper reemplaza a `EventFormContent` como cuerpo del Scaffold en modo creación.

---

## Orden de implementación

1. **ARB keys** — añadir todos los keys de Step 4 + cover picker a `app_es.arb`. Desbloquea la compilación de todos los demás widgets.
2. **Átomos/shared modificados** — `AppCircleIconButton` (D-3), `waypoint_item_card.dart` (B-3), `route_map_area.dart` (B-4).
3. **`SearchSkeletonList` y `PulsingMapDot`** — widgets utilitarios sin dependencias internas.
4. **`AppPlaceSuggestionsDropdown`** — integrar `SearchSkeletonList` + borde naranja activo.
5. **Widgets de steps** — en orden: `EventStepIndicator` → `EventStepNavBar` → `CoverPickerSheet` → `EventFormStep1` → `EventFormStep2` → `EventFormStep3` → `EventFormStep4Review`.
6. **`EventFormView` refactor** — acoplar todos los steps; añadir branch `isEditing`; `// TODO(stepper-edit)`.
7. **Eliminar código muerto** — `event_form_content.dart`, `event_form_bottom_bar.dart`, `draft_link.dart`, `publish_button.dart` (en este orden; verificar imports cero antes de cada eliminación).
8. **`dart analyze`** — verificar cero errores nuevos.

---

## Superficie de regresión

- **`EventFormView`** — todos sus consumidores: `event_form_page.dart`. Verificar que la página sigue montando `FormImageCubit` a nivel página.
- **`AppCircleIconButton`** — usado en múltiples features (vehicles, maintenance, events, etc.). Revisar visualmente que +4 px no rompe layouts con espacio justo.
- **`AppPlaceSuggestionsDropdown`** — usado en búsqueda de ruta (simple y custom) y potencialmente en otros features. Regresión visual: el "ítem activo" ahora tiene borde naranja izquierdo — verificar que no choca con el borde del `Container` padre.
- **Modo edición** — `isEditing = true` debe seguir mostrando el scroll plano. Test manual obligatorio.
- **Payload save/draft** — verificar que `buildEventToSave()` y `buildDraftToSave()` producen los mismos campos que antes del refactor.

---

## Fuera de alcance

- Cambios en `rideglory-api`.
- Wizard para modo edición — `// TODO(stepper-edit)`.
- Perfilado de memoria (`IndexedStack` + Mapbox + Quill simultáneos).
- Tests formales (Fase 3).
- `cover_placeholder_view.dart`.
- Botón "Generar con IA" en `CoverPickerSheet`.
