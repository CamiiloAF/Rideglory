# Design Handoff — Custom Route Builder

## Tool used
Pencil MCP — edited `rideglory.pen` directly (NOT a separate file).
Frames added to the existing design document below the `Crear Evento` frame (y=2100 row).

Screenshots exported to:
`docs/custom-iters/event-creation-fixes-custom-routes-drafts/analysis/design/route-builder/`

---

## Touched screens

| Screen | Status | Frame name in rideglory.pen | Frame ID |
|--------|--------|-----------------------------|----------|
| Custom Route Builder — Vacío | NEW | `Custom Route Builder — Vacío` | `IMyvf` |
| Custom Route Builder — Con Waypoints | NEW | `Custom Route Builder — Con Waypoints` | `veaGt` |
| Custom Route Builder — Límite 9/9 | NEW | `Custom Route Builder — Límite 9/9` | `kY0VR` |
| Custom Route Builder — Búsqueda Activa | NEW | `Custom Route Builder — Búsqueda Activa` | `z58GM` |

---

## UX flows

### Custom Route Builder

#### Empty state (Frame 1 — `IMyvf`)
- Full-screen view with status bar, back arrow, title "Crear ruta personalizada"
- Search bar at top with placeholder "Buscar un lugar..." (inactive border)
- Map area (280px tall) shows grid pattern with a centered overlay hint:
  - Map-pin-plus icon in accent orange
  - "Toca el mapa para agregar un punto"
  - "O usa el buscador de arriba" (secondary text)
- Divider separates map from waypoints section
- "PUNTOS DE RUTA" section header with "0/9 puntos" badge in `$bg-tertiary` / `$text-tertiary`
- Empty state illustration: route icon + "Agrega puntos para construir tu ruta"
- Bottom CTA bar:
  - "Agregar punto" button: `$bg-tertiary` fill, `$border-light` stroke, `$text-tertiary` label — visually inactive (no taps blocked in logic, just needs ≥1 point to route)
  - "Continuar" button: `$bg-tertiary` fill, `opacity: 0.4` — clearly disabled until ≥1 waypoint

#### Adding waypoints via tap / search (Frame 2 — `veaGt`)
- Search field gets orange `$accent` focus border when active
- Map shows numbered pins: pin 1 = `$success` green (origin), pins 2+ = `$accent` orange
- A path connects pins with an orange polyline (thickness 2.5, round cap/join)
- Recenter button (bottom-right of map) for GPS centering
- Waypoints list shows cards: number badge + place name + × delete icon
- Counter updates to "3/9 puntos" in `$accent` color with `$accent-subtle` background
- "Agregar punto" becomes active: `$bg-card` fill, `$border-light` stroke, white label
- "Continuar" CTA becomes fully orange with drop-shadow glow effect

#### At limit — 9/9 (Frame 3 — `kY0VR`)
- Search field shows "Límite de 9 puntos alcanzado" placeholder, `opacity: 0.6`, disabled appearance
- Map shows all 9 pins; pin #9 is rendered in `$error` red to signal it's the last allowed
- Orange warning banner below map: info icon + "Has alcanzado el límite de 9 puntos. Elimina uno para agregar otro."
- Counter shows "9/9 puntos" in `$accent` bold
- Waypoints list: all 9 items visible (scrollable — "Desliza para ver todos" hint shown)
- "Agregar punto" button: `$bg-tertiary`, `opacity: 0.5`, label "Agregar punto (máx. 9)" — disabled
- "Continuar" CTA: fully active orange

#### Active search / autocomplete (Frame 4 — `z58GM`)
- Search field has orange focus border, "Parque Central..." typed text, spinner animation placeholder
- Autocomplete dropdown renders immediately below the field (no gap — cornerRadius 0 on top corners of dropdown, 0 on bottom corners of field)
- Dropdown shows 3 result rows:
  - Row 1 (highlighted): `$bg-tertiary` fill, accent map-pin icon, bold white text
  - Rows 2–3: `$bg-card` fill, tertiary map-pin icon, secondary text
  - Dividers between rows
- Map area is dimmed (`opacity: 0.6`) and partially visible — shows 2 existing pins
- Existing waypoints list still visible below map
- Keyboard placeholder (230px) shows at bottom simulating system keyboard push

---

## Design tokens used (from rideglory.pen)

| Token | Value | Usage |
|-------|-------|-------|
| `$bg-primary` | `#0D0D0F` | Screen background, CTA bar background |
| `$bg-secondary` | `#1A1A1F` | Search field background |
| `$bg-card` | `#1E1E24` | Waypoint cards, dropdown rows |
| `$bg-tertiary` | `#242429` | Inactive buttons, highlighted dropdown row |
| `$border` | `#2A2A32` | Card borders, section dividers |
| `$border-light` | `#3A3A44` | Active button border |
| `$accent` | `#F98C1F` | Active pins, route line, CTA button, counter, focus borders |
| `$accent-subtle` | `#2D2117` | Counter badge background (active), warning banner background |
| `$success` | `#22C55E` | Origin pin (pin #1) |
| `$error` | `#EF4444` | Pin #9 at limit (visual signal) |
| `$text-primary` | `#FFFFFF` | Titles, active field text, card text |
| `$text-secondary` | `#9CA3AF` | Inactive search results |
| `$text-tertiary` | `#6B7280` | Labels, placeholder text, disabled states |
| `$text-inverse` | `#0D0D0F` | Text on orange CTA buttons |
| `$font-primary` | `Space Grotesk` | All text |
| `$radius-md` | `12` | Search field, general cards |
| `$radius-sm` | `8` | Waypoint cards |

Typography scale used:
- Screen title: 18px / 700
- Section labels: 11px / 600 / letter-spacing 0.8 (ALL CAPS)
- Card text: 13–14px / 500
- Counter / badge: 12px / 600–700
- Secondary hints: 11–12px / normal
- CTA button label: 16px / 700

---

## Components

| Component | Reuse existing? | Notes |
|-----------|-----------------|-------|
| Search/autocomplete field | YES — `AppPlaceAutocompleteField` (rewritten in this iteration) | Top of screen; orange focus border on active state |
| Waypoint list card | NEW — `WaypointItemCard` | Number badge (colored) + place name + × delete icon. No drag handle (reorder out of scope) |
| Counter badge | NEW — inline in `CustomRouteBuilderSection` header | `$accent-subtle` bg, `$accent` text/icon when >0 points; `$bg-tertiary` / `$text-tertiary` when 0 |
| Map area | YES — existing `MapboxMap` widget (or placeholder frame) | Full-width; 280px tall in empty/populated state; tap gesture handled via `onMapTap` callback |
| Numbered pin | NEW — rendered by Mapbox annotation layer | Green for origin (#1), orange for waypoints (#2+), red for #9 at limit |
| Route polyline | YES — existing route-drawing logic | Reuse `$accent` orange stroke |
| Recenter button | NEW — small 36px round button inside map | Locate icon; `$bg-card` fill |
| Warning banner | NEW — inline widget in `CustomRouteBuilderSection` | `$accent-subtle` bg, `$accent` stroke and text, info icon |
| CTA bar | EXTEND — `EventFormBottomBar` pattern | Two-button layout: secondary "Agregar punto" + primary "Continuar" |
| Autocomplete dropdown | NEW — overlay `OverlayPortal` | Attaches below search field; 3 visible rows max before scroll |

---

## Spanish copy

| l10n Key | Text |
|----------|------|
| `route_builder_title` | "Crear ruta personalizada" |
| `route_builder_hint_tap` | "Toca el mapa para agregar un punto" |
| `route_builder_hint_search` | "O usa el buscador de arriba" |
| `route_builder_search_placeholder` | "Buscar un lugar..." |
| `route_builder_search_placeholder_disabled` | "Límite de 9 puntos alcanzado" |
| `route_builder_section_title` | "PUNTOS DE RUTA" |
| `route_builder_counter` | "{count}/9 puntos" |
| `route_builder_empty_hint` | "Agrega puntos para construir tu ruta" |
| `route_builder_add_button` | "Agregar punto" |
| `route_builder_add_button_at_limit` | "Agregar punto (máx. 9)" |
| `route_builder_continue` | "Continuar" |
| `route_builder_limit_banner` | "Has alcanzado el límite de 9 puntos. Elimina uno para agregar otro." |
| `route_builder_scroll_hint` | "Desliza para ver todos" |
| `route_autocomplete_result_highlighted` | (first result highlighted — no separate key, handled by index) |

These supplement the keys already defined in `design.md` (`route_simpleLabel`, `route_customLabel`, etc.).

---

## Accessibility checklist

- [ ] Back button has sufficient tap target (40×40px)
- [ ] Map pins have numeric labels readable at small sizes (10–12px bold white on colored bg)
- [ ] Counter badge color change (grey → orange) provides non-color cue via icon
- [ ] Warning banner uses icon + text (not color alone)
- [ ] Disabled CTA "Continuar" uses opacity reduction for clear visual affordance
- [ ] Autocomplete dropdown rows have sufficient 48px+ effective touch targets (12px padding × 2 + content)
- [ ] All text meets contrast ratio with dark backgrounds (white/secondary on `$bg-card`)

---

## Notes for Frontend

1. **This screen is a full-page route** — `CustomRouteBuilderPage` pushed via `context.pushNamed()`. It is NOT an inline section of the event form. The form's `EventFormLocationsSection` shows a button/card that navigates to this page; on return it passes back the `List<String> waypoints`.

2. **Map tap interaction** — Wire `MapboxMap.onMapTap` to call `cubit.addWaypoint(placeName)` after reverse-geocoding the tapped coordinate using `PlaceService`. Show a brief loading indicator on the pin before the name resolves.

3. **Waypoint cards** — No drag-to-reorder (out of scope). Each card has an `onDelete` callback → `cubit.removeWaypoint(index)`.

4. **Counter badge color** — Inactive (0 pts): `$bg-tertiary` bg / `$text-tertiary` text. Active (1–8 pts): `$accent-subtle` bg / `$accent` text. Full (9 pts): same as active (orange).

5. **Pin #9 red** — The last pin (#9) renders in `$error` red only as a visual signal for the designer reference. In code, the actual color logic should be: pin #1 = `$success`, pins #2–9 = `$accent`. The red was used in the limit-state frame to show "this is the boundary".

6. **Autocomplete dropdown** — Implemented as `OverlayPortal` (per architect spec). The dropdown's top corners are square (borderRadius 0 top) to visually connect with the search field's bottom. Use `LayerLink` + `CompositedTransformFollower`.

7. **"Continuar" disabled state** — Disabled when `waypoints.isEmpty`. Enabled when `waypoints.length >= 1`. Pass waypoints list back via `context.pop(waypoints)` when tapped.

8. **Keyboard push** — The screen should be wrapped in `Scaffold` with `resizeToAvoidBottomInset: true` so the keyboard naturally pushes the content up. The map area scrolls out of view.
