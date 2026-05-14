> Slim handoff for /custom-iter pencil-screen-sync. Full detail: docs/custom-iters/pencil-screen-sync/handoffs/architect.md

## Hard rules
- **PRESENTATION-LAYER ONLY.** No `domain/`, `data/`, `core/di/`, no routes, no DTOs/services/use cases, no `build_runner` (no generated code touched).
- Touchable: `lib/features/*/presentation/pages|widgets|*_page.dart|*_view.dart`, `lib/design_system/`, `lib/shared/widgets/`, `lib/l10n/app_es.arb` (copy only).
- If a visual change needs a domain/data/DI/router change → **STOP, escalate to human.** Story is mis-scoped.
- No hardcoded Spanish strings — all user-visible text in `app_es.arb`, used via `context.l10n.<key>`.
- Color policy (iter-1, still in force): prefer `Theme.of(context).colorScheme.*` → then `AppColors` constants → then status palette. New `AppColors` constant only if a frame color has no mapping; log every addition.
- `dart analyze` after every module. `flutter test` after Module C and at the end.

## Hard gate — do NOT start until Design is done
Frontend cannot write a line until `docs/custom-iters/pencil-screen-sync/analysis/` has:
- `pencil-frame-map.md` (all ~40 frames screenshotted + mapped, 16 unknowns resolved)
- per-screen spec docs (hex colors, fonts, spacing, components, icons, states)

## PROTECTED — never touch
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` (AI cover widget)
- `lib/features/events/presentation/form/cubit/event_form_cubit.dart`
- `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`, `initials_marker_icon.dart`
- `lib/features/events/presentation/tracking/cubit/*`, `live_tracking_session_holder.dart`, `tracking_location_settings.dart`
- `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` (stays a placeholder)
- `lib/features/events/presentation/attendees/**` (ManageAttendeesPage — deferred since iter-2)
- `route_map_preview.dart` (both `design_system/organisms/map/` and `shared/widgets/map/`)
- Anything in `lib/features/*/domain/` or `lib/features/*/data/`

**CAUTION (touch surrounding chrome only, never the embedded widget/props/callbacks):**
- `event_form_content.dart` — consumes `CoverPreviewWidget`
- `event_form_locations_section.dart` — consumes `RouteMapPreview`
- `live_map_page.dart` — UI chrome only; do NOT touch `initState`/`dispose`/permission/camera/cubit wiring
- `main_shell.dart` — do NOT touch `_branchIndexToBarIndex` / `_addButtonBarIndex` / `goBranch`

## Implementation order (module by module, after Design gate)
1. **Design system** — `AppEventBadge` (`zKkmE`), `DocumentSlotPill` (`aGqnv`), bottom-nav `VMmN0`:
   `lib/shared/widgets/home_bottom_navigation_bar.dart` (primary), `bottom_nav_item.dart`, `bottom_nav_add_button.dart`, `main_shell.dart` (layout chrome only). Edit the `shared/widgets/` files — the `design_system/organisms/navigation/` versions are just re-export shims. Move hardcoded nav labels (`'Inicio'/'Garaje'/'Eventos'/'Perfil'`) to `app_es.arb`.
2. **Module A — splash + auth:** `splash_screen.dart` + `splash/widgets/*`, `login_view.dart` + `login/widgets/*`, `signup_view.dart` + `signup/widgets/*`, `authentication/presentation/widgets/*`. Note: forgot-password (`t7MYzR`) is **inline in `login_view.dart`** — no dedicated page.
3. **Module B — home (`dyWWs`):** `home_page.dart` + all `home/presentation/widgets/*`.
4. **Module C — events:** list (`events_page.dart`, `list/widgets/*` incl. `event_card*`, filter chips, `event_filters_bottom_sheet.dart`), detail (`event_detail_page.dart`/`_view`/`_by_id`, `detail/widgets/*` incl. CTA bar all variants), form (`event_form_page.dart`, `form/widgets/*` + `sections/*` — respect cover/route CAUTION), tracking chrome (`live_map_page.dart` chrome, `sos_button.dart`, `rider_telemetry_panel.dart` + cards, zoom/location controls). Run AI-cover + route-preview + live-map smoke tests after.
5. **Module D — garage/vehicles:** `garage_page.dart`/`_view`, `garage/widgets/*` (incl. `vehicle_detail_view.dart` = frame `P1GSzZ`), `vehicle_form_page.dart`, `vehicles/presentation/widgets/*`.
6. **Module E — maintenance:** `maintenance_filters_bottom_sheet.dart` (`v6RqaX`), `maintenance_form_page.dart` + `form/widgets/*` (`J5h6P`), list/detail/`item_card/*` per Design's unknown-frame maps. Donut chart = color-only unless Design upgrades scope.
7. **Module F — registration:** `registration_detail_page.dart` (3 state variants `ELB5u`/`eK2WW`/`heldR`, conditional render in one file), `registration_detail` widgets, `my_registrations_page.dart`/`_view`/`_data_view` (`XJtvl`), `inscription_card.dart`, form widgets.
8. **Module G — profile/users:** `profile_page.dart` + `profile/presentation/widgets/*` (`A7qDd`), `rider_profile_page.dart` + `users/presentation/widgets/*` per Design maps.

## Notes
- `events_page.dart` serves both Events List and "My Events" (`showMyEvents` flag) — confirm with Design whether `XJtvl` is this or `my_registrations_page.dart`.
- `PMuA4` + `zbCa0` are expected to be two states of one `EventFormPage` — confirm with Design's spec.
- Update only these tests in-place if their widget trees change: `events_page_view_test.dart`, `event_filters_bottom_sheet_test.dart`, `rider_profile_page_test.dart` (Module G if touched). No new tests.
- Prefer per-screen styling over editing shared DS atoms (`design_system/atoms/*`) — those have app-wide blast radius. Escalate before broad atom changes.
- Acceptance: every confirmed frame renders hex-exact; `dart analyze` 0 errors/0 warnings; `flutter test` no new failures (4 pre-existing `.g.dart` failures are the baseline).
