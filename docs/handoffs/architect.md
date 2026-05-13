# Architect handoff — Iteration 4

**Date:** 2026-05-13
**Status:** done

AI Event Cover Image Generation: full-stack feature wiring the existing "Generar portada con IA" button to a new backend endpoint that uses the existing ClaudeService (iter-3a pattern) to generate an Unsplash search query, then fetches a cover image and returns the URL to Flutter.

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|----------------|--------------|----------------------|
| events / form | New: `GetGenerateCoverUseCase` in `domain/use_cases/`. New: `EventCoverRepository` interface in `domain/repository/`. | New: `CoverGenerationDto` + `EventCoverService` (Retrofit `POST /events/generate-cover`) + `EventCoverRepositoryImpl`. | Refactor: `EventFormCubit` → extends `Cubit<EventFormState>` (freezed). New field: `ResultState<String> coverGenerationResult`. New method: `generateCover({title, eventType, city})`. Update `EventFormContent` to wire the existing `onGenerateWithAITap` callback. New: `CoverPreviewWidget` for 16:9 overlay. |

---

## API contracts (rideglory-api changes)

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|--------------|---------|--------|
| POST | `/events/generate-cover` | Firebase ID token (JWT bearer) | `{ title: string, eventType: string, city: string }` | 200 `{ imageUrl: string, source: "unsplash", query: string }` | 400 malformed body · 503 Claude or Unsplash failure |

**Implementation location:** `api-gateway/src/events/events.controller.ts` — add `@Post('generate-cover')` method. No microservice proxy needed; implement logic directly in `api-gateway` using `ClaudeService` (iter-3a pattern) and Axios/`axios` for Unsplash HTTP call.

**Unsplash call:** `GET https://api.unsplash.com/search/photos?query={query}&per_page=1&orientation=landscape` with `Authorization: Client-ID ${UNSPLASH_ACCESS_KEY}`.

**Claude prompt:** `"Generate a 3-5 word English search query for Unsplash to find a high-quality landscape photo for a motorcycle event. Event title: {title}. Event type: {eventType}. City: {city}. Return only the search query, nothing else."`

**Timeout:** 15 s on Unsplash call (Promise.race). If exceeded, throw `ServiceUnavailableException`.

---

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `CoverGenerationDto` | data | `lib/features/events/data/dto/cover_generation_dto.dart` | `@JsonSerializable()`. Fields: `imageUrl` (String), `source` (String), `query` (String). |
| `EventCoverRepository` | domain | `lib/features/events/domain/repository/event_cover_repository.dart` | Abstract. Single method: `Future<Either<DomainException, String>> generateCover({required String title, required String eventType, required String city})`. Returns the `imageUrl` only (domain-clean). |
| `GetGenerateCoverUseCase` | domain | `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` | `@injectable`. Delegates to `EventCoverRepository.generateCover()`. |
| `EventCoverService` | data | `lib/features/events/data/service/event_cover_service.dart` | Retrofit. `@POST('/events/generate-cover')`. Returns `Future<CoverGenerationDto>`. |
| `EventCoverRepositoryImpl` | data | `lib/features/events/data/repository/event_cover_repository_impl.dart` | `@Injectable(as: EventCoverRepository)`. Wraps `EventCoverService` with `executeService()`. Maps HTTP 503 to Spanish `DomainException`. Returns `Right(dto.imageUrl)`. |
| `EventFormState` | presentation | `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | `@freezed` class in same file as `EventFormCubit`. Fields: `ResultState<EventModel> saveResult`, `ResultState<String> coverGenerationResult`. |

---

## ADRs (architectural decisions)

### ADR-7 — EventFormCubit: split state into @freezed EventFormState
**Status:** Accepted.
**Context:** `EventFormCubit` previously extended `Cubit<ResultState<EventModel>>`, making it impossible to track cover generation state independently without clobbering form save state.
**Decision:** Introduce `@freezed EventFormState` with two `ResultState` fields (`saveResult`, `coverGenerationResult`). `EventFormCubit` now extends `Cubit<EventFormState>`.
**Consequence:** All existing `BlocBuilder<EventFormCubit, ResultState<EventModel>>` usages in `event_form_view.dart` and `event_form_page.dart` must be updated to use `state.saveResult`. Widget tests must be updated accordingly. `buildEventToSave()` logic is unchanged.

### ADR-8 — Cover generation lives in EventFormCubit, not FormImageCubit
**Status:** Accepted.
**Context:** `FormImageCubit` is a shared cubit for generic image picking. Cover URL from AI is event-specific and needs access to form field values (title, eventType, city).
**Decision:** `generateCover()` stays in `EventFormCubit`. On success, `EventFormCubit` updates `coverGenerationResult` to `data(imageUrl)`. The presentation layer then syncs this into `FormImageCubit` via `formImageCubit.setRemoteImageUrl(imageUrl)` — a new method to add to `FormImageCubit`.
**Consequence:** `FormImageCubit` needs one new method: `void setRemoteImageUrl(String url)` — emits `data(FormImageData(remoteImageUrl: url))`. This keeps `FormImageCubit` generic while allowing the cover generation result to be reflected in the image preview.

### ADR-9 — No new Flutter package additions for Iteration 4
**Status:** Accepted.
**Context:** `cached_network_image` is already a dependency (used in event list cards).
**Decision:** Use existing `CachedNetworkImage` for the preview. No new pub.dev packages needed. Loading overlay uses a `Stack` with a semi-transparent `CircularProgressIndicator` over the existing preview.

---

## New API route constant (Flutter)

Add to `lib/core/http/api_routes.dart`:
```dart
static const generateEventCover = '/events/generate-cover';
```

---

## Environment variables

| Variable | Repo | Description |
|----------|------|-------------|
| `UNSPLASH_ACCESS_KEY` | rideglory-api | Unsplash API access key. Add to `.env.example` and CI secrets. Never commit actual value. |

---

## Localization (l10n keys)

New keys in `lib/l10n/app_es.arb` (prefix `event_`):

| Key | Spanish value |
|-----|---------------|
| `event_coverGenerating` | "Generando portada..." |
| `event_coverGenerated` | "Portada generada" |
| `event_coverGenerateError` | "No pudimos generar la portada. Sube tu propia imagen." |
| `event_coverRegenerate` | "Regenerar" |
| `event_coverGeneratingOverlay` | "Generando con IA..." |

Note: `event_generateWithAI` already exists (used in `EventFormContent`).

---

## Risks and open questions

- **ClaudeService not implemented in iter-3a:** PO assumes ClaudeService exists from iter-3a. Backend verification shows no Claude/Anthropic files in `rideglory-api`. Backend agent must implement ClaudeService pattern (Anthropic Node.js SDK) as part of T-4-1 if it does not exist.
- **EventFormState freezed refactor regression:** Existing `event_form_page.dart` and `event_form_view.dart` use `BlocBuilder<EventFormCubit, ResultState<EventModel>>` — all must be updated to `EventFormState` and use `state.saveResult`. Existing tests must be updated.
- **FormImageCubit.setRemoteImageUrl coordination:** The presentation layer must call `formImageCubit.setRemoteImageUrl(imageUrl)` inside a `BlocListener` on `EventFormCubit` when `coverGenerationResult` transitions to `data(...)`.

---

## Next agent needs to know

- **Backend:** Implement `POST /events/generate-cover` in `api-gateway/src/events/events.controller.ts`. Add `ClaudeService` (Anthropic SDK) + Unsplash HTTP call (axios). Add `UNSPLASH_ACCESS_KEY` to `.env.example`. See `docs/handoffs/architect-for-backend.md`.
- **Frontend:** (1) Refactor `EventFormCubit` to `@freezed EventFormState`. (2) Add `GetGenerateCoverUseCase` + `EventCoverService` + `CoverGenerationDto` + `EventCoverRepositoryImpl`. (3) Add `setRemoteImageUrl()` to `FormImageCubit`. (4) Wire `onGenerateWithAITap` in `EventFormContent` to `EventFormCubit.generateCover()`. (5) Add `CoverPreviewWidget` with loading overlay. (6) Add 5 ARB keys. See `docs/handoffs/architect-for-frontend.md`.
- **QA:** Backend unit tests (happy + 4 error paths) + Flutter unit tests for use case + widget tests for all cover generation states. See `docs/handoffs/architect-for-qa.md`.
- **DevOps:** Add `UNSPLASH_ACCESS_KEY` to CI secrets. See `docs/handoffs/architect-for-devops.md`.

---

## Change log

- 2026-05-13 (iter-4): Full architect handoff. AI Event Cover Image Generation. Backend: new `POST /events/generate-cover` endpoint in api-gateway. Frontend: EventFormState freezed refactor + new use case/service/DTO + cover preview UI. ADR-7 (freezed state split), ADR-8 (generateCover in EventFormCubit), ADR-9 (no new packages). UNSPLASH_ACCESS_KEY env var. 5 l10n keys.
