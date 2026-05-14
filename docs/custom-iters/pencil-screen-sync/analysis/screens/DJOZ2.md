# Frame DJOZ2 — Rider Profile (Other User's Profile)

**Flutter file(s):** `lib/features/users/presentation/pages/rider_profile_page.dart` + `lib/features/users/presentation/widgets/*`  
**Module:** G  
**Screenshot:** ../screenshots/DJOZ2.png

## Colors
Same palette as Profile (`A7qDd`): bg-primary #0D0D0F, bg-card #1E1E24, accent #F98C1F, text-primary #FFFFFF, text-secondary #9CA3AF.

Additional:
| Role | Hex | Variable |
|------|-----|----------|
| "Seguir" button | #F98C1F | `$accent` |
| Stat value | #FFFFFF | `$text-primary` |
| Vehicle thumbnail bg | #1E1E24 | `$bg-card` |
| Profile tab active | #F98C1F | `$accent` (PERFIL tab) |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Back button | — | — | — | text-secondary |
| Screen sub-title "Perfil" | Space Grotesk | ~16 | 400 | #9CA3AF |
| User name | Space Grotesk | ~22 | 700 | #FFFFFF |
| Location | Space Grotesk | ~13 | 400 | #9CA3AF |
| Bio | Space Grotesk | ~13 | 400 | #9CA3AF |
| Stat value | Space Grotesk | ~22 | 700 | #FFFFFF |
| Stat label | Space Grotesk | ~11 | 400 | #9CA3AF |
| "Seguir" button | Space Grotesk | ~15 | 600 | #0D0D0F |
| Section header | Space Grotesk | ~11 | 700 | #9CA3AF |
| Event title | Space Grotesk | ~14 | 600 | #FFFFFF |
| Event subtitle | Space Grotesk | ~12 | 400 | #9CA3AF |

## Layout & Spacing
- Frame: 390px, 1084px tall (scrollable), clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [22, 20, 0, 20]
- **Header row (`NYMiq`):** height 56, padding [0, 20], gap 16
  - Back button (arrow-left)
  - "Perfil" subtitle text
  - Kebab menu (three-dot)
- **Content (`U1ttR`):** padding [0, 20, 24, 20], gap 24, fill_container
  - **Avatar:** centered, ~88×88, cornerRadius 44, gradient ring (accent → accent 40%)
  - **Name + location:** centered, vertical, gap 4
  - **Bio:** centered text, text-secondary, line-height 1.5
  - **Stats row:** 3 equal columns, gap 12
    - "23 Rodadas", "156 Seguidores", "89 Siguiendo"
    - Each: bg-card, cornerRadius 12, padding [16, 12], vertical, center
  - **"Seguir" button:** fill_container, height 52, bg-accent, cornerRadius 12, text-inverse
  - **"Motos" section:** section header + horizontal thumbnail row (3 vehicle thumbnails, 80×60, cornerRadius 8, bg-card)
  - **"Eventos organizados" section:** vertical list of event mini-rows
    - Each row: event title + date/attendees, divider-separated
- **Tab bar:** PERFIL tab active

## Notes for Frontend
- This screen is VIEW-ONLY — no edit capability (no settings button)
- The "Seguir" / "Siguiendo" button toggles follow state
- Vehicle thumbnails in "Motos" section: horizontal scroll, 3 visible
- Stat labels: "Rodadas", "Seguidores", "Siguiendo" (different from own profile which shows "Eventos")
- No menu list (that's only on own profile `A7qDd`)
