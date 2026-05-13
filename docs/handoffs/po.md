# PO handoff — Iteration 4

**Date:** 2026-05-13
**Status:** scope defined

---

## Iteration goal

Wire the existing "Generar portada con IA" button in the event creation form to a backend endpoint that uses Claude Haiku to generate a search query and Unsplash to return a relevant cover image, so organizers can publish visually rich events without manual design work.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
|----|-------|---------------------|---------------|
| US-4-1 | As an event organizer filling out the event creation form, I want to tap "Generar portada con IA" and see a loading overlay while the app fetches a cover image based on the event title, type, and city, so that my event has an attractive visual without manual design work. | (1) The "Generar portada con IA" button exists in `EventFormPage` (UI entry point already implemented). (2) Tapping the button calls `EventFormCubit.generateCover(title, eventType, city)`. (3) While generation is in progress, a loading overlay (shimmer or low-opacity spinner) renders on the cover preview area (not a blank state). (4) Form "Publicar" button remains enabled during generation. (5) Backend receives `POST /events/generate-cover` with `{ title, eventType, city }` and returns `{ imageUrl, source: "unsplash", query }` on success. (6) On success, `EventFormCubit` emits `data(imageUrl)` and the preview updates with the fetched image. (7) On failure (503, network error), `EventFormCubit` emits `error(DomainException)`, a Spanish error SnackBar displays ("No pudimos generar la portada. Sube tu propia imagen."), and form returns to idle state. (8) The cover preview container has a fixed 16:9 aspect ratio (matching event list card) and uses `CachedNetworkImage` with `BoxFit.cover`. (9) All new UI copy uses `context.l10n.<key>` from `app_es.arb` (prefix `event_`). (10) `dart analyze` passes with zero violations; `flutter test` passes with 100% green tests. | frontend |
| US-4-2 | As an organizer, after the cover is generated, I want to regenerate the image, accept it, or upload my own image, so that I stay in control of the event's visual presentation. | (1) After cover is generated and previewed, a "Regenerar" button is visible on the preview card. (2) Tapping "Regenerar" calls `EventFormCubit.generateCover(...)` again with the same title, type, and city. (3) While regenerating, a loading overlay appears over the **existing** preview image (not a blank state). (4) The "Subir imagen propia" button remains available at all times and does not conflict with AI generation. (5) Selecting a custom image replaces the generated URL in `EventFormState` without error. (6) The form can be submitted with: a generated AI image, a custom uploaded image, or no cover image (optional). (7) All three image sources coexist peacefully — no mode confusion. (8) Widget tests verify: idle state (button enabled), loading state (overlay visible, spinner), preview shown (image visible, regenerate button enabled), regenerate while preview visible (overlay over existing image, not blank). (9) `dart analyze` passes with zero violations; `flutter test` passes with 100% green tests. | frontend |
| US-4-3 | As the dev team, I want the backend to accept event metadata, generate a search query via Claude Haiku, fetch a photo from Unsplash, and return the image URL to the Flutter app, so that the AI cover generation is end-to-end functional. | (1) `POST /events/generate-cover` in `api-gateway` accepts `{ title, eventType, city }`. (2) Uses existing `ClaudeService` (Iter 3a) to prompt Claude Haiku for 3–5 word English search query. (3) Calls `GET /search/photos?query={query}&per_page=1&orientation=landscape` on Unsplash API. (4) Returns HTTP 200 with `{ imageUrl, source: "unsplash", query }`. (5) Error handling: Claude fails or Unsplash fails → HTTP 503 with error message. Malformed request → HTTP 400. (6) 15-second timeout on Unsplash API call — if exceeded, return 503. (7) `UNSPLASH_ACCESS_KEY` in `.env.example` and CI secrets (never committed). (8) Unit tests: happy path (Claude query → Unsplash photo → URL), Claude fails (503), Unsplash fails (503), timeout (503), malformed request (400). (9) `npm run test` passes with 100% coverage; `npm run lint` passes with zero violations. | backend |
| US-4-4 | As the dev team, I want `EventFormCubit` to track the cover generation state separately from the event form fields, so that the multi-step upload flow can emit independent states without losing existing form data. | (1) `EventFormCubit` state refactored to `@freezed EventFormState` class with: all existing form field state preserved, new field `ResultState<String> coverGenerationResult` (String = generated image URL). (2) `EventFormCubit.generateCover({required title, eventType, city})` method exists. (3) On call: emit `loading()`, call backend, on success emit `data(imageUrl)`, on error emit `error(DomainException)`. (4) Form fields never cleared during generation — existing data preserved. (5) `GetGenerateCoverUseCase` in `lib/features/events/domain/use_cases/`. (6) `EventCoverService` (Retrofit) in `lib/features/events/data/service/` with `POST /events/generate-cover` method. (7) `CoverGenerationDto` in `lib/features/events/data/dto/` with `@JsonSerializable()`: `imageUrl, source, query`. (8) Error mapping: HTTP 503 → `DomainException` with Spanish message. (9) `dart run build_runner build` runs cleanly after refactor. (10) Existing widget tests updated to reflect new `EventFormState`. (11) `dart analyze` passes with zero violations; `flutter test` passes with 100% green tests. | frontend |

---

## Assumptions and open questions

- **Iteration 3a complete:** The backend ClaudeService is implemented and tested in Iteration 3a. The Anthropic SDK (Node.js) is integrated and working. This iteration reuses that pattern and adds a new endpoint in `api-gateway`.
- **EventFormCubit already exists:** The event creation form and its cubit are already implemented (from earlier iterations). Refactoring to a `@freezed EventFormState` is a state-machine upgrade, not a full rewrite.
- **Unsplash free tier sufficient:** The free Unsplash API tier allows 50 requests/hour. For pilot usage, this is adequate. If exceeded, the endpoint returns 503 gracefully.
- **go_router `extra`-based navigation continues to work:** The existing event form submission logic and navigation are unchanged. The new `coverGenerationResult` field in the cubit state is orthogonal to form submission.
- **16:9 aspect ratio matches event list cards:** Existing event list item cards use 16:9 aspect ratio for their cover images. The form preview uses the same ratio for visual consistency.
- **No Pencil gate for Iteration 4:** Unlike Iteration 3b (SOAT UI), there is no hard dependency on Pencil design screens. The cover generation is a button + preview UI — design specs are documented in this PO. Design can optionally add a reference in `pencil-new.pen`, but it is not a blocker.

---

## Out of scope (this iteration)

- **Cover image caching:** Generated images are not locally cached. Fresh generation on every form open. Caching deferred to v2.
- **Alternative image sources:** Only Unsplash in v1. Other photo APIs (Pexels, Pixabay) deferred.
- **User-facing Claude prompt refinement:** The prompt is fixed. Future A/B testing of different prompts deferred.
- **Exif metadata / photo credits:** Generated images are not inspected for credits or license. Unsplash credits not displayed in the app.

---

## Task breakdown

| Task ID | Title | Agent | Story | Notes |
|---------|-------|-------|-------|-------|
| T-4-1 | Backend: implement `POST /events/generate-cover` endpoint (Claude + Unsplash) | backend | US-4-3 | Arch contract defines DTO shape; ClaudeService reuse from iter-3a |
| T-4-2 | Backend: unit tests for cover endpoint (happy path + 3 error paths) | qa | US-4-3 | Tests must cover 200, 503, 400 responses |
| T-4-3 | Frontend: refactor `EventFormCubit` to `@freezed EventFormState` with `coverGenerationResult` field | frontend | US-4-4 | Preserve all existing form fields; run build_runner after |
| T-4-4 | Frontend: implement `GetGenerateCoverUseCase`, `EventCoverService`, `CoverGenerationDto` | frontend | US-4-4 | Retrofit + json_serializable code generation |
| T-4-5 | Frontend: wire "Generar portada con IA" button to `EventFormCubit.generateCover()` | frontend | US-4-1, US-4-2 | Loading overlay on preview, spinner, regenerate button, custom image flow |
| T-4-6 | Frontend: cover preview UI (16:9 aspect ratio, CachedNetworkImage, loading overlay) | frontend | US-4-1 | Do not blank preview during regenerate — overlay on top |
| T-4-7 | Frontend: add ARB keys for cover generation UI copy | frontend | US-4-1, US-4-2 | Minimum 5 keys; prefix `event_` |
| T-4-8 | Frontend: unit tests for `GetGenerateCoverUseCase` (happy path + error path 503) | qa | US-4-4 | Mock the backend; verify DTO mapping if applicable |
| T-4-9 | Frontend: widget tests for `EventFormPage` cover generation (all states) | qa | US-4-1, US-4-2 | Button states, overlay, custom image flow |
| T-4-10 | QA gate: verify all acceptance criteria, dart analyze + flutter test pass | qa | all | Gate story |

---

## Next agent needs to know

- **architect:** Review this PO handoff and confirm technical feasibility. Produce architecture contracts: (1) Backend DTO shape for `POST /events/generate-cover` request/response. (2) Frontend `EventFormState` freezed class structure, use case interface, and service interface. Document any ADRs or diagram updates needed. Hand off to backend, frontend, and qa agents.
- **backend:** Your deliverable is `POST /events/generate-cover` endpoint in `api-gateway`. Accept `{ title, eventType, city }`, use the existing `ClaudeService` to generate an Unsplash search query, fetch a photo from Unsplash API, and return `{ imageUrl, source: "unsplash", query }`. Handle errors gracefully (503 on failure). Unit tests required for happy path and all error cases. See US-4-3 acceptance criteria for full spec.
- **frontend:** Your deliverables are: (1) Refactor `EventFormCubit` state to `@freezed EventFormState` with `ResultState<String> coverGenerationResult`. (2) Implement `GetGenerateCoverUseCase`, `EventCoverService`, `CoverGenerationDto`. (3) Wire the "Generar portada con IA" button to `EventFormCubit.generateCover()`. (4) Build the cover preview UI with 16:9 aspect ratio, loading overlay (not blank state), and regenerate button. (5) Add ARB keys for all new UI copy (prefix `event_`). See US-4-1, US-4-2, US-4-4 for full specs. Existing EventFormPage tests must be updated to reflect the new state structure.
- **qa:** Your deliverables are: (1) Backend unit tests for all 5 acceptance criteria of US-4-3 (happy path + 4 error paths). (2) Frontend unit tests for `GetGenerateCoverUseCase`. (3) Widget tests for the cover generation UI (all states per US-4-1 and US-4-2). (4) QA gate: verify all acceptance criteria pass, `dart analyze` and `flutter test` pass with 100% green, no regressions. See T-4-2, T-4-8, T-4-9, T-4-10 for task breakdown.

---

## Change log

- 2026-05-13: PO handoff for Iteration 4. Iteration 4 scopes AI Event Cover Image Generation. 4 user stories defined (US-4-1 through US-4-4). Full-stack feature: backend endpoint (Claude + Unsplash), frontend cubit refactor + UI, unit + widget + backend tests. Depends on Iteration 3a (ClaudeService pattern).
