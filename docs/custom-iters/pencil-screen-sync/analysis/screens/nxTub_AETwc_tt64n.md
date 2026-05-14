# Frames nxTub / AETwc / tt64n — Event Tracking SOS & Dialogs

**Flutter file(s):**
- `nxTub`: `lib/features/events/presentation/tracking/live_map_page.dart` + `lib/features/events/presentation/tracking/widgets/sos_button.dart`
- `AETwc`: `lib/features/events/presentation/tracking/live_map_page.dart` (dialog)
- `tt64n`: `lib/features/events/presentation/tracking/live_map_page.dart` (dialog)

**Module:** C  
**Screenshots:** ../screenshots/nxTub.png, ../screenshots/AETwc.png, ../screenshots/tt64n.png

---

## Frame nxTub — Event Tracking SOS Alert

This frame shows the live map with a SOS banner at the top — a rider has sent an SOS signal.

### Layout (layout=none, 390×844, clip=true)
- **Background map:** dark (`#0C1018` near-black rectangle full screen)
- **Top gradient overlay:** `#0D0D0FF0` → `#0D0D0FAA` → transparent, linear, 210px height
- **SOS Banner (`C3kDkh`):** positioned x=16, y=50, width=358
  - cornerRadius 16, fill `#EF444415` (error color 8% opacity), border 1.5px center `$error`
  - Vertical layout, gap 6, padding [14, 16]
  - Title: "Alex Rivera necesita ayuda" — bold, red (#EF4444)
  - Subtitle: "Km 40, Vía al Mar · Detenido hace 0 min" — text-secondary, small
- **SOS Actions row (`n5zgvn`):** x=16, y=148, width=358, horizontal, gap 12
  - "Llamar" button: height 44, cornerRadius 12, bg `#EF4444`, gap 8, phone icon
  - "Localizar" button: height 44, cornerRadius 12, bg-card, border, gap 8, map-pin icon
- **Route path:** SVG path, stroke accent orange, cap=round, thickness 3, width=310
- **Rider pins:** absolute positioned avatar circles with labels (AR = SOS red, CA = neutral, MR = neutral)
  - SOS pin: 14×14 orange dot with glow shadow `#F98C1F88`
- **Control cluster (`ahOkF`):** right side — zoom +/- group, cornerRadius 12, bg #1E1E24CC
- **My-location button (`R2NIK`):** right side below controls — 40×40, cornerRadius 12, bg-accent, center icon
- **Bottom gradient:** dark overlay, height 284, bottom of screen
- **Bottom sheet (`uZsuW`):** x=0, y=724, height 120, cornerRadius [16,16,0,0], bg-secondary, border outside `$border`
  - Shows SOS rider info — avatar, name "Alex Rivera — SOS", distance, speed/stop status

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Map bg | #0C1018 | custom dark |
| SOS banner fill | #EF444415 | error 8% |
| SOS banner border | #EF4444 | `$error` |
| SOS button bg | #EF4444 | `$error` |
| Locate button bg | #1E1E24 | `$bg-card` |
| Route path | #F98C1F | `$accent` |
| My-location btn | #F98C1F | `$accent` |
| Controls cluster | #1E1E24CC | bg-card 80% |
| Bottom sheet | #1A1A1F | `$bg-secondary` |

---

## Frame AETwc — SOS Confirmation Dialog

### Layout (layout=none, 390×844)
- **Background:** `#0C1018` + `#00000080` dim overlay
- **Dialog card (`mAzSr`):** x=25, y=260, width=340
  - cornerRadius 24, bg-secondary (#1A1A1F), border 1px `$border` (center)
  - shadow: blur 48, color `#000000A0`, offset y+16
  - vertical layout, gap 16, padding [32, 28], `alignItems: center`
  - **Icon area:** warning triangle icon, 48×48, error red, bg error 10%
  - **Title:** "¿Enviar alerta de emergencia?" — Space Grotesk 18 700 white, centered
  - **Body:** "Se notificará a todos los participantes de la rodada y tu ubicación será compartida." — Space Grotesk 13 400 text-secondary, centered, line-height 1.5
  - **"Enviar SOS" button:** fill_container, height 52, bg-error (#EF4444), cornerRadius 12, gap 8, users icon + label
  - **"Cancelar" link:** fill_container, height 40, cornerRadius 12, text-tertiary centered

### Colors
| Role | Hex | Variable |
|------|-----|----------|
| Dialog bg | #1A1A1F | `$bg-secondary` |
| Dialog border | #2A2A32 | `$border` |
| Warning icon color | #EF4444 | `$error` |
| Warning icon bg | #EF444419 | error ~10% |
| "Enviar SOS" button | #EF4444 | `$error` |
| Title text | #FFFFFF | `$text-primary` |
| Body text | #9CA3AF | `$text-secondary` |
| "Cancelar" text | #6B7280 | `$text-tertiary` |

---

## Frame tt64n — End Ride Confirmation Dialog

Same layout as AETwc but for ending the ride:
- **Dialog card (`La8qi`):** same dimensions, cornerRadius 24, bg-secondary
- **Icon:** flag icon, ~40×40, NOT red — uses accent or text-primary color (flag-finish)
- **Title:** "¿Terminar la rodada?"
- **Body:** "Todos los participantes serán notificados y el rastreo se detendrá para todos."
- **"Terminar rodada" button:** fill_container, height 52, bg-error (#EF4444), cornerRadius 12, flag icon + label
- **"Cancelar" link:** same as AETwc

### Notes for both dialogs
- These are modal dialogs (`showDialog`) rendered over the map — render-only per Architect (no business wiring in scope)
- Both use `AppDialog` or `ConfirmationDialog` styled to match
- The dialog has NO border-radius on inner elements — rounded edges come from the card container only
- The "Cancelar" link has NO background, NO border — pure text link, center-aligned

---

## Notes for Frontend (tracking screens)
- `live_map_widget.dart` is OFF-LIMITS — do not touch
- Only the overlay chrome (banners, dialogs, control widgets) are in scope
- The SOS banner overlay is NOT `sos_button.dart` — it's a separate `Positioned` widget in `live_map_page.dart`
- `sos_button.dart` is the red circular button in bottom-right of normal map view (frame `o1A6t4`)
