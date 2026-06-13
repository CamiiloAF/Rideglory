# Handoff: Frontend Agent — remove-city-field

**Fecha:** 2026-06-11  
**Estado:** COMPLETADO — 806/806 tests passing, `dart analyze lib/` limpio

---

## Resumen

Se eliminó el campo `city` de `EventModel` y todos sus consumidores en `lib/` y `test/`. El campo era redundante con `meetingPoint`; las cards de eventos ahora muestran `meetingPoint` en su lugar.

---

## Archivos modificados

### Domain
- `lib/features/events/domain/model/event_model.dart` — Eliminado campo `final String city`, param constructor y copyWith
- `lib/features/events/domain/model/ai_description_request.dart` — Eliminado `required this.city`
- `lib/features/events/domain/repository/event_repository.dart` — Eliminado `String? city` de `getEvents()`
- `lib/features/events/domain/use_cases/get_events_use_case.dart` — Eliminado param `city`
- `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` — Eliminado `city: request.city`

### Data
- `lib/features/events/data/dto/event_dto.dart` — Eliminado `required super.city` y `city: city` en toJson
- `lib/features/events/data/dto/ai_event_context_dto.dart` — Eliminado campo `city` y `city: request.city`
- `lib/features/events/data/service/event_service.dart` — Eliminado `@Query('city') String? city`
- `lib/features/events/data/repository/event_repository_impl.dart` — Eliminado param y arg `city`

### Presentation — Form
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — Eliminado `city: ''` de buildEventToSave/buildDraftToSave
- `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` — Eliminado `required String city` de sendMessage/retryLastMessage
- `lib/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart` — Eliminado `city: eventContext.city`
- `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` — Eliminado AppCityAutocomplete y `city: city` en _buildEventContext
- `lib/features/events/presentation/form/widgets/event_form_content.dart` — Eliminado `EventFormFields.city: event.city`

### Presentation — List/Cards
- `lib/features/events/presentation/list/events_cubit.dart` — Eliminado `String? city` de EventFilters, hasFilters, copyWith, _fetchFn y _applyFiltersAndEmit
- `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` — Eliminado sección ciudad (FilterSectionLabel + AppCityAutocomplete)
- `lib/features/events/presentation/list/widgets/event_card.dart` — `event.city` → `event.meetingPoint`
- `lib/features/events/presentation/list/widgets/event_card_info_panel.dart` — `event.city` → `event.meetingPoint`
- `lib/features/events/presentation/list/widgets/event_card_date_and_city.dart` — **ELIMINADO** (dead code)

### Event Registration
- `lib/features/event_registration/presentation/widgets/inscription_card.dart` — Eliminado bloque `if (event?.city != null)` completo

### Constants & L10n
- `lib/features/events/constants/event_form_fields.dart` — Eliminado `static const String city = 'city'`
- `lib/features/events/constants/event_filter_form_fields.dart` — Eliminado `static const String city = 'city'`
- `lib/l10n/app_es.arb` — Eliminadas keys: `event_eventCity`, `event_eventCityHint`, `event_cityRequired`, `event_filterByCity`

### Tests
- `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` — Eliminados `city:` args
- `test/features/events/data/repository/ai_description_repository_impl_test.dart` — Eliminado `city: 'Bogotá'`
- `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` — Eliminado `city: 'Medellín'`
- `test/features/events/presentation/cubit/events_filter_cubit_test.dart` — Eliminados TC-2-3/TC-2-10 de city, params city en mocks
- `test/features/home/presentation/cubit/home_cubit_test.dart` — Eliminado `city: 'Medellín'`
- `test/features/event_registration/presentation/cubit/my_registrations_cubit_test.dart` — Eliminado `city: 'Medellín'`
- `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` — Eliminado `city: 'Medellín'`
- `test/features/events/presentation/detail/cubit/event_detail_cubit_test.dart` — Eliminado `city: 'Medellín'`
- `test/features/events/presentation/list/events_cubit_analytics_test.dart` — Eliminados `city: null` y `city: 'Bogotá'`
- `test/features/events/presentation/list/widgets/events_page_view_test.dart` — `EventFilters(city: 'Medellín')` → `EventFilters(types: {EventType.tourism})`
- `test/features/events/presentation/form/cubit/event_form_auditor_tests_test.dart` — Eliminado grupo AC-6 completo (testeaba que `city == ''`)
- `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` — Eliminado `city: any(named: 'city')` del mock y `expect(ctx.city, ...)` del test

### Docs
- `docs/features/events.md` — Eliminado campo `city` del modelo, `EventFilters`, firmas de repositorio, tabla API endpoints, body `/ai/description`, sección form

---

## Código generado (build_runner)

`dart run build_runner build --delete-conflicting-outputs` ejecutado exitosamente — 42 outputs escritos.

---

## Resultado final

```
dart analyze lib/   → No issues found
flutter test        → 806/806 passed
```

---

## Notas para el auditor

- `AppCityAutocomplete` NO fue eliminado — sigue siendo usado en el wizard de event_registration. Solo se eliminó su uso en el form de eventos.
- `event_card_date_and_city.dart` fue eliminado (confirmado como dead code por grep vacío).
- Las cards ahora muestran `meetingPoint` donde antes mostraban `city`.
- El backend API `/ai/description` sigue recibiendo el campo `city` en su body (contrato del backend no modificado aquí). La eliminación del campo en el frontend DTO (`AiEventContextDto`) significa que el campo ya no se envía al backend. Coordinar con el equipo de backend si el campo debe eliminarse también del contrato del API.
