# PO Proposal — Refactor & Cleanup Extremo (Refactor-01)

> Generated: 2026-05-27
> Author: PO Agent
> Based on: `docs/prd-refactor-cleanup.md` + `docs/handoffs/planning/00-existing-system-scan.md`
> Iteration number: **Refactor-01** (separate from product iterations 1–5)

---

## Iteration summary

This iteration eliminates the technical debt that has accumulated across 62 feature files during the recent product-feature iterations. No new features, API changes, or backend changes are introduced. The work is pure internal refactoring: extract one widget per file, replace Flutter primitives with shared-design-system components, consolidate the duplicated SOAT implementation, migrate navigation to go_router, tokenize hardcoded colors, and fix one confirmed UX bug. When the iteration closes, `dart analyze` reports 0 errors and 0 warnings, every feature file contains at most one widget class, and all shared-component adoption rules are mechanically verifiable by grep.

---

## Stories

---

### REFACTOR-01: Fix SOAT loading-button bug

**Violation type:** UX bug — `_openingDocument` changes the button label to `soat_downloading` instead of passing `isLoading: true` to `AppButton`, breaking the design system's loading-spinner contract.

**Files affected:**
- `lib/features/soat/presentation/widgets/soat_data_view.dart`

**Acceptance criteria:**
- [ ] `grep "soat_downloading" lib/features/soat/presentation/widgets/soat_data_view.dart` returns 0 results
- [ ] `grep "isLoading: _openingDocument" lib/features/soat/presentation/widgets/soat_data_view.dart` returns 1 result
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — single-file change, no logic change, only button prop swap.

**Effort:** S (<1h)

---

### REFACTOR-02: Consolidate SOAT duplication — eliminate `vehicles/presentation/soat/`

**Violation type:** Code duplication — two active SOAT implementations; legacy folder uses `Navigator.of(context)` throughout and is still wired to the router at `/vehicles/soat`.

**Files affected (delete the entire legacy folder):**
- `lib/features/vehicles/presentation/soat/soat_upload_page.dart`
- `lib/features/vehicles/presentation/soat/soat_confirmation_page.dart`
- `lib/features/vehicles/presentation/soat/soat_manual_capture_page.dart`
- `lib/features/vehicles/presentation/soat/cubit/` (entire subfolder)
- `lib/features/vehicles/presentation/soat/widgets/` (entire subfolder: `soat_document_section.dart`, `vehicle_soat_options_sheet.dart`, `soat_vehicle_info_card.dart`, `soat_valid_alert.dart`, `soat_upload_option_card.dart`)

**Files affected (update router + cross-imports):**
- `lib/shared/router/app_router.dart` — remove `/vehicles/soat` route; redirect any callers to `/soat/upload`
- `lib/features/soat/presentation/` — remove any import of `vehicles/presentation/soat/` (e.g. `SoatManualCapturePage` import in `soat_status_view.dart`)

**Acceptance criteria:**
- [ ] `find lib/features/vehicles/presentation/soat -name "*.dart" | wc -l` returns 0
- [ ] `grep -r "vehicles/presentation/soat" lib/` returns 0 results
- [ ] `grep "\/vehicles\/soat" lib/shared/router/` returns 0 results (route removed or redirected)
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: SOAT upload flow navigates correctly from vehicle detail badge

**Risk:** Medium — router change + cross-import removal can cause runtime 404. Mitigation: verify all entry points to old route and update each one before deleting files.

**Effort:** M (2–3h)

---

### REFACTOR-03: Widget extraction — Vehicles feature (garage + form)

**Violation type:** Multiple widget classes per file (zero-tolerance rule). Files: `garage_vehicles_content.dart` (16 widgets), `vehicle_detail_view.dart` (13 widgets), `vehicle_form.dart` (9 widgets), plus widget-returning methods in `garage_vehicles_content.dart` (`Widget _buildContainer()`, `Widget _buildPlaceholderIcon()`), in `vehicle_card.dart` (`Widget _buildPlaceholderIcon()`).

**Files affected (extract FROM):**
- `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart` (4 widgets)
- `lib/features/vehicles/presentation/widgets/vehicle_form.dart`
- `lib/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart` (4 widgets)
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart` (2 widgets)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart` (4 widgets)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart` (3 widgets)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` (2 widgets)
- `lib/features/vehicles/presentation/widgets/vehicle_card.dart` (widget-returning method)

**Acceptance criteria:**
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` returns ≤1
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` returns ≤1
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/vehicles/presentation/widgets/vehicle_form.dart` returns ≤1
- [ ] `grep "Widget _build\|Widget _" lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` returns 0 results
- [ ] `grep "Widget _build\|Widget _" lib/features/vehicles/presentation/widgets/vehicle_card.dart` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Medium — `garage_vehicles_content.dart` has 16 classes sharing potential state/callbacks. Mitigation: extract leaf widgets first (pure display), then intermediate composers; use constructor parameters for data, never shared state mutation.

**Effort:** L (6–8h)

---

### REFACTOR-04: Widget extraction — Authentication feature

**Violation type:** Multiple widget classes per file. `forgot_password_view.dart` (9 widgets), `login_view.dart` (8 widgets), `signup_view.dart` (6 widgets). Also covers `context.goNamed` violations in `forgot_password_view.dart` (2 occurrences — should be `context.pushNamed` or `context.goAndClearStack` on return from password recovery).

**Files affected:**
- `lib/features/authentication/login/presentation/forgot_password_view.dart`
- `lib/features/authentication/login/presentation/login_view.dart`
- `lib/features/authentication/signup/presentation/signup_view.dart`

**Acceptance criteria:**
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/authentication/login/presentation/forgot_password_view.dart` returns ≤1
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/authentication/login/presentation/login_view.dart` returns ≤1
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/authentication/signup/presentation/signup_view.dart` returns ≤1
- [ ] `grep "context\.goNamed" lib/features/authentication/login/presentation/forgot_password_view.dart` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions
- [ ] Manual smoke test: Login → Forgot Password → back to Login; Signup flow start to end

**Risk:** Low — auth screens are stateless forms; no complex shared state between extracted widgets.

**Effort:** M (3–4h)

---

### REFACTOR-05: Widget extraction — Events feature (detail + form + tracking + list)

**Violation type:** Multiple widget classes per file. `event_detail_view.dart` (9 widgets), `event_detail_cta_bar.dart` (8 widgets + `Widget _buildContent()` method), `event_form_max_participants_section.dart` (7 widgets), `event_form_locations_section.dart` (6 widgets), `event_form_price_section.dart` (4 widgets), `event_detail_owner_lifecycle_bar.dart` (4 widgets), `event_detail_meeting_point_section.dart` (4 widgets), `event_route_config_screen.dart` (4 widgets), `live_map_app_bar.dart` (4 widgets), `events_data_view.dart` (4 widgets), `event_card.dart` (5 widgets), plus widget-returning methods in `event_detail_by_id_page.dart` (`Widget _shell()`), `participants_placeholder_page.dart` (`Widget _buildEmptyState()`, `Widget _buildRiderList()`), and `event_card_header.dart` (`Widget _buildPopupMenu()`).

**Files affected:**
- `lib/features/events/presentation/detail/event_detail_view.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart`
- `lib/features/events/presentation/detail/widgets/event_detail_header.dart` (2 widgets)
- `lib/features/events/presentation/detail/widgets/event_detail_header_background_image.dart` (2 widgets)
- `lib/features/events/presentation/detail/event_detail_by_id_page.dart` (widget-returning method)
- `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart`
- `lib/features/events/presentation/form/widgets/event_form_bottom_bar.dart` (3 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_form_details_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart`
- `lib/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart`
- `lib/features/events/presentation/form/widgets/sections/waypoint_item_card.dart` (2 widgets)
- `lib/features/events/presentation/form/widgets/sections/event_route_type_selector.dart` (2 widgets)
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` (2 widgets)
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` (4 widgets)
- `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` (3 widgets + 2 widget-returning methods)
- `lib/features/events/presentation/tracking/widgets/live_map_app_bar.dart` (4 widgets)
- `lib/features/events/presentation/list/widgets/event_card.dart` (5 widgets)
- `lib/features/events/presentation/list/widgets/events_data_view.dart` (4 widgets)
- `lib/features/events/presentation/list/widgets/events_page_view.dart` (2 widgets)
- `lib/features/events/presentation/list/widgets/event_card_header.dart` (widget-returning method)
- `lib/features/events/presentation/drafts/my_drafts_page.dart` (2 widgets)

**Acceptance criteria:**
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/events/presentation/detail/event_detail_view.dart` returns ≤1
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart` returns ≤1
- [ ] `grep "Widget _build\|Widget _" lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart` returns 0
- [ ] `grep "Widget _shell\|Widget _build" lib/features/events/presentation/detail/event_detail_by_id_page.dart` returns 0
- [ ] `grep "Widget _buildEmptyState\|Widget _buildRiderList" lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` returns 0
- [ ] `grep "Widget _buildPopupMenu" lib/features/events/presentation/list/widgets/event_card_header.dart` returns 0
- [ ] All `event_form_*_section.dart` files: each returns ≤1 on the widget-class grep
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions (widget tests for `event_filters_bottom_sheet`, `events_page_view`, `attendees_list_navigation` must continue to pass)

**Risk:** Medium — `event_detail_cta_bar.dart` has 8 state-variant widgets and the form has many tightly coupled sections. Extract widgets independently; verify CTA bar state variants after extraction.

**Effort:** L (6–8h)

---

### REFACTOR-06: Widget extraction — Maintenance + Home + Profile + Registration features

**Violation type:** Multiple widget classes per file. Maintenance: `maintenance_filters_bottom_sheet.dart` (12 widgets), `maintenances_page.dart` (3 widgets), `maintenance_detail_page.dart` (3 widgets), `maintenance_summary_widget.dart` (2 widgets), `maintenance_next_service_card.dart` (2 widgets), plus widget-returning method `Widget _rightBadge()` in `maintenance_grouped_list_item.dart`. Home: `home_event_card.dart` (5 widgets), `home_page.dart` (2 widgets), `home_garage_section.dart` (2 widgets). Profile: `edit_profile_page.dart` (3 widgets), `profile_stats_row.dart` (3 widgets), `profile_actions_list.dart` (3 widgets), `profile_header.dart` (2 widgets), `profile_garage_section.dart` (2 widgets), `profile_content.dart` (2 widgets). Users: `rider_profile_content.dart` (4 widgets). Event Registration: `event_registration_page.dart` (2 widgets), `registration_detail_page.dart` (2 widgets), `inscription_card.dart` (2 widgets).

**Files affected:**
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart`
- `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart`
- `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_summary_widget.dart`
- `lib/features/maintenance/presentation/detail/widgets/maintenance_next_service_card.dart`
- `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` (widget-returning method)
- `lib/features/home/presentation/widgets/home_event_card.dart`
- `lib/features/home/presentation/home_page.dart`
- `lib/features/home/presentation/widgets/home_garage_section.dart`
- `lib/features/profile/presentation/edit_profile_page.dart`
- `lib/features/profile/presentation/widgets/profile_stats_row.dart`
- `lib/features/profile/presentation/widgets/profile_actions_list.dart`
- `lib/features/profile/presentation/widgets/profile_header.dart`
- `lib/features/profile/presentation/widgets/profile_garage_section.dart`
- `lib/features/profile/presentation/widgets/profile_content.dart`
- `lib/features/users/presentation/widgets/rider_profile_content.dart`
- `lib/features/event_registration/presentation/event_registration_page.dart`
- `lib/features/event_registration/presentation/registration_detail_page.dart`
- `lib/features/event_registration/presentation/widgets/inscription_card.dart`

**Acceptance criteria:**
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` returns ≤1
- [ ] `grep "Widget _rightBadge" lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` returns 0
- [ ] `grep -c "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" lib/features/home/presentation/widgets/home_event_card.dart` returns ≤1
- [ ] All listed profile, users, event_registration files: each returns ≤1 on the widget-class grep
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low-Medium — `maintenance_filters_bottom_sheet.dart` is the heaviest file in this story (12 classes) but all are pure display/selection widgets. Profile and registration files are small and isolated.

**Effort:** L (5–7h)

---

### REFACTOR-07: Replace raw buttons with AppButton/AppTextButton

**Violation type:** Prohibited use of `ElevatedButton`, `TextButton`, `OutlinedButton` directly in feature files.

**Files affected (14 raw-button instances across 6 files):**
- `lib/features/users/presentation/widgets/rider_profile_content.dart` — 1x `ElevatedButton`
- `lib/features/events/presentation/form/widgets/event_form_view.dart` — 3x `TextButton`
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` — 1x `TextButton`
- `lib/features/events/presentation/tracking/widgets/end_ride_confirm_dialog.dart` — 1x `TextButton`
- `lib/features/events/presentation/tracking/widgets/sos_active_overlay.dart` — 1x `OutlinedButton`
- `lib/features/events/presentation/tracking/widgets/sos_confirm_dialog.dart` — 1x `TextButton`

**Acceptance criteria:**
- [ ] `grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] If any raw button is retained for a justified reason (e.g. SOS overlay with custom styling not supported by AppButton), it is annotated with `// Custom: <reason>` on the same line
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — AppButton and AppTextButton already support `isLoading`, `variant`, and `icon`. The only possible exception is `sos_active_overlay.dart` which may require a specific `OutlinedButton` styling; document if so.

**Effort:** S (1–2h)

---

### REFACTOR-08: Replace FormBuilderTextField with AppTextField

**Violation type:** Prohibited use of `FormBuilderTextField` where `AppTextField` exists.

**Files affected (5 occurrences in 4 files):**
- `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart` — 1 instance
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart` — 2 instances
- `lib/features/maintenance/presentation/form/widgets/maintenance_next_km_pill.dart` — 1 instance
- `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` — 1 instance

**Acceptance criteria:**
- [ ] `grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"` returns 0 results
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — `AppTextField` is a direct wrapper around `FormBuilderTextField`; it accepts the same `name` prop and validation hooks. The only risk is a missing prop mapping; verify each instance against `AppTextField`'s constructor.

**Effort:** S (1h)

---

### REFACTOR-09: Migrate navigation — eliminate `Navigator.of(context)` in features

**Violation type:** Prohibited use of `Navigator.of(context).push*` / `.pop()` where go_router should be used.

**Files affected (29 occurrences across 18 files):**

Note: 10 of these 29 occurrences live in the legacy SOAT folder (`vehicles/presentation/soat/`) and are automatically resolved when REFACTOR-02 deletes that folder. Only the 13 remaining files below need explicit fixes.

Files with explicit Navigator.of calls to fix:
- `lib/features/maintenance/presentation/form/maintenance_form_page.dart` (2 calls)
- `lib/features/maintenance/presentation/form/widgets/change_vehicle_mileage_bottom_sheet.dart` (2 calls)
- `lib/features/maintenance/presentation/form/widgets/maintenance_form_content.dart` (1 call)
- `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` (2 calls)
- `lib/features/events/presentation/form/screens/event_route_config_screen.dart` (2 calls)
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` (1 call)
- `lib/features/events/presentation/detail/event_detail_view.dart` (1 call)
- `lib/features/events/presentation/detail/event_route_map_screen.dart` (1 call)
- `lib/features/events/presentation/attendees/widgets/attendees_filter_bottom_sheet.dart` (1 call)
- `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart` (2 calls)
- `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart` (2 calls)
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart` (1 call)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` (1 call)
- `lib/features/soat/presentation/widgets/soat_source_grid.dart` (1 call)

**Acceptance criteria:**
- [ ] `grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] For bottom sheets that use `Navigator.of(context).pop(result)` to return a value: replaced with a callback pattern or `context.pop(result)` (go_router 14+); document with `// Custom:` only if pop-with-result cannot be replaced
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Medium — `Navigator.of(context).pop(result)` (bottom sheets that return a value to caller) cannot be mechanically replaced by `context.pop()` without verifying the caller reads the result via `showModalBottomSheet`'s returned future. Review each case individually before replacing.

**Effort:** M (3–4h)

---

### REFACTOR-10: Fix `context.goNamed` navigation violations

**Violation type:** `context.goNamed()` used for normal navigation where `context.pushNamed()` or `context.goAndClearStack()` is required.

**Files affected:**
- `lib/features/profile/presentation/profile_page.dart` — `context.goNamed(AppRoutes.home)` in PopScope
- `lib/features/vehicles/presentation/garage/garage_page.dart` — `context.goNamed(AppRoutes.home)` in PopScope
- `lib/features/events/presentation/list/events_page.dart` — `context.goNamed(AppRoutes.home)` in PopScope
- `lib/features/authentication/login/presentation/forgot_password_view.dart` — `context.goNamed(AppRoutes.login)` x2

**Decision rules per case:**
- `profile_page.dart`, `garage_page.dart`, `events_page.dart` in `PopScope`: these are shell tabs that should not stack onto each other. `context.goNamed` (replaces stack) may be intentional here. Each case must be evaluated: if the intent is "prevent double-tab back to previous tab", keep as `goNamed` and annotate `// Intentional: shell-tab navigation resets stack`; if not intentional, change to `pushNamed`.
- `forgot_password_view.dart` x2: returning to login from password recovery should use `context.goAndClearStack(AppRoutes.login)` or `context.pop()` if the view is pushed. Evaluate and fix.

**Acceptance criteria:**
- [ ] `grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] All remaining `context.goNamed` calls are annotated with `// Intentional: <reason>`
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — 5 isolated navigation calls. PopScope cases likely remain as `goNamed` with annotation.

**Effort:** S (1h)

---

### REFACTOR-11: Tokenize hardcoded colors in features

**Violation type:** `Color(0x...)` and `Colors.*` literals used directly in feature `build()` methods instead of `AppColors.*` or `colorScheme.*`.

**Files affected:**

`Color(0x...)` literals (confirmed):
- `lib/features/home/presentation/widgets/home_vehicle_info_row.dart` — `Color(0xFFEAB308)`, `Color(0x1AEF4444)`, `Color(0x1AEAB308)` (SOAT status colors)
- `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` — 10+ `Color(0x...)` for maintenance overdue/warning states
- `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` — `Color(0xCC0D0D0F)`, `Color(0xFF0D0D0F)` (gradient overlay)
- `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart` — `Color(0xFF22C55E)`, `Color(0xFFEAB308)`, `Color(0xFFEF4444)` (status colors)
- `lib/features/profile/presentation/edit_profile_page.dart` — `Color(0x66F98C1F)` (primary tint)
- `lib/features/profile/presentation/widgets/profile_header.dart` — `Color(0x66F98C1F)`
- `lib/features/users/presentation/widgets/rider_profile_content.dart` — `Color(0x66F98C1F)`

`Colors.*` literals (confirmed in features):
- `lib/features/home/presentation/widgets/home_event_view_details_button.dart` — `Colors.white`, `Colors.black87` x2
- `lib/features/home/presentation/widgets/home_view_all_events_button.dart` — `Colors.transparent`
- `lib/features/home/presentation/widgets/home_event_card.dart` — `Colors.white`
- `lib/features/home/presentation/widgets/home_event_gradient_overlay.dart` — `Colors.transparent`, `Colors.black87`
- `lib/features/home/presentation/widgets/home_event_difficulty_badge.dart` — `Colors.white`
- `lib/features/event_registration/presentation/registration_detail_page.dart` — `Colors.transparent` (surfaceTintColor)
- `lib/features/event_registration/presentation/my_registrations_view.dart` — `Colors.transparent` (surfaceTintColor)
- `lib/features/event_registration/presentation/widgets/inscription_card.dart` — `Colors.transparent`
- `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart` — `Colors.transparent`
- `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart` — `Colors.white`
- `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart` — `Colors.transparent`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart` — `Colors.black`, `Colors.white`

**Tokenization strategy:**
- SOAT status colors (`#22C55E`, `#EAB308`, `#EF4444`) — verify `AppColors.success`, `AppColors.warning`, `AppColors.error` exist; add to `lib/core/theme/app_colors.dart` if missing
- `Color(0x66F98C1F)` (primary at 40% opacity) — add `AppColors.primarySubtle` or use `context.colorScheme.primary.withValues(alpha: 0.4)`
- `surfaceTintColor: Colors.transparent` — acceptable Flutter idiom for removing Material3 surface tint; annotate `// Intentional: remove Material3 surface tint`
- Gradient overlay stops with `Colors.transparent` — annotate `// Intentional: gradient stop`

**Acceptance criteria:**
- [ ] `grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] `grep -rn "Colors\." lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results (or ≤5 fully justified exceptions all annotated)
- [ ] Any new color constants are added to `lib/core/theme/app_colors.dart` with a named identifier
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — purely cosmetic; colors in build methods have no behavioral side effects. Gradient stops and `surfaceTintColor` are the main ambiguity but do not affect behavior.

**Effort:** M (2–3h)

---

### REFACTOR-12: Document or resolve `bool isLoadingMore` in NotificationsState

**Violation type:** Primitive boolean flag for a loading state in a `@freezed` state class, where `ResultState<T>` is the required pattern.

**Files affected:**
- `lib/features/notifications/presentation/cubit/notifications_state.dart`
- `lib/features/notifications/presentation/cubit/notifications_cubit.dart`
- `lib/features/notifications/presentation/widgets/notifications_data_view.dart`
- `lib/features/notifications/presentation/notifications_view.dart`

**Decision:** `isLoadingMore` represents incremental pagination loading (appending to an existing list), which is distinct from the primary `listResult: ResultState<List<NotificationModel>>`. The correct resolution is:

- **Option A (recommended for this iteration):** Keep `bool isLoadingMore` and add a comment in `notifications_state.dart`: `// Exception: isLoadingMore is a secondary loading indicator for cursor-based pagination append. It cannot be replaced by a second ResultState<List> because listResult must remain in Data state while additional pages are loading.`
- **Option B (full compliance, deferred):** Replace with a second `ResultState<List<NotificationModel>> paginationResult` field and merge results in the cubit.

**Acceptance criteria:**
- [ ] `notifications_state.dart` contains either: (a) the `// Exception:` comment on the `isLoadingMore` field OR (b) zero `bool isLoadingMore` fields (Option B)
- [ ] `dart analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with 0 regressions

**Risk:** Low — Option A is a single comment addition. Option B requires regenerating the freezed file.

**Effort:** S (<1h for Option A)

---

## Iteration totals

| Stories | Total effort | Estimated days | Risk level |
|---------|-------------|----------------|------------|
| 12 stories | S×4 + M×4 + L×3 ≈ 34–46h raw work | 5–6 developer days | Medium (SOAT consolidation + large widget files are the risk drivers) |

Effort breakdown:
- S stories (REFACTOR-01, 07, 08, 10, 12): ~6–8h
- M stories (REFACTOR-02, 04, 09, 11): ~12–14h
- L stories (REFACTOR-03, 05, 06): ~18–23h

---

## Recommended execution order

Execute in this order to minimize risk and avoid rework:

1. **REFACTOR-01** — bug fix, no dependencies, immediate UX win
2. **REFACTOR-02** — SOAT consolidation; auto-resolves 10 of the 29 Navigator.of calls in REFACTOR-09
3. **REFACTOR-08** — quick win, no dependencies (5 file changes)
4. **REFACTOR-07** — quick win, no dependencies (6 file changes)
5. **REFACTOR-10** — quick win, no dependencies (4 files)
6. **REFACTOR-12** — trivial comment addition
7. **REFACTOR-11** — color tokenization; some files overlap with widget-extraction stories; do color work on already-modified files to avoid duplicate PRs
8. **REFACTOR-09** — remaining Navigator.of migrations (REFACTOR-02 has already removed the bulk)
9. **REFACTOR-04** — auth widget extraction; isolated feature, low regression risk
10. **REFACTOR-06** — maintenance + home + profile + registration extraction; medium blast radius
11. **REFACTOR-03** — vehicles widget extraction (largest single file with 16 widgets)
12. **REFACTOR-05** — events widget extraction (most files, highest test coverage risk); run `flutter test` after each extracted widget

---

## Definition of Done (iteration-level)

- [ ] `dart analyze lib/` returns 0 errors, 0 warnings
- [ ] `flutter test` passes — all pre-existing tests pass, 0 new failures
- [ ] `find lib/features -name "*.dart" | xargs grep -lc "extends StatelessWidget\|extends StatefulWidget\|extends PreferredSizeWidget" | while read line; do file=$(echo "$line" | cut -d: -f1); count=$(echo "$line" | cut -d: -f2); if [ "$count" -gt 1 ]; then echo "$count $file"; fi; done` returns 0 lines (every feature file has ≤1 widget class)
- [ ] `grep -rn "Widget _build\|Widget _[a-z]" lib/features/ --include="*.dart" | grep -v "//"` returns 0 results (no widget-returning methods)
- [ ] `grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] `grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"` returns 0 results
- [ ] `grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"` returns 0 results
- [ ] `grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] `grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"` returns 0 results
- [ ] `find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l` returns 0 (legacy SOAT folder deleted)
- [ ] Manual smoke test: SOAT upload flow (vehicle detail badge → upload page → status page) works end to end
- [ ] Manual smoke test: Login → Forgot Password → back to Login navigates correctly
- [ ] Manual smoke test: Event detail CTA bar renders in all state variants (registered / pending / closed / full)

---

## Risks

- **SOAT router consolidation (REFACTOR-02):** The `/vehicles/soat` route and all cross-imports (including `soat_status_view.dart` importing `SoatManualCapturePage` from the legacy folder) must all be updated before the legacy folder is deleted. Missing one import causes a compile error. Mitigation: run `grep -r "vehicles/presentation/soat" lib/` before deleting and fix all results first.

- **Widget extraction with shared state (REFACTOR-03, 05, 06):** Files like `garage_vehicles_content.dart` (16 classes) likely have inner private widget classes that access parent state or callbacks via closure. Extracting them requires converting closures to explicit constructor parameters or lifting state to the cubit. Never extract a widget that reads parent `State<T>` fields directly; convert to constructor params first.

- **Navigator.of pop-with-result (REFACTOR-09):** Bottom sheets that return a value via `Navigator.of(context).pop(result)` cannot be replaced with `context.pop(result)` without verifying the caller's `showModalBottomSheet` return future is consumed. Review each of the 14 non-SOAT files individually before replacing.

- **Color tokenization gaps (REFACTOR-11):** Some status colors (`#22C55E` success green, `#EAB308` warning yellow, `#EF4444` danger red) may not yet have named constants in `AppColors`. Adding them requires updating `lib/core/theme/app_colors.dart` and running `dart analyze`. Audit `AppColors` first and add missing constants before replacing literals.

- **Test stability during widget extraction (REFACTOR-03, 05, 06):** Existing widget tests reference finders by type (e.g. `find.byType(EventCard)`). Extracting private inner classes changes the widget tree and may break finder assertions. Run `flutter test` after each extracted story, not only at the end of the iteration.

---

## Deferred

- **`app_place_suggestions_dropdown.dart` `Widget _buildContainer()` method:** Lives in `lib/shared/widgets/` (not `lib/features/`), outside primary feature scope. Defer to a shared-widgets cleanup pass.
- **`splash_screen.dart` (2 widgets):** Deferred if it conflicts with iter-1's redesign scope (Story 1.2 touched this file). Evaluate during REFACTOR-06 pre-flight.
- **Full replacement of `bool isLoadingMore` with `ResultState`** (Option B of REFACTOR-12): Deferred unless full compliance is explicitly required this iteration.
- **Patrol integration test `native` deprecations:** These are Patrol framework warnings, not Rideglory code. Explicitly out of scope per PRD §4.
