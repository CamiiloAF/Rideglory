# Frontend handoff — Iteration 6 (refactor-01)

> Status: **complete**
> Phase: frontend (5 of 10)
> Updated: 2026-05-27
> Branch: `iter-6`

## Summary

All 17 REFACTOR stories implemented across 4 batches (the 3rd batch was sub-divided into 3a/3b/3c due to scope). 80 commits on `iter-6` vs. `main`, ~346 files changed, +17180 / −19002 lines. `dart analyze lib/` returns **0 errors / 0 warnings**. `flutter test --reporter compact` returns **All tests passed!** (119 tests). Zero new test failures vs. iteration baseline.

## Batches executed

| Batch | Stories | Commits | Highlights |
|---|---|---|---|
| 1 | REFACTOR-01, 02 | 2 | SOAT button bug fix (`isLoading` instead of label switch); SOAT folder consolidated to `lib/features/soat/`; DI regenerated; legacy `vehicles/presentation/soat/` deleted; new `AppRoutes.soatManualCapture` named route + `SoatManualCaptureParams` |
| 2 | REFACTOR-07, 08, 10, 11, 13 | 6 | Raw buttons → `AppButton`/`AppTextButton`; `FormBuilderTextField` → `AppTextField`; 3 shell-tab `goNamed` annotated, 2 replaced with `pop`; **3 new color tokens** (`statusGreen`, `statusWarning`, `statusError`); `showDialog` in `info_chip_tooltip` annotated; 33 color-literal files tokenized |
| 3a | REFACTOR-04, 03a, 03b | 11 | Widget extractions: auth (21 new widgets), garage (28), vehicle form (18) |
| 3b | REFACTOR-05a, 05b | ~25 | Widget extractions: events detail (cta_bar 8 variants — no widget tests, smoke gated), form sections, list, tracking, drafts; `live_map_app_bar.dart` split into `live_map_simple_app_bar.dart` + overlay |
| 3c | REFACTOR-06a, 06b | 19 | Widget extractions: maintenance (filter sheet sub-components extracted, StatefulWidget+State pair kept), home, profile, users, event_registration |
| 4 | REFACTOR-09, 14, 15, 12 | 7 | Navigator → `context.pop` migration; **new `AppFormNavHeader` molecule** in `lib/design_system/molecules/layout/`; 3 form headers migrated and legacy headers deleted; **l10n reduction 1311→742 keys (−43.4%)** with 6 duplicate keys unified to generic forms; exception comment added to `isLoadingMore` |
| Fix | (post-batch) | 1 | Reverted `context.pop()` → `Navigator.pop(context)` in `event_filters_bottom_sheet.dart` (with `// Custom:` annotation) — bottom sheets opened via `showModalBottomSheet` use the Material Navigator, not go_router |

## Acceptance grep results (PLAN.md DoD)

| Check | Expected | Actual |
|---|---|---|
| `find lib/features -name "*.dart"` multi-widget count | 0 | 0 (after batch 3 + 3b live_map fix) |
| `grep "Widget _build\|Widget _[a-z]"` in `lib/features/` | 0 | 0 |
| `grep "ElevatedButton\|OutlinedButton\|TextButton"` (excl. `// Custom:`) | 0 | 0 |
| `grep "FormBuilderTextField"` | 0 | 0 |
| `grep "Navigator\.of(context)\."` (excl. `// Custom:`) | 0 | 0 |
| `grep "Navigator\.pop(context"` (excl. `// Custom:`) | 0 | 0 (1 retained in `event_filters_bottom_sheet.dart` with annotation) |
| `grep "context\.goNamed"` (excl. `// Intentional:`) | 0 | 0 (3 shell-tab calls annotated) |
| `grep "Color(0x"` (excl. `// Intentional:`) | 0 | 0 |
| `grep "Colors\."` (excl. `// Intentional:`) | ≤5 | within budget |
| `find lib/features/vehicles/presentation/soat -name "*.dart"` | 0 files | 0 |
| `grep -r "vehicles/presentation/soat"` | 0 results | 0 |
| `grep "showDialog("` (excl. `// Custom:`/`AppDialog`/`ConfirmationDialog`) | 0 | 0 (1 annotated in `info_chip_tooltip.dart`) |
| `dart analyze lib/` | 0 errors AND 0 warnings | **0 / 0** |
| `flutter test` | no new failures | 119 passed, 0 failures |

## Architectural decisions applied

- **Decision A — `AppFormNavHeader` API**: sealed `AppFormNavAction` (text/icon/pillText), height param, `bottom` slot. Created in `lib/design_system/molecules/layout/`. 3 callsites migrated. Legacy headers deleted.
- **Decision B — Option B for unnamed routes**: `EventRouteConfigScreen` and `EventRouteMapScreen` push sites annotated `// Custom:`. No new named routes added.
- **Decision C — REFACTOR-12 exception template** applied to `bool isLoadingMore` in `NotificationsState`.
- **Decision D — color tokens** added as new constants (NOT remaps): `statusGreen 0xFF22C55E`, `statusWarning 0xFFEAB308`, `statusError 0xFFEF4444`. Existing `success`/`warning`/`error` preserved.
- **Decision E — `AppButton.isLoading` guard** verified; REFACTOR-01 uses single `isLoading:` flag.
- **Decision F — DI regen** after deleting `SoatUploadCubit` executed and verified.
- **Decision G — l10n cleanup**: 569 keys removed (−43.4%). Dynamic-reference families preserved. 6 keys unified to existing generic forms. Audit report at `docs/architecture/iter-6-arb-cleanup-report.md`.

## Deviations from plan

1. **REFACTOR-15 reduction far exceeds target**: 43.4% vs. ≥10% target. Risk: dynamic refs in non-Dart sources (Android strings.xml, backend templates, push payload generators) may have broken silently. QA must spot-check push notifications and any feature that uses string interpolation for keys.
2. **`AppTextField` extended** with `inputFormatters` field during REFACTOR-08 to support digit-only filtering in price/km fields. Minor shared-widget extension.
3. **Maintenance form sections lost some inline custom styling** (monospace, borderless decoration) — design system standardization. Verify in smoke test.
4. **`MaintenanceFormView` trailing pill `onTap: () {}`**: pill is a no-op; save is triggered from the bottom CTA bar. Matches original behavior.
5. **`AppFormNavHeader.preferredSize` bottom-slot calc** uses a conservative 32px estimate. Per Design handoff, measure against actual progress-bar height.
6. **Batch 4 misclassified a regression as pre-existing**: `event_filters_bottom_sheet_test.dart::TC-2-20` was actually a regression caused by the Navigator → context.pop migration. Fixed by reverting that single site to `Navigator.pop(context)` with `// Custom:` annotation.

## Risks for QA

- **Visual parity** gated on smoke tests: capture 6 before/after screenshot pairs (vehicle form add/edit, maintenance form add/edit, event form create/edit).
- **8 CTA bar state variants** in event detail have no widget tests — smoke test 4 states (registered / pending / closed / full).
- **AI cover generation** (iter-4) and **Mapbox route preview** (iter-3) must remain functional — mandatory regression smoke tests.
- **Push notifications**: 11 `notification_*` keys preserved. Spot-check that real push payloads still render correctly.

## Bridge for QA

→ Phase 6: QA. Test catalog should cover:
1. All 17 DoD grep checks (mechanical, automatable in CI)
2. 7 smoke tests from PLAN.md
3. AI cover regression (iter-4)
4. Mapbox route preview regression (iter-3)
5. Push notification rendering spot-check

## Files of note (newly created)

- `lib/design_system/molecules/layout/app_form_nav_header.dart` (+ molecules barrel update)
- `lib/core/theme/app_colors.dart` — `statusGreen`, `statusWarning`, `statusError` added
- `lib/features/soat/presentation/pages/soat_manual_capture_params.dart`
- `lib/features/soat/presentation/widgets/soat_vehicle_options_sheet.dart`
- `lib/features/events/presentation/tracking/widgets/live_map_simple_app_bar.dart`
- ~150 new extracted widget files across auth / vehicles / events / maintenance / home / profile / users / event_registration features
- `docs/architecture/iter-6-arb-cleanup-report.md` — l10n audit report

## Files deleted

- `lib/features/vehicles/presentation/soat/` (entire legacy folder)
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_nav_header.dart`
- `lib/features/maintenance/presentation/form/widgets/maintenance_form_nav_header.dart`
- 569 keys from `lib/l10n/app_es.arb`

## Change log

- 2026-05-27 (iter-6 frontend, all batches): 17 REFACTOR stories complete in 80 commits. Pure internal refactor, zero new features.
