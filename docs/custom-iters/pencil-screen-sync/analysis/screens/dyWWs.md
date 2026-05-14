# Frame dyWWs — Home Dashboard

**Flutter file(s):** `lib/features/home/presentation/home_page.dart` + `lib/features/home/presentation/widgets/*`  
**Module:** B  
**Screenshot:** ../screenshots/dyWWs.png

## Colors
| Role | Hex | AppColors / Variable mapping |
|------|-----|------------------------------|
| Page background | #0D0D0F | `$bg-primary` / `AppColors.darkBackground` |
| Card background | #1E1E24 | `$bg-card` |
| Accent / orange | #F98C1F | `$accent` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| Text tertiary | #6B7280 | `$text-tertiary` |
| Border | #2A2A32 | `$border` |
| Border light | #3A3A44 | `$border-light` |
| View all button border | #3A3A44 | `$border-light` (transparent fill) |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Time (status bar) | Inter | 16 | 600 | #FFFFFF |
| User name (greeting) | Space Grotesk | ~20 | 700 | #FFFFFF |
| User subtitle | Space Grotesk | ~13 | 400 | #9CA3AF |
| Section title ("MI GARAJE", "PRÓXIMAS RODADAS") | Space Grotesk | ~11 | 700 | #9CA3AF (uppercase, letter-spacing) |
| "VER TODAS" link | Space Grotesk | ~12 | 600 | #F98C1F |
| Vehicle name | Space Grotesk | ~16 | 700 | #FFFFFF |
| Vehicle subtitle (year/cc/plate) | Space Grotesk | ~12 | 400 | #9CA3AF |
| "VER DETALLE" link | Space Grotesk | ~12 | 600 | #F98C1F |
| Garage stats (km, km prom, month) | Space Grotesk | ~18 | 700 | #FFFFFF |
| Garage stat labels | Space Grotesk | ~10 | 400 | #9CA3AF |
| Event card title | Space Grotesk | ~15–16 | 700 | #FFFFFF |
| Event card location/date | Space Grotesk | ~11 | 400 | #9CA3AF |
| "VER DETALLES" button | Space Grotesk | ~11 | 600 | #FFFFFF |
| "VER CATÁLOGO COMPLETO DE EVENTOS" | Space Grotesk | ~13 | 600 | #9CA3AF |

## Layout & Spacing
- Page padding: top 8, horizontal 20, bottom 24
- Status bar height: 62px
- Gap between top section and bottom section: 24px
- **Top section ("MI GARAJE"):**
  - Greeting row: `space_between` alignment
  - Notification bell: 40×40, bg-card, cornerRadius 20
  - Garage section gap: 12px
  - Main vehicle card: bg-card, cornerRadius 16, clip=true, overflow image
  - Vehicle image: 180px tall (hero), full-width
  - Vehicle info area: padding [12, 16], vertical layout, gap 12
  - Stats row: 3 columns, gap 12, each stat: vertical layout, gap 4
  - "Mantenimiento" + "Documentos" action buttons: horizontal row, gap 12, each button height 48, bg-secondary, cornerRadius 12, border 1px `$border`
  - "Otras motos" list items: padding [12,16], horizontal layout, gap 12, height ~52, bg-card, cornerRadius 12
- **Bottom section ("PRÓXIMAS RODADAS"):**
  - Section header: `space_between`
  - Event cards horizontal scroll row: height 340, clip=true, gap 16
  - Each event card: width ~165–180px, cornerRadius 16, clip=true, bg-card, overflow image top
  - Card image: ~140px tall
  - Card content: padding [10,12], vertical gap 8
  - Event badge: top-right of card image (absolute/positioned)
  - "VER DETALLES" button: width fill, height 36, cornerRadius 8, bg-secondary, border 1px border-light
  - "VER CATÁLOGO" CTA: fill_container, height 48, border 1px border-light, cornerRadius 16, transparent fill, gap 8

## Components used
- `AppEventBadge` (`zKkmE`) — event status chip on event cards
- `HomeBottomNavigationBar` (`VMmN0`) — tab bar at bottom, "Inicio" tab active (icon+label fill `$text-inverse`, pill fill `$accent`)
- Lucide icons: `house`, `bell`, `motorcycle` (or bike), `wrench`, `file-text`
- Status bar icons: Lucide `signal`, `wifi`, `battery-full`

## States / Variants
- **With garage data:** main vehicle card shows image, stats, action buttons
- **Empty garage:** `home_empty_garage_card.dart` — empty state with CTA to add vehicle
- **With events:** horizontal scroll of event cards
- **No events:** `home_empty_events_card.dart`

## Notes for Frontend
- The "MI GARAJE" section title uses ALL CAPS with letter-spacing (~1.5)
- The active tab for this screen is INICIO — `IoLku` item gets `fill: $accent`, icon and text fill `$text-inverse` (#0D0D0F)
- Vehicle stats row shows: km, "Prom. servicio", "Último servicio" (month/year)
- The bottom "VER CATÁLOGO" button has a chevron-down icon and is borderless-background
