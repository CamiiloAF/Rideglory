# Frame v6RqaX — Mantenimientos Filter Sheet (Maintenance Filters Bottom Sheet)

**Flutter file(s):** `lib/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart`  
**Module:** E  
**Screenshot:** ../screenshots/v6RqaX.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Dim overlay | #00000080 | semi-transparent black |
| Sheet background | #1E1E24 | `$bg-card` |
| Sheet border | #2A2A32 | `$border` |
| Sheet corner radius | 24 24 0 0 | `$radius-xl` top corners |
| Active filter chip | #F98C1F | `$accent` |
| Inactive chip | #242429 | `$bg-tertiary` |
| "Limpiar todo" link | #F98C1F | `$accent` |
| "Al día" chip | #22C55E | `$success` |
| "Atrasado" chip | #EF4444 | `$error` |
| "Próximo" chip | #EAB308 | `$warning` |
| Radio button active | #F98C1F | `$accent` |
| Radio button inactive | #2A2A32 | `$border` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| "Filtros" title | Space Grotesk | ~18 | 700 | #FFFFFF |
| "Limpiar todo" | Space Grotesk | ~13 | 600 | #F98C1F |
| Section label | Space Grotesk | ~12 | 700 | #9CA3AF |
| Chip label | Space Grotesk | ~13 | 600 | #FFFFFF (active) / #9CA3AF (inactive) |
| Radio option label | Space Grotesk | ~14 | 400 | #FFFFFF |
| "Aplicar filtros" button | Space Grotesk | ~15 | 600 | #0D0D0F |

## Layout & Spacing
- Frame: 390px wide, 844px tall, clip=true, layout=none (absolute)
- **Dim overlay:** full-screen rectangle, #00000080
- **Sheet panel (`LgSpH`):** width 390, positioned at y=320 (from bottom), vertical layout, cornerRadius [24,24,0,0], bg-card, border 1px `$border`
  - Drag handle: small centered bar, ~32×4, bg-tertiary, cornerRadius 2
  - Header row: "Filtros" + "Limpiar todo" link, padding [0, 20], `space_between`
  - **Tipo de mantenimiento** section: label + horizontal chip row (Aceite, Frenos, Llantas, Revisión), gap 8
  - **Estado** section: label + horizontal chip row (Todos, Atrasado, Próximo, Al día)
  - **Rango de fecha** section: label + radio list (Este mes, Últimos 3 meses, Último año, Personalizado)
  - **"Aplicar filtros" CTA:** full-width, height 52, bg-accent, cornerRadius 12
  - Bottom padding: 32px

## Filter Chip Styles
- Active: bg-accent, text white, cornerRadius 17, height 34, padding [0, 16]
- Estado chips have semantic colors: Atrasado=error, Próximo=warning, Al día=success, Todos=inactive (when not selected)
- Radio buttons: standard circular radio, accent when selected

## Notes for Frontend
- Sheet appears as modal over dim overlay
- Only the sheet panel is interactive; tapping overlay dismisses
- Radio options for date range include "Personalizado" which reveals a date picker
