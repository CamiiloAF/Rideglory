# 05 — Síntesis PO: Plan Final (v3)

**Slug:** `event-form-stepper`
**Fecha:** 2026-06-09T00:49:56Z
**Autor:** Product Owner (consolidación final — correcciones Auditor Opus v2 + v3)

---

## Overview

El formulario de creación de eventos pasa de un scroll único a un **wizard de 4 pasos** (Básico → Detalles → Ruta → Revisión) con indicador de progreso, navegación Atrás/Continuar, pantalla de revisión antes de publicar y opción de guardar borrador desde Step 4. La ciudad desaparece del formulario: la cadena completa `GetGenerateCoverUseCase` → `EventCoverRepository` (interface) → `EventCoverRepositoryImpl` pasa a tratar `city` como `String?`, el impl omite la clave del body cuando city es null o vacío, y `GenerateCoverDto.city` se marca `@IsOptional()` en el backend. `city: ''` se usa en los payloads de creación/borrador. `meetingPointName` actúa como proxy geográfico para el contexto IA de descripción.

El plan se ejecuta en **3 fases secuenciales** (1 → 2 → 3). La Fase 1 es el único momento con toque de `rideglory-api`. Las Fases 2 y 3 son exclusivamente Flutter.

---

## Cambios aplicados

### Ajustes de Architect + Plan Reviewer (v1)

| Código | Origen | Acción incorporada |
|--------|--------|--------------------|
| A1 | Architect | `city` opcional en `GenerateCoverDto` declarado como alcance obligatorio de Fase 1, no opcional. Toda la cadena Flutter pasa a `String? city` (ver Corr-A). |
| A2 | Architect | `static const Map<int, List<String>> stepFields` y `bool validateStep(int step)` viven exclusivamente en `EventFormCubit`. Entregable explícito de Fase 1. |
| A3 | Architect | Fase 2 incluye actualizar `_buildEventContext()` en `EventFormBasicInfoSection` para leer `context.read<EventFormCubit>().state.meetingPointName ?? ''` en lugar de `formValues[EventFormFields.city]`. |
| A4 | Architect | Fase 1 comienza con verificación de `git status`: si hay archivos `??` en `lib/features/events/`, el implementador detiene la fase y reporta al humano. |
| A5 | Architect | `EventStepNavBar` acepta `isLastStep: bool`. Step 4: botón derecho = 'Publicar' (accent, `saveEvent()`), text button secundario = 'Guardar borrador' (`saveDraft()`). Pasos 1–3: botón derecho = 'Continuar' (`validateStep()` + `nextStep()`). |
| Plan-1 | Plan Reviewer | Tabla completa de ARB keys definida en Fase 1. |
| Plan-2 | Plan Reviewer | AC explícito en Fase 1: firma `generateCover({required String title, required String eventType, String? city})` tras el cambio de backend. |
| Plan-3 | Plan Reviewer | Constantes `_step1Fields` / `_step2Fields` / `_step3Fields` e `isCurrentStepValid()` creados en Fase 1 dentro de `EventFormCubit`. |
| Plan-4 | Plan Reviewer | Fase 2 lista `draft_link.dart` y `publish_button.dart` como archivos a eliminar junto con `event_form_bottom_bar.dart` para evitar código muerto no detectado por `dart analyze`. |
| Plan-5 | Plan Reviewer | Layout de `EventStepIndicator` especificado: 4 círculos de 28px, etiquetas ≤8 chars, texto del número activo con `AppColors.darkBgPrimary` sobre fondo naranja. |
| Plan-6 | Plan Reviewer | `EventFormStep4Review` acotado a resumen de texto plano. Sin Quill en modo lectura, sin mapa de ruta, sin pickers. |
| Plan-7 | Plan Reviewer | Fase 3 acotada: tests de cubit (nextStep/prevStep/isCurrentStepValid/buildEventToSave) + 1 smoke test de widget para `EventFormStep1`. Steps 2, 3 y 4Review no reciben widget tests en esta iteración. |

### Correcciones de Auditor Opus (v2 — primera ronda)

| Código | Acción incorporada |
|--------|--------------------|
| Corr-1 | `EventFormDateTimeSection` asignado explícitamente a Step 1. `event_form_step1.dart` contiene: `EventFormBasicInfoSection` (nombre + descripción + AI chat) + área de portada (tap ≥120px → `CoverPickerSheet`) + `EventFormDateTimeSection` (dateRange, isMultiDay, meetingTime). Los 5 campos de Step 1 en `_step1Fields` reflejan esto. |
| Corr-2 | Enumeración completa y determinística de los 16 campos (excluido `city`) en `_step1Fields` / `_step2Fields` / `_step3Fields`. Ver sección "Mapeo campo→paso". |
| Corr-3 | `formKey.currentState?.fields[name]?.validate()` cubre los campos de fecha. `isMultiDay` siempre pasa. `dateRange` solo falla si `isMultiDay == true`. El implementador **confirma en `EventFormDateTimeSection` que el validator de `dateRange` no falla cuando `isMultiDay == false`** antes de cerrar el AC `validateStep(0) == true` en ese caso. |
| Corr-4 | El botón 'Publicar' en Step 4 reutiliza la key existente `event_form_publish_action`. No se crea key nueva. `event_step_reviewAndPublish` se reserva como título del paso, no como label del botón. |
| Corr-5 | Ruta canónica confirmada: `lib/features/events/constants/event_form_fields.dart`. |

### Correcciones de Auditor Opus (v3 — segunda ronda)

| Código | Acción incorporada |
|--------|--------------------|
| Corr-A | El cambio de `city` opcional en Fase 1 cubre **toda la cadena Flutter**, no solo el cubit: (a) `GetGenerateCoverUseCase.call()` pasa de `required String city` a `String? city`; (b) `EventCoverRepository` (interface en domain) pasa a `String? city`; (c) `EventCoverRepositoryImpl` pasa a `String? city` y construye el body map agregando la entrada `'city'` solo si `city != null && city.isNotEmpty`. Esta es la pieza que efectivamente omite el campo del payload. Los tres archivos se añaden a la lista de modificados de Fase 1. |
| Corr-B | AC reescrito con criterio observable y ubicado en la capa correcta: `EventCoverRepositoryImpl` omite la clave `city` del body cuando `city` es null o vacío; cuando es non-empty la incluye. Test/inspección del map enviado a `EventCoverService.generateCover` lo confirma. |
| Corr-C | Archivos de Fase 1 ampliados con: `get_generate_cover_use_case.dart`, `event_cover_repository.dart` (interface), `event_cover_repository_impl.dart`. |
| Corr-D | En Fase 2, `cover_picker_sheet.dart` invoca `cubit.generateCover(title: ..., eventType: ..., city: context.read<EventFormCubit>().state.meetingPointName)` — el parámetro `city` es nullable; no se fuerza `''`. |
| Corr-E | Supuesto S8 ampliado con nota de verificación previa de `dateRange` validator cuando `isMultiDay == false`. |

---

## Mapeo campo → paso (enumeración completa)

Esta tabla define `_step1Fields`, `_step2Fields` y `_step3Fields` en `EventFormCubit`. Los 16 campos son todas las constantes de `lib/features/events/constants/event_form_fields.dart` excepto `city` (eliminado).

| Campo (`EventFormFields.`) | Tipo de dato | Paso | `_stepNFields` | Nota de validación |
|---------------------------|-------------|------|------------|-------------------|
| `name` | `String` | 1 | `_step1Fields` | Required; validator `@IsNotEmpty`. `validateStep(0)` falla si vacío. |
| `description` | `String` | 1 | `_step1Fields` | Texto Quill; validator opcional. |
| `dateRange` | `DateTimeRange?` | 1 | `_step1Fields` | Validator activo solo cuando `isMultiDay == true`. Ver Corr-3 y S8. |
| `isMultiDay` | `bool` | 1 | `_step1Fields` | Toggle (`AppSwitch`); sin validator; `validate()` retorna `true` siempre. |
| `meetingTime` | `DateTime?` | 1 | `_step1Fields` | Time picker; validator `@NotNull`. |
| `difficulty` | `EventDifficulty` | 2 | `_step2Fields` | Enum; default valid; `validate()` pasa con default. |
| `eventType` | `EventType` | 2 | `_step2Fields` | Enum; default valid. |
| `price` | `String` | 2 | `_step2Fields` | Numérico; opcional si `isFreeEvent == true`. |
| `isFreeEvent` | `bool` | 2 | `_step2Fields` | Toggle; sin validator. |
| `maxParticipants` | `int?` | 2 | `_step2Fields` | Slider/campo numérico; nullable. |
| `isMultiBrand` | `bool` | 2 | `_step2Fields` | Toggle; sin validator. |
| `allowedBrands` | `List<String>` | 2 | `_step2Fields` | Multi-select; requerido si `isMultiBrand == false`. |
| `meetingPoint` | `String` | 3 | `_step3Fields` | Texto de autocomplete; se almacena en `state.meetingPointName`. |
| `destination` | `String` | 3 | `_step3Fields` | Texto de autocomplete; se almacena en `state.destinationName`. |
| `routeType` | `RouteType` | 3 | `_step3Fields` | Enum; default `RouteType.simple`; siempre válido. |
| `waypoints` | `List<String>` | 3 | `_step3Fields` | Solo activo si `routeType == custom`. |

**Step 4** no tiene campos de formulario. `EventFormStep4Review` es un resumen de texto plano — no hay campos que validar.

**Implementación en cubit:**
```dart
// lib/features/events/presentation/form/cubit/event_form_cubit.dart
// Ruta del archivo de constantes: lib/features/events/constants/event_form_fields.dart

static const _step1Fields = [
  EventFormFields.name,
  EventFormFields.description,
  EventFormFields.dateRange,
  EventFormFields.isMultiDay,
  EventFormFields.meetingTime,
];

static const _step2Fields = [
  EventFormFields.difficulty,
  EventFormFields.eventType,
  EventFormFields.price,
  EventFormFields.isFreeEvent,
  EventFormFields.maxParticipants,
  EventFormFields.isMultiBrand,
  EventFormFields.allowedBrands,
];

static const _step3Fields = [
  EventFormFields.meetingPoint,
  EventFormFields.destination,
  EventFormFields.routeType,
  EventFormFields.waypoints,
];

static const Map<int, List<String>> stepFields = {
  0: _step1Fields,
  1: _step2Fields,
  2: _step3Fields,
};

bool validateStep(int step) {
  final fields = stepFields[step] ?? const [];
  var valid = true;
  for (final name in fields) {
    final field = formKey.currentState?.fields[name];
    if (field != null && !field.validate()) valid = false;
  }
  return valid;
}

bool isCurrentStepValid() => validateStep(state.currentStep);
```

---

## ARB keys del stepper (Fase 1)

| Key | Texto | Nota |
|-----|-------|------|
| `event_step_basic` | `'Básico'` | Etiqueta Step 1 en indicador (≤8 chars) |
| `event_step_details` | `'Detalles'` | Etiqueta Step 2 (8 chars exactos — OK) |
| `event_step_route` | `'Ruta'` | Etiqueta Step 3 |
| `event_step_review` | `'Revisar'` | Etiqueta Step 4 (≤8 chars) |
| `event_step_continue` | `'Continuar'` | Botón derecho pasos 1–3 |
| `event_step_back` | `'Atrás'` | Botón izquierdo todos los pasos |
| `event_step_reviewAndPublish` | `'Revisar y publicar'` | Título opcional del Step 4 (no label de botón) |
| `event_step_saveDraft` | `'Guardar borrador'` | Text button Step 4 |
| `event_step_progressLabel` | `'Paso {current} de {total}'` | Label de progreso accesible |
| *(existente)* `event_form_publish_action` | `'Publicar'` | **Reutilizar** para botón accent de Step 4. No crear key nueva. |

---

## Lista final de fases

| # | Título | Nivel | Por qué ese nivel |
|---|--------|-------|-------------------|
| 1 | Fundación técnica | **normal** | Toca `rideglory-api` (TypeScript cross-repo, `generate-cover.dto.ts`). La rúbrica excluye `lite` ante cualquier toque de contrato API. Además modifica 3 archivos de la cadena domain/data de Flutter (`GetGenerateCoverUseCase`, `EventCoverRepository` interface, `EventCoverRepositoryImpl`). Requiere codegen freezed. Sin migración ni seguridad/PII — no escala a `full`. |
| 2 | Wizard completo | **normal** | Feature UI de complejidad media: 7 widgets nuevos, `IndexedStack` + `AnimatedSwitcher`, validación por paso, eliminación de 4 archivos, verificación de no-regresión en modo edición. Una área principal, riesgo medio, sin backend. |
| 3 | Cobertura y cierre | **lite** | Cambio mecánico: actualizar assertions de `city` en tests existentes, agregar tests de cubit y 1 smoke test de widget. Sin contratos API, sin migraciones, una sola área, reversible. |

---

### Fase 1 — Fundación técnica

**Nivel:** normal
**Meta:** El cubit gestiona pasos, la ciudad no bloquea ninguna operación en toda la cadena Flutter + backend, y los step-field maps están centralizados.

**Alcance:**

1. **Prerrequisito bloqueante:** Correr `git status`. Si hay archivos `??` en `lib/features/events/`, detener la fase y reportar al humano.

2. **Backend (`rideglory-api`):** En `api-gateway/src/events/dto/generate-cover.dto.ts`, reemplazar:
   ```typescript
   @IsString()
   @IsNotEmpty()
   city: string;
   ```
   por:
   ```typescript
   @IsOptional()
   @IsString()
   city?: string;
   ```

3. **Cadena Flutter — `city` opcional (3 archivos):**

   a. `lib/features/events/domain/repository/event_cover_repository.dart` (interface):
   ```dart
   Future<Either<DomainException, String>> generateCover({
     required String title,
     required String eventType,
     String? city,  // era: required String city
   });
   ```

   b. `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart`:
   ```dart
   Future<Either<DomainException, String>> call({
     required String title,
     required String eventType,
     String? city,  // era: required String city
   }) => _repository.generateCover(title: title, eventType: eventType, city: city);
   ```

   c. `lib/features/events/data/repository/event_cover_repository_impl.dart`: recibe `String? city`, construye el body map e incluye la clave `'city'` **solo si** `city != null && city.isNotEmpty`:
   ```dart
   final body = <String, dynamic>{
     'title': title,
     'eventType': eventType,
     if (city != null && city.isNotEmpty) 'city': city,
   };
   ```

4. **`EventFormState`:** Añadir `@Default(0) int currentStep`. Correr `dart run build_runner build --delete-conflicting-outputs`.

5. **`EventFormCubit`** (`lib/features/events/presentation/form/cubit/event_form_cubit.dart`):
   - `buildEventToSave()`: `city: formData[EventFormFields.city] as String` → `city: ''`.
   - `buildDraftToSave()`: `city: (formData[EventFormFields.city] as String?)?.trim() ?? ''` → `city: ''`.
   - `generateCover()`: cambiar firma a `({required String title, required String eventType, String? city})`. Pasar `city` al use case tal cual (nullable) — no forzar `''`.
   - Añadir `nextStep()`, `prevStep()`, `goToStep(int)`.
   - Añadir constantes `_step1Fields`, `_step2Fields`, `_step3Fields` con los 16 campos (ver sección Mapeo campo→paso).
   - Añadir `static const Map<int, List<String>> stepFields`.
   - Añadir método `bool validateStep(int step)`.
   - Añadir método `bool isCurrentStepValid()`.

6. **ARB keys** (`lib/l10n/app_es.arb`): Añadir las 9 keys nuevas del stepper (ver tabla ARB). `event_form_publish_action` ya existe — NO duplicar.

7. **Eliminar código muerto:**
   - `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
   - Directorio `lib/features/events/presentation/form/widgets/sections/details/` (contiene `difficulty_picker.dart`, `event_type_picker.dart`).

**Archivos modificados en Fase 1:**
- `rideglory-api/api-gateway/src/events/dto/generate-cover.dto.ts`
- `lib/features/events/domain/repository/event_cover_repository.dart`
- `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart`
- `lib/features/events/data/repository/event_cover_repository_impl.dart`
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
- `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` (generado)
- `lib/l10n/app_es.arb`
- `lib/l10n/app_localizations.dart` (generado)
- `lib/l10n/app_localizations_es.dart` (generado)

**Archivos eliminados en Fase 1:**
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
- `lib/features/events/presentation/form/widgets/sections/details/` (directorio completo)

**Criterios de aceptación:**
- `dart analyze` sin errores nuevos.
- `EventCoverRepositoryImpl` omite la clave `city` del body cuando `city` es null o vacío; cuando es non-empty la incluye. Verificable inspeccionando el map construido antes de llamar a `EventCoverService.generateCover`.
- `buildEventToSave()` y `buildDraftToSave()` producen `city: ''` sin fallo.
- `validateStep(0)` retorna `false` si `EventFormFields.name` está vacío, `true` si está lleno.
- Los 9 ARB keys nuevos existen en `app_es.arb` y en `app_localizations_es.dart` regenerado.
- `_step1Fields` tiene 5 entries, `_step2Fields` tiene 7, `_step3Fields` tiene 4. Total = 16 (todos los campos de `EventFormFields` excepto `city`).

---

### Fase 2 — Wizard completo

**Nivel:** normal
**Meta:** El organizador navega 4 pasos secuenciales, puede publicar o guardar borrador desde Step 4, y el modo edición no regresiona.

**Alcance:**

**Contenido de cada step:**

| Step | Secciones reutilizadas | Campos FormBuilder cubiertos |
|------|------------------------|------------------------------|
| Step 1 (Básico) | `EventFormBasicInfoSection` + área portada + `EventFormDateTimeSection` | name, description, dateRange, isMultiDay, meetingTime |
| Step 2 (Detalles) | `EventFormDifficultySection`, `EventFormEventTypeSection`, `EventFormMaxParticipantsSection`, `EventFormPriceSection`, `EventFormMultiBrandSection` | difficulty, eventType, price, isFreeEvent, maxParticipants, isMultiBrand, allowedBrands |
| Step 3 (Ruta) | `EventFormLocationsSection` | meetingPoint, destination, routeType, waypoints |
| Step 4 (Revisión) | Resumen de texto plano (sin secciones reutilizadas) | (ninguno — solo lectura) |

**Nuevos archivos en `lib/features/events/presentation/form/widgets/steps/`:**
- `event_step_indicator.dart` — 4 círculos 28px, etiquetas ≤8 chars debajo; activo: `colorScheme.primary` con número en `AppColors.darkBgPrimary` (regla de acento — no blanco); completados: fill primario semitransparente; futuros: `colorScheme.surfaceContainerHighest`.
- `event_step_nav_bar.dart` — `isLastStep: bool`; cuando `false`: botón derecho = `l10n.event_step_continue` (`validateStep` + `nextStep`); cuando `true`: botón derecho = `l10n.event_form_publish_action` (accent, `saveEvent()`) + text button `l10n.event_step_saveDraft` (`saveDraft()`). `SafeArea` en el bottom. Usa `AppButton` (no `ElevatedButton`).
- `cover_picker_sheet.dart` — bottom sheet con dos `AppButton`: galería + generar con IA. Reutiliza `FormImageCubit`. El caller invoca: `cubit.generateCover(title: titleValue, eventType: eventTypeValue, city: context.read<EventFormCubit>().state.meetingPointName)` — `city` es nullable; no se fuerza `''`.
- `event_form_step1.dart` — `EventFormBasicInfoSection` + área de portada (tap ≥120px → `CoverPickerSheet`) + `EventFormDateTimeSection`.
- `event_form_step2.dart` — `EventFormDifficultySection` + `EventFormEventTypeSection` + `EventFormMaxParticipantsSection` + `EventFormPriceSection` + `EventFormMultiBrandSection`.
- `event_form_step3.dart` — `EventFormLocationsSection` (Mapbox lazy-init: `MapboxMap` se inicializa solo cuando `currentStep == 2`).
- `event_form_step4_review.dart` — resumen de texto plano: título, descripción (texto plano sin formato Quill), fecha/hora, dificultad, tipo, punto de encuentro/destino, marcas, participantes, precio. **Sin** `flutter_quill`, **sin** mapa, **sin** pickers.

**`EventFormView` refactorizado:**
- `FormBuilder(key: cubit.formKey)` envuelve `AnimatedSwitcher(key: ValueKey(currentStep))` sobre `IndexedStack` con los 4 steps.
- Nuevo AppBar: sin botón 'Publicar' en trailing. `EventStepIndicator` en el body superior.
- `if (isEditing)` conserva el scroll anterior; `else` muestra el wizard. Comentario `// TODO(stepper-edit): wizard para modo edición pendiente`.

**`EventFormBasicInfoSection`:**
- Eliminar `AppCityAutocomplete` (línea 166 del archivo exec-run).
- Actualizar `_buildEventContext()` (línea 71): `city = context.read<EventFormCubit>().state.meetingPointName ?? ''`.

**Archivos a eliminar (verificar imports con `grep -r "<archivo>" lib/` antes):**
- `event_form_content.dart`
- `event_form_bottom_bar.dart`
- `draft_link.dart`
- `publish_button.dart`

**Archivos a NO eliminar:**
- `cover_placeholder_view.dart` — sigue referenciado por `CoverPreviewWidget` como fallback.

**Criterios de aceptación:**
- Flujo completo Step 1 → Step 4 → Publicar sin pérdida de datos al retroceder.
- Botón 'Continuar' en Step 1 deshabilitado con nombre vacío, habilitado con nombre lleno.
- `isEditing = true` navega al scroll form sin regresión.
- `dart analyze` sin errores.
- Sin métodos `Widget _buildXxx()` en ningún widget nuevo.
- Un widget por archivo en `widgets/steps/`.
- El botón 'Publicar' usa la key `event_form_publish_action` (no hardcoding, no nueva key duplicada).
- `EventFormStep1` incluye `EventFormDateTimeSection` y los 5 campos de Step 1 están presentes en el formulario.
- `cover_picker_sheet.dart` pasa `city` como `state.meetingPointName` (nullable — no `''`).

---

### Fase 3 — Cobertura y cierre

**Nivel:** lite
**Meta:** El flujo pasa `dart analyze` limpio y los tests cubren los cambios del cubit y un smoke test de Step 1.

**Alcance:**

1. **Tests de cubit existentes actualizados:**
   - `event_form_cubit_analytics_test.dart` línea 39: `city: 'Medellín'` → `city: ''`.
   - `event_form_basic_info_section_test.dart`: actualizar assertions de `city` (líneas 85, 147, 220) para verificar `city == ''` y que `_buildEventContext().city` usa `meetingPointName`.

2. **Nuevos tests de cubit:**
   - `nextStep()` incrementa `currentStep` hasta 3 (no pasa de 3).
   - `prevStep()` decrementa hasta 0 (no baja de 0).
   - `isCurrentStepValid()` retorna `false` con Step 0 y nombre vacío; `true` con nombre lleno.
   - `buildEventToSave()` produce `city: ''`.

3. **Nuevo test de widget:**
   - `event_form_step1_test.dart` — smoke test: renderiza sin overflow, botón 'Continuar' deshabilitado con nombre vacío, habilitado con nombre lleno.

4. **No cubrir en esta iteración:** `EventFormStep2`, `EventFormStep3`, `EventFormStep4Review` con widget tests.

5. **`dart analyze` limpio:** Verificar que no quedan referencias a `EventFormFields.city` en `lib/features/events/presentation/`. Sin errores ni warnings nuevos.

**Criterios de aceptación:**
- `flutter test` pasa sin fallos.
- `dart analyze` sin errores ni warnings en `lib/` (excluidos `.g.dart` y `.freezed.dart`).
- No quedan referencias a `EventFormFields.city` en `lib/features/events/presentation/`.

---

## Supuestos y riesgos

### Supuestos

| # | Supuesto |
|---|----------|
| S1 | El exec-run `app-ai-description-assistant` está revisado y commitado antes de la Fase 1. Si no lo está, el implementador detiene la Fase 1 y reporta. |
| S2 | `POST /events` (`CreateEventDto`) acepta `city: ''` sin error (campo `@IsString()` sin `@IsNotEmpty()`). Sin cambio de contrato. |
| S3 | `IndexedStack` mantiene todos los widgets vivos. `FormBuilder` global con `formKey` accesible desde cualquier paso. No se necesita `AutomaticKeepAliveClientMixin`. |
| S4 | El wizard aplica solo a `isEditing = false`. El modo edición conserva el scroll único hasta diseño futuro. |
| S5 | `CoverPlaceholderView` se conserva (referenciado por `CoverPreviewWidget` como fallback). |
| S6 | 'Guardar borrador' aparece solo en Step 4, no en pasos intermedios. |
| S7 | Step 2 y Step 3 tienen valores por defecto válidos y permiten 'Continuar' sin selección explícita del usuario. |
| S8 | `formKey.currentState?.fields[name]?.validate()` es el mecanismo estándar de FormBuilder y cubre todos los campos de los 3 pasos activos, incluyendo date pickers. `isMultiDay` siempre pasa (sin validator). `dateRange` solo falla si `isMultiDay == true` y el usuario no seleccionó rango (lógica ya en el validator del campo). **Nota de verificación previa (Corr-E):** el implementador confirma en `EventFormDateTimeSection` que el validator de `dateRange` no falla cuando `isMultiDay == false` antes de cerrar el AC `validateStep(0) == true` en ese caso. |
| S9 | La ruta canónica de constantes es `lib/features/events/constants/event_form_fields.dart`. Los `_stepNFields` en `EventFormCubit` importan desde esa ruta. |

### Riesgos residuales

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **Step-field mapping drift** — `_stepFields` se desincroniza con `EventFormFields` en refactors futuros. No detectado por compilador. | MEDIA | Comentario explícito en `_stepFields` vinculando cada entry a la constante. Test unitario de `validateStep()` actúa como safety net. |
| R2 | **`IndexedStack` y memoria en gama baja** — Mapbox + Quill vivos simultáneamente. Sin usuarios reales no es bloqueante. | BAJA-MEDIA | Lazy-init del `MapboxMap` (solo cuando `currentStep == 2`). Documentado como tech debt en `EventFormView`. |
| R3 | **Estado de validación previa no se re-evalúa** — Si el usuario retrocede a Step 1 y borra el nombre, el cubit no debe cachear `isCurrentStepValid()`. | BAJA | `isCurrentStepValid()` evalúa en tiempo real — no cachea. Corre los validators en el momento de la llamada. |
| R4 | **Modo edición sin wizard** — Inconsistencia UX temporal. | BAJA | Tech debt explícito con comentario `// TODO(stepper-edit)`. Aceptado sin usuarios reales. |
| R5 | **`AnimatedSwitcher` sin `ValueKey`** — Sin key no anima. | BAJA | Plan especifica `ValueKey(currentStep)` como criterio de aceptación de Fase 2. |
| R6 | **`dateRange` oculto con `isMultiDay == false`** — Si el campo no está montado en el árbol, `fields['dateRange']` puede retornar `null`. | BAJA | `validateStep` usa `field?.validate()` (null-safe). Si el campo no está presente, no falla. El validator de `dateRange` solo se activa cuando el campo está visible. |
