# Frame J5h6P — Registrar Paso 1 Tipo (Maintenance Form Step 1)

**Flutter file(s):** `lib/features/maintenance/presentation/form/maintenance_form_page.dart` + `lib/features/maintenance/presentation/form/widgets/*`  
**Module:** E  
**Screenshot:** ../screenshots/J5h6P.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Type card — selected | #F98C1F | `$accent` |
| Type card — unselected | #1E1E24 | `$bg-card` |
| Type card border | #2A2A32 | `$border` |
| Type card icon — selected | #0D0D0F | `$text-inverse` |
| Type card icon — unselected | #F98C1F | `$accent` |
| Step indicator active | #F98C1F | `$accent` |
| Step indicator inactive | #2A2A32 | `$border` |
| "Continuar" button | #F98C1F | `$accent` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Nuevo Mantenimiento" | Space Grotesk | ~18 | 700 | #FFFFFF |
| "Paso 1 de 2" | Space Grotesk | ~12 | 400 | #9CA3AF |
| Section subtitle | Space Grotesk | ~14 | 400 | #9CA3AF |
| Type card label | Space Grotesk | ~13 | 600 | #FFFFFF (selected) / #FFFFFF (unselected) |
| "Continuar" button | Space Grotesk | ~15 | 600 | #0D0D0F |

## Layout & Spacing
- Frame: 390px, 844px, clip=true, vertical layout, bg-primary
- **Status bar:** height 44, padding [0, 20]
- **Header/nav:** height 52, padding [0, 16], gap 8
  - Back button: 36×36, bg-card, cornerRadius 18, border
  - Title: "Nuevo Mantenimiento" centered
- **Step row:** horizontal, padding [12, 24, 4, 24], gap 8
  - Step indicators: circles (2 total), active = accent fill, inactive = border fill
- **Subtitle section:** padding [12, 16, 4, 16] — "Selecciona el tipo de mantenimiento"
- **Cards grid (`cardsGrid`):** padding [8, 16, 0, 16], gap 12
  - 2-column grid of type cards (4 rows × 2 = 8 types)
  - Each card: bg-card OR bg-accent (selected), cornerRadius 12, border 1px `$border`, padding 16, height ~80
  - Card layout: vertical, icon (32×32) + label text, gap 8, center-aligned
- **Spacer:** fill_container height (flexible space above CTA)
- **CTA bar (`iiUtZ`):** padding [16, 16, 34, 16]
  - "Continuar" button: fill_container, height 52, bg-accent, cornerRadius 12

## Maintenance Type Cards
| Type | Icon | Label |
|------|------|-------|
| Cambio de aceite | `droplets` (flame/oil icon) | Cambio de aceite |
| Revisión de frenos | `disc` | Revisión de frenos |
| Cambio de llantas | `circle` | Cambio de llantas |
| Revisión general | `wrench` | Revisión general |
| Filtro de aire | `wind` | Filtro de aire |
| Cadena y piñones | `link` | Cadena y piñones |
| Electricidad | `zap` | Electricidad |
| Otro | `more-horizontal` | Otro |

## States / Variants
- Default: all cards unselected (bg-card, icon color = accent)
- One card selected: selected card bg = accent, icon color = text-inverse (#0D0D0F)

## Notes for Frontend
- The selected card uses bg-accent fill with text-inverse icon — creates the "inverse" active look
- "Paso 1 de 2" step indicator shows 2 dots/circles — first filled (accent), second empty (border)
- CTA bottom padding is 34px (accounts for safe area)
