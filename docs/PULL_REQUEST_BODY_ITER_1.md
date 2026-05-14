## Iter-1: UI/UX Redesign — Design System Baseline

**Goal:** Bring 15 existing Flutter screens into full visual alignment with `rideglory.pen` — no new features, no backend changes — establishing a consistent design system baseline before SOAT, notifications, tracking, and deep links are layered on.

---

## Stories delivered

| ID | Story | Status |
|----|-------|--------|
| US-1-1 | Gap analysis: all 15 screens mapped to rideglory.pen frames with specific mismatches | ✅ Done |
| US-1-2 | Splash screen aligned with rideglory.pen design (color, logo, loading states) | ✅ Done |
| US-1-3 | Auth screens (login, signup, password recovery) use AppButton, AppTextField, AppPasswordTextField | ✅ Done |
| US-1-4 | Home Dashboard matches frame dyWWs — greeting, garage card, upcoming rides, bottom nav pill bar VMmN0 | ✅ Done |
| US-1-5 | Events list + detail match frames Neipf/kAubW — cards, badges, filter bottom sheet, CTA bar | ✅ Done |
| US-1-6 | Create/Edit Event form matches frame zbCa0 — AI cover widget preserved, Mapbox preview unchanged | ✅ Done |
| US-1-7 | Garage (vehicle list + detail) matches frames KCf6W/P1GSzZ — DocumentSlotPill molecule extracted | ✅ Done |
| US-1-8 | Add/Edit vehicle form matches frame EqnMm | ✅ Done |
| US-1-9 | Maintenance (dashboard, history, forms) matches frames Ako7u/SykjL/J5h6P/eK2WW/ELB5u | ✅ Done |
| US-1-10 | Registration list + detail use design system components throughout | ✅ Done |
| US-1-11 | Zero regressions gate — dart analyze + flutter test + 5 smoke tests | ✅ Done |

**Deferred to iter-2:** ManageAttendeesPage redesign (Story 2.9) — awaiting frame dUc9h design gate.

---

## What changed

### Design system primitives (new)
- `lib/design_system/atoms/badges/app_event_badge.dart` — AppEventBadge (6 variants: scheduled, inProgress, finished, cancelled, free, paid) from frame zKkmE
- `lib/design_system/molecules/feedback/document_slot_pill.dart` — DocumentSlotPill (4 states: empty, valid, expiringSoon, expired) from frame aGqnv — ready for iter-2 SOAT wiring

### Color tokenization
- **47 hardcoded color literals** replaced with `AppColors` constants or `colorScheme` semantic tokens across 42 feature files
- Zero `Color(0x...)` or non-standard `Colors.<named>` references remaining in `lib/features/`

### Widget adoption
- ElevatedButton → AppButton; TextFormField → AppTextField throughout

### Localization
- ~140 new ARB keys added to `lib/l10n/app_es.arb`; `flutter gen-l10n` regenerated

### Test updates
- 3 events widget tests updated in the same PRs as their widget swaps (no test-rot)
- 19 `const` keyword fixes applied via `dart fix`

---

## Test results

| Gate | Result |
|------|--------|
| `dart analyze` — errors | 0 ✅ |
| `dart analyze` — warnings | 0 ✅ |
| `flutter test` — pass | 28 ✅ |
| `flutter test` — pre-existing failures (stale .g.dart) | 4 (deferred to iter-2 full rebuild) |
| New test failures introduced by iter-1 | 0 ✅ |

**QA sign-off:** ✅ GREEN

---

## Handoffs
- [PO handoff](docs/handoffs/po.md)
- [Architect handoff](docs/handoffs/architect.md)
- [Design handoff + mockups](docs/handoffs/design.md) — `docs/design/html-mockups/iter-1/`
- [Frontend handoff](docs/handoffs/frontend.md)
- [QA handoff](docs/handoffs/qa.md)
- [DevOps handoff](docs/handoffs/devops.md)

---

## Test plan

- [ ] `dart analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — 28 pass, no new failures
- [ ] Manual smoke: AI cover generation (generate → select → save event → confirm functional)
- [ ] Manual smoke: Event detail CTA state variants (registered / not registered / organizer)
- [ ] Manual smoke: Maintenance donut chart renders with correct urgency colors
- [ ] Manual smoke: Home bottom nav pill bar visible and correct across all shell screens
- [ ] Manual smoke: Mapbox route preview renders in event form
- [ ] Grep: `grep -r "Color(0x" lib/features/` returns empty
- [ ] Grep: `grep -r "Colors\." lib/features/` returns empty (or only Colors.white/black/transparent)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
