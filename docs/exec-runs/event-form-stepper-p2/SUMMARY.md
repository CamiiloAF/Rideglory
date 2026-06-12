# SUMMARY — Event Form Stepper · Fase 2

**Generado:** 2026-06-12T03:38:27Z (actualizado en re-review 2026-06-12T03:50:30Z)
**Tech Lead:** claude-sonnet-4-6
**Veredicto:** needs_changes

---

## Objetivo

Implementar el wizard de 4 pasos (Básico → Detalles → Ruta → Revisión) para el formulario de creación de eventos en Flutter, con indicador de progreso, validación por paso, mejoras de accesibilidad (touch targets 44 px, skeleton shimmer, pulsing map dot, resultado activo con borde naranja) y eliminación de código muerto.

---

## Qué cambió por área

### Frontend — Events Form (creación)
- `event_form_view.dart`: refactorizado en `_CreationScaffold` (wizard con `IndexedStack`) + `_EditingScaffold` (scroll plano preservado) + `_EditingBottomBar` inline. `FormBuilder` envuelve el `IndexedStack` para que todos los pasos compartan `formKey`. Modo edición bifurcado con `// TODO(stepper-edit)`.
- 9 archivos nuevos bajo `lib/features/events/presentation/form/widgets/steps/`: `event_step_indicator.dart`, `event_step_nav_bar.dart`, `cover_picker_sheet.dart`, `event_form_step1.dart`, `event_form_step2.dart`, `event_form_step3.dart`, `event_form_step4_review.dart`, `search_skeleton_list.dart`, `pulsing_map_dot.dart`.
- 3 archivos de código muerto eliminados: `draft_link.dart`, `event_form_bottom_bar.dart`, `publish_button.dart`.

### Frontend — Shared Widgets
- `app_place_suggestions_dropdown.dart`: loading reemplazado por `SearchSkeletonList` (shimmer 3 filas); resultado activo con borde izquierdo naranja 4 px y fondo `Color(0xFF1C1C24)`.
- `app_circle_icon_button.dart`: tamaño subido de 36 → 40 px (B-5).

### Frontend — Secciones existentes
- `waypoint_item_card.dart`: botón eliminar waypoint envuelto en `SizedBox(44x44)` con `Center` (B-3).
- `route_map_area.dart`: botón recentrar subido de 36x36 → 44x44 px (B-4).
- `inscription_card.dart`: campo `city` eliminado del card.

### Localización
- `app_es.arb`: 28 nuevas ARB keys para Step 4 review y `CoverPickerSheet`.

### Tests
- `my_registrations_cubit_test.dart`: campo `city` removido del mock `EventModel`.

---

## Archivos

| Archivo | Operación |
|---------|-----------|
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | Modificado |
| `lib/features/events/presentation/form/widgets/steps/event_step_indicator.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/event_form_step2.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/event_form_step3.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/search_skeleton_list.dart` | Creado |
| `lib/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart` | Creado |
| `lib/features/events/presentation/form/widgets/draft_link.dart` | Eliminado |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | Eliminado |
| `lib/features/events/presentation/form/widgets/publish_button.dart` | Eliminado |
| `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` | Modificado |
| `lib/features/events/presentation/form/screens/route_map_area.dart` | Modificado |
| `lib/design_system/atoms/buttons/app_circle_icon_button.dart` | Modificado |
| `lib/features/event_registration/presentation/widgets/inscription_card.dart` | Modificado |
| `lib/shared/widgets/form/app_place_suggestions_dropdown.dart` | Modificado |
| `lib/l10n/app_es.arb` | Modificado |
| `test/.../my_registrations_cubit_test.dart` | Modificado |

---

## Pruebas

- `dart analyze` en archivos modificados: **No issues found**.
- Test mock actualizado para eliminar `city`. Sin tests nuevos de widget (diferido Fase 3).

---

## Riesgos / Watchlist

| # | Riesgo | Severidad |
|---|--------|-----------|
| B1 | 6 archivos con múltiples clases widget — violación "1 widget por archivo" | **Blocker** |
| B2 | `Color(0xFF1C1C24)` raw en `build()` en `app_place_suggestions_dropdown.dart` | **Blocker** |
| B3 | `FormBuilder.of(context)?.save()` llamado durante `build()` en Step 4 | **Blocker** |
| W1 | `_OverlayButton` (botones cover) mide 36×36 px — por debajo de WCAG 44 px | Watchlist |
| W2 | `IndexedStack` Mapbox+Quill vivos simultáneamente — sin perfilado de memoria | Watchlist (diferido Fase 3) |
| W3 | Edits de `docs/plans/observability-sentry/` son cambios fuera de alcance en el working tree | Watchlist |

---

## Mensaje de commit sugerido

```
feat(events): wizard 4 pasos para creación de eventos (Fase 2)

- IndexedStack + AnimatedSwitcher(ValueKey) + FormBuilder compartido
- 9 widgets nuevos: steps 1–4, step indicator, nav bar, cover picker,
  search skeleton, pulsing map dot
- Touch targets 44px: waypoint delete (B-3), recenter (B-4)
- AppCircleIconButton 40px (B-5)
- SearchSkeletonList shimmer; resultado activo con borde naranja 4px (S-2, S-5)
- PulsingMapDot sobre mapa vacío (S-3)
- Modo edición preservado con _EditingScaffold + TODO(stepper-edit)
- Elimina event_form_content, event_form_bottom_bar, draft_link, publish_button
- 28 nuevas ARB keys para review step y cover picker

Pendiente (blockers): 1-widget-per-file en 6 archivos, raw Color(0xFF1C1C24),
FormBuilder.save() en build()
```
