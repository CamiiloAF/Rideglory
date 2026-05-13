# Tech lead review — Iteration 1

**Date:** 2026-05-12
**Status:** approved

## Pull request

| Field     | Value                                         |
| --------- | --------------------------------------------- |
| URL       | https://github.com/CamiiloAF/Rideglory/pull/8 |
| Branch    | iter-1 → main                                 |
| PR number | #8                                            |

## Inline review comments

| File / location | Severity | Summary |
| --------------- | -------- | ------- |
| `lib/features/profile/presentation/profile_page.dart` | Blocking (fixed) | `_ProfileContent` class is a second widget in the same file — violates one-widget-per-file rule. Extracted to `profile_content.dart`. |
| `lib/features/events/presentation/list/widgets/event_card.dart:71` | Warning (fixed) | Unnecessary `!` null assertion on `imageUrl` already guarded by `hasImageUrl`. Removed. |
| `lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_summary_header.dart:4` | Warning (fixed) | Unused import `l10n_extensions.dart`. Removed. |
| `lib/core/http/rest_client_functions.dart:62` | Blocking (fixed) | `print()` call in production code. Replaced with `log()`. |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart:65` | Blocking (fixed) | Raw `TextButton` — replaced with `AppTextButton`. |
| `lib/features/events/presentation/attendees/widgets/attendees_list.dart:136` | Blocking (fixed) | Raw `TextButton` — replaced with `AppTextButton`. |
| `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart:196,231` | Non-blocking | `OutlinedButton.icon` for date-picker triggers — `AppButton` does not cover icon + dynamic text layout. Rationale documented in-code; deferred to Iter 2. |

## Stories reviewed

| Story ID | Outcome | Notes |
| -------- | ------- | ----- |
| US-1-1 | Pass | `mocktail`, `bloc_test` in `dev_dependencies`; test directory tree created; `flutter pub get` clean. |
| US-1-4 | Pass | `ProfileCubit`, `GetMyProfileUseCase`, profile page with 4 ResultState branches, 3 extracted widgets, 5 l10n keys — all acceptance criteria met. |
| US-1-5 | Pass | Code review complete; findings documented in `docs/architecture/code-review-iter1.md`; all blocking items fixed inline. |
| US-1-2 | Deferred | Cubit blocTests for VehicleCubit/EventsCubit/EventDetailCubit/MaintenancesCubit deferred to Iter 2 per PO scope. |
| US-1-3 | Deferred | Widget tests for garage/event list/event detail deferred to Iter 2 per PO scope. |

## Flutter Clean Architecture adherence

| Layer | Compliant | Violations |
| ----- | --------- | ---------- |
| domain | yes | None — `GetMyProfileUseCase` has no Flutter imports, no HTTP calls |
| data | yes | None — no `BuildContext` in any `lib/features/*/data/` file |
| presentation | yes | None — `ProfileCubit` emits `UserModel` (domain model), never `UserDto` |

## rideglory-coding-standards adherence

| Rule | Compliant | Violations |
|------|-----------|------------|
| One widget per file | yes (after fix) | `_ProfileContent` in `profile_page.dart` — extracted to `profile_content.dart` |
| No `_buildXxx` helpers | yes | None found |
| All strings via `context.l10n` | yes | All 5 new `profile_` keys in ARB; no hardcoded Spanish |
| `AppButton` not `ElevatedButton` | yes | No ElevatedButton in new code |
| `AppTextButton` not `TextButton` | yes (after fix) | 2 pre-existing `TextButton` violations fixed; 2 `OutlinedButton.icon` deferred |
| No `showDialog()` directly | yes | `ConfirmationDialog.show()` used correctly |
| `ResultState<T>` for async | yes | `ProfileCubit<ResultState<UserModel>>` — no boolean flags |
| `context.pushNamed` for navigation | yes | All feature nav uses `pushNamed`; `goAndClearStack` for logout |
| `colorScheme` colors | yes | All new widgets use `colorScheme.*` |

## Security findings

| Finding | Severity | Status |
| ------- | -------- | ------ |
| `print(error.stackTrace)` in `rest_client_functions.dart` | Low | Fixed — replaced with `log()` |
| No secrets in source | Pass | `.env.example` has placeholders only |
| Firebase config files not tracked | Pass | `google-services.json`, `GoogleService-Info.plist` in `.gitignore` |
| No `BuildContext` in data layer | Pass | Confirmed |

## Test coverage assessment

- `dart analyze`: pass — 0 warnings, 0 errors; 34 info-level items (all pre-existing `withOpacity` deprecations in shared widgets)
- `flutter test`: 5/5 pass — ProfileCubit initial, loading→data, loading→error, reset states; placeholder widget test
- Coverage assessment: US-1-4 acceptance criteria verified via blocTest. US-1-2 (cubit state transition tests for VehicleCubit/EventsCubit/MaintenancesCubit) and US-1-3 (widget tests) deferred to Iter 2 per PO scope agreement.

## Blocking issues (must fix before merge)

All blocking issues were fixed directly in this review pass:
1. `_ProfileContent` in `profile_page.dart` → extracted to `profile_content.dart` (one-widget-per-file)
2. `print()` in `rest_client_functions.dart` → replaced with `log()`
3. `TextButton` in `vehicle_maintenance_history_section.dart` → `AppTextButton`
4. `TextButton` in `attendees_list.dart` → `AppTextButton`
5. `unnecessary_non_null_assertion` in `event_card.dart` → removed `!`
6. `unused_import` in `maintenances_summary_header.dart` → removed

## Non-blocking notes (fix in next iteration)

- `withOpacity` → `.withValues()` in 28 locations across `lib/shared/widgets/` — batch fix in Iter 2
- `OutlinedButton.icon` date-picker in `maintenance_filters_bottom_sheet.dart` — extract `DatePickerButton` shared widget if pattern recurs in Iter 2+

## Overall signal

Iteration 1 is ready to ship. The new profile feature (US-1-4) strictly follows Clean Architecture — domain use case, singleton cubit, domain model emission, and proper widget decomposition. All localization keys are present with correct `profile_` prefix. The test infrastructure (US-1-1) is in place. Code review (US-1-5) found and fixed 6 blocking items (one-widget-per-file violation, print() call, 2 raw TextButton usages, 2 analyzer warnings). No security concerns. Tests are green. The 34 remaining info-level items are all pre-existing `withOpacity` deprecations in shared widgets — low risk, batched for Iter 2.

## Change log

- 2026-05-12: Initial tech lead review for Iteration 1 — approved with inline fixes
