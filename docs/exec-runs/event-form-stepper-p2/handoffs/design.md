# Design handoff — event-form-stepper-p2

**Fecha:** 2026-06-11T23:03:16Z
**Status:** done — fix UX bloqueantes 2026-06-11T23:12:48Z

---

## Sistema de diseño base

| Token | Valor |
|-------|-------|
| Primary (acento) | `#f98c1f` |
| Texto sobre primary | `#0D0D0F` (darkBgPrimary) — NUNCA blanco |
| Dark bg primary | `#0D0D0F` |
| Dark bg secondary | `#161618` |
| Dark card | `#1C1C24` |
| Border | `#2A2A38` |
| Text primary | `#FFFFFF` |
| Text secondary | `#A0A0B0` |
| Text tertiary | `#5A5A70` |
| Font | Space Grotesk |
| Border radius estándar | 8px |
| Cambios esta fase | Ningún token nuevo — se extiende el sistema existente |

---

## Pantallas y estados

| Pantalla | Tipo | Mockup | Descripción |
|----------|------|--------|-------------|
| Step 1 — Básico (vacío) | UPDATE | `step1-basico.html` | AppBar sin "Publicar" derecha; "Cancelar" derecha; EventStepIndicator en slot bottom; Cover placeholder; Básico + Fecha/Hora; NavBar solo "Continuar" |
| Step 1 — Cover picker sheet | EXTEND | `step1-basico.html` | Bottom sheet con opción "Subir desde galería"; sin IA |
| Step 1 — Error validación nombre | EXTEND | `step1-basico.html` | Campo nombre con borde rojo + mensaje error bajo el campo; step no avanza |
| Step 2 — Detalles | UPDATE | `step2-detalles.html` | Indicador: paso 1 completado (✓ naranja); Dificultad + Tipo + Marcas + Participantes + Precio; NavBar Atrás + Continuar |
| Step 3 — Ruta (mapa vacío) | UPDATE | `step3-ruta.html` | Indicador: pasos 1-2 completados; PulsingMapDot en centro del mapa; SearchSkeletonList en autocomplete loading; NavBar Atrás + Continuar |
| Step 3 — Ruta con puntos + autocomplete | EXTEND | `step3-ruta.html` | PulsingMapDot oculto; waypoints con delete 44×44; ítem activo con borde naranja 4px izquierdo |
| Step 4 — Revisión | UPDATE | `step4-revision.html` | Indicador: pasos 1-3 completados; 3 review cards (Básico/Configuración/Ruta) con botón "Editar"; llamas en `#f98c1f`; AppButton "Publicar evento" + AppTextButton "Guardar borrador" |
| Step 4 — Publicando | EXTEND | `step4-revision.html` | Botón en estado loading (spinner + texto "Publicando..."); cards en opacidad reducida |
| EventStepIndicator — todos los estados | NEW | `step-indicator-states.html` | Documentación visual de los 4 estados del indicador |
| Componentes UX — correcciones B/S | NEW | `components-ux.html` | B-3 (waypoint delete 44px), B-4 (recenter 44px), B-5 (back btn 40px), S-2 (autocomplete activo), S-5 (skeleton), S-3 (pulsing dot) |

---

## Flujos UX

### Flujo principal — Creación de evento

```
[EventFormView — modo creación]
  AppBar: Cancelar (izq) | "Nuevo evento" (centro) | [vacío derecha]
  Bottom slot: EventStepIndicator [1] [─] [2] [─] [3] [─] [4]
  Body: IndexedStack index=currentStep
    │
    ├─ Step 1 (Básico)
    │   CoverPickerSheet → pickImageFromGallery()
    │   EventFormBasicInfoSection (nombre + descripción)
    │   EventFormDateTimeSection
    │   NavBar: [Continuar]
    │       └─ validateStep(0): si nombre vacío → error in-field, NO avanza
    │
    ├─ Step 2 (Detalles)
    │   EventFormDifficultySection
    │   EventFormEventTypeSection
    │   EventFormMultiBrandSection
    │   EventFormMaxParticipantsSection
    │   EventFormPriceSection
    │   NavBar: [Atrás] [Continuar]
    │
    ├─ Step 3 (Ruta)
    │   EventFormLocationsSection (MapboxMap + búsqueda)
    │   NavBar: [Atrás] [Continuar]
    │
    └─ Step 4 (Revisión)
        3 review cards con botones "Editar" → cubit.goToStep(n)
        NavBar: [Publicar evento] (AppButton accent)
                [Guardar borrador] (AppTextButton)
```

### Flujo — Modo edición

```
[EventFormView isEditing=true]
  → Conserva el scroll único original (EventFormContent)
  → NO activa el wizard
  → // TODO(stepper-edit) en el código
  → AppBar muestra "Editar evento" con acciones originales
```

### Flujo — CoverPickerSheet

```
Toca cover placeholder (Step 1)
  → showModalBottomSheet → CoverPickerSheet
  → Opción: "Subir desde galería"
       → FormImageCubit.pickImageFromGallery()
       → Cierra sheet al seleccionar
  → SIN opción "Generar con IA"
```

### Flujo — Autocomplete con skeleton

```
Usuario escribe en campo de lugar (Step 3)
  isLoading = true → SearchSkeletonList (3 filas shimmer)
  isLoading = false + results → lista de sugerencias
    resultado[0]: borde izquierdo 4px naranja + fondo #1C1C24 (S-2)
    resultado[n>0]: estilo estándar
  hasError = true → mensaje de error
```

---

## Componentes

### Nuevos widgets a crear (`lib/features/events/presentation/form/widgets/steps/`)

| Widget | Tipo | Descripción del componente |
|--------|------|---------------------------|
| `EventStepIndicator` | `StatelessWidget` | Row de 4 círculos 28×28 + 3 líneas 2px; recibe `currentStep int`; estados: done/active/future |
| `EventStepNavBar` | `StatelessWidget` | Bottom bar; steps 1-3: back (oculto en step 1) + continue; step 4: AppButton "Publicar" + AppTextButton "Guardar borrador" |
| `CoverPickerSheet` | `StatelessWidget` | ModalBottomSheet; una sola opción "Subir desde galería"; sin IA |
| `EventFormStep1` | `StatelessWidget` | Scroll: cover widget + EventFormBasicInfoSection + EventFormDateTimeSection |
| `EventFormStep2` | `StatelessWidget` | Scroll: Difficulty + EventType + MultiBrand + MaxParticipants + Price |
| `EventFormStep3` | `StatelessWidget` | Scroll: EventFormLocationsSection |
| `EventFormStep4Review` | `StatelessWidget` | Scroll: 3 review cards + botones en la parte baja; sin Quill, sin MapboxMap |
| `SearchSkeletonList` | `StatelessWidget` | 3 filas Shimmer.fromColors; colores dark; baseColor #383838 / highlightColor #505050 |
| `PulsingMapDot` | `StatefulWidget` | AnimationController + dispose(); ring 44px pulsante + dot central 14px naranja; visible cuando 0 waypoints |

### Widgets existentes a modificar

| Widget | Cambio |
|--------|--------|
| `EventFormView` | Body → IndexedStack (modo creación) con FormBuilder wrapper; AppBar: quita "Publicar" trailing, añade "Cancelar" trailing; EventStepIndicator en slot bottom; branch isEditing preserva EventFormContent |
| `AppCircleIconButton` | `_size`: 36 → 40; afecta todos los back buttons de la app |
| `WaypointItemCard` | Botón eliminar: `GestureDetector` + `Padding(4)` → `SizedBox(44, 44)` + `Center(child: Icon)` |
| `RouteMapArea` | Recenter container: `width: 36, height: 36` → `width: 44, height: 44` |
| `AppPlaceSuggestionsDropdown` | Rama `isLoading`: spinner → `SearchSkeletonList`; item[0]: añadir `border-left 4px #f98c1f` + fondo `#1C1C24` |

### Componentes shared reutilizados

- `AppButton` — botón "Publicar evento" en Step 4 y NavBar
- `AppTextButton` — "Guardar borrador" + "Cancelar" en AppBar
- `AppFormNavHeader` — con slot `bottom` para EventStepIndicator
- `AppSwitch` / `AppSwitchTile` — en Precio, MultiBrand, Multi-día
- `FormImageSection` — para preview de portada en Step 1 (reutilizado)

---

## Copy (español)

### Nuevas cadenas ARB necesarias (`app_es.arb`)

| Key | Texto | Contexto |
|-----|-------|---------|
| `event_step_review_basicSection` | `Información básica` | Título card revisión Step 4 |
| `event_step_review_detailsSection` | `Configuración` | Título card revisión Step 4 |
| `event_step_review_routeSection` | `Ruta` | Título card revisión Step 4 |
| `event_step_review_editButton` | `Editar` | Botón en cada card de revisión |
| `event_cover_picker_title` | `Portada del evento` | Título del bottom sheet |
| `event_cover_picker_gallery` | `Subir desde galería` | Opción de galería en CoverPickerSheet |
| `event_cover_picker_gallery_hint` | `Selecciona una imagen de tu dispositivo` | Subtítulo de la opción |
| `event_step_review_fieldName` | `Nombre` | Label en card básico |
| `event_step_review_fieldDate` | `Fecha` | Label en card básico |
| `event_step_review_fieldCover` | `Portada` | Label en card básico |
| `event_step_review_fieldDifficulty` | `Dificultad` | Label en card configuración |
| `event_step_review_fieldType` | `Tipo` | Label en card configuración |
| `event_step_review_fieldBrands` | `Marcas` | Label en card configuración |
| `event_step_review_fieldParticipants` | `Participantes` | Label en card configuración |
| `event_step_review_fieldPrice` | `Precio` | Label en card configuración |
| `event_step_review_fieldMeetingPoint` | `Punto de encuentro` | Label en card ruta |
| `event_step_review_fieldDestination` | `Destino` | Label en card ruta |
| `event_step_review_fieldRouteType` | `Tipo de ruta` | Label en card ruta |
| `event_step_review_coverReady` | `Imagen lista` | Valor cuando hay portada en Step 4 |
| `event_step_review_noCover` | `Sin portada` | Valor cuando no hay portada en Step 4 |
| `event_step_review_noLimit` | `Sin límite` | Participantes sin máximo |
| `event_step_review_free` | `Gratuito` | Precio gratuito |
| `event_step_review_multibrand` | `Multimarca` | Marcas sin restricción |
| `event_step_review_customRoute` | `Ruta personalizada` | Tipo de ruta custom |
| `event_step_review_simpleRoute` | `Ruta simple` | Tipo de ruta simple |
| `event_form_publish_label` | `Publicar evento` | Label del AppButton en Step 4 / NavBar |

### Cadenas ARB existentes reutilizadas

| Key existente | Texto | Dónde se usa |
|---------------|-------|-------------|
| `event_step_basicInfo` | `Básico` | Tooltip/label paso 1 |
| `event_step_details` | `Detalles` | Tooltip/label paso 2 |
| `event_step_route` | `Ruta` | Tooltip/label paso 3 |
| `event_step_reviewAndPublish` | `Revisar` | Tooltip/label paso 4 |
| `event_step_continue` | `Continuar` | NavBar botón |
| `event_step_back` | `Atrás` | NavBar botón |
| `event_step_saveDraft` | `Guardar borrador` | NavBar Step 4 |
| `event_form_publish_action` | `Publicar` | AppBar trailing (modo edición) |
| `cancel` | `Cancelar` | AppBar trailing (modo creación) |

---

## Accesibilidad

### Touch targets (WCAG 2.5.5 — AA: 44×44px mínimo)

| Elemento | Antes | Después | Criterio |
|----------|-------|---------|---------|
| Botón eliminar waypoint (B-3) | ~24px (icon 16 + padding 4×2) | 44×44 via `SizedBox(44,44)` + `Center` | WCAG 2.5.5 |
| Botón recentrar mapa (B-4) | 36×36 | 44×44 | WCAG 2.5.5 |
| AppCircleIconButton / back btn (B-5) | 36×36 | 40×40 (`_size = 40`) | HIG mínimo 44pt, aquí 40pt aceptable como mejora; ver nota |
| Indicador de paso (círculos) | 28×28 (solo visual) | 28×28 — no son interactive | n/a |

> Nota B-5: El PRD especifica 40×40 (no 44×44) para el back button. El cambio `_size: 36 → 40` cumple el requerimiento del PRD. Para 44×44 estricto WCAG, sería necesario un wrapper `SizedBox(44,44)` alrededor del `GestureDetector` sin cambiar el tamaño visual — decisión diferida al Frontend.

### Contraste (WCAG 1.4.3 — AA: ratio ≥ 4.5:1)

| Combinación | Ratio estimado | Estado |
|-------------|---------------|--------|
| Texto blanco sobre `#0D0D0F` | ~21:1 | Aprobado |
| `#0D0D0F` sobre `#f98c1f` (primario) | ~4.6:1 | Aprobado — regla darkBgPrimary |
| `#A0A0B0` sobre `#0D0D0F` (secundario) | ~5.9:1 | Aprobado |
| Texto skeleton (#383838/#505050) | n/a — decorativo | n/a |

### WCAG 1.4.1 — Uso del color

- `EventStepIndicator`: el estado "completado" se diferencia mediante el **ícono check** (`Icons.check`), no solo el cambio de color. Esto garantiza que la distinción sea perceptible sin depender únicamente del color.
- Ítem activo del autocomplete: **borde izquierdo 4px naranja** como señal adicional al cambio de color de fondo.
- Llamas de dificultad: las llamas "apagadas" tienen `opacity: 0.25`, no solo color diferente — el número del nivel también se muestra en texto.

### Semántica / accesibilidad adicional

- Todos los botones de acción deben tener `Semantics(label: ...)` o estar en widgets con texto descriptivo.
- `AppCircleIconButton.back` debe usar `Semantics(button: true, label: 'Atrás')` o el tooltip/`semanticLabel` del `Icon`.
- `PulsingMapDot` debe tener `ExcludeSemantics` ya que es decorativo.
- Los círculos del `EventStepIndicator` deben tener `Semantics(label: 'Paso N de 4, completado/activo/pendiente')` para lectores de pantalla.

---

## Notas para Frontend

### Decisión crítica: FormBuilder wrapper (D-14)

El `FormBuilder(key: cubit.formKey, initialValue: ...)` **DEBE** vivir como ancestro del `IndexedStack`, no dentro de `EventFormStep1`. Si vive en un solo step, `validateStep()` retorna null en los otros steps porque `formKey.currentState` es null.

Estructura en `EventFormView` (modo creación):
```
Scaffold
  appBar: AppFormNavHeader(bottom: EventStepIndicator(...))
  body: FormBuilder(
    key: cubit.formKey,
    initialValue: _getInitialValues(cubit),
    child: AnimatedSwitcher(
      key: ValueKey(state.currentStep),
      child: IndexedStack(
        index: state.currentStep,
        children: [
          EventFormStep1(), EventFormStep2(),
          EventFormStep3(), EventFormStep4Review(),
        ],
      ),
    ),
  )
```

La lógica `_getInitialValues()` migra de `EventFormContent` a `EventFormView`.

### EventStepNavBar: gate de validación

Pasos 1-3 → "Continuar" llama `cubit.validateStep(n)` antes de `cubit.nextStep()`. Si la validación falla, el campo muestra su error in-field y el step NO avanza. El botón "Atrás" se **oculta** en el paso 0 (no deshabilitado — directamente ausente del Row).

### Modo edición: branch

```dart
isEditing
  ? EventFormContent()  // scroll único original
  : /* IndexedStack wizard */
```
Agregar `// TODO(stepper-edit): implement wizard for edit mode` en el branch.

### IndexedStack y memoria

`IndexedStack` mantiene Mapbox (Step 3) y Quill (Step 1) vivos simultáneamente. Agregar comentario:
```dart
// NOTE: IndexedStack keeps MapboxMap + QuillEditor alive simultaneously.
// Memory profiling is deferred to Phase 3.
```

### Step 4 — sin Quill ni Mapbox

`EventFormStep4Review` muestra los valores del formulario como texto estático (strings). No renderiza el editor Quill ni el mapa Mapbox. Leer valores directamente del cubit state o del `formKey.currentState?.value`.

### Dificultad en Step 4 — llamas

Usar `Icons.local_fire_department` con `color: AppColors.primary` para llamas "on" y `color: AppColors.darkBorderPrimary` para llamas "off" (mismo patrón que `FlameSelector` existente). La cantidad de llamas = `difficulty.value` (1-5).

### Texto sobre acento naranja

En **todos** los lugares donde haya fondo `AppColors.primary` (`#f98c1f`):
- Texto/íconos → `AppColors.darkBgPrimary` (`#0D0D0F`) o `colorScheme.onPrimary`
- NUNCA `Colors.white`, NUNCA `AppColors.textOnDarkPrimary`
- Aplica a: círculo activo del indicador, círculo completado, knob del switch "on", label del AppButton

### CoverPickerSheet

Solo llama `context.read<FormImageCubit>().pickImageFromGallery()`. No pasa parámetro `city`. La limpieza de imagen usa `FormImageCubit.clearLocalImage()`.

### Código muerto a eliminar (orden)

Verificar `grep -r "<archivo>" lib/ --include="*.dart"` retorna vacío antes de cada eliminación:
1. `event_form_content.dart` — migrar `_getInitialValues` a `EventFormView` primero
2. `event_form_bottom_bar.dart`
3. `draft_link.dart`
4. `publish_button.dart`

---

## Archivos de mockup

Ubicados en `docs/exec-runs/event-form-stepper-p2/html-mockups/`:

| Archivo | Contenido |
|---------|-----------|
| `styles.css` | Design tokens y componentes base |
| `step1-basico.html` | Step 1: vacío, cover sheet, error validación |
| `step2-detalles.html` | Step 2: dificultad, tipo, marcas, participantes, precio |
| `step3-ruta.html` | Step 3: mapa vacío (PulsingMapDot), mapa con puntos + autocomplete |
| `step4-revision.html` | Step 4: review cards + botones; estado publicando |
| `step-indicator-states.html` | EventStepIndicator en los 4 estados con tokens |
| `components-ux.html` | B-3, B-4, B-5, S-2, S-5, S-3 — antes/después |

---

## Cambios UX Fix — 2026-06-11T23:12:48Z

Corrección de los 5 bloqueantes identificados por el UX Reviewer. Todos aplicados directamente en Pencil (rideglory.pen). Sin cambios en código Flutter.

### B-1 — Step 2 (EzQtb): contenido corregido

**Antes:** Frame mostraba "Descripción del evento" con card de generación IA ("Generar descripción con IA") y editor de descripción. Funcionalidad eliminada del alcance en PRD §3 AC #12.

**Después:** Frame renombrado a "Detalles del evento". Contenido reemplazado por:
1. Dificultad (FlameSelector — copiado de Step 1)
2. Tipo de Evento (chip grid — copiado de Step 1)
3. Marcas Permitidas (toggle multimarca + chips Honda/Yamaha/Kawasaki + "Agregar")
4. Cupo Máximo (movido desde Step 3 — ver B-5)
5. Precio por Persona (movido desde Step 3 — ver B-5)

Secciones eliminadas de Step 1 (AybHb): DIFICULTAD y TIPO DE EVENTO (movidas a Step 2). Step 1 queda: Portada + Información Básica + Fecha y Hora. Subtítulo de Step 1 actualizado a "Portada, nombre y fecha del evento".

Nodos Pencil afectados: `EzQtb` (scrollContent `QvzFE`), `AybHb` (scrollContent `VTUAO`).

### B-2 — Etiqueta "Desc" → "Detalles" en todos los frames

| Frame | Nodo texto | Antes | Después |
|-------|-----------|-------|---------|
| EzQtb (Step 2) | `Oao0d` | `Desc` | `Detalles` |
| AybHb (Step 1) | `q4dka` | `Desc` | `Detalles` |
| XbcHD (Step 3) | `mWdf9` | `Desc` | `Detalles` |
| FW3Hd (Step 4) | `duPsx` | `Desc` | `Detalles` |

### B-3 — backBtn 36×36 → 40×40 (AybHb + XbcHD)

| Frame | Nodo | Antes | Después |
|-------|------|-------|---------|
| AybHb (Step 1) | `MrrIM` | 36×36 / cornerRadius 18 | 40×40 / cornerRadius 20 |
| XbcHD (Step 3) | `wUxoT` | 36×36 / cornerRadius 18 | 40×40 / cornerRadius 20 |

Cumple AC #11 del PRD (40×40 px) y mejora WCAG 2.5.5.

### B-4 — Botón "Atrás" eliminado del NavBar de Step 1 (AybHb)

Nodo `asdb5` ("Atrás", opacity: 0.4) eliminado del NavBar `xmT0F`. El botón "Continuar" (`j8LBcS`) ya tenía `fill_container` y ocupa el ancho completo automáticamente al quedar solo en el Row.

Elimina ambigüedad Nielsen H5 y violación WCAG 1.4.1 (estado comunicado solo por opacidad/color).

### B-5 — CUPO MÁXIMO y PRECIO POR PERSONA movidos de Step 3 a Step 2

Nodos `Ie90s` (CUPO MÁXIMO) e `I8xfa4` (PRECIO POR PERSONA) movidos desde `xc03o` (scrollContent de XbcHD) a `QvzFE` (scrollContent de EzQtb), posiciones 3 y 4 (tras Dificultad, Tipo y Marcas; antes del NavBar).

Step 3 (XbcHD) queda con únicamente: PUNTOS DE RUTA + DISTANCIA ESTIMADA. Título actualizado a "Ruta del evento" / "Define los puntos de salida, intermedios y llegada".

Elimina violación Ley de Hick y rotura semántica del wizard.
