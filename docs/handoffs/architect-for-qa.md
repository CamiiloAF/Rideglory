# Architect → QA handoff — Iteration 4

**Date:** 2026-05-13
**Iteration:** 4 — AI Event Cover Image Generation

---

## Test commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after EventFormState freezed refactor
dart analyze --no-summary                                   # must be zero violations
flutter test                                                # must be 100% green
flutter test test/features/events/                          # focused run

# Backend tests (run from rideglory-api/api-gateway/)
npm run test                                               # must pass
npm run lint                                               # must pass
```

---

## AC → test traceability

### US-4-3 (T-4-2) — Backend: `POST /events/generate-cover`

File: `api-gateway/test/events/generate-cover.spec.ts`

| AC | Test case | Expected |
|----|-----------|----------|
| AC-1 (happy path) | Claude returns query → Unsplash returns photo | HTTP 200 `{ imageUrl, source: 'unsplash', query }` |
| AC-5a (Claude fails) | Mock ClaudeService to throw | HTTP 503 |
| AC-5b (Unsplash fails) | Mock UnsplashService to throw | HTTP 503 |
| AC-6 (timeout) | Mock Unsplash to delay 16 s | HTTP 503 |
| AC-5c (malformed request) | Send body without `title` | HTTP 400 |

### US-4-4 (T-4-8) — `GetGenerateCoverUseCase` unit test

File: `test/features/events/domain/get_generate_cover_use_case_test.dart`

| AC | Test case | Expected |
|----|-----------|----------|
| AC-2 (happy path) | Mock `EventCoverRepository` returns `Right(imageUrl)` | Use case returns `Right('https://...')` |
| AC-8 (503 error) | Mock repository returns `Left(DomainException)` | Use case returns `Left(DomainException)` |

Mock: `class MockEventCoverRepository extends Mock implements EventCoverRepository`.

### US-4-1 + US-4-2 (T-4-9) — `EventFormPage` widget tests

File: `test/features/events/presentation/form/event_form_page_test.dart`

| AC | Test case | Verify |
|----|-----------|--------|
| US-4-1 AC-3 | Emit `coverGenerationResult = Loading` | Loading overlay visible over preview area; spinner present |
| US-4-1 AC-4 | Loading state | "Publicar" button remains enabled |
| US-4-1 AC-6 | Emit `coverGenerationResult = Data(imageUrl)` | Preview image visible |
| US-4-2 AC-1 | After `Data(imageUrl)` state | "Regenerar" button visible |
| US-4-2 AC-3 | Tap "Regenerar" → emit Loading | Overlay renders over existing preview (not blank) |
| US-4-2 AC-4 | Custom image selected | "Subir imagen propia" path available, no conflict |
| US-4-1 AC-7 | Emit `coverGenerationResult = Error` | Spanish SnackBar visible; form returns to idle |
| US-4-1 AC-8 | 16:9 container present | `AspectRatio(aspectRatio: 16/9)` found in widget tree |

Use `mockNetworkImages()` from `network_image_mock` when testing preview with image URL.

### Updated existing `EventFormCubit` tests (T-4-3)

After the `@freezed EventFormState` refactor:
- Update all existing `blocTest<EventFormCubit, ResultState<EventModel>>` to `blocTest<EventFormCubit, EventFormState>`.
- Assert on `state.saveResult` instead of top-level state.
- Add new blocTest group for `generateCover`:
  - `loading → data(imageUrl)` path
  - `loading → error(DomainException)` path
  - Form fields NOT cleared during cover generation (check that `saveResult` stays `initial` while `coverGenerationResult` is `loading`)

---

## QA gate (T-4-10)

1. `dart analyze --no-summary` → zero violations.
2. `flutter test` → 100% green; no skipped tests.
3. `npm run test` (api-gateway) → all 5 backend tests pass.
4. All 8 widget test cases for `EventFormPage` cover generation pass.
5. All `ResultState` cover generation branches (`initial`, `loading`, `data`, `error`) covered.
6. No hardcoded Spanish strings in new Flutter code.

> Full detail: docs/handoffs/architect.md
