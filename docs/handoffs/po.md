# PO Handoff — Iteration 6 (refactor-01)

**Date:** 2026-05-27
**Status:** in progress
**Type:** REFACTORING ONLY — zero new features, zero API changes, zero DB changes

---

## Iteration goal

Eliminate the accumulated technical debt across 68+ feature files by performing a pure internal Flutter refactor: fix the SOAT loading-button bug, consolidate the duplicate SOAT implementation, extract one widget class per file across all features, replace raw Flutter primitives with design-system equivalents, tokenize all hardcoded color literals, migrate remaining Navigator.of usage to go_router, centralize the form nav header pattern into a shared molecule, and reduce the localization file by ≥10% — leaving `dart analyze` at zero warnings and the codebase mechanically compliant with every rule in `rideglory-coding-standards.mdc`, with zero functional or visual changes for end users.

---

## Stories for this iteration

> **Framing note:** This is a pure refactor iteration. All stories are framed as developer-persona violations because there are zero rider- or organizer-facing behavioral changes. Acceptance criteria are mechanical grep/find checks, not user-observable behaviors.

| ID | Story | Acceptance criteria (summary — full detail in PLAN.md) | Primary agent |
|----|-------|--------------------------------------------------------|---------------|
| US-6-1 | As a developer, I want the SOAT loading-button bug (changing label to "Descargando…" instead of passing `isLoading: true`) corrected so that `AppButton`'s native loading-spinner contract is honored consistently across the app. | `grep "soat_downloading" soat_data_view.dart` = 0; `grep "isLoading: _openingDocument"` = 1; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-2 | As a developer, I want the duplicate SOAT implementation consolidated into `features/soat/` and `vehicles/presentation/soat/` deleted so that no dead code or dual-import paths remain in the router or the codebase. | `find lib/features/vehicles/presentation/soat -name "*.dart" \| wc -l` = 0; `grep -r "vehicles/presentation/soat" lib/` = 0; router `/vehicles/soat` route kept + wired to new `SoatUploadPage`; `soatManualCapture` named route added; `dart run build_runner build` succeeds; 4 manual SOAT smoke tests pass. | frontend |
| US-6-3 | As a developer, I want all `context.goNamed()` navigation calls in feature files either annotated as intentional shell-tab resets or replaced with `context.pop()` so that navigation semantics match go_router conventions. | `grep -rn "context\.goNamed" lib/features/ \| grep -v "// Intentional:"` = 0; 3 shell-tab calls annotated; 2 `forgot_password_view.dart` calls replaced with `context.pop()`. | frontend |
| US-6-4 | As a developer, I want all `FormBuilderTextField` usages in feature files replaced with `AppTextField` so that the shared text field component is adopted uniformly across 4 affected files. | `grep -rn "FormBuilderTextField" lib/features/` = 0; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-5 | As a developer, I want all raw `ElevatedButton`, `TextButton`, and `OutlinedButton` usages in feature files replaced with `AppButton`/`AppTextButton` (or annotated with `// Custom:` where genuinely necessary) so that the design system's button contract is enforced. | `grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ \| grep -v "// Custom:"` = 0; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-6 | As a developer, I want direct `showDialog(...)` calls in feature files replaced with `AppDialog`/`ConfirmationDialog` wrappers (or annotated where the wrapper does not apply) so that dialog creation follows the design system contract. | `grep -rn "showDialog(" lib/features/ \| grep -v "// Custom:\|AppDialog\|ConfirmationDialog"` = 0; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-7 | As a developer, I want all hardcoded `Color(0x...)` and `Colors.*` literals in feature build methods replaced with `AppColors.*` or `colorScheme.*` tokens (with new tokens `statusGreen`/`statusWarning`/`statusError`/`primarySubtle` committed first) so that color intent is expressed through the design token system. | New tokens committed first; `grep -rn "Color(0x" lib/features/ \| grep -v "// Intentional:"` = 0; `grep -rn "Colors\." lib/features/ \| grep -v "// Intentional:"` = 0 or ≤5 annotated exceptions; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-8 | As a developer, I want the Authentication feature (forgot_password_view.dart · 9 widgets, login_view.dart · 8 widgets, signup_view.dart · 6 widgets) refactored to one widget class per file so that the one-widget-per-file rule is enforced and each component is independently testable. | `find lib/features/authentication` widget-class check = 0 lines; `grep "Widget _build" lib/features/authentication/` = 0; manual smoke tests pass (Login↔ForgotPassword, Signup end-to-end). | frontend |
| US-6-9 | As a developer, I want `garage_vehicles_content.dart` (16 widgets + 2 widget-returning methods) and `vehicle_detail_view.dart` (13 widgets) each split into individual one-class files so that the vehicle garage is independently composable and each extracted widget is a testable leaf. | `find lib/features/vehicles/presentation/garage` widget-class check = 0 lines; `grep "Widget _build" lib/features/vehicles/presentation/garage/` = 0; `dart analyze` 0 errors; `flutter test` 0 regressions after each extracted widget commit. | frontend |
| US-6-10 | As a developer, I want the vehicle form files (vehicle_form.dart · 9, vehicle_document_upload_slot.dart · 4, vehicle_form_page.dart · 2, vehicle_form_cover_section.dart · 4, vehicle_form_id_section.dart · 3, vehicle_form_docs_section.dart · 2, vehicle_card.dart · method) each split to one widget class per file, maintaining the `GlobalKey<FormBuilderState>` constructor-injection pattern. | `find lib/features/vehicles/presentation` widget-class check = 0 lines; `grep "Widget _build" lib/features/vehicles/presentation/` = 0; `vehicle_form_page.dart` `// Custom:` annotations preserved; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-11 | As a developer, I want the Events detail cluster (event_detail_view.dart · 9, event_detail_cta_bar.dart · 8 + `_buildContent` method, plus 5 additional detail files) each split to one widget class per file, preserving the `onEdit` callback pattern and documenting the `EventRouteMapScreen` unnamed-push decision. | `find lib/features/events/presentation/detail` widget-class check = 0 lines; `grep "Widget _buildContent\|Widget _shell" lib/features/events/presentation/detail/` = 0; event detail CTA bar manual smoke test (all 4 state variants) passes — HARD AC. | frontend |
| US-6-12 | As a developer, I want the Events form/list/tracking/drafts cluster (19 source files with 2–7 widgets each, plus 2 widget-returning methods) each split to one widget class per file so that form sections, list items, and tracking overlays are individually composable. | `find lib/features/events/presentation/form lib/features/events/presentation/tracking lib/features/events/presentation/list lib/features/events/presentation/drafts` widget-class check = 0 lines; `grep "Widget _buildEmptyState\|Widget _buildRiderList\|Widget _buildPopupMenu" lib/features/events/` = 0; existing event widget tests still pass. | frontend |
| US-6-13 | As a developer, I want the Maintenance feature (maintenance_filters_bottom_sheet.dart · 12 widgets, plus 6 additional files, plus the `info_chip_tooltip.dart` showDialog violation) refactored to one widget class per file, extracting only the stateless sub-components and keeping the outer `StatefulWidget` + `State` pair intact. | `find lib/features/maintenance` widget-class check = 0 lines; `grep "Widget _rightBadge" lib/features/maintenance/` = 0; `maintenance_filters_bottom_sheet.dart:95` migrated to `context.pop(_filters)`; manual smoke test (maintenance filters apply) passes. | frontend |
| US-6-14 | As a developer, I want the Home, Profile, Users, and EventRegistration features (13 source files with 2–5 widgets each) each split to one widget class per file so that the one-widget-per-file rule is enforced across all remaining features. | `find lib/features/home lib/features/profile lib/features/users lib/features/event_registration` widget-class check = 0 lines; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-15 | As a developer, I want all remaining `Navigator.of(context).push*/pop()` and `Navigator.pop(context)` calls in feature files migrated to `context.pop()` / `context.push()` go_router equivalents (or annotated with `// Custom:` for justified exceptions), so that navigation is managed exclusively through go_router in feature code. | `grep -rn "Navigator\.of(context)\." lib/features/ \| grep -v "// Custom:"` = 0; `grep -rn "Navigator\.pop(context" lib/features/ \| grep -v "SystemNavigator\|// Custom:"` = 0; manual smoke tests for maintenance filters (pop-with-result) and garage options (archive/delete/set-main) pass. | frontend |
| US-6-16 | As a developer, I want the form navigation header pattern (`VehicleFormNavHeader`, `MaintenanceFormNavHeader`, inline `AppBar` in `event_form_view.dart`) centralized into a single `AppFormNavHeader` molecule in `lib/design_system/molecules/` so that any future design change to the form header is made in one place. | `lib/design_system/molecules/app_form_nav_header.dart` exists; `grep -rn "VehicleFormNavHeader\|MaintenanceFormNavHeader" lib/` = 0; `event_form_view.dart` uses `AppFormNavHeader`; visual regression smoke test (screenshots before/after for all 3 forms) confirms identical rendering; `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |
| US-6-17 | As a developer, I want `lib/l10n/app_es.arb` audited for unused and duplicate keys — reducing total key count by ≥10% (from 1357 to ≤1220) — so that the localization file is easier to navigate and maintain, and no dead keys inflate generated code. | Audit report committed (keys before/after, list of deleted keys, list of unifications); `grep` for all `context.l10n.*` usages produces a subset of current ARB keys (no missing-key references); `flutter gen-l10n` run and generated files committed; 15-screen manual navigation confirms all texts render correctly (no missing-translation strings); `dart analyze` 0 errors; `flutter test` 0 regressions. | frontend |

---

## Story-to-REFACTOR mapping

| Story ID | REFACTOR ID | Linear execution order |
|----------|-------------|----------------------|
| US-6-1 | REFACTOR-01 | 1st |
| US-6-2 | REFACTOR-02 | 2nd |
| US-6-3 | REFACTOR-10 | 3rd |
| US-6-4 | REFACTOR-08 | 4th |
| US-6-5 | REFACTOR-07 | 5th |
| US-6-6 | REFACTOR-13 | 6th |
| US-6-7 | REFACTOR-11 | 7th |
| US-6-8 | REFACTOR-04 | 8th |
| US-6-9 | REFACTOR-03a | 9th |
| US-6-10 | REFACTOR-03b | 10th |
| US-6-11 | REFACTOR-05a | 11th |
| US-6-12 | REFACTOR-05b | 12th |
| US-6-13 | REFACTOR-06a | 13th |
| US-6-14 | REFACTOR-06b | 14th |
| US-6-15 | REFACTOR-09 | 15th |
| US-6-16 | REFACTOR-14 | 16th |
| US-6-17 | REFACTOR-15 | 17th |
| *(inline with 6-2)* | REFACTOR-12 | Trivial — after US-6-2 |

> REFACTOR-12 (document `bool isLoadingMore` exception) is a trivial single-comment addition; it maps to no standalone US story and is bundled with T-6-2 (frontend carries it as part of the REFACTOR-02 clean-baseline work).

---

## Scope decisions

1. **Backend is fully stand-down.** No API contracts, no DTO changes, no DB migrations, no rideglory-api changes in this iteration. The backend agent does not execute.

2. **Design is light.** No new screens. No new Pencil frames. The only design-phase output is the `AppFormNavHeader` molecule specification (US-6-16, REFACTOR-14) — the architect will define the API (`AppFormNavAction` sealed class, height, border params); the frontend implements it. No mockups, no HTML screens, no Pencil inspections needed.

3. **Frontend is the dominant phase.** 17 stories, all single-agent (frontend). Tasks are ordered by the linear execution sequence in PLAN.md. Each task should be committed independently to keep rollback scope minimal.

4. **AI cover and Mapbox features must remain functional throughout.** These are mandatory regression smoke tests (not just nice-to-have):
   - AI cover generation: generate cover → select image → save event → confirm functional.
   - Mapbox route preview in event form: renders correctly post-extraction.
   These are encoded as QA hard gates in T-6-18.

5. **`lib/core/http/api_base_url_resolver.dart` is intentionally NOT in scope.** The `dead_code` and `prefer_const_declarations` warnings at line 17–19 exist because the dev-toggle condition (`kIsWeb`) is a known dead branch on mobile. This file is under active dev modification and must not be touched in this refactor.

6. **`context.goNamed()` in shell-tab PopScope (profile, garage, events pages) is intentionally preserved.** These 3 calls are NOT violations — they must remain as `context.goNamed()` to reset the `StatefulShellRoute` stack correctly. They will be annotated with `// Intentional: shell-tab navigation resets stack…` per REFACTOR-10.

7. **`Navigator.of` justified exceptions are annotated, not migrated.** Two categories of justified exceptions (already identified in PLAN.md): `vehicle_form_page.dart` `pushReplacement` (stack must not include VehicleFormPage after SOAT confirmation) and `soat_manual_capture_page.dart` modal bottom sheet `pop(0/1/2)` calls (required for typed-result `showModalBottomSheet` pattern).

---

## Assumptions

a. **`dart analyze` baseline on iter-6 starting point must be captured before any refactor begins.** The QA task (T-6-18) must record the exact pre-refactor warning/error count so the "zero new warnings/errors" criterion is verifiable. (Expected: 2 warnings in `api_base_url_resolver.dart` which are out-of-scope; 0 elsewhere.)

b. **`flutter test` baseline must be captured before refactor begins.** The pre-existing failing test (TC-2-28, unrelated to this iteration) must be documented as pre-existing so QA does not flag it as a regression.

c. **The 1357-key `app_es.arb` is the confirmed baseline for REFACTOR-15.** The ≥10% reduction target (to ≤1220 keys) is based on this count. If a pre-audit reveals the file has grown, the target adjusts proportionally.

d. **No new packages are introduced.** All component replacements (`AppButton`, `AppTextField`, `AppDialog`, `AppFormNavHeader`) use existing production dependencies. The `AppFormNavHeader` molecule is a new Dart file, not a new `pubspec.yaml` dependency.

e. **SOAT consolidation (US-6-2 / REFACTOR-02) is the highest-risk story.** Five external files import from the legacy folder; 6 active callers use `AppRoutes.vehicleSoat`; a new named route for `SoatManualCapturePage` must be created; DI must be regenerated after deleting `SoatUploadCubit`. The developer must run `grep -r "vehicles/presentation/soat" lib/` before any file deletion to verify the full blast perimeter.

f. **Color token additions precede color literal replacement.** `AppColors.statusGreen`, `AppColors.statusWarning`, `AppColors.statusError`, and `AppColors.primarySubtle` must be committed to `lib/core/theme/app_colors.dart` as the very first commit of US-6-7 (REFACTOR-11). Replacing existing literals with existing `AppColors.success`/`.warning` would change the rendered color — these are distinct hex values.

---

## Risks

| Risk | Probability | Mitigation |
|------|-------------|------------|
| SOAT consolidation blast perimeter — missed import causes compile error | High | Run `grep -r "vehicles/presentation/soat" lib/` before any deletion; fix all results first |
| Widget extraction with shared state (garage_vehicles_content.dart · 16, event_detail_cta_bar.dart · 8) causes silent runtime rendering failure | High | Extract one widget per commit; run `flutter test` after each commit |
| Event CTA bar has no widget tests — extraction failure is silent at compile time | High | Manual smoke test of all 4 CTA state variants (registered/pending/closed/full) is a HARD AC |
| Color token mismatch — `Color(0xFF22C55E)` differs from `AppColors.success` | Medium | New `statusGreen`/`statusWarning` tokens committed first; no blind mapping to existing tokens |
| `Navigator.pop(context)` form (without `.of`) is invisible to standard grep | Medium | DoD includes a separate grep: `grep -rn "Navigator\.pop(context"` |
| REFACTOR-15 ARB cleanup removes a dynamically-referenced key — runtime crash (not compile-time) | Medium | Run `flutter gen-l10n` + debug app before each mass-deletion batch; commit per phase |

---

## Tasks created

| Task ID | Story | Description | Agent | Status |
|---------|-------|-------------|-------|--------|
| T-6-1 | US-6-1 | Fix SOAT loading-button bug in `soat_data_view.dart`: replace label swap with `isLoading: _openingDocument`; verify `AppButton.isLoading` disables `onPressed` internally | frontend | backlog |
| T-6-2 | US-6-2 | Consolidate SOAT feature: MOVE 6 files to `features/soat/`; DELETE 9 legacy files; update router + routes + 5 import sites; add `SoatManualCaptureParams`; annotate 3 justified Navigator exceptions; run `dart run build_runner build`; also add `// Exception:` comment for REFACTOR-12 (`isLoadingMore`) | frontend | backlog |
| T-6-3 | US-6-3 | Fix `context.goNamed` violations: annotate 3 shell-tab calls; replace 2 `forgot_password_view.dart` calls with `context.pop()` | frontend | backlog |
| T-6-4 | US-6-4 | Replace all 5 `FormBuilderTextField` usages (4 files) with `AppTextField` | frontend | backlog |
| T-6-5 | US-6-5 | Replace 8 raw Flutter button usages across 6 files with `AppButton`/`AppTextButton`; annotate any SOS overlay `OutlinedButton` if `AppButton` does not cover the style; update `rider_profile_page_test.dart` if it uses `find.byType(ElevatedButton)` | frontend | backlog |
| T-6-6 | US-6-6 | Fix direct `showDialog(...)` in `info_chip_tooltip.dart`: replace with `AppDialog` or annotate `// Custom:` if `AppDialog` requires action buttons; also replace `Colors.black.withValues` with `AppColors.*` or `colorScheme.*` | frontend | backlog |
| T-6-7 | US-6-7 | Commit new color tokens to `lib/core/theme/app_colors.dart` (statusGreen, statusWarning, statusError, primarySubtle) as first commit; then tokenize all `Color(0x...)` and `Colors.*` literals across 25+ affected files | frontend | backlog |
| T-6-8 | US-6-8 | Widget extraction — Authentication: split `forgot_password_view.dart` (9), `login_view.dart` (8), `signup_view.dart` (6) into one-widget-per-file; create `widgets/` subdirectory for 4+ extracted classes; manual smoke tests | frontend | backlog |
| T-6-9 | US-6-9 | Widget extraction — Vehicles garage: split `garage_vehicles_content.dart` (16 + 2 methods) and `vehicle_detail_view.dart` (13) into one-widget-per-file; classify each class as pure-display / state-consumer / state-mutator before extracting; extract one widget per commit; run `flutter test` after each commit | frontend | backlog |
| T-6-10 | US-6-10 | Widget extraction — Vehicles form: split 7 vehicle form files; maintain `GlobalKey<FormBuilderState>` constructor-injection; preserve `vehicle_form_page.dart` `// Custom:` annotations | frontend | backlog |
| T-6-11 | US-6-11 | Widget extraction — Events detail: split 7 detail files; extract `EventDetailCtaBarContent` and ~8 CTA variant widgets to `detail/widgets/cta/`; document `EventRouteMapScreen` unnamed-push decision; hard AC: all 4 CTA state variants smoke-tested | frontend | backlog |
| T-6-12 | US-6-12 | Widget extraction — Events form/list/tracking/drafts: split 19 source files (2–7 widgets each) into one-widget-per-file; document `EventRouteConfigScreen` unnamed-push decision; verify existing event widget tests still pass | frontend | backlog |
| T-6-13 | US-6-13 | Widget extraction — Maintenance: split 6 files including `maintenance_filters_bottom_sheet.dart` (12 widgets, keep outer StatefulWidget + State pair); migrate `Navigator.pop(context, _filters)` → `context.pop(_filters)`; manual smoke test filters | frontend | backlog |
| T-6-14 | US-6-14 | Widget extraction — Home + Profile + Users + EventRegistration: split 13 source files across 4 features | frontend | backlog |
| T-6-15 | US-6-15 | Migrate remaining `Navigator.of(context).push*/pop()` and `Navigator.pop(context)` calls to go_router `context.pop()` / `context.push()`; document and annotate all 6 `Navigator.pop(context)` form calls; annotate justified exceptions; manual smoke tests | frontend | backlog |
| T-6-16 | US-6-16 | Create `AppFormNavHeader` molecule + `AppFormNavAction` sealed class in `lib/design_system/molecules/`; migrate `VehicleFormNavHeader`, `MaintenanceFormNavHeader`, and `event_form_view.dart` AppBar inline; delete old feature-level nav header files; screenshot before/after smoke test | frontend | backlog |
| T-6-17 | US-6-17 | Audit `app_es.arb` (Phase 1: unused keys; Phase 2: duplicates; Phase 3: apply + gen); target ≥10% reduction from 1357 to ≤1220 keys; commit per phase for rollback; 15-screen navigation smoke test | frontend | backlog |
| T-6-18 | — (QA gate) | QA full iteration gate: (1) capture `dart analyze` + `flutter test` baseline on iter-6 pre-refactor; (2) verify all DoD grep checks pass post-refactor; (3) run 7 manual smoke tests: SOAT upload→confirmation→status, SOAT vehicle creation, Login↔ForgotPassword, Event detail CTA bar all 4 variants, Maintenance filters apply, Garage options archive/delete/set-main, Signup end-to-end; (4) AI cover generation regression: generate cover → select → save event → confirm functional; (5) Mapbox route preview regression: renders in event form post-extraction; (6) confirm `api_base_url_resolver.dart` was NOT touched (its 2 warnings must remain and are acceptable) | qa | backlog |
| T-6-19 | — (DevOps gate) | DevOps no-op CI verification: confirm `dart analyze` and `flutter test` pass in CI on the iter-6 branch; no new packages in `pubspec.yaml`; no new build steps; CI pipeline unchanged | devops | backlog |

---

## Assumptions and open questions

- **open:** `AppButton.isLoading` — does it internally guard `onPressed` or does the caller need to also pass `onPressed: null`? Developer must verify in `app_button.dart` before implementing US-6-1.
- **open:** `AppDialog` — does it support info-only dialogs (no action buttons)? Developer must verify before implementing US-6-6; annotate `// Custom:` if not.
- **open:** `AppButton` outline variant — does `AppButton` expose an `OutlinedButton`-style variant for the SOS overlay? Verify before implementing US-6-5.
- **open:** `EventRouteConfigScreen` and `EventRouteMapScreen` — unnamed routes. Developer must choose: (A) add named routes to `app_router.dart` + `app_routes.dart`, or (B) annotate `// Custom: screen has no go_router named route — anonymous push preserved`. Decision must be documented in PR description.
- **assumed:** `dart analyze` baseline on iter-6 = 2 warnings in `api_base_url_resolver.dart` + 0 elsewhere. QA must confirm before refactor begins.

---

## Out of scope (this iteration)

- **New features of any kind:** No new rider/organizer-visible functionality.
- **Backend changes:** No API endpoints, no schema changes, no DTO modifications.
- **`api_base_url_resolver.dart`:** Intentionally excluded; 2 warnings are accepted as a known active-dev artifact.
- **Patrol integration tests:** Deprecation warnings in `native` calls are framework-level; not app code.
- **Profile photo upload:** Deferred post-MVP (no Prisma schema).
- **OCR auto-fill for SOAT:** Deferred post-MVP.
- **Any new Pencil design frames:** No new screens, no redesigns.
- **`lib/features/events/presentation/tracking/widgets/live_map_app_bar.dart`:** Already compliant (transparent overlay pattern); excluded from AppFormNavHeader centralization.
- **`lib/features/maintenance/presentation/list/maintenances/widgets/maintenances_page_app_bar.dart`:** Already uses `AppAppBar`; no change needed.

---

## Bridge for Architect

The Architect needs to define the `AppFormNavHeader` component API (US-6-16 / REFACTOR-14) before T-6-16 can begin:

1. **Confirm the `AppFormNavAction` sealed class API:** The PLAN.md proposes `.text()`, `.icon()`, `.pillText()` factory variants. Architect should confirm or adjust, noting the Maintenance form's unique `bottom` slot for progress bars.
2. **Height parametrization:** Vehicle form uses 56px; Maintenance form uses 52px. The `height` parameter in `AppFormNavHeader` must accommodate both.
3. **`EventRouteConfigScreen` unnamed-push decision:** The Architect should make the authoritative call on Option A (add named route) vs. Option B (annotate `// Custom:`) and document it in the architect handoff to eliminate ambiguity for the frontend agent.
4. **REFACTOR-12 (`isLoadingMore`):** Architect should confirm Option A (add `// Exception:` comment, do not convert to `ResultState<T>`) is the approved exception pattern for cursor-based pagination loading state.
5. **No API changes are needed.** Backend stand-down is confirmed. Architect's work is constrained to Flutter-layer decisions only.

---

## Change log

- 2026-05-27: Iteration 6 (refactor-01) scoped. 17 user stories (US-6-1..US-6-17) mapped 1:1 to REFACTOR-01..15 (incl. 03a/b, 05a/b, 06a/b, 14, 15). 19 tasks (T-6-1..T-6-17 frontend + T-6-18 qa + T-6-19 devops). Backend stand-down confirmed. Design light (AppFormNavHeader API only). Frontend dominant phase. 7 smoke tests defined. REFACTOR-12 bundled with T-6-2.
