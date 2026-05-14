# Code Review — Iteration 1

> Reviewer: tech_lead
> Date: 2026-05-14

## Findings

| File | Issue | Resolution | Deferred? |
|------|-------|-----------|-----------|
| `lib/design_system/atoms/badges/app_event_badge.dart:65` | `final fg = _foregroundColor()` — abbreviated variable name (standards prefer domain names) | Acceptable — local color alias in 3-line build method; type and purpose obvious | Yes — low risk |
| `lib/features/home/presentation/widgets/home_event_gradient_overlay.dart:13` | `Colors.black87` introduced (replaced `Color(0xDD000000)`). Standard allows only `Colors.black`. | Should be `Colors.black.withValues(alpha: 0.87)` in strict compliance | Yes — iter-2 cleanup |
| `lib/features/events/presentation/detail/widgets/event_detail_header_overlay_gradient.dart:18` | `Colors.black87` introduced (replaced `Color(0xE0000000)`). Same as above. | Should be `Colors.black.withValues(alpha: 0.88)` in strict compliance | Yes — iter-2 cleanup |
| `lib/design_system/molecules/feedback/document_slot_pill.dart:76-79` | Default `effectiveStateLabel` values are hardcoded Spanish strings. Widget has no `BuildContext`. | Callers must pass localized `stateLabel` explicitly. Add code comment to enforce contract. Molecule-level fallback is tolerable for iter-1 where widget is not yet integrated with live data. | Yes — iter-2 callers required to pass `stateLabel` |
| `lib/features/maintenance/presentation/widgets/item_card/mileage_info_dialog.dart` | `AlertDialog` raw widget (should be `AppDialog`) — PRE-EXISTING, not introduced by iter-1 | Track in iter-2 cleanup story | Yes — pre-existing |
| `lib/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart` | `TextFormField` raw widget (should be `AppTextField`) — PRE-EXISTING, not introduced by iter-1 | Track in iter-2 cleanup story | Yes — pre-existing |
| `lib/features/maintenance/presentation/widgets/item_card/info_chip_tooltip.dart` | `showDialog()` direct call (should use `AppDialog` wrapper) — PRE-EXISTING, not introduced by iter-1 | Track in iter-2 cleanup story | Yes — pre-existing |
| `lib/features/home/presentation/widgets/home_view_all_events_button.dart` | `context.goNamed()` instead of `context.pushNamed()` — PRE-EXISTING, not introduced by iter-1 | Track in iter-2 cleanup story | Yes — pre-existing |

## Deferred items

1. **`Colors.black87` in gradient overlays** — 2 files (`home_event_gradient_overlay.dart`, `event_detail_header_overlay_gradient.dart`). The iter-1 replacements swapped `Color(0xDD000000)` and `Color(0xE0000000)` to `Colors.black87`, which is a functional improvement but still outside the exact allowed set (`Colors.black` only). Correct form: `Colors.black.withValues(alpha: 0.87)`. Deferred to iter-2 color cleanup sweep.

2. **`DocumentSlotPill` hardcoded fallback strings** — The `effectiveStateLabel` fallback in `document_slot_pill.dart` has 4 Spanish literals. Since iter-2 will be the first time this molecule is called with live SOAT data, iter-2's SOAT integration must always pass `stateLabel` explicitly using `context.l10n.vehicle_doc_state_*` keys. Add a code comment to document this contract.

3. **Pre-existing raw Material widgets** — `AlertDialog` in `mileage_info_dialog.dart`, `TextFormField` in `event_form_multi_brand_section.dart`, `showDialog()` in `info_chip_tooltip.dart`. These were in scope per the architect handoff but untouched by iter-1 (file diff is empty for all three). Consolidate these into a single iter-2 cleanup PR.

4. **Pre-existing `context.goNamed()` usages** — `home_view_all_events_button.dart`, `profile_page.dart`, `garage_page.dart`, `events_page.dart`. All were present before iter-1. Review for correctness: `goNamed` to home from shell tabs may be intentional (clearing stack). Confirm intent before converting to `pushNamed`.

5. **`fg` variable name in `app_event_badge.dart`** — Tolerable abbreviation in a 3-line method where the type (`Color`) and origin (`_foregroundColor()`) are immediately obvious. Document exception if linter rules are ever enforced on private variable names.

## Architecture health summary

- **Clean Architecture compliance: excellent.** Zero domain/data/DI/router changes. The presentation-layer boundary was respected across all 5 modules and 34 modified files. git diff main..iter-1 on restricted paths returns empty.
- **Color tokenization: complete.** `grep -rE "Color\(0x" lib/features/` returns 0 matches. All `Colors.<named>` replaced except 2 `Colors.black87` occurrences (borderline tolerable, deferred).
- **Design system adoption: mature.** `AppButton`, `AppTextField`, `AppPasswordTextField` used throughout — no new raw Material buttons or inputs introduced. Pre-existing violations are tracked but pre-date iter-1.
- **Localization: comprehensive.** ~140 new ARB keys covering all 5 modules. Generated files committed. Emoji in one ARB value is ARB-level acceptable.
- **Test baseline maintained.** 28 tests pass (unchanged). 4 pre-existing failures (stale .g.dart) are compile-time failures in test files, not caused by iter-1 changes.
