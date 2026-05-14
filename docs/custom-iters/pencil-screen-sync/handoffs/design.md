# Design Handoff — pencil-screen-sync

**Date:** 2026-05-14  
**Agent:** Design  
**Status:** done  
**Tool:** Pencil MCP — `mcp__pencil__open_document` + `mcp__pencil__get_screenshot` + `mcp__pencil__batch_get` + `mcp__pencil__get_variables`

---

## Touched Screens

All 40 top-level frames in `rideglory.pen` were screenshotted and analyzed. The table below shows all confirmed in-scope frames that Frontend must implement:

| Frame ID | Screen Name | Flutter File | Module | Action |
|----------|------------|--------------|--------|--------|
| `VMmN0` | Component/Tab Bar | `lib/shared/widgets/home_bottom_navigation_bar.dart` + `bottom_nav_item.dart` + `bottom_nav_add_button.dart` | DS | Update to match |
| `zKkmE` | Component/Event Badge | `lib/design_system/atoms/badges/app_event_badge.dart` | DS | Confirm or update |
| `aGqnv` | Document Slot Pill | `lib/design_system/molecules/feedback/document_slot_pill.dart` | DS | Update to match |
| `VrqVl` | Splash | `lib/features/splash/presentation/splash_screen.dart` + widgets | A | Update |
| `uVOQl` | Login | `lib/features/authentication/login/presentation/login_view.dart` + widgets | A | Update |
| `MrYmb` | Register | `lib/features/authentication/signup/presentation/signup_view.dart` + widgets | A | Update |
| `t7MYzR` | Forgot Password | Auth feature — needs dedicated view (see §Answers Q3) | A | Update / create |
| `UYeeY` | Email Sent | Auth feature — follow-on to forgot password | A | Update / create |
| `dyWWs` | Home Dashboard | `lib/features/home/presentation/home_page.dart` + widgets | B | Update |
| `Neipf` | Events List | `lib/features/events/presentation/list/events_page.dart` + widgets | C | Update |
| `kAubW` | Event Detail | `lib/features/events/presentation/detail/event_detail_page.dart` + widgets | C | Update |
| `PMuA4` | CTA State Variants (ref sheet) | `event_detail_cta_bar.dart` — reference only | C | Use as reference |
| `zbCa0` | Create/Edit Event Form | `lib/features/events/presentation/form/event_form_page.dart` + widgets | C | Update |
| `nxTub` | Event Tracking SOS Alert | `live_map_page.dart` chrome + `sos_button.dart` | C | Update chrome |
| `AETwc` | SOS Confirmation Dialog | `live_map_page.dart` dialog | C | Update/create dialog |
| `tt64n` | End Ride Confirmation Dialog | `live_map_page.dart` dialog | C | Update/create dialog |
| `o1A6t4` | Event Tracking Map | `live_map_page.dart` chrome + control widgets | C | Update chrome |
| `Gv2Rr` | Event Tracking Riders Panel | `rider_telemetry_panel.dart` + related | C | Update |
| `XJtvl` | Mis Eventos | `lib/features/event_registration/presentation/my_registrations_page.dart` + views | F | Update |
| `pQCmS` | Registration Form V2 | `lib/features/event_registration/presentation/event_registration_page.dart` + widgets | F | Update |
| `f0lXw` | Mi Inscripción | `lib/features/event_registration/presentation/registration_detail_page.dart` | F | Update |
| `KCf6W` | Garage / Vehicle List | `lib/features/vehicles/presentation/garage/garage_page.dart` + widgets | D | Update |
| `P1GSzZ` | Vehicle Detail | `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | D | Update |
| `EqnMm` | Add/Edit Vehicle Form | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | D | Update |
| `YCuIq` | Vehicle Selector Bottom Sheet | `lib/shared/widgets/vehicle_selection_bottom_sheet.dart` | D | Update |
| `v6RqaX` | Maintenance Filters Sheet | `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart` | E | Update |
| `J5h6P` | Maintenance Form Step 1 | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | E | Update |
| `ELB5u` | Maintenance Form Step 2 (Programado) | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | E | Update |
| `eK2WW` | Maintenance Form Step 2 (Completado) | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | E | Update |
| `heldR` | Maintenance Form Step 2 (Programado variant) | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` | E | Update |
| `o7KqgL` | Maintenance List/Dashboard | `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart` | E | Update |
| `VKLP4` | Maintenance Detail | `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` | E | Update |
| `A7qDd` | Profile | `lib/features/profile/presentation/profile_page.dart` + widgets | G | Update |
| `DJOZ2` | Rider Profile | `lib/features/users/presentation/pages/rider_profile_page.dart` + widgets | G | Update |

**Out of scope (not yet implemented / deferred):**
- `LDsMT` — Notifications Center: not implemented
- `b5YFuy` — Edit Profile: not implemented  
- `IUxas` — Gestionar Inscritos: `attendees_page.dart` deferred (iter-2 Story 2.9)
- `UqpLS` — Event Registrations (organizer view): deferred
- `qs5o1` — SOAT upload: future iteration
- `Q44tYx` — SOAT confirmation: future iteration

---

## Architect Open Questions — Answers

### 1. Unknown frames resolved (16/16)

| Frame | Resolved As | Scope |
|-------|-------------|-------|
| `YCuIq` | Vehicle Selector Bottom Sheet (`vehicle_selection_bottom_sheet.dart`) | in_scope |
| `pQCmS` | Event Registration Form (`event_registration_page.dart`) | in_scope |
| `UqpLS` | Event Registrations list (organizer) — `attendees_page.dart` | **out_of_scope** (deferred) |
| `UYeeY` | Email Sent (password reset step 2) | in_scope |
| `o7KqgL` | Maintenance List/Dashboard (`maintenances_page.dart`) | in_scope |
| `uVOQl` | Login (`login_view.dart`) | in_scope |
| `MrYmb` | Register/Signup (`signup_view.dart`) | in_scope |
| `VrqVl` | Splash (`splash_screen.dart`) | in_scope |
| `LDsMT` | Notifications Center | **out_of_scope** (not implemented) |
| `b5YFuy` | Edit Profile | **out_of_scope** (not implemented) |
| `DJOZ2` | Rider Profile (`rider_profile_page.dart`) | in_scope |
| `IUxas` | Manage Attendees | **out_of_scope** (deferred) |
| `f0lXw` | My Registration Detail (`registration_detail_page.dart`) | in_scope |
| `qs5o1` | SOAT upload flow | **out_of_scope** |
| `Q44tYx` | SOAT confirmation | **out_of_scope** |
| `VKLP4` | Maintenance Detail (`maintenance_detail_page.dart`) | in_scope |

### 2. PMuA4 vs zbCa0

**`PMuA4` is NOT a screen and NOT part of `event_form_page.dart`.** It is an 860px-wide **design reference sheet** documenting all EventDetail CTA bar state variants (8 states). The frame name "CTA Action States — Bottom bar variations per registration status" makes this explicit.

**`zbCa0`** (390px, "Crear Evento") is the **one and only Create/Edit Event Form** screen. Frontend implements one `EventFormPage` from `zbCa0`. The CTA bar states from `PMuA4` are implemented in `event_detail_cta_bar.dart`.

### 3. t7MYzR Forgot Password

**`t7MYzR` is a full-page screen** — NOT a dialog and NOT an inline state of `LoginView`. It has a complete layout: status bar, RIDEGLORY logo, heading, body text, email field, CTA button, and a "remember it? sign in" link. It is 390×844 (standard mobile page height).

**Issue:** Architect confirmed no dedicated page file exists. The Pencil frame proves a dedicated screen is needed. Two options:
1. Create `forgot_password_view.dart` as a new file + route in auth — **requires human approval** (new route = normally out of scope)
2. Implement as an `AnimatedSwitcher`/`PageController` state within `login_view.dart` that replaces the form content — no new route needed, safe option

**Design recommendation:** Option 2 (inline state switch in `login_view.dart`) to stay within scope. The `UYeeY` "Email Sent" screen would be a second inline state in the same flow.

### 4. XJtvl "Mis Eventos"

**`XJtvl` is `my_registrations_page.dart`** — it shows events the **current user has registered for as an attendee** (not events they created). The frame shows filter chips "Todos / Próximos / Pasados" and event cards with status badges. This is NOT `events_page.dart` with `showMyEvents: true`.

### 5. ELB5u / eK2WW / heldR

**CRITICAL CORRECTION from PRD/Architect mapping:**

These three frames are **NOT** `registration_detail_page.dart`. The Pencil frame names ("Registrar — Paso 2 Formulario") are misleading. The **screenshots clearly show** "Nuevo Mantenimiento / Paso 2 de 2" with Completado/Programado tabs. These are **Maintenance Form Step 2** variants in `maintenance_form_page.dart`.

Correct mapping:
- `eK2WW` → Maintenance Form Step 2, **Completado** tab (recording past service: date, km, taller, cost, notes)
- `ELB5u` → Maintenance Form Step 2, **Programado** tab (scheduling: notes + next km/date)
- `heldR` → Maintenance Form Step 2, **Programado variant** (fewer fields — initial state)

The state controller is a **tab chip row** ("Completado" | "Programado") in `grpEstado` section — maps to `MaintenanceStatus` enum.

The **actual** registration detail for attendees is `f0lXw` ("Mi Inscripción").

### 6. Gv2Rr Riders Panel

**Confirmed:** `Gv2Rr` maps to `rider_telemetry_panel.dart` (NOT `participants_placeholder_page.dart`). The frame shows a full participants list with search, filter chips, rider cards, and SOS alert card. This is a complete, implemented screen — NOT a placeholder.

The tab bar in this view is a CUSTOM VMmN0 instance with "RIDERS" and "MAP" tabs instead of the standard 4-tab navigation. This is specific to the tracking context.

### 7. Per-frame design tokens

See individual spec files in `analysis/screens/`:
- `dyWWs.md`, `Neipf.md`, `kAubW.md`, `PMuA4.md`, `zbCa0.md`
- `KCf6W.md`, `P1GSzZ.md`, `EqnMm.md`, `YCuIq.md`
- `aGqnv.md`, `VMmN0.md`, `zKkmE.md`
- `v6RqaX.md`, `J5h6P.md`, `ELB5u_eK2WW_heldR.md`
- `nxTub_AETwc_tt64n.md`, `o1A6t4.md`, `Gv2Rr.md`
- `XJtvl.md`, `t7MYzR_UYeeY.md`, `A7qDd.md`
- `uVOQl_MrYmb_VrqVl.md`, `DJOZ2.md`, `o7KqgL.md`, `VKLP4.md`
- `pQCmS_f0lXw.md`

---

## Design System Tokens in Use

### Color Variables (from `get_variables`)
| Variable | Hex | AppColors mapping |
|----------|-----|-------------------|
| `$bg-primary` | #0D0D0F | `AppColors.darkBackground` |
| `$bg-secondary` | #1A1A1F | `AppColors.darkSurface` (or similar) |
| `$bg-card` | #1E1E24 | `AppColors.darkCard` |
| `$bg-tertiary` | #242429 | `AppColors.darkTertiary` |
| `$accent` | #F98C1F | `AppColors.primary` |
| `$accent-light` | #FFAB4F | `AppColors.primaryLight` |
| `$accent-subtle` | #2D2117 | `AppColors.primarySubtle` |
| `$border` | #2A2A32 | `AppColors.darkBorder` |
| `$border-light` | #3A3A44 | `AppColors.darkBorderLight` |
| `$text-primary` | #FFFFFF | `AppColors.textPrimary` |
| `$text-secondary` | #9CA3AF | `AppColors.textSecondary` |
| `$text-tertiary` | #6B7280 | `AppColors.textTertiary` |
| `$text-inverse` | #0D0D0F | `AppColors.textInverse` |
| `$tab-bar-bg` | #15151A | `AppColors.tabBarBackground` |
| `$tab-inactive` | #6B7280 | `AppColors.tabInactive` |
| `$error` | #EF4444 | `AppColors.error` |
| `$success` | #22C55E | `AppColors.success` |
| `$warning` | #EAB308 | `AppColors.warning` |
| `$info` | #3B82F6 | `AppColors.info` |

### Spacing Variables
| Variable | Value | Use |
|----------|-------|-----|
| `$spacing-xs` | 4px | tiny gaps |
| `$spacing-sm` | 8px | small gaps |
| `$spacing-md` | 16px | standard gaps |
| `$spacing-lg` | 24px | section gaps |
| `$spacing-xl` | 32px | large gaps |

### Border Radius Variables
| Variable | Value |
|----------|-------|
| `$radius-sm` | 8px |
| `$radius-md` | 12px |
| `$radius-lg` | 16px |
| `$radius-xl` | 24px |

### Typography
- Primary font: **Space Grotesk** (`$font-primary`)
- System font: **SF Pro** (`$font-system`) — for status bar time display only

---

## New AppColors Constants Needed

The following colors appear in frames but have no current AppColors mapping:

| Constant Name | Hex | Used In |
|---------------|-----|---------|
| `AppColors.successSubtle` | `#162A1F` | Document slot (Vigente badge bg), maintenance detail (Realizado badge bg) |
| `AppColors.warningSubtle` | `#2A2200` | Document slot (Por vencer badge bg) |
| `AppColors.errorSubtle` | `#2D1010` | Document slot (Vencido badge bg) |
| `AppColors.infoSubtle` | `#1B2E4A` | Document slot (SOAT icon bg, info-type spec icons) |
| `AppColors.riderCardBg` | `#161616` | Tracking rider telemetry card background |
| `AppColors.trackingMapBg` | `#0C1018` | Tracking map dark background |

> If existing `AppColors` already has these mapped under different names, use those. Only add if no mapping exists.

---

## Components

### Reused (existing — confirm match)
- `AppButton` — used in all CTA bars
- `AppTextField` — used in all forms
- `AppEventBadge` (`zKkmE`) — used on event cards, list items
- `DocumentSlotPill` (`aGqnv`) — used in Vehicle Detail
- `HomeBottomNavigationBar` (`VMmN0`) — used in all shell screens
- `ConfirmationDialog` / `AppDialog` — used for SOS, End Ride, Cancel dialogs
- `VehicleSelectionBottomSheet` — used in maintenance form

### Updated (match Pencil frame spec)
- `home_bottom_navigation_bar.dart` — pill shape, cornerRadius 36, tab item cornerRadius 26, labels ALL CAPS 10px 600 letter-spacing 0.5
- `document_slot_pill.dart` — header with count badge, 3 doc slots with status badges, info row at bottom
- `app_event_badge.dart` — pill shape (cornerRadius 20), padding [5, 12], text 11 700 white — confirm this matches

### New (Design recommends creating)
- None required for confirmed in-scope frames. All frames use existing component patterns.
- Note: `t7MYzR` / `UYeeY` may require new inline state handling in `login_view.dart` (not new widget files, but new state logic)

---

## Tool Used
Pencil MCP — `mcp__pencil__open_document` + `mcp__pencil__get_screenshot` + `mcp__pencil__batch_get` + `mcp__pencil__get_variables` + `mcp__pencil__snapshot_layout`

- Screenshots saved to: `docs/custom-iters/pencil-screen-sync/analysis/screenshots/`
- Per-screen specs: `docs/custom-iters/pencil-screen-sync/analysis/screens/`

---

## Critical Notes for Frontend

1. **ELB5u / eK2WW / heldR are MAINTENANCE, not registration.** The architect's change map was based on frame names, which are incorrect. The screenshots prove these are `maintenance_form_page.dart` Step 2 variants. Do NOT implement these as `registration_detail_page.dart`.

2. **f0lXw is the actual registration detail.** `registration_detail_page.dart` maps to `f0lXw` ("Mi Inscripción"), not to `ELB5u`/`eK2WW`/`heldR`.

3. **PMuA4 is a design reference sheet, not a screen.** Do not create a page for it. Use it to implement the 8 CTA bar states in `event_detail_cta_bar.dart`.

4. **t7MYzR requires a decision.** Forgot Password is a full-page screen. Recommend implementing as inline state in `login_view.dart` to avoid new route (escalate to human if new route required).

5. **Tab bar pill cornerRadius is 36**, not 24. Tab item cornerRadius is 26. These are non-standard values — use exact numbers.

6. **Form field cornerRadius is 12** (`$radius-md`), not 8 (`$radius-sm`). This applies to all form screens.

7. **"Finalizar rodada" dialog button (tt64n) and "Enviar SOS" button (AETwc) use `$error` (#EF4444)**, not accent. These dialogs are render-only per Architect — wire with existing button callbacks, no new business logic.

8. **New AppColors constants** (`successSubtle`, `warningSubtle`, `errorSubtle`, `infoSubtle`) are needed for the Document Slot Pill to be fully spec-compliant.

9. **Splash background is flat `#0D0D0F`** — no glow, no gradient. If `splash_glow_background.dart` exists from iter-1, it should be removed or replaced with a flat background.

10. **Maintenance list items use a colored left-border (3px)** indicating urgency status — this requires a `BoxDecoration` with `border: Border(left: BorderSide(...))`.
