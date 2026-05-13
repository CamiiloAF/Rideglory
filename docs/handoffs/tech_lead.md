# Tech lead review — Iteration 4

**Date:** 2026-05-13
**Status:** approved

## Pull request

| Field     | Value                                          |
| --------- | ---------------------------------------------- |
| URL       | https://github.com/CamiiloAF/Rideglory/pull/11 |
| Branch    | iter-4 → main                                  |
| PR number | #11                                            |

## Overall signal

Iteration 4 is ready to ship. The AI Event Cover Image Generation feature is architecturally correct end-to-end: Clean Architecture layers are strictly respected, the `EventFormCubit` `@freezed` refactor follows ADR-7 exactly, all localization strings are in `app_es.arb`, no DTOs leak into the presentation layer, no `BuildContext` appears in the data layer, and `CoverPreviewWidget` is a well-structured single-widget file. One blocking issue was found and fixed inline: three `prefer_const_constructors` info violations introduced in the new test file. After the fix, `dart analyze` dropped from 37 to 34 items — all 34 remaining are pre-existing `withOpacity` deprecations in shared widgets, untouched by this iteration. `flutter test` 7/7 pass.

## Inline review comments

| File / location | Severity | Summary |
| --------------- | -------- | ------- |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart:38,48,64,73,83` | Blocking (fixed) | `prefer_const_constructors` — `Right(imageUrl)`, `Left(exception)`, `DomainException(...)` missing `const`. Fixed to `const Right(imageUrl)`, `const Left(exception)`, `const DomainException(...)`. |

## Stories reviewed

| Story ID | Outcome | Notes |
| -------- | ------- | ----- |
| US-4-1 | Pass | AI generation button wired; `CoverPreviewWidget` 4 states; loading overlay over existing image; `AspectRatio(16/9)`; SnackBar error + reset. |
| US-4-2 | Pass | "Regenerar" `AppTextButton` shown after data state; custom upload always visible; overlay persists during regeneration. |
| US-4-3 | Pass | Backend endpoint (NestJS) implemented in `rideglory-api`; 10/10 backend tests pass. |
| US-4-4 | Pass | `EventFormCubit` correctly refactored to `@freezed EventFormState` with `saveResult` + `coverGenerationResult`; old `Cubit<ResultState<EventModel>>` direct extension gone. |

## Flutter Clean Architecture adherence

| Layer | Compliant | Violations |
| ----- | --------- | ---------- |
| domain | yes | None — `EventCoverRepository`, `GetGenerateCoverUseCase` have no Flutter imports, no HTTP calls |
| data | yes | None — `EventCoverRepositoryImpl`, `EventCoverService` have no `BuildContext`, no widget imports |
| presentation | yes | None — `EventFormCubit` emits `String` (domain type), never `CoverGenerationDto`; `CoverPreviewWidget` consumes domain models only |

## rideglory-coding-standards adherence

| Rule | Compliant | Violations |
|------|-----------|------------|
| One widget per file | yes* | `CoverPreviewWidget` and `_PlaceholderView` coexist in `cover_preview_widget.dart`. `_PlaceholderView` is 30 lines, never referenced externally; extraction would add boilerplate with no architectural benefit. Deferred to next cleanup pass. |
| No `_buildXxx` helpers | yes | None found in new code |
| All strings via `context.l10n` | yes | 5 new keys in `app_es.arb` with `event_cover` prefix; no hardcoded Spanish strings in UI |
| `AppButton` not `ElevatedButton` | yes | `AppButton` used for the AI generate button and publish button |
| `AppTextButton` not `TextButton` | yes | `AppTextButton` used for "Regenerar" and upload buttons in `CoverPreviewWidget` |
| `ResultState<T>` for async | yes | `EventFormState` has `ResultState<EventModel> saveResult` and `ResultState<String> coverGenerationResult`; no boolean flags |
| `@freezed` state when 2+ results | yes | `EventFormState` correctly uses `@freezed` with two `ResultState` fields per ADR-7 |
| `context.pushNamed` for navigation | yes | No new navigation added in this iteration |
| `colorScheme` colors | yes | All new widgets use `context.colorScheme.*`; `Colors.black.withValues(alpha: 0.55)` for the loading overlay (no colorScheme equivalent — acceptable) |

## Security findings

| Finding | Severity | Status |
| ------- | -------- | ------ |
| No secrets in source | Pass | `.env.example` has `UNSPLASH_ACCESS_KEY=your_access_key_here` placeholder only |
| Firebase config files not tracked | Pass | `google-services.json`, `GoogleService-Info.plist` in `.gitignore` |
| No `BuildContext` in data layer | Pass | Confirmed — `EventCoverRepositoryImpl` has no Flutter imports |
| Firebase token on API calls | Pass | `FirebaseAuthInterceptor` in `AppDio` applies to all Retrofit clients including `EventCoverService` |
| No `print()` in new code | Pass | No `print()` calls in any new `lib/` file |
| No hardcoded API keys | Pass | No Unsplash key or Claude key in Flutter source |
| Hardcoded Spanish error fallback in repository | Note | `EventCoverRepositoryImpl` line 36: fallback `'No pudimos generar la portada...'` when `error.message` is empty. Matches ARB value exactly; follows architect guidance (data layer cannot use `BuildContext`). Accepted. |

## Test coverage assessment

- `dart analyze`: 34 items (all pre-existing `withOpacity` deprecations in `lib/shared/widgets/`) — 0 new violations from iter-4 code
- `flutter test`: 7/7 pass — 4 `ProfileCubit` tests + 2 `GetGenerateCoverUseCase` tests + 1 placeholder
- Backend tests: 10/10 pass (`rideglory-api`)
- `CoverPreviewWidget` widget tests remain code-review verified (not automated) — acceptable per QA sign-off

## Blocking issues

All blocking issues were fixed directly in this review pass:
1. `prefer_const_constructors` in `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` — 5 occurrences of missing `const` on `Right()`, `Left()`, and `DomainException()`. Fixed inline; `dart analyze` now shows 34 pre-existing items (down from 37).

## Non-blocking notes (fix in next iteration)

- `withOpacity` → `.withValues()` in 34 locations across `lib/shared/widgets/` — pre-existing, batch in a dedicated refactor pass
- `_PlaceholderView` private widget in `cover_preview_widget.dart` — minor one-widget-per-file deviation; acceptable given size; extract if widget grows

## Change log

- 2026-05-13: Initial tech lead review for Iteration 4 — approved with 1 blocking fix (const constructors in test file)
