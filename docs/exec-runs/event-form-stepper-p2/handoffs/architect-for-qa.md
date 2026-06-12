> Slim handoff — lee esto antes de docs/exec-runs/event-form-stepper-p2/handoffs/architect.md

# Architect → QA — event-form-stepper-p2

**Fecha:** 2026-06-11T22:53:34Z

## Comandos de verificación

```bash
# Lint limpio (cero errores nuevos)
dart analyze

# Sin código muerto
grep -r "draft_link\|publish_button\|event_form_bottom_bar\|event_form_content" lib/ --include="*.dart"
# Esperado: vacío

# Un widget por archivo en steps/
grep -r "extends StatelessWidget\|extends StatefulWidget" lib/features/events/presentation/form/widgets/steps/
# Esperado: exactamente 1 clase por archivo

# Sin métodos Widget _buildXxx en steps/
grep -r "Widget _build" lib/features/events/presentation/form/widgets/steps/
# Esperado: vacío

# Sin city en presentación
grep -r "EventFormFields.city" lib/features/events/presentation/
# Esperado: vacío

# Sin Quill ni Mapbox en step4
grep -r "flutter_quill\|MapboxMap" lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart
# Esperado: vacío

# Sin botón IA en cover picker
grep -r "generateWithAI\|Generar con IA\|generate_cover\|generateCover" lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart
# Esperado: vacío

# Shimmer en pubspec
grep "shimmer" pubspec.yaml
# Esperado: shimmer: ^3.0.0

# Touch target delete waypoint
grep -r "SizedBox.*44\|width.*44\|height.*44" lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart
# Esperado: al menos un match

# Recenter button 44px
grep -r "width.*44\|height.*44" lib/features/events/presentation/form/screens/route_map_area.dart
# Esperado: al menos un match
```

## Criterios de aceptación — traceabilidad

| CA# | Qué verificar | Método |
|-----|--------------|--------|
| 1 | Flujo completo Step1→4→Publicar produce mismo payload | Manual: crear evento completo, verificar request en logs Dio |
| 2 | Validación Step 1 (nombre vacío no avanza) | Manual: dejar nombre vacío, pulsar "Continuar" |
| 3 | Botón "Publicar" usa `event_form_publish_action`; texto oscuro sobre naranja | Code review: grep `event_form_publish_action`; ningún `Colors.white` sobre `AppColors.primary` |
| 4 | "Guardar borrador" llama `cubit.saveDraft()` solo en Step 4 | Code review: `grep saveDraft` en `steps/` |
| 5-7 | Step indicator estados (completado/activo/futuro) | Manual + Code review: verificar check icon y colores |
| 8 | `AnimatedSwitcher` con `key: ValueKey(state.currentStep)` | Code review: `grep ValueKey` en `event_form_view.dart` |
| 9 | Modo edición sin wizard | Manual: editar evento existente — debe mostrar scroll plano |
| 10 | AppBar "Cancelar" visible en todos los pasos (creación) | Manual: navegar por los 4 pasos |
| 11 | Back button 40 px | Code review: `app_circle_icon_button.dart` `_size == 40` |
| 12 | `CoverPickerSheet` sin IA | Grep (ver comandos arriba) |
| 13 | Botones "Editar" en Step 4 → `cubit.goToStep(n)` | Code review: grep `goToStep` en `event_form_step4_review.dart` |
| 14 | Dificultad con llamas naranja en Step 4 | Manual: crear evento con dificultad 3, verificar Step 4 |
| 15 | Touch target waypoint delete ≥ 44 px | Grep (ver comandos arriba) |
| 16 | Recenter btn 44 px | Grep (ver comandos arriba) |
| 17 | Resultado activo con borde naranja izquierdo | Manual: buscar un lugar, verificar primer resultado |
| 18 | SearchSkeletonList durante carga autocomplete | Manual: buscar lentamente con throttling |
| 19 | PulsingMapDot con 0 waypoints; desaparece con ≥1 | Manual: abrir Step 3 con ruta simple vacía |
| 20 | `flutter pub get` pasa limpio | `flutter pub get` (shimmer ya en pubspec) |
| 21 | `city` no pasado en CoverPickerSheet | Grep: `grep city lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` → vacío |
| 22-23 | 1 widget/archivo; sin `Widget _buildXxx` | Grep (ver comandos arriba) |
| 24 | Código muerto eliminado | Grep (ver comandos arriba) |
| 25 | Sin `EventFormFields.city` en presentación | Grep (ver comandos arriba) |
| 26 | `dart analyze` ≤ baseline | `dart analyze` |
| 27 | Sin Quill/Mapbox en step4 | Grep (ver comandos arriba) |

## Superficie de regresión crítica

1. **Modo edición (`isEditing = true`)** — flujo completo de edición sin el wizard.
2. **Payload publicar/borrador** — mismos campos que antes.
3. **`AppCircleIconButton`** — back buttons en vehicles, maintenance, events. Visual check.
4. **`AppPlaceSuggestionsDropdown`** — búsqueda en ruta simple, custom y cualquier otro feature.
5. **`FormImageCubit`** — la portada no debe perder estado al cambiar de paso.

> Full detail: docs/exec-runs/event-form-stepper-p2/handoffs/architect.md
