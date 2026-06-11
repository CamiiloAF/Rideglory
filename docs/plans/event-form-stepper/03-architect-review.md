# 03 — Architect Review

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T00:13:00Z
**Autor:** Architect

---

## Validación por fase

### Fase 1 — Fundación técnica

**Complejidad: BAJA**

**Viabilidad:** VIABLE sin cambios estructurales al stack. Todo el trabajo es mecánico: campo freezed + codegen, dos asignaciones de `city: ''` en el cubit, decisión de proxy para `generateCover()`, strings ARB y borrado de código muerto.

**Desglose técnico:**

| Tarea | Archivo(s) | Notas |
|-------|-----------|-------|
| Añadir `currentStep: int` a `EventFormState` | `event_form_cubit.dart` (parte freezed) | Requiere `dart run build_runner build` para regenerar `event_form_cubit.freezed.dart`. Cambio mínimo: `@Default(0) int currentStep` en el factory. |
| Fijar `city: ''` en `buildEventToSave()` | `event_form_cubit.dart` línea 374 | `CreateEventDto` acepta string vacío (`@IsString()` sin `@IsNotEmpty()`). Sin impacto en backend. |
| Fijar `city: ''` en `buildDraftToSave()` | `event_form_cubit.dart` línea 447 | Ídem. |
| Resolver `generateCover()` sin `city` | `event_form_cubit.dart` + `generate-cover.dto.ts` | **Ver sección de Contratos.** Requiere un toque mínimo de backend. |
| ARB strings stepper | `lib/l10n/app_es.arb` + generadas | Keys nuevas: `event_step_info`, `event_step_details`, `event_step_route`, `event_step_review`, `event_step_continue`, `event_step_back`, `event_step_of` (ej. "Paso 2 de 4"). Sin conflicto con keys existentes. |
| Eliminar `EventFormDetailsSection` | `lib/…/sections/event_form_details_section.dart` + `sections/details/` | Código muerto confirmado: cero importaciones en `lib/`. Borrado seguro. |

**Prerequisito bloqueante verificado:** `EventFormBasicInfoSection` actual (committed) aún contiene `AppCityAutocomplete` en línea 166. El exec-run `app-ai-description-assistant` lo convirtió a `StatefulWidget` con Quill + AI chat, pero esos archivos están `??` (untracked) y `M` (modified) en git status. La Fase 1 debe asumir que el humano **commitea ese exec-run primero**. Si no, el implementador trabajaría sobre la versión sin QuillController y tendría que volver a integrar el AI chat.

---

### Fase 2 — Wizard completo

**Complejidad: MEDIA**

**Viabilidad:** VIABLE. El patrón `FormBuilder` global + `IndexedStack` es la elección correcta para este codebase. Sin dependencias nuevas. El mayor riesgo de implementación es la validación por paso y la coordinación de la portada con `FormImageCubit`.

**Desglose técnico:**

| Componente | Decisión arquitectónica |
|-----------|------------------------|
| `FormBuilder` scope | El widget `FormBuilder(key: cubit.formKey)` envuelve el `IndexedStack` completo en `EventFormView`. Todos los fields de los 4 pasos viven bajo la misma key. Estado del formulario no se destruye al cambiar de paso. |
| Validación por paso | **El cubit expone `bool validateStep(int step)`** que itera sobre `_stepFields[step]` llamando `formKey.currentState?.fields[name]?.validate()` por campo. El mapa `_stepFields` vive como `static const Map<int, List<String>>` dentro de `EventFormCubit`, no en los widgets. Si un field name cambia en `EventFormFields`, el compilador no falla — es una trampa de mantenimiento. Mitigación: comentario explícito vinculando el mapa a `EventFormFields`. |
| Paso de portada | `CoverPickerSheet` lee `FormImageCubit` via `context.read`. No es un form field — vive en estado separado. No requiere cambios al patrón existente. |
| `EventFormView` refactorizado | Nuevo AppBar: sin botón "Publicar" en `trailing`. El trailing es `null` en pasos 1–3; en Step 4 review aparece el botón "Publicar" (o se conserva como leading del `EventStepNavBar`). `EventFormBottomBar` se elimina. |
| `EventFormBasicInfoSection` — `AppCityAutocomplete` | Se elimina el campo. **Pero `_buildEventContext()` en esa misma clase aún lee `formValues[EventFormFields.city]`** (línea 71 del archivo actual exec-run). Este método debe cambiarse para obtener la ciudad del proxy (ver Contratos). |
| `IndexedStack` memoria | Todos los widgets viven simultáneamente. `CustomRouteBuilderSection` (Mapbox + waypoints) es el más pesado. Mitigación: el mapa de Mapbox se inicializa solo cuando el usuario llega al Step 3. No bloquea la Fase 2 — perfilar en Fase 3. |
| Modo edición | `isEditing = true` → flujo de scroll anterior. La condición vive en `EventFormView` con un `if/else` sobre `isEditing`. Documentar como tech debt explícito con comentario `// TODO(stepper-edit): implementar wizard para modo edición`. |
| Animación de transición | `AnimatedSwitcher` con `FadeTransition` sobre el `IndexedStack`. Sin librería adicional. Duración: 150ms. |

**Regla de un widget por archivo** se aplica a los 7 nuevos widgets de `widgets/steps/`. Cada archivo tiene exactamente una clase StatelessWidget/StatefulWidget. Las clases `State<T>` coexisten con su `StatefulWidget` en el mismo archivo (regla permitida).

**Archivos a crear en `widgets/steps/`:**
- `event_step_indicator.dart` — indicador de progreso (4 dots/pills)
- `event_step_nav_bar.dart` — barra Atrás/Continuar
- `cover_picker_sheet.dart` — bottom sheet para portada (galería + IA)
- `event_form_step1.dart` — nombre + descripción + portada
- `event_form_step2.dart` — dificultad + tipo + participantes + precio + marcas
- `event_form_step3.dart` — ruta + ubicaciones
- `event_form_step4_review.dart` — resumen + botones Publicar / Guardar borrador

**Archivos a eliminar:**
- `event_form_content.dart`
- `event_form_bottom_bar.dart`
- `draft_link.dart` (movido a Step 4 review — verificar que no hay otras importaciones)

**Archivos a NO eliminar:**
- `cover_placeholder_view.dart` — sigue referenciado en `CoverPreviewWidget` como fallback/error widget. Solo deja de ser el estado inicial visible. El brief original decía "eliminar" pero esto es incorrecto — se conserva el archivo.

---

### Fase 3 — Cobertura y cierre

**Complejidad: BAJA**

**Viabilidad:** VIABLE. Actualizaciones mecánicas de tests + `dart analyze`.

**Desglose técnico:**

| Archivo de test | Cambio requerido |
|----------------|-----------------|
| `event_form_cubit_analytics_test.dart` línea 39 | `city: 'Medellín'` → `city: ''` |
| `event_form_basic_info_section_test.dart` | Cabecera de test (línea 6), matcher (línea 85), nombre del test (línea 147), assertion (línea 220): el test AC18 verificaba que `_buildEventContext().city == EventFormFields.city value`. Tras remover el campo city, el test debe actualizarse para verificar que `city == ''` (o que usa el proxy meetingPoint). |
| Tests de wizard nuevos | Crear tests para `EventFormCubit.validateStep()` (valida que Step 1 falla sin nombre, pasa con nombre). Un test de widget para `EventFormStep4Review` verificando que el botón Publicar está deshabilitado si el formulario no es válido. |

`dart analyze` bloqueante conocido: si `AppCityAutocomplete` se elimina de `EventFormBasicInfoSection` pero `EventFormFields.city` aún se referencia en `_buildEventContext()`, hay un acceso a un key inexistente en el formulario — no rompe en análisis estático pero sí es un bug de runtime. Fase 3 debe incluir la verificación explícita de que no quedan referencias a `EventFormFields.city` en la capa de presentación.

---

## Contratos

### Cambio de backend requerido — `GenerateCoverDto.city` (Fase 1)

Este es el único cambio de backend en todo el plan. Es bloqueante para el correcto funcionamiento de "Generar con IA" en Step 1.

**Situación actual:**
```typescript
// api-gateway/src/events/dto/generate-cover.dto.ts
@IsString()
@IsNotEmpty()
city: string;
```

Enviar `city: ''` retorna HTTP 400. El Flutter actual pasa `city` desde el campo `AppCityAutocomplete`. Al eliminar ese campo, no hay ciudad disponible al momento en que el usuario activa "Generar portada" en Step 1 (antes de llegar a Step 3 con el meetingPoint).

**Decisión arquitectónica — ADR-generate-cover-city:**
Hacer `city` opcional en `GenerateCoverDto`. El servicio backend ya genera la portada con Gemini usando `title` y `eventType` como contexto principal — `city` es contexto secundario de calidad.

**Cambio en backend (`api-gateway/src/events/dto/generate-cover.dto.ts`):**
```typescript
@IsOptional()
@IsString()
city?: string;
```

**Cambio en Flutter (`EventFormCubit.generateCover()`):**
```dart
Future<void> generateCover({
  required String title,
  required String eventType,
  String? city,  // <- opcional
}) async { ... }
```

El parámetro `city` se pasa como `state.meetingPointName` si está disponible, `null` en caso contrario. No se fuerza un string vacío porque el backend recibiría un campo con valor semántico vacío.

**`_buildEventContext()` en `EventFormBasicInfoSection`:**
El método actual lee `formValues[EventFormFields.city]`. Al eliminar el campo, devuelve `null → ''`. Para el AI de descripción, usar `context.read<EventFormCubit>().state.meetingPointName ?? ''` como proxy de ciudad. Esto es aceptable en la capa de presentación (el widget ya tiene acceso al cubit por BLoC).

**No hay migración de datos, no hay contrato en `rideglory-contracts` para `GenerateCoverDto`** (vive solo en `api-gateway/src/events/dto/`). El cambio no requiere `npm run build` en los microservicios.

### Contratos sin cambios

| Endpoint | Impacto |
|---------|---------|
| `POST /events` (`CreateEventDto`) | `city: ''` es aceptado. Sin cambio en contrato. |
| `PATCH /events/:id` (`UpdateEventDto`) | Ídem. |
| `GET /events`, `GET /events/:id`, `PATCH /events/:id/publish` | Sin impacto. |
| WebSocket tracking | Sin impacto. |

### Code generation

Un solo paso de codegen requerido: añadir `currentStep` a `EventFormState` (freezed) obliga a correr `dart run build_runner build --delete-conflicting-outputs`. Los archivos del exec-run `app-ai-description-assistant` ya tienen sus propios `.freezed.dart` y `.g.dart` generados (están en los archivos `??` del git status). El implementador debe confirmar que esos archivos están presentes y actualizados antes de iniciar Fase 1.

---

## Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **Exec-run no commitado** — Fase 1 arranca sobre base incorrecta si el humano no commitea `app-ai-description-assistant` primero. Resultado: `EventFormBasicInfoSection` sin QuillController ni AI chat. Doble trabajo o conflictos. | ALTA | Bloqueante explícito: el implementador verifica `git status` al iniciar Fase 1. Si hay archivos `??` en `lib/features/events/`, detiene la ejecución y reporta al humano. |
| R2 | **`generateCover()` roto sin city** — Si la decisión de backend se demora, el botón "Generar con IA" en Step 1 falla con HTTP 400 cuando el usuario no ha completado el meetingPoint. | ALTA | Resolver en Fase 1: hacer `city` opcional en `GenerateCoverDto`. Es un cambio de 2 líneas en backend. |
| R3 | **Step-field mapping drift** — La lista `_stepFields` en el cubit se desincroniza con los field names reales si un refactor futuro cambia `EventFormFields`. No hay error en compilación. | MEDIA | Centralizar el mapa en el cubit (no en widgets). Añadir comentario explícito en `_stepFields` vinculando cada entry a la sección correspondiente. Cubrir con test unitario de `validateStep()`. |
| R4 | **`IndexedStack` y Mapbox en memoria** — `CustomRouteBuilderSection` (Mapbox map + waypoint autocompletado) permanece vivo en memoria desde que se monta el formulario. En dispositivos con ≤3 GB de RAM puede causar presión de memoria. | MEDIA | Lazy-init del mapa (solo inicializar `MapboxMap` cuando `currentStep == 2`). Perfilar en Fase 3 con `flutter run --profile`. |
| R5 | **`_buildEventContext().city` vacío degrada contexto AI** — El asistente de descripción recibe `city: ''` y genera sugerencias sin referencia geográfica. | BAJA | Aceptado como deuda de calidad v1. Usar proxy `meetingPointName` si está disponible. No bloquea el flujo. |
| R6 | **`draft_link.dart` y otras importaciones** — Al eliminar `EventFormBottomBar`, se debe verificar que `draft_link.dart` no es importado en otros lugares antes de eliminar. | BAJA | `grep -r "draft_link" lib/` antes de eliminar. Si hay importaciones externas, conservar el archivo y dejar solo el import dentro del nuevo Step 4. |
| R7 | **`AppCityAutocomplete` en `AiDescriptionRequest`** — El test `event_form_basic_info_section_test.dart` AC18 verifica `city == EventFormFields.city value`. Al eliminar el field, el test falla hasta que se actualice el assertion. | BAJA | Actualizar en Fase 3. No bloquea Fases 1–2 porque el test de widget puede ser skipped temporalmente con `// TODO(stepper)`. |

---

## Ajustes

Los siguientes ajustes son requeridos para que el plan sea ejecutable con mínimo riesgo:

### A1 — Backend touch en Fase 1 (REQUERIDO)

La propuesta original dice "sin cambios de backend obligatorios" y menciona el fix de `GenerateCoverDto.city` como alternativa a usar proxy. Ambas opciones se dejan abiertas. El ajuste: **declarar explícitamente que hacer `city` opcional en `GenerateCoverDto` ES parte del alcance de Fase 1**, no opcional. Es la solución limpia y bloquea solo 2 líneas de TypeScript. La alternativa de proxy (`meetingPointName`) falla silenciosamente si el usuario genera portada antes de completar el meetingPoint (Step 3), lo cual es el caso de uso normal en Step 1.

El `generateCover()` de Flutter debe recibir `city` como parámetro `String?` opcional y solo pasarlo al use case si es non-null y non-empty.

### A2 — Step-field mapping centralizado en cubit (REQUERIDO)

La propuesta no especifica dónde vive la lógica de "qué fields pertenecen a cada paso". Ajuste: el cubit expone `static const Map<int, List<String>> stepFields = { 0: [...], 1: [...], 2: [...] }` y un método `bool validateStep(int step)`. Este método es testeable unitariamente. Los widgets de paso NO replican esta lógica.

### A3 — `_buildEventContext()` actualización explícita (REQUERIDO en Fase 2)

La Fase 2 elimina `AppCityAutocomplete` de `EventFormBasicInfoSection`. El scope actual no menciona que `_buildEventContext()` en la misma clase también debe cambiar su fuente de `city`. Ajuste: al eliminar el field en Fase 2, actualizar `_buildEventContext()` para usar `context.read<EventFormCubit>().state.meetingPointName ?? ''` en lugar de `formValues[EventFormFields.city]`.

### A4 — Verificación de prerequisito como primer paso de Fase 1 (REQUERIDO)

La Fase 1 debe comenzar con un paso explícito: verificar que los archivos del exec-run `app-ai-description-assistant` están commitados (correr `git status` y confirmar que no hay `??` en `lib/features/events/`). Si el prerequisito no se cumple, la fase se detiene con un mensaje claro al humano.

### A5 — Alcance del `EventStepNavBar` en Step 4 (AJUSTE MENOR)

La propuesta dice que "Guardar borrador aparece solo en Step 4" y que Step 4 habilita "Publicar". El `EventStepNavBar` en Step 4 debe tener comportamiento diferente al de los pasos anteriores: el botón derecho es "Publicar" (accent, llama `cubit.saveEvent()`) y hay un enlace secundario "Guardar borrador" (text button, llama `cubit.saveDraft()`). El `EventStepNavBar` debe aceptar un parámetro `isLastStep: bool` que controla este comportamiento. El cubit ya tiene `saveEvent()` y `saveDraft()` correctamente implementados.
