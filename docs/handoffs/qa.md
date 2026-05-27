# QA handoff — Iteration 6 (refactor-01)

> Status: **complete**
> Phase: qa (6 of 10)
> Updated: 2026-05-27
> Branch: `iter-6`
> Sign-off: **GREEN ✅**

## Summary

Pure refactor iteration — QA model was **regression-first**. No new user-facing acceptance criteria; the contract was "everything renders and behaves exactly as before."

## Automated verification

| Check | Baseline (main) | iter-6 |
|---|---|---|
| `dart analyze lib/` | 0 errors / 0 warnings | **0 / 0** |
| `flutter test --reporter compact` | 119 pass / 0 fail | **119 pass / 0 fail** |

All 17 DoD mechanical grep checks (from PLAN.md Refactor-01 DoD) verified passing — see `docs/handoffs/contracts/iter-6/frontend.json` and the PR description for the full list.

## Test catalog (TC-6-N)

Since this is a pure refactor with no new behavior, the test catalog is the union of:

1. **Pre-existing automated suite** (119 tests) — must continue to pass: ✅
2. **DoD grep matrix** (17 mechanical checks) — must all pass: ✅
3. **Manual smoke tests** (11 scenarios from PR description) — must all pass: ✅

## Manual smoke tests executed

| ID | Scenario | Result |
|---|---|---|
| TC-6-S1 | SOAT upload → confirmation → status (vehicle detail badge → upload page con 2 cards → manual / foto → guardar → status refresca) | ✅ pass |
| TC-6-S2 | SOAT vehicle creation flow | ✅ pass |
| TC-6-S3 | Login → Forgot Password → back | ✅ pass |
| TC-6-S4 | Event detail CTA bar 4 variantes (registered / pending / closed / full) | ✅ pass |
| TC-6-S5 | Maintenance filters apply | ✅ pass |
| TC-6-S6 | Garage vehicle options (archive / delete / set-main) | ✅ pass |
| TC-6-S7 | Signup end-to-end | ✅ pass |
| TC-6-S8 | AI cover generation regression (iter-4) | ✅ pass |
| TC-6-S9 | Mapbox route preview regression (iter-3) | ✅ pass |
| TC-6-S10 | Push notifications render correctly (`notification_*` keys preserved) | ✅ pass |
| TC-6-S11 | Visual parity en los 3 form headers (vehicle / maintenance / event) — create + edit | ✅ pass |

## Bugs filed

**None.** All blocking issues found mid-iteration were resolved within the same iteration:

- `event_filters_bottom_sheet_test.dart::TC-2-20` — regression caught and fixed in `ea59e3c` (reverted `context.pop()` → `Navigator.pop(context)` for showModalBottomSheet route).
- `AppFormNavHeader.preferredSize` 1px overflow — caught manually, fixed in `7ff04fb`.
- SOAT 2-card flow regression — caught by human review, restored in `4db6f94` (10 l10n keys recovered, `SoatUploadCubit` and 4 widget files re-introduced).
- Maintenance primary buttons rendering white-on-orange (broke design rule) — fixed in `97f711d` (now use `colorScheme.onPrimary`).
- Leading back buttons inconsistent shapes/sizes — fixed in `d61fffb` + atom unification in follow-up commit.

## Edge cases verified

- Typed-result `Navigator.pop` calls (modal bottom sheets returning `MaintenanceAction.*`, `SoatOptionsResult`, `_filters`) — all preserved with `// Custom:` annotation. ✅
- `withValues(alpha:)` rendering after color tokenization — no visual artifacts. ✅
- ARB key resolution — `flutter gen-l10n` clean, no missing translation strings observed in screen tour. ✅
- 11 `notification_*` push payload keys preserved despite the −43% ARB reduction. ✅
- SOAT consolidation: all callers of `AppRoutes.vehicleSoat` navigate correctly. ✅
- DI regeneration after deletion of `SoatUploadCubit` legacy + re-introduction in new namespace — `dart run build_runner build` clean. ✅

## Risk notes for tech_lead / merge

- `event_detail_cta_bar` 8 state variants have **no widget tests**. Manual smoke (TC-6-S4) is the only safety net here.
- ARB reduced by 43.4% (1311 → 742, with 10 keys restored later). If any push payload uses a non-`notification_*` key dynamically, it could break silently. Mitigation: TC-6-S10 covered the visible push notification flows.
- `MaintenanceFormView` trailing pill `onTap: () {}` is a no-op (save is from the bottom CTA bar). Matches original UX but worth a second look from tech_lead.

## Bridge for next phase

→ Phase 7: DevOps. CI verification on `iter-6` branch.

## Change log

- 2026-05-27 (iter-6 qa): Refactor-only QA sign-off. 119 automated tests pass, 11 manual smokes pass, 17 DoD grep checks pass. 5 mid-iteration regressions caught and resolved before sign-off.
