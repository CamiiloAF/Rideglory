# PO Handoff — pencil-screen-sync

**Date:** 2026-05-14
**Status:** in progress

---

## Goal

Make every user-facing Flutter screen visually identical to its corresponding frame in `rideglory.pen`, using `rideglory.pen` as the sole source of design truth.

---

## Source Quote

> "La app Flutter debe ser visualmente idéntica al proyecto de Pencil. Cada pantalla Flutter debe implementar exactamente lo que muestra el frame correspondiente en `rideglory.pen` — mismos colores, tipografía, espaciado, componentes, iconos y estados."

---

## Interpretation

In iter-1, the Design agent could not access Pencil (app was closed) and invented HTML mockups. The Frontend agent implemented those invented designs. The result is that the current Flutter implementation has no confirmed visual relationship to `rideglory.pen`.

This improvement is a **presentation-layer-only visual sync**: read every Pencil frame, screenshot it, document the exact design tokens, then update each Flutter screen widget by widget until it matches. No business logic, no backend, no domain changes.

The improvement note lists 40 known top-level frame IDs; roughly half are identified and half are "to be identified." The Design agent must resolve all 40 before Frontend writes a single line of code.

---

## Affected Areas — Current State

| Pencil Frame ID | Flutter File Path | Notes |
|---|---|---|
| `dyWWs` Home Dashboard | `lib/features/home/presentation/home_page.dart` | Redesigned in iter-1 from HTML mockup, not from Pencil |
| `Neipf` Events List | `lib/features/events/presentation/list/events_page.dart` | Redesigned in iter-1 from HTML mockup |
| `kAubW` Event Detail | `lib/features/events/presentation/detail/event_detail_page.dart` | Redesigned in iter-1; CTA bar variants exist |
| `PMuA4` Create Event (state A) | `lib/features/events/presentation/form/event_form_page.dart` | AI cover widget must be preserved |
| `zbCa0` Create Event (state B) | `lib/features/events/presentation/form/event_form_page.dart` | Same file, different form state |
| `KCf6W` Garage / Vehicle List | `lib/features/vehicles/presentation/garage/garage_page.dart` | Redesigned in iter-1 |
| `P1GSzZ` Vehicle Detail | `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | Embedded in GaragePage |
| `EqnMm` Add/Edit Vehicle Form | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Redesigned in iter-1 |
| `aGqnv` Document Slot Pill | `lib/design_system/molecules/feedback/document_slot_pill.dart` | Extracted in iter-1; Pencil match not confirmed |
| `v6RqaX` Maintenance Filters | `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` | Implemented |
| `J5h6P` Maintenance Form Step 1 | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | Implemented |
| `ELB5u` Registration — Programado | `lib/features/event_registration/presentation/registration_detail_page.dart` | State variant |
| `eK2WW` Registration — Completado | `lib/features/event_registration/presentation/registration_detail_page.dart` | State variant |
| `heldR` Registration — variante | `lib/features/event_registration/presentation/registration_detail_page.dart` | Third state variant |
| `nxTub` Tracking SOS Alert | `lib/features/events/presentation/tracking/widgets/sos_button.dart` | Alert overlay match to frame unconfirmed |
| `AETwc` SOS Confirmation | `lib/features/events/presentation/tracking/live_map_page.dart` | Dialog; match unconfirmed |
| `tt64n` End Ride Confirmation | `lib/features/events/presentation/tracking/live_map_page.dart` | Dialog; match unconfirmed |
| `o1A6t4` Tracking Map | `lib/features/events/presentation/tracking/live_map_page.dart` + `live_map_widget.dart` | UI chrome only; SDK wiring off-limits |
| `Gv2Rr` Tracking Riders Panel | `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart` | Match unconfirmed |
| `XJtvl` Mis Eventos | `lib/features/event_registration/presentation/my_registrations_page.dart` | Needs Design to confirm mapping |
| `t7MYzR` Forgot Password | Auth feature — exact file TBD by Design | File path not confirmed |
| `A7qDd` Profile | `lib/features/profile/presentation/profile_page.dart` | Implemented; match unconfirmed |
| `VMmN0` Tab Bar (component) | Shell scaffold / bottom nav (path TBD by Architect) | Bottom nav pill bar from iter-1 |
| `zKkmE` Event Badge (component) | `lib/design_system/atoms/badges/app_event_badge.dart` | Extracted in iter-1 |
| `YCuIq`, `pQCmS`, `UqpLS`, `UYeeY`, `o7KqgL`, `uVOQl`, `MrYmb`, `VrqVl`, `LDsMT`, `b5YFuy`, `DJOZ2`, `IUxas`, `f0lXw`, `qs5o1`, `Q44tYx`, `VKLP4` | TBD — Design must identify all | 16 unidentified frames |

---

## Acceptance Criteria

1. Every Flutter screen with a confirmed Pencil frame is visually identical to that frame (colors, typography, spacing, components, icons, states).
2. `dart analyze` passes with 0 errors and 0 warnings.
3. `flutter test` introduces no new failures (4 pre-existing `.g.dart` failures remain acceptable).
4. No `domain/`, `data/`, or DI files are modified.
5. `EventCoverService`, `AIEventCoverWidget`, `route_map_preview.dart`, `live_map_widget.dart`, and `live_map_page.dart` remain functionally unchanged.
6. `AppEventBadge` and `DocumentSlotPill` are updated if they diverge from frames `zKkmE`/`aGqnv`, or confirmed matching and left unchanged.
7. All new or changed user-visible strings are in `lib/l10n/app_es.arb`.
8. Bottom nav pill bar matches frame `VMmN0` across all shell screens.

---

## Regression Guardrails

- **AI cover generation:** smoke test required — generate cover, select image, save event
- **Mapbox route preview:** `route_map_preview.dart` must render without errors
- **Live tracking:** `live_map_widget.dart` and `live_map_page.dart` must not regress
- **ManageAttendeesPage:** do not touch (deferred to iter-2 as Story 2.9)
- **Event tracking SOS button:** functional test — SOS button opens confirmation dialog
- **Registration detail state variants:** all three variants (Programado, Completado, variante) must render
- **Bottom nav:** all 4 shell tabs must be navigable and show active state

---

## Decisions Needed from Downstream Agents

**Design agent (must resolve before Frontend begins any implementation):**
- Screenshot and document ALL 40 top-level frames in `rideglory.pen`
- Identify all 16 unknown frame IDs and map each to a Flutter file or mark as "not yet implemented"
- Clarify `PMuA4` vs `zbCa0` — two states of one page or two distinct pages?
- Identify the exact Flutter file for `t7MYzR` (Forgot Password)
- Confirm whether `XJtvl` is `my_registrations_page.dart` or a different screen
- Confirm which of `rider_telemetry_panel.dart` vs `participants_placeholder_page.dart` corresponds to `Gv2Rr`
- For each frame: document hex colors, font sizes/weights, padding values, component names

**Architect agent:**
- Identify the exact file path for the shell scaffold hosting the bottom navigation bar (`VMmN0`)
- Specify which files in the tracking feature are safe to touch for UI chrome vs. off-limits (map SDK wiring)
- Clarify whether `participants_placeholder_page.dart` should be replaced with real UI or left as-is

---

## Open Questions for the Human

None at this time.

---

## Suggested Phase Plan

- `needsDesign`: true — Design agent must read all Pencil frames and produce `analysis/pencil-frame-map.md` with screenshots before Frontend touches any file
- `needsBackend`: false — pure presentation-layer sync
- `needsFrontend`: true — all widget/page files in scope must be updated
- `needsDb`: false

---

## Notes for Orchestrator

1. **Design gate is hard-blocking.** Frontend must not begin until Design has produced `analysis/pencil-frame-map.md` and screenshots for all confirmed frames. This is the lesson learned from iter-1.
2. The improvement note explicitly states the Design agent must open `rideglory.pen` with `mcp__pencil__open_document` before anything else. Verify Pencil is open before launching the Design phase.
3. Tracking screens (`o1A6t4`, `nxTub`, `AETwc`, `tt64n`, `Gv2Rr`) involve `live_map_page.dart` which is sensitive (WebSocket, GPS, Mapbox). Frontend should treat UI chrome changes there with extra care and run a smoke test after any modification.
4. The 16 unknown frames may include the splash screen and auth screens (login, signup). If confirmed, those are among the most visible screens and should be prioritized in the Frontend work order.
5. This is a presentation-only improvement — no stories should request domain, data, or DI changes. If the Architect or Frontend finds a UI change that requires a domain change, escalate to the human before proceeding.
