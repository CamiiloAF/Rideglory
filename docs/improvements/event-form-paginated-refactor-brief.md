# Brief — Refactor Formulario de Eventos: Paginado (Stepper)

**Fecha:** 2026-06-08  
**Branch objetivo:** `feature/event-form-stepper` (desde `feature/ai-event-generation`)  
**Nodos Pencil:** `AybHb` (Step 1), `EzQtb` (Step 2), `XbcHD` (Step 3), `FW3Hd` (Step 4), `q9FSg` (Portada Picker)

---

## 1. Qué cambia (resumen ejecutivo)

El formulario de creación/edición de eventos pasa de **un solo scroll largo** a **un wizard de 4 pasos** con navegación Atrás/Continuar por paso, un indicador de progreso en la cabecera, y una pantalla de revisión antes de publicar. Además se elimina el campo **Ciudad** y la sección de **Marcas Permitidas** de la UI de creación.

---

## 2. Diseño de referencia (Pencil)

| Nodo | Nombre | Contenido |
|------|--------|-----------|
| `AybHb` | Step 1 — Información básica | Portada (tap → sheet) · Nombre + Descripción + botón IA · Fecha y Hora |
| `EzQtb` | Step 2 — Configuración del evento | Dificultad · Tipo de Evento · Cupo Máximo · Precio por persona |
| `XbcHD` | Step 3 — Ruta del evento | Puntos de ruta (Salida / Intermedio / Llegada) · Distancia calculada |
| `FW3Hd` | Step 4 — Revisa tu evento | Cards de resumen de los 3 pasos anteriores · Publicar Evento · Guardar borrador |
| `q9FSg` | Portada Picker (bottom sheet) | Galería · Generar con IA |

---

## 3. Anatomía de cada pantalla

### 3.1 Cabecera compartida (todos los pasos)
- **AppBar:** botón Atrás (← en círculo bg-secondary 36 px) + título "Nuevo Evento" centrado + spacer vacío. **No hay botón "Publicar" en la cabecera** — desaparece del `AppFormNavHeader`.
- **Step indicator:** fila horizontal con 4 columnas separadas por conectores. Etiquetas: Básico · Config · Ruta · Revisar. Paso activo: círculo con número naranja; pasos completados: check; pasos futuros: círculo gris.

### 3.2 Step 1 — Información básica
- Sección PORTADA: área de tap (ícono + texto "Agregar portada") que abre `q9FSg` (bottom sheet). Cuando hay portada seleccionada/generada → mostrar preview con opción de cambiar.
- Sección INFORMACIÓN BÁSICA: card con `stroke: $accent` / `strokeWidth: 1.5` conteniendo campo Nombre + editor Descripción (con botón IA). Debajo del card: botón "Generar descripción con IA" (bg-secondary + border accent).
- Sección FECHA Y HORA: toggle multiday + picker(s), igual al actual `EventFormDateTimeSection`.
- **Ciudad eliminada** de este paso (no aparece en ningún paso).

### 3.3 Step 2 — Configuración del evento
- Sección DIFICULTAD: `EventFormDifficultySection` (Flame Selector).
- Sección TIPO DE EVENTO: `EventFormEventTypeSection` (chips).
- Sección CUPO MÁXIMO: `EventFormMaxParticipantsSection`.
- Sección PRECIO POR PERSONA: `EventFormPriceSection`.
- Sección MARCAS PERMITIDAS: `EventFormMultiBrandSection` — card con toggle "Multimarca" + chips de marcas cuando está desactivado.

### 3.4 Step 3 — Ruta del evento
- Sección PUNTOS DE RUTA: `EventFormLocationsSection` (Salida · Punto intermedio · Llegada).
- Sección DISTANCIA: label calculado al completar los puntos ("Distancia se calculará al completar la ruta").
- No incluye el selector de tipo de ruta visible por separado — se mantiene la lógica interna.

### 3.5 Step 4 — Revisa tu evento
- Pantalla de revisión de solo lectura con 4 cards agrupadas:
  - `card_Información básica`: Nombre · Descripción · Portada
  - `card_Configuración`: Dificultad · Tipo · Cupo · Precio
  - `card_Ruta`: Tipo · Salida · Llegada · Distancia
  - `card_Fecha y hora`: Fecha · Hora inicio · Varios días
- CTA bar: **Publicar Evento** (pill accent, alto 52 px) + **Guardar borrador** (pill bg-tertiary, alto 44 px).

### 3.6 Portada Picker (bottom sheet — `q9FSg`)
- `DraggableScrollableSheet` o `showModalBottomSheet` con `cornerRadius: [24,24,0,0]`.
- Opción 1: "Subir desde galería" — ícono en `bg-secondary`.
- Opción 2: "Generar con IA" — ícono en `accent-subtle` con glow naranja.
- Botón "Cancelar" al fondo.
- Reemplaza el comportamiento actual de `FormImageSection` (inline) y el botón separado "Generar con IA".

### 3.7 Nav bar (Steps 1–3)
- Dos pills lado a lado: **Atrás** (`bg-tertiary`, 52 px) + **Continuar** (`$accent`, 52 px).
- En Step 1, "Atrás" tiene `opacity: 0.4` (deshabilitado) y no regresa.
- "Continuar" valida solo los campos del paso actual antes de avanzar.
- En Step 4 el nav bar se reemplaza por los CTAs Publicar/Borrador.

---

## 4. Eliminaciones confirmadas

| Elemento | Archivo actual | Motivo |
|----------|---------------|--------|
| Campo Ciudad (`AppCityAutocomplete`) | `event_form_basic_info_section.dart` | No aparece en ningún paso del diseño |
| Botón "Publicar" en AppBar | `event_form_view.dart` | Acción movida a Step 4 |
| `EventFormBottomBar` | `event_form_bottom_bar.dart` | Reemplazado por nav bar por pasos |
| Scroll único (`SingleChildScrollView`) | `event_form_content.dart` | Reemplazado por PageView/AnimatedSwitcher |

---

## 5. Archivos más afectados

```
lib/features/events/presentation/form/
├── event_form_page.dart              → sin cambios estructurales
├── cubit/
│   └── event_form_cubit.dart         → agregar currentStep; actualizar buildEventToSave()
│                                       (eliminar city; manejar allowedBrands con default vacío)
├── widgets/
│   ├── event_form_view.dart          → reemplazar AppBar + body (PageView)
│   ├── event_form_content.dart       → REEMPLAZADO por widgets de pasos individuales
│   ├── event_form_bottom_bar.dart    → ELIMINADO (o repropuesto como StepNavBar)
│   ├── cover_placeholder_view.dart   → ELIMINADO (reemplazado por portada tap area)
│   ├── cover_preview_widget.dart     → CONSERVADO (se usa en Step 1 cuando hay portada)
│   └── sections/
│       ├── event_form_basic_info_section.dart → adaptar: quitar Ciudad
│       ├── event_form_multi_brand_section.dart → ELIMINADO de la UI
│       └── (resto de secciones) → CONSERVADOS, reubicados en sus steps
└── widgets/steps/                    (nuevo directorio)
    ├── event_form_step1.dart
    ├── event_form_step2.dart
    ├── event_form_step3.dart
    ├── event_form_step4_review.dart
    ├── event_step_indicator.dart
    ├── event_step_nav_bar.dart
    └── cover_picker_sheet.dart
```

---

## 6. Impacto en dominio / datos

### EventModel.city
- El campo `city` existe hoy en `EventModel` y se popula desde el formulario.
- Con la eliminación del campo, el cubit debe enviar `city: ''` o `city: null` al guardar.
- **Decisión a tomar:** ¿se elimina `city` del modelo y del backend, o se deriva de los puntos de ruta (meetingPoint)? Esta decisión afecta el contrato de API — deberá coordinarse con `rideglory-api`.
- **Impacto en IA:** `_buildEventContext()` usa `EventFormFields.city` para el asistente de descripción. Si se elimina, ese campo se omite del contexto (pasa como `city: ''`).
- **Impacto en `generateCover()`:** el método del cubit tiene parámetro `city`; deberá ajustarse o el valor será vacío.

### EventModel.allowedBrands
- La sección de Marcas Permitidas se conserva en Step 2. Sin cambios en modelo ni backend.

---

## 7. Conflicto con exec-run activo

El exec-run **`app-ai-description-assistant`** está actualmente en curso y modifica los siguientes archivos que también serán afectados por este refactor:

| Archivo | Qué hace el exec-run | Qué hace el refactor |
|---------|---------------------|---------------------|
| `event_form_basic_info_section.dart` | Convierte a `StatefulWidget`, agrega `QuillController` externo, `_buildEventContext()` (usa `city`), abre `AiDescriptionChatSheet` | Elimina `AppCityAutocomplete`; el resto del AI chat se conserva |
| `event_form_content.dart` | Elimina callback `onAiSuggest` de `EventFormContent` | `EventFormContent` desaparece (reemplazado por steps) |
| `app_rich_text_editor.dart` | Agrega `externalController` param | Sin impacto (widget compartido, cambio retrocompatible) |

**Recomendación de secuencia:**
1. Completar y commitear `app-ai-description-assistant` primero.
2. Iniciar este refactor desde ese commit como base.
3. En `event_form_step1.dart` reutilizar directamente `EventFormBasicInfoSection` (ya con el AI chat integrado) sin `AppCityAutocomplete`.

---

## 8. Preguntas abiertas para el Architect

1. **FormBuilder scope:** ¿Un `FormBuilder` global que envuelve el `PageView` (todos los campos en un único estado de formulario) o un `FormBuilder` por paso? El diseño implica navegación Atrás sin perder datos — esto favorece el `FormBuilder` global con `PageView` donde el widget del formulario persiste en memoria.

2. **`city` en el modelo:** ¿Se elimina del `EventModel` y del API, o se vacía silenciosamente? Si se vacía, quedan registros con `city: ''` en la base de datos. Si se elimina del modelo necesita migración de backend.

3. **Marcas Permitidas:** Se conserva en Step 2 — confirmado por diseño actualizado.

4. **Edición vs. Creación:** El stepper aplica a creación. En edición (`isEditing = true`), ¿también se usa el stepper de 4 pasos, o se mantiene el scroll único? El diseño solo muestra "Nuevo Evento" — la edición no está diseñada.

5. **Validación por paso:** ¿Qué campos son required en cada paso para poder avanzar? Step 1: Nombre + Descripción (obligatorios hoy). Step 2: ¿Dificultad y tipo son required o tienen defaults? Step 3: ¿Al menos un punto de ruta es required?

6. **Draft en pasos intermedios:** ¿Se puede guardar borrador desde cualquier paso o solo desde Step 4?

---

## 9. Riesgos y puntos de atención

- **FormBuilder key global vs. por paso:** si se usa un único `formKey`, el `PageView` debe mantener los widgets vivos (usar `AutomaticKeepAliveClientMixin` o `IndexedStack`) para que los campos no se destruyan al cambiar de página.
- **Animación de pasos:** la transición entre pasos debe ser suave (deslizamiento horizontal). `PageController` con `animateToPage` es la opción natural.
- **`buildEventToSave()` sin `city`:** actualmente hace `formData[EventFormFields.city] as String` — sin el campo esto lanzará `null` cast. Debe actualizarse antes de que el refactor esté completo.
- **Tests afectados:** los tests del cubit que mockean el formulario con `city` deberán actualizarse.
- **`EventFormDetails`:** la sección `event_form_details_section.dart` existe pero no se ve referenciada en `event_form_content.dart`. Verificar si está en uso antes de decidir.

---

## 10. Alcance sugerido para la planificación

Este refactor es **puramente de presentación** (no requiere cambios de backend excepto la decisión sobre `city`). El scope natural es una sola fase de ejecución:

**Fase única:** Refactor UI del formulario de eventos a stepper de 4 pasos.

Bloques de trabajo internos:
1. Nuevo `EventStepIndicator` widget
2. Nuevo `EventStepNavBar` widget (Atrás/Continuar)
3. `CoverPickerSheet` (reemplaza `FormImageSection` inline)
4. `EventFormStep1` (reutiliza secciones existentes, sin Ciudad)
5. `EventFormStep2` (reutiliza secciones existentes, sin Marcas)
6. `EventFormStep3` (reutiliza `EventFormLocationsSection`)
7. `EventFormStep4Review` (nuevo — cards de resumen + CTAs)
8. `EventFormView` actualizado (nuevo AppBar + PageView/IndexedStack)
9. `EventFormCubit` actualizado (`currentStep`, `buildEventToSave()` sin `city`)
10. Limpieza: eliminar `EventFormContent`, `EventFormBottomBar`, `CoverPlaceholderView`
11. Strings ARB para labels del stepper y Step 4
12. Tests actualizados (`buildEventToSave`, cubit con pasos)
