# Frame A7qDd — Profile

**Flutter file(s):** `lib/features/profile/presentation/profile_page.dart` + `lib/features/profile/presentation/widgets/*`  
**Module:** G  
**Screenshot:** ../screenshots/A7qDd.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Card background | #1E1E24 | `$bg-card` |
| Avatar outer ring gradient | #F98C1F → #F98C1F66 | accent gradient |
| Accent | #F98C1F | `$accent` |
| Settings button | #1E1E24 | `$bg-card` |
| Stats card | #1E1E24 | `$bg-card` |
| Stats card cornerRadius | 12 | `$radius-md` |
| Bio text | #9CA3AF | `$text-secondary` |
| "VER TODAS" link | #F98C1F | `$accent` |
| Vehicle card border | #2A2A32 | `$border` |
| Menu divider | #2A2A32 | `$border` |
| Menu card border | #2A2A32 | `$border` |
| "Cerrar sesión" text | #EF4444 | `$error` |
| Menu icon | #9CA3AF | `$text-secondary` |
| Chevron icon | #6B7280 | `$text-tertiary` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Perfil" | Space Grotesk | 22 | 700 | #FFFFFF |
| User name | Space Grotesk | ~20 | 700 | #FFFFFF |
| Location/city | Space Grotesk | ~13 | 400 | #9CA3AF |
| Bio text | Space Grotesk | 13 | 400 | #9CA3AF (line-height 1.5) |
| Stat value | Space Grotesk | ~20 | 700 | #FFFFFF |
| Stat label | Space Grotesk | ~11 | 400 | #9CA3AF |
| "MIS EVENTOS" section label | Space Grotesk | ~11 | 700 | #9CA3AF (uppercase) |
| "VER TODAS" link | Space Grotesk | ~12 | 600 | #F98C1F |
| Event card title | Space Grotesk | ~14 | 700 | #FFFFFF |
| Vehicle name | Space Grotesk | ~14 | 600 | #FFFFFF |
| Vehicle subtitle | Space Grotesk | ~12 | 400 | #9CA3AF |
| "Moto principal" badge | Space Grotesk | ~11 | 600 | #0D0D0F |
| Menu item label | Space Grotesk | ~14 | 400 | #FFFFFF |
| "Cerrar sesión" | Space Grotesk | ~14 | 400 | #EF4444 |

## Layout & Spacing
- Frame: 390px, 1205px tall (scrollable), clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [0, 24]
- **Header row:** "Perfil" title + settings button (40×40, bg-card, cornerRadius 20)
- **Content (`jnQqg`):** padding [0, 20, 24, 20], gap 24, fill_container
  - **Profile card (`vToY3`):** bg-card, cornerRadius 16, padding [24, 20], gap 16, vertical layout, center-aligned
    - Avatar outer frame (`K6jmuV`): 88×88, cornerRadius 44, gradient ring (accent → accent 40%), layout=none
      - Inner avatar: ~76×76, cornerRadius 38, bg-card (photo or initials)
    - Name section (`O3yAr`): vertical, gap 4, center-aligned
      - Name: Space Grotesk ~20 700 white
      - Location: "Medellín, Colombia" — text-secondary ~13
    - Bio text: fixed-width, fill_container, text-secondary 13, lineHeight 1.5, textAlign center
  - **Stats row (`Yo2yz`):** 3 stats in `fill_container` columns, gap 12
    - Each stat card: bg-card, cornerRadius 12, padding [16, 12], vertical layout, gap 4, center-aligned
    - Stat value: ~20 700 white; label: ~11 400 text-secondary
    - Stats: "24 Rodadas", "1,240 Seguidores", "3 Eventos"
  - **Mis Eventos section (`bQXPA`):** vertical, gap 12
    - Section header: "MIS EVENTOS" label (uppercase, text-tertiary) + "VER TODAS" link (accent)
    - Cards row: horizontal scroll (gap 12), event mini-cards ~130px wide
    - Each mini-card: cornerRadius 12, clip=true, height ~100, image fill
  - **My Garage section (`v8prxp`):** vertical, gap 12
    - Section header: "MI GARAJE" + "VER TODO" link
    - Vehicle card (`CbXlK`): bg-card, cornerRadius 12, border `$border`, padding 14, horizontal layout, gap 14
      - Thumbnail: 48×48 image, cornerRadius 8
      - Name + subtitle column
      - "Moto principal" badge chip (accent, cornerRadius 20, padding [6, 10])
  - **Menu list (`mqtxY`):** bg-card, cornerRadius 12, border `$border`, vertical layout
    - "Mis Eventos" row: icon (calendar) + label + chevron
    - Divider: 1px `$border`
    - "Mantenimientos" row
    - Divider
    - "Seguridad" row
    - Divider
    - "Notificaciones" row
    - Divider
    - "Cerrar sesión" row: icon (log-out, red) + label (red) + NO chevron
    - Each row: padding [14, 16], horizontal layout, gap 12, `space_between`
- **Tab bar:** PERFIL tab active (`aHDTO` fill `$accent`, `V86WV` user icon + `tEB17` label fill `$text-inverse`)

## Components used
- `HomeBottomNavigationBar` — PERFIL tab active
- Lucide icons: `settings`, `calendar`, `wrench`, `shield`, `bell`, `log-out`, `chevron-right`, `bike`
- `AppEventBadge` — on mini event cards in "Mis Eventos" section

## States / Variants
- **With data:** profile card with bio, stats, events, garage, menu
- **Own profile:** shows "Mis Eventos" section, full menu with all options
- **Empty events section:** hidden or shows empty placeholder

## Notes for Frontend
- The avatar uses an outer gradient ring (linear, 135deg, accent → accent 66%)
- Stats cards are equal-width (fill_container each) in a horizontal row
- Bio text uses `textGrowth: fixed-width` + `textAlign: center`
- Menu rows use `space_between` with icon left + chevron right
- "Cerrar sesión" row: NO chevron, uses error color for icon and text
