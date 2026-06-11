# Architect handoff — remove-city-field

**Date:** 2026-06-11T21:55:31Z
**Status:** done (v2 — corrección post-auditor Opus)

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| D1 | `city` se elimina de **todos los layers** en un único sweep (backend + Flutter) | El campo no tiene usuarios ni datos reales; hacerlo en partes generaría builds rotos transitorios |
| D2 | En la UI de event cards (`EventCard`, `EventCardInfoPanel`) la ciudad se **reemplaza por `event.meetingPoint`** | `meetingPoint` ya es el proxy geográfico canónico del evento; `city` era un duplicado de menor precisión |
| D3 | ~~`EventCardDateAndCity` renombra su parámetro `city` → `meetingPoint`~~ — **DECISIÓN ANULADA**: el widget no tiene call-sites en la app (código muerto). Se **elimina el archivo** en lugar de renombrar un parámetro que nadie consume | Confirmado con `grep -rn "EventCardDateAndCity" lib/ --include="*.dart"` → solo aparece en su propia definición. Renombrar un parámetro de un widget sin instanciación introduce ruido sin beneficio |
| D4 | El filtro de ciudad en `EventFiltersBottomSheet` y `EventFilters` se **elimina completamente** (campo + UI) | El filtro de city en el backend tampoco se usará; mantener la sección de filtro vacía sería confuso para el usuario |
| D5 | `EventsCubit._applyFiltersAndEmit()` elimina el bloque de búsqueda por `city` en `_searchQuery` y el bloque de filtro `_filters.city` | `meetingPoint` no necesita búsqueda por city; la búsqueda local puede hacerse por `name` + `meetingPoint` si se requiere en el futuro |
| D6 | En el contexto de IA (`AiDescriptionRequest`, `AiEventContextDto`), `city` se elimina sin reemplazo — Gemini no necesita este campo si `meetingPointName` está en el `EventFormState` del cubit | Simplemente quitar `city` reduce ruido; si en el futuro se quiere incluir la ubicación se añade `meetingPoint` |
| D7 | `AiDescriptionChatCubit.sendMessage()` y `retryLastMessage()` pierden el param `city: city`; los call-sites en `AiDescriptionChatPage` se actualizan | Cascada de D6 |
| D8 | `EventFormContent._getInitialValues()` elimina `EventFormFields.city: event.city` | No hay campo de formulario city en modo edit |
| D9 | Las claves l10n `event_eventCity`, `event_eventCityHint`, `event_cityRequired`, `event_filterByCity` se eliminan de `app_es.arb` | Evitar claves huérfanas; `event_filterByCity` solo era usada en `EventFiltersBottomSheet` |
| D10 | `docs/features/events.md` se actualiza para eliminar `city` de modelo, filtros, contratos y formulario | Regla `feedback_update_feature_docs.md` |
| D11 | ~~`EventCardDateAndCity` pasa de mostrar `city` a mostrar `meetingPoint`~~ — **DECISIÓN ANULADA** por D3: el widget es código muerto y se elimina directamente | No hay call-sites que actualizar; eliminar es más limpio que renombrar parámetros invisibles |
| D12 | `inscription_card.dart` en `event_registration`: el bloque `if (event?.city != null)` se **elimina** (no se reemplaza por `meetingPoint`) | La card de inscripción no es el lugar para mostrar punto de encuentro; el PRD no pide añadir meetingPoint aquí; eliminar el bloque es seguro y más limpio |
| D13 | Los tests AC-6 en `event_form_auditor_tests_test.dart` se **eliminan por completo** | Esos tests aseguran que `city == ''` en `buildEventToSave()`/`buildDraftToSave()`. Al eliminar el campo `city` del `EventModel`, las aserciones `event.city` ya no compilan. No tiene sentido reescribirlos porque el invariante que protegían (no leer city del formulario) deja de existir |

---

## Change map

### Backend — rideglory-api

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `rideglory-contracts/src/events/dto/create-event.dto.ts` | modify | Remove `city!: string` field | low |
| `rideglory-contracts/src/events/dto/event-filter.dto.ts` | modify | Remove `city?: string` field | low |
| `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` | modify | Remove `city!: string` field | low |
| `events-ms/prisma/schema.prisma` | modify | Remove `city String` field from `Event` model | med — requiere migración de base de datos local |
| `events-ms/src/events/events.service.ts` | modify | Remove `city` from `findAll`/`findMine` filter destructuring and Prisma where clause | low |
| `api-gateway/src/ai/gemini.service.ts` | modify | Remove `- Ciudad: ${eventContext.city}` line from prompt template | low |
| `rideglory-contracts` build | run command | `npm run build` + `pnpm install` in events-ms + api-gateway | med — si se omite, MODULE_NOT_FOUND en runtime |
| `events-ms/src/events/events.service.spec.ts` | modify | Remove TC-4 and TC-5 city assertions; update mock event objects without city | low |
| `api-gateway/src/ai/gemini.service.spec.ts` | modify | Remove `city` from mock AiDescriptionEventContextDto | low |
| `api-gateway/src/ai/ai.controller.spec.ts` | modify | Remove `city` from mock eventContext objects | low |
| `api-gateway/src/ai/ai-description.spec.ts` | modify | Remove `city` from mock request DTOs | low |

### Flutter — lib/

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/events/domain/model/event_model.dart` | modify | Remove `city` field, constructor param, copyWith param/body | med — model central; todos sus consumidores fallarán si queda una referencia |
| `lib/features/events/data/dto/event_dto.dart` | modify | Remove `required super.city` in constructor + `city: city` in `EventModelExtension.toJson()` | low — patrón B; generado por build_runner |
| `lib/features/events/data/service/event_service.dart` | modify | Remove `@Query('city') String? city` del método `getEvents` | low |
| `lib/features/events/data/repository/event_repository_impl.dart` | modify | Remove `String? city` param + `city: city` argument | low |
| `lib/features/events/domain/repository/event_repository.dart` | modify | Remove `String? city` param de `getEvents` | low |
| `lib/features/events/domain/use_cases/get_events_use_case.dart` | modify | Remove `String? city` param + `city: city` in call | low |
| `lib/features/events/domain/model/ai_description_request.dart` | modify | Remove `required this.city` field + constructor param | low |
| `lib/features/events/data/dto/ai_event_context_dto.dart` | modify | Remove `required this.city` field, constructor param, `city: request.city` in `fromDomain()` | low |
| `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` | modify | Remove `city: request.city` in trimmedRequest construction | low |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | modify | Remove `AppCityAutocomplete` widget + `city` local variable + `city: city` in `_buildEventContext()` | med — widget visible; riesgo de runtime error si queda referencia colgante |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | modify | Remove `required String city` param de `sendMessage()` y `retryLastMessage()`; remove `city: city` en `AiDescriptionRequest` construction | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart` | modify | Remove `city: eventContext.city` en los dos call-sites de `sendMessage`/`retryLastMessage` | low |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | Remove `city: ''` named arg completely (x2: `buildEventToSave` + `buildDraftToSave`) | low |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | modify | Remove `EventFormFields.city: event.city` from `_getInitialValues()` (edit branch) | low |
| `lib/features/events/constants/event_form_fields.dart` | modify | Remove `static const String city = 'city'` constant | low |
| `lib/features/events/constants/event_filter_form_fields.dart` | modify | Remove `static const String city = 'city'` constant | low |
| `lib/features/events/presentation/list/events_cubit.dart` | modify | Remove `String? city` from `EventFilters` + `EventsCubit._fetchFn` signature; remove city filter block in `_applyFiltersAndEmit()`; remove city from search filter in `_searchQuery` block | med — lógica de filtrado activa |
| `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` | modify | Remove ciudad section (FilterSectionLabel + AppCityAutocomplete); remove `city` from `_clearAll()` and `_apply()` | med — UI visible |
| `lib/features/events/presentation/list/widgets/event_card.dart` | modify | Replace `event.city` → `event.meetingPoint` in location row | low |
| `lib/features/events/presentation/list/widgets/event_card_info_panel.dart` | modify | Replace `event.city` → `event.meetingPoint` | low |
| `lib/features/events/presentation/list/widgets/event_card_date_and_city.dart` | **delete** | Widget es código muerto: no tiene call-sites en ningún archivo bajo `lib/` (confirmado con grep). Eliminar es más limpio que renombrar parámetros de un widget sin instanciación | low |
| `lib/features/event_registration/presentation/widgets/inscription_card.dart` | modify | Remove `if (event?.city != null)` block at lines ~190-212; replace `event!.city` reference with nothing (eliminar el bloque completo) | low — el feature compila; sin esto `EventModel.city` no existe y el archivo no compila |
| `lib/l10n/app_es.arb` | modify | Remove keys: `event_eventCity`, `event_eventCityHint`, `event_cityRequired`, `event_filterByCity` | low — claves huérfanas generan advertencia de l10n |
| `docs/features/events.md` | modify | Remove `city` from model section, form section, filter section, API contracts table | low |

### Tests Flutter

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | modify | Remove `city:` named arg from all `AiDescriptionRequest(...)` constructors | low |
| `test/features/events/data/repository/ai_description_repository_impl_test.dart` | modify | Remove `city:` from mock `AiDescriptionRequest` | low |
| `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` | modify | Remove `city:` from mock `EventModel` factory | low |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | modify | Remove TC-2-3/TC-2-10 city tests; remove `city:` from `EventFilters` and `EventModel` mock instances | med — múltiples test cases afectados |
| `test/features/home/presentation/cubit/home_cubit_test.dart` | modify | Remove `city: 'Medellín'` from mock `EventModel` | low |
| `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart` | modify | Remove `city: 'Medellín'` from mock `EventModel` | low |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | modify | Remove city-related test cases and city param from `_buildEventContext` verifications | med — city era campo verificado explícitamente |
| `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | modify | Remove `city: 'Medellín'` from mock `EventModel` (line 22) | low |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | modify | Remove `city:` from all mock `AiDescriptionRequest` / `EventModel` instances (lines 115, 143, 190, 220, 256, 292) | low |
| `test/features/events/presentation/detail/cubit/event_detail_cubit_test.dart` | modify | Remove `city: 'Medellín'` from mock `EventModel` (line 69) | low |
| `test/features/events/presentation/list/events_cubit_analytics_test.dart` | modify | Remove `city:` from all mock `EventModel` and `EventFilters` instances (lines 35, 63, 130, 144, 183) | low |
| `test/features/events/presentation/list/widgets/events_page_view_test.dart` | modify | Remove `city: 'Medellín'` from all `EventFilters(...)` instances (lines 86, 132, 157) | low |
| `test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart` | modify | **Eliminar el grupo AC-6 completo** (`group('AC-6: city == "" ...')` lines ~113-187). Ver nota abajo. | low |

**Nota sobre `event_form_auditor_tests_test.dart` AC-6:** Los dos tests del grupo AC-6 aseguran que `buildEventToSave()` y `buildDraftToSave()` producen `city == ''`. Al eliminar `city` de `EventModel`, estas aserciones (`event.city`, `draft!.city`) ya no compilan. El invariante que protegían — no leer `city` del formulario — deja de ser relevante porque el campo desaparece. **Decisión: eliminar el grupo AC-6 completo.** El resto del archivo de tests (otros grupos AC) no está afectado y debe permanecer.

---

## Contratos rideglory-api

No hay endpoints nuevos ni cambios de firma de endpoints. Los cambios son **eliminaciones** de campos existentes:

### `POST /events` — CreateEventDto (antes → después)

```diff
- city: string  (required)
```

### `GET /events` — EventFilterDto (antes → después)

```diff
- city?: string  (optional query param)
```

### `POST /ai/description` — AiDescriptionEventContextDto (antes → después)

```diff
- city: string  (required)
```

### Gemini prompt template (gemini.service.ts)

```diff
- - Ciudad: ${eventContext.city}
```

Solo eliminar la línea; no agregar `meetingPoint` al prompt (fuera de alcance).

---

## Datos/migraciones

Ver `analysis/MIGRATION_PLAN.md` para los comandos exactos.

**Resumen:**
- Una única migración Prisma: `remove_event_city`
- Solo local; no tocar staging/prod
- `npx prisma migrate dev --name remove_event_city` + `npx prisma generate` en `events-ms/`
- Rebuild contracts + pnpm install en events-ms y api-gateway **obligatorio** después de cambiar los DTOs de contratos

---

## Env

Sin variables de entorno nuevas ni eliminadas. `analysis/ENV_DELTA.md` no aplica para esta tarea.

---

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| build_runner falla post-edición de `event_dto.dart` | baja | alto | Usar `dart run build_runner build --delete-conflicting-outputs`; si en worktree fresco añadir `--force-jit` |
| Referencia a `city` olvidada en algún archivo no listado | media | alto | Después de implementar, correr `grep -rn "\.city" lib/features/ --include="*.dart" \| grep -v ".g.dart\|.freezed.dart"` y debe retornar vacío |
| `inscription_card.dart` no actualizado — no compila | **alta** | alto | Está en el change map; el feature `event_registration` usa `event.city` directamente en líneas ~190 y ~202; sin este cambio el proyecto no compila tras eliminar `EventModel.city` |
| Contracts rebuild omitido (MODULE_NOT_FOUND en runtime) | baja | alto | Ver `project_contracts_rebuild_gotcha.md`; correr `npm run build` en rideglory-contracts antes del `pnpm install` en MS afectados |
| Prisma client desactualizado después de migración | baja | alto | `npx prisma generate` debe correr DESPUÉS de `migrate dev` |
| `event_card_date_and_city.dart` eliminado pero referenciado en test | baja | med | Se confirmó con grep que no hay call-sites ni tests que lo referencien; eliminación segura |
| Tests de backend fallan si no se actualizan (`city` en mocks) | media | med | Ver change map — backend test files incluidos en el alcance |

---

## Orden de implementación

1. **Backend primero** — contratos y migración:
   a. Editar `rideglory-contracts` DTOs (B2, B3, B4)
   b. Rebuild contracts: `npm run build` + `pnpm install` en events-ms y api-gateway
   c. Editar `events-ms/prisma/schema.prisma` + migrar: `npx prisma migrate dev --name remove_event_city` + `npx prisma generate`
   d. Editar `events-ms/src/events/events.service.ts` (B5)
   e. Editar `api-gateway/src/ai/gemini.service.ts` (B6)
   f. Actualizar test files de backend
   g. Verificar: `tsc --noEmit` o `nest build` en events-ms y api-gateway

2. **Flutter domain layer**:
   a. `event_model.dart` — eliminar campo `city` (F1)
   b. `ai_description_request.dart` (F7)
   c. `event_repository.dart` (F5)
   d. `get_events_use_case.dart` (F6)
   e. `generate_event_description_use_case.dart` (F9)

3. **Flutter data layer**:
   a. `event_dto.dart` (F2)
   b. `ai_event_context_dto.dart` (F8)
   c. `event_service.dart` (F3)
   d. `event_repository_impl.dart` (F4)

4. **Flutter presentation layer — form**:
   a. `event_form_cubit.dart` — quitar `city: ''` (x2) en EventModel constructions
   b. `ai_description_chat_cubit.dart` — quitar param `city` de sendMessage/retryLastMessage
   c. `ai_description_chat_page.dart` — quitar `city:` call-sites
   d. `event_form_content.dart` — quitar `EventFormFields.city: event.city`
   e. `event_form_basic_info_section.dart` — quitar `AppCityAutocomplete` widget + local var

5. **Flutter presentation layer — list/cards**:
   a. `events_cubit.dart` — quitar city de `EventFilters`, `_fetchFn` signature, filtros locales
   b. `event_filters_bottom_sheet.dart` — quitar sección ciudad
   c. `event_card.dart` → `event.meetingPoint`
   d. `event_card_info_panel.dart` → `event.meetingPoint`
   e. `event_card_date_and_city.dart` — **eliminar archivo** (código muerto, sin call-sites)

6. **Flutter — event_registration (CRÍTICO — no compilará sin este paso)**:
   a. `inscription_card.dart` — eliminar bloque `if (event?.city != null)` (lines ~190-212)

7. **Flutter constants y l10n**:
   a. `event_form_fields.dart` — quitar `city`
   b. `event_filter_form_fields.dart` — quitar `city`
   c. `app_es.arb` — quitar 4 claves l10n

8. **Regenerar código Flutter**:
   - `dart run build_runner build --delete-conflicting-outputs`
   - `dart analyze lib/` — debe quedar en verde

9. **Tests Flutter** — actualizar todos los archivos listados en el change map de tests (incluye los 13 archivos; eliminar grupo AC-6 de `event_form_auditor_tests_test.dart`)

10. **Docs** — actualizar `docs/features/events.md`

---

## Superficie de regresión

- **Event form** (create y edit): `EventFormBasicInfoSection` pierde el campo city; el formulario debe validar y guardar sin ese campo. Verificar que `buildEventToSave()` y `buildDraftToSave()` no requieran city en el `EventModel` constructor.
- **Event cards list**: `EventCard` y `EventCardInfoPanel` ahora muestran `event.meetingPoint` en la fila de ubicación. El texto puede ser más largo que antes (meetingPoint es una dirección completa); `maxLines: 1 + overflow: ellipsis` ya está presente — sin riesgo visual.
- **Filtro de eventos**: la sección CIUDAD desaparece del bottom sheet; el recuento `_activeCount` no se ve afectado (solo sumaba types + difficulties). `EventFilters.hasFilters` ya no incluye city en su check.
- **Búsqueda local**: `_applyFiltersAndEmit()` ya no filtra por city en `_searchQuery`; si el usuario busca por texto, solo matchea `name`. Esto es intencional y aceptable.
- **AI description**: Gemini ya no recibe `city`; el contexto queda `title + eventType + difficulty? + startDate?`. Calidad de las sugerencias AI no se ve afectada materialmente.
- **event_registration feature**: `inscription_card.dart` consume `event.city` directamente (líneas ~190 y ~202). **Sí está afectado** — el bloque de ubicación debe eliminarse o compilará con error de campo inexistente. Se incluye en el change map (paso 6 del orden de implementación).
- **Tests de backend**: TC-4 (city-only filter) y TC-5 (combined filter con city) deben eliminarse o actualizarse en `events.service.spec.ts`.
- **Tests Flutter**: 13 archivos de test requieren actualización (ver change map de tests). El grupo AC-6 de `event_form_auditor_tests_test.dart` se elimina por completo.

---

## Fuera de alcance

- Renombrar `EventCardDateAndCity` widget a `EventCardDateAndLocation` — irrelevante; el widget se elimina por ser código muerto.
- Agregar `meetingPoint` al contexto enviado a Gemini — mejora futura, no pedida en esta tarea.
- Búsqueda de texto por `meetingPoint` en `updateSearchQuery` — mejora futura.
- Eliminar `AppCityAutocomplete` shared widget (`lib/shared/widgets/form/app_city_autocomplete.dart`) — el widget se usa en `event_registration` feature (registration wizard), por lo que **no debe eliminarse**. Solo se elimina su uso en events/form.
- Migrar staging/prod — requiere aprobación humana explícita.
- Mostrar `meetingPoint` en `inscription_card.dart` — el PRD no pide añadir este campo a la card de inscripción; solo eliminar el bloque de city.
