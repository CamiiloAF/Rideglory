# PO handoff — Iteration 1

**Date:** 2026-05-13
**Status:** in progress

---

## Iteration goal

Bring 15 existing screens into full visual alignment with `rideglory.pen` — no new features, no backend changes — establishing a consistent design system baseline before new capabilities are layered on in iter-2.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
|----|-------|---------------------|---------------|
| US-1-1 | As a designer reviewing existing screens, I can identify all visual gaps between the current Flutter implementation and the `rideglory.pen` frames, documented in a gap analysis before any Flutter code is touched. | Gap analysis document lists every screen (all 15) with specific mismatches: component name, spacing value, color token, typography rule. Document reviewed and approved before any Flutter code changes begin. | design |
| US-1-2 | As a rider opening the app, I see the splash screen with the correct logo, loading state indicator, and overall layout matching the `rideglory.pen` design. | Splash screen layout, logo sizing, background color, and loading indicator match the Pencil frame exactly. All loading states (loading, error, success) handled visually. No hardcoded `Color()` literals. | frontend |
| US-1-3 | As a rider on the auth screens (login, signup, password recovery), the pages use `AppButton`, `AppTextField`, `AppPasswordTextField`, correct typography, and the exact color tokens from the design system. | No `ElevatedButton`, no `TextFormField` direct usage, no hardcoded color literals on any auth screen. `AppButton` used for all primary and secondary actions. Space Grotesk applied. Password recovery confirmation screen matches design. **Auth frames gate must be satisfied before this story begins.** | frontend |
| US-1-4 | As a rider on the Home Dashboard, the layout matches the `rideglory.pen` frame `dyWWs` — including the greeting header, garage card (main vehicle + empty state), upcoming rides section (horizontal scroll + empty state), and bottom navigation pill bar (`VMmN0`). | Frame `dyWWs` matched: correct spacing, correct card border radius (12 px cards, 24 px bottom sheets), correct color tokens. Bottom nav pill bar matches frame `VMmN0`. SOAT badge placeholder **not included** (iter-2). No layout regressions vs. current behavior. | frontend |
| US-1-5 | As a rider browsing Events, the events list page and event detail page match the `rideglory.pen` frames `Neipf` and `kAubW` — including event cards, badges (frame `zKkmE`), filter chips, the filter bottom sheet, and the CTA bar on event detail. **Pre-condition:** `lib/design_system/atoms/app_event_badge.dart` must be extracted/created from frame `zKkmE` before this story's implementation begins. | Event list: search bar, filter chips, event cards (image overlay, badge, organizer avatar, chips) match frame `Neipf`. Event detail: hero image, metric chips, map preview, allowed brands chips, CTA bar match frame `kAubW`. Filter bottom sheet layout correct. `app_event_badge.dart` used in all event card contexts. | frontend |
| US-1-6 | As a rider creating an event, the Create/Edit Event form matches the `rideglory.pen` frame `zbCa0` — correct input fields, layout sections, difficulty selector, and button styles. | Form layout matches frame `zbCa0`. AI cover generation widget (iter-4 feature) is preserved and functional. Mapbox route preview widget unchanged. All inputs use `AppTextField`. `AppButton` used for primary actions. | frontend |
| US-1-7 | As a rider viewing the Garage, the vehicle list page and vehicle detail page match `rideglory.pen` frames `KCf6W` and `P1GSzZ` — including the main vehicle card, "other vehicles" list, spec chips, and document slots. The document slot pill (`aGqnv`) is extracted as a design system molecule during this story for reuse in iter-2 SOAT badge. | Vehicle list matches frame `KCf6W`: main vehicle card with full-width image, stats chips, quick-access buttons; compact other-vehicles list. Vehicle detail matches frame `P1GSzZ`: specs, document badges, action buttons. All states (loading, empty, data, error) visually correct. | frontend |
| US-1-8 | As a rider adding or editing a vehicle, the Add/Edit vehicle form matches `rideglory.pen` frame `EqnMm` — correct field layout, image upload UI, and step structure. | Form fields, image upload banner, and section layout match frame `EqnMm`. Document slot section (SOAT, tech review) UI is present but non-functional pending iter-2. `AppTextField` and `AppButton` used throughout. | frontend |
| US-1-9 | As a rider viewing Maintenance, the dashboard, history list, and new maintenance forms match `rideglory.pen` frames `Ako7u` (dashboard), `SykjL` (history), `J5h6P` (step 1), `eK2WW` (step 2 — completed), and `ELB5u` (step 2 — scheduled). | All 5 maintenance frames matched. Dashboard: donut chart health indicator, urgency color coding (red/yellow/green) correct. History: year grouping, cost summary, chronological order. Filters bottom sheet (frame `v6RqaX`) layout correct. Step 1 grid 2×4 card layout correct. Step 2 tab (Completado / Programado) layout correct. | frontend |
| US-1-10 | As a rider viewing their registrations, the My Registrations list and Registration Detail pages match `rideglory.pen` frames `oUv12` and the registration list layout. | Registration list and detail pages use design system components throughout; no hardcoded colors; empty and loading states correct. | frontend |
| US-1-11 | As the dev team, we confirm zero visual regressions and zero `dart analyze` violations after the redesign — all existing tests pass and 5 manual smoke tests are green before final merge. | `dart analyze` passes with zero new violations. All 10 existing `flutter test` cases pass. 5 manual smoke tests green: (a) AI cover generation, (b) Event detail CTA state variants, (c) Maintenance donut chart rendering, (d) Home bottom nav pill bar, (e) Mapbox route preview in event form. All 3 events widget tests updated in the same PR that swaps their widgets. | qa |

---

## Task definitions

| Task ID | Description | Agent | Status |
|---------|-------------|-------|--------|
| T-1-1 | Inspect all relevant `rideglory.pen` frames via Pencil MCP; produce gap analysis document listing every screen (15 total) with specific mismatches (component, spacing, color, typography) | design | todo |
| T-1-2 | Confirm or create Login / Signup / PasswordRecovery frames in `rideglory.pen` (auth frames gate for US-1-3) | design | todo |
| T-1-3 | Implement US-1-2 (Splash screen) + US-1-3 (Auth screens) — module PR 1/5: `splash+auth` (≤ 40 files) | frontend | todo |
| T-1-4 | Implement US-1-4 (Home Dashboard) — module PR 2/5: `home` (≤ 40 files) | frontend | todo |
| T-1-5 | Extract `app_event_badge.dart` atom from frame `zKkmE`; implement US-1-5 (Events list + detail) + US-1-6 (Create/Edit Event form) — module PR 3/5: `events` (≤ 40 files) | frontend | todo |
| T-1-6 | Extract document slot pill (`aGqnv`) as design system molecule; implement US-1-7 (Garage list + detail) + US-1-8 (Add/Edit vehicle form) — module PR 4/5: `garage` (≤ 40 files) | frontend | todo |
| T-1-7 | Implement US-1-9 (Maintenance dashboard, history, forms) + US-1-10 (Registrations) — module PR 5/5: `maintenance+registration` (≤ 40 files) | frontend | todo |
| T-1-8 | Run `dart analyze` baseline on `main` branch; document any pre-existing violations; verify violation count does not grow during iter-1 | qa | todo |
| T-1-9 | Execute quality gate validation: `dart analyze` + `flutter test` green; widget tests updated; 5 manual smoke tests logged; no hardcoded color literals remain in `lib/features/` | qa | todo |
| T-1-10 | Review all module PRs for Clean Architecture compliance: no layer violations, no hardcoded colors, correct widget usage (`AppButton`, `AppTextField`, `AppDialog`), updated `app_es.arb`, no test-rot merges | tech_lead | todo |

---

## Assumptions and open questions

- **No auth frames in rideglory.pen (assumption):** It is unknown whether Login, Signup, and PasswordRecovery screens have dedicated Pencil frames. The Design agent must verify this during pre-flight and create them if missing, before Story US-1-3 (Task T-1-2) begins. Stories US-1-2 and US-1-4 through US-1-10 may proceed in parallel with T-1-2.
- **Donut chart scope (assumption):** The donut chart in frame `Ako7u` (Maintenance dashboard) may require either a color token swap only or a geometry/animation change. If geometry change is needed, it is descoped to color-only for iter-1. The Design agent must flag this during pre-flight (T-1-1) before US-1-9 begins.
- **No backend changes (assumption):** Iter-1 is strictly presentation-layer. No new domain models, DTOs, services, use cases, or routes are introduced. The Architect confirmed only 3 imports of `core/data/` in `lib/features/*/presentation/`, all referencing `colombia_motos_brands_data.dart` (a static catalog).
- **File blast radius confirmed:** Approximately 95–135 files will be touched. The heavy lift is color tokenization (~33 raw `Color(0x...)` literals + ~80 files with `Colors.<named>` references), not widget swapping (only ~3 files use `ElevatedButton`/`TextFormField` directly).
- **AI cover generation (assumption):** The iter-4 AI cover generation widget in the event form must remain functional. It is treated as a blocking smoke test criterion, not advisory.
- **ManageAttendeesPage deferred (confirmed):** Story 1.11 (ManageAttendeesPage) was explicitly deferred from iter-1 to iter-2 as Story 2.9 per the approved PLAN.md.

---

## Out of scope (this iteration)

- **SOAT badge on Home Dashboard / vehicle detail** — added in iter-3 per PLAN.md (not iter-2 either). Vehicle detail document slot pill is extracted as a molecule (US-1-7) but no SOAT logic is wired.
- **ManageAttendeesPage redesign** — deferred to iter-2 as Story 2.9.
- **New backend endpoints** — zero. No Prisma migrations, no new API routes.
- **New domain models or use cases** — zero.
- **New routes in go_router** — zero.
- **New dev dependencies (mocktail, bloc_test)** — deferred; test infrastructure was planned for the prior plan's iter-1, now descoped for this redesign-first iter-1.
- **Code generation** (`build_runner`) — not required since no domain/data changes are made.
- **FCM, SOAT, tracking, followers, deep links, Apple Sign-In** — iter-2 through iter-5.

---

## Next agent needs to know

### architect
- Iter-1 is **presentation-layer only**. No domain model, data layer, DI, or routing changes are permitted. Confirm this constraint and document it explicitly in your handoff so the frontend agent does not introduce any layer violations.
- The `app_event_badge.dart` atom (from frame `zKkmE`) and the document slot pill molecule (from frame `aGqnv`) are new design system files — these live in `lib/design_system/atoms/` and `lib/design_system/molecules/` respectively. Confirm naming and file placement conventions.
- Verify the 5–6 module-scoped PR strategy is compatible with the current feature branch setup. Document the feature branch name and merge order in your handoff.
- No code generation files need regeneration (no `build_runner` run required).

### design (frontend, UX)
- **Pre-flight priority:** Gap analysis (T-1-1) is the highest-priority task. No Flutter code may begin until the gap analysis is complete and reviewed.
- **Auth frames gate:** If Login / Signup / PasswordRecovery frames do not exist in `rideglory.pen`, create them before Task T-1-3 begins. This is a story-level blocker for US-1-3 only.
- **Donut chart flag:** During pre-flight, determine whether the donut chart in `Ako7u` requires geometry/animation changes or is a color-only update. Flag explicitly.
- **Frame ID reference:** All 15 screen Pencil frame IDs are documented in REQUIREMENTS.md Appendix A. Use these IDs in the gap analysis document.

### frontend (flutter_dev)
- Follow the 5–6 module-scoped PR strategy (tasks T-1-3 through T-1-7). Maximum 40 files per PR. Each PR requires `dart analyze` + `flutter test` green before merge into the feature branch.
- Replace all `Color(0x...)` / `Colors.<named>` literals with `Theme.of(context).colorScheme.<property>` or `AppColors` constants.
- Replace `ElevatedButton` → `AppButton`, raw `TextFormField` → `AppTextField`, raw `AlertDialog` → `AppDialog`.
- All user-visible text changes must be reflected in `lib/l10n/app_es.arb`; run `flutter gen-l10n` after ARB changes.
- The AI cover generation widget (iter-4) **must remain functional** — treat as a blocking smoke test.
- The 3 events widget tests (`attendees_list_navigation_test.dart`, `event_filters_bottom_sheet_test.dart`, `events_page_view_test.dart`) must be updated in the same PR that swaps their widgets. No test-rot merges.

### qa
- Run `dart analyze` baseline on `main` before any code is merged (T-1-8). Document existing violations count — it must not grow.
- After all module PRs are merged into the feature branch, execute the full quality gate (T-1-9): `dart analyze` + `flutter test` green + 5 manual smoke tests.
- Smoke test checklist: (a) AI cover generation, (b) Event detail CTA state variants (registered / pending / closed / full), (c) Maintenance donut chart rendering, (d) Home bottom nav pill bar matches frame `VMmN0`, (e) Mapbox route preview in event form.
- Update widget test finders whenever widget classes are renamed or replaced.

### backend
- **No backend work required for iter-1.** Backend agent is not active this iteration. Standby for iter-2 (SOAT + notification infrastructure).

### tech_lead
- Code review focus: layer violations (no data/domain imports in presentation), color literal elimination, widget adoption (`AppButton`, `AppTextField`, `AppDialog`), `app_es.arb` completeness, widget test coverage (no test-rot).
- Each module PR must be reviewed before the next begins. Provide explicit approve / request-changes per PR.

---

## Change log

- 2026-05-13: Iteration 1 scoped from approved PLAN.md (redesign-first plan v3). 11 user stories defined (US-1-1 through US-1-11). 10 tasks defined (T-1-1 through T-1-10). QA gate task T-1-9 included. Scope decisions: ManageAttendeesPage deferred to iter-2, no backend work, no new domain models, 5–6 module-scoped PR strategy, auth frames gate per-story.
