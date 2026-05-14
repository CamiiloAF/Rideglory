# Frame YCuIq — Vehicle Bottom Sheet (Vehicle Selector)

**Flutter file(s):** `lib/shared/widgets/vehicle_selection_bottom_sheet.dart` OR `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`  
**Module:** D  
**Screenshot:** ../screenshots/YCuIq.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Dim overlay | #00000099 | semi-transparent black (60%) |
| Sheet bg | #1E1E24 | `$bg-card` |
| Sheet border | #2A2A32 | `$border` |
| Selected radio | #F98C1F | `$accent` |
| Unselected radio | #2A2A32 | `$border` |
| "Agregar nuevo vehículo" | #F98C1F | `$accent` |
| Drag handle | #2A2A32 | `$border` |
| Divider | #2A2A32 | `$border` |
| Vehicle icon | #9CA3AF | `$text-secondary` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Sheet title "Seleccionar Vehículo" | Space Grotesk | ~18 | 700 | #FFFFFF |
| Close button (X) | — | — | — | text-secondary |
| Vehicle name | Space Grotesk | ~14 | 600 | #FFFFFF |
| Vehicle subtitle (plate + year) | Space Grotesk | ~12 | 400 | #9CA3AF |
| "Agregar nuevo vehículo" | Space Grotesk | ~14 | 600 | #F98C1F |

## Layout & Spacing
- Frame: 390×844, layout=none, clip=true
- **Dim overlay (`IJdeM`):** full screen rectangle, #00000099
- **Sheet panel (`LgSpH`):** width 390, positioned at y=436 (from top), cornerRadius [24,24,0,0], bg-card, border inside 1px `$border`, vertical layout
  - **Drag handle:** centered bar, ~32×4, bg-border, cornerRadius 2, padding top 12
  - **Sheet header row:** "Seleccionar Vehículo" title + X close button, padding [16, 20]
  - **Vehicle list:** vertical, each vehicle = horizontal list item, padding [12, 20], gap 12
    - Bike icon (24×24, text-secondary) + name/subtitle column + radio button right
    - Selected: radio = accent filled circle; unselected = border circle
    - Divider between items: 1px `$border`
  - **"+ Agregar nuevo vehículo":** text link with + icon, accent, padding [16, 20]
  - Bottom safe area padding: ~32px

## Notes for Frontend
- This sheet is used from multiple screens: maintenance form (select vehicle), garage (options), etc.
- The sheet slides up from bottom with the dim overlay behind it
- Radio selection is single-choice (only one vehicle can be "main" / selected)
- The "BMW R 1250 GS" is shown as selected (orange radio fill)
- "Agregar nuevo vehículo" navigates to `VehicleFormPage`
