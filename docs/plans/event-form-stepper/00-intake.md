# 00 — Intake

**Slug:** `event-form-stepper`  
**Fecha:** 2026-06-09T00:05:42Z  
**Fuente:** `docs/improvements/event-form-paginated-refactor-brief.md`

---

## Fuente

Brief detallado en `docs/improvements/event-form-paginated-refactor-brief.md` (10 secciones).  
Branch objetivo: `feature/event-form-stepper` (desde `feature/ai-event-generation`).  
Nodos Pencil de referencia: `AybHb` (Step 1), `EzQtb` (Step 2), `XbcHD` (Step 3), `FW3Hd` (Step 4), `q9FSg` (Portada Picker).

---

## Objetivo

Refactorizar el formulario de creación/edición de eventos de un único scroll largo a un **wizard de 4 pasos (stepper)** con indicador de progreso, navegación Atrás/Continuar por paso, pantalla de revisión antes de publicar, y bottom sheet de selección de portada. De paso se elimina el campo Ciudad de la UI y se reubican las secciones existentes en sus pasos correspondientes.

---

## Alcance percibido

**Capa afectada:** Presentación exclusivamente (un posible impacto menor en dominio/datos por la eliminación del campo `city`).

**Nuevos widgets (directorio `widgets/steps/`):**
- `EventStepIndicator` — fila de progreso con 4 pasos (activo/completado/futuro)
- `EventStepNavBar` — pills Atrás / Continuar (Step 1–3); Step 4 tiene sus propios CTAs
- `CoverPickerSheet` — bottom sheet con opciones "Galería" / "Generar con IA" / "Cancelar"
- `EventFormStep1` — Portada + Información básica + Fecha y Hora
- `EventFormStep2` — Dificultad + Tipo + Cupo + Precio + Marcas Permitidas
- `EventFormStep3` — Puntos de ruta + Distancia calculada
- `EventFormStep4Review` — Cards de resumen de los 3 pasos + CTAs Publicar / Guardar borrador

**Widgets modificados:**
- `EventFormView` — nuevo AppBar (sin botón Publicar) + `PageView`/`IndexedStack` en el body
- `EventFormBasicInfoSection` — eliminar `AppCityAutocomplete` (Ciudad)
- `EventFormCubit` — agregar `currentStep`; actualizar `buildEventToSave()` para omitir `city`; ajustar `generateCover()` sin `city`

**Widgets eliminados:**
- `EventFormContent` (reemplazado por steps individuales)
- `EventFormBottomBar` (reemplazado por `EventStepNavBar`)
- `CoverPlaceholderView` (reemplazado por área tap de portada en Step 1)

**Strings ARB:** Labels del indicador de pasos (Básico · Config · Ruta · Revisar) y textos del Step 4.

**Tests a actualizar:** Cubit tests que usen `city` en `buildEventToSave()`; tests de widgets afectados.

**Backend/API:** Sin cambios obligatorios si `city` se vacía silenciosamente. Cambio opcional si se decide eliminar `city` del modelo.

**Dependencia de secuencia:** El exec-run `app-ai-description-assistant` debe completarse y commitearse antes de iniciar este refactor (comparten `event_form_basic_info_section.dart` y `event_form_content.dart`).

---

## Preguntas abiertas

1. **FormBuilder scope:** ¿Un `FormBuilder` global envolviendo el `PageView` (con `AutomaticKeepAliveClientMixin` / `IndexedStack` para mantener estado entre pasos) o un `FormBuilder` por paso? La experiencia "Atrás sin perder datos" favorece el global.

2. **Campo `city` en dominio:** ¿Se elimina de `EventModel` y del API (requiere migración de backend y coordinación con `rideglory-api`), o se envía vacío silenciosamente (`city: ''`)? Afecta `buildEventToSave()`, `_buildEventContext()` del asistente de IA y el parámetro `city` de `generateCover()`.

3. **Stepper en modo edición (`isEditing = true`):** El diseño solo muestra "Nuevo Evento". ¿Se aplica el mismo stepper en edición o se mantiene el scroll único hasta que se diseñe?

4. **Reglas de validación por paso:** ¿Qué campos bloquean "Continuar" en cada step? Step 1: Nombre y descripción parecen obligatorios. Step 2 y Step 3: ¿tienen campos required o todos tienen defaults?

5. **Guardar borrador en pasos intermedios:** ¿Solo desde Step 4, o disponible desde cualquier paso?

6. **`EventFormDetails` section:** `event_form_details_section.dart` existe pero no aparece referenciada en `event_form_content.dart`. ¿Está en uso activo o ya es código muerto que puede eliminarse?
