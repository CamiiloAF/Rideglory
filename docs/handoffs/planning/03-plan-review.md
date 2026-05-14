# Plan Review — Rideglory Iterations (Redesign-First Replan)

> Generated: 2026-05-13
> Reviewer: sonnet (UX + Tech Lead)
> Run mode: FEEDBACK_REPLAN

---

## Overall verdict

**APPROVE WITH CHANGES**

Iter-5 is structurally sound and the redesign-first rationale is well-justified. The two scope additions recommended by the Architect (Stories 5.10 and 5.11) push the screen count to 17, which is at the edge of what is realistic for a single frontend-only iteration. The plan is approvable with three targeted scope adjustments and one mandatory quality gate addition. Iters 6–9 are clean — no regressions from the renumbering.

---

## Iter-5 (Redesign) review

### Auth frames gap

**Verdict: Pre-flight workaround required — not a code blocker, but a design gate blocker for Story 5.3 specifically.**

The Architect correctly identifies the risk: Appendix A of REQUIREMENTS.md has no explicit frame IDs for Login, Signup, or Password Recovery. This does not block Stories 5.2, 5.4–5.9 from starting in parallel, but it does block Story 5.3 from entering Flutter implementation until the frame gap is resolved.

The recommended workaround is option (a): Designer opens `rideglory.pen` via Pencil MCP during pre-flight, confirms whether auth frames exist under a different name or group, and either (a1) documents the existing frame IDs if they are present, or (a2) creates the three missing frames in `rideglory.pen` before Story 5.3 implementation begins. This is not a plan-level blocker — it is a per-story gate.

**Required pre-flight addition:** Add a checklist item to iter-5 pre-flight: "Confirm or create Pencil frames for Login, Signup, and Password Recovery in `rideglory.pen` via Pencil MCP tools. Document frame IDs in the gap analysis. Story 5.3 implementation is blocked until this is complete."

Story 5.3 scope itself is low-risk because the system scan confirms component adoption is already mature (only 3 files with raw widget usage, none in auth). The work is color tokenization and typography — straightforward once the design reference exists.

### Scope: 17 screens

**Verdict: Trim recommended — reduce to 15 screens for this iteration.**

At 17 screens the UX design work (gap analysis + Pencil inspection + HTML mockups for screens without confirmed frames) is at risk of overrunning the pre-flight phase and delaying code start. The justification for the scope increase is sound architecturally, but two of the three added screens carry disproportionate design ambiguity:

- **Story 5.10 (RegistrationFormPage + RegistrationDetailPage):** INCLUDE. Frames `pQCmS` (4-step form) and `oUv12` (detail) exist. This is a core conversion flow. Medium-high effort but well-defined.
- **Story 5.11 (ManageAttendeesPage):** DEFER to iter-6 design gate. The Architect notes that frame `dUc9h` may cover "edit only" not "list + edit." If the frame ambiguity forces a descoped "component swap only" treatment, Story 5.11 delivers minimal UX value versus its design investigation cost. Iter-6 introduces new attendee-related surfaces (registration approval notifications) — redesigning ManageAttendeesPage in iter-6 alongside those additions is lower risk and better batched.

**Recommended screen count: 15** (14 original + RegistrationFormPage + RegistrationDetailPage via Story 5.10). This is achievable for a redesign-only iteration.

If the team disagrees and wants to include Story 5.11, it must be explicitly scoped to "component replacement and color tokenization only, no layout rework" with a hard time-box of 1 dev day. No layout work without a confirmed Pencil frame.

### File blast radius risk

**Verdict: At risk — manageable with the right QA approach.**

95–135 files across 6 modules is a large PR surface. The key mitigant is that iter-5 is presentation-layer only: no domain models, no DTOs, no code generation, no generated file conflicts. The diff is wide but shallow.

**Minimum test requirements before this PR merges:**

1. `dart analyze` must pass with zero new violations. This is a hard gate, not advisory. Replacing color literals and widgets across 80+ files will surface lint issues (`prefer_const_constructors`, `avoid_unnecessary_containers`, etc.) — these must be fixed in the same PR, not filed as follow-up issues.
2. All 10 existing test files must pass green. The 3 events widget tests (`attendees_list_navigation_test.dart`, `event_filters_bottom_sheet_test.dart`, `events_page_view_test.dart`) will need finder updates when widgets are swapped — these updates are part of the story, not post-merge cleanup.
3. Manual smoke test required for the 5 highest-risk surfaces: (a) AI cover generation widget end-to-end, (b) Event detail CTA state variants (registered / pending / closed / full), (c) Maintenance donut chart rendering, (d) Home bottom nav pill bar, (e) Mapbox route preview in the event form. These cannot be covered by widget tests alone.
4. No PR should exceed 40 files changed. Split the implementation into per-module PRs if a single PR would exceed this: one PR per feature module (splash + auth, home, events, vehicles, maintenance, registrations). This makes review tractable and isolates regressions.

**Recommended PR strategy:** 5–6 module-scoped PRs merged sequentially into a feature branch, with `dart analyze` and `flutter test` run after each merge.

### DS atom gap (app_event_badge)

**Verdict: Pre-condition for Story 5.5, not DoD only.**

The Architect is correct that `app_event_badge.dart` is likely inlined inside event cards today. Extracting it as a proper atom is not optional busywork — the Architect's forward note flags that iter-7 (tracking) and iter-9 (share metadata preview) will need to reuse it. If Story 5.5 (Events List + Event Detail) completes without extracting the atom, the next developer will inline a second version, creating a two-source-of-truth problem that compounds with every subsequent iteration.

**Required:** Creating `lib/design_system/atoms/app_event_badge.dart` from frame `zKkmE` is a pre-condition for Story 5.5 implementation, not a DoD checkbox. The gap analysis document must include this extraction as a named task. The atom must also be used in Story 5.6 (Event Detail) and any other story that renders event badges.

Similarly, the document slot pill (`aGqnv`) should be extracted as a molecule during Story 5.7 (Garage) given its confirmed reuse in iter-6 SOAT badge. Flag in gap analysis.

### Hardcoded color replacement scope

**Verdict: In scope for iter-5, but scoped to feature files only — not a DoD checkbox to be deferred.**

The estimate of ~33 raw `Color(0x...)` literals and ~80 files with `Colors.<named>` references is the primary implementation volume of this iteration. This is not optional. The PO DoD already states "All hardcoded color hex literals replaced with `Theme.of(context).colorScheme.<property>` or `AppColors` constants" — this review affirms that requirement as non-negotiable.

However, the scope boundary must be stated explicitly to avoid scope creep: color replacement applies to the **`lib/features/`** tree only. Files in `lib/design_system/` and `lib/shared/` that predate this iteration are out of scope unless they are directly touched by a story widget swap. This prevents the iteration from expanding into a full codebase audit.

The replacement work should be done systematically: one module at a time, with `dart analyze` run after each module to catch regressions before moving to the next. A find/replace pass (`Colors.white` → `Theme.of(context).colorScheme.onSurface`, etc.) is acceptable for named colors with clear semantic mappings; raw `Color(0x...)` literals require manual inspection against the design token table.

**UX verdict: AT RISK**
The combination of 15 screens, auth frame ambiguity requiring pre-flight resolution, and the donut chart risk (custom widget that may require geometry changes, not just token swaps) puts UX delivery at risk if pre-flight is rushed. Mitigation: enforce the design gate strictly — no code starts until the gap analysis document is complete and reviewed.

**Tech Lead verdict: AT RISK**
95–135 files with zero test coverage expansion is the core risk. The PR splitting strategy (5–6 module PRs) and the mandatory `dart analyze` gate per PR are the minimum mitigants. The AI cover generation smoke test is a hard gate that must be documented as a test case, not assumed.

---

## Iters 6–9 (brief pass)

**CLEAR — with one naming fix required.**

Renumbering audit passes. All story IDs, DoD bullets, pre-flight steps, cross-iteration references, and the dependency block at the bottom of the PO proposal are correctly shifted by +1. No story content was lost.

**One naming fix required (non-blocking):** Iter-9 section header reads "Deep Links + Compartir Evento + Apple Sign-In" but the renumbering table at the top of the PO proposal reads "Deep Links + Apple Sign-In + Notification Routing." The section header variant omits Notification Routing (Story 9.5, the highest-complexity story). PO must normalize both to: "Deep Links + Apple Sign-In + Notification Routing." This is a documentation fix only — no story content is affected.

**Iters 6–9 specific confirmations:**
- Iter-6: FCM infrastructure, cursor pagination contract, SOAT domain — intact and sequenced correctly. Scope reduction rule (6.7 can fall back to SharedPreferences) is a pragmatic safety valve; keep it.
- Iter-7: Story 7.0 as the mandatory first story (Mapbox migration gate) before 7.1–7.7 is the right structure. GeoJSON LineString vs encoded polyline (Q3) must be resolved before iter-7 begins — flag for PO to force a decision at iter-6 close.
- Iter-8: GoRouter DI assessment as a DoD item before iter-9 is the right governance pattern. Deep link domain provisioning as a hard iter-9 prerequisite is correctly flagged.
- Iter-9: Apple Sign-In entitlement lead time (1 business day for provisioning propagation) is documented in pre-flight — no change needed.

---

## Top risks (updated)

| Rank | Risk | Iter | Mitigation |
|------|------|------|------------|
| 1 | Pre-flight takes longer than expected (auth frames missing, donut chart ambiguity, 15-screen gap analysis) — delays code start | 5 | Enforce design gate strictly: no Flutter code until gap analysis is complete and reviewed. Parallelize: Designer inspects Pencil while Developer runs `dart analyze` baseline on main. |
| 2 | Iter-4 AI cover generation widget breaks during event form refactor (Story 5.6) | 5 | Mandatory smoke test case: generate cover → select image → save event → confirm widget functional. Treat as a blocking acceptance criterion, not advisory. |
| 3 | 95–135 file PR is unreviable as a single diff | 5 | Split into 5–6 module-scoped PRs merged into a feature branch. Each PR requires `dart analyze` + `flutter test` green before merge. |
| 4 | Widget tests (3 of 4) break after widget swaps and are not updated in same PR | 5 | Finder updates are part of each story's definition of done. No test-rot allowed past merge. |
| 5 | Custom donut chart (`Ako7u`) requires geometry/animation rework beyond token swap | 5 | Designer flags during pre-flight: "swap colors only" vs "full rework." If full rework, descope to colors-only and defer chart geometry to post-iter-5 polish. |
| 6 | Story 7.0 (Mapbox migration) consumes full iter-7 sprint | 7 | 7.0 is already gated as iter-blocking. No change — existing mitigation is correct. |
| 7 | GeoJSON vs polyline decision (Q3) not made before iter-7 starts | 6→7 | PO to force decision at iter-6 retrospective. Architect recommendation (GeoJSON LineString) is the default if no decision is made. |
| 8 | Deep link domain provisioning slips past iter-8 close | 8→9 | iter-8 DoD requires `curl` verification of both `.well-known` files before iteration close. Hard stop. |

---

## Recommended scope adjustments for iter-5

1. **Drop Story 5.11 (ManageAttendeesPage)** from iter-5. Defer to iter-6 where it fits naturally alongside registration notification surfaces. If frame `dUc9h` is confirmed to cover the full list + edit view during iter-5 pre-flight, reconsider — but do not pre-commit the scope.

2. **Promote Story 5.10 (RegistrationFormPage + RegistrationDetailPage) to required** — Architect already recommended this; affirmed here. Frames `pQCmS` and `oUv12` exist. This story is included.

3. **Add auth-frame pre-flight checklist item** to iter-5 pre-flight block: "Confirm or create Pencil frames for Login, Signup, and Password Recovery via Pencil MCP tools. Story 5.3 is blocked until frame IDs are documented in the gap analysis."

4. **Add `app_event_badge.dart` atom extraction** as a named pre-condition task in the gap analysis document — not a DoD checkbox. Must be created before Story 5.5 implementation begins.

5. **Normalize iter-9 title** in the renumbering table to match the section header: "Deep Links + Apple Sign-In + Notification Routing."

---

## Quality gates for iter-5

- [ ] Gap analysis document complete and reviewed before any Flutter code changes begin — lists every screen (15) with specific mismatches per component, spacing, color token, and typography rule
- [ ] Pencil MCP tools used to inspect all relevant `rideglory.pen` frames during pre-flight — frame IDs documented for auth screens before Story 5.3 begins
- [ ] `dart analyze` baseline run on `main` branch before any changes — all pre-existing violations documented (not required to fix in this iteration, but violation count must not grow)
- [ ] All 10 existing test files pass green before any redesign work begins (clean baseline confirmed)
- [ ] `app_event_badge.dart` atom extracted from frame `zKkmE` before Story 5.5 implementation begins
- [ ] Implementation split into 5–6 module-scoped PRs; each PR requires `dart analyze` + `flutter test` green before merge into feature branch
- [ ] No single PR exceeds 40 files changed
- [ ] All 3 events widget tests updated in the same PR that swaps their widgets — no test-rot merges allowed
- [ ] Mandatory smoke test documented and executed: AI cover generation → image selection → event save (Story 5.6 acceptance blocker)
- [ ] Designer flags donut chart scope during pre-flight: "token swap only" or "geometry rework needed" — if geometry rework, descope to colors-only for iter-5
- [ ] `dart analyze` zero new violations on the final feature branch before PR to main
- [ ] All hardcoded `Color(0x...)` and `Colors.<named>` literals in `lib/features/` replaced with `Theme.of(context).colorScheme.<property>` or `AppColors` constants
- [ ] All replaced components use design system atoms: `AppButton`, `AppTextField`, `AppPasswordTextField`, `AppDialog`, `ConfirmationDialog`
- [ ] `app_es.arb` updated if any UI copy changed during redesign; `flutter gen-l10n` run and generated files committed
- [ ] Bottom navigation pill bar (`VMmN0`) verified to match frame exactly across all shell screens
- [ ] No new routes, no new domain models, no new use cases, no new backend endpoints merged in this iteration
- [ ] Iter-4 AI cover generation smoke test result documented in PR description
