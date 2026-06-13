# PRD Normalizado — Event Form Stepper · Fase 2 (Wizard completo)

**Slug:** `event-form-stepper-p2`
**Generado:** 2026-06-11T22:49:49Z
**Fuente:** `docs/plans/event-form-stepper/phases/phase-02-wizard-completo.md`
**Nivel rg-exec:** normal
**Depende de:** Fase 1 (Fundación técnica) — `EventFormState.currentStep`, métodos de navegación en `EventFormCubit`, ARB keys del stepper.

---

## 1 Objetivo

Implementar el wizard de 4 pasos (Básico → Detalles → Ruta → Revisión) para el formulario de creación de eventos en Flutter. El organizador navega pasos secuenciales con indicador de progreso visible, puede publicar o guardar borrador desde el Step 4, y el modo edición (`isEditing = true`) no regresiona: conserva el flujo de scroll anterior mientras el wizard se aplica únicamente a creación nueva. Las decisiones de la auditoría UX (bloqueantes B-1 a B-6 y sugerencias S-2/S-3/S-4/S-5) quedan implementadas.

---

## 2 Por qué

El formulario de creación de eventos actual es un scroll único plano que carga todos los campos —incluido un `MapboxMap` y un editor Quill— simultáneamente, lo que resulta en una UX pesada y toca targets inadecuados (< 44 px). La división en pasos reduce la carga cognitiva, introduce validación progresiva por paso, cumple los criterios WCAG de touch target (44×44 px mínimo) y cierra 6 bloqueantes de accesibilidad/usabilidad identificados en la auditoría UX.

---

## 3 Alcance

### Entra
- Agregar `shimmer: ^3.0.0` a `pubspec.yaml`.
- Crear 9 widgets nuevos bajo `lib/features/events/presentation/form/widgets/steps/`:
  - `event_step_indicator.dart`
  - `event_step_nav_bar.dart`
  - `cover_picker_sheet.dart`
  - `event_form_step1.dart`
  - `event_form_step2.dart`
  - `event_form_step3.dart`
  - `event_form_step4_review.dart`
  - `search_skeleton_list.dart`
  - `pulsing_map_dot.dart`
- Refactorizar `EventFormView`: `IndexedStack` + `AnimatedSwitcher(key: ValueKey(currentStep))`, AppBar con botón "Cancelar" en modo creación, botón back 40 px.
- Actualizar `EventFormBasicInfoSection`: eliminar `AppCityAutocomplete`; usar `meetingPointName` como proxy de ciudad.
- Actualizar `EventFormLocationsSection` y/o widgets hijo: touch targets 44×44 px (B-3, B-4), resultado activo con borde naranja 4 px (S-2), `SearchSkeletonList` durante carga (S-5), `PulsingMapDot` en mapa vacío (S-3).
- Eliminar 4 archivos de código muerto: `event_form_content.dart`, `event_form_bottom_bar.dart`, `draft_link.dart`, `publish_button.dart` (verificando imports antes de borrar).
- `dart analyze` limpio al cierre de fase.

### No entra
- Botón "Generar con IA" — la funcionalidad fue eliminada; `CoverPickerSheet` solo tiene "Subir desde galería".
- Cambios en `rideglory-api` (Fase 1).
- Tests formales (Fase 3).
- Wizard para modo edición (diferido — `// TODO(stepper-edit)`).
- Perfilado de memoria de `IndexedStack` (Mapbox + Quill simultáneos).
- Modificaciones a `cover_placeholder_view.dart`.

---

## 4 Áreas afectadas

| Área | Archivos principales |
|------|---------------------|
| **Presentación — Events Form** | `lib/features/events/presentation/form/widgets/event_form_view.dart` |
| **Secciones existentes** | `event_form_basic_info_section.dart`, `event_form_locations_section.dart` (y widgets hijo) |
| **Widgets nuevos (steps)** | `lib/features/events/presentation/form/widgets/steps/` (9 archivos nuevos) |
| **Código muerto eliminado** | `event_form_content.dart`, `event_form_bottom_bar.dart`, `draft_link.dart`, `publish_button.dart` |
| **Dependencias** | `pubspec.yaml` (shimmer) |
| **Localización** | `lib/l10n/app_es.arb` — uso de ARB keys del stepper creadas en Fase 1 |

---

## 5 Criterios de aceptación

1. **Flujo completo de creación:** Navegar Step 1 → Step 2 → Step 3 → Step 4 → pulsar "Publicar" produce el mismo payload que el formulario de scroll anterior. No hay pérdida de datos al retroceder con "Atrás".

2. **Validación Step 1:** Con el campo nombre vacío, pulsar "Continuar" no avanza al Step 2 y el validator del campo `name` muestra el error. Con nombre lleno, avanza correctamente.

3. **Step 4 — Publicar:** El botón "Publicar" usa `l10n.event_form_publish_action` (sin hardcoding). El botón accent tiene texto en `AppColors.darkBgPrimary`, nunca blanco.

4. **Step 4 — Guardar borrador:** El `AppTextButton` "Guardar borrador" en Step 4 llama `cubit.saveDraft()` correctamente; solo aparece en Step 4.

5. **Step indicator — completado con check:** Los pasos completados (índice < currentStep) muestran fondo naranja sólido (`colorScheme.primary`) con ícono check (`Icons.check`) en `AppColors.darkBgPrimary`. No solo fondo diferente — el ícono es el diferenciador (WCAG 1.4.1).

6. **Step indicator — activo:** Círculo activo con fondo naranja + número con `AppColors.darkBgPrimary`. Nunca texto blanco sobre naranja.

7. **Step indicator — futuro:** Fondo `colorScheme.surfaceContainerHighest`, número con `colorScheme.onSurfaceVariant`.

8. **`AnimatedSwitcher` con key:** El `IndexedStack` está envuelto en `AnimatedSwitcher` con `key: ValueKey(state.currentStep)`.

9. **Modo edición sin regresión:** Con `isEditing = true`, el formulario muestra el scroll único anterior sin el wizard. Comentario `// TODO(stepper-edit)` visible en el código.

10. **AppBar "Cancelar":** En modo creación, el AppBar tiene un `AppTextButton` "Cancelar" en el lado derecho que cierra el wizard (`context.pop()`). Visible en todos los pasos (1–4).

11. **Back button 40 px:** El botón back circular del AppBar mide 40×40 px (era 36×36 px — B-5).

12. **CoverPickerSheet sin IA:** `cover_picker_sheet.dart` no contiene ningún botón ni texto relacionado con "Generar con IA". Solo tiene "Subir desde galería".

13. **Step 4 — botones "Editar":** Cada card de resumen (Básico, Configuración, Ruta) tiene un botón "Editar" que al pulsarse llama `cubit.goToStep(n)` con el índice correcto (0, 1, 2 respectivamente).

14. **Step 4 — dificultad con llamas:** La dificultad en Step 4 se muestra con flame icons en `AppColors.primary` (no como texto plano). Cantidad de llamas según el nivel.

15. **Touch targets X (B-3):** Cada botón de eliminar waypoint tiene un área táctil de mínimo 44×44 px. `grep -r "GestureDetector\|SizedBox.*44\|width: 44" lib/features/events/presentation/form/widgets/sections/` muestra la implementación.

16. **recenterBtn 44 px (B-4):** El botón de recentrar el mapa mide 44×44 px.

17. **Autocomplete activo (S-2):** El resultado activo de la búsqueda de lugares tiene borde izquierdo naranja de 4 px y fondo `Color(0xFF1C1C24)`, diferenciable del resto.

18. **SearchSkeletonList (S-5):** Cuando el autocomplete está cargando resultados, se muestran 3 filas skeleton con shimmer (`Shimmer.fromColors`) en lugar de la lista vacía.

19. **PulsingMapDot (S-3):** Cuando el mapa está vacío (0 waypoints), se muestra el `PulsingMapDot` (ring pulsante 44 px + dot 14 px naranja). Cuando hay ≥1 waypoint, el dot desaparece.

20. **`shimmer` en pubspec.yaml:** `flutter pub get` pasa limpio con `shimmer: ^3.0.0` en `dependencies`.

21. **`city` no forzado:** En `cover_picker_sheet.dart`, NO se pasa `city`. La llamada es únicamente a `pickImageFromGallery()`.

22. **Un widget por archivo:** Ningún archivo en `widgets/steps/` contiene más de una clase que extienda `StatelessWidget` o `StatefulWidget`.

23. **Cero métodos `Widget _buildXxx()`:** `grep -r "Widget _build" lib/features/events/presentation/form/widgets/steps/` retorna vacío.

24. **Código muerto eliminado:** `grep -r "draft_link\|publish_button\|event_form_bottom_bar\|event_form_content" lib/ --include="*.dart"` retorna vacío.

25. **Sin referencias a `EventFormFields.city` en presentación:** `grep -r "EventFormFields.city" lib/features/events/presentation/` retorna vacío.

26. **`dart analyze` sin errores nuevos:** Conteo de errores/warnings al final ≤ conteo base del Paso 0.

27. **Step 4 sin Quill ni Mapbox:** `grep -r "flutter_quill\|MapboxMap" lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` retorna vacío.

---

## 6 Guardrails de regresión

- **Modo edición intacto:** `isEditing = true` no activa el wizard; el scroll único actual permanece funcionando sin cambios visibles.
- **Payload publicar/borrador idéntico:** El wizard no debe alterar las claves ni los valores del mapa enviado al backend. Verificar con el mismo evento de prueba.
- **`cover_placeholder_view.dart` no modificado:** Es el fallback de `CoverPreviewWidget`; cualquier cambio en él queda fuera del alcance.
- **Secciones existentes no rotas:** `EventFormDifficultySection`, `EventFormEventTypeSection`, `EventFormMaxParticipantsSection`, `EventFormPriceSection`, `EventFormMultiBrandSection`, `EventFormDateTimeSection` no deben ser modificadas.
- **`dart analyze` no empeora:** Ningún cambio de esta fase introduce nuevos errores o warnings en archivos fuera del alcance de la fase.
- **`FormImageCubit` sigue proveído a nivel página:** El `IndexedStack` mantiene children vivos; el cubit de imagen no se re-monta ni pierde estado al cambiar de paso.

---

## 7 Constraints heredados

- **Un widget por archivo** — regla de arquitectura Rideglory: máximo 1 clase `StatelessWidget`/`StatefulWidget` por archivo `.dart` (la clase `State<T>` puede coexistir con su `StatefulWidget`).
- **Prohibidos métodos `Widget _buildXxx()`** — cada pieza de UI es su propia clase widget en su propio archivo.
- **AppShared widgets obligatorios** — usar `AppButton`, `AppTextButton`, `AppTextField` etc. de `lib/shared/widgets/`; nunca `ElevatedButton`, `TextButton`, `Material Switch` directamente.
- **Texto/iconos sobre acento naranja siempre oscuro** — `AppColors.darkBgPrimary` (`#0D0D0F`) o `colorScheme.onPrimary`; nunca `Colors.white` ni `AppColors.textOnDarkPrimary` sobre `AppColors.primary`.
- **Localización obligatoria** — todo texto visible en `app_es.arb` + `context.l10n.<key>`; sin string literals en UI.
- **DTO Pattern B** — no aplica directamente a esta fase (sin cambios en capa data/domain).
- **No commitear** — el árbol de trabajo queda sucio para revisión humana.
- **No tocar** — `workflow/state.json`, `docs/PRD.md`, `docs/PLAN.md`, sistema `/iter`, `.claude/agents/`, `.claude/workflows/`, ni la fuente original del plan.
- **Shimmer dark theme** — colores de skeleton: `Color(0xFF383838)` base y `Color(0xFF505050)` highlight (aprobados para fondos `#161616`). No usar valores más claros.
- **`AnimationController` lifecycle** — `dispose()` obligatorio en cualquier `StatefulWidget` que use `AnimationController`; sin este cleanup se introduce memory leak.
