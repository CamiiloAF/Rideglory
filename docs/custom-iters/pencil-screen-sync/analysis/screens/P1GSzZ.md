# Frame P1GSzZ — Detalle de Moto (Vehicle Detail)

**Flutter file(s):** `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` (embedded in `garage_page.dart`)  
**Module:** D  
**Screenshot:** ../screenshots/P1GSzZ.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Page background | #0D0D0F | `$bg-primary` |
| Card/section background | #1E1E24 | `$bg-card` |
| Accent | #F98C1F | `$accent` |
| "Moto principal" badge | #F98C1F | `$accent` |
| Spec icon colors | varies | `$info`, `$success`, `$text-secondary` |
| Spec icon bg | #1B2E4A (blue), #162A1F (green) | custom |
| Document badge Vigente | #22C55E | `$success` |
| Document badge Vigente bg | #162A1F | custom |
| Document badge Por vencer | #EAB308 | `$warning` |
| Document badge Por vencer bg | #2A2200 | custom |
| Document badge Vencido | #EF4444 | `$error` |
| Border | #2A2A32 | `$border` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| Text tertiary | #6B7280 | `$text-tertiary` |
| CTA "Ver historial" button | #F98C1F | `$accent` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title (vehicle name) | Space Grotesk | ~18 | 700 | #FFFFFF |
| "Moto principal" badge | Space Grotesk | ~11 | 600 | #0D0D0F |
| Vehicle year/cc/plate (subtitle) | Space Grotesk | ~12 | 400 | #9CA3AF |
| Plate number (large) | Space Grotesk | ~20 | 700 | #FFFFFF |
| Engine spec value | Space Grotesk | ~14 | 600 | #FFFFFF |
| Engine spec label | Space Grotesk | ~11 | 400 | #9CA3AF |
| Section header (ESPECIFICACIONES, DOCUMENTOS, etc.) | Space Grotesk | ~11 | 700 | #9CA3AF (UPPERCASE, letter-spacing 1.5) |
| Spec row label | Space Grotesk | ~13 | 400 | #9CA3AF |
| Spec row value | Space Grotesk | ~13 | 600 | #FFFFFF |
| Document slot title | Space Grotesk | 13 | 700 | #FFFFFF |
| Document slot expiry | Space Grotesk | 11 | 400 | #9CA3AF |
| Document status badge | Space Grotesk | 10 | 600 | varies |
| Overview item value | Space Grotesk | ~16 | 700 | #FFFFFF |
| Overview item label | Space Grotesk | ~10 | 400 | #9CA3AF |
| "Ver historial de mantenimientos" | Space Grotesk | ~14 | 600 | #0D0D0F |

## Layout & Spacing
- Frame: 390px wide, 1213px tall (scrollable), clip=true, vertical layout
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Header/nav:** padding [8, 20], `space_between`, height 52
  - Back button: 36×36, bg-card, cornerRadius 18, border `$border` — lucide `arrow-left`
  - Vehicle name: center
  - Edit button: 36×36, bg-card, cornerRadius 18, border `$border` — lucide `edit` or `pencil`
- **Hero image:** height 180, fill=image, clip=true, layout=none
  - "Moto principal" badge: positioned top-right corner, cornerRadius 20, bg-accent, gap 4
- **Scroll content:** padding [16, 20, 24, 20], gap 16, clip=true
  - **Quick Info section:** horizontal row, gap 8, 3 stats — each: bg-card, cornerRadius 12, padding [12, 16], vertical layout
    - Values: 16 700, labels: 10 400
  - **Plate card:** bg-card, cornerRadius 12, border `$border`, padding 16
    - "PLACA" label: text-tertiary 11 700 uppercase
    - Plate value: text-primary 20 700
  - **Full Specs section:** vertical list of spec rows
    - Each row: horizontal `space_between`, height ~48, border-bottom 1px `$border`
    - Icon: 32×32 bg-icon, cornerRadius 8; spec label; spec value right-aligned
  - **Documents section (aGqnv):** document slot cards (see aGqnv.md)
  - **Garage Overview (stats):** 3-column grid — km total, trips, maintenance count
- **CTA bar:** "Ver historial de mantenimientos" — full-width, height 52, bg-accent, cornerRadius 12, padding bottom 16

## Components used
- `DocumentSlotPill` (`aGqnv`) — document cards
- Lucide icons: `arrow-left`, `pencil`, `gauge`, `zap`, `weight`, `palette`, `star`, `calendar`, `route`, `wrench`

## States / Variants
- **With documents:** shows document slot cards with Vigente/Por vencer/Vencido badges
- **Empty documents:** empty slot pill with "+ Agregar documento" CTA
- **Main vehicle:** "Moto principal" badge visible

## Notes for Frontend
- Section headers use ALL CAPS, Space Grotesk 11 700, text-tertiary, letter-spacing 1.5
- The "tab bar container" at the bottom is GARAJE tab active (same as KCf6W)
- Spec row icons have colored icon backgrounds: blue `#1B2E4A` for info-type specs, green `#162A1F` for green specs
- Documents section reuses the `aGqnv` component pattern directly
