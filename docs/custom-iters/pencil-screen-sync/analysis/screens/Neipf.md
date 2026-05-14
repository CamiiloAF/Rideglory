# Frame Neipf — Events List

**Flutter file(s):** `lib/features/events/presentation/list/events_page.dart` + `lib/features/events/presentation/list/widgets/*`  
**Module:** C  
**Screenshot:** ../screenshots/Neipf.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Page background | #0D0D0F | `$bg-primary` |
| Card background | #1E1E24 | `$bg-card` |
| Accent orange | #F98C1F | `$accent` |
| Search bar background | #1A1A1F | `$bg-secondary` |
| Active filter chip fill | #F98C1F | `$accent` |
| Inactive filter chip fill | #242429 | `$bg-tertiary` |
| Filter button (icon) fill | #F98C1F | `$accent` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| FAB background | #F98C1F | `$accent` |
| FAB shadow | #F98C1F55 | accent 33% opacity |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Explorar Eventos" | Space Grotesk | 22 | 700 | #FFFFFF |
| Search placeholder | Space Grotesk | ~14 | 400 | #6B7280 |
| Active filter chip label | Space Grotesk | ~13 | 600 | #FFFFFF |
| Inactive filter chip label | Space Grotesk | ~13 | 600 | #9CA3AF |
| Event card title | Space Grotesk | ~16 | 700 | #FFFFFF |
| Event card location | Space Grotesk | ~12 | 400 | #9CA3AF |
| Event card date | Space Grotesk | ~12 | 400 | #9CA3AF |
| Event card price | Space Grotesk | ~13 | 700 | #F98C1F |
| Event type chip | Space Grotesk | ~11 | 600 | various |

## Layout & Spacing
- Status bar height: 63px, padding [22, 20, 0, 20]
- Content padding: [8, 20, 16, 20], gap 16
- **Header row:** `space_between`, screen title left
- **Search row:** height 44, gap 10
  - Search bar: fill_container, height 44, bg-secondary, cornerRadius `$radius-sm` (8), border 1px `$border`, padding [0, 14], gap 8 (icon + placeholder)
  - Filter button: 44×44, bg-accent, cornerRadius 8, center-aligned icon (lucide `sliders-horizontal`)
- **Filter chips row:** horizontal scroll, gap 8, height 34 per chip
  - Active chip: bg-accent, cornerRadius 17, padding [0, 16]
  - Inactive chip: bg-tertiary, cornerRadius 17, padding [0, 16]
  - Chip labels: text only (no icons)
- **Events list:** vertical layout, gap 16, fill_container height
  - Each event card: fill_container width, cornerRadius `$radius-md` (12), bg-card, clip=true, vertical layout
- **FAB ("+ Nueva Rodada"):** absolute positioned bottom-right, cornerRadius 24, bg-accent, height 48, padding [0,20], gap 8, shadow: blur 20, color #F98C1F55, offset y+4

## Event Card Structure
- **Hero image:** full-width, height ~160–180px, clip=true
- **Badges row:** positioned on image (top-right): `AppEventBadge` for status
- **Type/category chip:** positioned on image (top-left)
- **Card body:** padding [12, 16], vertical layout, gap 8
  - Title: Space Grotesk 16 700 white
  - Location row: lucide `map-pin` icon (12px, accent) + location text
  - Date/time row: lucide `calendar` icon + date text
  - Price row: Space Grotesk 13 700 accent (#F98C1F)
- **Expand toggle:** bottom of card, text-tertiary, small chevron

## Components used
- `AppEventBadge` — status chip per event (DISPONIBLE=blue, LLENO=red, etc.)
- `HomeBottomNavigationBar` — EVENTOS tab active (`yeeg4`/`zw4DM`/`XpfRt` get accent fill)
- Lucide icons: `search`, `sliders-horizontal`, `map-pin`, `calendar`, `plus`, `chevron-down`

## States / Variants
- **Data state:** list of event cards
- **Empty state:** no events found illustration + message
- **Loading state:** shimmer/loading indicators

## Notes for Frontend
- The filter chips visible in frame: "Todos" (active), "Este fin de semana", "Gratuito", "Road"
- The FAB has absolute positioning (layoutPosition: "absolute") at bottom-right — it overlays the scroll content
- The tab bar shows EVENTOS tab active: `yeeg4` pill fill `$accent`, `XpfRt` (calendar icon) and `zw4DM` (label) get fill `$text-inverse`
