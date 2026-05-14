# Architect handoff — custom-iter `pencil-screen-sync`

**Date:** 2026-05-14
**Status:** done
**Type:** redesign (presentation-layer only)
**Goal:** Make every user-facing Flutter screen visually identical to its corresponding `rideglory.pen` frame.

---

## 1. Load-bearing architectural constraint

> **This custom-iter is PRESENTATION-LAYER ONLY.**
> No `domain/` changes. No `data/` changes. No DTOs, services, repositories, use cases. No new routes. No DI (`core/di/`) changes. No `build_runner` run required (no generated code touched). No `rideglory-api` changes.
>
> Touchable surface: `lib/features/*/presentation/pages|widgets|*_page.dart|*_view.dart`, `lib/design_system/`, `lib/shared/widgets/`, and `lib/l10n/app_es.arb` (copy only).
>
> If any agent finds a UI change that *requires* a domain/data/DI/router change → **STOP and escalate to the human.** The story is mis-scoped.

This mirrors and extends the iter-1 architect constraint (`docs/handoffs/architect.md`). The difference: iter-1 implemented from invented HTML mockups; this iter re-syncs against the *actual* Pencil frames, which Design must read first.

---

## 2. Hard dependency: Design gate

Frontend **cannot start** until the Design agent has produced, under `docs/custom-iters/pencil-screen-sync/analysis/`:

1. `pencil-frame-map.md` — every one of the ~40 top-level `rideglory.pen` frames, screenshot + frame→Flutter-file mapping, with all 16 currently-unknown frame IDs resolved (or marked "not implemented → out of scope").
2. Per-screen spec docs (one per confirmed frame, or grouped per module) documenting: hex colors, font family/size/weight per text role, padding/margin/gap values, component names, icon names, and per-state variations.

Design **MUST** use Pencil MCP tools — `mcp__pencil__open_document` first, then `mcp__pencil__get_screenshot` + `mcp__pencil__batch_get` / `mcp__pencil__snapshot_layout` for every frame. No invented designs. This is the iter-1 lesson learned.

Design must also answer the open questions in §8 below.

---

## 3. Answers to PO's Open Questions for Architect

**Q1 — Live tracking: which files are safe to touch (UI chrome) vs off-limits?**

| File | Verdict |
|------|---------|
| `lib/features/events/presentation/tracking/live_map_page.dart` | **UI chrome ONLY.** May restyle `AppAppBar`, the `Positioned` overlay chrome (active-riders chip, zoom controls cluster, my-location button, SOS button placement), spacing, colors, and dialog styling. **MUST NOT** touch: `initState`/`dispose`, `_guardPermission`, `_loadInitialCamera`, `LiveTrackingSessionHolder`/`LiveTrackingCubit` wiring, `CameraPosition` logic, the `LiveMapWidget` instantiation contract. |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | **OFF-LIMITS.** Map SDK wiring (Google Maps controller, markers). Do not touch. |
| `lib/features/events/presentation/tracking/widgets/initials_marker_icon.dart` | **OFF-LIMITS.** Marker rendering tied to SDK. |
| `lib/features/events/presentation/tracking/widgets/sos_button.dart` | **Touchable** (pure presentation atom — restyle to match `nxTub`). Keep `onPressed`/`label` API. |
| `lib/features/events/presentation/tracking/widgets/map_zoom_controls.dart`, `zoom_button.dart`, `my_location_button.dart` | **Touchable** (pure UI). Keep callback APIs. |
| `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart`, `rider_telemetry_card.dart`, `rider_telemetry_riders_content.dart`, `telemetry_metric.dart` | **Touchable** (pure UI — restyle to match `Gv2Rr`). Keep BLoC `buildWhen`/state-read shape. |
| SOS / End-Ride dialogs (`AETwc`, `tt64n`) | Currently the SOS button's `onPressed` is a no-op (`onPressed: () {}`) and there is **no end-ride dialog wired in `live_map_page.dart`**. Treat these frames as **visual spec only**: if Design confirms the frames are confirmation dialogs, Frontend may build them with `ConfirmationDialog`/`AppDialog` styled to match — **but wiring them to real SOS/end-ride logic is OUT OF SCOPE** (that is domain/cubit work). Render-only, triggered by existing buttons, no business behaviour. If Design's frames imply behaviour beyond styling, escalate. |
| `lib/features/events/presentation/tracking/cubit/*`, `live_tracking_session_holder.dart`, `tracking_location_settings.dart` | **OFF-LIMITS** (state/session/permissions). |

**Q2 — Shell scaffold hosting the bottom nav (`VMmN0`)?**

The bottom nav is composed across three files (all touchable presentation):
- `lib/shared/widgets/main_shell.dart` — `MainShell`, the `StatefulShellRoute` host. Wraps `Scaffold` + `HomeBottomNavigationBar`. Touch only the `Scaffold`/layout chrome; **do not** change the branch-index ↔ bar-index mapping logic (`_branchIndexToBarIndex`, `_addButtonBarIndex`) or `navigationShell.goBranch` wiring.
- `lib/shared/widgets/home_bottom_navigation_bar.dart` — `HomeBottomNavigationBar`, the actual pill bar (height, shadow, `Row` of items, add button). **Primary file to restyle for `VMmN0`.** Note hardcoded Spanish labels (`'Inicio'`, `'Garaje'`, `'Eventos'`, `'Perfil'`) → must move to `app_es.arb` if touched.
- `lib/shared/widgets/bottom_nav_item.dart` + `lib/shared/widgets/bottom_nav_add_button.dart` — the item atom + center add button. Restyle to match frame; keep `onTap` API.
- Mirror barrel exports under `lib/design_system/organisms/navigation/` (`main_shell.dart`, `home_bottom_navigation_bar.dart`, `bottom_nav_item.dart`, `bottom_nav_add_button.dart`) just re-export the `shared/widgets/` versions — **edit the `shared/widgets/` files, not the re-export shims.**

**Q3 — Should `participants_placeholder_page.dart` be replaced with real UI?**

**No.** Leave `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` as-is. It is an intentional placeholder; the real riders UI is `rider_telemetry_panel.dart` (the `Gv2Rr` target, embedded in `live_map_page.dart`). Replacing the placeholder with real functionality is feature work, not a visual sync. If Design maps a Pencil frame to it, escalate — do not implement.

---

## 4. Change map — by module

Risk legend: **low** = color/text/token swap · **med** = layout restructure within existing widget tree · **high** = widget replacement or new widget extraction.

### Module A — splash + auth (`lib/features/splash/`, `lib/features/authentication/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/splash/presentation/splash_screen.dart` | Splash with brand content, glow background, footer | Match Pencil splash frame (likely one of the unknown IDs) — colors, glow, logo placement, spacing | med |
| `lib/features/splash/presentation/widgets/splash_brand_content.dart` | Logo + brand text | Match frame typography/spacing | low |
| `lib/features/splash/presentation/widgets/splash_glow_background.dart` | Radial glow backdrop | Match frame gradient/glow colors | low |
| `lib/features/splash/presentation/widgets/splash_footer.dart` | Footer text | Match frame copy/style | low |
| `lib/features/authentication/login/presentation/login_view.dart` | Login screen; **also hosts the inline forgot-password flow** (no dedicated page — see §8) | Match Pencil login frame; the `t7MYzR` forgot-password frame is an inline state/dialog of this view | med |
| `lib/features/authentication/login/presentation/widgets/login_heading.dart` | Heading text | Match frame typography | low |
| `lib/features/authentication/login/presentation/widgets/login_email_field.dart` | Email input | Match frame field style (likely `AppTextField`) | low |
| `lib/features/authentication/login/presentation/widgets/login_password_field.dart` | Password input | Match frame field style | low |
| `lib/features/authentication/login/presentation/widgets/login_field_label.dart` | Field label | Match frame label style | low |
| `lib/features/authentication/login/presentation/widgets/login_sign_in_button.dart` | Primary CTA | Match frame button (`AppButton`) | low |
| `lib/features/authentication/login/presentation/widgets/login_forgot_password_link.dart` | Forgot-password link → triggers inline recovery | Match frame link style; copy to `app_es.arb` if changed | low |
| `lib/features/authentication/login/presentation/widgets/login_divider.dart` | "o" divider | Match frame divider | low |
| `lib/features/authentication/login/presentation/widgets/login_social_row.dart` / `login_social_button.dart` | Google/Apple social buttons | Match frame social button style | low |
| `lib/features/authentication/login/presentation/widgets/login_register_link.dart` | "Crear cuenta" link | Match frame style | low |
| `lib/features/authentication/signup/presentation/signup_view.dart` | Signup screen | Match Pencil signup frame | med |
| `lib/features/authentication/signup/presentation/widgets/signup_terms_text.dart` | Terms checkbox/text | Match frame style | low |
| `lib/features/authentication/presentation/widgets/signup_header.dart` | Signup header | Match frame typography | low |
| `lib/features/authentication/presentation/widgets/signup_email_form.dart` / `login_email_form.dart` | Email form bodies | Match frame field layout | low |
| `lib/features/authentication/presentation/widgets/signup_social_buttons.dart` / `social_login_button.dart` | Social buttons | Match frame style | low |
| `lib/features/authentication/presentation/widgets/divider_with_text.dart` / `auth_text_with_link.dart` | Shared auth bits | Match frame style | low |

> **Note:** there is **no dedicated forgot-password page file.** `grep` confirms recovery lives inline in `login_view.dart` + `login_forgot_password_link.dart` + `auth_state.dart` (domain — off-limits). Frame `t7MYzR` must be implemented as an inline state/dialog of `LoginView`. Design must confirm whether the frame depicts a dialog or a full-screen state.

### Module B — home (`lib/features/home/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/home/presentation/home_page.dart` | Dashboard, iter-1 redesign from HTML mockup | Recompose to match frame `dyWWs` exactly | med |
| `lib/features/home/presentation/widgets/home_header.dart` | Greeting header | Match frame greeting/avatar layout | low |
| `lib/features/home/presentation/widgets/home_notification_button.dart` | Notification bell | Match frame icon button style | low |
| `lib/features/home/presentation/widgets/home_garage_section.dart` / `home_garage_card.dart` | Main-vehicle card | Match frame garage card layout/colors | med |
| `lib/features/home/presentation/widgets/home_empty_garage_card.dart` | Empty garage state | Match frame empty state | low |
| `lib/features/home/presentation/widgets/home_vehicle_info_row.dart` / `home_vehicle_placeholder_image.dart` | Vehicle row bits | Match frame | low |
| `lib/features/home/presentation/widgets/home_events_section.dart` | Upcoming-rides horizontal scroll | Match frame `dyWWs` events strip | med |
| `lib/features/home/presentation/widgets/home_event_card.dart` | Event card in carousel | Match frame card; consider reusing `AppEventBadge` | med |
| `lib/features/home/presentation/widgets/home_event_default_background.dart` / `home_event_gradient_overlay.dart` / `home_event_difficulty_badge.dart` / `home_event_view_details_button.dart` | Event card chrome | Match frame colors/badges | low |
| `lib/features/home/presentation/widgets/home_empty_events_card.dart` | Empty events state | Match frame | low |
| `lib/features/home/presentation/widgets/home_view_all_events_button.dart` / `home_submenu_option.dart` | CTAs / submenu | Match frame | low |

### Module C — events (`lib/features/events/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/events/presentation/list/events_page.dart` | Events list page (also serves "My Events" via `showMyEvents` flag) | Match frame `Neipf`; verify `XJtvl` "Mis Eventos" relationship (see §8) | med |
| `lib/features/events/presentation/list/widgets/events_page_view.dart` / `events_data_view.dart` / `events_state_widgets.dart` | List body, data/empty/loading | Match frame layout + states | med |
| `lib/features/events/presentation/list/widgets/event_card.dart` + `event_card_*.dart` (header, info panel, date/city, expand toggle, price badge/chip, type chip, my-event badge, meeting time) | Event card composite, iter-1 redesign | Match frame card exactly — colors, spacing, badge placement; reuse `AppEventBadge` | med |
| `lib/features/events/presentation/list/widgets/event_filter_chip.dart` / `event_type_chip.dart` / `event_type_filter_chips.dart` | Filter chips | Match frame chip style | low |
| `lib/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart` | Filter bottom sheet | Match frame bottom sheet | med |
| `lib/features/events/presentation/detail/event_detail_page.dart` / `event_detail_view.dart` / `event_detail_by_id_page.dart` | Event detail, iter-1 redesign | Match frame `kAubW` | med |
| `lib/features/events/presentation/detail/widgets/*` (header, header info, background image, overlay gradient, placeholder, body, chip, difficulty flames, destination card, meeting point section, organizer row, section title, info row, allowed brands section, started banner, owner lifecycle bar, cta bar) | Detail composite widgets | Match frame `kAubW`; **CTA bar all state variants** (register/pending/approved/cancelled) must render | med |
| `lib/features/events/presentation/detail/widgets/no_registration_content.dart` / `registration_status_content.dart` / `cancelled_registration_content.dart` | CTA state contents | Match frame per-state | med |
| `lib/features/events/presentation/form/event_form_page.dart` | Create/Edit event form | Match frames `PMuA4` + `zbCa0` (see §8 — likely two states of one page) | med |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` / `event_form_view.dart` / `event_form_section_card.dart` / `form_section_title.dart` | Form scaffolding | Match frame section cards/titles | med |
| `lib/features/events/presentation/form/widgets/sections/*` (basic info, date/time, details, difficulty, event type, locations, multi-brand) | Form section widgets | Match frame field layout/styling per section | med |
| `lib/features/events/presentation/shared/widgets/initials_avatar.dart` / `registration_status_chip.dart` | Shared event UI bits | Match frame style | low |
| `lib/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart` | Cancel dialog | Match frame dialog style if a frame exists | low |
| **Tracking** `lib/features/events/presentation/tracking/live_map_page.dart` | Live map page | UI chrome ONLY — see §3 Q1. Match `o1A6t4` overlays | med |
| `lib/features/events/presentation/tracking/widgets/sos_button.dart` | SOS button | Match frame `nxTub` styling; keep API | low |
| `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart` / `rider_telemetry_card.dart` / `rider_telemetry_riders_content.dart` / `telemetry_metric.dart` | Riders panel | Match frame `Gv2Rr`; keep BLoC read shape | med |
| `lib/features/events/presentation/tracking/widgets/map_zoom_controls.dart` / `zoom_button.dart` / `my_location_button.dart` | Map control chrome | Match `o1A6t4` controls | low |

**PROTECTED — Frontend MUST NOT touch:**
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` (the AI cover widget — `AIEventCoverWidget` equivalent; consumes `coverGenerationResult`/`EventCoverService` flow)
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart` (cubit — presentation but state-bearing; off-limits to avoid AI cover regression)
- `lib/features/events/presentation/form/widgets/event_form_content.dart` — **CAUTION:** this file *consumes* `CoverPreviewWidget` and the cover-generation callbacks. Touchable for surrounding layout/styling **only**; do **not** alter the `CoverPreviewWidget` instantiation, its props, or the generate/regenerate/upload callbacks.
- `lib/features/events/presentation/form/widgets/sections/event_form_locations_section.dart` — **CAUTION:** consumes `RouteMapPreview` (`route_map_preview.dart`). Touchable for surrounding styling **only**; do not alter the map preview widget or its props.
- `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`, `initials_marker_icon.dart` (map SDK wiring)
- `lib/features/events/presentation/tracking/cubit/*`, `live_tracking_session_holder.dart`, `tracking_location_settings.dart`
- `lib/features/events/presentation/attendees/**` — entire `attendees/` subtree (`attendees_page.dart` = `ManageAttendeesPage`, deferred since iter-2 Story 2.9). Do NOT redesign unless Design explicitly confirms a frame maps here AND the human approves.
- `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` (intentional placeholder — see §3 Q3)
- `route_map_preview.dart` itself (`lib/design_system/organisms/map/` + `lib/shared/widgets/map/`)
- All of `lib/features/events/domain/` and `lib/features/events/data/`

### Module D — garage / vehicles (`lib/features/vehicles/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/vehicles/presentation/garage/garage_page.dart` / `garage_page_view.dart` | Garage page (hosts list + embedded detail) | Match frame `KCf6W` | med |
| `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | Vehicle list content | Match frame list layout | med |
| `lib/features/vehicles/presentation/garage/widgets/garage_empty_state.dart` | Empty garage state | Match frame empty state | low |
| `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` | Vehicle options sheet | Match frame bottom sheet | low |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | **Vehicle detail (frame `P1GSzZ`)** — embedded in GaragePage | Match frame `P1GSzZ` | med |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_header.dart` | Detail header | Match frame | low |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_full_specs_section.dart` / `vehicle_quick_info_section.dart` / `vehicle_spec_row.dart` / `vehicle_info_card.dart` | Spec sections | Match frame spec layout | med |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_garage_overview_section.dart` / `vehicle_garage_overview_item.dart` | Overview grid | Match frame | low |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart` | Maintenance history block (uses `DocumentSlotPill`?) | Match frame; verify document slot states | med |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Add/Edit vehicle form | Match frame `EqnMm` | med |
| `lib/features/vehicles/presentation/widgets/vehicle_card.dart` / `vehicle_form.dart` / `vehicle_selector.dart` | Shared vehicle UI | Match frame style | low |

### Module E — maintenance (`lib/features/maintenance/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` | Filters bottom sheet | Match frame `v6RqaX` | med |
| `lib/features/maintenance/presentation/widgets/maintenance_filters.dart` / `filter_section_title.dart` | Filter content | Match frame | low |
| `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | Maintenance form (step 1) | Match frame `J5h6P` | med |
| `lib/features/maintenance/presentation/form/widgets/maintenance_form_content.dart` / `maintenance_form_view.dart` | Form scaffolding | Match frame layout | med |
| `lib/features/maintenance/presentation/form/widgets/selected_vehicle_card.dart` / `vehicle_list_item.dart` / `next_maintenance_mileage_field.dart` / `save_maintenance_button.dart` / `change_vehicle_mileage_bottom_sheet.dart` | Form widgets | Match frame styling | low |
| `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart` + `widgets/*` (list, summary card, data/empty/error/loading, header, app bar, summary header, vehicle selector chip) | Maintenance list/dashboard | Match frame(s) if Design maps unknown frames here; donut chart geometry **color-only** unless Design upgrades scope | med |
| `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` + `widgets/*` (alert card, detail header, detail row, info tile, options bottom sheet, section header) | Maintenance detail | Match frame if Design maps an unknown frame here | med |
| `lib/features/maintenance/presentation/widgets/item_card/*` (modern_maintenance_card, card body/content/header, actions menu, dates section, mileage info, notes section, progress bar, vehicle info chip, info_chip_tooltip, mileage_info_dialog) | Maintenance card composite | Match frame card styling | med |
| `lib/features/maintenance/presentation/widgets/expandable_fab.dart` / `fab_option.dart` | FAB | Match frame FAB if present | low |

### Module F — registration (`lib/features/event_registration/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/event_registration/presentation/registration_detail_page.dart` | Registration detail — **3 state variants** (`ELB5u` Programado, `eK2WW` Completado, `heldR` variante) | Match all three frames; single page, conditional rendering by state | med |
| `lib/features/event_registration/presentation/registration_detail_extra.dart` | Route param wrapper | Likely no change (not UI) — touch only if it carries a state enum needing render branch | low |
| `lib/features/event_registration/presentation/widgets/registration_detail_header.dart` / `registration_detail_section_card.dart` / `registration_detail_info_row.dart` / `registration_detail_emergency_card.dart` / `registration_detail_bottom_bar.dart` | Detail composite | Match frame per-variant | med |
| `lib/features/event_registration/presentation/my_registrations_page.dart` / `my_registrations_view.dart` / `my_registrations_data_view.dart` | "Mis Eventos" list (frame `XJtvl` — verify, see §8) | Match frame `XJtvl` | med |
| `lib/features/event_registration/presentation/widgets/inscription_card.dart` | Registration list card | Match frame card | med |
| `lib/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart` | Filter sheet | Match frame if present | low |
| `lib/features/event_registration/presentation/event_registration_page.dart` / `registration_form_content.dart` / `registration_form_view.dart` | Registration form flow | Match frame if Design maps one; else color/token swap | med |
| `lib/features/event_registration/presentation/widgets/registration_form_section_card.dart` / `expandable_container.dart` / `save_to_profile_checkbox.dart` | Form widgets | Match frame styling | low |

### Module G — profile / users (`lib/features/profile/`, `lib/features/users/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/features/profile/presentation/profile_page.dart` | Profile page | Match frame `A7qDd` | med |
| `lib/features/profile/presentation/widgets/profile_content.dart` | Profile body | Match frame layout | med |
| `lib/features/profile/presentation/widgets/profile_header.dart` | Profile header (avatar/name) | Match frame | low |
| `lib/features/profile/presentation/widgets/profile_main_vehicle_card.dart` | Main vehicle card | Match frame card | low |
| `lib/features/profile/presentation/widgets/profile_actions_list.dart` | Action list items | Match frame list rows; items must remain tappable | low |
| `lib/features/users/presentation/pages/rider_profile_page.dart` | Rider (other-user) profile | Match frame if Design maps an unknown frame here | med |
| `lib/features/users/presentation/widgets/rider_profile_content.dart` / `rider_profile_error.dart` / `rider_profile_loading.dart` | Rider profile states | Match frame; keep state structure | low |

### Design system updates (`lib/design_system/`, `lib/shared/widgets/`)

| File | Current state | Required change | Risk |
|------|---------------|-----------------|------|
| `lib/design_system/atoms/badges/app_event_badge.dart` | `AppEventBadge` atom, extracted iter-1 | Update if it diverges from frame `zKkmE`; else leave unchanged | low |
| `lib/design_system/molecules/feedback/document_slot_pill.dart` | `DocumentSlotPill` molecule, extracted iter-1 | Update if it diverges from frame `aGqnv`; else leave unchanged. Hardcoded Spanish fallbacks → move to `app_es.arb` only if frame reveals new copy (else leave) | low/med |
| `lib/shared/widgets/home_bottom_navigation_bar.dart` | Bottom nav pill bar | **Primary `VMmN0` target.** Restyle bar height/shadow/items; move hardcoded labels (`'Inicio'`/`'Garaje'`/`'Eventos'`/`'Perfil'`) to `app_es.arb` | med |
| `lib/shared/widgets/bottom_nav_item.dart` | Nav item atom | Restyle to match `VMmN0` item; keep API | low |
| `lib/shared/widgets/bottom_nav_add_button.dart` | Center add button | Restyle to match `VMmN0` add button; keep API | low |
| `lib/shared/widgets/main_shell.dart` | Shell scaffold | Layout chrome only; **do not** touch branch-index mapping | low |
| `lib/design_system/foundation/theme/app_colors.dart` | Color palette | Add new `AppColors` constant ONLY if a frame color has no existing mapping (per iter-1 3-tier policy). Log every addition in `analysis/` | low |
| `lib/design_system/atoms/buttons/*`, `chips/*`, `inputs/*`, `layout/*` | DS atoms | Touch ONLY if a frame reveals a primitive divergence used app-wide. Prefer per-screen styling first; escalate before changing a shared atom that affects unrelated screens | med |
| `lib/l10n/app_es.arb` | Spanish ARB | Add/change keys ONLY for copy that changes to match a frame. No hardcoded Spanish in widgets. Run `flutter gen-l10n` (or `build_runner`) after edits | low |

> **DS-change discipline:** This iter is a *screen sync*, not a DS overhaul. Prefer fixing the screen. Only edit a shared atom/molecule when (a) a frame component clearly maps to that primitive (`AppEventBadge`↔`zKkmE`, `DocumentSlotPill`↔`aGqnv`, bottom-nav↔`VMmN0`), or (b) Design's spec shows a primitive used identically across ≥3 screens diverges. Otherwise escalate.

---

## 5. Frame → file resolution status

**Confirmed (24):** all rows in PRD §4 with a concrete Flutter path. Architect note: `t7MYzR` (Forgot Password) is **inline in `login_view.dart`** — no dedicated page exists.

**Unresolved (16) — Design must map:** `YCuIq`, `pQCmS`, `UqpLS`, `UYeeY`, `o7KqgL`, `uVOQl`, `MrYmb`, `VrqVl`, `LDsMT`, `b5YFuy`, `DJOZ2`, `IUxas`, `f0lXw`, `qs5o1`, `Q44tYx`, `VKLP4`. Likely candidates (Architect estimate, Design to confirm): splash (`splash_screen.dart`), login/signup (`login_view.dart`/`signup_view.dart`), rider profile (`rider_profile_page.dart`), maintenance list/dashboard (`maintenances_page.dart`), maintenance detail (`maintenance_detail_page.dart`), maintenance form step 2, event registration form (`event_registration_page.dart`). Any frame Design cannot map to an existing file → mark "not implemented → OUT OF SCOPE for this sync" (do NOT build new screens).

---

## 6. Regression test surface

Existing tests (`flutter test`):

| Test file | Covers | Touched by this iter? | Action |
|-----------|--------|----------------------|--------|
| `test/features/events/presentation/list/widgets/events_page_view_test.dart` | `events_page_view.dart` (Module C) | **YES** — events list redesign | Keep green; update test in same module work if widget tree changes |
| `test/features/events/presentation/list/widgets/event_filters_bottom_sheet_test.dart` | `event_filters_bottom_sheet.dart` (Module C) | **YES** — filter sheet redesign | Keep green; update if structure changes |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | Events filter cubit (logic) | NO — cubit not touched | Must stay green (no UI dependency) |
| `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | `attendees/` subtree | **NO** — attendees is PROTECTED | Must stay green (untouched) |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` | AI cover use case (domain) | NO — domain off-limits | Must stay green |
| `test/features/profile/presentation/cubit/profile_cubit_test.dart` | Profile cubit (logic) | NO — cubit not touched | Must stay green |
| `test/features/users/domain/use_cases/get_user_by_id_use_case_test.dart` | Users domain | NO | Must stay green |
| `test/features/users/presentation/cubit/rider_profile_cubit_test.dart` | Rider profile cubit | NO — cubit not touched | Must stay green |
| `test/features/users/presentation/pages/rider_profile_page_test.dart` | `rider_profile_page.dart` (Module G) | **MAYBE** — if Design maps a frame here | Keep green; update if widget tree changes |
| `test/widget_test.dart` | App smoke test | Possibly (root render) | Keep green |

**Baseline:** PRD §6.3 states 4 pre-existing failures from stale `.g.dart` files are the *only* acceptable failures. QA must capture the baseline `flutter test` run **before** Frontend starts and confirm no *new* failures after.

**No new tests required** unless an existing test breaks due to a widget swap (then update in-place, same module work).

---

## 7. Implementation order for Frontend

Hard gate: **Design completes ALL Pencil frame reads + specs first.** Then Frontend proceeds module by module:

1. **Design system** — `AppEventBadge` (`zKkmE`), `DocumentSlotPill` (`aGqnv`), bottom-nav `VMmN0` (`home_bottom_navigation_bar.dart` + `bottom_nav_item.dart` + `bottom_nav_add_button.dart` + `main_shell.dart`). Do this first so downstream screens consume corrected primitives.
2. **Module A** — splash + auth (includes inline forgot-password `t7MYzR`).
3. **Module B** — home (`dyWWs`).
4. **Module C** — events (list `Neipf`, detail `kAubW`, form `PMuA4`/`zbCa0`, tracking chrome `o1A6t4`/`nxTub`/`Gv2Rr`). Run AI-cover + route-preview + live-map smoke tests after.
5. **Module D** — garage / vehicles (`KCf6W`, `P1GSzZ`, `EqnMm`).
6. **Module E** — maintenance (`v6RqaX`, `J5h6P`, + any unknown-frame maps).
7. **Module F** — registration (`ELB5u`/`eK2WW`/`heldR`, `XJtvl`).
8. **Module G** — profile / users (`A7qDd`, + any unknown-frame maps).

Run `dart analyze` after each module. Run `flutter test` after Module C (test-touching module) and at the end.

---

## 8. Open questions for Design (must answer in `analysis/`)

1. Map all 16 unknown frame IDs (§5) to a Flutter file or mark "not implemented → out of scope".
2. `PMuA4` (double-width 860px) vs `zbCa0` — two states of one `EventFormPage`, or two distinct screens? Architect expectation: two states of one page (only one `EventFormPage` + one `createEvent`/`editEvent` route pair exists). Confirm and document the state difference.
3. `t7MYzR` Forgot Password — Architect confirms **no dedicated page file**; recovery is inline in `login_view.dart`. Design must confirm whether the frame is a dialog or a full-screen state of `LoginView`.
4. `XJtvl` "Mis Eventos" — is it `my_registrations_page.dart`, or `events_page.dart` with `showMyEvents: true` (the `myEvents` route)? Both exist. Confirm which.
5. `ELB5u` / `eK2WW` / `heldR` — confirm all three map to `registration_detail_page.dart` and document which state field/enum controls the variant.
6. `Gv2Rr` Riders Panel — Architect confirms it maps to `rider_telemetry_panel.dart` (NOT `participants_placeholder_page.dart`, which stays a placeholder). Design to confirm frame content matches the telemetry panel.
7. Per frame: document hex colors, font family/size/weight per text role, padding/gap values, component + icon names, per-state variants.

## 9. Open questions for the Human

- None blocking. If Design finds an unknown frame that depicts a **new, unimplemented screen**, the human must decide whether it is in-scope (new build → outside this sync's mandate) or a design-only reference. Default per PRD §5: out of scope.
- If any tracking SOS/end-ride frame (`AETwc`, `tt64n`) implies *behaviour* beyond render-only styling, escalate before Frontend wires anything.

## 10. Risks

- **AI cover regression (`PMuA4`/`zbCa0`):** `event_form_content.dart` consumes `CoverPreviewWidget`. Frontend restyles surrounding layout only — never the cover widget, its props, or callbacks. QA smoke test: generate cover → select image → save event.
- **Route preview regression:** `event_form_locations_section.dart` consumes `RouteMapPreview`. Same rule — surrounding chrome only.
- **Live map regression:** `live_map_page.dart` UI chrome only; `live_map_widget.dart` off-limits. QA device smoke test: map renders, markers render, SOS button present.
- **Bottom-nav index mapping:** `main_shell.dart` has non-obvious branch↔bar index math. Restyle visuals only; never touch `_branchIndexToBarIndex` / `_addButtonBarIndex` / `goBranch`.
- **Shared DS atom blast radius:** editing `lib/design_system/atoms/*` affects unrelated screens. Prefer per-screen styling; escalate before broad atom changes.
- **Test churn:** only `events_page_view_test.dart`, `event_filters_bottom_sheet_test.dart`, possibly `rider_profile_page_test.dart` are at risk. Update in-place within the owning module's work.
- **Unknown frames → scope creep:** 16 unmapped frames. If any maps to a non-existent screen, it is OUT OF SCOPE — do not build new screens under a "sync" mandate.

## 11. Change log

- 2026-05-14 (custom-iter `pencil-screen-sync`): Architect phase complete. Confirmed presentation-layer-only constraint (extends iter-1). Produced full change map across modules A–G + design system (~150 touchable presentation files). Resolved PO open questions: tracking touch boundaries (chrome-only `live_map_page.dart`; SDK files off-limits), bottom-nav shell = `main_shell.dart` + `home_bottom_navigation_bar.dart` + `bottom_nav_item.dart` + `bottom_nav_add_button.dart`, `participants_placeholder_page.dart` stays a placeholder. Identified that `t7MYzR` Forgot Password has no dedicated page (inline in `login_view.dart`). Defined Design gate as hard-blocking, regression test surface (3 at-risk tests), and 8-step Frontend implementation order. No domain/data/DI/router changes. No protected files in change map.
