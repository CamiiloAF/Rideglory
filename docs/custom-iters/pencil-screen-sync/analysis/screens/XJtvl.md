# Frame XJtvl — Mis Eventos (My Events / My Registrations)

**Flutter file(s):** `lib/features/event_registration/presentation/my_registrations_page.dart` + `my_registrations_view.dart` + `my_registrations_data_view.dart` + `widgets/inscription_card.dart`  
**Module:** F  
**Screenshot:** ../screenshots/XJtvl.png

## Architect Open Question — Q4 (XJtvl)

**Answer:** `XJtvl` is `my_registrations_page.dart` — it shows events the user has **registered for as an attendee** (not events they created as organizer). The frame shows registration cards with status badges (DISPONIBLE, COMPLETADO) and filter tabs.

This is NOT `events_page.dart` with `showMyEvents: true`.

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Card bg | #1E1E24 | `$bg-card` |
| Card border | #2A2A32 | `$border` |
| Accent | #F98C1F | `$accent` |
| Active filter tab | #F98C1F | `$accent` |
| Inactive filter tab | #242429 | `$bg-tertiary` |
| Status badge DISPONIBLE | #3B82F6 | `$info` |
| Status badge COMPLETADO | #22C55E | `$success` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Mis Eventos" | Space Grotesk | 22 | 700 | #FFFFFF |
| Filter tab label | Space Grotesk | ~13 | 600 | #FFFFFF / #9CA3AF |
| Event card title | Space Grotesk | ~16 | 700 | #FFFFFF |
| Event card location | Space Grotesk | ~12 | 400 | #9CA3AF |
| Event card date | Space Grotesk | ~12 | 400 | #9CA3AF |
| Price badge | Space Grotesk | ~12 | 700 | #F98C1F |
| Status badge | Space Grotesk | 11 | 700 | #FFFFFF |

## Layout & Spacing
- Frame: 390px, 1650px tall (long scroll), clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [0, 20]
- **Top bar (`c8J0rn`):** height 56, padding [0, 16], gap 12
  - "Mis Eventos" title + gear/settings icon button
- **Filter bar (`g7LIIk`):** height 52, padding [0, 16], gap 8, horizontal scroll
  - Filter chips: "Todos" (active=accent), "Próximos", "Pasados" (inactive=bg-tertiary)
  - Height 34, cornerRadius 17, padding [0, 16]
- **Cards list (`WYBMO`):** padding 16, gap 14, fill_container height
  - Each event card: fill_container width, cornerRadius 12, bg-card, clip=true, vertical layout
  - **Hero image:** full-width, height ~140–160px, fill=image
    - Status badge: `AppEventBadge` positioned top-left on image, padding [6, 8]
    - Price badge: top-right, cornerRadius 12, bg `#F98C1FCC`, padding [4, 8]
  - **Card body:** padding [12, 16], vertical layout, gap 8
    - Title: Space Grotesk 16 700 white
    - Location: map-pin icon + text
    - Date: calendar icon + date text
- **Tab bar:** EVENTOS tab active (same as Neipf)

## Components used
- `AppEventBadge` — status badges (DISPONIBLE, COMPLETADO, PRÓXIMAMENTE, etc.)
- `HomeBottomNavigationBar` — EVENTOS tab active
- Lucide icons: `map-pin`, `calendar`, `settings` or `sliders`

## States / Variants
- **Data:** list of inscription cards
- **Empty (Todos):** empty state — "No tienes eventos registrados"
- **Empty (Próximos):** "No tienes rodadas próximas"
- **Empty (Pasados):** "No tienes rodadas pasadas"

## Notes for Frontend
- This is a SEPARATE page from `events_page.dart` — it has its own route and cubit
- Filter tabs are horizontally scrollable chips (not a TabBar widget)
- The card design is visually similar to `event_card.dart` but may differ in registered-status indicators
- Each card should show the attendee's registration status badge, not just event status
