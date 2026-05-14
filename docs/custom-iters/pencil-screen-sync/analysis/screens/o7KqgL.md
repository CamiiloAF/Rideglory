# Frame o7KqgL — Mantenimientos V2 (Maintenance List / Dashboard)

**Flutter file(s):** `lib/features/maintenance/presentation/list/maintenances/maintenances_page.dart` + `list/widgets/*`  
**Module:** E  
**Screenshot:** ../screenshots/o7KqgL.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Summary card bg | #1E1E24 | `$bg-card` |
| "Atrasado" card left border | #EF4444 | `$error` |
| "Próximamente" card left border | #EAB308 | `$warning` |
| "Al día" card left border | #22C55E | `$success` |
| Category label "ATRASADO" | #EF4444 | `$error` |
| Category label "PRÓXIMAMENTE" | #EAB308 | `$warning` |
| Category label "AL DÍA" | #22C55E | `$success` |
| Accent | #F98C1F | `$accent` |
| Filter/add button | #F98C1F | `$accent` |
| Tab bar bg | #15151A | `$tab-bar-bg` (GARAJE tab active) |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| Mileage value | varies | green/yellow/red based on status |
| "Fallará" label | #EF4444 | `$error` |
| "Faltan" label | #EAB308 | `$warning` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Mantenimientos" | Space Grotesk | ~22 | 700 | #FFFFFF |
| Filter/add button icon | — | — | — | #0D0D0F |
| Summary card number "5" / "$847,500" | Space Grotesk | ~26 | 700 | #FFFFFF |
| Summary label "Servicios" / "Total gastado" | Space Grotesk | ~12 | 400 | #9CA3AF |
| Category label ("ATRASADO", "PRÓXIMAMENTE", "AL DÍA") | Space Grotesk | ~10 | 700 | varies (semantic) |
| Category count badge | Space Grotesk | ~11 | 600 | #FFFFFF |
| Maintenance item name | Space Grotesk | ~14 | 700 | #FFFFFF |
| Vehicle name chip | Space Grotesk | ~11 | 600 | #9CA3AF |
| Mileage info | Space Grotesk | ~12 | 600 | varies |
| "Faltan X km" | Space Grotesk | ~11 | 400 | `$text-secondary` |
| "Fallará" | Space Grotesk | ~11 | 700 | `$error` |

## Layout & Spacing
- Frame: 390px, 844px tall, clip=true, vertical layout, bg-primary
- **Status bar:** height 44, padding [0, 20]
- **Header (`Y5NVYp`):** height 52, padding [0, 20], `space_between`
  - Left: "Mantenimientos" title
  - Right: filter icon button (40×40, bg-card, cornerRadius 20) + add FAB (accent)
- **Scroll content (`NsbmQ`):** padding [8, 20, 16, 20], gap 16, fill_container height
  - **Summary card:** bg-card, cornerRadius 16, padding 16 — shows "5 Servicios" + "$847,500 Total gastado" in 2-column layout
  - **"ATRASADO" section:** section label (red, uppercase, 10 700, letter-spacing 1.5) + badge count + maintenance items
  - **"PRÓXIMAMENTE" section:** yellow label + items
  - **"AL DÍA" section:** green label + items
  - Each maintenance item card: bg-card, cornerRadius 12, left-border 3px (semantic color), padding 14, horizontal layout, gap 12
    - Left: category icon (colored circle, 40×40)
    - Middle: name + vehicle chip + mileage info
    - Right: mileage value (km) + status text ("Fallará" / "Faltan N km")
- **Tab bar:** GARAJE tab active (PhMdo fill accent)

## Components used
- `HomeBottomNavigationBar` — GARAJE tab active
- Lucide icons: `sliders-horizontal` (filter), `plus` (add), `oil-can`, `disc-brake`, `tire`, `wrench`, `wind`, `link`, `zap`, `more-horizontal`

## Notes for Frontend
- This is the maintenance LIST/DASHBOARD, not the form. It groups items by status category.
- The "Total gastado" shows COP format (Colombian pesos) — currency formatting needed
- Maintenance items have a colored left-border (3px) indicating urgency — this is a design pattern specific to this list
- The summary card shows aggregate stats — from `MaintenanceCubit` / `MaintenanceSummary` domain model
- Tab bar active: GARAJE (since maintenance is part of the garage feature area)
