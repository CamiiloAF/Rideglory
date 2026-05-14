# Tech lead review — Iteration 2

**Date:** 2026-05-15
**Status:** blocked

## Pull request
| Field     | Value                                               |
| --------- | --------------------------------------------------- |
| URL       | https://github.com/CamiiloAF/Rideglory/pull/14     |
| Branch    | iter-2 → main                                       |
| PR number | #14                                                 |

## Inline review comments
| File / location | Severity | Summary |
| --------------- | -------- | ------- |
| `lib/features/notifications/presentation/notifications_view.dart:34` | blocking | Raw `TextButton` in feature code — replace with `AppTextButton` |
| `lib/features/soat/presentation/pages/soat_status_page.dart:64` | blocking | Raw `TextButton` in feature code — replace with `AppTextButton` |
| `lib/features/soat/presentation/pages/soat_manual_form_page.dart` | blocking | 3 widget classes in one file (`SoatManualFormPage`, `_SoatManualFormView`, `_SectionHeader`) — extract to separate files |
| `lib/features/soat/presentation/pages/soat_status_page.dart` | blocking | 5 widget classes in one file — extract `_SoatStatusView`, `_SoatEmptyState`, `_SoatDataView`, `_DetailRow` |
| `lib/features/soat/presentation/pages/soat_upload_page.dart` | blocking | 3 widget classes in one file — extract `_SoatSourceGrid`, `_SourceOption` |
| `lib/features/notifications/presentation/notifications_view.dart` | blocking | 4 widget classes in one file — extract `_ErrorState`, `_EmptyState`, `_DataView` |
| `lib/features/notifications/presentation/widgets/notification_bell_button.dart:21-22` | blocking | Hardcoded Spanish strings in Semantics labels (`'$unread notificaciones sin leer'`, `'Notificaciones'`) — must go through `app_es.arb` + `context.l10n` |
| `lib/features/notifications/presentation/widgets/notification_item.dart:69` | blocking | Hardcoded Spanish string `'Notificación: ...'` in Semantics label — must go through `app_es.arb` + `context.l10n` |
| `lib/features/soat/presentation/pages/soat_status_page.dart:131` | blocking | `Navigator.push(MaterialPageRoute(...))` bypasses go_router — add `AppRoutes.soatManualForm` named route and use `context.pushNamed()` |
| `lib/features/soat/presentation/pages/soat_upload_page.dart:108` | blocking | `Navigator.push(MaterialPageRoute(...))` bypasses go_router — same fix as above |
| `lib/core/services/fcm_service.dart:81` | info | FCM token first 10 chars logged in kDebugMode — acceptable in debug; add inline comment documenting the rationale |
| `lib/features/soat/data/dto/soat_dto.dart` | info | `SoatModelToRequest` extension on domain model lives in data layer DTO file — minor concern about layer dependency direction; tolerable but worth noting |

## Stories reviewed
| Story ID | Outcome | Notes |
| -------- | ------- | ----- |
| US-2-1 | needs-fixes | SOAT upload implemented. 4 blocking violations in soat_upload_page.dart |
| US-2-2 | needs-fixes | SOAT manual form implemented. 4 blocking violations in soat_manual_form_page.dart |
| US-2-3 | pass | SoatModel 4-state logic correct; VehicleSoatSection uses localized stateLabel via context.l10n.soat_status_* — iter-1 deferred item resolved |
| US-2-4 | deferred | Backend cron prerequisite (T-2-7); manual device testing pending |
| US-2-5 | deferred | Backend FCM trigger prerequisite; manual device testing pending |
| US-2-6 | deferred | Backend notification delivery; manual device testing pending |
| US-2-7 | needs-fixes | NotificationsCubit correct; violations in notifications_view.dart (multiple widgets, TextButton) |
| US-2-8 | pass (backend) | Backend agent responsibility — not in Flutter PR scope |
| US-2-9 | pass | ManageAttendeesPage scope confirmed (component-swap); not touched in this PR (pre-existing) |
| US-2-10 | needs-fixes | dart analyze PASS; flutter test PASS; 4 coding-standards violations remain |

## Flutter Clean Architecture adherence
| Layer | Compliant | Violations |
| ----- | --------- | ---------- |
| domain | yes | None — zero Flutter imports, zero HTTP calls in soat/domain/ and notifications/domain/ |
| data | yes | None — zero BuildContext in soat/data/ and notifications/data/; DTOs not exposed to presentation |
| presentation | yes (architecture) | No direct HTTP calls; no DTO types exposed publicly; dependencies flow correctly |

Note: Architecture is clean. All 4 blocking issues are coding-standards violations, not architecture violations.

## rideglory-coding-standards adherence
| Rule | Compliant | Violations |
|------|-----------|------------|
| One widget per file | no | soat_manual_form_page.dart (3), soat_status_page.dart (5), soat_upload_page.dart (3), notifications_view.dart (4) — 12 extra widget classes across 4 files |
| No `Widget _buildXxx()` helpers | yes | None found |
| ARB strings only | no | 3 hardcoded Spanish strings in Semantics labels in notification_bell_button.dart:21-22 and notification_item.dart:69 |
| No ElevatedButton/OutlinedButton/TextButton directly | no | TextButton used in notifications_view.dart:34 and soat_status_page.dart:64 (AppBar actions) |
| No showDialog() directly | yes | None — AppButton/AppDialog used throughout |
| ResultState<T> for async | yes | SoatCubit: Cubit<ResultState<SoatModel>> correct; NotificationsCubit: @freezed NotificationsState with ResultState<List<NotificationModel>> correct |
| pushNamed navigation | no | MaterialPageRoute used in soat_status_page.dart:131 and soat_upload_page.dart:108 for SoatManualFormPage navigation (no named route) |
| Colors via colorScheme or AppColors | yes | All colors use AppColors constants; Colors.white used only for text-on-dark-badge (allowed set) |
| Button text sentence case | yes | All button labels checked — sentence case throughout |

## Security findings
| Finding | Severity | Status |
| ------- | -------- | ------ |
| FCM token partial logging (first 10 chars) | info | Wrapped in `kDebugMode`, uses `dart:developer log` (not `print`) — acceptable |
| No secrets in source | pass | No API keys, credentials, or tokens hardcoded |
| Firebase ID token auth | pass | All API calls go through `FirebaseAuthInterceptor` in `AppDio` |
| FCM background handler @pragma | pass | `@pragma('vm:entry-point')` present on `firebaseMessagingBackgroundHandler` |
| google-services.json not tracked | pass | Confirmed absent from diff |
| No print() statements | pass | Uses `dart:developer log` with `kDebugMode` guard only |

## Test coverage assessment
- dart analyze: **PASS — No issues found!** (0 errors, 0 warnings)
- flutter test: **64 pass / 1 pre-existing fail** (TC-2-28 rider email display — unchanged from iter-1)
- 21 new test cases (TC-2-20 through TC-2-40): 7 SOAT domain boundary tests, 5 SoatCubit state machine tests, 9 NotificationsCubit tests (load, pagination, markRead, markAllRead, error rollback)
- Coverage is adequate for domain + cubit layers; widget tests for SOAT pages and NotificationsView deferred per QA rationale

## Blocking issues (must fix before merge)

1. **[BLOCKING-1] Raw TextButton in feature code**
   - `lib/features/notifications/presentation/notifications_view.dart:34` — replace `TextButton(...)` with `AppTextButton(label: context.l10n.notification_markAllRead, onPressed: ...)`
   - `lib/features/soat/presentation/pages/soat_status_page.dart:64` — replace `TextButton(...)` with `AppTextButton(label: context.l10n.soat_edit_btn, onPressed: ...)`

2. **[BLOCKING-2] One-widget-per-file violation**
   - `soat_manual_form_page.dart`: extract `_SoatManualFormView` → `_soat_manual_form_view.dart` and `_SectionHeader` → `_soat_section_header.dart`
   - `soat_status_page.dart`: extract `_SoatStatusView`, `_SoatEmptyState`, `_SoatDataView`, `_DetailRow` to separate files
   - `soat_upload_page.dart`: extract `_SoatSourceGrid` → `_soat_source_grid.dart` and `_SourceOption` → `_soat_source_option.dart`
   - `notifications_view.dart`: extract `_ErrorState`, `_EmptyState`, `_DataView` to separate files

3. **[BLOCKING-3] Hardcoded Spanish strings in Semantics labels**
   - `notification_bell_button.dart:21-22`: add ARB keys `notification_bell_unread_label` (with `{count}` placeholder) and `notification_bell_label`; use `context.l10n.notification_bell_unread_label(unread)` and `context.l10n.notification_bell_label`
   - `notification_item.dart:69`: add ARB key `notification_item_accessibility_label` (with `{title}` and `{time}` placeholders); use via `context.l10n.notification_item_accessibility_label(notification.title, _timeAgo(notification.createdAt))`

4. **[BLOCKING-4] Raw Navigator.push(MaterialPageRoute(...)) bypasses go_router**
   - Add `static const String soatManualForm = '/soat/manual-form'` to `lib/shared/router/app_routes.dart`
   - Add route in `lib/shared/router/app_router.dart` that accepts `VehicleModel` (vehicle) and `SoatModel?` (existingSoat) as `extra`
   - Replace `Navigator.of(context).push(MaterialPageRoute(...))` with `context.pushNamed(AppRoutes.soatManualForm, extra: {'vehicle': vehicle, 'existingSoat': soat})`

## Non-blocking notes (fix in next iteration)

- `lib/core/services/fcm_service.dart:81` — FCM token first 10 chars logged in kDebugMode via `dart:developer log`. Functionally acceptable; add a comment explaining why partial logging is sufficient for debugging without exposing full token.
- `lib/features/soat/data/dto/soat_dto.dart` — `SoatModelToRequest` extension adds `toRequestJson()` to the domain model from a data-layer file. This creates a subtle data→domain dependency. Consider moving to `SoatModel` directly or a separate `soat_model_extensions.dart` in domain. Not an architecture violation per se (extension is additive), but worth cleaning up.
- `lib/core/services/fcm_service.dart` — `configureDependencies()` is commented as a future requirement in the background handler. Per architect spec, this must be called when DI-registered services are used in the background. Add a `// TODO(iter-3): call configureDependencies() if background processing beyond logging is needed` so it is not forgotten.

## Overall signal

PR #14 delivers a solid SOAT + FCM notification foundation: Clean Architecture is correctly layered (domain/data/presentation separation verified), ResultState<T> pattern used throughout, cursor pagination enforced, FCM @pragma handler correct, NotificationsCubit correctly marked @lazySingleton in root MultiBlocProvider, 140+ ARB keys localized, and the iter-1 DocumentSlotPill deferred item (localized stateLabel) is now resolved. The code is architecturally sound.

However, 4 coding-standards violations are blocking: (1) raw `TextButton` in 2 AppBar actions where `AppTextButton` is required; (2) multiple widget classes per file across 4 new files (12 extra classes total); (3) 3 hardcoded Spanish strings in Semantics labels that must go through app_es.arb; (4) `MaterialPageRoute` used for SoatManualFormPage navigation instead of a named go_router route. All 4 are mechanical fixes with no architectural impact. Fix and re-push; the PR is otherwise ready to merge.

## Change log
- 2026-05-15: Initial review — PR #14 — BLOCKED (4 blocking coding-standards violations)

## Re-review cycle

**Date:** 2026-05-15
**Verdict:** APPROVED

### Violation checks

| Blocking ID | Status | Evidence |
|-------------|--------|---------|
| BLOCKING-1: Raw TextButton | FIXED | notifications_view.dart uses `AppTextButton(label: context.l10n.notification_markAllRead, onPressed: ...)`. soat_status_page.dart now a thin page wrapper — AppTextButton is used in the extracted SoatStatusView widget. No raw TextButton remaining in either file. |
| BLOCKING-2: One-widget-per-file | FIXED | 8 extracted soat widget files: `soat_data_view.dart`, `soat_detail_row.dart`, `soat_empty_state.dart`, `soat_manual_form_view.dart`, `soat_section_header.dart`, `soat_source_grid.dart`, `soat_source_option.dart`, `soat_status_view.dart`. 3 extracted notifications widget files: `notifications_data_view.dart`, `notifications_empty_state.dart`, `notifications_error_state.dart`. All 4 original page files now contain exactly one widget class each. |
| BLOCKING-3: Hardcoded Semantics strings | FIXED | ARB keys added to `app_es.arb`: `notification_bell_unread_label` (with `{count}` placeholder), `notification_bell_label`, `notification_item_accessibility_label` (with `{title}`, `{time}` placeholders). `notification_bell_button.dart` uses `context.l10n.notification_bell_unread_label(unread)` / `context.l10n.notification_bell_label`. `notification_item.dart` uses `context.l10n.notification_item_accessibility_label(...)`. |
| BLOCKING-4: MaterialPageRoute bypasses go_router | FIXED | `AppRoutes.soatUpload`, `AppRoutes.soatStatus`, `AppRoutes.soatManualForm` constants added to `app_routes.dart`. All 3 routes registered in `app_router.dart` via `GoRoute`. No `Navigator.push(MaterialPageRoute(...))` remaining in any soat file. |

### Quality gates

| Gate | Result |
|------|--------|
| dart analyze | PASS — No issues found! (0 errors, 0 warnings) |
| flutter test | PASS — 64 pass / 1 pre-existing fail (TC-2-28 rider email, unchanged from iter-1) |

### Decision

**APPROVED** — All 4 blocking violations resolved. Architecture remains clean. PR #14 is ready to merge.
