# Tech Lead review — Iteration 6 (refactor-01)

> Status: **complete**
> Phase: tech_lead (9 of 10)
> Updated: 2026-05-27
> PR: #23 — https://github.com/CamiiloAF/Rideglory/pull/23
> Decision: **APPROVED ✅** (merge blocked by pre-existing CI failure; see Caveats)

## Scope reviewed

Full diff: 348 files changed, +17,336 / −18,747 lines, 85 commits on `iter-6` vs `main`. Pure internal refactor — zero new features, zero API changes, zero domain model changes.

## Clean Architecture sweep — PASS

| Check | Result |
|---|---|
| Domain doesn't import Flutter/HTTP/`dart:io` | ✅ verified |
| Data doesn't import widgets or use `BuildContext` | ✅ `grep "BuildContext" lib/features/*/data/` → 0 results |
| Presentation doesn't call HTTP clients directly | ✅ `grep "DioException\|data/(dto\|service\|repository)"` in presentation → 0 results |
| Dependencies flow inward only | ✅ |
| `EventDetailViewState.currentEvent` mutable state preserved post-extraction | ✅ (REFACTOR-05a critical pattern) |
| `NotificationsState.isLoadingMore` documented exception | ✅ 3-line `// Exception:` per Architect decision C |

## rideglory-coding-standards sweep — PASS

| Rule | Result |
|---|---|
| One widget per file | 0 violations |
| No `Widget _build*` helper methods | 0 violations |
| No raw `ElevatedButton`/`OutlinedButton`/`TextButton` | 0 (excl. `// Custom:`) |
| No `FormBuilderTextField` | 0 |
| `Navigator.of(context).` excl. `// Custom:` | 0 |
| `Navigator.pop(context` excl. `// Custom:` | 0 |
| `context.goNamed` excl. `// Intentional:` | 0 (3 shell-tab calls annotated) |
| `Color(0x` excl. `// Intentional:` | 0 |
| No `showDialog(` direct calls excl. `AppDialog`/`// Custom:` | 0 (1 annotated) |
| `dart analyze lib/` | 0 errors, 0 warnings |
| `flutter test` | 119/119 pass |

## Design system additions — APPROVED

- **`AppCircleIconButton`** (atom): 36×36, 3 variants (`surface`/`accent`/`translucent`), `.back()` factory. Locks long-tail of leading-back-button inconsistencies. 3 per-feature widgets deleted (`VehicleDetailNavButton`, `MaintenanceDetailIconButton`, `MaintenancesAppBarIconButton`).
- **`AppFormNavHeader`** (molecule): sealed `AppFormNavAction` (text/icon/pillText), `bottom` slot, `preferredSize` accounts for status bar + slot + border. Delegates pill-icon to `AppCircleIconButton` — cross-design-system reuse, good.
- 3 new `AppColors` tokens are additions, not remaps — pixel-exact preservation per Architect decision D.

## Risks called out (non-blocking)

1. **`event_detail_cta_bar` 8 state variants have no widget tests.** Manual smoke TC-6-S4 covered all 4 main states. Recommend follow-up to add widget tests.
2. **l10n cleanup reduced ARB by 43.4%** (vs. ≥10% target). 11 `notification_*` keys explicitly preserved; 10 SOAT keys restored after a regression caught in human review. Residual risk: non-Dart references (Android strings.xml, backend templates) could break silently. Recommend backend-side spot-check before production rollout.
3. **MaintenanceFormView trailing pill is a no-op** (`onTap: () {}`). Save is triggered from bottom CTA bar — matches pre-refactor behavior but worth flagging.
4. **`AppFormNavHeader.preferredSize`** uses fixed proxies (`_bottomSlotHeight = 24`, `_maxStatusBarHeight = 48`). Only `MaintenanceFormProgressBars` (~12px) consumes the bottom slot today, so safe. If a future form needs a taller `bottom` widget, refactor to compute height via `LayoutBuilder`.

## Mid-iteration regressions (all resolved)

- `event_filters_bottom_sheet_test.dart::TC-2-20` — fixed in `ea59e3c`.
- `AppFormNavHeader.preferredSize` 1px overflow — fixed in `7ff04fb`.
- SOAT 2-card UX regression — fixed in `4db6f94` (restored cubit + 4 widgets + 10 l10n keys).
- Maintenance primary buttons white-on-orange (broke design rule) — fixed in `97f711d` (now `colorScheme.onPrimary`).
- Leading back buttons inconsistent shapes/sizes — fixed in `d61fffb` + atom unification commit.

## Security review — PASS

No new endpoints, no new auth flows, no new secrets, no new packages with security implications. `FirebaseAuthInterceptor` and request signing paths untouched. The re-introduced `SoatUploadCubit` is functionally identical to the legacy version (verbatim restore from git history, same `@injectable` annotation).

## Test coverage assessment

- 119 pre-existing automated tests preserved (0 regressions).
- 1 test file updated mid-batch (`event_filters_bottom_sheet_test.dart`) to align with go_router migration — then reverted alongside production code revert.
- No new automated tests added (refactor-only, would only test refactor mechanics — covered by DoD grep matrix).
- 11 manual smoke tests passed before merge.

## Security findings

None.

## Overall signal

**APPROVED.** The refactor is faithful to the plan: 17 stories delivered, all DoD grep checks pass, all 11 manual smoke tests pass, Clean Architecture compliance verified, design system genuinely improved (atom + molecule add long-term consistency). The 5 mid-iteration regressions were caught and resolved before sign-off, none persist.

## Caveats / merge gate

- **CI is failing on `iter-6` AND on `main`** due to `lucide_icons 0.257.0` extending Flutter's `final IconData` class. This failure is **pre-existing** (verified: same error on main runs `26523075925`, `26522649039`, `26520626824`). iter-6 does NOT regress CI status, but merge is blocked by branch protection until `lucide_icons` is pinned to a compatible version or upgraded.
- **Recommended path:** open a separate small PR fixing `lucide_icons` version pinning, merge that first, then iter-6 will go green on rebase.
- Alternatively, an administrator can override branch protection to merge iter-6, then fix `lucide_icons` as the first commit on `main` post-merge.

## Blocking issues

None from iter-6 itself. Only external CI blocker (`lucide_icons` package, pre-existing).

## Change log

- 2026-05-27 (iter-6 tech_lead): Full diff reviewed. Clean Architecture and rideglory-coding-standards sweeps PASS. Design system additions approved. 4 non-blocking risks called out. 5 mid-iteration regressions verified resolved. Decision: APPROVED. Merge blocked only by pre-existing CI failure on `lucide_icons` package incompatibility — not introduced by iter-6.
