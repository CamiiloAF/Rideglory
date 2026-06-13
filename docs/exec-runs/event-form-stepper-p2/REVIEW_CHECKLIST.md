# REVIEW CHECKLIST — Event Form Stepper · Fase 2

**Generado:** 2026-06-12T03:50:30Z (actualizado en re-review)

---

## Blockers — resolver antes de commitear

- [ ] **B1 — 1 widget por archivo:** Extraer cada clase privada widget a su propio archivo:
  - `event_form_view.dart`: extraer `_CreationScaffold`, `_EditingScaffold`, `_EditingFormBody`, `_EditingBottomBar`
  - `event_form_step1.dart`: extraer `_CoverEmpty`, `_CoverPreview`, `_OverlayButton`
  - `event_step_indicator.dart`: extraer `_StepCircle`
  - `event_step_nav_bar.dart`: extraer `_NavigationRow`, `_PublishRow`
  - `search_skeleton_list.dart`: extraer `_SkeletonRow`
  - `event_form_step4_review.dart`: extraer `_ReviewCard`, `_ReviewRow`, `_DifficultyFlames`

- [ ] **B2 — Raw Color literal:** En `app_place_suggestions_dropdown.dart:75`, reemplazar `Color(0xFF1C1C24)` por una constante nombrada:
  ```dart
  // En app_colors.dart:
  static const Color darkActiveSuggestion = Color(0xFF1C1C24);
  // En app_place_suggestions_dropdown.dart:
  color: AppColors.darkActiveSuggestion,
  ```

- [ ] **B3 — save() en build():** En `event_form_step4_review.dart:26`, eliminar la línea `FormBuilder.of(context)?.save()`. El `value` map es accesible directamente sin invocar `save()`:
  ```dart
  // Eliminar esta línea:
  // FormBuilder.of(context)?.save();
  final formData = FormBuilder.of(context)?.value ?? {};
  ```

---

## Verificaciones funcionales

- [ ] Flujo creación Step 1→4→Publicar: payload completo sin pérdida de datos.
- [ ] Retroceder Step 4→Step 1: datos conservados en todos los campos.
- [ ] Step 1 nombre vacío + "Continuar": error de validación visible, no avanza.
- [ ] Step 4 botones "Editar": Básico→Step 0, Configuración→Step 1, Ruta→Step 2.
- [ ] Step 4 "Guardar borrador": llama `saveDraft()` correctamente.
- [ ] Modo edición (`isEditing=true`): scroll plano sin wizard; sin regresión.
- [ ] "Cancelar" visible en todos los pasos; cierra con `context.pop()`.

---

## Verificaciones de accesibilidad / UX

- [ ] Step indicator: completados = naranja + check oscuro; activo = naranja + número oscuro; futuros = gris.
- [ ] Texto "Publicar evento" (sobre acento naranja) es oscuro (`darkBgPrimary`), nunca blanco.
- [ ] Waypoint delete: área táctil 44×44 px en dispositivo físico.
- [ ] Botón recentrar mapa: 44×44 px.
- [ ] `AppCircleIconButton`: 40 px.
- [ ] Autocomplete loading: shimmer skeleton 3 filas visible.
- [ ] Resultado activo: borde izquierdo naranja 4 px + fondo `AppColors.darkActiveSuggestion`.
- [ ] `PulsingMapDot`: visible sin waypoints; desaparece con ≥1 waypoint.

---

## Verificaciones de lint y código

- [ ] `dart analyze lib/ --no-summary` sin nuevos warnings (post-fix).
- [ ] `grep -rn "class _.*Widget\|extends StatelessWidget\|extends StatefulWidget" lib/features/events/presentation/form/widgets/` — cada archivo tiene como máximo 1 clase widget.
- [ ] `grep -r "Color(0xFF" lib/features/events lib/shared/widgets/form/app_place_suggestions_dropdown.dart --include="*.dart"` — solo `0xFF383838`/`0xFF505050` permitidos (shimmer, aprobados por PRD).
- [ ] `grep -r "\.save()" lib/features/events/presentation/form/widgets/steps/ --include="*.dart"` — retorna vacío.
- [ ] `grep -r "draft_link\|publish_button\|event_form_bottom_bar\|event_form_content" lib/ --include="*.dart"` — retorna vacío.
- [ ] `grep -r "EventFormFields.city" lib/features/events/presentation/ --include="*.dart"` — retorna vacío.
- [ ] `grep -r "Widget _build" lib/features/events/presentation/form/widgets/steps/ --include="*.dart"` — retorna vacío.
