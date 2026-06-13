# Frontend handoff — event-form-stepper-p2

**Fecha:** 2026-06-12T03:47:55Z
**Agente:** Frontend (Flutter lib/) — MODO FIX
**Status:** done (fixes AC8 / AC19 / AC24 aplicados)

---

## Baseline

- `flutter test` (baseline): **30/30 passed** (rest_client_functions_test.dart)
- `dart analyze lib/`: **0 errors, 0 warnings** al inicio

---

## Archivos cambiados

### Creados

| Archivo | Descripción |
|---------|-------------|
| `lib/features/events/presentation/form/widgets/steps/search_skeleton_list.dart` | 3 filas shimmer con `Shimmer.fromColors(base: 0xFF383838, highlight: 0xFF505050)` |
| `lib/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart` | Ring pulsante 44px + dot 14px naranja. `AnimationController` con `dispose()` explícito. |
| `lib/features/events/presentation/form/widgets/steps/event_step_indicator.dart` | 4 círculos: completado=naranja+check+darkBgPrimary, activo=naranja+número, futuro=surfaceContainerHighest |
| `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` | Steps 1-3: Atrás/Continuar con `validateStep` gate; Step 4: Publicar + Guardar borrador |
| `lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` | Bottom sheet solo con "Subir desde galería". Sin IA. |
| `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` | Cover (Image.file/network + CoverPickerSheet) + EventFormBasicInfoSection + EventFormDateTimeSection |
| `lib/features/events/presentation/form/widgets/steps/event_form_step2.dart` | Difficulty + EventType + MultiBrand + MaxParticipants + Price |
| `lib/features/events/presentation/form/widgets/steps/event_form_step3.dart` | EventFormLocationsSection (Mapbox). Nota: IndexedStack mantiene MapboxMap vivo. |
| `lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` | 3 cards resumen (Básico/Configuración/Ruta) con botones Editar → `cubit.goToStep(n)`. Llamas de dificultad en AppColors.primary. Publish + Save Draft via EventStepNavBar. |

### Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | Refactor completo: modo creación → `_CreationScaffold` con `FormBuilder` + `IndexedStack(4 steps)` + `EventStepIndicator` en bottom slot. Modo edición → `_EditingScaffold` (layout original preservado + `// TODO(stepper-edit)`). `EventFormBottomBar` eliminado de la firma. |
| `lib/design_system/atoms/buttons/app_circle_icon_button.dart` | `_size`: 36 → 40 (B-5 touch target 40px) |
| `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` | Botón eliminar: `SizedBox(44,44)` + `Center` (B-3 touch target 44px) |
| `lib/features/events/presentation/form/screens/route_map_area.dart` | Recenter button: 36×36 → 44×44 (B-4 touch target) |
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` | `isLoading` branch: spinner → `SearchSkeletonList`. Ítem activo (i==0): borde izquierdo naranja 4px + fondo `Color(0xFF1C1C24)` (S-2) |
| `lib/l10n/app_es.arb` | 28 nuevas keys: `event_step_review_*`, `event_cover_picker_*` |

### Eliminados

| Archivo | Razón |
|---------|-------|
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | Reemplazado por `EventStepNavBar` en Step 4; cero referencias |
| `lib/features/events/presentation/form/widgets/draft_link.dart` | Funcionalidad migrada a `EventStepNavBar` Step 4; cero referencias |
| `lib/features/events/presentation/form/widgets/publish_button.dart` | Funcionalidad migrada a `EventStepNavBar` Step 4; cero referencias |

### Eliminados (fix AC24)

| Archivo | Razón |
|---------|-------|
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Eliminado (AC24). Contenido inlineado en `_EditingFormBody` dentro de `event_form_view.dart`. |

---

## Pruebas nuevas

No se añadieron tests de widget (marcado como fuera de alcance en el PRD §"No entra" — Fase 3).

Tests existentes se mantienen en verde: **30/30 passed**.

---

## Fixes aplicados (MODO FIX — 2026-06-12)

### AC8 — AnimatedSwitcher (BUG-p2-1) — RESUELTO

`event_form_view.dart`: el `IndexedStack` en `_CreationScaffold` ahora está envuelto en
`AnimatedSwitcher(duration: 200 ms, child: IndexedStack(key: ValueKey(state.currentStep), ...))`.

El test `event_form_stepper_p2_qa_test.dart` que documentaba el bug fue actualizado para
verificar el patrón correcto (ya no es un test que falla intencionalmente).

### AC19 — PulsingMapDot integrado (BUG-p2-2) — RESUELTO

`route_map_area.dart`:
- Import de `PulsingMapDot` añadido.
- Nuevo parámetro `hasWaypoints` (default `false`).
- Overlay `IgnorePointer(child: Center(child: PulsingMapDot()))` añadido al `Stack`,
  visible cuando `!hasWaypoints && !isPickMode`.

`event_route_config_screen.dart`: pasa `hasWaypoints: hasWaypoints` al constructor de
`RouteMapArea` (la variable `hasWaypoints` ya existía en el `BlocBuilder`).

### AC24 — event_form_content.dart eliminado — RESUELTO (Opción A)

`event_form_content.dart` fue **eliminado**. Su contenido (scrollable form body para modo
edición) fue inlineado en la clase privada `_EditingFormBody` dentro de `event_form_view.dart`.

`grep -r 'event_form_content' lib/` → solo retorna el comentario de documentación en
`event_form_view.dart`; cero importaciones activas.

---

## Resultado final

```
dart analyze lib/  → 0 errors, 0 warnings, 0 infos
flutter test       → 820/820 passed (exit 0)
```

---

## Verificación manual

Para verificar el stepper en modo creación:

1. Abrir formulario de creación de evento (botón "+" en la lista de eventos).
2. Confirmar que el `AppFormNavHeader` muestra 4 círculos de progreso en el `bottom` slot.
3. Paso 1: Cover vacía → tap → bottom sheet con un solo botón "Subir desde galería". Llenar nombre y fechas.
4. Tap "Continuar" sin nombre → validación falla (no avanza). Con nombre → avanza a Paso 2.
5. Paso 2: Llenar dificultad, tipo, etc. Botón "Atrás" vuelve a Paso 1.
6. Paso 3: Mapa de ruta. `PulsingMapDot` visible cuando hay 0 waypoints.
7. Paso 4: 3 cards de resumen. Botones "Editar" redirigen al paso correspondiente. "Publicar evento" lanza el save. "Guardar borrador" guarda en draft.
8. **Modo edición**: abrir evento existente → layout plano original (scroll único, sin stepper). `// TODO(stepper-edit)` en `_EditingScaffold`.
9. **Autocomplete**: en campo de ruta, tipear → skeleton de 3 filas (no spinner). Primer resultado con borde naranja izquierdo.

---

## Notas para QA

- **FormBuilder posicionado como ancestor** del `IndexedStack` — todos los pasos comparten el mismo `formKey`. Los campos se validan entre pasos sin perder valores.
- **`IndexedStack` mantiene MapboxMap (Step 3) y QuillEditor (Step 1) vivos simultáneamente** — posible presión de memoria en dispositivos de gama baja. Monitorear durante pruebas de carga.
- **`event_form_content.dart` fue eliminado** (fix AC24). El contenido vive ahora en `_EditingFormBody` dentro de `event_form_view.dart`. `grep -r 'event_form_content' lib/` devuelve cero importaciones activas.
- **`AppCircleIconButton._size` subió de 36→40** — afecta todos los back buttons de la app. Verificar visualmente que +4px no rompe layouts con espacio justo (vehicles, maintenance, events).
- **El botón de recenter del mapa custom subió de 36→44** — verificar que no solapa con otros controles del mapa.
- Los ARB keys `event_step_review_*` y `event_cover_picker_*` están todos definidos. Si `flutter gen-l10n` lanza error de key duplicada, revisar que no existan en otra sección del ARB.
