# Architect handoff — Iteration 1

**Date:** 2026-05-14
**Status:** done
**Iteration goal:** UI/UX Redesign — bring 15 existing screens into alignment with `rideglory.pen`. Presentation layer only.

---

## Iteration 1 architectural constraint (LOAD-BEARING)

> **Iter-1 is presentation-layer ONLY.**
> No `domain/` changes. No `data/` changes. No DTOs. No services. No use cases. No new routes. No DI changes (other than registering newly extracted design-system widgets, which are stateless — no DI). No code generation (`build_runner`) run required.
> No `rideglory-api` changes — backend agent is **not active** this iteration.

Rationale: per existing-system scan + PO scope, only 3 imports of `core/data/` exist in `lib/features/*/presentation/`, all referencing `colombia_motos_brands_data.dart` (a static catalog, not a service). Component adoption is mature (only 3 files use raw `ElevatedButton`/`TextFormField`/`AlertDialog`). The work is **color tokenization (~99 files reference `Colors.<named>`, ~20 files use `Color(0x…)` literals)** + **screen recomposition to match Pencil frames** + **two new design-system primitives**.

If any agent in this iteration needs to add a new domain model, DTO, service, route, or backend endpoint to satisfy a story → STOP. Escalate to PO; the story is mis-scoped.

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|----------------|--------------|----------------------|
| splash | none | none | `splash_page.dart` recomposed to match Pencil; loading/error/success visual states use `AppLoadingIndicator` + design tokens (US-1-2) |
| authentication | none | none | `login_page.dart`, `signup_page.dart`, `password_recovery_page.dart` swap raw widgets → `AppButton`/`AppTextField`/`AppPasswordTextField`; Space Grotesk applied via theme; no hardcoded colors (US-1-3) |
| home | none | none | `home_page.dart` recomposed to match frame `dyWWs` (greeting header, garage card, upcoming rides horizontal scroll, bottom nav `VMmN0`); SOAT badge **not added** (iter-2/3) (US-1-4) |
| events | none | none | `event_list_page.dart`, `event_detail_page.dart`, filter chips, filter bottom sheet, CTA bar match frames `Neipf`/`kAubW`; new atom `app_event_badge.dart` consumed in card contexts (US-1-5). `create_event_page.dart` matches frame `zbCa0` — AI cover widget + Mapbox route preview preserved untouched (US-1-6) |
| vehicles | none | none | `vehicle_list_page.dart`, `vehicle_detail_page.dart` match frames `KCf6W`/`P1GSzZ`; new molecule `document_slot_pill.dart` extracted from `aGqnv` (US-1-7). `vehicle_form_page.dart` matches `EqnMm` — document slot section is **non-functional UI placeholder** for iter-2 (US-1-8) |
| maintenance | none | none | dashboard, history, step1/step2 forms match frames `Ako7u`/`SykjL`/`J5h6P`/`eK2WW`/`ELB5u`; donut chart geometry **scope-flagged** by Design — color-only swap unless Design upgrades scope (US-1-9) |
| event_registration | none | none | `my_registrations_page.dart`, `registration_detail_page.dart` adopt design-system components, no hardcoded colors, correct empty/loading states (US-1-10). `manage_attendees_page.dart` is **deferred to iter-2 Story 2.9** |
| profile / users / tracking / live_tracking | none | none | **Out of scope** for iter-1 (no PO story targets these screens) |

---

## API contracts (rideglory-api changes)

**No changes.** Backend agent is idle this iteration. See `docs/handoffs/architect-for-backend.md`.

---

## New models and DTOs

**None.** No domain models, no DTOs added.

## New design-system components (presentation only)

| Name | Layer | File path | Source frame | Used by |
|------|-------|-----------|--------------|---------|
| `AppEventBadge` | atom | `lib/design_system/atoms/badges/app_event_badge.dart` (new `badges/` subfolder) | `zKkmE` | Event card image overlay (list + detail), upcoming-rides carousel on Home |
| `DocumentSlotPill` | molecule | `lib/design_system/molecules/feedback/document_slot_pill.dart` | `aGqnv` | Vehicle detail document section (US-1-7), vehicle form document slot section non-functional placeholder (US-1-8). **Reused in iter-2 for SOAT badge wiring.** |

Both files MUST be added to the corresponding barrel exports:
- `lib/design_system/atoms/atoms.dart` → add `export 'badges/app_event_badge.dart';`
- `lib/design_system/molecules/molecules.dart` → add `export 'feedback/document_slot_pill.dart';`

Constructors: `const`, stateless, no `BuildContext` capture in fields. Colors come from `Theme.of(context).colorScheme` or `AppColors`. Strings come from caller (no `context.l10n` inside the widget) so they remain pure presentation primitives reusable across features.

## Color tokenization strategy (replaces `Color(0x…)` and `Colors.<named>`)

**Mapping policy (apply per file, in this priority order):**
1. **Semantic theme tokens (preferred)** — `Theme.of(context).colorScheme.primary | onPrimary | surface | onSurface | surfaceContainerHighest | outline | error | onError`. Use when the color carries a semantic role.
2. **`AppColors` palette constants** — for dark surfaces/borders/text not covered by `colorScheme`: `AppColors.darkBackground`, `AppColors.darkSurface`, `AppColors.darkSurfaceHighest`, `AppColors.darkBorder`, `AppColors.darkTextPrimary`, `AppColors.darkTextSecondary`, `AppColors.darkInputIcon`, `AppColors.primaryGradient`, `AppColors.maintenanceUrgent|Warning|Ok`, `AppColors.licensePlateTagBackground|Text`.
3. **Status palette** — `AppColors.success|warning|error|info` (and `Light`/`Dark` variants) for non-themed status indicators (e.g., maintenance urgency dots, badge backgrounds).

**Forbidden after iter-1:** `Color(0xFF…)` in `lib/features/`. `Colors.<named>` literals in `lib/features/` **except** `Colors.transparent` and `Colors.black`/`Colors.white` when overlaying images (which should still prefer `AppColors.overlay*` if available).

**Process per module PR:**
1. Run `grep -rE "Color\(0x|Colors\.(?!transparent\b|black\b|white\b)" <module-path>` to enumerate occurrences.
2. Map each to one of the three buckets above. If a color has no clear mapping, add it to `AppColors` as a domain-specific constant (do NOT inline `Color(0x…)`) and document it in the PR description.
3. `dart analyze` after each substitution batch.

If any new `AppColors` constant is added during the redesign, append a one-line entry to the architect handoff "Change log" section of *this* file in the same PR.

## Environment variables

**None added.** No `.env` keys, no Firebase Remote Config keys.

## Module PR strategy (compatibility check)

PO defined 5–6 module-scoped PRs (≤ 40 files each) targeting the `iter-1` feature branch. Architecturally compatible because:
- Each module touches only files inside one `lib/features/<feature>/presentation/` subtree (+ shared design system in PRs 3 and 4 for the new atom/molecule).
- No shared cross-feature dependency edits (no `injection.dart` re-wiring, no `app_router.dart` route additions, no shared `core/` mutations apart from the `AppColors` additions noted above).
- Test impact is local: `attendees_list_navigation_test.dart`, `event_filters_bottom_sheet_test.dart`, `events_page_view_test.dart` updated in the same PR (PR 3) that swaps their target widgets. No cross-module test churn.

**Merge order (recommended):** PR 1 (splash+auth) → PR 2 (home) → PR 3 (events) → PR 4 (garage) → PR 5 (maintenance+registration). PR 3 must be preceded by extraction of `AppEventBadge`; PR 4 must be preceded by extraction of `DocumentSlotPill`.

**Branch:** `iter-1` (already exists, current branch).

## Risks and open questions

- **Donut chart scope drift (US-1-9):** if Design flags geometry/animation change, descope to color-only per PO directive — no new package, no animation refactor in iter-1.
- **AI cover widget regression risk (US-1-6):** EventForm refactor must NOT touch `EventFormCubit`, `EventCoverService`, or any iter-4 cubit/service. Only the page composition + section widget styling. QA smoke test (a) is the gate.
- **Mapbox route preview (US-1-6):** `route_map_preview.dart` widget left untouched; only its surrounding page chrome restyled. Architect prohibition: do NOT swap to a different map widget in iter-1.
- **`Colors.transparent`/`black`/`white` exemptions:** explicitly allowed for image overlays and dividers. QA gate `T-1-9` should grep for the broader pattern but exempt these three names.

## Next agent needs to know

- **Backend (rideglory-api):** stand down for iter-1. Resume in iter-2.
- **Design:** read `docs/handoffs/architect-for-frontend.md` for the design-system primitive specs (`AppEventBadge`, `DocumentSlotPill`) so the gap analysis annotates frame mappings consistently.
- **Frontend (Flutter dev):** read `docs/handoffs/architect-for-frontend.md` for full component extraction plan, color tokenization mapping, l10n key conventions, and the per-module file lists.
- **DevOps:** read `docs/handoffs/architect-for-devops.md` — no CI changes, no new env vars, but the branch protection on `iter-1` needs to allow 5-PR merge cadence.
- **QA:** read `docs/handoffs/architect-for-qa.md` for test commands, baseline + final gates, and the 5 smoke-test traceability matrix.

## Change log

- 2026-05-14 (iter-1): Architect phase complete. Confirmed presentation-layer-only constraint. Defined two new design-system primitives (`AppEventBadge` atom, `DocumentSlotPill` molecule) with file paths and barrel-export instructions. Documented 3-tier color tokenization policy (colorScheme → AppColors → status palette). No backend changes. No domain/data/DI/router changes. Module PR strategy validated against shared-file impact (low). DIAGRAMS.md updated with design-system component hierarchy diagram (no data model diagrams required this iter).
