# Plan Review — Refactor & Cleanup (Refactor-01)

> Generated: 2026-05-27
> Author: Plan Reviewer Agent (UX quality + Flutter Clean Architecture)
> Input: PRD, PO proposal (01), Architect review (02), coding standards, dev checklist, existing tests, `event_detail_view.dart`, `garage_vehicles_content.dart`

---

## Completeness audit

| Violation (from PRD) | Covered by story | Gap? |
|---------------------|-----------------|------|
| Multiple widgets per file (68 files) — §3.1 | REFACTOR-03, 04, 05, 06 | **Partial gap** — all files inventoried, but REFACTOR-05 covers 26 source files (over safe PR limit); see Story Sizing |
| Widget-returning methods (`Widget _build*`) — §3.2 | REFACTOR-03, 05, 06 | No gap — all 8 files listed |
| Raw Flutter buttons (`ElevatedButton/TextButton/OutlinedButton`) — §3.3 | REFACTOR-07 | No gap — 25 occurrences, correct file list |
| `FormBuilderTextField` — §3.4 | REFACTOR-08 | No gap — all 5 occurrences |
| SOAT button text bug — §3.5 | REFACTOR-01 | No gap |
| `Navigator.of(context).push*` — §3.6 | REFACTOR-02 (legacy SOAT), REFACTOR-09 (remaining) | **Gap — scope undercount**: `Navigator.pop(context)` (without `.of`) in `garage_options_bottom_sheet.dart` (×3), `maintenance_options_bottom_sheet.dart` (×2), and `maintenance_filters_bottom_sheet.dart` (×1) are **not covered** by REFACTOR-09. The DoD grep `Navigator\.of(context)\.` does not match these forms. |
| `context.goNamed` instead of `context.pushNamed` — §3.7 | REFACTOR-10 | No gap |
| SOAT duplication — §3.8 | REFACTOR-02 | No gap (Architect conditions expand scope correctly) |
| Hardcoded colors — §3.9 | REFACTOR-11 | **Significant scope gap** — see below |
| `dart analyze` warnings — §3.10 | Implicitly covered by all story ACs | No explicit story; low risk since each story has `dart analyze` as an AC |
| `bool isLoadingMore` — §3.11 | REFACTOR-12 | No gap |
| `showDialog` called directly instead of `AppDialog`/`ConfirmationDialog` — coding standards §Components | **Not covered by any story** | **Missing violation** — `info_chip_tooltip.dart` calls `showDialog` directly in `lib/features/maintenance/presentation/widgets/item_card/` |

### REFACTOR-11 Color scope gap — quantified

The PO listed 7 files with `Color(0x...)` literals. Actual count verified from source is **25 files** across features. The 18 files missed by REFACTOR-11:

**Maintenance feature (10 files):** `maintenance_type_style.dart`, `maintenance_next_service_card.dart`, `maintenance_status_toggle.dart`, `maintenance_next_date_pill.dart`, `maintenance_next_km_pill.dart`, `maintenance_type_card.dart` (detail), `maintenance_grouped_list_item.dart`, `maintenances_data_widget.dart`, `maintenance_filters_bottom_sheet.dart`, `modern_maintenance_card.dart`

**Events feature (4 files):** `event_detail_view.dart`, `event_detail_cta_bar.dart`, `event_detail_owner_lifecycle_bar.dart`, `rider_telemetry_panel.dart`

**Vehicles feature (1 file):** `vehicle_maintenance_history_section.dart`

**Impact on DoD:** The acceptance criterion `grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"` will still fail if REFACTOR-11 only addresses the 7 listed files. REFACTOR-11 scope must expand to all 25 files or the DoD is unachievable.

### Color value mismatch — Architect Condition 5 partially incorrect

The Architect (Condition 5) recommends using `AppColors.success` (#10B981) and `AppColors.warning` (#F59E0B) as replacements. However, the hardcoded values in features are:
- `Color(0xFF22C55E)` = Tailwind `green-500` — **different** from `AppColors.success` (#10B981 = `emerald-500`)
- `Color(0xFFEAB308)` = Tailwind `yellow-500` — **different** from `AppColors.warning` (#F59E0B = `amber-500`)

Replacing these literally changes the rendered color in SOAT status badges and maintenance status indicators. The developer must decide: adopt the existing `AppColors` value (design alignment intent) or add new tokens (`AppColors.statusGreen`, `AppColors.statusYellow`). This decision must be made before REFACTOR-11 starts and documented as Condition 5B.

---

## UX preservation risks

### REFACTOR-01 — SOAT button tap-while-loading risk

The fix swaps `onPressed: _openingDocument ? null : _openDocument` to `onPressed: _openDocument` (always callable) while passing `isLoading: true`. If `AppButton` does **not** disable tap propagation internally when `isLoading == true`, this creates a double-tap bug where users can fire `_openDocument` while the document is already loading. Verify `lib/shared/widgets/form/app_button.dart` implementation before coding. If `AppButton` does not guard `onPressed` during loading, the correct fix is `isLoading: _openingDocument` AND `onPressed: _openingDocument ? null : _openDocument` together.

### REFACTOR-02 — `soat_manual_capture_page.dart` page-level Navigator calls

Lines 240 and 262 of `soat_manual_capture_page.dart` call `Navigator.of(context).pop(true)` and `Navigator.of(context).pop()` **at the page level** — these are NOT inside a `showModalBottomSheet` builder and are NOT the `sheetCtx` calls covered by the Architect's Condition 3. They are genuine violations that require migration to `context.pop(true)` and `context.pop()` during REFACTOR-02 (when the file is moved) or REFACTOR-09.

### REFACTOR-03 — Vehicles widget extraction state analysis

`garage_vehicles_content.dart` verified: all 16 inner classes use explicit constructor parameters (`_MainVehicleCard`, `_VehicleImageSection`, etc.) — no closure capture of parent `State<T>` fields observed. Extraction is structurally safe.

However, `_MaintenanceCard` (lines 676–842, 167 lines) uses inline `Color(0xFF22C55E)` and `Color(0xFFEAB308)` literals to derive maintenance status color. When these are extracted into their own files, the color literals move with them and still fail REFACTOR-11's DoD grep. Color tokenization must be addressed jointly in REFACTOR-03 or REFACTOR-11 — not left as a follow-up.

### REFACTOR-05 — `event_detail_view.dart` extraction safety

`EventDetailViewState` holds `currentEvent` as mutable local state. The 8 inner private widgets (`_HeroSection`, `_CircleButton`, `_OwnerMenuButton`, `_EventHeaderSection`, `_MetaSection`, `_AboutSection`, `_AllowedBrandsSection`, `_ParticipantsSection`) all receive `event` as a constructor parameter — no direct access to `EventDetailViewState`. Extraction is safe.

**Critical pattern to preserve:** `_HeroSection.onEdit` is passed as a `Future<void> Function()` from `EventDetailViewState` that calls `setState(() => currentEvent = result)`. After extraction, `onEdit` must remain as a typed callback on `_HeroSection`'s constructor. The `setState` call must stay inside `EventDetailViewState`. If the extracted `_HeroSection` tries to call `setState` directly or store `currentEvent` locally, the event model will diverge between the view and the widget.

**Navigator.of at line 275:** `EventDetailMeetingPointSection.onViewMap` calls `Navigator.of(context).push(MaterialPageRoute(...EventRouteMapScreen...))`. `EventRouteMapScreen` has **no named route** in `app_routes.dart`. REFACTOR-09 lists this as 1 call to fix but does not provide a path forward for the missing route. The developer must either add `AppRoutes.eventRouteMap` (scope increase) or annotate `// Custom:`. This decision must be explicit before REFACTOR-09 implementation.

**Lines 399, 417:** These are `Navigator.of(sheetCtx).pop()` inside a `showModalBottomSheet` builder using the bottom sheet's own `sheetCtx` — not a violation. Correct pattern. Architect Condition 3 annotation applies.

### REFACTOR-05 — `event_detail_cta_bar.dart` state variants

8 state-variant widgets in one file with a `_buildContent(BuildContext context)` method. After extraction, each variant (e.g., `EventDetailRegisteredBanner`, `EventDetailPendingBanner`) becomes its own file in `detail/widgets/cta/`. There are **no widget tests** for the CTA bar — extraction failures are silent at compile time. Add a manual smoke test for all 4 CTA state variants (registered / pending / closed / full) as a hard AC for REFACTOR-05a.

### REFACTOR-06 — `maintenance_filters_bottom_sheet.dart`

Confirmed `StatefulWidget` using `setState` to hold `_filters` as local state (as the Architect predicted). The outer `StatefulWidget` + `State` pair must stay in one file — only stateless sub-components (filter chips, section headers, type selectors) should be extracted. `Navigator.pop(context, _filters)` at line 95 is a pop-with-result that must be migrated to `context.pop(_filters)` (see REFACTOR-09 gap).

### Shared animation / scroll controller risk

No `ScrollController`, `AnimationController`, or `FocusNode` shared across inner widgets was observed in `garage_vehicles_content.dart` or `event_detail_view.dart`. No extraction-breaking shared animation state exists in the reviewed files.

---

## Clean Architecture compliance

### Post-REFACTOR-02 structure

The proposed structure (`features/soat/presentation/{pages,cubit,widgets}/`) is valid. All moved files stay within the `presentation` layer of `features/soat/`. `SoatFormCubit` is a presentation-layer cubit — moving it from `vehicles/presentation/soat/cubit/` to `features/soat/presentation/cubit/` is correct and creates no layer violation.

`SoatManualCapturePage` imports `SaveSoatUseCase` and `SoatModel` from the domain layer and `ImageStorageService` from the data layer. After the move, these import paths remain valid (same package). No new cross-feature imports introduced.

`SoatManualCaptureParams` (proposed as a new simple data class): contains only `VehicleModel?`, `SoatModel?`, and `String?` fields — no logic, no layer concerns. Belongs in `features/soat/presentation/pages/`. Confirm it does not import from `features/vehicles/` (it must not — the dependency direction flows via domain model types, not feature-to-feature).

### Extracted widgets layer placement

All extracted widgets from REFACTOR-03 through 06 land in `features/<feature>/presentation/<subdir>/widgets/`. This is the correct presentation layer placement. No domain or data layer code exists in the reviewed inner private widget classes. The extraction is clean.

### Domain isolation — `_MaintenanceWidget` in `garage_vehicles_content.dart`

`_MaintenanceWidget` calls `getIt<GetMaintenancesByVehicleIdUseCase>()` directly. This is a presentation→domain dependency via use case — architecturally correct. After extraction, the new file continues using `getIt` for the same use case. No violation.

---

## Story sizing recommendations

| Story | Input files (touch) | Est. new files created | Total file changes | Recommendation |
|-------|--------------------|-----------------------|--------------------|----------------|
| REFACTOR-01 | 1 | 0 | 1 | Approve as-is |
| REFACTOR-02 (expanded) | ~15 move/update | ~3 new | ~18 | Approve as-is |
| REFACTOR-03 | 10 | ~45 | **~55** | **SPLIT REQUIRED** |
| REFACTOR-04 | 3 | ~20 | ~23 | Borderline — acceptable |
| REFACTOR-05 | 26 | ~60+ | **~86+** | **SPLIT REQUIRED** |
| REFACTOR-06 | 19 | ~30 | **~49** | **SPLIT REQUIRED** |
| REFACTOR-07 | 6 | 0 | 6 | Approve as-is |
| REFACTOR-08 | 4 | 0 | 4 | Approve as-is |
| REFACTOR-09 (expanded) | ~14 | 0 | ~14 | Approve with scope expansion |
| REFACTOR-10 | 4 | 0 | 4 | Approve as-is |
| REFACTOR-11 (expanded) | ~25 | 0 | ~25 | Approve with scope expansion |
| REFACTOR-12 | 1 | 0 | 1 | Approve as-is |

### Required splits

**REFACTOR-03 → 03a + 03b:**
- **03a** — `garage_vehicles_content.dart` (16 widgets) + `vehicle_detail_view.dart` (13 widgets) only. ~29 file changes. Acceptable for a focused PR.
- **03b** — Remaining 8 vehicle files (`vehicle_form.dart`, `vehicle_form_id_section.dart`, `vehicle_document_upload_slot.dart`, etc.). ~25 file changes.

**REFACTOR-05 → 05a + 05b + 05c:**
- **05a — Event detail:** `event_detail_view.dart` (9), `event_detail_cta_bar.dart` (8), `event_detail_owner_lifecycle_bar.dart` (4), `event_detail_meeting_point_section.dart` (4), `event_detail_header*.dart`, `event_detail_by_id_page.dart`. ~35 file changes.
- **05b — Event form:** All `event_form_*_section.dart` files (7 files, 4–7 widgets each), `event_form_bottom_bar.dart`, `waypoint_item_card.dart`, `event_route_type_selector.dart`, `cover_preview_widget.dart`, `event_route_config_screen.dart`. ~30 file changes.
- **05c — List + tracking + drafts:** `participants_placeholder_page.dart`, `live_map_app_bar.dart`, `event_card.dart`, `events_data_view.dart`, `events_page_view.dart`, `event_card_header.dart`, `my_drafts_page.dart`. ~18 file changes.

**REFACTOR-06 → 06a + 06b:**
- **06a — Maintenance:** `maintenance_filters_bottom_sheet.dart` (12), `maintenances_page.dart` (3), `maintenance_detail_page.dart` (3), `maintenance_summary_widget.dart` (2), `maintenance_next_service_card.dart` (2), `maintenance_grouped_list_item.dart` (method), and `info_chip_tooltip.dart` (missing violation). ~18 file changes.
- **06b — Home + Profile + Registration:** 12 remaining files from the original REFACTOR-06 list. ~20 file changes.

**Updated iteration total: 15 stories** (was 12; adds 03b, 05b, 05c, 06b).

---

## DoD review

### Verified items

- `dart analyze lib/` — mechanically verifiable, correct
- `flutter test` — mechanically verifiable, correct
- SOAT folder deletion check (`find lib/features/vehicles/presentation/soat`) — correct
- `grep -rn "FormBuilderTextField"` — correct, unambiguous
- `grep -rn "context\.goNamed"` with `// Intentional:` exception — correct
- Manual smoke tests (SOAT, Login/ForgotPassword, Event detail CTA variants) — good coverage of highest-risk flows

### Missing from DoD

**1. DoD widget-class grep is BROKEN on macOS**

The proposed command `find lib/features -name "*.dart" | xargs grep -lc "extends StatelessWidget|..."` does not work on macOS. `grep -lc` on macOS outputs the count and filename on **separate lines** (not as `filename:count`), which breaks the `cut -d:` pipeline. The command silently returns 0 lines even when violations exist (verified locally). This is the most critical DoD gap.

**2. `Navigator.pop(context)` form not covered**

The DoD grep `Navigator\.of(context)\.` does not catch `Navigator.pop(context)` calls in `garage_options_bottom_sheet.dart` (×3), `maintenance_options_bottom_sheet.dart` (×2), and `maintenance_filters_bottom_sheet.dart` (×1). The DoD will show green while these violations remain.

**3. REFACTOR-11 Color scope gap not reflected in DoD**

The DoD criterion `grep -rn "Color(0x" lib/features/` will still fail after REFACTOR-11 if only 7 of 25 files are fixed. No DoD item currently blocks implementation of the partial 7-file scope.

**4. Missing manual smoke test: Maintenance filters**

`maintenance_filters_bottom_sheet.dart` uses `Navigator.pop(context, _filters)` to return filter state to the caller. After REFACTOR-09 migrates this to `context.pop(_filters)`, verify the `MaintenanceListPage` (or equivalent) still receives the result correctly. No current smoke test covers this flow.

**5. Missing manual smoke test: Garage options**

`garage_options_bottom_sheet.dart` has 3 `Navigator.pop(context)` calls (archive, delete, set-main). After migration, all three must function correctly.

### Suggested additions

```bash
# Replace the broken DoD widget-class check with:
find lib/features -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done
# Must return 0 lines

# Add to DoD — Navigator.pop form:
grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"
# Must return 0 results

# Add to REFACTOR-01 AC — verify AppButton callback guard:
# When isLoading: true, AppButton must not propagate onPressed. Confirm in app_button.dart.

# Add to REFACTOR-11 AC — document color value decision:
# Before touching any Color(0xFF22C55E) or Color(0xFFEAB308) literal, document
# whether to use existing AppColors.success/warning or add new AppColors.statusGreen/statusYellow tokens.
```

Additional smoke tests to add to DoD:
- Manual smoke: Maintenance list → open filters → select type → apply → list filters correctly
- Manual smoke: Garage → vehicle options (long-press or options button) → archive / delete / set main — all three actions function

---

## Missing violations found

### 1. `showDialog` called directly — not using `AppDialog`/`ConfirmationDialog` wrapper (MAJOR)

**File:** `lib/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart`

```dart
showDialog(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .4),  // also a Colors.* violation
  builder: (context) => MileageInfoDialog(...),
);
```

**Rule violated:** Coding standards §Components — "Prohibido llamar `showDialog(...)` directamente; usar los wrappers existentes."

`MileageInfoDialog` is a plain `StatelessWidget` without CTA buttons. If it does not fit the `AppDialog`/`ConfirmationDialog` contract (no action buttons), annotate with `// Custom: MileageInfoDialog is an info tooltip — AppDialog requires action buttons`. Otherwise migrate. This file must be added to **REFACTOR-06a**. Not listed in any current story.

### 2. `Navigator.pop(context)` form missing from REFACTOR-09 scope

**Files:**
- `garage_options_bottom_sheet.dart:108,125,149` — 3 simple `Navigator.pop(context)` calls
- `maintenance_options_bottom_sheet.dart:43,53` — 2 `Navigator.pop(context, MaintenanceAction.xxx)` calls with typed result
- `maintenance_filters_bottom_sheet.dart:95` — `Navigator.pop(context, _filters)` with typed result

The DoD grep `Navigator\.of(context)\.` does not match these. All 6 are genuine violations of the same rule. Must be added to REFACTOR-09 or REFACTOR-06 scope.

### 3. `event_form_locations_section.dart` pushes an unnamed screen

**File:** `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart:218`

Calls `Navigator.of(context).push(MaterialPageRoute(...EventRouteConfigScreen...))` — but `EventRouteConfigScreen` has **no named route** in `app_routes.dart`. REFACTOR-09 lists this as 1 call to fix, but without a named route, `context.pushNamed()` cannot be used. The developer must add `AppRoutes.eventRouteConfig` to `app_routes.dart` and `app_router.dart` **as part of REFACTOR-09** or annotate `// Custom:`. The current plan does not make this explicit.

### 4. `soat_manual_capture_page.dart` lines 240, 262 are page-level Navigator calls (not sheetCtx)

The Architect's Condition 3 covers only `Navigator.of(sheetCtx).pop(0/1/2)` (lines 103, 111, 119 — inside `showModalBottomSheet`). Lines 240 and 262 are at the page level:
- Line 240: `Navigator.of(context).pop(true)` — fired after successful SOAT save
- Line 262: `Navigator.of(context).pop()` — fired on discard

These are genuine violations to be migrated to `context.pop(true)` and `context.pop()` respectively during REFACTOR-02 (when the file is moved) or REFACTOR-09.

### 5. `Colors.white` and `Colors.black` used widely beyond REFACTOR-11 listed files

The verified grep found 143 `Colors.*` non-AppColors references in features (excluding `Colors.transparent`). The PO REFACTOR-11 file list covers ~12 files; the actual scope is substantially larger — especially in the maintenance feature (`maintenance_card_body.dart`, `maintenance_card_content.dart`, `vehicle_list_item.dart`, `maintenance_type_card.dart`, etc.) and vehicles feature (`garage_options_bottom_sheet.dart`, `vehicle_detail_header.dart`, `vehicle_form.dart`, etc.). Many of these use `Colors.white` inside `dark`-mode containers where `colorScheme.onSurface` or `colorScheme.onPrimary` would be semantically correct. REFACTOR-11's expanded scope must include these.

---

## Risk re-assessment

**Overall risk: Medium-High**

The 12-story (now 15-story after required splits) structure is sound. The violation inventory is comprehensive with the gaps noted above. The SOAT consolidation and large widget extraction stories are the primary risk drivers.

**Highest-risk story: REFACTOR-02 — SOAT consolidation**

Reason: 5 files import from the legacy folder (blast perimeter), 6 active callers use `AppRoutes.vehicleSoat`, a new named route for `SoatManualCapturePage` must be created, DI must be regenerated after deleting `SoatUploadCubit`, and 3 typed-result `Navigator.of().push<bool>()` calls in the blast perimeter must be migrated to `context.push<bool>()`. Any one step missed causes a compile error or silent runtime crash. All steps are identified by the Architect; the risk is execution completeness, not analysis.

**Second-highest risk: REFACTOR-05a — `event_detail_cta_bar.dart` extraction**

8 state-variant widgets sharing a CTA context with no existing widget tests. Extraction failures are silent at compile time — the app builds but the wrong CTA variant renders. Mandatory smoke test for all 4 state variants is a hard AC.

---

## Reviewer verdict

**APPROVED WITH ADDITIONS**

The PO proposal and Architect review form a solid, actionable plan. The violation inventory is accurate, the story sequencing is well-considered, and the Architect conditions address the two critical REFACTOR-02 gaps. The required additions below must be incorporated before a developer begins any story.

---

## Required additions to final plan

### 1. REQUIRED — Fix DoD widget-count command (broken on macOS)

Replace the `xargs grep -lc` command in the DoD and in each story's AC with:

```bash
find lib/features -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done
# Must return 0 lines
```

### 2. REQUIRED — Expand REFACTOR-09 scope to include `Navigator.pop(context)` form

Add to REFACTOR-09 files list:
- `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` (3 simple pops)
- `lib/features/maintenance/presentation/detail/widgets/maintenance_options_bottom_sheet.dart` (2 pops with result)
- `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` (1 pop with result — verify `showModalBottomSheet` caller reads the returned `Future`)

Add to REFACTOR-09 AC and DoD:
```bash
grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"
# Must return 0 results
```

### 3. REQUIRED — Expand REFACTOR-11 to all 25 Color(0x...) files

Add to REFACTOR-11 files list (16 additional files — see Completeness audit above for full list). Note: for maintenance and events files that REFACTOR-06a and REFACTOR-05a are already modifying during widget extraction, the color tokenization should be done **in the same commit** as extraction to avoid double-editing the same files.

### 4. REQUIRED — Condition 5B: Resolve color value mismatch before REFACTOR-11

Add to REFACTOR-11 description:

Before touching any `Color(0xFF22C55E)` or `Color(0xFFEAB308)` literal, document the decision:

- **Option A:** Map to existing `AppColors.success` (#10B981) and `AppColors.warning` (#F59E0B) — changes rendered color; requires design sign-off.
- **Option B (recommended):** Add `AppColors.statusGreen = Color(0xFF22C55E)` and `AppColors.statusYellow = Color(0xFFEAB308)` to `lib/design_system/foundation/theme/app_colors.dart` — preserves exact current color, extends token palette.

The decision must be the first commit of REFACTOR-11.

### 5. REQUIRED — Add `showDialog` violation to REFACTOR-06a

Add to REFACTOR-06a files list:
- `lib/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart`

Decision for developer: if `MileageInfoDialog` (info tooltip, no CTA buttons) does not fit the `AppDialog` contract, annotate `// Custom: MileageInfoDialog is an info-only tooltip — AppDialog requires action buttons`. Otherwise migrate.

### 6. REQUIRED — Add explicit decision for unnamed screen pushes in REFACTOR-09

Add to REFACTOR-09 description for `event_form_locations_section.dart:218` and `event_detail_view.dart:275`:

`EventRouteConfigScreen` and `EventRouteMapScreen` have no named routes in `app_routes.dart`. Developer must choose:
- **Option A:** Add named routes to `app_routes.dart` + `app_router.dart` and migrate to `context.pushNamed()`.
- **Option B:** Annotate `// Custom: <screen> has no go_router named route — anonymous push preserved`.

Document the chosen option before implementation.

### 7. REQUIRED — Verify AppButton disables tap during loading (REFACTOR-01)

Add to REFACTOR-01 AC: Check `lib/shared/widgets/form/app_button.dart` — when `isLoading: true`, the button must not propagate `onPressed`. If it does not guard the callback, the correct fix is `isLoading: _openingDocument` AND `onPressed: _openingDocument ? null : _openDocument` (both conditions, not just `isLoading`).

### 8. REQUIRED — Split REFACTOR-03, 05, 06 per Story Sizing section

Split REFACTOR-03 → 03a + 03b, REFACTOR-05 → 05a + 05b + 05c, REFACTOR-06 → 06a + 06b. Revised iteration total: **15 stories**.

### 9. INFORMATIONAL — `soat_manual_capture_page.dart` lines 240, 262

These are page-level `Navigator.of(context).pop()` calls, not `sheetCtx.pop()` calls. They are not covered by Architect Condition 3. Handle during REFACTOR-02 (when the file is moved) or add to REFACTOR-09 explicitly.

### 10. INFORMATIONAL — `flutter test` after each extracted file (not just after each story)

The Architect's non-regression test gates recommend running `flutter test` after each extracted story. Given the split into 15 stories, the recommendation should be strengthened: run `flutter test` after **each extracted file** during REFACTOR-03a (the highest-risk extraction). The `garage_vehicles_content.dart` has 16 widgets — extract one per commit, run `flutter test` after each. Squash into a single PR only after all 16 pass.
