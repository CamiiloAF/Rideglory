# Tech Lead Review — Event Form Stepper · Fase 2

**Generado:** 2026-06-12T03:50:30Z
**Revisión:** Tech Lead (Re-review tras correcciones de frontend)
**Status:** blocked

---

## Veredicto

**needs_changes** — 3 blockers arquitectónicos: (1) violación de la regla "1 widget por archivo" en 6 archivos, (2) `Color(0xFF1C1C24)` raw literal en `build()`, (3) `FormBuilder.of(context)?.save()` llamado desde `build()`.

Los blockers previos de la iteración anterior (AC8 AnimatedSwitcher, AC19 PulsingMapDot, AC24 event_form_content.dart) han sido **resueltos correctamente** en esta iteración.

---

## Hallazgos

### Blocker 1 — Violación "1 widget por archivo" en 6 archivos [frontend]

La regla de arquitectura `rideglory-coding-standards.mdc §2` es explícita: "Máximo 1 clase widget por archivo — sin excepciones." Los siguientes archivos la violan:

| Archivo | Clases widget |
|---------|--------------|
| `event_form_view.dart` | `EventFormView`, `_CreationScaffold`, `_EditingScaffold`, `_EditingFormBody`, `_EditingBottomBar` (5) |
| `event_form_step1.dart` | `EventFormStep1`, `_CoverEmpty`, `_CoverPreview`, `_OverlayButton` (4) |
| `event_step_indicator.dart` | `EventStepIndicator`, `_StepCircle` (2) |
| `event_step_nav_bar.dart` | `EventStepNavBar`, `_NavigationRow`, `_PublishRow` (3) |
| `search_skeleton_list.dart` | `SearchSkeletonList`, `_SkeletonRow` (2) |
| `event_form_step4_review.dart` | `EventFormStep4Review`, `_ReviewCard`, `_ReviewRow`, `_DifficultyFlames` (4) |

Fix: cada clase privada debe extraerse a su propio archivo. Los archivos privados pueden vivir en el mismo directorio con un prefijo de guion bajo en el nombre si se desea (`_review_card.dart`, etc.) o sin prefijo.

### Blocker 2 — `Color(0xFF1C1C24)` raw literal en `build()` [frontend]

`lib/shared/widgets/form/app_place_suggestions_dropdown.dart:75` usa `Color(0xFF1C1C24)` directamente en el método `build()`. La regla `rideglory-coding-standards.mdc §3` prohíbe `Color(0xFF...)` en build methods.

`AppColors.darkCard` es `0xFF1E1E24` — una sombra diferente, por lo que no es un alias accidental. Fix: añadir `static const Color darkActiveSuggestion = Color(0xFF1C1C24)` a `app_colors.dart` y reemplazar el literal en el dropdown.

### Blocker 3 — `FormBuilder.of(context)?.save()` en `build()` [frontend]

`event_form_step4_review.dart:26`:
```dart
// ❌ Llamada con side-effect durante build
FormBuilder.of(context)?.save();
final formData = FormBuilder.of(context)?.value ?? {};
```

`save()` invoca `onSaved` en cada campo y puede disparar `setState` sobre los form fields durante la fase de build, lo que Flutter prohíbe ("setState() or markNeedsBuild() called during build"). Además, es innecesario: `FormBuilder.of(context)?.value` ya refleja los valores actuales de los campos sin necesitar `save()` cuando no se usan callbacks `onSaved`.

Fix: eliminar la línea `FormBuilder.of(context)?.save()`. Leer `FormBuilder.of(context)?.value ?? {}` directamente.

---

## Resueltos en esta iteración

| Blocker anterior | Estado |
|-----------------|--------|
| AC8: `AnimatedSwitcher` ausente | **Resuelto** — `IndexedStack(key: ValueKey(state.currentStep))` dentro de `AnimatedSwitcher(duration: 200ms)`. |
| AC19: `PulsingMapDot` no integrado | **Resuelto** — `IgnorePointer(child: Center(child: PulsingMapDot()))` en `RouteMapArea` cuando `!hasWaypoints && !isPickMode`. |
| AC24: `event_form_content.dart` no eliminado | **Resuelto** — Archivo eliminado; contenido inlineado en `_EditingFormBody` dentro de `event_form_view.dart`. |

---

## Seguridad

Sin observaciones. No hay secretos, SQL concatenado, PII en logs ni URLs hardcodeadas. Auth e interceptores no modificados. No hay cambios en rideglory-api.

---

## Arquitectura

### Correcto

- `FormBuilder(key: cubit.formKey)` envuelve el `IndexedStack` — todos los pasos comparten el form state sin re-montar el cubit.
- `IndexedStack` mantiene `MapboxMap` + `QuillEditor` vivos entre pasos — guardrail `FormImageCubit` respetado.
- `AnimationController.dispose()` presente en `_PulsingMapDotState.dispose()`.
- `context.mounted` verificado post-`await` en `_onPublish`, `_onSave`, `_onSaveDraft`.
- `AppButton`/`AppTextButton` usados en todo el código nuevo; nunca `ElevatedButton`/`TextButton`.
- Texto/iconos sobre acento naranja usan `AppColors.darkBgPrimary` — rule sobre texto oscuro respetada.
- Shimmer usa `Color(0xFF383838)`/`Color(0xFF505050)` — valores aprobados explícitamente en PRD §7.
- Modo edición (`isEditing = true`) conserva scroll plano con `// TODO(stepper-edit)` visible.
- Todos los strings visibles van via `context.l10n.<key>` — sin hardcoding.

### Violaciones

Ver Blocker 1, 2, 3.

---

## Flutter Clean Architecture

| Layer | Compliant | Violations |
|-------|-----------|------------|
| domain | Yes | None |
| data | Yes | None |
| presentation | Mostly | 1-widget-per-file (Blocker 1); raw Color literal (Blocker 2); save() en build (Blocker 3) |

---

## rideglory-coding-standards

| Regla | Compliant | Detalle |
|-------|-----------|---------|
| 1 widget por archivo | **No** | 6 archivos con múltiples clases widget |
| No métodos `Widget _buildXxx()` | Yes | `grep` retorna vacío |
| Strings via l10n | Yes | Todos los strings en ARB + `context.l10n` |
| No widgets Material raw | Yes | `AppButton`/`AppTextButton` usados |
| No `Color(0xFF...)` en build | **No** | `app_place_suggestions_dropdown.dart:75` |
| `ResultState` para async | Yes | `state.saveResult is Loading<EventModel>` |
| Texto oscuro sobre primario | Yes | `AppColors.darkBgPrimary` en indicator y publish button |

---

## Acceptance Criteria

| AC | Estado |
|----|--------|
| AC1 — Flujo completo creación | Pass |
| AC2 — Validación Step 1 | Pass |
| AC3 — Publicar con l10n y texto oscuro | Pass |
| AC4 — Guardar borrador solo en Step 4 | Pass |
| AC5 — Check icon en completados | Pass |
| AC6 — Activo naranja + número oscuro | Pass |
| AC7 — Futuro gris | Pass |
| AC8 — AnimatedSwitcher + ValueKey | Pass |
| AC9 — Modo edición sin wizard | Pass |
| AC10 — Cancelar en AppBar | Pass |
| AC11 — Back button 40 px | Pass |
| AC12 — CoverPickerSheet sin IA | Pass |
| AC13 — Editar en Step 4 cards | Pass |
| AC14 — Llamas de dificultad | Pass |
| AC15 — Touch target delete 44 px | Pass |
| AC16 — recenterBtn 44 px | Pass |
| AC17 — Autocomplete activo S-2 | Pass (raw Color → Blocker 2) |
| AC18 — SearchSkeletonList S-5 | Pass |
| AC19 — PulsingMapDot S-3 | Pass |
| AC20 — shimmer en pubspec.yaml | Pass |
| AC21 — city no forzado en cover picker | Pass |
| AC22 — 1 widget por archivo | **Fail** → Blocker 1 |
| AC23 — Cero Widget _buildXxx() | Pass |
| AC24 — Código muerto eliminado | Pass |
| AC25 — Sin EventFormFields.city en presentación | Pass |
| AC26 — dart analyze sin errores | Pass (`No issues found!`) |
| AC27 — Step 4 sin Quill ni Mapbox | Pass |

---

## Tests

- `dart analyze lib/`: **Pass** — `No issues found!`
- `my_registrations_cubit_test.dart`: actualizado correctamente (campo `city` removido del mock en línea con la eliminación de `EventModel.city`).
- Tests de widget nuevos: diferidos a Fase 3 per PRD §3. Sin hallazgos en esta área.

---

## Pruebas manuales recomendadas (post-fix)

1. Flujo creación completo Step 1→4→Publicar: verificar que el payload no pierde datos.
2. Retroceder Step 4→Step 1: datos conservados en todos los campos.
3. Step 1 nombre vacío + "Continuar": error de validación visible, sin avanzar.
4. Step 4 botones "Editar": Básico→Step 0, Configuración→Step 1, Ruta→Step 2.
5. Modo edición: scroll plano, sin wizard.
6. Autocomplete: shimmer 3 filas durante carga; borde naranja izquierdo en primer resultado.
7. Mapa sin waypoints: `PulsingMapDot` visible; al agregar un waypoint, desaparece.
8. Waypoint delete: área táctil 44 px confirmada en dispositivo físico.

---

## Change log

- 2026-06-12T03:38:27Z: Primera revisión — bloqueada (AC8, AC19, AC24).
- 2026-06-12T03:50:30Z: Re-revisión — AC8/AC19/AC24 resueltos; nuevos blockers AC22 (1-widget-per-file), raw Color, save-en-build identificados.
