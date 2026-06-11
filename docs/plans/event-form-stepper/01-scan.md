# 01 — System Scan

**Slug:** `event-form-stepper`  
**Fecha:** 2026-06-09T00:07:19Z  
**Scanner:** System Scanner

---

## Inventario Flutter

### Feature `events` — capas

**Domain** (`lib/features/events/domain/`)
- `EventModel` — modelo puro con campo `city: String` (requerido, no nullable). Contiene también `allowedBrands`, `routeGeoJson`, `waypoints`, `routePoints` getter.
- `EventDifficulty`, `EventType`, `EventState`, `RouteType` — enums definidos en `constants/event_form_fields.dart` (conviven con `EventFormFields`).
- Use cases: `CreateEventUseCase`, `UpdateEventUseCase`, `UploadEventImageUseCase`, `GetGenerateCoverUseCase`, `GenerateEventDescriptionUseCase` (nuevo, del exec-run ai).
- Repository interfaces: `AiDescriptionRepository` (nuevo, no commitado).

**Data** (`lib/features/events/data/`)
- `EventDto` — DTO que extiende `EventModel` (Pattern B). Incluye `city`.
- `AiDescriptionRequestDto`, `AiDescriptionResponseDto`, `AiEventContextDto`, `AiChatTurnDto` — nuevos DTOs del exec-run ai (no commitados, archivos `??` en git status).
- `AiDescriptionService`, `AiDescriptionRepositoryImpl` — nuevos, no commitados.
- `CoverGenerationDto` — DTO para `POST /events/generate-cover`.

**Presentation — form** (`lib/features/events/presentation/form/`)

*Cubit:*
- `EventFormCubit` — `@injectable`, estado con `saveResult`, `coverGenerationResult`, route fields. Expone `formKey: GlobalKey<FormBuilderState>`. Métodos: `initialize()`, `buildEventToSave()`, `buildDraftToSave()`, `saveEvent()`, `saveDraft()`, `generateCover(title, eventType, city)`. **`city` es parámetro requerido en `generateCover()` y se lee via `formData[EventFormFields.city]` en ambos build methods.**
- `EventFormState` (freezed) — no tiene campo `currentStep`. Hay que añadirlo.
- `AiDescriptionChatCubit` — nuevo cubit del exec-run ai (no commitado).

*Widgets raíz:*
- `EventFormView` — `Scaffold` con `AppFormNavHeader` (título + botón Publicar a la derecha), `EventFormContent` en body, `EventFormBottomBar` como bottomNavigationBar.
- `EventFormContent` — `SingleChildScrollView` + `FormBuilder(key: cubit.formKey)` con todas las secciones en columna. Contiene lógica de portada (cover/preview). **Es el widget a reemplazar.**
- `EventFormBottomBar` — pill "Publicar evento" + link "Guardar borrador". **A eliminar.**
- `CoverPlaceholderView` — placeholder gris de portada. **Referenciado por `CoverPreviewWidget`** como error/fallback widget — NO eliminable directamente; el brief lo marca como eliminado pero sigue en uso en `cover_preview_widget.dart`.
- `CoverPreviewWidget` — muestra portada generada/subida con opciones. Se conserva.

*Secciones (todas `lib/features/events/presentation/form/widgets/sections/`):*
| Widget | Target step |
|--------|-------------|
| `EventFormBasicInfoSection` | Step 1 — nombre + descripción + botón IA (ya convertido a StatefulWidget con `QuillController` en exec-run no commitado) |
| `EventFormDateTimeSection` | Step 1 |
| `EventFormDifficultySection` | Step 2 |
| `EventFormEventTypeSection` | Step 2 |
| `EventFormMaxParticipantsSection` | Step 2 |
| `EventFormPriceSection` | Step 2 |
| `EventFormMultiBrandSection` | Step 2 |
| `EventFormLocationsSection` | Step 3 |
| `EventFormDetailsSection` | **Código muerto** — no importado en ningún archivo de `lib/`. Tiene sub-widgets `details/difficulty_picker.dart` y `details/event_type_picker.dart` propios. Seguro eliminar. |

*Widgets de AI chat (exec-run no commitado):*
- `AiDescriptionChatSheet`, `AiChatBubble`, `AiChatEmptyState`, `AiChatErrorBanner`, `AiChatInputRow`, `AiChatLoadingIndicator`, `AiInsertButton`, `AiQuotaIndicator` — todos bajo `widgets/ai_chat/`.

*Nuevo directorio objetivo (no existe aún):*
- `widgets/steps/` — vacío; 7 widgets nuevos van aquí.

---

## Dependencias

Del `pubspec.yaml` relevantes para este refactor:

| Paquete | Versión | Relevancia |
|---------|---------|------------|
| `flutter_bloc` | ^9.1.1 | Cubit + BlocBuilder |
| `flutter_form_builder` | ^10.2.0 | FormBuilder global con `formKey` |
| `freezed_annotation` | ^3.1.0 | `EventFormState` necesita codegen al añadir `currentStep` |
| `go_router` | ^17.0.0 | Pop on save |
| `flutter_quill` | ^11.0.0 | Rich text editor en Step 1 |

No se necesita ninguna dependencia nueva para el stepper (`PageView` e `IndexedStack` son Flutter core).

---

## Superficie rideglory-api

**Microservicio:** `events-ms` via `api-gateway/src/events/events.controller.ts`

| Método | Path | Propósito | Impacto por refactor |
|--------|------|-----------|----------------------|
| `POST` | `/events` | Crear evento (`CreateEventDto`) | `city: string` es campo presente (`@IsString()` sin `@IsNotEmpty()`) — enviar `''` pasaría validación DTO pero quedaría registro vacío en DB |
| `PATCH` | `/events/:id` | Actualizar evento (`UpdateEventDto`) | Ídem |
| `POST` | `/events/generate-cover` | Genera portada (`GenerateCoverDto`) | `city` tiene `@IsNotEmpty()` — enviar `''` **falla con 400**. Requiere decisión antes de ejecutar |
| `GET` | `/events` | Listar eventos con filtros | Sin impacto |
| `GET` | `/events/:id` | Detalle de evento | Sin impacto |
| `PATCH` | `/events/:id/publish` | Publicar evento | Sin impacto |

**Contrato `CreateEventDto`** (`rideglory-contracts`): `city: string` marcado `@IsString()` (sin `@IsNotEmpty()`). El campo no es `@IsOptional()` por lo tanto requiere estar presente pero acepta string vacío.

**`GenerateCoverDto`**: `city` tiene `@IsNotEmpty()` — es el único punto crítico de validación que bloquea el envío de `city: ''`.

---

## Gap analysis

| Elemento | Estado | Detalle |
|----------|--------|---------|
| `EventFormState.currentStep` | **not started** | Campo `int` o `enum` no existe; requiere añadir a la clase freezed y regenerar |
| `widgets/steps/` con 7 nuevos widgets | **not started** | Directorio y archivos inexistentes |
| `EventFormView` actualizado (PageView + nuevo AppBar) | **not started** | Aún usa `EventFormContent` + `EventFormBottomBar` |
| `EventFormBasicInfoSection` sin `AppCityAutocomplete` | **partial** | El exec-run ya convirtió a `StatefulWidget` con AI chat pero `AppCityAutocomplete` sigue presente (línea 166). El exec-run NO está commitado. |
| `EventFormCubit.buildEventToSave()` sin `city` | **partial** | Lee `formData[EventFormFields.city]` en línea 374 y 447. Hay que cambiar a `city: ''` |
| `EventFormCubit.generateCover()` sin `city` | **partial** | Parámetro `city` requerido; la API no admite vacío → decisión pendiente |
| `EventFormDetailsSection` (código muerto) | **partial** | Existe pero no se usa; safe to delete |
| `CoverPlaceholderView` eliminación | **partial** | Sigue referenciado en `CoverPreviewWidget` — no es eliminable independientemente; el brief lo marca como eliminado incorrectamente |
| Strings ARB para stepper + Step 4 | **not started** | No hay keys `event_step_*` ni labels del indicador |
| Tests actualizados (city en cubit, basic_info_section) | **partial** | `event_form_cubit_analytics_test.dart` línea 39 tiene `city: 'Medellín'`; `event_form_basic_info_section_test.dart` verifica `_buildEventContext().city` en AC18 (líneas 6, 85, 147, 220) |
| Exec-run `app-ai-description-assistant` commitado | **not started** | Git status muestra todos sus archivos como `??` (untracked) y `M` (modified). **Prerrequisito bloqueante.** |

---

## Patrones

1. **FormBuilder global con `formKey` en el cubit** — el patrón ya establecido. El cubit es `@injectable` (no singleton) y se crea por `BlocProvider` en `EventFormPage`. El `formKey` puede seguir siendo global si el `FormBuilder` envuelve el `IndexedStack`/`PageView` completo. `AutomaticKeepAliveClientMixin` es la alternativa si se usa `PageView`.

2. **`EventFormState` freezed** — añadir `currentStep` requiere `dart run build_runner build`. El freezed está en `event_form_cubit.dart` como `part`.

3. **Secciones autocontenidas** — cada `EventFormXxxSection` usa `FormBuilder.of(context)` internamente o acepta `name` fields. Se pueden reubicar en steps sin cambiar su API interna.

4. **`ResultState<T>` para async** — se mantiene para `saveResult` y `coverGenerationResult`. No se necesita nuevo estado async para la navegación entre pasos.

5. **Validación por paso** — `formKey.currentState?.saveAndValidate()` valida TODO el formulario. Para validar solo un paso se necesita o bien `formKey.currentState?.fields` filtrado, o sub-keys por paso. La opción más simple es marcar como `required: false` los campos de pasos posteriores y validar manualmente en el cubit.

6. **`AppFormNavHeader`** — ya tiene soporte para `leading` y `trailing` como `AppFormNavAction`. El nuevo AppBar sin botón Publicar simplifica el trailing (puede ser `null` o spacer).

---

## Implicaciones para el plan

1. **Prerrequisito duro:** el exec-run `app-ai-description-assistant` debe ser revisado y commitado por el humano **antes** de iniciar esta fase. Toda la integración de AI chat en `EventFormBasicInfoSection` ya existe pero está sin commitear. El refactor asume ese código como base.

2. **Decisión de `city` debe resolverse en la fase:** la recomendación es enviar `city: ''` en `buildEventToSave()` y `buildDraftToSave()` (el backend lo acepta), y ajustar `generateCover()` para usar el `meetingPoint` como proxy de ciudad (o simplemente omitir el campo si el backend lo hace opcional). Alternativamente: hacer `city` opcional en `GenerateCoverDto` (cambio menor de backend sin migración de datos). Esta decisión afecta si el plan incluye un toque mínimo de backend.

3. **`CoverPlaceholderView` no se elimina limpiamente:** sigue siendo usado como fallback en `CoverPreviewWidget`. La "eliminación" del brief se refiere a que deja de ser el estado inicial visible (reemplazado por el área tap en Step 1), no a borrar el archivo. El plan debe aclarar esto para no romper `CoverPreviewWidget`.

4. **`IndexedStack` > `PageView` para mantener estado:** con `IndexedStack` todos los widgets del formulario permanecen en el árbol (los `FormBuilder` fields no se destruyen), el `formKey` global sigue funcionando sin `AutomaticKeepAliveClientMixin`. La animación de deslizamiento se puede lograr con `AnimatedSwitcher` sobre el `IndexedStack`.

5. **Codegen necesario una vez:** al añadir `currentStep` a `EventFormState` hay que regenerar `event_form_cubit.freezed.dart`. El plan debe incluir este paso explícitamente (o el implementador lo corre al tocar el archivo).
