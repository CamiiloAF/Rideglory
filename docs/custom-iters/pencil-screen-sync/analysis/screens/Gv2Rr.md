# Frame Gv2Rr — Event Tracking Riders Panel

**Flutter file(s):** `lib/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart` + `rider_telemetry_card.dart` + `rider_telemetry_riders_content.dart`  
**Module:** C  
**Screenshot:** ../screenshots/Gv2Rr.png

## Architect Open Question — Q6 (Gv2Rr)

**Answer:** `Gv2Rr` maps to `rider_telemetry_panel.dart` (NOT `participants_placeholder_page.dart`). The frame shows a full participants list screen with:
- Status bar
- Back button + "Participants List" title + kebab menu
- Search bar
- Filter chips: Todos (active), Active, Stopped, SOS
- Rider cards with speed, distance, vehicle, action buttons
- SOS alert card (highlighted with red border)
- Custom tab bar (RIDERS tab active — custom variant of VMmN0)

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Background | #0D0D0F | `$bg-primary` |
| Card bg | #1E1E24 | `$bg-card` |
| Normal rider card | #1E1E24 | `$bg-card` |
| SOS rider card | #EF444415 | error 8% |
| SOS rider card border | #EF4444 | `$error` |
| Active filter chip | #F98C1F | `$accent` |
| Inactive filter chip | #242429 | `$bg-tertiary` |
| SOS chip | #EF4444 | `$error` |
| "LEAD" badge | #F98C1F | `$accent` |
| Speed text | #22C55E | `$success` (good) |
| "Stopped" label | #EF4444 | `$error` |
| "Emergency Call" button | #EF4444 | `$error` |
| "Locate" button | #242429 | `$bg-tertiary` (or similar) |
| "View Profile" link | #F98C1F | `$accent` |
| Avatar bg | varies by initials | |
| Search bar bg | #1A1A1F | `$bg-secondary` |
| Border | #2A2A32 | `$border` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title "Participants List" | Space Grotesk | ~18 | 700 | #FFFFFF |
| Search placeholder | Space Grotesk | ~13 | 400 | #6B7280 |
| Filter chip label | Space Grotesk | ~12 | 600 | #FFFFFF / #9CA3AF |
| Rider name | Space Grotesk | ~14 | 700 | #FFFFFF |
| Vehicle info | Space Grotesk | ~12 | 400 | #9CA3AF |
| Speed value | Space Grotesk | ~13 | 700 | #22C55E |
| Distance badge | Space Grotesk | ~11 | 600 | #9CA3AF |
| "Trailing" label | Space Grotesk | ~11 | 400 | #9CA3AF |
| "View Profile →" | Space Grotesk | ~12 | 600 | #F98C1F |
| "Emergency Call" | Space Grotesk | ~13 | 600 | #FFFFFF |
| "Locate ↑" | Space Grotesk | ~13 | 600 | #FFFFFF |
| "SOS ALERT" chip | Space Grotesk | ~10 | 700 | #FFFFFF |
| "LEAD" chip | Space Grotesk | ~10 | 700 | #0D0D0F |

## Layout & Spacing
- Frame: 390px, 844px, clip=true, vertical layout, bg-primary
- **Status bar:** height 62, padding [0, 24]
- **Content wrap (`OL6Hf`):** padding [0, 16, 16, 16], gap 16, fill_container height
  - **Header row:** back arrow (left) + "Participants List" title (center) + kebab menu (right)
  - **Search bar:** fill_container, height 44, bg-secondary, cornerRadius 8, border, padding [0, 14], gap 8 (search icon + placeholder)
  - **Filter chips:** horizontal scroll, gap 8
    - "Todos" (active = accent), "● Active", "● Stopped", "● SOS" (red)
    - Height 34, cornerRadius 17, padding [0, 16]
  - **Rider card list:** vertical, gap 12
    - Each standard card: bg-card, cornerRadius 12, border 1px `$border`, padding [12, 16], vertical layout, gap 10
      - Row 1: avatar (40×40, cornerRadius 20) + name + "LEAD"/"distance" badge, `space_between`
      - Row 2: phone icon (call) + chat icon, horizontal
      - Row 3: vehicle info (bike icon + "KTM 890 Adventure R")
      - Row 4: speed icon + "85 km/h", `space_between` with "View Profile →" link
    - **SOS card:** same structure BUT bg `#EF444415`, border 1.5px `$error`, cornerRadius 12
      - Name chip shows "SOS ALERT" badge (red)
      - "Stopped" status in red
      - Actions row: "Emergency Call" full-width red button + "Locate ↑" button (gap 8)
- **Tab bar:** custom VMmN0 instance — RIDERS tab active, MAP tab shown
  - `descendants` override: `PhMdo` (RIDERS) fill accent, Q9xwhf icon = `users`, tGqK5 label = "RIDERS"
  - Map tab: `XpfRt` icon = `map`, `zw4DM` label = "MAP"

## Notes for Frontend
- The filter chips row has 4 chips: "Todos" (all), "Active" (green dot), "Stopped" (gray/red dot), "SOS" (red dot)
- Phone/chat icons on rider cards are action buttons (call, message)
- The SOS card uses `EF444415` fill (not error-subtle from DS — this is an inline color)
- The "LEAD" badge: cornerRadius 20, bg-accent, padding [4, 8], text text-inverse (dark)
- Avatar initials: white text on colored bg (auto-generated color from name)
- The tab bar for this view uses a CUSTOM VMmN0 instance with "RIDERS" and "MAP" tabs instead of the standard 4-tab navigation
