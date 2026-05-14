# Architect Review — Rideglory Iterations (Redesign-First Replan)

> Generated: 2026-05-13
> Run mode: FEEDBACK_REPLAN (redesign iter inserted)
> Architect model: opus

---

## Iter-5 (Redesign) — scope audit

### Screen effort table

| Screen | Frame ID | Implemented | Effort | Notes |
|--------|----------|-------------|--------|-------|
| Splash | (no frame ID — covered implicitly by branding) | Yes (`splash_page.dart`) | LOW | Simple page: logo + catalog loading; mostly tokenization + loading state polish. Single page + cubit; minimal blast radius. |
| Login | (no frame ID; auth module not in Appendix A) | Yes (`login/presentation/`) | MEDIUM | Verify `AppButton` / `AppTextField` / `AppPasswordTextField` already used; gap analysis must enumerate. Auth design intent in `rideglory.pen` should be confirmed via Pencil before coding — Designer to flag if no auth frame exists. |
| Signup | (no frame ID) | Yes (`signup/presentation/`) | MEDIUM | Same as Login. Confirm field layout + step structure. |
| Password Recovery | (no frame ID) | Yes (within authentication) | LOW | Confirmation screen + form; small surface. |
| Home Dashboard | `dyWWs` + `VMmN0` (bottom nav) | Yes (`home_page.dart` + widgets) | MEDIUM | Greeting header, garage card, upcoming rides carousel, bottom nav pill bar. Bottom nav pill bar already extracted to `lib/design_system/organisms/navigation/home_bottom_navigation_bar.dart` — confirm it matches `VMmN0`. SOAT badge explicitly OUT (iter-6/7). |
| Events List | `Neipf` + `zKkmE` (badge) | Yes (`events_page.dart`) | MEDIUM | Search bar, filter chips, event cards. Filter chips (`app_filter_chip.dart`) exist as atom. Event badge component needs verification against `zKkmE` (may need new atom). |
| Event Detail | `kAubW` + `PMuA4` (CTA variants) | Yes (`event_detail_page.dart`, `event_detail_by_id_page.dart`) | MEDIUM-HIGH | Hero image, metric chips, map preview, allowed brands chips, CTA bar with state variants. Two detail pages (by-id + direct) — both must be redesigned. CTA state variants (`PMuA4`) is the highest-risk piece. |
| Create/Edit Event | `zbCa0` | Yes (`event_form_page.dart` + many `widgets/sections/`) | HIGH | Multi-section form, AI cover generation widget (iter-4), Mapbox route preview, multi-brand selector. Largest single-screen surface. `event_form_multi_brand_section.dart` contains raw `TextFormField` — flagged for refactor. **Critical: iter-4 AI cover generation must remain intact.** |
| Garage (Vehicle List) | `KCf6W` | Yes (`garage_page.dart` + widgets) | MEDIUM | Main vehicle card, other-vehicles list. `vehicle_list_item.dart` already in organisms. |
| Vehicle Detail | `P1GSzZ` | Yes (vehicle detail rendered inside garage/widgets stack) | MEDIUM | Specs, document slots (SOAT/tech review). Document slots are stubs — iter-5 only adds visual placeholder, no logic. |
| Add/Edit Vehicle | `EqnMm` + `aGqnv` (documents component) | Yes (`vehicle_form_page.dart` + `widgets/vehicle_form.dart`) | MEDIUM | Field layout, image upload UI. Brands autocomplete already uses molecule `app_autocomplete_chips_field.dart`. |
| Maintenance Dashboard | `Ako7u` | Yes (`maintenances_page.dart`) | MEDIUM-HIGH | Donut chart health %, urgency sections. Donut chart is custom — design alignment may require redrawing. |
| Maintenance History | `SykjL` + `v6RqaX` (filters sheet) | Yes (`list/maintenances/...`) | MEDIUM | Year grouping, cost summary. `maintenance_filters_bottom_sheet.dart` has raw `TextFormField` — flagged. |
| New Maintenance Form | `J5h6P` (step 1) + `eK2WW` (step 2 completed) + `ELB5u` (step 2 scheduled) | Yes (`maintenance_form_page.dart`) | MEDIUM | 3-step form. Grid 2×4 service type selector at step 1. Tabs at step 2. |

**Total screens in PO scope: 14.** All have matching frames in `rideglory.pen` Appendix A (or fall under the auth umbrella). All are implemented in `lib/`.

### Auth frame gap

Appendix A does **not** list explicit frames for Login / Signup / Password Recovery. Story 5.3 references "the exact color tokens from the design system" but no frame ID. **Risk: Designer may discover no auth-specific frames exist in `rideglory.pen` during pre-flight.** If true, options are (a) Designer creates auth frames in Pencil during pre-flight (recommended); or (b) descope Story 5.3 to a component-swap-only task (no layout work). Architect recommends (a) — defer code start of 5.3 until auth frames exist. This must be raised in the gap analysis document.

### PO open questions answered

**Q1 — ManageAttendeesPage (`AttendeesManagementPage`):** **INCLUDE as Story 5.11 (new).** The page exists in `lib/features/events/presentation/attendees/`, is used by event organizers, and represents a non-trivial visual surface (search + filter + per-row actions). Excluding it leaves a visible inconsistency in a core flow (organizer workflow). Appendix A does not list a frame ID for it explicitly, but `dUc9h` ("Editar Inscripción — organizador") is the closest match; Designer should confirm during pre-flight whether `dUc9h` covers list + edit or only edit. Effort: MEDIUM. If `dUc9h` does not cover the list view, descope to "swap components + tokenize colors only, no layout rework" and defer full layout to a later polish iteration — but do not skip entirely.

**Q2 — Registration pages (`RegistrationFormPage`, `RegistrationDetailPage`, `ManageRegistrationPage`):** **PARTIAL INCLUDE.** Recommendation:
- `RegistrationFormPage` (frame `pQCmS`): **INCLUDE** as Story 5.10 (promoted from optional). This is a core conversion flow; visual debt here harms perceived quality more than any other screen. 4-step form with significant surface — MEDIUM-HIGH effort.
- `RegistrationDetailPage` (frame `oUv12`): **INCLUDE** as part of Story 5.10 (same story scope). The detail page is the natural successor screen after form submission.
- `ManageRegistrationPage`: covered by Q1 answer (it's the organizer-side ManageAttendees flow).

**Justification:** Bringing registration into iter-5 prevents iter-6 (SOAT) and iter-7 (Tracking) from inheriting a partially-redesigned events module. Cost of inclusion: 1 additional story; total screens grows from 14 → 16. This is acceptable scope for a redesign-only iteration since there is **zero domain/data layer work**.

### Architecture risk assessment

**Presentation-only guarantee:** **Confirmed with one minor exception.** A grep of `lib/features/*/presentation/` shows only 3 imports of `core/data/` files, all referencing `colombia_motos_brands_data.dart` (a static in-app catalog, not a network DTO). No presentation code imports feature DTOs/services. No code generation files (`*.g.dart`, `*.freezed.dart`) need regeneration. Domain models and data services are untouched.

**Design system gaps (potential new atoms/molecules required):**
- **Event Badge atom** (`zKkmE`): does not appear as a discrete file in `lib/design_system/atoms/`. Likely inlined inside event cards today. **Recommend: extract as new atom `app_event_badge.dart`** during iter-5.
- **Bottom nav pill bar**: `home_bottom_navigation_bar.dart` exists. Verify it matches frame `VMmN0` exactly; if drift, refactor in place (no new atom).
- **CTA state variants** (frame `PMuA4`): event detail CTA has multiple states (registered / pending / closed / full). Confirm `AppButton` variants cover all states; if not, add `AppButton.variant` enum entries — small change.
- **Donut chart health** (frame `Ako7u`): custom widget in `lib/features/maintenance/presentation/widgets/`. Keep feature-local (not promoted to design system) — too domain-specific.
- **Document slot pill** (frame `aGqnv`): used in vehicle detail. Likely inlined. Consider extracting as molecule for reuse in iter-6 SOAT badge.

**File blast radius:**
- 6 affected feature modules (splash, authentication, home, events, vehicles, maintenance) contain **285 `.dart` files** (excluding generated `*.g.dart` / `*.freezed.dart`).
- Estimated files actually requiring edits: ~80-120 files (pages + widget files + section files). Most domain/data files untouched.
- With Q1+Q2 additions (event_registration), add ~15 more files. **Total estimate: ~95–135 files touched.**

**Widget test impact:**
- Current test suite: 10 test files, of which 4 are widget tests:
  - `rider_profile_page_test.dart`
  - `attendees_list_navigation_test.dart`
  - `event_filters_bottom_sheet_test.dart`
  - `events_page_view_test.dart`
- **Blast radius: ~3 of 4 widget tests likely need updates** (rider profile is in iter-8 scope and not redesigned in iter-5, so it should remain green). The 3 events widget tests will need their `find.byType(...)` and finder assertions updated as widgets are swapped. Bloc/cubit tests (6 files) are unaffected.
- Low test debt overall — manageable.

**Hardcoded literals estimate:**
- **80 feature files** contain hardcoded `Color(0x...)` or `Colors.<named>` literals.
- Raw `Color(0x...)` instances: **33** across the lib/features tree.
- Raw `ElevatedButton` / `TextFormField` / `OutlinedButton` / `FilledButton` / `AlertDialog(`: only **3 files** flagged (good — design system adoption is already mature):
  - `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart`
  - `lib/features/maintenance/presentation/widgets/item_card/mileage_info_dialog.dart`
  - `lib/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart`
- **Conclusion:** the heavy lift is color tokenization (~33 raw hex literals + ~80 files with `Colors.named` references), not widget swapping. Component adoption is already strong.

### Backend changes needed

**None — confirmed.** Iter-5 is presentation-layer only. No new DTOs, no new endpoints, no API contract changes, no `rideglory-api` work. The Story 5.6 acceptance criteria explicitly preserves iter-4 AI cover generation (which is a backend-integrated feature) without modification.

**Exception flag:** if Designer determines that the bottom nav pill bar `VMmN0` requires data not currently provided by `HomeDashboardService` (e.g., per-tab badge counts), that would be a backend change — but PO scope explicitly excludes SOAT badge (iter-6) and notification badge logic (iter-6). So this is highly unlikely. Document this as a watch-item in the gap analysis.

---

## Renumbering validation

**PASS with 1 minor finding to fix.**

Cross-iteration references audited in `01-po-proposal.md`:

**Carry-forward references that read correctly (good):**
- Iter-6 DoD: "**Home Dashboard SOAT badge NO incluido en esta iteración** — se agrega en iter-7" → correctly updated from prior "iter-6".
- Iter-7 DoD: "`VehicleModel` con `soatStatus` y `soatExpiryDate`; Home Dashboard badge SOAT en card de vehículo principal" → matches the iter-6 deferral note above. Consistent.
- Iter-8 action item: "Action item during iter-8 (hard prerequisite for iter-9)" → correctly renumbered (previously "during iter-7 (prereq for iter-8)").
- Iter-8 DoD: "GoRouter DI assessment ... planificar como Story 9.0" → correctly references iter-9.
- Iter-9 pre-flight: "Dominio (provisionado en iter-8)" → correctly references iter-8.
- Iter-9 pre-flight: "GoRouter DI: si el assessment de iter-8 determinó..." → correctly references iter-8.
- Dependency block at bottom (iter-5 → iter-6 → iter-7 → iter-8 → iter-9): all correct.
- "Iteration numbering change" table at top: maps prior 5→6, 6→7, 7→8, 8→9 correctly.

**One finding — title drift on Iter-9:** Iter-9 section header reads "**Iteration 9: Deep Links + Compartir Evento + Apple Sign-In**" but the top renumbering table and original prior-iter-8 title is "**Deep Links + Apple Sign-In + Notification Routing**". These are functionally the same (notification routing = Story 9.5), but the title in the renumbering table at line 28 does not match the section header at line 228. **Recommendation:** PO should normalize both to the same title (architect prefers "Deep Links + Apple Sign-In + Notification Routing" as it more accurately captures Story 9.5, the highest-risk story). Non-blocking — naming-only.

No story content was lost or mis-renumbered. All pre-flight steps, DoD bullets, and architectural notes carry forward intact.

---

## Iters 6–9 — carry-forward confirmation

All content from prior iters 5–8 is preserved with story IDs correctly shifted by +1 throughout:

- **Iter-6 (was iter-5):** 8 stories (6.1–6.8), pre-flight intact (4 seed.ts files, 4 prisma resets, api-gateway prisma init, @nestjs/schedule install, vehicles 200 check), DoD intact (FCM init, scope-reduction rule, home dashboard SOAT badge deferral to iter-7).
- **Iter-7 (was iter-6):** 8 stories (7.0–7.7), pre-flight note about 7.0 being the Mapbox migration story intact, DoD intact (Mapbox-only verification, GeoJSON LineLayer, foreground task, geolocator AppleSettings, VehicleModel SOAT badge introduction).
- **Iter-8 (was iter-7):** 5 stories (8.1–8.5), pre-flight note "none" intact, action item for deep-link domain provisioning intact and correctly flagged as iter-9 prerequisite, DoD intact (Follow entity, PublicVehicleDto, FollowCubit optimistic, GoRouter DI assessment).
- **Iter-9 (was iter-8):** 5 stories (9.1–9.5), pre-flight intact (entitlement + provisioning profile + Apple provider + domain verification + GoRouter DI conditional Story 9.0), DoD intact (app_links, sign_in_with_apple, NotificationRouteHandler with cold-start/background handling).

**No regressions found.** No story body references stale iteration numbers.

---

## Stack assessment (iters 6–9)

**No changes from prior review — confirmed.** All stack decisions remain valid:

- `app_links ^6.x` for deep links (replaces Firebase Dynamic Links, EOL Aug 2025) — confirmed.
- `mapbox_maps_flutter ^2.6.0` as sole maps SDK — confirmed; `google_maps_flutter` + `geocoding` already absent or to be removed in Story 7.0.
- `sign_in_with_apple ^6.x` — iOS-only conditional render — confirmed.
- `flutter_foreground_task` (Android) + `geolocator` AppleSettings (iOS) for background GPS — confirmed.
- `@nestjs/schedule` cron in api-gateway with `America/Bogota` TZ — confirmed.
- `flutter_local_notifications` for iOS foreground banners + Android notification channel — confirmed.
- Cursor pagination contract `{ data, nextCursor }` for notifications — confirmed.
- GeoJSON LineString route (open question Q3) — recommended; pending PO/PRD confirmation.

**One new watch-item raised by iter-5 insertion:** if iter-5 promotes a new atom `app_event_badge.dart` (frame `zKkmE`) into the design system, iter-7 (tracking) and iter-9 (share metadata preview cards) should reuse it. No new dependency required; design-system inheritance only.

---

## Updated risks

| Risk | Iter | Likelihood | Mitigation |
|------|------|-----------|------------|
| Designer discovers no explicit Pencil frames for Login/Signup/PasswordRecovery during iter-5 pre-flight | 5 | Medium | Block code start on Story 5.3 until Designer either confirms frames exist or creates them in `rideglory.pen`. Gap analysis must call this out explicitly. |
| Iter-4 AI cover generation widget breaks during event form refactor (Story 5.6) | 5 | Medium | Mandatory smoke test: generate cover, select image, save event. DoD already includes "Iter-4 AI cover generation widget verified functional after all changes" — keep it. |
| Scope creep: Q1 (ManageAttendees) + Q2 (Registration form/detail) add 3 screens to iter-5, expanding from 14 to 17 | 5 | High | Accept the scope expansion. The cost is justified: zero domain/data work, and excluding these screens leaves a half-redesigned events module that taints iter-6/7. Promote optional Story 5.10 to required and add Story 5.11 for ManageAttendees. |
| Widget tests (3 of 4) break after widget swap | 5 | High | Update finders concurrently with widget refactor (same PR). Do not let tests rot. |
| Custom donut chart (frame `Ako7u`) requires visual rework beyond simple token swap | 5 | Medium | Designer to flag during pre-flight whether donut chart is a "swap colors only" task or requires geometry/animation changes. If the latter, descope to colors-only and defer full chart rework. |
| Event badge component (`zKkmE`) inconsistently used today; extracting as new atom may break tests | 5 | Low | Run widget tests on every PR; update finders. |
| Iter-7 Story 7.0 (Mapbox migration) consumes the entire iter — blocks 7.1–7.7 | 7 | Medium | Already mitigated: pre-flight requires 7.0 PR merged before 7.1 starts. No change. |
| Iter-9 Story 9.5 (NotificationRouteHandler) requires GoRouter to be DI-registered | 9 | Medium | iter-8 DoD requires GoRouter DI assessment; iter-9 pre-flight has conditional Story 9.0. No change. |
| Deep link domain provisioning slips past iter-8 close → blocks iter-9 | 8 → 9 | Medium | iter-8 action item explicitly flagged as iter-9 blocker; pre-flight iter-9 includes `curl` verification. No change. |

---

## Open questions resolved / escalated

**Resolved:**
- Q1 (ManageAttendeesPage in iter-5): **YES — include as Story 5.11.** New story to be added by PO.
- Q2 (Registration pages in iter-5): **YES — include `RegistrationFormPage` + `RegistrationDetailPage` as Story 5.10 (promoted from optional). `ManageRegistrationPage` covered by Q1 answer.** PO to update story list.

**Escalated to PO (non-blocking — for plan-review phase):**
- Iter-9 title drift: section header vs. renumbering table mismatch. Normalize to "Deep Links + Apple Sign-In + Notification Routing".
- Auth frame gap in `rideglory.pen`: Story 5.3 needs frame IDs documented or new frames created during pre-flight. PO should add a checklist item to iter-5 pre-flight: "Confirm or create Pencil frames for Login, Signup, Password Recovery before Story 5.3 begins."

**Still open (carried from prior plan, decision needed before iter-7):**
- Q3 (`routeGeoJson` vs encoded polyline): Architect reaffirms GeoJSON LineString recommendation. Decision needed before iter-7 begins.
- Q4 (Deep link domain choice): `links.rideglory.app` vs api-gateway-served. Must be decided during iter-8 action-item phase.
- Q5 (`notifications-ms` extraction post-MVP): No decision required for iter-5–9 execution; document intent post-MVP.

---

*Architect review complete. Ready for plan-review phase. Recommendation: PO incorporates Q1/Q2 answers as new Stories 5.10 and 5.11 (drop "optional" tag from 5.10), fixes iter-9 title drift, and adds auth-frame pre-flight checklist item.*
