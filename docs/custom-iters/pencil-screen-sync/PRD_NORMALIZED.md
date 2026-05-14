# § 1 Title

Pencil Screen Sync — Align all Flutter screens to their rideglory.pen frames

---

# § 2 Goal

Make every user-facing Flutter screen visually identical to its corresponding Pencil frame in `rideglory.pen`, using the existing design system (AppColors, Space Grotesk, 8px border radius) for any detail not explicitly specified in a frame.

---

# § 3 Type and Severity

- **Type:** redesign
- **Severity:** high — affects every user-facing screen in the app; no business logic changes

---

# § 4 Affected Areas

| Pencil Frame ID | Frame Description | Flutter File Path | Current State |
|---|---|---|---|
| `dyWWs` | Home Dashboard | `lib/features/home/presentation/home_page.dart` (+ widgets/) | Implemented with iter-1 redesign; may diverge from actual Pencil frame |
| `Neipf` | Events List | `lib/features/events/presentation/list/events_page.dart` (+ widgets/) | Implemented with iter-1 redesign; origin was HTML mockup, not Pencil |
| `kAubW` | Event Detail | `lib/features/events/presentation/detail/event_detail_page.dart` (+ widgets/) | Implemented; exact match to Pencil not verified |
| `PMuA4` | Create/Edit Event form (state A) | `lib/features/events/presentation/form/event_form_page.dart` (+ sections/) | Implemented; AI cover widget present (must be preserved) |
| `zbCa0` | Create/Edit Event form (state B) | `lib/features/events/presentation/form/event_form_page.dart` (+ sections/) | Same file as above; two form states may map to one page |
| `KCf6W` | Garage / Vehicle List | `lib/features/vehicles/presentation/garage/garage_page.dart` (+ widgets/) | Implemented with iter-1 redesign |
| `P1GSzZ` | Vehicle Detail | `lib/features/vehicles/presentation/garage/garage_page.dart` (vehicle_detail_view.dart) | Embedded in GaragePage; implementation may diverge from frame |
| `EqnMm` | Add/Edit Vehicle Form | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Implemented with iter-1 redesign |
| `aGqnv` | Document Slot Pill (molecule) | `lib/design_system/molecules/feedback/document_slot_pill.dart` | Extracted in iter-1; match to Pencil frame not confirmed |
| `v6RqaX` | Maintenance Filters bottom sheet | `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` | Implemented |
| `J5h6P` | Maintenance Form Step 1 | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` (+ widgets/) | Implemented |
| `ELB5u` | Registration Paso 2 — Programado | `lib/features/event_registration/presentation/registration_detail_page.dart` | Implemented; state variant |
| `eK2WW` | Registration Paso 2 — Completado | `lib/features/event_registration/presentation/registration_detail_page.dart` | Same file — different state tab |
| `heldR` | Registration Paso 2 — variante | `lib/features/event_registration/presentation/registration_detail_page.dart` | Same file — third state variant |
| `nxTub` | Event Tracking SOS Alert | `lib/features/events/presentation/tracking/widgets/sos_button.dart` + live_map_page.dart | SOS button exists; alert overlay not confirmed against frame |
| `AETwc` | SOS Confirmation dialog | `lib/features/events/presentation/tracking/live_map_page.dart` | Confirmation dialog expected; match to frame not confirmed |
| `tt64n` | End Ride Confirmation | `lib/features/events/presentation/tracking/live_map_page.dart` | Dialog present; match to frame not confirmed |
| `o1A6t4` | Event Tracking Map | `lib/features/events/presentation/tracking/live_map_page.dart` + live_map_widget.dart | Implemented; UI chrome (overlays, controls) may diverge |
| `Gv2Rr` | Event Tracking Riders Panel | `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart` | Implemented; match to Pencil not confirmed |
| `XJtvl` | Mis Eventos (My Events) | `lib/features/event_registration/presentation/my_registrations_page.dart` | Implemented; frame labeled "Mis Eventos" — verify it is registrations page |
| `t7MYzR` | Forgot Password | `lib/features/authentication/login/presentation/widgets/login_forgot_password_link.dart` (links to screen) | Password recovery screen — exact page file not confirmed; likely in auth feature |
| `A7qDd` | Profile | `lib/features/profile/presentation/profile_page.dart` (+ widgets/) | Implemented; profile content may diverge |
| `VMmN0` | Component / Tab Bar (reusable) | `lib/shared/widgets/` (bottom nav / shell scaffold) | Implemented as bottom nav pill bar in iter-1 |
| `zKkmE` | Component / Event Badge (reusable) | `lib/design_system/atoms/badges/app_event_badge.dart` | Extracted in iter-1 |
| `YCuIq` | Unknown — to be identified by Design | TBD after Design reads frame | Not yet mapped |
| `pQCmS` | Unknown — to be identified by Design | TBD after Design reads frame | Not yet mapped |
| `UqpLS` | Unknown — to be identified by Design | TBD after Design reads frame | Not yet mapped |
| `UYeeY` | Unknown — to be identified by Design | TBD after Design reads frame | Not yet mapped |
| `o7KqgL` | Unknown — to be identified by Design | TBD after Design reads frame | Not yet mapped |
| `uVOQl` | Unknown — possibly auth | TBD after Design reads frame | Not yet mapped |
| `MrYmb` | Unknown — possibly auth | TBD after Design reads frame | Not yet mapped |
| `VrqVl` | Unknown — possibly auth | TBD after Design reads frame | Not yet mapped |
| `LDsMT` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `b5YFuy` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `DJOZ2` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `IUxas` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `f0lXw` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `qs5o1` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `Q44tYx` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |
| `VKLP4` | Unknown — to be identified | TBD after Design reads frame | Not yet mapped |

> **Note:** The Design agent must read and screenshot ALL 40 top-level frames before finalizing this table. Unknown frames above (rows with "TBD") may map to: splash screen (`lib/features/splash/presentation/splash_screen.dart`), login view (`lib/features/authentication/login/presentation/login_view.dart`), signup view (`lib/features/authentication/signup/presentation/signup_view.dart`), rider profile (`lib/features/users/presentation/pages/rider_profile_page.dart`), maintenance detail (`lib/features/maintenance/presentation/detail/maintenance_detail_page.dart`), or attendees page (`lib/features/events/presentation/attendees/attendees_page.dart`).

---

# § 5 NOT in Scope

- Any screen that has no corresponding frame in `rideglory.pen` (confirmed missing by Design agent)
- Changes to domain models, use cases, repositories, or data layer (DTOs, services)
- Changes to the backend (`rideglory-api`)
- New routes, features, or business logic not present in any Pencil frame
- `EventCoverService` and `AIEventCoverWidget` (iter-4 AI cover generation — touch to preserve only)
- `route_map_preview.dart` (Mapbox route preview — touch to preserve only)
- `ManageAttendeesPage` (`attendees_page.dart`) — deferred since iter-2 (Story 2.9); do not redesign unless its frame is explicitly confirmed by Design
- `live_map_widget.dart` and `live_map_page.dart` live tracking internals (map SDK wiring) — UI chrome overlays only
- New widget tests or test infrastructure (unless existing tests break due to widget swaps)
- SOAT badge and notification center (future iterations)

---

# § 6 Acceptance Criteria

1. Every Flutter screen that has a confirmed Pencil frame renders visually identically to that frame: same colors (hex-exact), same typography family/size/weight, same component layout and spacing.
2. `dart analyze` passes with 0 errors and 0 warnings after all changes.
3. `flutter test` produces no new failures; the 4 pre-existing failures from stale `.g.dart` files remain the only failures.
4. No files in `domain/`, `data/`, or DI (`core/di/`) are modified.
5. `EventCoverService`, `AIEventCoverWidget`, `route_map_preview.dart`, `live_map_widget.dart`, and `live_map_page.dart` are functionally unchanged (no breakage confirmed by smoke test).
6. `AppEventBadge` (atom) and `DocumentSlotPill` (molecule) are updated if they diverge from their Pencil frames (`zKkmE`, `aGqnv`), or left unchanged if they already match.
7. All user-visible text strings added or changed during this sync are present in `lib/l10n/app_es.arb` (no hardcoded Spanish strings in UI widgets).
8. The bottom navigation pill bar matches frame `VMmN0` across all shell screens.
9. All unknown Pencil frames (`YCuIq`, `pQCmS`, `UqpLS`, etc.) are identified by Design and either mapped to an existing Flutter file or confirmed as not yet implemented (and therefore out of scope for this sync).

---

# § 7 Regression Guardrails

| Affected Area | Guardrail |
|---|---|
| Home Dashboard (`dyWWs`) | After changes, verify home loads with main vehicle card and upcoming events section rendering correctly |
| Events List (`Neipf`) | Existing widget test `events_page_view_test.dart` must remain green; event cards and filter chips must function |
| Event Detail (`kAubW`) | CTA bar state variants (register, pending, approved, cancelled) must all render correctly |
| Create/Edit Event form (`PMuA4`, `zbCa0`) | AI cover generation smoke test required: generate cover → select image → save event |
| Garage / Vehicle List (`KCf6W`) | Vehicle list and detail must load with real data; empty state must render |
| Vehicle Detail (`P1GSzZ`) | DocumentSlotPill states (empty/valid/expiringSoon/expired) must all render correctly |
| Add/Edit Vehicle Form (`EqnMm`) | Form submission must complete without errors |
| Maintenance Filters (`v6RqaX`) | Bottom sheet must open and filter list correctly |
| Maintenance Form (`J5h6P`) | Both steps (scheduled and completed) must render; form submission must work |
| Registration Detail (`ELB5u`, `eK2WW`, `heldR`) | All three state variants must render from the same page |
| Event Tracking Map (`o1A6t4`) | `live_map_widget.dart` must not be broken; map must render on device |
| Event Tracking SOS (`nxTub`, `AETwc`, `tt64n`) | SOS button, confirmation dialog, and end-ride dialog must remain functional |
| Tracking Riders Panel (`Gv2Rr`) | `rider_telemetry_panel.dart` renders rider cards without crash |
| My Registrations (`XJtvl`) | Registration list loads with correct empty and data states |
| Profile (`A7qDd`) | Profile page loads user data; action list items are tappable |
| Tab Bar (`VMmN0`) | Bottom nav works across all shell tabs; selected state is visually correct |
| Event Badge (`zKkmE`) | All 6 `AppEventBadge` variants render correctly in event cards |
| Document Slot Pill (`aGqnv`) | All 4 `DocumentSlotPill` states render correctly in vehicle detail |

---

# § 8 Open Questions for Architect / Design / Frontend

**For Design agent:**
1. What do frames `YCuIq`, `pQCmS`, `UqpLS`, `UYeeY`, `o7KqgL`, `uVOQl`, `MrYmb`, `VrqVl`, `LDsMT`, `b5YFuy`, `DJOZ2`, `IUxas`, `f0lXw`, `qs5o1`, `Q44tYx`, `VKLP4` contain? Map each to a Flutter file or confirm out of scope.
2. Frames `PMuA4` (double-width 860px) and `zbCa0` — are these two states of the same `EventFormPage`, or two distinct screens? Document the difference so Frontend knows how to handle.
3. Does frame `t7MYzR` (Forgot Password) correspond to a dedicated page file, or is it an inline flow within `login_view.dart`? Identify the exact Flutter file.
4. Is frame `XJtvl` ("Mis Eventos") the same screen as `my_registrations_page.dart`, or is there a separate "my events as organizer" screen not yet implemented?
5. For frames with multiple states (`ELB5u`, `eK2WW`, `heldR`) — confirm all three map to `registration_detail_page.dart` and document which widget/tab controls the state.
6. Does frame `Gv2Rr` (Riders Panel) correspond to `rider_telemetry_panel.dart` or `participants_placeholder_page.dart`?

**For Architect:**
1. Live tracking screens (`o1A6t4`, `nxTub`, `AETwc`, `tt64n`, `Gv2Rr`) — which files are safe to touch for UI chrome only, and which are strictly off-limits?
2. Is there a shared shell scaffold file that hosts the bottom nav (`VMmN0`)? Identify the exact file path so Frontend knows where to apply changes.
3. Should `participants_placeholder_page.dart` be replaced with the real riders panel UI, or is it intentionally a placeholder pending iter-3?

**For Frontend:**
1. When implementing frame changes for screens that embed multiple states (e.g., registration detail with 3 variants), should a single file handle all states via conditional rendering, or is a new widget per state preferred?
2. The `DocumentSlotPill` molecule has hardcoded Spanish fallback strings per iter-1 handoff. Should these be moved to `app_es.arb` during this sync if the frame reveals new copy, or left as-is?

---

# § 9 Open Questions for the Human

*(None at this time — all blocking questions are directed to downstream agents. The human should confirm if any frames that appear blank or component-only should be treated as new screens requiring implementation rather than design references.)*
