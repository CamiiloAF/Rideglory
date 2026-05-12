# Design Handoff — Iteration 2

**Agent:** design  
**Iteration:** 2  
**Status:** COMPLETE  
**Generated:** 2026-05-12

---

## Story Classification

| Story | Title | Classification | Rationale |
|-------|-------|---------------|-----------|
| US-2-1 | Event list filters | EXTEND | Filter bottom sheet already exists (`EventFiltersBottomSheet`). Extend with: badge counter on filter button, "Limpiar filtros" conditional visibility, filtered empty state. |
| US-2-2 | Clear filters | EXTEND | Sub-feature of filter bottom sheet. The "Limpiar filtros" button already exists in the sheet but needs conditional display + wiring. Badge disappear on clear. |
| US-2-3 | Attendee profile navigation | NEW | `RiderProfilePage` does not exist. New screen with 4 ResultState branches. Attendee list row gains tap affordance (chevron hint). |

---

## Screen Inventory

### Screen 1: Events List — Filter button with badge (EXTEND)
**Route:** existing (`/events`)  
**Component:** `EventsDataView` → filter button area

**States:**

| State | Description | Mockup |
|-------|-------------|--------|
| No filters | Filter button: orange background, no badge | `events-list/events-list-no-filters.html` — frame 1 |
| Active filters | Filter button: orange background + white badge with count (1–3) | `events-list/events-list-no-filters.html` — frame 2 |
| Filtered empty | Full-screen empty state: icon + "No hay eventos con estos filtros" + "Limpiar filtros" outline button | `events-list/events-list-no-filters.html` — frame 3 |
| All-events empty | Existing empty state: "No hay eventos próximos" (no change) | — |

**Badge logic:**  
- Count = number of non-null backend filters: `type`, `city`, `dateFrom`/`dateTo` (date range = 1)
- Badge hidden when count = 0
- Badge: 16×16px circle, white bg, primary-colored text, 9px bold, positioned top-right of filter icon

**Active filter tag row (below search):**  
- Optional pill row showing active filter values with ✕ tap to remove individual filter
- Orange tinted pill: `rgba(249,140,31,0.15)` bg, primary border

---

### Screen 2: Event Filters Bottom Sheet (EXTEND)
**Route:** Modal overlay on events list  
**Component:** `EventFiltersBottomSheet`

**States:**

| State | Description | Mockup |
|-------|-------------|--------|
| Empty (no filters) | Sheet open, no values set. "Limpiar filtros" **hidden**. "Filtrar" button enabled. | `event-filters/event-filters-bottom-sheet.html` — frame 1 |
| With selection | ≥1 filter active: "Limpiar filtros" (AppTextButton) **visible** in header right. | `event-filters/event-filters-bottom-sheet.html` — frame 2 |
| All 3 backend filters | tipo + ciudad + fechas all set → badge on parent shows "3" | `event-filters/event-filters-bottom-sheet.html` — frame 3 |

**Layout (top-to-bottom):**
1. Drag handle (40×4px, `var(--border)` color, centered, 12px top margin)
2. Header row: title "Filtros de eventos" (titleLarge bold) + `AppTextButton` "Limpiar filtros" (visible only when `activeFilter != null`)
3. Divider
4. Scrollable body:
   - Section "Tipo de evento" → `FilterChip` wrap (Touring, Enduro, Rally, Track day, Adventure)
   - Section "Ciudad" → `AppCityAutocomplete` field
   - Section "Rango de fechas" → two `AppDatePicker` fields side-by-side (Desde / Hasta)
   - Checkboxes: "Solo eventos gratuitos", "Solo multimarca" (local-only filters)
5. Footer (not scrollable): `AppButton` "Filtrar" full-width

**l10n keys used:**  
`event_filterTitle`, `event_filterType`, `event_filterCity`, `event_filterDateRange`, `event_clearFilters`, `event_applyFilters`

---

### Screen 3: Attendee List — Tap affordance (EXTEND)
**Route:** `/events/attendees` (existing)  
**Component:** `AttendeeProcessedItem`

**Change:** Add trailing chevron `›` icon (`Icons.chevron_right_rounded`) in `onSurfaceVariant` color when `onTap` is provided. The row already has `InkWell` + `onTap` wired — visual hint only.

**Mockup:** `rider-profile/rider-profile-states.html` — frame 1 (attendee list with chevron)

---

### Screen 4: Rider Profile Page (NEW)
**Route:** `/events/attendees/rider-profile`  
**Component:** `RiderProfilePage` (new)  
**Widgets:** `RiderProfileContent` (data), `RiderProfileLoading` (shimmer)

**States:**

| State | Description | Mockup |
|-------|-------------|--------|
| Loading | Shimmer skeleton: circular avatar placeholder (72px) + 2 text lines + info rows + vehicle rows | `rider-profile/rider-profile-states.html` — frame 2 |
| Data (with vehicles) | Avatar initials (large, 72px) + name + email + "Motos registradas" section + vehicle list items | `rider-profile/rider-profile-states.html` — frame 3 |
| Data (no vehicles) | Same header + "Sin vehículos registrados" text under section title | `rider-profile/rider-profile-states.html` — frame 4 |
| Error | Error banner (red tint, ⚠ icon, message + sub-message) + "Reintentar" outline button | `rider-profile/rider-profile-states.html` — frame 5 |
| Empty | Not expected (every user has name + email). No design needed. |

**AppBar:** Back button (`‹`) + title "Perfil del motorista"

**Profile header (data state):**  
- `CircleAvatar` 72px with initials (uses `Initials.buildFromFullName`)
- Name: `textTheme.headlineSmall`, bold
- Email: `textTheme.bodyMedium`, `onSurfaceVariant`

**Info section:**  
- City row: icon `📍` + label + value (if `residenceCity` non-null)
- Section title "MOTOS REGISTRADAS" (uppercase, muted, small caps style)
- `VehicleListItem`-style rows: moto icon + `displayName` + plate

**Read-only guarantee:** No edit affordances, no "Set as main" button, no delete icon anywhere on this screen.

**l10n keys used:**  
`rider_profileTitle`, `rider_noVehicles`, `rider_errorRetry`

---

## Component Hierarchy

### Reused from `lib/shared/widgets/`
| Component | Used in |
|-----------|---------|
| `AppButton` | Filter sheet "Filtrar" footer |
| `AppTextButton` | "Limpiar filtros" in sheet header |
| `EmptyStateWidget` | Filtered empty state on events list (extended with "Limpiar filtros" action) |
| `NoSearchResultsEmptyWidget` | When local search returns 0 results (unchanged) |

### Reused from `lib/features/events/`
| Component | Used in |
|-----------|---------|
| `EventFiltersBottomSheet` | Extended: "Limpiar filtros" conditional + AppTextButton |
| `AttendeeProcessedItem` | Extended: trailing chevron when `onTap` provided |
| `InitialsAvatar` | Reused in `RiderProfileContent` |

### New components (iter-2)
| Component | File | Purpose |
|-----------|------|---------|
| `RiderProfilePage` | `lib/features/users/presentation/pages/rider_profile_page.dart` | New screen, provides cubit, 4-branch BlocBuilder |
| `RiderProfileContent` | `lib/features/users/presentation/widgets/rider_profile_content.dart` | Data state widget (one-widget-per-file rule) |
| `RiderProfileLoading` | `lib/features/users/presentation/widgets/rider_profile_loading.dart` | Shimmer skeleton (one-widget-per-file rule) |

---

## UI Copy (Spanish, sentence case)

| Key | Value |
|-----|-------|
| `event_filterTitle` | Filtros de eventos |
| `event_filterType` | Tipo de evento |
| `event_filterDateRange` | Rango de fechas |
| `event_filterCity` | Ciudad |
| `event_clearFilters` | Limpiar filtros |
| `event_noResultsFiltered` | No hay eventos con estos filtros |
| `event_applyFilters` | Filtrar |
| `rider_profileTitle` | Perfil del motorista |
| `rider_noVehicles` | Sin vehículos registrados |
| `rider_errorRetry` | Reintentar |

Button labels: sentence case (`Filtrar`, `Limpiar filtros`, `Reintentar`) — no ALL CAPS.

---

## Dark Theme Tokens Applied

| Token | Value | Usage |
|-------|-------|-------|
| `--bg` | `#111111` | Screen background |
| `--surface` | `#1a1a1a` | Cards, bottom sheet, attendee items |
| `--surface-high` | `#242424` | Form fields, vehicle icon bg |
| `--border` | `#2a2a2a` | Dividers, card borders |
| `--primary` | `#f98c1f` | Filter button bg, active chips, badge ring, active state borders |
| `--on-surface-muted` | `#888888` | Subtitles, meta text, empty icons |
| `--radius` | `8px` | Standard card/button radius |
| `--radius-full` | `999px` | Chips, badges |

---

## Mockup Files

```
docs/design/html-mockups/iter-2/
├── shared/
│   └── styles.css                          ← Design token baseline (new for iter-2)
├── events-list/
│   └── events-list-no-filters.html         ← 3 states: no filters, active badge, filtered empty
├── event-filters/
│   └── event-filters-bottom-sheet.html     ← 3 states: empty, partial fill, all 3 backend filters
└── rider-profile/
    └── rider-profile-states.html           ← 5 frames: attendee list tap + 4 profile states
```

---

## ADR-3 Design Impact

Per ADR-3, `EventsCubit` keeps `Cubit<ResultState<List<EventModel>>>` — no `EventsState` freezed class. Design consequence: badge count derives from `cubit.filters.hasFilters` + individual null checks (type, city, dateRange), not from a `activeFilter` field. Frontend computes the integer count from the existing `EventFilters` plain class.

---

## Acceptance Criteria Cross-reference

| AC | Covered in design |
|----|-------------------|
| US-2-1 #11 Active filter badge | Filter button + badge spec ✓ |
| US-2-1 #12 "Limpiar filtros" conditional | Bottom sheet header, visible only when `hasFilters` ✓ |
| US-2-1 #13 Filtered empty state | Frame 3 of events-list mockup ✓ |
| US-2-1 #14 All-events empty state | Existing `EmptyStateWidget` unchanged ✓ |
| US-2-2 #1 Single-tap clear | "Limpiar filtros" AppTextButton in sheet header ✓ |
| US-2-2 #5 Badge disappears | Badge hidden when `!filters.hasFilters` ✓ |
| US-2-3 #2 Route param | `context.pushNamed(AppRoutes.riderProfile, extra: userId)` noted ✓ |
| US-2-3 #4 UI content | Name + email + vehicle list in data state ✓ |
| US-2-3 #5 Read-only | No edit affordances in any state ✓ |
| US-2-3 #6 ResultState branches | Loading shimmer, data, error, empty (not expected) ✓ |
| US-2-3 #7 Navigation | Attendee list tap → `pushNamed` noted ✓ |
