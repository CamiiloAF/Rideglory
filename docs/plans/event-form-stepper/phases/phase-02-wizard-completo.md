# Fase 2 — Wizard completo

**Slug:** `event-form-stepper`
**Fase:** 2 de 3
**Fecha:** 2026-06-09T02:14:02Z (actualizado 2026-06-11)
**Nivel rg-exec:** normal
**Depende de:** Fase 1 (Fundación técnica)

---

## Objetivo

El organizador navega 4 pasos secuenciales (Básico → Detalles → Ruta → Revisión) con indicador de
progreso visible, puede publicar o guardar borrador desde el Step 4, y el modo edición
(`isEditing = true`) no regresiona: conserva el flujo de scroll anterior mientras el wizard se añade
únicamente para creación nueva. Las decisiones de diseño de la auditoría UX (resolución de
bloqueantes B-1 a B-6 y sugerencias S-2/S-3/S-4/S-5) quedan implementadas en Flutter.

---

## Alcance (entra / no entra)

### Entra

- Agregar `shimmer: ^3.0.0` a `pubspec.yaml` (requerido por widgets de animación).
- Crear directorio `lib/features/events/presentation/form/widgets/steps/` con **9 widgets** nuevos
  (un widget por archivo, cero métodos `Widget _buildXxx()`):
  - `event_step_indicator.dart`
  - `event_step_nav_bar.dart`
  - `cover_picker_sheet.dart`
  - `event_form_step1.dart`
  - `event_form_step2.dart`
  - `event_form_step3.dart`
  - `event_form_step4_review.dart`
  - `search_skeleton_list.dart` — 3 skeleton rows con shimmer (S-5, estado "cargando búsqueda")
  - `pulsing_map_dot.dart` — punto pulsante animado sobre mapa vacío (S-3)
- Refactorizar `EventFormView`: `IndexedStack` con `AnimatedSwitcher(key: ValueKey(currentStep))`;
  AppBar con botón "Cancelar" (`AppTextButton`, `text-secondary`) en modo creación (todos los pasos);
  botón back del AppBar 40px.
- Actualizar `EventFormBasicInfoSection`: eliminar `AppCityAutocomplete` y corregir
  `_buildEventContext()` para usar `meetingPointName` como proxy de ciudad.
- Modificar `EventFormLocationsSection` (y/o sus widgets hijo):
  - B-3: touch targets de botones X eliminar waypoint → frame/GestureDetector de 44×44 px.
  - B-4: `recenterBtn` 44×44 px.
  - S-2: resultado activo de autocomplete → borde izquierdo 4 px naranja (`AppColors.primary`).
  - S-5: mostrar `SearchSkeletonList` mientras el autocomplete está en estado de carga.
  - S-3: mostrar `PulsingMapDot` cuando el mapa está vacío (sin waypoints).
- Eliminar 4 archivos de código muerto tras verificar con `grep -r` que no tienen importaciones
  externas: `event_form_content.dart`, `event_form_bottom_bar.dart`, `draft_link.dart`,
  `publish_button.dart`.
- `dart analyze` limpio al final de la fase.

### No entra

- Botón "Generar con IA" en `CoverPickerSheet` — **la funcionalidad de generación IA fue
  eliminada**; `CoverPickerSheet` solo tiene "Subir desde galería".
- Cambios en `rideglory-api` (pertenecen a Fase 1).
- Tests (pertenecen a Fase 3).
- Widget tests para Steps 2, 3 y 4 (diferidos a Fase 3 o deuda técnica documentada).
- Wizard para modo edición — se implementa con `// TODO(stepper-edit)` y el scroll anterior
  permanece.
- Perfilado de memoria de `IndexedStack` (Mapbox + Quill vivos simultáneamente).
- Modificaciones a `cover_placeholder_view.dart` (se conserva intacto como fallback de
  `CoverPreviewWidget`).

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificación de prerequisito

1. Verificar que la Fase 1 está completa: `EventFormState` tiene `currentStep`, `EventFormCubit`
   expone `nextStep()`, `prevStep()`, `validateStep()`, `isCurrentStepValid()`, y las ARB keys del
   stepper existen en `app_es.arb`.
2. Correr `dart analyze` sobre el estado actual del repo y registrar el conteo base de
   warnings/errores. Si hay errores bloqueantes heredados, detener y reportar al humano.

### Paso 1 — Agregar dependencia shimmer y crear widgets de animación

1. En `pubspec.yaml`, agregar bajo `dependencies`:
   ```yaml
   shimmer: ^3.0.0
   ```
   Correr `flutter pub get`.

2. Crear `lib/features/events/presentation/form/widgets/steps/search_skeleton_list.dart`:
   - `StatelessWidget`. Sin parámetros.
   - 3 filas skeleton con shimmer usando el paquete `shimmer`.
   - Cada fila: `Shimmer.fromColors(baseColor: #383838, highlightColor: #505050, child: Container(height: 48, decoration: BoxDecoration(color: #383838, borderRadius: 8px)))`.
   - Fila separada por `Divider` o `SizedBox(height: 1)` igual a los resultados reales.
   - Devuelve una `Column` con las 3 filas, sin `SingleChildScrollView` propio.
   - Accesibilidad: `Semantics(label: 'Cargando resultados', child: ...)`.

3. Crear `lib/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart`:
   - `StatefulWidget`. Sin parámetros. El dot es decorativo/instructivo — sin callbacks.
   - `AnimationController` con `vsync: this`, `duration: const Duration(milliseconds: 1200)`,
     `.repeat()` en `initState`.
   - `CurvedAnimation(parent: _controller, curve: Curves.easeOut)`.
   - Stack con 2 capas:
     1. Capa exterior (ring): `ScaleTransition(scale: Tween(begin: 1.0, end: 2.0))` +
        `FadeTransition(opacity: Tween(begin: 1.0, end: 0.0))` sobre un `Container` circular
        de 44×44 px, color `AppColors.primary.withValues(alpha: 0.25)`, sin borde.
     2. Capa interior (dot): `Container` circular 14×14 px, color `AppColors.primary`,
        centrado sobre el ring (sin animación propia).
   - El widget completo ocupa el espacio del ring (44×44 px).
   - `dispose()` destruye el `AnimationController`.

### Paso 2 — Crear los widgets de navegación del stepper

4. Crear `event_step_indicator.dart`:
   - `StatelessWidget` con `currentStep: int` (0–3) y `totalSteps: int` (fijo en 4).
   - 4 círculos de 28 px con `BoxDecoration` circular + etiqueta debajo.
   - **Estado completado** (índice < currentStep): fondo `colorScheme.primary` (naranja sólido),
     **ícono check** (`Icons.check`, tamaño 16) con color `AppColors.darkBgPrimary`. No número.
   - **Estado activo** (índice == currentStep): fondo `colorScheme.primary`, número con
     `AppColors.darkBgPrimary`. Nunca blanco.
   - **Estado futuro** (índice > currentStep): fondo `colorScheme.surfaceContainerHighest`,
     número con `colorScheme.onSurfaceVariant`.
   - Etiquetas: `l10n.event_step_basicInfo`, `l10n.event_step_details`, `l10n.event_step_route`,
     `l10n.event_step_reviewAndPublish`.
   - Accesibilidad: `Semantics(label: l10n.event_step_progressLabel(current: currentStep + 1, total: totalSteps))` envolviendo el indicador completo.

5. Crear `event_step_nav_bar.dart`:
   - `StatelessWidget` con `isLastStep: bool`.
   - Layout: `SafeArea(bottom: true)` → `Container` con borde superior `AppColors.darkBorderPrimary`
     → `Row` con dos botones.
   - Botón izquierdo: `AppTextButton` label `l10n.event_step_back`; en Step 0 (`currentStep == 0`)
     → `SizedBox.shrink()` (oculto); llama `cubit.prevStep()`.
   - `isLastStep == false` (Steps 1–3): botón derecho = `AppButton` label
     `l10n.event_step_continue`; al pulsar llama `cubit.validateStep(currentStep)` y, si `true`,
     `cubit.nextStep()`; si `false`, no avanza (los validators de `FormBuilder` muestran errores).
     El texto del botón deshabilitado usa color `#9CA3AF` mínimo (contraste ≥ 5.1:1 sobre
     `#242429`) — no `#6B7280`.
   - `isLastStep == true` (Step 4): `AppTextButton` "Guardar borrador"
     (`l10n.event_step_saveDraft`, encima del accent) + `AppButton` accent
     `l10n.event_form_publish_action` (key existente). Texto del accent con
     `AppColors.darkBgPrimary`, nunca blanco.

### Paso 3 — Crear los widgets de cada step

6. Crear `event_form_step1.dart`:
   - `StatelessWidget`. Recibe `isEditing: bool` y `descriptionInitialValue: String?`.
   - Contenido (columna con padding 16/16/24, `SingleChildScrollView`):
     - Área de portada: `GestureDetector` (height mínima ≥ 120 px) que muestra
       `CoverPreviewWidget` / `FormImageSection` y al pulsar abre `CoverPickerSheet`.
     - `AppSpacing.gapXxl`
     - `EventFormBasicInfoSection(isEditing: isEditing, descriptionInitialValue: descriptionInitialValue)`
     - `AppSpacing.gapXxl`
     - `const EventFormDateTimeSection()`

7. Crear `event_form_step2.dart`:
   - `StatelessWidget`. Sin parámetros. `SingleChildScrollView`, padding estándar:
     `EventFormDifficultySection`, `EventFormEventTypeSection`, `EventFormMaxParticipantsSection`,
     `EventFormPriceSection`, `EventFormMultiBrandSection`.

8. Crear `event_form_step3.dart`:
   - `StatefulWidget`. Recibe `isActive: bool`. Cuando `isActive == false`, el `MapboxMap` interno
     no se inicializa (lazy-init). Contenido: `EventFormLocationsSection(isActive: isActive)`
     envuelto en `SingleChildScrollView`.

9. Crear `event_form_step4_review.dart`:
   - `StatelessWidget`. Lee el cubit directamente.
   - **Sin** `flutter_quill`, sin `MapboxMap`, sin pickers.
   - Cards por sección: "Básico", "Configuración", "Ruta". Cada card incluye en su header un botón
     "Editar" — `Row` con `AppSpacing.spacer` (fill_container) + `Icon(Icons.edit_outlined, size: 16,
     color: AppColors.primary)` + `AppTextButton` label "Editar" (color `AppColors.primary`);
     al pulsar llama `cubit.goToStep(n)` (0 para Básico, 1 para Configuración, 2 para Ruta).
   - Dificultad: mostrar flame icons (`🔥` o ícono de llama custom) en naranja en cantidad según el
     nivel (1, 2 o 3 llamas) + label del nivel. Mismo patrón visual que el selector de dificultad
     de Step 2.
   - Descripción (texto plano): si el value empieza con `[`, usar
     `Document.fromJson(jsonDecode(value)).toPlainText()`; fallback al string raw si falla el parse.
   - Marcas: lista o "Todas las marcas". Participantes: número o "Sin límite". Precio: monto o
     "Evento gratuito".

### Paso 4 — Crear `CoverPickerSheet`

10. Crear `cover_picker_sheet.dart`:
    - `StatelessWidget`. Se muestra como bottom sheet modal.
    - **Un solo** `AppButton`: "Subir desde galería" →
      `context.read<FormImageCubit>().pickImageFromGallery()` → `Navigator.pop(context)`.
    - Sin botón "Generar con IA" — la funcionalidad fue eliminada.

### Paso 5 — Refactorizar `EventFormView`

11. Reescribir `event_form_view.dart`:
    - `BlocConsumer` de saveResult y coverGenerationResult permanece (misma lógica de listener).
    - **AppBar** (modo creación): `AppFormNavHeader` sin trailing "Publicar"; botón back circular
      **40 px** (era 36 px — B-5). Agregar **"Cancelar"** (`AppTextButton`, color
      `colorScheme.onSurfaceVariant`) al lado derecho del AppBar — cierra el wizard y regresa a la
      pantalla anterior (`context.pop()`).
    - `body` modo creación:
      ```dart
      FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(cubit),
        child: Column(children: [
          EventStepIndicator(currentStep: state.currentStep, totalSteps: 4),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: IndexedStack(
              key: ValueKey(state.currentStep),
              index: state.currentStep,
              children: [
                EventFormStep1(isEditing: cubit.isEditing, descriptionInitialValue: cubit.editingEvent?.description),
                const EventFormStep2(),
                EventFormStep3(isActive: state.currentStep == 2),
                const EventFormStep4Review(),
              ],
            ),
          )),
        ]),
      )
      ```
    - `body` modo edición (`isEditing == true`): conservar `SingleChildScrollView` + `FormBuilder` +
      columna de secciones (flujo actual con `EventFormContent`), con comentario
      `// TODO(stepper-edit): implementar wizard para modo edición`.
    - `bottomNavigationBar`: `EventStepNavBar(isLastStep: state.currentStep == 3)`.
    - Mover `_getInitialValues()` desde `EventFormContent` a `EventFormView`; eliminar
      `EventFormFields.city` del mapa de valores iniciales.
    - Lógica `_onPublish` y `_onSaveDraft` movida a `EventStepNavBar` (o pasada como callbacks).

### Paso 6 — Actualizar `EventFormBasicInfoSection`

12. Eliminar import de `AppCityAutocomplete`; actualizar `_buildEventContext()`:
    ```dart
    // meetingPointName actúa como proxy de ciudad para el contexto IA
    final city = context.read<EventFormCubit>().state.meetingPointName ?? '';
    ```

### Paso 7 — Actualizar `EventFormLocationsSection` y sus widgets hijo

13. Touch targets X eliminar (B-3): envolver cada ícono X en un `GestureDetector` o `SizedBox` de
    44×44 px. Si los botones están en un widget hijo separado (p.ej. un `WaypointListItem`), aplicar
    el cambio allí.

14. `recenterBtn` (B-4): cambiar a 44×44 px (era 36×36 px).

15. S-2 — resultado activo en autocomplete: el item de la lista marcado como activo debe tener
    `BoxDecoration` con `border: Border(left: BorderSide(color: AppColors.primary, width: 4))` y
    `color: Color(0xFF1C1C24)` (vs. `Color(0xFF161616)` para inactivos).

16. S-5 — estado cargando búsqueda: cuando `isLoading == true` en el estado del autocomplete,
    mostrar `SearchSkeletonList()` en lugar del dropdown de resultados. Cuando `isLoading == false`
    y hay resultados, mostrar la lista normal.

17. S-3 — PulsingMapDot: cuando el mapa está vacío (sin waypoints y sin búsqueda activa), mostrar
    `PulsingMapDot()` centrado sobre el área del mapa. Usar `Positioned` o `Overlay` según la
    estructura del widget de mapa existente. Cuando hay ≥1 waypoint o búsqueda activa, ocultar el
    dot (`PulsingMapDot` ya no se muestra).

### Paso 8 — Eliminar archivos de código muerto

18. Antes de eliminar cada archivo, correr `grep -r "<nombre_base>" lib/ --include="*.dart" -l`:
    - `draft_link.dart` — `grep -r "draft_link" lib/`.
    - `publish_button.dart` — `grep -r "publish_button" lib/`.
    - `event_form_bottom_bar.dart` — `grep -r "event_form_bottom_bar" lib/`.
    - `event_form_content.dart` — `grep -r "event_form_content" lib/`.
19. Eliminar los 4 archivos.

### Paso 9 — Cierre de fase

20. `dart analyze` y resolver todos los errores.
21. Verificar que no quedan referencias a `EventFormFields.city` en presentación:
    `grep -r "EventFormFields.city" lib/features/events/presentation/`.
22. `flutter pub get` limpio tras agregar `shimmer`.
23. Compilación en frío opcional: `flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json`.

---

## Archivos a crear / modificar (rutas reales)

### `pubspec.yaml`

| Campo | Cambio |
|-------|--------|
| `dependencies` | Agregar `shimmer: ^3.0.0` |

### Archivos a crear

| Ruta | Qué hace |
|------|----------|
| `lib/features/events/presentation/form/widgets/steps/search_skeleton_list.dart` | 3 skeleton rows con `Shimmer.fromColors` — estado "cargando búsqueda" (S-5) |
| `lib/features/events/presentation/form/widgets/steps/pulsing_map_dot.dart` | Dot 14 px + ring pulsante 44 px con `ScaleTransition` + `FadeTransition` — mapa vacío (S-3) |
| `lib/features/events/presentation/form/widgets/steps/event_step_indicator.dart` | Indicador de progreso: completados con check icon oscuro, activo con número oscuro, futuro neutro |
| `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` | Barra Atrás/Continuar y Publicar/Borrador para Step 4; texto disabled en `#9CA3AF` |
| `lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` | Bottom sheet: solo "Subir desde galería" (sin "Generar con IA") |
| `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` | Step 1: portada + `EventFormBasicInfoSection` + `EventFormDateTimeSection` |
| `lib/features/events/presentation/form/widgets/steps/event_form_step2.dart` | Step 2: dificultad, tipo, participantes, precio, multimarca |
| `lib/features/events/presentation/form/widgets/steps/event_form_step3.dart` | Step 3: `EventFormLocationsSection` con `MapboxMap` lazy-init |
| `lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` | Step 4: resumen de texto plano; botón "Editar" por card; llamas para dificultad |

### Archivos a modificar

| Ruta | Qué cambia |
|------|------------|
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | `FormBuilder` global + `IndexedStack` + `AnimatedSwitcher`; AppBar "Cancelar" en modo creación; back 40 px; modo edición conserva scroll con `// TODO(stepper-edit)` |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | Eliminar `AppCityAutocomplete`; `_buildEventContext()` usa `state.meetingPointName ?? ''` |
| `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` (y/o widgets hijo) | Touch targets X 44×44 px; recenterBtn 44×44 px; S-2 active autocomplete; S-5 SearchSkeletonList; S-3 PulsingMapDot |

### Archivos a eliminar

| Ruta | Por qué |
|------|---------|
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Reemplazado por Steps 1–4 + `EventFormView` refactorizado |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | Reemplazado por `EventStepNavBar` |
| `lib/features/events/presentation/form/widgets/draft_link.dart` | Lógica movida a `EventStepNavBar` (Step 4); código muerto |
| `lib/features/events/presentation/form/widgets/publish_button.dart` | Lógica movida a `EventStepNavBar` (Step 4); código muerto |

### Archivos a NO modificar

| Ruta | Por qué se conserva |
|------|---------------------|
| `lib/features/events/presentation/form/widgets/cover_placeholder_view.dart` | Referenciado como fallback por `CoverPreviewWidget` |
| `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` | Se reutiliza en `EventFormStep1` sin cambios |
| Secciones en `widgets/sections/` excepto `event_form_basic_info_section.dart` y `event_form_locations_section.dart` | Se reutilizan como están en los steps |

---

## Contratos / API rideglory-api

Ninguno. Los contratos de `rideglory-api` fueron modificados en la Fase 1. Esta fase es
exclusivamente Flutter.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Flujo completo de creación:** Navegar Step 1 → Step 2 → Step 3 → Step 4 → pulsar "Publicar"
   produce el mismo payload que el formulario de scroll anterior. No hay pérdida de datos al
   retroceder con "Atrás".

2. **Validación Step 1:** Con el campo nombre vacío, pulsar "Continuar" no avanza al Step 2 y el
   validator del campo `name` muestra el error. Con nombre lleno, avanza correctamente.

3. **Step 4 — Publicar:** El botón "Publicar" usa `l10n.event_form_publish_action` (sin hardcoding).
   El botón accent tiene texto en `AppColors.darkBgPrimary`, nunca blanco.

4. **Step 4 — Guardar borrador:** El `AppTextButton` "Guardar borrador" en Step 4 llama
   `cubit.saveDraft()` correctamente; solo aparece en Step 4.

5. **Step indicator — completado con check:** Los pasos completados (índice < currentStep) muestran
   fondo naranja sólido (`colorScheme.primary`) con ícono check (`Icons.check`) en
   `AppColors.darkBgPrimary`. No solo fondo diferente — el ícono es el diferenciador (WCAG 1.4.1).

6. **Step indicator — activo:** Círculo activo con fondo naranja + número con `AppColors.darkBgPrimary`. Nunca texto blanco sobre naranja.

7. **Step indicator — futuro:** Fondo `colorScheme.surfaceContainerHighest`, número con
   `colorScheme.onSurfaceVariant`.

8. **`AnimatedSwitcher` con key:** El `IndexedStack` está envuelto en `AnimatedSwitcher` con
   `key: ValueKey(state.currentStep)`.

9. **Modo edición sin regresión:** Con `isEditing = true`, el formulario muestra el scroll único
   anterior sin el wizard. Comentario `// TODO(stepper-edit)` visible en el código.

10. **AppBar "Cancelar":** En modo creación, el AppBar tiene un `AppTextButton` "Cancelar" en el
    lado derecho que cierra el wizard (`context.pop()`). Visible en todos los pasos (1–4).

11. **Back button 40 px:** El botón back circular del AppBar mide 40×40 px (era 36×36 px — B-5).

12. **CoverPickerSheet sin IA:** `cover_picker_sheet.dart` no contiene ningún botón ni texto
    relacionado con "Generar con IA". Solo tiene "Subir desde galería".

13. **Step 4 — botones "Editar":** Cada card de resumen (Básico, Configuración, Ruta) tiene un
    botón "Editar" que al pulsarse llama `cubit.goToStep(n)` con el índice correcto (0, 1, 2
    respectivamente).

14. **Step 4 — dificultad con llamas:** La dificultad en Step 4 se muestra con flame icons en
    `AppColors.primary` (no como texto plano). Cantidad de llamas según el nivel.

15. **Touch targets X (B-3):** Cada botón de eliminar waypoint tiene un área táctil de mínimo
    44×44 px. `grep -r "GestureDetector\|SizedBox.*44\|width: 44" lib/features/events/presentation/form/widgets/sections/`
    muestra la implementación.

16. **recenterBtn 44 px (B-4):** El botón de recentrar el mapa mide 44×44 px.

17. **Autocomplete activo (S-2):** El resultado activo de la búsqueda de lugares tiene borde
    izquierdo naranja de 4 px y fondo `Color(0xFF1C1C24)`, diferenciable del resto.

18. **SearchSkeletonList (S-5):** Cuando el autocomplete está cargando resultados, se muestran 3
    filas skeleton con shimmer (`Shimmer.fromColors`) en lugar de la lista vacía.

19. **PulsingMapDot (S-3):** Cuando el mapa está vacío (0 waypoints), se muestra el `PulsingMapDot`
    (ring pulsante 44 px + dot 14 px naranja). Cuando hay ≥1 waypoint, el dot desaparece.

20. **`shimmer` en pubspec.yaml:** `flutter pub get` pasa limpio con `shimmer: ^3.0.0` en
    `dependencies`.

21. **`city` no forzado:** En `cover_picker_sheet.dart`, NO se pasa `city` (el campo fue eliminado
    junto con la funcionalidad IA). La llamada solo es a `pickImageFromGallery()`.

22. **Un widget por archivo:** Ningún archivo en `widgets/steps/` contiene más de una clase que
    extienda `StatelessWidget` o `StatefulWidget`.

23. **Cero métodos `Widget _buildXxx()`:**
    `grep -r "Widget _build" lib/features/events/presentation/form/widgets/steps/` retorna vacío.

24. **Código muerto eliminado:**
    `grep -r "draft_link\|publish_button\|event_form_bottom_bar\|event_form_content" lib/ --include="*.dart"`
    retorna vacío.

25. **Sin referencias a `EventFormFields.city` en presentación:**
    `grep -r "EventFormFields.city" lib/features/events/presentation/` retorna vacío.

26. **`dart analyze` sin errores nuevos:** Conteo de errores/warnings al final ≤ conteo base del
    Paso 0.

27. **Step 4 sin Quill ni Mapbox:**
    `grep -r "flutter_quill\|MapboxMap" lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart`
    retorna vacío.

---

## Pruebas (unitarias / widget / integración)

Las pruebas formales de esta fase pertenecen a la **Fase 3**. El implementador debe hacer
verificación manual mínima antes de cerrar la fase:

| Verificación | Método |
|-------------|--------|
| Flujo Step 1–4 completo | `flutter run --flavor dev`, navegar el wizard |
| Validación de nombre vacío | Intentar avanzar desde Step 1 sin nombre; error visible |
| Publicar desde Step 4 | Completar 4 pasos y publicar; SnackBar de éxito |
| Modo edición | Editar evento existente; scroll único sin wizard |
| "Cancelar" en AppBar | Pulsar Cancelar en cualquier paso; cierra el wizard |
| Botones "Editar" en Step 4 | Pulsar "Editar" de Básico → va a Step 1 |
| PulsingMapDot | Abrir Step 3 vacío; ver el dot pulsante |
| SearchSkeletonList | Escribir en búsqueda de lugares; ver skeleton antes de resultados |
| X delete touch target | Eliminar waypoint fácilmente con el dedo; sin dificultad |
| recenterBtn | Pulsar fácilmente; 44 px |

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **`AnimatedSwitcher` sin `ValueKey`** — Sin `key: ValueKey(currentStep)` la animación no ocurre. | ALTA | AC-8 exige la key explícitamente; verificar visualmente. |
| R2 | **`IndexedStack` y memoria** — Mapbox + Quill vivos simultáneamente en ≤ 3 GB. | MEDIA | Lazy-init via `isActive` en `EventFormStep3`. Documentar como tech debt. |
| R3 | **`PulsingMapDot` sobre Mapbox** — Posicionar un widget Flutter sobre un `MapboxMap` nativo puede requerir `Stack` específico según la implementación del mapa. | MEDIA | Usar `Stack` sobre el `MapboxMap` widget; si el mapa usa una vista nativa opaca, usar el overlay de Mapbox SDK para el dot en lugar de un widget Flutter. Documentar la solución adoptada. |
| R4 | **`Shimmer` vs dark theme** — Los colores de shimmer deben usar tonos del dark theme para no romper la paleta. `#383838` base y `#505050` highlight son los valores aprobados (visibles sobre `#161616`). | BAJA | Hardcodear `Color(0xFF383838)` y `Color(0xFF505050)` en `SearchSkeletonList` con comentario de justificación. |
| R5 | **`isActive` no existe en `EventFormLocationsSection`** — Si el widget actual no acepta `isActive`, la compilación falla. | MEDIA | Buscar la firma real del constructor antes de pasarle el parámetro. Si no existe, agregar el parámetro o usar `Visibility(visible: isActive, maintainState: true, child: ...)`. |
| R6 | **Estructura de `EventFormLocationsSection`** — Los botones X, `recenterBtn` y la lista de autocomplete pueden estar en widgets hijo separados no identificados en el plan. | MEDIA | `grep -rn "recenterBtn\|IconButton.*close\|Icons.close" lib/features/events/presentation/form/` para localizar el código real antes de modificar. |
| R7 | **Estado de portada perdido al cambiar de paso** — `FormImageCubit` re-montado. | BAJA | `IndexedStack` mantiene children vivos. `FormImageCubit` proveído a nivel de página. Sin riesgo. |

---

## Dependencias

### Fase 1 — Fundación técnica (prerequisito directo)

- `EventFormState.currentStep` existe y codegen ejecutado.
- `EventFormCubit` expone `nextStep()`, `prevStep()`, `validateStep(int)`, `isCurrentStepValid()`.
- ARB keys del stepper en `app_es.arb` y `app_localizations_es.dart`.
- `generateCover()` eliminado del cubit (o acepta `String? city` nullable) — con la eliminación
  de IA, `cover_picker_sheet.dart` no llama `generateCover()`, por lo que este punto ya no bloquea.
- `_step1Fields`, `_step2Fields`, `_step3Fields` definidos.

---

## Ejecución recomendada (nivel rg-exec: normal)

**Nivel:** `normal`

**Por qué normal y no lite:**
- 9 widgets nuevos con lógica UI específica y constraints UX (touch targets, animaciones,
  accesibilidad).
- Animaciones (`AnimationController`, `ScaleTransition`, `FadeTransition`) requieren gestión de
  lifecycle correcta para evitar memory leaks.
- Eliminación de 4 archivos con verificación de imports.
- Lógica de validación por paso en `EventStepNavBar`.
- No-regresión del modo edición.
- Modificaciones en `EventFormLocationsSection` que tocan lógica existente de mapa.

**Por qué no full:**
- Sin cambios de backend en esta fase.
- Sin contratos API nuevos.
- Sin migración de datos.
- Sin PII ni seguridad.
