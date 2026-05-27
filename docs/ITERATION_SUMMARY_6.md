# Iteration 6 Summary — Refactor & Cleanup Extremo

> Codename: `refactor-01`
> Closed: 2026-05-27
> PR: #23 — https://github.com/CamiiloAF/Rideglory/pull/23
> Tech Lead: **APPROVED**

## Goal

Pure internal refactor of the Flutter app — eliminate 17 categories of technical debt accumulated across recent product iterations. Zero new features. Zero API changes. Zero database changes.

## Stories delivered (17/17)

| ID | Title | Status |
|---|---|---|
| REFACTOR-01 | Fix SOAT loading-button bug | ✅ |
| REFACTOR-02 | Consolidate SOAT feature | ✅ |
| REFACTOR-03a | Vehicles garage widget extraction | ✅ |
| REFACTOR-03b | Vehicles form widget extraction | ✅ |
| REFACTOR-04 | Authentication widget extraction | ✅ |
| REFACTOR-05a | Events detail widget extraction | ✅ |
| REFACTOR-05b | Events form/list/tracking/drafts widget extraction | ✅ |
| REFACTOR-06a | Maintenance widget extraction | ✅ |
| REFACTOR-06b | Home + Profile + Registration widget extraction | ✅ |
| REFACTOR-07 | Raw buttons → `AppButton` / `AppTextButton` | ✅ |
| REFACTOR-08 | `FormBuilderTextField` → `AppTextField` | ✅ |
| REFACTOR-09 | `Navigator.*` → `context.pop` / `context.push` | ✅ |
| REFACTOR-10 | Fix `context.goNamed` violations | ✅ |
| REFACTOR-11 | Tokenize hardcoded colors | ✅ |
| REFACTOR-12 | Document `bool isLoadingMore` exception | ✅ |
| REFACTOR-13 | Fix direct `showDialog` → `AppDialog` | ✅ |
| REFACTOR-14 | Centralize form headers (`AppFormNavHeader`) | ✅ |
| REFACTOR-15 | Cleanup `app_es.arb` | ✅ |

## Design system additions

- **`AppCircleIconButton`** (atom in `lib/design_system/atoms/buttons/`): 36×36 circular icon button with 3 variants (`surface` / `accent` / `translucent`) and a `.back()` factory. Single source of truth for leading back arrows and small circular trigger buttons.
- **`AppFormNavHeader`** (molecule in `lib/design_system/molecules/layout/`): centralized form-screen header with sealed `AppFormNavAction` (text / icon / pillText) and optional `bottom` slot.
- **3 new `AppColors` tokens**: `statusGreen`, `statusWarning`, `statusError` (Tailwind-derived, additions only — preserve pre-refactor pixel values).

## Quality metrics

| Metric | Value |
|---|---|
| Commits on `iter-6` vs `main` | 85 |
| Files changed | 348 |
| Lines added | 17,336 |
| Lines deleted | 18,747 |
| Net change | −1,411 (more code deleted than added) |
| `dart analyze lib/` | **0 errors / 0 warnings** |
| `flutter test` | **119 / 119 pass** |
| Manual smoke tests | **11 / 11 pass** |
| DoD grep checks | **17 / 17 pass** |
| ARB key reduction | 1311 → 742 (−43.4%) |
| Per-feature back-button widgets deleted | 3 |
| Legacy form-header widgets deleted | 2 |
| Bugs filed | 0 |

## Mid-iteration regressions (caught and resolved)

1. `event_filters_bottom_sheet_test.dart::TC-2-20` — fixed by reverting `context.pop()` → `Navigator.pop(context)` (modal bottom sheet uses Material Navigator, not go_router).
2. `AppFormNavHeader.preferredSize` 1px overflow — fixed by including status bar + bottom slot + border in calculation.
3. SOAT 2-card upload-vs-manual UX regression — caught in human review; cubit + 4 widget files + 10 l10n keys restored.
4. Maintenance primary buttons rendering white-on-orange (broke design rule) — fixed to use `colorScheme.onPrimary`.
5. Leading back buttons had inconsistent shapes and sizes — fixed and unified via new `AppCircleIconButton` atom.

## Risks for next iteration

- `event_detail_cta_bar` 8 state variants still have no widget tests. Manual smoke is the only safety net.
- `lucide_icons 0.257.0` extends Flutter's now-`final` `IconData` class. Fixed by pinning CI Flutter to `3.38.5`. **Follow-up:** when upgrading Flutter, migrate `lucide_icons` references to a maintained alternative or replace with Material icons.
- l10n cleanup (−43.4%) preserved 11 `notification_*` keys but may have removed keys referenced from non-Dart sources. Spot-check push payloads in production.

## Reference

- PR: https://github.com/CamiiloAF/Rideglory/pull/23
- PRD: `docs/prd-refactor-cleanup.md`
- Plan: `docs/PLAN.md` § Refactor-01
- Frontend handoff: `docs/handoffs/frontend.md`
- QA handoff: `docs/handoffs/qa.md`
- Tech Lead review: `docs/handoffs/tech_lead.md`
- l10n audit: `docs/architecture/iter-6-arb-cleanup-report.md`
