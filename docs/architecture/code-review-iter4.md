# Code Review — Iteration 4

> Reviewer: tech_lead
> Date: 2026-05-13
> PR: #11 — feat(iter-4): AI event cover image generation

## Findings

| File | Issue | Severity | Fix | Deferred? |
|------|-------|----------|-----|-----------|
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:38` | `prefer_const_constructors` — `Right(imageUrl)` missing `const` | Blocking | Changed to `const Right(imageUrl)` | No — fixed inline |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:48` | `prefer_const_constructors` — `Right(imageUrl)` missing `const` (expect call) | Blocking | Changed to `const Right(imageUrl)` | No — fixed inline |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:64` | `prefer_const_constructors` — `DomainException(...)` missing `const` | Blocking | Changed to `const DomainException(...)` | No — fixed inline |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:73` | `prefer_const_constructors` — `Left(exception)` missing `const` | Blocking | Changed to `const Left(exception)` | No — fixed inline |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:83` | `prefer_const_constructors` — `Left(exception)` missing `const` (expect call) | Blocking | Changed to `const Left(exception)` | No — fixed inline |
| `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` | `_PlaceholderView` private widget in same file as `CoverPreviewWidget` — minor one-widget-per-file deviation | Non-blocking | Extract to `cover_placeholder_view.dart` if widget grows | Yes — deferred |
| `lib/features/events/data/repository/event_cover_repository_impl.dart:36` | Hardcoded Spanish fallback `'No pudimos generar la portada. Sube tu propia imagen.'` when `error.message` is empty | Note | Accepted — matches ARB value; data layer cannot use `BuildContext` | N/A — accepted pattern |

## Deferred items

- **`_PlaceholderView` extraction** (`cover_preview_widget.dart`): The private `_PlaceholderView` widget (30 lines) lives alongside `CoverPreviewWidget` in the same file. This technically violates the one-widget-per-file rule. Given its small size and that it is never externally referenced, extraction was deferred. If `_PlaceholderView` grows beyond 50 lines or acquires state, extract to `cover_placeholder_view.dart`.
- **`withOpacity` → `.withValues()`** in 34 locations in `lib/shared/widgets/` — pre-existing from before iter-4. Batch fix in a dedicated refactor pass.

## Architecture health summary

- **Domain layer is clean**: `EventCoverRepository` (interface) and `GetGenerateCoverUseCase` import only `dartz` and `injectable` — no Flutter, no Retrofit, no HTTP.
- **Data layer is clean**: `EventCoverRepositoryImpl` uses `executeService()` correctly; no `BuildContext` imported; `CoverGenerationDto` stays in the data layer and only `imageUrl` (a `String`) crosses into domain.
- **Presentation layer is clean**: `EventFormCubit` emits only `EventFormState` containing `ResultState<EventModel>` and `ResultState<String>` — never a DTO. `CoverPreviewWidget` receives a `ResultState<String>` and a nullable `String?` imageUrl — pure domain types.
- **State management follows standards**: `EventFormState` uses `@freezed` with two independent `ResultState` fields per ADR-7 and the coding-standards cubit rule; no boolean loading/error flags anywhere.
- **Localization is complete**: All 5 new user-visible strings (`event_coverGenerating`, `event_coverGenerated`, `event_coverGenerateError`, `event_coverRegenerate`, `event_coverGeneratingOverlay`) are in `app_es.arb` with `event_cover` prefix; all consumed via `context.l10n.*` in widgets.
