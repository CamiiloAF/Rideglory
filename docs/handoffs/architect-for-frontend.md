> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Frontend (Flutter) — Iteration 1

**Iter-1 = presentation layer ONLY.** No domain/data/DI/router/build_runner work. If a story tempts you toward `lib/features/<feature>/{domain,data}/` or `lib/core/di/` — stop and re-read the story.

## Branch & PR cadence

- Work on branch `iter-1` (already checked out).
- 5 module-scoped PRs (≤ 40 files each), merged in order: `splash+auth` → `home` → `events` → `garage` → `maintenance+registration`.
- Each PR: `dart analyze` + `flutter test` green before merge.

## Feature → file scope per PR

| PR | Stories | Files in scope |
|----|---------|----------------|
| 1 splash+auth | US-1-2, US-1-3 | `lib/features/splash/presentation/**`, `lib/features/authentication/presentation/**` |
| 2 home | US-1-4 | `lib/features/home/presentation/**`, `lib/shared/widgets/home_bottom_navigation_bar.dart`, `bottom_nav_*.dart`, `main_shell.dart` (only color tokens, no nav refactor) |
| 3 events | US-1-5, US-1-6 | `lib/features/events/presentation/**` (excluding `live_tracking/`, `tracking/` — out of scope), `lib/design_system/atoms/badges/app_event_badge.dart` (NEW), barrel update, 3 widget tests |
| 4 garage | US-1-7, US-1-8 | `lib/features/vehicles/presentation/**`, `lib/design_system/molecules/feedback/document_slot_pill.dart` (NEW), barrel update |
| 5 maintenance+registration | US-1-9, US-1-10 | `lib/features/maintenance/presentation/**`, `lib/features/event_registration/presentation/**` (EXCLUDE `manage_*` — deferred to iter-2 Story 2.9) |

## NEW design-system primitives (build BEFORE the consuming PR)

### `AppEventBadge` — atom (PR 3 pre-condition)
- Path: `lib/design_system/atoms/badges/app_event_badge.dart`
- Source frame: `zKkmE`
- API: `const AppEventBadge({required EventBadgeVariant variant, required String label})` — variant is an enum (e.g., `scheduled`, `inProgress`, `finished`, `cancelled`, `free`, `paid`); label comes from caller (`context.l10n.event_badge_<state>`).
- Colors: `colorScheme.primary` for default; `AppColors.success/warning/error` for status; `AppColors.eventFree/eventPaid` for price variants.
- Add export to `lib/design_system/atoms/atoms.dart`.

### `DocumentSlotPill` — molecule (PR 4 pre-condition)
- Path: `lib/design_system/molecules/feedback/document_slot_pill.dart`
- Source frame: `aGqnv`
- API: `const DocumentSlotPill({required String label, required DocumentSlotState state, VoidCallback? onTap, IconData? leading})` — state enum: `empty`, `valid`, `expiringSoon`, `expired` (state mapping is iter-2 SOAT concern; iter-1 ships the visual primitive only).
- Colors: `AppColors.darkSurfaceHighest` background; `AppColors.success`, `warning`, `error` accents per state; `AppColors.darkBorder` divider.
- Add export to `lib/design_system/molecules/molecules.dart`.
- **Reuse contract**: iter-2 SOAT badge story (2.3) will consume this same molecule; do not couple it to vehicle-feature types.

## Color tokenization (mandatory across all 5 PRs)

Replace, in priority order:
1. **`Theme.of(context).colorScheme.<role>`** when the color has semantic role.
2. **`AppColors.<constant>`** for dark surfaces/borders/text/status not in `colorScheme`.
3. **Add to `AppColors`** (do not inline `Color(0xFF…)`) if no mapping exists. Append to architect handoff change log in same PR.

Forbidden in `lib/features/`: `Color(0xFF…)` literals; `Colors.<named>` except `Colors.transparent`, `Colors.black`, `Colors.white`.

Per-PR procedure: `grep -rE "Color\(0x|Colors\." <module-path>` → map → batch substitute → `dart analyze`.

## Widget swap (only ~3 files affected)

Per existing-system scan: only `mileage_info_dialog.dart` and `event_form_multi_brand_section.dart` use raw widgets. Replace per US-1-3/1-6 acceptance:
- `ElevatedButton` → `AppButton` (atoms)
- `TextFormField` → `AppTextField` (atoms)
- `TextField` for password → `AppPasswordTextField` (atoms)
- `AlertDialog` → `AppDialog` (molecules)

## Localization (l10n)

- File: `lib/l10n/app_es.arb`. Run `flutter gen-l10n` after edits and commit generated `lib/l10n/app_localizations*.dart`.
- Key naming: feature prefix.
  - **NEW** keys for `AppEventBadge` labels: `event_badge_scheduled`, `event_badge_inProgress`, `event_badge_finished`, `event_badge_cancelled`, `event_badge_free`, `event_badge_paid` (US-1-5).
  - **NEW** keys for `DocumentSlotPill` labels (used in vehicle pages, not the molecule itself): `vehicle_doc_soat_label`, `vehicle_doc_techreview_label`, `vehicle_doc_state_empty`, `vehicle_doc_state_valid`, `vehicle_doc_state_expiringSoon`, `vehicle_doc_state_expired` (US-1-7, US-1-8). State labels are stubs in iter-1; iter-2 SOAT story will reuse them.
  - Reuse existing keys whenever possible. Do not create duplicate keys.

## Cubit / state — read carefully

You are **not** allowed to:
- Create new cubits.
- Add new states or methods to existing cubits.
- Change the `Cubit<ResultState<T>>` signature of any cubit.
- Inject new services into existing cubits.

You **are** allowed to:
- Restructure widget trees in `presentation/` to match Pencil frames.
- Replace inline color/spacing literals with theme tokens.
- Extract or rename private widgets within a feature for clarity (one widget per file).
- Update `BlocBuilder<CubitX, ResultState<Y>>.builder` to render new visuals — without changing the cubit.

If you find yourself wanting to refactor a cubit signature, the story is mis-scoped. Stop and escalate.

## Tests

- Update finders in 3 events widget tests (`attendees_list_navigation_test.dart`, `event_filters_bottom_sheet_test.dart`, `events_page_view_test.dart`) **in PR 3**, the same PR that swaps their target widgets. No test-rot merges.
- Do not write new widget tests this iter (QA owns that).

## Out of scope (do not touch)

- `live_tracking/`, `tracking/`, `users/` (rider profile), `profile/` features — no PO story.
- `manage_attendees_page.dart` — deferred to iter-2.
- `EventFormCubit`, `EventCoverService`, AI cover bottom sheet — preserve exact behavior; styling chrome around them is fine.
- `route_map_preview.dart` — leave widget body untouched.

> Full detail: docs/handoffs/architect.md
