> Slim handoff for /custom-iter pencil-screen-sync. Full detail: docs/custom-iters/pencil-screen-sync/handoffs/architect.md

## Scope of change
Presentation-layer-only visual sync: ~150 widget/page files across `lib/features/*/presentation/`, `lib/design_system/`, `lib/shared/widgets/`, plus `lib/l10n/app_es.arb`. No `domain/`, `data/`, `core/di/`, no routes, no DTOs/services, no `build_runner`.

## Gate commands
- `dart analyze` — must pass with **0 errors and 0 warnings** after every module and at the end.
- `flutter test` — **no new failures.** Baseline: 4 pre-existing failures from stale `.g.dart` files are the ONLY acceptable failures. Capture the baseline run **before** Frontend starts; compare after.
- `dart format --output=none lib/` — should report no changes needed.

## Regression test surface (existing tests)
| Test | Status expectation |
|------|--------------------|
| `test/features/events/presentation/list/widgets/events_page_view_test.dart` | **At risk** (events list redesign) — must end green; Frontend updates in-place if widget tree changes |
| `test/features/events/presentation/list/widgets/event_filters_bottom_sheet_test.dart` | **At risk** (filter sheet redesign) — must end green |
| `test/features/users/presentation/pages/rider_profile_page_test.dart` | **Maybe at risk** (if Design maps a frame to rider profile) — must end green |
| `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | Must stay green (cubit untouched) |
| `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart` | Must stay green (attendees PROTECTED, untouched) |
| `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart` | Must stay green (domain untouched) |
| `test/features/profile/presentation/cubit/profile_cubit_test.dart` | Must stay green (cubit untouched) |
| `test/features/users/domain/use_cases/get_user_by_id_use_case_test.dart` | Must stay green |
| `test/features/users/presentation/cubit/rider_profile_cubit_test.dart` | Must stay green |
| `test/widget_test.dart` | Must stay green |

No new tests required unless an existing test breaks from a widget swap (Frontend updates in-place).

## Smoke tests (manual / device — required regression checks)
1. **AI cover generation** — open Create Event → generate cover → select image → save event. Must work (`cover_preview_widget.dart` + `event_form_cubit.dart` are PROTECTED, must be unchanged).
2. **Route map preview** — Create Event locations section renders `RouteMapPreview` without error.
3. **Live tracking map** — open a live event → `live_map_page.dart` renders, map + markers render, SOS button present and tappable, riders panel renders without crash.
4. **Bottom nav** — all 4 shell tabs navigable; center add button opens Create Event; selected state visually correct across tabs.
5. **Event detail CTA bar** — all state variants render: register / pending / approved / cancelled.
6. **Registration detail** — all 3 state variants render (Programado / Completado / variante) from `registration_detail_page.dart`.
7. **Vehicle detail** — `DocumentSlotPill` states render (empty / valid / expiringSoon / expired).
8. **Event badge** — all `AppEventBadge` variants render in event cards.
9. **Garage / My Registrations / Profile** — empty and data states both render.

## Acceptance criteria traceability (PRD §6)
- AC1 — every confirmed Pencil frame renders hex-exact (colors, typography, layout, spacing) → visual review against Design's `analysis/` specs.
- AC2 — `dart analyze`: 0 errors, 0 warnings.
- AC3 — `flutter test`: no new failures (4 `.g.dart` baseline failures only).
- AC4 — no `domain/`, `data/`, `core/di/` files modified → verify via `git diff --stat` (no paths under those dirs).
- AC5 — `EventCoverService`, `AIEventCoverWidget`/`cover_preview_widget.dart`, `route_map_preview.dart`, `live_map_widget.dart`, `live_map_page.dart` functionally unchanged → smoke tests 1–3 + diff check (`live_map_page.dart` may have chrome-only diffs; the other four must be 0-diff).
- AC6 — `AppEventBadge` / `DocumentSlotPill` updated only if they diverge from `zKkmE` / `aGqnv`.
- AC7 — all new/changed strings in `app_es.arb`; grep widgets for hardcoded Spanish literals.
- AC8 — bottom nav matches `VMmN0` across all shell screens.
- AC9 — all 16 unknown frames resolved by Design (mapped or marked out-of-scope).

## Protected — must show ZERO diff (except `live_map_page.dart` chrome-only)
`cover_preview_widget.dart`, `event_form_cubit.dart`, `live_map_widget.dart`, `initials_marker_icon.dart`, `tracking/cubit/*`, `live_tracking_session_holder.dart`, `tracking_location_settings.dart`, `participants_placeholder_page.dart`, `attendees/**`, `route_map_preview.dart`, all `domain/` + `data/`.
