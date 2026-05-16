# Design Handoff — event-form-redesign

**Date:** 2026-05-16
**Source:** Pencil frame `zbCa0` ("Crear Evento") in `rideglory.pen`
**Tool used:** Pencil MCP — batch_get on frame `zbCa0` and children

---

## Touched Screens

| Screen | Classification | Frame ID |
|---|---|---|
| Event Create/Edit Form | UPDATE | `zbCa0` |

---

## UX Flows

### Crear Evento (zbCa0) — States

| State | Description |
|---|---|
| Idle (create) | Title "Nuevo Evento", all fields empty, chips unselected except Turismo (first) |
| Idle (edit) | Title "Editar Evento", fields pre-populated from existing event |
| Loading (save) | "Publicar" button shows CircularProgressIndicator |
| Success | SnackBar "Evento creado" / "Evento actualizado", form pops |
| Error | SnackBar with error message |
| maxParticipants unset | Stepper shows placeholder state; field not sent |
| maxParticipants set | Stepper shows count (default 25 per design) |
| Precio normal | Price input active, "Evento gratuito" unchecked |
| Evento gratuito | Price input collapsed via AnimatedSize, value null |

---

## Frame Structure — Pencil zbCa0 (exact measurements)

### Header (node `b5ke7`, padding [12,20,16,20])
- Left: "Cancelar" text, `$text-secondary`, fontSize 16, weight normal
- Center: "Nuevo Evento" text, `$text-primary`, fontSize 17, weight 700
- Right: "Publicar" text, `$accent`, fontSize 16, weight 700

**Flutter mapping:**
- `leading`: `TextButton("Cancelar", style: TextButtonTheme with textOnDarkSecondary)`
- `title`: `Text("Nuevo Evento", 16sp, w600)`
- `actions`: `[TextButton("Publicar", style: primary color)]`
- No back arrow; AppBar `automaticallyImplyLeading: false`

---

### Cover Section (node `SHg6c`, gap 12)
- Cover area: h=160, bg `$bg-secondary`, border `$border-light`, cornerRadius `$radius-md`, vertical layout centered
  - Image icon (lucide `image`, 32×32, `$text-tertiary`)
  - "Agregar portada del evento" (14sp, w600, `$text-secondary`)
  - "Imagen principal de la rodada" (12sp, normal, `$text-tertiary`)
- Buttons row (gap 12):
  - "Subir foto" btn: bg `$bg-tertiary`, border `$border`, cornerRadius `$radius-sm`, h=42
  - "Generar con IA" btn: bg `$accent-subtle`, border `$accent`, cornerRadius `$radius-sm`, h=42

**Note:** Cover section already implemented as `FormImageSection` — keep existing widget, only ensure styling matches.

---

### INFORMACIÓN BÁSICA (node `LL4sx`, gap 10)
- Section header: "INFORMACIÓN BÁSICA", 11sp, w700, letterSpacing 1.5, `$text-tertiary`
- Nombre field (node `Io4BN`): bg `$bg-secondary`, border `$border`, cornerRadius `$radius-md`, padding [14,16], gap 6
  - Label row (pencil icon + "Nombre") 
  - Placeholder: "Ej. Rodada Nocturna — Ruta del Café", 15sp, `$text-tertiary`
- Descripción field (node `FZqVL`): same card style
  - Label: "Descripción y recomendaciones" (12sp, w600, `$text-secondary`)
  - Rich text toolbar row
  - Divider (1px, `$border`)
  - Placeholder (80px tall, 14sp, `$text-tertiary`)

**Note:** These already exist as `EventFormBasicInfoSection`. Keep existing implementation.

---

### FECHA Y HORA (node `i05zi`, gap 10)
- Section header: "FECHA Y HORA", 11sp, w700, letterSpacing 1.5, `$text-tertiary`
- Date row (gap 10): two equal cards "Fecha Inicio" + "Fecha Fin" side-by-side
- Hora field: full-width card, bg `$bg-secondary`, border `$border`, cornerRadius `$radius-md`

**Note:** Already implemented as `EventFormDateTimeSection`. Keep.

---

### RUTA (node in Scroll Bottom, `QJphU` section header)
- Section header: "RUTA", 11sp, w600, letterSpacing 0.8, Space Grotesk, `$text-tertiary`
- Route card (node `MLC9v`): bg `$bg-card`, border `$border`, cornerRadius 12
  - Origin waypoint row (green dot 10×10 + label col + map-pin icon)
  - Divider 1px `$border`
  - Destination waypoint row (accent dot + label + map-pin)
  - Map preview strip (node `b0OXBg`): h=130, bg `$bg-primary`, cornerRadius [0,0,12,12], absolute-positioned route line in `$accent`

**Note:** Already implemented as `EventFormLocationsSection`. Keep.

---

### DIFICULTAD (node `YKyYy`, gap 10)
- Section header: "DIFICULTAD", 11sp, w600, letterSpacing 0.8, `$text-tertiary`
- Flame selector card (node `J3vDB`): bg `$bg-card`, border `$border`, cornerRadius 12, padding [14,16], gap 12
  - Top row: flame icons (5x) + current level text (right)
  - Subtitle: level description text, 12sp, `$text-tertiary`

**Note:** Already implemented as `EventFormDifficultySection`. Keep.

---

### TIPO DE EVENTO (node `N7QUeB`, gap 10) — REDESIGN REQUIRED

- Section header: "TIPO DE EVENTO", 11sp, w600, letterSpacing 0.8, Space Grotesk, `$text-tertiary`
- Row 1 (node `NO2D1`, gap 8): Turismo · Urbana · Off-road
- Row 2 (node `ef5Kp`, gap 8): Competición · Solidaria · Corta distancia

**Chip spec (from Pencil):**
- **Selected** (node `KfitW`): `fill: $accent` (#f98c1f), `cornerRadius: 20`, `padding: [9,14]`
  - Text: "Turismo", 13sp, w600, `$text-inverse` (white)
- **Unselected** (nodes `jjvnE`, `Y6ycY3`, etc.): `fill: $bg-card`, `cornerRadius: 20`, `padding: [9,14]`, `stroke: $border 1px inside`
  - Text: 13sp, w500, `$text-secondary`

**Flutter implementation:**
```dart
// Chip container
decoration: BoxDecoration(
  color: isSelected ? AppColors.primary : AppColors.darkCard,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: isSelected ? AppColors.primary : AppColors.darkBorderPrimary,
    width: 1,
  ),
),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
// Text
TextStyle(
  color: isSelected ? Colors.white : AppColors.textOnDarkSecondary,
  fontSize: 13,
  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
)
```

**Layout:** Two separate `Row` widgets (not Wrap) to match Pencil's 2-row layout exactly:
- Row 1: Row(children: [tourism, urban, offRoad], gap: 8, mainAxisAlignment: start)
- Row 2: Row(children: [competition, solidarity, shortDistance], gap: 8, mainAxisAlignment: start)
- Use `Wrap` with runSpacing 8 + spacing 8 to handle overflow gracefully, equivalent to 2 rows of 3.

---

### MARCAS PERMITIDAS (node `fmcDo`, gap 10) — KEEP

- Section header: "MARCAS PERMITIDAS", 11sp, w600, letterSpacing 0.8, `$text-tertiary`
- Toggle card (node `m8OEI8`): bg `$bg-card`, border `$border`, cornerRadius 12, padding [12,14], `justifyContent: space_between`
  - Left: label + subtitle
  - Right: toggle switch (accent track, cornerRadius 14)
- Hint row (node `gg2OR`): bg `$bg-secondary`, cornerRadius 10, padding [10,12], gap 8
  - Info icon (lucide `info`, 15×15, `$text-tertiary`) + hint text (12sp, lineHeight 1.5)

**Note:** Already implemented as `EventFormMultiBrandSection`. Keep.

---

### MÁXIMO DE PARTICIPANTES (node `oRT03`, gap 10) — NEW

- Header row (node `STKhz`, `justifyContent: space_between`):
  - "MÁXIMO DE PARTICIPANTES", 11sp, w600, letterSpacing 0.8, `$text-tertiary`
  - "Opcional" badge: bg `$bg-tertiary` (AppColors.darkTertiary), cornerRadius 10, padding [2,8]
    - Text: "Opcional", 10sp, w500, `$text-tertiary`

- Max card (node `zgJUg`): bg `$bg-card`, border `$border`, cornerRadius 12, padding [12,14], `justifyContent: space_between`, `alignItems: center`
  - Left (node `kl1Vc`, gap 2, vertical):
    - "Cupos disponibles", 14sp, w500, `$text-primary`
    - "Deja vacío para no limitar inscritos", 11sp, normal, `$text-tertiary`
  - Right — Stepper (node `u0pNVH`): bg `$bg-tertiary`, cornerRadius 10, border `$border` 1px
    - Minus button: 40×40 frame, lucide `minus` icon 16×16 `$text-secondary`
    - Vertical divider: 1px `$border`, h=24
    - Count frame: 52px wide, 40px tall, count text 16sp w700 `$text-primary`
    - Vertical divider: 1px `$border`, h=24
    - Plus button: 40×40 frame, lucide `plus` icon 16×16 `$accent`

- Hint row (node `ZQgga`, gap 6, no background):
  - Users icon: lucide `users`, 13×13, `$text-tertiary`
  - "Una vez lleno el cupo, el evento aparece como 'Completo' automáticamente.", 11sp, normal, `$text-tertiary`, lineHeight 1.4

**Flutter stepper behavior:** min=5, max=500, step=5. Default display: 25. When field is null (unset), show "—" or the default 25 but treat as null in form state.

**Recommended approach:** `FormBuilderField<int?>` with `null` as the initial value when not in edit mode. The card is always shown (optional but visible). User must tap "+" to activate. When null, show default display value 25 in the stepper but don't emit it until user interacts. Actually simpler: initialize stepper at null (show "0") and let user tap + to increase. Or: show 0 and only include in payload if > 0. **Decision:** Initialize as `null`; display "–" in count frame when null; first tap on "+" sets to 5 (min). Tapping "–" when at 5 returns to null (effectively removing the limit).

---

### PRECIO DE INSCRIPCIÓN (node `OdzcB`, gap 10) — REDESIGN REQUIRED

- Header row (node `HMPRg`, `justifyContent: space_between`):
  - "PRECIO DE INSCRIPCIÓN", 11sp, w600, letterSpacing 0.8, `$text-tertiary`
  - "Opcional" badge: same style as maxParticipants

- Price input card (node `OVzj4`): bg `$bg-card`, border `$border`, cornerRadius 12, h=52, padding [0,14], gap 10, `alignItems: center`
  - "$" symbol: 18sp, w600, `$text-tertiary`
  - Vertical divider: 1px `$border`, h=24
  - Amount input: 16sp, w500, `$text-tertiary` (placeholder "0.00")

- Free event row (node `Q2HJb`, gap 8, `alignItems: center`):
  - Checkbox (node `VFwm7`): 18×18, bg `$accent`, cornerRadius 4, contains check icon (lucide `check`, 12×12, `$text-inverse`)
  - "Evento gratuito", 13sp, w500, `$text-secondary`

**AnimatedSize behavior:** When "Evento gratuito" is checked:
- Price input card collapses via `AnimatedSize` (duration 200ms, curve easeInOut)
- Price value cleared/nulled in form state
- "Evento gratuito" row always visible

---

### CTA Area (node `pcpCE`, gap 10) — KEEP (already in bottom bar)

- "Publicar evento" button (node `JHKkv`): bg `$accent`, cornerRadius 28, h=56, gap 10, centered
  - Send icon (lucide `send`, 20×20, `$text-inverse`) + "Publicar evento" (16sp, w700, `$text-inverse`)
- "Guardar como borrador" link (node `xLhce`): gap 6, padding [4,0], centered
  - Archive icon (lucide `archive`, 14×14, `$text-tertiary`) + "Guardar como borrador" (13sp, w500, `$text-tertiary`)

**Note:** Already implemented in `_FormBottomBar`. Keep behavior, just extract to own file.

---

## Components — Reused vs New

| Component | Status | Notes |
|---|---|---|
| `FormImageSection` | reuse | Cover section |
| `EventFormBasicInfoSection` | reuse | Name, description, city |
| `EventFormDateTimeSection` | reuse | Date/time |
| `EventFormLocationsSection` | reuse | Route section |
| `EventFormDifficultySection` | reuse | Flame selector |
| `EventFormMultiBrandSection` | reuse | Multi-brand toggle |
| `EventFormEventTypeSection` | update | Pills radius 20, 6 types, 2 rows |
| `EventFormMaxParticipantsSection` | **new** | Stepper + header + hint |
| `EventFormPriceSection` | **new** | Price card + free checkbox |
| `EventFormBottomBar` | **extracted** | From `_FormBottomBar` in view |

---

## Copy (All New User-Visible Strings)

| Key | Spanish |
|---|---|
| `event_form_max_participants_section_title` | MÁXIMO DE PARTICIPANTES |
| `event_form_optional_badge` | Opcional |
| `event_form_max_participants_label` | Cupos disponibles |
| `event_form_max_participants_subtitle` | Deja vacío para no limitar inscritos |
| `event_form_max_participants_hint` | Una vez lleno el cupo, el evento aparece como 'Completo' automáticamente. |
| `event_form_price_section_title` | PRECIO DE INSCRIPCIÓN |
| `event_form_price_subtitle` | Precio de inscripción (COP) |
| `event_form_free_event_label` | Evento gratuito |
| `event_form_publish_action` | Publicar |
| `event_form_cancel_action` | Cancelar |

Note: `event_form_max_participants_label` already exists in ARB (value: "Máx. participantes") — update to "Cupos disponibles" or add a new key for the card label.

---

## Accessibility Checklist

- [ ] "Cancelar" and "Publicar" buttons have `Semantics` labels
- [ ] Stepper "–" and "+" buttons have `Tooltip`/`semanticsLabel` for screen readers
- [ ] Chip selection announces selected state
- [ ] Price input has appropriate `keyboardType: TextInputType.number`
- [ ] "Evento gratuito" checkbox has clear visual state (filled = checked)
- [ ] All text meets contrast ratio against dark backgrounds

---

## Notes for Frontend

1. **AppBar leading is a TextButton**, not an IconButton — use `TextButton("Cancelar")` in `leading:` slot with `automaticallyImplyLeading: false`.
2. **Two Rows for EventType chips** — use a `Column` with two `Row` children (or a `Wrap` with spacing=8, runSpacing=8); do NOT use a single flat `Wrap` since it may produce uneven rows.
3. **Stepper null semantics**: when `maxParticipants` is null in form state, display "–" in count frame; first "+" tap sets value to 5.
4. **Price AnimatedSize**: the price card collapses when "Evento gratuito" is checked — use `AnimatedSize` wrapping the price card widget with `SizedBox(height: isFree ? 0 : null)` child.
5. **One widget per file** — `EventFormBottomBar`, `EventFormMaxParticipantsSection`, `EventFormPriceSection` must each be their own file.
6. **Section order in `event_form_content.dart`**: Cover → BasicInfo → DateTime → Difficulty → Route → EventType → Brands → MaxParticipants → Price → (CTA is in bottom bar)
7. The Pencil frame does NOT show a `FormSectionTitle` widget for most sections — the sections use their own embedded headers (plain `Text` nodes, not the `FormSectionTitle` widget). Only RUTA and DIFICULTAD sections show a separate header row in the design. For TIPO DE EVENTO, MARCAS PERMITIDAS, MÁXIMO DE PARTICIPANTES, and PRECIO DE INSCRIPCIÓN, the header text is embedded inside the section's own layout.
