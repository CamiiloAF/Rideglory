# Frame aGqnv — Documentos / Document Slot Pill (Molecule)

**Flutter file(s):** `lib/design_system/molecules/feedback/document_slot_pill.dart`  
**Module:** DS (Design System)  
**Screenshot:** ../screenshots/aGqnv.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Section background | #0D0D0F | `$bg-primary` |
| Card background (each slot) | #1E1E24 | `$bg-card` |
| Icon bg — SOAT (info/blue) | #1B2E4A | custom (no AppColors constant) |
| Icon color — SOAT | #3B82F6 | `$info` |
| Icon bg — Tecnicomecánica (success/green) | #162A1F | custom (no AppColors constant) |
| Icon color — Tecnicomecánica | #22C55E | `$success` |
| Icon bg — expired/neutral | #242429 | `$bg-tertiary` |
| Icon color — neutral | #9CA3AF | `$text-secondary` |
| Badge Vigente fill | #162A1F | custom |
| Badge Vigente text | #22C55E | `$success` |
| Badge Por vencer fill | #2A2200 | custom |
| Badge Por vencer text | #EAB308 | `$warning` |
| Badge Vencido fill | #2D1010 | custom |
| Badge Vencido text | #EF4444 | `$error` |
| Delete button bg | #242429 | `$bg-tertiary` |
| Delete button icon | #9CA3AF | `$text-tertiary` |
| Border | #2A2A32 | `$border` |
| Border light | #3A3A44 | `$border-light` |
| Info row text | #6B7280 | `$text-tertiary` |
| Count text | #F98C1F | `$accent` |
| "Opcional" badge text | #6B7280 | `$text-tertiary` |
| "Opcional" badge border | #3A3A44 | `$border-light` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| "DOCUMENTOS" header label | Space Grotesk | 10 | 700 | #6B7280 (text-tertiary, uppercase, letter-spacing 1.5) |
| "Opcional" badge | Space Grotesk | 10 | 400 | #6B7280 |
| Count "3/3" | Space Grotesk | 13 | 700 | #F98C1F (accent) |
| Document name | Space Grotesk | 13 | 700 | #FFFFFF |
| Expiry "Vence: DD MMM YYYY" | Space Grotesk | 11 | 400 | #9CA3AF |
| Badge text (Vigente / Por vencer / Vencido) | Space Grotesk | 10 | 600 | varies |
| "Máximo 3 documentos" | Space Grotesk | 11 | 400 | #6B7280 |

## Layout & Spacing
- Outer frame: 390px wide, 377px tall, clip=true, bg-primary, gap 10, padding `$spacing-md` (16)
- **Header row (`B4ALn`):** horizontal, gap `$spacing-xs` (4), `fill_container` width
  - "DOCUMENTOS" label
  - "Opcional" badge: cornerRadius 4, border 1px `$border-light`, padding [8, 3]
  - Spacer: fill_container height 1 (flexible)
  - Count "3/3": accent text
- **Each document card (oDq6h / tSWLa / wYtpw):** horizontal, gap 10, bg-card, cornerRadius `$radius-md` (12), padding 12, fill_container width
  - Icon container: 40×40, cornerRadius `$radius-sm` (8), icon 20×20, center-aligned
  - Middle column: vertical, gap 2, fill_container — name (700) + expiry (400)
  - Right column: vertical, gap 6, `align-end`
    - Status badge: cornerRadius 4, padding [6, 3] — colored bg + text
    - Delete button: 24×24, cornerRadius 4, bg-tertiary, x-icon 14×14
- **Info row (`myXRU`):** horizontal, gap 5, center-aligned, fill_container
  - Info icon: lucide `info` 12×12, text-tertiary
  - "Máximo 3 documentos": Space Grotesk 11, text-tertiary

## States
| State | Icon bg | Icon color | Badge label | Badge fill | Badge text color |
|-------|---------|------------|-------------|------------|------------------|
| Vigente | #162A1F | `$success` | "Vigente" | #162A1F | `$success` |
| Por vencer | `$bg-tertiary` | `$text-secondary` | "Por vencer" | #2A2200 | `$warning` |
| Vencido | `$bg-tertiary` | `$error` | "Vencido" | #2D1010 | `$error` |
| Empty slot | n/a | n/a | n/a | n/a | n/a |

## Components used
- Lucide icons: `file-text` (20×20), `info` (12×12), `x` (14×14)

## Notes for Frontend
- The header "DOCUMENTOS" label uses uppercase and letter-spacing 1.5
- The count "3/3" is right-aligned with a fill_container spacer in between
- The "Opcional" badge uses `stroke` (border), no fill — not a filled chip
- New AppColors constants needed:
  - `AppColors.successSubtle` = `#162A1F` (used for Vigente icon bg + badge bg)
  - `AppColors.warningSubtle` = `#2A2200` (used for Por vencer badge bg)
  - `AppColors.errorSubtle` = `#2D1010` (used for Vencido badge bg)
  - `AppColors.infoSubtle` = `#1B2E4A` (used for SOAT icon bg)
