# Fase 2 — Wizard completo

**Slug:** `event-form-stepper`
**Fase:** 2 de 3
**Fecha:** 2026-06-09T02:14:02Z
**Nivel rg-exec:** normal
**Depende de:** Fase 1 (Fundación técnica)

---

## Objetivo

El organizador navega 4 pasos secuenciales (Básico → Detalles → Ruta → Revisión) con indicador de progreso visible, puede publicar o guardar borrador desde el Step 4, y el modo edición (`isEditing = true`) no regresiona: conserva el flujo de scroll anterior mientras el wizard se añade únicamente para creación nueva.

---

## Alcance (entra / no entra)

### Entra

- Crear directorio `lib/features/events/presentation/form/widgets/steps/` con 7 widgets nuevos (un widget por archivo, cero métodos `Widget _buildXxx()`):
  - `event_step_indicator.dart`
  - `event_step_nav_bar.dart`
  - `cover_picker_sheet.dart`
  - `event_form_step1.dart`
  - `event_form_step2.dart`
  - `event_form_step3.dart`
  - `event_form_step4_review.dart`
- Refactorizar `EventFormView` para envolver el `IndexedStack` con `FormBuilder` y `AnimatedSwitcher(key: ValueKey(currentStep))`.
- Actualizar `EventFormBasicInfoSection`: eliminar `AppCityAutocomplete` y corregir `_buildEventContext()` para usar `meetingPointName` como proxy de ciudad.
- Eliminar 4 archivos de código muerto tras verificar con `grep -r` que no tienen importaciones externas: `event_form_content.dart`, `event_form_bottom_bar.dart`, `draft_link.dart`, `publish_button.dart`.
- `dart analyze` limpio al final de la fase.

### No entra

- Cambios en `rideglory-api` (pertenecen a Fase 1).
- Tests (pertenecen a Fase 3).
- Widget tests para Steps 2, 3 y 4 (diferidos a Fase 3 o deuda técnica documentada).
- Wizard para modo edición — se implementa con `// TODO(stepper-edit)` y el scroll anterior permanece.
- Perfilado de memoria de `IndexedStack` (Mapbox + Quill vivos simultáneamente).
- Modificaciones a `cover_placeholder_view.dart` (se conserva intacto como fallback de `CoverPreviewWidget`).

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificación de prerequisito

1. Verificar que la Fase 1 está completa: `EventFormState` tiene `currentStep`, `EventFormCubit` expone `nextStep()`, `prevStep()`, `validateStep()`, `isCurrentStepValid()`, y las ARB keys del stepper existen en `app_es.arb`.
2. Correr `dart analyze` sobre el estado actual del repo y registrar el conteo base de warnings/errores. Si hay errores bloqueantes heredados, detener y reportar al humano.

### Paso 1 — Crear el directorio y los widgets de navegación

1. Crear `lib/features/events/presentation/form/widgets/steps/` (directorio vacío).
2. Crear `event_step_indicator.dart`:
   - `StatelessWidget` que recibe `currentStep: int` (0–3) y `totalSteps: int` (fijo en 4).
   - 4 círculos de 28 px con `BoxDecoration` circular.
   - Etiquetas debajo: `l10n.event_step_basic`, `l10n.event_step_details`, `l10n.event_step_route`, `l10n.event_step_review` (todas ≤ 8 chars).
   - Estado **activo**: fondo `colorScheme.primary` (naranja), número con `AppColors.darkBgPrimary` — nunca blanco (regla de texto oscuro sobre acento).
   - Estado **completado** (índice < currentStep): fondo `colorScheme.primary.withValues(alpha: 0.35)`, número con `AppColors.darkBgPrimary`.
   - Estado **futuro** (índice > currentStep): fondo `colorScheme.surfaceContainerHighest`, número con `colorScheme.onSurfaceVariant`.
   - Accesibilidad: `Semantics(label: l10n.event_step_progressLabel(current: currentStep + 1, total: totalSteps))` envolviendo el indicador completo.
3. Crear `event_step_nav_bar.dart`:
   - `StatelessWidget` que recibe `isLastStep: bool`.
   - Layout: `SafeArea(bottom: true)` → `Container` con borde superior `AppColors.darkBorderPrimary` → `Row` con dos botones.
   - Botón izquierdo: `AppTextButton` con label `l10n.event_step_back`; oculto (o invisible) en Step 0 (`currentStep == 0` → `opacity 0` o `SizedBox.shrink()`); llama `cubit.prevStep()`.
   - Cuando `isLastStep == false` (Steps 1–3): botón derecho = `AppButton` con label `l10n.event_step_continue`; al pulsar llama `cubit.validateStep(currentStep)` y, si retorna `true`, llama `cubit.nextStep()`; si retorna `false`, no avanza (los validators del `FormBuilder` muestran los errores automáticamente).
   - Cuando `isLastStep == true` (Step 4): botón derecho = `AppButton` estilo accent con label `l10n.event_form_publish_action` (key existente, no crear nueva); al pulsar ejecuta la lógica de `_onPublish` (misma lógica hoy en `EventFormView._onPublish`). `AppTextButton` secundario con label `l10n.event_step_saveDraft` encima del botón accent; llama `_onSaveDraft`.
   - Ambas acciones de guardado (`_onPublish`, `_onSaveDraft`) leen `FormImageCubit` via `context.read` — misma lógica extraída de `publish_button.dart` y `draft_link.dart`.

### Paso 2 — Crear los widgets de cada step

4. Crear `event_form_step1.dart`:
   - `StatelessWidget`. Recibe `isEditing: bool` y `descriptionInitialValue: String?`.
   - Contenido (columna con padding estándar `16/16/24`):
     - Área de portada: `GestureDetector` (height mínima ≥ 120 px) que muestra `CoverPreviewWidget` / `FormImageSection` (misma lógica extraída de `EventFormContent`) y al pulsar abre `CoverPickerSheet`.
     - `AppSpacing.gapXxl`
     - `EventFormBasicInfoSection(isEditing: isEditing, descriptionInitialValue: descriptionInitialValue)`
     - `AppSpacing.gapXxl`
     - `const EventFormDateTimeSection()`
   - Envuelto en `SingleChildScrollView` para que el teclado no corte el contenido.

5. Crear `event_form_step2.dart`:
   - `StatelessWidget`. Sin parámetros.
   - Contenido (columna con padding, `SingleChildScrollView`):
     - `const EventFormDifficultySection()`
     - `AppSpacing.gapXxl`
     - `const EventFormEventTypeSection()`
     - `AppSpacing.gapXxl`
     - `const EventFormMaxParticipantsSection()`
     - `AppSpacing.gapXxl`
     - `const EventFormPriceSection()`
     - `AppSpacing.gapXxl`
     - `const EventFormMultiBrandSection()`

6. Crear `event_form_step3.dart`:
   - `StatefulWidget` (necesita saber cuándo se convierte en el paso activo).
   - Recibe `isActive: bool`. Cuando `isActive == false`, el `MapboxMap` interno de `EventFormLocationsSection` no se inicializa (lazy-init).
   - Contenido: `EventFormLocationsSection` envuelto en `SingleChildScrollView`.
   - Implementar lazy-init: pasar `isActive` a `EventFormLocationsSection` si el widget lo acepta; si no, usar `Visibility(visible: isActive, maintainState: true, child: const EventFormLocationsSection())` como primer approach y documentar como tech debt si causa scroll issues.

7. Crear `event_form_step4_review.dart`:
   - `StatelessWidget`. Sin parámetros (lee el cubit directamente).
   - Contenido: resumen de **texto plano únicamente** — sin `flutter_quill`, sin `MapboxMap`, sin pickers.
   - Campos mostrados (leer del cubit `formKey.currentState?.value` o del `EventFormState`):
     - Título del evento
     - Descripción (texto plano — extraer con `Document.fromJson(...).toPlainText()` o fallback al string raw si falla el parse)
     - Fecha/hora de encuentro
     - Dificultad (label del enum)
     - Tipo de evento (label del enum)
     - Punto de encuentro y destino (strings del autocomplete)
     - Marcas permitidas (lista o "Todas las marcas")
     - Máximo de participantes (o "Sin límite")
     - Precio (o "Evento gratuito")
   - Layout: `ListView` con `ListTile`s o filas de label + valor para cada campo, `SingleChildScrollView`, padding estándar.

### Paso 3 — Crear `CoverPickerSheet`

8. Crear `cover_picker_sheet.dart`:
   - `StatelessWidget`. Se muestra como bottom sheet modal.
   - Dos `AppButton`:
     - "Subir desde galería" → `context.read<FormImageCubit>().pickImageFromGallery()` → `Navigator.pop(context)`.
     - "Generar con IA" → invoca:
       ```dart
       final cubit = context.read<EventFormCubit>();
       final formValues = cubit.formKey.currentState?.value;
       cubit.generateCover(
         title: formValues?[EventFormFields.name] as String? ?? '',
         eventType: (formValues?[EventFormFields.eventType] as EventType?)?.name ?? '',
         city: context.read<EventFormCubit>().state.meetingPointName,
         // city es String? nullable — no forzar ''
       );
       Navigator.pop(context);
       ```
   - Sin spinner propio: el estado de generación se refleja en `CoverPreviewWidget` en el Step 1.

### Paso 4 — Refactorizar `EventFormView`

9. Reescribir `event_form_view.dart`:
   - El `BlocConsumer` de saveResult y coverGenerationResult permanece (misma lógica de listener).
   - `AppBar`: `AppFormNavHeader` sin trailing en modo creación (el trailing "Publicar" se elimina del AppBar — ahora vive en `EventStepNavBar` para Step 4). En modo edición, conservar el trailing "Guardar" si existe.
   - `body`: cuando `isEditing == true` → conservar `SingleChildScrollView` + `FormBuilder` + columna de secciones (flujo actual con `EventFormContent`), con comentario `// TODO(stepper-edit): implementar wizard para modo edición`. Cuando `isEditing == false` → wizard:
     ```dart
     FormBuilder(
       key: cubit.formKey,
       initialValue: _getInitialValues(cubit),
       child: Column(
         children: [
           EventStepIndicator(currentStep: state.currentStep, totalSteps: 4),
           Expanded(
             child: AnimatedSwitcher(
               duration: const Duration(milliseconds: 150),
               child: IndexedStack(
                 key: ValueKey(state.currentStep),
                 index: state.currentStep,
                 children: [
                   EventFormStep1(
                     isEditing: cubit.isEditing,
                     descriptionInitialValue: cubit.editingEvent?.description,
                   ),
                   const EventFormStep2(),
                   EventFormStep3(isActive: state.currentStep == 2),
                   const EventFormStep4Review(),
                 ],
               ),
             ),
           ),
         ],
       ),
     )
     ```
   - `bottomNavigationBar`: `EventStepNavBar(isLastStep: state.currentStep == 3)`.
   - Mover `_getInitialValues()` desde `EventFormContent` a `EventFormView` (o a un helper privado estático).
   - La lógica de `_onPublish` y `_onSaveDraft` se mueve a `EventStepNavBar` (o se pasa como callbacks si se prefiere mantener el contexto en `EventFormView`).

### Paso 5 — Actualizar `EventFormBasicInfoSection`

10. En `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart`:
    - Eliminar el import de `AppCityAutocomplete` y cualquier `FormBuilderTextField` o widget relacionado con `EventFormFields.city`.
    - Actualizar `_buildEventContext()` — reemplazar:
      ```dart
      final city = formValues[EventFormFields.city] as String? ?? '';
      ```
      por:
      ```dart
      // meetingPointName actúa como proxy de ciudad para el contexto IA
      final city = context.read<EventFormCubit>().state.meetingPointName ?? '';
      ```
    - Verificar que el import de `EventFormCubit` ya existe en el archivo (lo tiene por el BLoC context); si no, añadirlo.

### Paso 6 — Eliminar archivos de código muerto

11. Antes de eliminar cada archivo, correr `grep -r "<nombre_base>" lib/ --include="*.dart" -l` para confirmar que solo `event_form_bottom_bar.dart` los importa:
    - `draft_link.dart` — confirmar con `grep -r "draft_link" lib/`.
    - `publish_button.dart` — confirmar con `grep -r "publish_button" lib/`.
    - `event_form_bottom_bar.dart` — confirmar con `grep -r "event_form_bottom_bar" lib/` (solo debe aparecer en `event_form_view.dart`, que va a ser reescrito).
    - `event_form_content.dart` — confirmar con `grep -r "event_form_content" lib/` (solo debe aparecer en `event_form_view.dart`).
12. Eliminar los 4 archivos.

### Paso 7 — Cierre de fase

13. Correr `dart analyze` y resolver todos los errores. Warnings esperados ignorables: los archivos `.g.dart` y `.freezed.dart` excluidos por `analysis_options.yaml`.
14. Verificar que no quedan referencias a `EventFormFields.city` en `lib/features/events/presentation/` con `grep -r "EventFormFields.city" lib/features/events/presentation/`.
15. Compilación en frío opcional: `flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json` para verificar que no hay errores de compilación en device.

---

## Archivos a crear / modificar (rutas reales)

### Archivos a crear

| Ruta | Qué hace |
|------|----------|
| `lib/features/events/presentation/form/widgets/steps/event_step_indicator.dart` | Indicador de progreso: 4 círculos 28 px con etiquetas y estado activo/completado/futuro |
| `lib/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart` | Barra Atrás/Continuar y Publicar/Borrador para Step 4; `SafeArea` bottom; usa `AppButton` |
| `lib/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart` | Bottom sheet de portada: galería + generar con IA; pasa `city` nullable sin forzar `''` |
| `lib/features/events/presentation/form/widgets/steps/event_form_step1.dart` | Step 1: área portada + `EventFormBasicInfoSection` + `EventFormDateTimeSection` |
| `lib/features/events/presentation/form/widgets/steps/event_form_step2.dart` | Step 2: dificultad, tipo, participantes, precio, multimarca |
| `lib/features/events/presentation/form/widgets/steps/event_form_step3.dart` | Step 3: `EventFormLocationsSection` con `MapboxMap` lazy-init |
| `lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` | Step 4: resumen texto plano; sin Quill, sin mapa, sin pickers |

### Archivos a modificar

| Ruta | Qué cambia |
|------|------------|
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | Refactorizar: `FormBuilder` global + `IndexedStack` + `AnimatedSwitcher(key: ValueKey(currentStep))`; modo edición conserva scroll con `// TODO(stepper-edit)`; `AppBar` sin trailing "Publicar" en modo creación; `bottomNavigationBar` = `EventStepNavBar` |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | Eliminar `AppCityAutocomplete`; actualizar `_buildEventContext()` para usar `state.meetingPointName ?? ''` como ciudad |

### Archivos a eliminar

| Ruta | Por qué |
|------|---------|
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Reemplazado por `EventFormStep1`–`EventFormStep4Review` + `EventFormView` refactorizado |
| `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` | Reemplazado por `EventStepNavBar` |
| `lib/features/events/presentation/form/widgets/draft_link.dart` | Lógica movida a `EventStepNavBar` (Step 4); código muerto |
| `lib/features/events/presentation/form/widgets/publish_button.dart` | Lógica movida a `EventStepNavBar` (Step 4); código muerto |

### Archivos a NO modificar

| Ruta | Por qué se conserva |
|------|---------------------|
| `lib/features/events/presentation/form/widgets/cover_placeholder_view.dart` | Referenciado como fallback por `CoverPreviewWidget`; no es código muerto |
| `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` | Se reutiliza en `EventFormStep1` sin cambios |
| Todas las secciones en `widgets/sections/` excepto `event_form_basic_info_section.dart` | Se reutilizan como estás en los steps |

---

## Contratos / API rideglory-api

Ninguno. Los contratos de `rideglory-api` fueron modificados en la Fase 1 (`GenerateCoverDto.city` opcional). Esta fase es exclusivamente Flutter.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Flujo completo de creación:** Navegar Step 1 → Step 2 → Step 3 → Step 4 → pulsar "Publicar" produce el mismo payload que el formulario de scroll anterior. No hay pérdida de datos al retroceder con "Atrás".
2. **Validación Step 1:** Con el campo nombre vacío, pulsar "Continuar" no avanza al Step 2 y el validator del campo `name` muestra el error. Con nombre lleno, avanza correctamente.
3. **Paso 4 — Publicar:** El botón "Publicar" en Step 4 usa la key `l10n.event_form_publish_action` (sin hardcoding, sin key duplicada nueva). El botón accent tiene texto en `AppColors.darkBgPrimary`, nunca blanco.
4. **Paso 4 — Guardar borrador:** El `AppTextButton` "Guardar borrador" en Step 4 llama `cubit.saveDraft()` correctamente; solo aparece en Step 4 (no en Steps 1–3).
5. **Indicador de progreso:** El círculo del paso activo tiene fondo `colorScheme.primary` y número con `AppColors.darkBgPrimary`. Los pasos completados tienen fondo `colorScheme.primary.withValues(alpha: 0.35)`. Los futuros tienen `colorScheme.surfaceContainerHighest`.
6. **`AnimatedSwitcher` con key:** El `IndexedStack` está envuelto en `AnimatedSwitcher` con `key: ValueKey(state.currentStep)`. Sin esta key, la animación de fade no ocurre (verificable visualmente).
7. **Modo edición sin regresión:** Con `isEditing = true`, el formulario muestra el scroll único anterior sin el wizard. El comentario `// TODO(stepper-edit)` es visible en el código.
8. **`city` no forzado:** En `cover_picker_sheet.dart`, el argumento `city` pasado a `cubit.generateCover()` es `state.meetingPointName` (nullable). No se pasa `''` ni se fuerza non-null.
9. **Un widget por archivo:** Ningún archivo en `widgets/steps/` contiene más de una clase que extienda `StatelessWidget` o `StatefulWidget`. La clase `State<T>` puede coexistir con su `StatefulWidget` en el mismo archivo.
10. **Cero métodos `Widget _buildXxx()`:** `grep -r "Widget _build" lib/features/events/presentation/form/widgets/steps/` retorna vacío.
11. **Código muerto eliminado:** `grep -r "draft_link\|publish_button\|event_form_bottom_bar\|event_form_content" lib/ --include="*.dart"` retorna vacío.
12. **Sin referencias a `EventFormFields.city` en presentación:** `grep -r "EventFormFields.city" lib/features/events/presentation/` retorna vacío.
13. **`dart analyze` sin errores nuevos:** El conteo de errores/warnings al final de la fase es igual o menor al conteo base del Paso 0.
14. **Step 4 sin Quill ni Mapbox:** `grep -r "flutter_quill\|MapboxMap" lib/features/events/presentation/form/widgets/steps/event_form_step4_review.dart` retorna vacío.

---

## Pruebas (unitarias / widget / integración)

Las pruebas formales de esta fase pertenecen a la **Fase 3**. Sin embargo, el implementador debe hacer verificación manual mínima antes de cerrar la fase:

| Verificación | Método |
|-------------|--------|
| Flujo de navegación Step 1–4 | Correr `flutter run --flavor dev` y navegar manualmente el wizard completo |
| Validación de nombre vacío | Intentar avanzar desde Step 1 sin nombre; confirmar error visible |
| Publicar desde Step 4 | Completar los 4 pasos y publicar; confirmar SnackBar de éxito |
| Modo edición | Abrir formulario de edición de un evento existente; confirmar scroll único sin wizard |

Los tests formales que Fase 3 deberá cubrir para esta fase:
- `event_form_step1_test.dart`: smoke test de render, botón Continuar deshabilitado con nombre vacío, habilitado con nombre lleno.
- Actualizar `event_form_basic_info_section_test.dart`: assertions de `city` ahora leen de `state.meetingPointName`, no de `EventFormFields.city` form value.

---

## Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **`AnimatedSwitcher` sin `ValueKey`** — Sin `key: ValueKey(currentStep)` la animación de fade no ocurre y el `IndexedStack` puede mostrar el índice incorrecto. | ALTA | El AC 6 exige la key explícitamente. Implementador verifica visualmente el fade al cambiar de paso. |
| R2 | **`IndexedStack` y memoria** — `MapboxMap` (Step 3) + `QuillController` (Step 1) vivos simultáneamente. En dispositivos con ≤ 3 GB puede causar presión de memoria. | MEDIA | Lazy-init del `MapboxMap` via `isActive` en `EventFormStep3`. Documentar como tech debt si el enfoque de `Visibility` causa issues de scroll. Perfilar en Fase 3. |
| R3 | **`_buildEventContext()` en `EventFormBasicInfoSection`** — Usar `context.read<EventFormCubit>()` en un método llamado desde `build` es seguro, pero si se llama fuera del árbol de BLoC lanza error. | BAJA | `EventFormBasicInfoSection` siempre está bajo `BlocProvider<EventFormCubit>` (instanciado en la página del formulario). Sin riesgo práctico. |
| R4 | **`EventFormContent` eliminado con `EventFormFields.city` inicial value** — El `_getInitialValues()` en `EventFormContent` pasa `EventFormFields.city: event.city`. Al mover este método a `EventFormView`, el campo `city` puede quedar en el mapa de valores iniciales aunque no exista como field en el formulario. `FormBuilder` ignora valores sin field matching — no falla, pero es ruido. | BAJA | Eliminar la entrada `EventFormFields.city` del mapa de valores iniciales en `_getInitialValues()` al moverlo a `EventFormView`. |
| R5 | **`draft_link.dart` / `publish_button.dart` con imports externos** — Si algún otro archivo los importa (no detectado por el `grep` del plan), eliminarlos rompe la compilación. | BAJA | El Paso 6 exige `grep -r` antes de eliminar. Si aparece un import inesperado, conservar el archivo y reportar. |
| R6 | **Estado de portada perdido al cambiar de paso** — `FormImageCubit` es un Cubit de scope de página; si se re-monta al cambiar de paso, pierde la imagen seleccionada. | BAJA | `IndexedStack` mantiene todos los children vivos (no desmonta). `FormImageCubit` está proveído a nivel de página, no de step. Sin riesgo de pérdida. |
| R7 | **`EventFormStep3` lazy-init con `Visibility`** — `maintainState: true` mantiene el `FormBuilderField` montado pero el `MapboxMap` puede no renderizar correctamente al volverse visible por primera vez. | BAJA | Probar `Visibility(maintainState: true)` primero. Si falla, pasar `isActive` directamente a `EventFormLocationsSection` y que ese widget maneje la inicialización del mapa condicionalmente. Documentar la solución adoptada en un comentario. |

---

## Dependencias

### Fase 1 — Fundación técnica (prerequisito directo)

Esta fase requiere que la Fase 1 haya completado:

- `EventFormState.currentStep` (`@Default(0) int currentStep`) existe y el codegen fue ejecutado. Sin este campo, `BlocBuilder` no puede leer `state.currentStep` para construir el `IndexedStack`.
- `EventFormCubit` expone `nextStep()`, `prevStep()`, `validateStep(int)`, `isCurrentStepValid()`. Sin estos métodos, `EventStepNavBar` no puede compilar.
- Las ARB keys del stepper (`event_step_basic`, `event_step_details`, `event_step_route`, `event_step_review`, `event_step_continue`, `event_step_back`, `event_step_saveDraft`) existen en `app_es.arb` y en `app_localizations_es.dart`. Sin ellas, `EventStepIndicator` y `EventStepNavBar` no pueden compilar.
- `generateCover()` en el cubit acepta `String? city` (no `required String city`). Sin este cambio, `cover_picker_sheet.dart` no puede pasar `city` como nullable.
- `_step1Fields`, `_step2Fields`, `_step3Fields` están definidos en el cubit. Sin ellos, `validateStep()` retorna vacío y "Continuar" nunca bloquea.

---

## Ejecución recomendada (nivel rg-exec: normal)

**Nivel:** `normal`

**Por qué normal y no lite:**
- **7 widgets nuevos** en un directorio nuevo, cada uno con su propia lógica UI y constraints específicos (regla de acento, `SafeArea`, lazy-init).
- **Eliminación de 4 archivos** con verificación de imports — requiere `grep` previo y no es una tarea mecánica trivial.
- **Lógica de validación por paso** en `EventStepNavBar` que llama `validateStep()` y condiciona la navegación — lógica de control de flujo no trivial.
- **No-regresión del modo edición** — el implementador debe mantener el flujo de scroll anterior funcional mientras añade el wizard para creación nueva.
- **Una área principal** (`presentation/form/widgets/`) con modificaciones transversales (view, sections, nuevo subdirectorio).

**Por qué no full:**
- Sin cambios de backend en esta fase.
- Sin contratos API nuevos.
- Sin migración de datos.
- Sin PII ni seguridad.
- El riesgo más alto (R2, memoria) está mitigado con una estrategia concreta (lazy-init) y es perfilable en Fase 3.
