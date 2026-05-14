# Frame VKLP4 — Detalle de Mantenimiento (Maintenance Detail)

**Flutter file(s):** `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` + `detail/widgets/*`  
**Module:** E  
**Screenshot:** ../screenshots/VKLP4.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Card bg | #1E1E24 | `$bg-card` |
| "Realizado" badge | #22C55E | `$success` |
| "Realizado" badge bg | #162A1F | custom (success-subtle) |
| Info row border-bottom | #2A2A32 | `$border` |
| Cost value (accent) | #F98C1F | `$accent` |
| "Próxima revisión" card border | #2A2A32 | `$border` |
| "Próxima fecha" date | #FFFFFF | `$text-primary` |
| "Próximo odómetro" | #9CA3AF | `$text-secondary` |
| "Editar" button | #F98C1F | `$accent` (border + text) |
| "Eliminar" button | #EF4444 | `$error` |
| Kebab menu icon | #9CA3AF | `$text-secondary` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Detalle de Mantenimiento" | Space Grotesk | ~18 | 700 | #FFFFFF |
| Back button | — | — | — | text-secondary |
| Maintenance type name | Space Grotesk | ~16 | 700 | #FFFFFF |
| Vehicle chip | Space Grotesk | ~11 | 600 | #9CA3AF |
| "Realizado" badge | Space Grotesk | ~11 | 700 | #22C55E |
| Section header ("INFORMACIÓN DEL SERVICIO") | Space Grotesk | ~10 | 700 | #9CA3AF (uppercase, letter-spacing 1.5) |
| Info row label | Space Grotesk | ~13 | 400 | #9CA3AF |
| Info row value | Space Grotesk | ~13 | 600 | #FFFFFF |
| Cost value | Space Grotesk | ~15 | 700 | #F98C1F |
| Notes text | Space Grotesk | ~13 | 400 | #9CA3AF |
| "Próxima revisión" section header | Space Grotesk | ~13 | 700 | #FFFFFF |
| Date / km values | Space Grotesk | ~14 | 600 | #FFFFFF |
| "Editar" button | Space Grotesk | ~14 | 600 | #F98C1F |
| "Eliminar" button | Space Grotesk | ~14 | 600 | #EF4444 |

## Layout & Spacing
- Frame: 390px, 870px tall, vertical layout, bg-primary
- **Status bar:** height 44, padding [0, 24]
- **Header row:** back button + "Detalle de Mantenimiento" + kebab menu (three-dot), padding [0, 20], height 52
- **Scroll content (`qITfb`):** padding [12, 20, 24, 20], gap 16, fill_container height, clip=true
  - **Header card:** bg-card, cornerRadius 12, padding 16, vertical layout
    - Maintenance type icon (40×40 circle, colored icon bg) + type name + vehicle chip
    - "Realizado" badge: cornerRadius 8, bg #162A1F, padding [6, 10], text success green
  - **Info section:** section header + info rows (bg-card, cornerRadius 12)
    - Each row: label left + value right, height ~44, border-bottom 1px `$border`
    - Fields: Fecha del servicio, Odómetro, Taller, Costo
    - Cost uses accent color for value
  - **Notes section:** "Notas" header + text content area (bg-card, cornerRadius 12, padding 16)
  - **"Próxima revisión" card:** bg-card, cornerRadius 12, border `$border`, padding 16
    - "Próxima fecha" + date value
    - "Próximo odómetro" + km value
- **CTA bar (`tDGGl`):** padding [16, 20, 32, 20], horizontal layout, gap 12
  - "Editar" button: fill_container, height 52, cornerRadius 12, border 1px `$accent`, text-accent
  - "Eliminar" button: fill_container, height 52, cornerRadius 12, bg-error (#EF4444), text-white

## Notes for Frontend
- The "Realizado" / "Programado" badge is in the header card — semantic status
- Section headers use ALL CAPS, 10 700, text-tertiary, letter-spacing 1.5
- The info rows use bg-card as background with border-bottom dividers between rows (NOT between cards)
- Cost formatting: Colombian pesos (e.g., "$85,000 COP")
- "Editar" button is ghost style (border only); "Eliminar" button is solid red
