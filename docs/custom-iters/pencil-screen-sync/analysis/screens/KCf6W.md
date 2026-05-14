# Frame KCf6W — Garaje (Vehicle List)

**Flutter file(s):** `lib/features/vehicles/presentation/garage/garage_page.dart` + `lib/features/vehicles/presentation/garage/widgets/*`  
**Module:** D  
**Screenshot:** ../screenshots/KCf6W.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Page background | #0D0D0F | `$bg-primary` |
| Card background | #1E1E24 | `$bg-card` |
| Accent | #F98C1F | `$accent` |
| "Moto principal" badge | #F98C1F | `$accent` |
| Vehicle list item bg | #1E1E24 | `$bg-card` |
| Vehicle list item border | #2A2A32 | `$border` |
| Quick stat icon backgrounds | varies (#1B2E4A for blue, #162A1F for green) | custom |
| Quick stat icon colors | `$info`, `$success` | |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| "Agregar" button | #F98C1F | `$accent` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Mi Garaje" | Space Grotesk | 22 | 700 | #FFFFFF |
| "Agregar" button | Space Grotesk | ~13 | 600 | #0D0D0F |
| "Moto principal" badge label | Space Grotesk | ~11 | 600 | #0D0D0F |
| Main vehicle name | Space Grotesk | ~18 | 700 | #FFFFFF |
| Vehicle subtitle (year/cc/plate) | Space Grotesk | ~12 | 400 | #9CA3AF |
| "Ver detalle" link | Space Grotesk | ~12 | 600 | #F98C1F |
| Quick stat value | Space Grotesk | ~16 | 700 | #FFFFFF |
| Quick stat label | Space Grotesk | ~10 | 400 | #9CA3AF |
| "Mantenimiento" / "Documentos" button | Space Grotesk | ~13 | 600 | #FFFFFF |
| Section header "Otras motos" | Space Grotesk | ~13 | 700 | #9CA3AF |
| Other vehicle name | Space Grotesk | ~14 | 600 | #FFFFFF |
| Other vehicle subtitle | Space Grotesk | ~12 | 400 | #9CA3AF |

## Layout & Spacing
- Frame: 390px wide, 844px tall, clip=true, vertical layout
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Header row:** padding [8, 20], `space_between`, height implicit
  - Left: "Mi Garaje" title
  - Right: "+ Agregar" button — cornerRadius 20, bg-accent, padding [8, 16], gap 4, icon `plus`
- **Scroll content:** padding [4, 16, 24, 16], gap 16, height 639
  - "Moto principal" badge: cornerRadius 20, bg-accent, padding [6, 12], gap 4, icon `star` or similar
  - Main vehicle card: bg-card, cornerRadius 16, clip=true, vertical layout
    - Image area: ~120px tall, full-width, bg-secondary
    - Info area: padding [12, 16], vertical layout, gap 12
    - Name + subtitle + "Ver detalle" row
    - Quick stats row: 3 stats (km, prom. servicio, último servicio), horizontal, gap 12
    - Action buttons row: "Mantenimiento" + "Documentos", gap 12, height 48 each, bg-secondary, cornerRadius 12
  - "Otras motos" section header (if multiple vehicles)
  - Each other vehicle: horizontal list item, padding [12, 16], gap 12, bg-card, cornerRadius 12, border 1px `$border`
    - Thumbnail: 44×44, cornerRadius 8
    - Name + subtitle column
    - Chevron right icon
- **Tab Bar Container:** padding [12, 21, 21, 21]

## Components used
- `HomeBottomNavigationBar` — GARAJE tab active (`PhMdo` fill `$accent`, `Q9xwhf` bike icon + `tGqK5` label fill `$text-inverse`)
- `DocumentSlotPill` — used inside vehicle detail (not visible here, but via "Documentos" button)
- Lucide icons: `plus`, `star`, `wrench`, `file-text`, `chevron-right`, `bike`, `map-pin`, `calendar`

## States / Variants
- **With vehicles:** main vehicle card + "Otras motos" list
- **Empty garage:** `garage_empty_state.dart` — empty state illustration + "Agregar mi primera moto" CTA
- **Options bottom sheet:** `YCuIq` frame — shown on "..." menu tap

## Notes for Frontend
- The "•••" (three-dot) menu on the main vehicle card opens the `YCuIq` Vehicle Bottom Sheet
- Quick stats row shows: Kilómetros, Prom. servicio, Último servicio
- "Ver detalle" link has a chevron-right icon inline
- The main vehicle image uses a hero image (from vehicle photo) or placeholder gradient
