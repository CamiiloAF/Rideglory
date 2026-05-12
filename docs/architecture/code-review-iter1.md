# Code Review — Iteration 1

> Reviewer: tech_lead
> Date: 2026-05-12

## Findings

| File | Issue | Severity | Resolution | Deferred? |
|------|-------|----------|-----------|-----------|
| `lib/features/events/presentation/list/widgets/event_card.dart:71` | Unnecessary `!` on `imageUrl` (already null-checked by `hasImageUrl`) — `unnecessary_non_null_assertion` warning | Warning | Removed `!` operator — `imageUrl` is `String` in the true branch | No |
| `lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_summary_header.dart:4` | Unused import `l10n_extensions.dart` — `unused_import` warning | Warning | Import removed | No |
| `lib/core/http/rest_client_functions.dart:62` | `print(error.stackTrace)` in production code — removed per US-1-5 requirement | Warning | Replaced with `log('Stack trace: ${error.stackTrace}')` using existing `log` | No |
| `lib/features/profile/presentation/profile_page.dart` | Two widgets in one file: `ProfilePage` + `_ProfileContent` — violates one-widget-per-file rule | Blocking | Extracted `_ProfileContent` → `profile_content.dart` as `ProfileContent` | No |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart:65` | `TextButton` used directly — must use `AppTextButton` | Blocking | Replaced with `AppTextButton(label:..., onPressed:..., visualDensity: VisualDensity.compact)` | No |
| `lib/features/events/presentation/attendees/widgets/attendees_list.dart:136` | `TextButton` used directly — must use `AppTextButton` | Blocking | Replaced with `AppTextButton` | No |
| `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart:196,231` | `OutlinedButton.icon` used for date-picker triggers | Non-blocking | Added rationale comment: `AppButton` does not support icon + dynamic text label layout; deferred to refactor into shared widget if pattern recurs | Yes — Iter 2 |
| `lib/shared/widgets/detail_pill.dart` et al. (34 info items) | `withOpacity` deprecated — use `.withValues()` | Info | All in shared widgets not changed in iter-1. Batched for Iter 2 cleanup pass. | Yes — Iter 2 |

## Deferred items

| Item | Rationale | Target |
|------|-----------|--------|
| `withOpacity` → `.withValues()` across `lib/shared/widgets/` (28 instances) | Pre-existing; info-level only; no functional impact. Batch-fix in next cleanup pass. | Iter 2 |
| `OutlinedButton.icon` date-picker in `maintenance_filters_bottom_sheet.dart` | `AppButton` does not support icon + dynamic label; rationale documented in-code. Extract `DatePickerButton` shared widget when pattern recurs. | Iter 2 |

## Architecture health summary

- **Layer compliance is clean.** Domain layer has no Flutter imports. Data layer has no `BuildContext`. Presentation layer does not expose DTOs.
- **New profile feature follows the prescribed pattern perfectly.** `ProfileCubit<ResultState<UserModel>>` → `GetMyProfileUseCase` → `UserRepository.getCurrentUser()` — correct inward dependency flow.
- **DI wiring is correct.** `ProfileCubit` registered as `@lazySingleton` in `injection.config.dart`; added to root `MultiBlocProvider` in `main.dart`.
- **Localization is complete.** All 5 required `profile_` keys added to `app_es.arb`; no hardcoded Spanish strings in any new file.
- **Two pre-existing widget violations (TextButton) fixed** in `vehicle_maintenance_history_section.dart` and `attendees_list.dart`. One complex date-picker case documented and deferred.
