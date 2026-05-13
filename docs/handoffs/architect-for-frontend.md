# Architect → Frontend handoff — Iteration 4

**Date:** 2026-05-13
**Iteration:** 4 — AI Event Cover Image Generation

---

## Focus stories: US-4-1, US-4-2, US-4-4 (tasks T-4-3 through T-4-7)

---

## New files to create

```
lib/features/events/
  domain/
    repository/
      event_cover_repository.dart          ← NEW (abstract interface)
    use_cases/
      get_generate_cover_use_case.dart     ← NEW
  data/
    dto/
      cover_generation_dto.dart            ← NEW (+ .g.dart via build_runner)
    service/
      event_cover_service.dart             ← NEW (Retrofit, + .g.dart)
    repository/
      event_cover_repository_impl.dart     ← NEW
  presentation/
    form/
      cubit/
        event_form_cubit.dart              ← REFACTOR (add freezed EventFormState)
      widgets/
        cover_preview_widget.dart          ← NEW
```

---

## Domain layer

**`EventCoverRepository`** (abstract):
```dart
abstract class EventCoverRepository {
  Future<Either<DomainException, String>> generateCover({
    required String title,
    required String eventType,
    required String city,
  });
}
```

**`GetGenerateCoverUseCase`** (`@injectable`):
- Single `call({required title, required eventType, required city})`
- Delegates to `EventCoverRepository.generateCover(...)`

---

## Data layer

**`CoverGenerationDto`** (`@JsonSerializable()`):
```dart
class CoverGenerationDto {
  final String imageUrl;
  final String source;
  final String query;
}
```

**`EventCoverService`** (Retrofit `@singleton`):
```dart
@POST('/events/generate-cover')
Future<CoverGenerationDto> generateCover(@Body() Map<String, dynamic> body);
```

**`EventCoverRepositoryImpl`** (`@Injectable(as: EventCoverRepository)`):
- Wraps `EventCoverService` with `executeService()`
- Maps HTTP 503 to `DomainException(message: context.l10n.event_coverGenerateError)` — Note: error mapping happens in the repository using the pre-defined Spanish message string (no BuildContext here; hardcode the Spanish string directly matching the ARB value)
- Returns `Right(dto.imageUrl)` on success

**Add to `lib/core/http/api_routes.dart`**:
```dart
static const generateEventCover = '/events/generate-cover';
```

---

## Presentation layer: EventFormState refactor (ADR-7)

Replace `EventFormCubit extends Cubit<ResultState<EventModel>>` with:

```dart
@freezed
class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(ResultState<EventModel>.initial()) ResultState<EventModel> saveResult,
    @Default(ResultState<String>.initial()) ResultState<String> coverGenerationResult,
  }) = _EventFormState;
}

@injectable
class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit(...) : super(const EventFormState());

  Future<void> generateCover({
    required String title,
    required String eventType,
    required String city,
  }) async {
    emit(state.copyWith(coverGenerationResult: const ResultState.loading()));
    final result = await _getGenerateCoverUseCase(title: title, eventType: eventType, city: city);
    result.fold(
      (error) => emit(state.copyWith(coverGenerationResult: ResultState.error(error: error))),
      (imageUrl) => emit(state.copyWith(coverGenerationResult: ResultState.data(data: imageUrl))),
    );
  }
  // saveEvent() now emits state.copyWith(saveResult: ...)
}
```

Update all `BlocBuilder<EventFormCubit, ResultState<EventModel>>` usages to use `state.saveResult`.

---

## FormImageCubit: add one method

```dart
void setRemoteImageUrl(String url) {
  emit(ResultState.data(data: FormImageData(remoteImageUrl: url)));
}
```

In `EventFormContent`, add a `BlocListener<EventFormCubit, EventFormState>` that calls `formImageCubit.setRemoteImageUrl(imageUrl)` when `state.coverGenerationResult` transitions to `Data`.

---

## CoverPreviewWidget

- `AspectRatio(aspectRatio: 16 / 9)`
- Uses `CachedNetworkImage` when imageUrl available
- Loading overlay: `Stack` with semi-transparent black `Container` + `CircularProgressIndicator` centered — shown when `coverGenerationResult` is `Loading`
- Do NOT blank the preview during regeneration; overlay on top of existing image
- Shows "Regenerar" `AppTextButton` below image when state is `Data`

---

## Wire the AI button

In `EventFormContent`, pass `onGenerateWithAITap` to `FormImageSection`:
```dart
onGenerateWithAITap: () {
  final formState = cubit.formKey.currentState?.value;
  cubit.generateCover(
    title: formState?[EventFormFields.name] as String? ?? '',
    eventType: (formState?[EventFormFields.eventType] as EventType?)?.name ?? '',
    city: formState?[EventFormFields.city] as String? ?? '',
  );
},
```

---

## ARB keys to add

| Key | Spanish value |
|-----|---------------|
| `event_coverGenerating` | `"Generando portada..."` |
| `event_coverGenerated` | `"Portada generada"` |
| `event_coverGenerateError` | `"No pudimos generar la portada. Sube tu propia imagen."` |
| `event_coverRegenerate` | `"Regenerar"` |
| `event_coverGeneratingOverlay` | `"Generando con IA..."` |

---

## Gates before pushing

- `dart run build_runner build --delete-conflicting-outputs` succeeds
- `dart analyze` zero violations
- `flutter test` green
- No `BuildContext` in data layer

> Full detail: docs/handoffs/architect.md
