# Flutter Dev handoff — Iteration 4

**Date:** 2026-05-13
**Status:** done

## Screens / features delivered

| Screen / Cubit | Route / path | Status | Notes |
|----------------|--------------|--------|-------|
| EventFormCubit | lib/features/events/presentation/form/cubit/event_form_cubit.dart | Refactored | @freezed EventFormState with saveResult + coverGenerationResult |
| EventFormView | lib/features/events/presentation/form/widgets/event_form_view.dart | Updated | BlocConsumer for new EventFormState; handles cover error SnackBar + FormImageCubit bridge |
| EventFormContent | lib/features/events/presentation/form/widgets/event_form_content.dart | Updated | Wires AI button; switches between FormImageSection and CoverPreviewWidget |
| CoverPreviewWidget | lib/features/events/presentation/form/widgets/cover_preview_widget.dart | New | 4 states: initial (FormImageSection), loading (spinner overlay), data (image + Regenerar), error (SnackBar then reset) |

## Layer changes

### Domain
- `lib/features/events/domain/repository/event_cover_repository.dart` (new — abstract interface)
- `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` (new — @injectable, delegates to EventCoverRepository)

### Data
- `lib/features/events/data/dto/cover_generation_dto.dart` (new — @JsonSerializable, fields: imageUrl, source, query)
- `lib/features/events/data/dto/cover_generation_dto.g.dart` (generated)
- `lib/features/events/data/service/event_cover_service.dart` (new — @singleton Retrofit, POST /events/generate-cover)
- `lib/features/events/data/service/event_cover_service.g.dart` (generated)
- `lib/features/events/data/repository/event_cover_repository_impl.dart` (new — @Injectable(as: EventCoverRepository), wraps executeService())
- `lib/core/http/api_routes.dart` — added `generateEventCover = '/events/generate-cover'`

### Presentation
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` — refactored to @freezed EventFormState
- `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` (generated)
- `lib/features/events/presentation/form/widgets/event_form_view.dart` — updated BlocConsumer
- `lib/features/events/presentation/form/widgets/event_form_content.dart` — wires AI button
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` (new)

### Shared
- `lib/shared/cubits/form_image_cubit.dart` — added `setRemoteImageUrl(String url)` method

### l10n
- `lib/l10n/app_es.arb` — 5 new keys added
- `lib/l10n/app_localizations_es.dart` — regenerated via flutter gen-l10n
- `lib/l10n/app_localizations.dart` — regenerated

## DI registration

All new classes use `@injectable` / `@singleton` / `@Injectable(as:...)` annotations and were picked up by `build_runner` automatically in `injection.config.dart`:
- `EventCoverService` → singleton
- `EventCoverRepositoryImpl` → factory bound to `EventCoverRepository`
- `GetGenerateCoverUseCase` → factory
- `EventFormCubit` → factory (now takes 5 arguments, 5th is `GetGenerateCoverUseCase`)

## API integration

- New Retrofit endpoint: `POST /events/generate-cover` via `EventCoverService`
- Request body: `{ title, eventType, city }` (Map<String, dynamic>)
- Response: `CoverGenerationDto { imageUrl, source, query }`
- On 503 / network error: `executeService()` maps to `DomainException`; Spanish SnackBar displayed in `EventFormView`

## l10n keys added

| Key | Value |
|-----|-------|
| `event_coverGenerating` | "Generando portada..." |
| `event_coverGenerated` | "Portada generada" |
| `event_coverGenerateError` | "No pudimos generar la portada. Sube tu propia imagen." |
| `event_coverRegenerate` | "Regenerar" |
| `event_coverGeneratingOverlay` | "Generando con IA..." |

## State architecture

`EventFormState` (freezed):
```dart
@freezed
abstract class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(ResultState<EventModel>.initial()) ResultState<EventModel> saveResult,
    @Default(ResultState<String>.initial()) ResultState<String> coverGenerationResult,
  }) = _EventFormState;
}
```

`EventFormCubit.generateCover()` emits loading → data(imageUrl) | error(DomainException).
`EventFormView` `BlocListener` bridges `coverGenerationResult` data to `FormImageCubit.setRemoteImageUrl()`.
Error in `coverGenerationResult` triggers SnackBar + `resetCoverGeneration()` (back to initial).

## Test results

- `dart run build_runner build --delete-conflicting-outputs` — success, 127 outputs
- `dart analyze` — 0 errors, 0 warnings (34 pre-existing info items in existing shared widgets, untouched)
- `flutter test` — 5/5 pass (existing tests unbroken)

## Known gaps / QA notes

- Widget tests for CoverPreviewWidget all 4 states (idle, loading, preview, error) are for QA phase (T-4-9)
- Unit tests for GetGenerateCoverUseCase (happy path + error 503) are for QA phase (T-4-8)
- The form allows submission with remoteCoverImageUrl (AI-generated) — `saveEvent()` now accepts optional `remoteCoverImageUrl` param alongside `localCoverImagePath`

## Change log

- 2026-05-13 (iter-4): Initial frontend handoff. EventFormCubit refactored to @freezed EventFormState. GetGenerateCoverUseCase + EventCoverService + CoverGenerationDto + EventCoverRepositoryImpl implemented. CoverPreviewWidget created. EventFormContent wires AI button. EventFormView BlocConsumer updated. 5 l10n keys added. dart analyze 0 errors. flutter test 5/5.
