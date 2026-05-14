# Frame VMmN0 — Component/Tab Bar (Bottom Navigation)

**Flutter file(s):** `lib/shared/widgets/home_bottom_navigation_bar.dart` + `lib/shared/widgets/bottom_nav_item.dart` + `lib/shared/widgets/bottom_nav_add_button.dart`  
**Module:** DS (Design System)  
**Screenshot:** ../screenshots/VMmN0.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Outer frame bg | transparent | (no fill on outer) |
| Pill container fill | #15151A | `$tab-bar-bg` |
| Pill border | #2A2A32 | `$border` |
| Active tab icon fill | #0D0D0F | `$text-inverse` |
| Active tab label fill | #0D0D0F | `$text-inverse` |
| Active tab item fill | #F98C1F | `$accent` (the tab item frame gets accent background) |
| Inactive tab icon fill | #6B7280 | `$tab-inactive` |
| Inactive tab label fill | #6B7280 | `$tab-inactive` |
| Inactive tab item fill | none | (transparent) |

## Typography
| Text role | Family | Size | Weight | Letter-spacing |
|-----------|--------|------|--------|---------------|
| Tab label (INICIO, EVENTOS, GARAJE, PERFIL) | Space Grotesk | 10 | 600 | 0.5 |

## Layout & Spacing
- **Outer frame (`VMmN0`):** width 390, height 95, padding [12, 21, 21, 21], `justifyContent: center`
- **Pill container (`SxurC`):** fill_container width, height 62, cornerRadius 36, bg `$tab-bar-bg`, border: inside 1px `$border`, padding 4
  - Layout: horizontal (default for frame)
  - 4 tab items, each `fill_container` width, `fill_container` height
- **Each tab item (IoLku / yeeg4 / PhMdo / aHDTO):** vertical layout, `justifyContent: center`, `alignItems: center`, gap 4, cornerRadius 26
  - Inactive: fill = none (transparent)
  - Active: fill = `$accent` (#F98C1F)
  - Icon: 18×18, `fill: $tab-inactive` (inactive) / `fill: $text-inverse` (active)
  - Label: Space Grotesk 10 600, letter-spacing 0.5, same fill logic

## Tab Items
| Tab | ID | Icon (lucide) | Label | Active screen |
|-----|-----|---------------|-------|---------------|
| Inicio | IoLku | `house` | INICIO | Home (`dyWWs`) |
| Eventos | yeeg4 | `calendar` | EVENTOS | Events list (`Neipf`) |
| Garaje | PhMdo | `bike` | GARAJE | Garage (`KCf6W`) |
| Perfil | aHDTO | `user` | PERFIL | Profile (`A7qDd`) |

## Active State Per Screen
Each screen overrides the `VMmN0` instance `descendants` to set the active tab:
- Home (`dyWWs`): `IoLku` fill `$accent`, `lstaG` (house icon) fill `$text-inverse`, `qFkwP` (INICIO label) fill `$text-inverse`
- Events (`Neipf`): `yeeg4` fill `$accent`, `XpfRt` (calendar icon) fill `$text-inverse`, `zw4DM` (EVENTOS label) fill `$text-inverse`
- Garage (`KCf6W`): `PhMdo` fill `$accent`, `Q9xwhf` (bike icon) fill `$text-inverse`, `tGqK5` (GARAJE label) fill `$text-inverse`
- Profile (`A7qDd`): `aHDTO` fill `$accent`, `V86WV` (user icon) fill `$text-inverse`, `tEB17` (PERFIL label) fill `$text-inverse`

## Notes for Frontend
- The outer frame padding is [12, 21, 21, 21] — top 12, sides 21, bottom 21 (safe area accounts for this)
- The pill cornerRadius is 36 (very rounded), NOT the standard `$radius-xl` (24) — use 36 explicitly
- Tab item cornerRadius is 26 — gives the "pill-inside-pill" appearance for the active state
- Labels are ALL CAPS with letter-spacing 0.5 — must use `letterSpacing: 0.5` in TextStyle
- Icons: 18×18 — use `iconSize: 18` or `width: 18, height: 18`
- Hardcoded strings ('Inicio', 'Garaje', 'Eventos', 'Perfil') MUST be moved to `app_es.arb` when touched
