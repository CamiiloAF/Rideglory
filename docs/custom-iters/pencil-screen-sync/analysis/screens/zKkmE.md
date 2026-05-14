# Frame zKkmE — Component/Event Badge

**Flutter file(s):** `lib/design_system/atoms/badges/app_event_badge.dart`  
**Module:** DS (Design System)  
**Screenshot:** ../screenshots/zKkmE.png

## Colors
| Badge variant | Fill | Text color |
|---------------|------|------------|
| Default/Estado (blue) | #3B82F6 (`$info`) | #FFFFFF |
| Disponible | #3B82F6 (`$info`) | #FFFFFF |
| Lleno / Sold Out | #EF4444 (`$error`) | #FFFFFF |
| Próximamente | #EAB308 (`$warning`) | #FFFFFF |
| En Vivo | #22C55E (`$success`) | #FFFFFF |
| Cancelado | #6B7280 (`$text-tertiary`) | #FFFFFF |
| Custom (any) | provided fill | #FFFFFF |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Badge label | Space Grotesk | 11 | 700 | #FFFFFF |

## Layout & Spacing
- Container: horizontal layout, `alignItems: center`, `justifyContent: center`
- Corner radius: 20 (fully rounded pill)
- Padding: [5, 12] — vertical 5, horizontal 12
- Label: Space Grotesk 11 700, fill #FFFFFF, no letter-spacing in component definition (may vary per usage)

## Notes for Frontend
- The component's default fill is `$info` (#3B82F6) — "ESTADO" placeholder text shown in the design
- All badge variants use the same shape; only the fill color changes
- Text is always white (#FFFFFF) regardless of fill — hardcoded, not using text-inverse
- The badge has NO icon — text only
- Padding is asymmetric: [5, 12] = top/bottom 5, left/right 12
- No border/stroke on this component
