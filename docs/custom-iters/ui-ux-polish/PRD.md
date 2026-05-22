# § 1 Title

UI/UX Polish — Design System Consistency Pass (post ui-ux-pro-max review)

---

# § 2 Goal

Sync 7 Flutter widgets with the final Pencil design after a full ui-ux-pro-max design review of all 43 screens. All changes are purely visual — no new state, no new routes, no API changes. The review identified three categories of inconsistency: section headers using secondary-gray instead of primary-white, stat cells with white numbers instead of accent-orange + missing top-border treatment, and filter chips below the 40px touch-target minimum.

---

# § 3 Type and Severity

- **Type:** polish / design-sync
- **Severity:** low — zero logic or API changes; purely cosmetic; no regression risk beyond visual

---

# § 4 Pencil Frame References

| Frame ID | Screen | Relevant widget |
|---|---|---|
| `dyWWs` | Home Dashboard | `HomeEventsSection`, `HomeGarageSection`, `HomeNotificationButton`, `HomeViewAllEventsButton` |
| `A7qDd` | Profile | `ProfileStatsRow` |
| `DJOZ2` | Rider Profile | `_RiderStatsRow` in `rider_profile_content.dart` |
| `Neipf` | Events List | `EventFilterChip` |

---

# § 5 Changes Per File

## 5.1 `lib/features/home/presentation/widgets/home_events_section.dart`

**"PRÓXIMAS RODADAS" section header row** — currently uses gray secondary color and 13px. Design shows white primary.

```dart
// BEFORE
color: AppColors.textOnDarkSecondary,
fontSize: 13,

// AFTER
color: AppColors.textOnDarkPrimary,
fontSize: 14,
```

**Tune icon next to the header** — currently gray, should be orange accent.

```dart
// BEFORE
color: AppColors.textOnDarkSecondary,

// AFTER
color: AppColors.primary,
```

---

## 5.2 `lib/features/home/presentation/widgets/home_garage_section.dart`

**`_SectionHeader` title** — currently uses gray secondary at 11px. Design shows white primary at 12px.

```dart
// BEFORE
color: AppColors.textOnDarkSecondary,
fontSize: 11,

// AFTER
color: AppColors.textOnDarkPrimary,
fontSize: 12,
```

---

## 5.3 `lib/features/home/presentation/widgets/home_notification_button.dart`

**Icon circle background** — currently `AppColors.darkTertiary` (neutral dark). Design uses `AppColors.primarySubtle` (`0xFF2D2117`, the orange-tinted dark) to tie the notification button to the brand.

```dart
// BEFORE
color: AppColors.darkTertiary,

// AFTER
color: AppColors.primarySubtle,
```

---

## 5.4 `lib/features/home/presentation/widgets/home_view_all_events_button.dart`

**CTA "VER CATÁLOGO COMPLETO DE EVENTOS"** — text and chevron icon are currently gray secondary. Design shows white text + orange chevron.

```dart
// BEFORE (text)
color: AppColors.textOnDarkSecondary,

// AFTER (text)
color: AppColors.textOnDarkPrimary,
```

```dart
// BEFORE (icon)
color: AppColors.textOnDarkSecondary,

// AFTER (icon)
color: AppColors.primary,
```

---

## 5.5 `lib/features/profile/presentation/widgets/profile_stats_row.dart`

**`_StatCell` — three changes:**

**a) Stat value color** — currently white (`textOnDarkPrimary`). Design shows orange (`$accent`).

```dart
// BEFORE
color: AppColors.textOnDarkPrimary,

// AFTER
color: AppColors.primary,
```

**b) Label font size** — currently 11px (below minimum readability). Design shows 12px.

```dart
// BEFORE
fontSize: 11,

// AFTER
fontSize: 12,
```

**c) Top accent border** — currently no border. Design adds a 2px orange top border to each stat card for visual energy, matching the "vibrant block-based" style recommended by the design review.

```dart
// BEFORE
BoxDecoration(
  color: AppColors.darkCard,
  borderRadius: BorderRadius.circular(12),
)

// AFTER
BoxDecoration(
  color: AppColors.darkCard,
  borderRadius: BorderRadius.circular(12),
  border: const Border(
    top: BorderSide(color: AppColors.primary, width: 2),
  ),
)
```

---

## 5.6 `lib/features/users/presentation/widgets/rider_profile_content.dart`

**`_StatCell` — same three changes as §5.5** for visual consistency between own Profile and Rider Profile (other users' profile page).

```dart
// value color: AppColors.textOnDarkPrimary → AppColors.primary
// label fontSize: 11 → 12
// BoxDecoration: add Border(top: BorderSide(color: AppColors.primary, width: 2))
```

---

## 5.7 `lib/features/events/presentation/list/widgets/event_filter_chip.dart`

**Touch target** — current height is 34px, which is below the Apple HIG / Material minimum of 44px for interactive elements. The design review updated Pencil chips to 40px as a reasonable compromise for a horizontal filter bar.

```dart
// BEFORE
height: 34,
// ...
borderRadius: BorderRadius.circular(17),

// AFTER
height: 40,
// ...
borderRadius: BorderRadius.circular(20),
```

Update the doc comment to reflect the new values:
```dart
/// Matches Pencil design: h=40, radius=20, padding=[0,16]
```

---

# § 6 NOT in Scope

- `AppButton` global border radius — changing it would affect all buttons app-wide and needs a separate UX decision.
- Event Detail "Total participación" label — the CTA bar price label (11px) is inside `event_detail_page.dart`; given it sits at the bottom of a scroll view and is secondary metadata, this is deferred to avoid scope creep.
- Garaje V2 screen (`wmewU` Pencil frame) — work-in-progress, placeholder content; excluded.
- Any new widgets, new screens, or routing changes.
- `dart run build_runner` — no generated code changes; no need to re-run.

---

# § 7 Affected Flutter Files

| File | Change |
|---|---|
| `lib/features/home/presentation/widgets/home_events_section.dart` | Section header color + size; tune icon color |
| `lib/features/home/presentation/widgets/home_garage_section.dart` | `_SectionHeader` title color + size |
| `lib/features/home/presentation/widgets/home_notification_button.dart` | Background color |
| `lib/features/home/presentation/widgets/home_view_all_events_button.dart` | Text + icon colors |
| `lib/features/profile/presentation/widgets/profile_stats_row.dart` | Value color, label size, top border |
| `lib/features/users/presentation/widgets/rider_profile_content.dart` | `_StatCell` value color, label size, top border |
| `lib/features/events/presentation/list/widgets/event_filter_chip.dart` | Height 34→40, radius 17→20 |

**Zero files added. Zero files deleted.**

---

# § 8 Acceptance Criteria

1. Home Dashboard section headers ("PRÓXIMAS RODADAS", "MI GARAJE") render in white (`textOnDarkPrimary`) not gray.
2. The tune icon in `HomeEventsSection` and chevron in `HomeViewAllEventsButton` render in orange.
3. `HomeNotificationButton` has an orange-tinted dark circle background (`primarySubtle`).
4. Profile and Rider Profile stat cards show numbers in orange with a 2px orange top border.
5. Profile stat labels are 12px (readable on mobile at normal viewing distance).
6. `EventFilterChip` height is 40px — passes 44px touch target guidance with normal tap area padding.
7. `dart analyze` passes with 0 errors after all changes.
8. No widget tests broken (run `flutter test`).

---

# § 9 Regression Guardrails

| Area | Guardrail |
|---|---|
| Home screen | Events list, garage card, and navigation still render correctly |
| Profile | Stats counts and menu items still display correctly |
| Rider Profile | Follow button, stats, and events section still display correctly |
| Events list | Filter chips still toggle correctly; event cards unaffected |
| All screens | Dark theme colors consistent; no hardcoded color literals introduced |

---

# § 10 Open Questions

_(none — all decisions were resolved during the Pencil review session)_
