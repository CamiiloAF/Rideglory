# 02 — PO Proposal

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T00:10:35Z
**Autor:** Product Owner

---

## Contexto

El formulario de creación de eventos es hoy un único scroll largo. El organizador debe recorrerlo completo antes de poder publicar, sin guía de progreso ni agrupación temática. Este plan convierte ese formulario en un **wizard de 4 pasos** con indicador de progreso, navegación Atrás/Continuar, y pantalla de revisión antes de publicar.

**Prerrequisito duro (acción humana, no agente):** El exec-run `app-ai-description-assistant` debe estar revisado y commitado antes de iniciar la Fase 1. Los archivos `event_form_basic_info_section.dart`, `event_form_content.dart` y `app_rich_text_editor.dart` de ese exec-run son la base de este refactor.

---

## Fases propuestas

| # | Título | Meta de valor (organizador) | Alcance clave |
|---|--------|-----------------------------|---------------|
| 1 | Fundación técnica | El cubit maneja pasos y `city` no bloquea el guardado | `currentStep` en `EventFormState`; `city: ''` en `buildEventToSave()` / `buildDraftToSave()`; `generateCover()` sin `city` hardcoded; ARB strings del stepper; eliminación de `EventFormDetailsSection` (código muerto) |
| 2 | Wizard completo | El organizador crea eventos con el wizard de 4 pasos y puede publicar o guardar borrador desde la pantalla de revisión | Todos los widgets en `widgets/steps/` (`EventStepIndicator`, `EventStepNavBar`, `CoverPickerSheet`, `EventFormStep1`–`Step4Review`); `EventFormView` refactorizado (nuevo AppBar + `IndexedStack`); `EventFormBasicInfoSection` sin `AppCityAutocomplete`; eliminación de `EventFormContent` y `EventFormBottomBar` |
| 3 | Cobertura y cierre | El flujo pasa `dart analyze` limpio y los tests cubren el cubit con pasos | Tests actualizados (cubit `city`, `buildEventToSave()`, `event_form_basic_info_section_test.dart`); `dart analyze` sin errores; documentación de decisiones de edge cases (modo edición, validación por paso) |

---

## Supuestos

1. **Prerequisito commitado:** El exec-run `app-ai-description-assistant` está revisado y mergeado antes del inicio de la Fase 1. Si no lo está, el implementador arranca de una base incorrecta.

2. **Estrategia `city`:** Se envía `city: ''` en `buildEventToSave()` y `buildDraftToSave()`. El endpoint `POST /events` acepta `city: ''` (campo `@IsString()` sin `@IsNotEmpty()`). Para `generateCover()`, se pasa el texto del `meetingPoint` como proxy de ciudad (o se hace `city` opcional en `GenerateCoverDto` con un cambio mínimo de backend previo a la Fase 2).

3. **`IndexedStack` como mecanismo de pasos:** El `FormBuilder` global envuelve un `IndexedStack` con los 4 steps. Los widgets permanecen vivos en el árbol entre navegaciones — no se necesita `AutomaticKeepAliveClientMixin`.

4. **Solo creación usa el wizard:** El modo edición (`isEditing = true`) conserva el scroll único hasta que se diseñe un flujo de edición con stepper. El stepper de este plan aplica exclusivamente a `isEditing = false`.

5. **`CoverPlaceholderView` no se elimina:** El archivo se conserva porque `CoverPreviewWidget` lo referencia como fallback/error widget. Lo que cambia es que deja de ser el estado inicial visible en el formulario (reemplazado por el área de tap de portada en Step 1).

6. **Guardar borrador solo desde Step 4:** El CTA "Guardar borrador" aparece únicamente en la pantalla de revisión, no en pasos intermedios.

7. **Validación por paso:** Step 1 requiere al menos el campo Nombre para habilitar "Continuar". Steps 2 y 3 tienen valores por defecto válidos y permiten continuar sin selección explícita. Step 4 habilita "Publicar" si el formulario completo es válido.

8. **Sin cambios de backend obligatorios:** Salvo la decisión de `GenerateCoverDto.city` (ver Riesgos), toda la implementación es presentación pura.

---

## Riesgos

1. **`GenerateCoverDto.city` tiene `@IsNotEmpty()`:** Enviar `city: ''` al endpoint `POST /events/generate-cover` retorna HTTP 400. Si no se resuelve antes de la Fase 2 (ajuste backend o proxy meetingPoint), el botón "Generar con IA" quedará roto en el nuevo Step 1. Mitigación: decidir y ejecutar el fix en Fase 1 o antes.

2. **`IndexedStack` y memoria:** Mantener todos los widgets del formulario vivos simultáneamente (Quill editor, autocompletados de ubicación, mapa de ruta) puede incrementar el uso de memoria en dispositivos de gama baja. Mitigación: perfilar en Fase 3 y usar `keepAlive` selectivo si es necesario.

3. **Exec-run no commitado como base:** Si el humano no commitea `app-ai-description-assistant` antes de la Fase 1, el implementador encuentra `EventFormBasicInfoSection` sin el AI chat integrado. Resultado: doble trabajo o conflictos de merge. Mitigación: bloquear la ejecución de la Fase 1 hasta confirmar el prerequisito.

4. **Validación de campos por paso con `formKey` global:** Identificar qué `FormBuilder` field names pertenecen a cada paso requiere mantener una lista explícita sincronizada con los `EventFormFields` del cubit. Si cambia un field name, la validación por paso puede sillar pasos incorrectamente. Mitigación: centralizar la lista en el cubit (no en los widgets de paso).

5. **Modo edición sin diseño:** El stepper no aplica a edición. Si un usuario edita un evento verá el scroll antiguo mientras que al crear ve el wizard — inconsistencia UX temporal hasta que se diseñe y ejecute el stepper de edición. Mitigación: documentar en `EventFormView` como tech debt explícito.

6. **Animación entre pasos:** `IndexedStack` no anima las transiciones. Para lograr deslizamiento suave se necesita `AnimatedSwitcher` o similar sobre el stack. Sin esto la experiencia es abrupta. Mitigación: incluir en Fase 2 como parte de los criterios de aceptación del `EventFormView`.

---

## Criterios de éxito globales

- El organizador puede crear un evento completo navegando 4 pasos secuenciales sin recargar ni perder datos al retroceder.
- El indicador de progreso refleja el paso actual y los completados en tiempo real.
- El campo "Ciudad" no aparece en ningún paso del formulario.
- La portada se puede subir desde galería o generar con IA desde un bottom sheet en Step 1.
- La pantalla de revisión (Step 4) muestra un resumen de los 3 pasos anteriores antes de publicar.
- `dart analyze` pasa sin errores en la rama `feature/event-form-stepper`.
- Todos los tests de cubit y widget afectados por el refactor están actualizados y pasan.
- El modo edición (`isEditing = true`) sigue funcionando con el flujo anterior (no regresión).
