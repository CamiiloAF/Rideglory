# § 1 Title

Event Form — Full Redesign to Pencil Frame `zbCa0` + EventType Enum Expansion

---

# § 2 Goal

Redesign `event_form_page.dart` (and all its section widgets) to be visually identical to Pencil frame `zbCa0` ("Crear Evento"), and expand the `EventType` enum from 4 values to the 6 values shown in the design. Also add the missing `maxParticipants` field that appears in the design's "Máximo de Participantes" section.

---

# § 3 Type and Severity

- **Type:** feature + redesign
- **Severity:** high — `EventType` enum expansion is a **breaking change**: all existing events with old enum values (`OFF_ROAD`, `ON_ROAD`, `EXHIBITION`, `CHARITABLE`) must be migrated to the new values in the Prisma migration SQL. Coordinate mobile + backend release.

---

# § 4 Pencil Frame Reference

| Frame ID | Name | File |
|---|---|---|
| `zbCa0` | Crear Evento | `lib/features/events/presentation/form/event_form_page.dart` |

**Frame structure (top → bottom):**

1. **Header Bar** — "Cancelar" text button (left, text-secondary), "Nuevo Evento" title (center, bold), "Publicar" accent text button (right, accent color). No back arrow — modal-style presentation.
2. **Cover Section** — 160px tall placeholder (bg-secondary, dashed border `$border-light`), image icon (text-tertiary), "Agregar portada del evento" text, "Imagen principal de la rodada" subtitle. Two buttons below: "Subir foto" (bg-tertiary + border) + "Generar con IA" (accent-subtle bg + accent border). This section already exists; update styling to match.
3. **INFORMACIÓN BÁSICA section**
   - Nombre field — card (bg-secondary, border), name label row with pencil icon, placeholder "Ej. Rodada Nocturna — Ruta del Café"
   - Descripción field — card (bg-secondary, border), rich text toolbar row, divider, placeholder text 80px tall
4. **FECHA Y HORA section**
   - Fecha Inicio + Fecha Fin — two equal-width cards side by side, 10px gap
   - Hora field — full-width card below
5. **RUTA section**
   - Route Card (bg-card, border): green dot (success) + origin waypoint row, divider, orange dot (accent) + destination waypoint row, map preview strip (130px tall, bg-primary, accent-colored SVG route, origin/dest dots)
6. **DIFICULTAD section**
   - Flame Selector card (bg-card, border): top row with flame icons + current level text, subtitle description
7. **TIPO DE EVENTO section**
   - Section header: "TIPO DE EVENTO", 11px, letterSpacing 0.8, text-tertiary
   - Pill chips in 2 rows (3 + 3), `cornerRadius: 20`, gap 8:
     - Row 1: Turismo · Urbana · Off-road
     - Row 2: Competición · Solidaria · Corta distancia
   - Selected chip: `$accent` fill, white bold text (w600→inverse color)
   - Unselected chip: `$bg-card` fill, border `$border`, text-secondary, w500
8. **MARCAS PERMITIDAS section**
   - Toggle row card (bg-card, border, cornerRadius 12): brand label + subtitle (left) + toggle switch (right, accent track)
   - Hint row (bg-secondary, cornerRadius 10, info icon + hint text)
9. **MÁXIMO DE PARTICIPANTES section** ← new
   - Section header row: "MÁXIMO DE PARTICIPANTES" + "Opcional" badge chip (bg-tertiary, cornerRadius 10)
   - Max card (bg-card, border, cornerRadius 12): label + subtitle (left) + stepper widget (bg-tertiary, minus/number/plus, cornerRadius 10) (right)
   - Hint text: users icon + "Una vez lleno el cupo, el evento aparece como 'Completo' automáticamente."
10. **PRECIO DE INSCRIPCIÓN section**
    - Section header row: "PRECIO DE INSCRIPCIÓN" + "Opcional" badge chip
    - Price input card (bg-card, border, cornerRadius 12, height 52): "$" symbol (18px, w600, text-tertiary) + vertical divider + amount text input
    - "Evento gratuito" row: checkbox (accent, 18x18, cornerRadius 4) + "Evento gratuito" label (text-secondary, 13px, w500)
11. **CTA Area**
    - "Publicar evento" primary button (accent, 56px, cornerRadius 28, send icon left)
    - "Guardar como borrador" text link (text-tertiary, 13px, archive icon left, centered)

---

# § 5 Enum & Field Changes (Backend + Mobile)

## 5.1 EventType Enum — Breaking Change

**Current values → New values:**

| Old (current) | New | Display label |
|---|---|---|
| `OFF_ROAD` | `TOURISM` | Turismo |
| `ON_ROAD` | `URBAN` | Urbana |
| `EXHIBITION` | `OFF_ROAD` | Off-road |
| `CHARITABLE` | `COMPETITION` | Competición |
| — | `SOLIDARITY` | Solidaria |
| — | `SHORT_DISTANCE` | Corta distancia |

> Note: `OFF_ROAD` is reused (same name, different semantics) — the rename of the old `OFF_ROAD` to `TOURISM` requires a data migration.

### 5.1.1 Backend — `rideglory-api` (events-ms)

Repo path: `/Users/cami/Developer/Personal/rideglory-api/events-ms`

**Files to modify:**

- `prisma/schema.prisma` — replace `EventType` enum block:
  ```prisma
  enum EventType {
    TOURISM
    URBAN
    OFF_ROAD
    COMPETITION
    SOLIDARITY
    SHORT_DISTANCE
  }
  ```
- **Reset DB and regenerate** — drop all data and apply a clean migration:
  ```bash
  npx prisma migrate reset --force
  npx prisma migrate dev --name expand_event_type_enum
  ```
  No data migration SQL needed — dev database is wiped clean.

### 5.1.2 Mobile — Flutter

**`lib/features/events/domain/model/event_model.dart`** — replace `EventType` enum:
```dart
enum EventType {
  tourism('Turismo'),
  urban('Urbana'),
  offRoad('Off-road'),
  competition('Competición'),
  solidarity('Solidaria'),
  shortDistance('Corta distancia');

  final String label;
  const EventType(this.label);
}
```

**`lib/features/events/data/dto/event_dto.dart`** — update `@JsonValue` annotations on `EventType` to match new backend string values (`TOURISM`, `URBAN`, `OFF_ROAD`, `COMPETITION`, `SOLIDARITY`, `SHORT_DISTANCE`).

## 5.2 MaxParticipants Field — New Optional Field

### 5.2.1 Backend

**`prisma/schema.prisma`** — add to `Event` model:
```prisma
maxParticipants  Int?
```

Run migration: `npx prisma migrate dev --name add_max_participants`

No service logic changes needed (field passes through automatically). Event list/detail views should show "Completo" badge when registrations count >= maxParticipants — that logic is out of scope for this iteration.

### 5.2.2 Mobile

**`lib/features/events/domain/model/event_model.dart`** — add `final int? maxParticipants;`, update `copyWith()`.

**`lib/features/events/data/dto/event_dto.dart`** — add `@JsonKey(name: 'maxParticipants') final int? maxParticipants;`, regenerate.

**`lib/features/events/constants/event_form_fields.dart`** — add constant `static const maxParticipants = 'maxParticipants';`.

**`lib/features/events/presentation/form/cubit/event_form_cubit.dart`** — include `maxParticipants` in form state mapping and submit payload.

---

# § 6 Affected Flutter Files

| File | Change |
|---|---|
| `lib/features/events/domain/model/event_model.dart` | Replace EventType enum (6 values) + add maxParticipants field |
| `lib/features/events/data/dto/event_dto.dart` | Update @JsonValue mappings + add maxParticipants |
| `lib/features/events/constants/event_form_fields.dart` | Add maxParticipants constant |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Map maxParticipants on load + submit |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Restructure section order, add new sections |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | Redesign AppBar to modal style (Cancelar / title / Publicar) |
| `lib/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart` | Redesign chips to pill shape (cornerRadius 20), update to 6 types |
| New `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | New stepper widget for maxParticipants |
| New `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` | Price card + "Evento gratuito" checkbox |
| `lib/l10n/app_es.arb` | Add l10n keys for new labels |

---

# § 7 NOT in Scope

- "Guardar como borrador" actual draft logic — show as tappable UI placeholder (`onTap: () {}`)
- Capacity enforcement ("Completo" badge when full) — backend event list/detail changes
- Route map preview rendering — existing map widget is preserved as-is
- Changes to event list, event detail, or event registration screens
- AI cover generation changes — existing `generateCover()` logic is preserved
- Event state transitions (the new "Publicar" button in the header calls the same submit as the current form)

---

# § 8 Acceptance Criteria

1. `event_form_page.dart` and all its section widgets render visually identical to Pencil frame `zbCa0`.
2. The EventType chips are pill-shaped (cornerRadius 20), 6 values, 2 rows of 3.
3. Selected chip uses accent fill with white text; unselected uses bg-card + border.
4. The 6 new EventType values are correctly sent to / received from the backend after enum migration.
5. `maxParticipants` field is optional, sent as `null` when not set, and loaded correctly in edit mode.
6. Price section shows "$" symbol card + "Evento gratuito" checkbox; checking the box clears/nulls the price.
7. AppBar shows "Cancelar" (left) | "Nuevo Evento" / "Editar Evento" (center) | "Publicar" accent text (right).
8. `dart analyze` passes with 0 errors after all changes.
9. `dart run build_runner build` runs cleanly with no conflicts.
10. Existing event create + edit flow works end-to-end after enum migration.
11. All new user-visible strings are in `lib/l10n/app_es.arb`.

---

# § 9 Regression Guardrails

| Area | Guardrail |
|---|---|
| Event create / edit | Form submits successfully in both create and edit mode |
| AI cover generation | `generateCover()` still triggers and returns a URL |
| Route map preview | Origin/destination inputs still populate the map preview |
| Difficulty selector | Flame selector still sets difficulty on submit |
| Multi-brand toggle | allowedBrands still correctly populated on submit |

---

# § 10 Open Questions

1. **MaxParticipants stepper range**: What are the min/max allowed values for the stepper? Recommend min=5, max=500, step=5, with direct text input also allowed.
3. **"Evento gratuito" checkbox behavior**: When checked, should the price input be hidden or just disabled/greyed out? Recommend hidden (AnimatedSize collapse).
4. **"Cancelar" action**: In create mode this pops the form without saving. In edit mode should it show a discard confirmation dialog? Recommend yes if any field has been modified.
