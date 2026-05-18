# § 1 Title

Vehicle Form — Specs Fields + Full Redesign to Pencil Frame `EqnMm`

---

# § 2 Goal

Redesign `vehicle_form_page.dart` to be visually identical to Pencil frame `EqnMm` ("Agregar / Editar Moto"), and add the four new optional specs fields (engine, horsepower, torque, weight) that appear in the design but are missing from the data model and backend.

---

# § 3 Type and Severity

- **Type:** feature + redesign
- **Severity:** high — adds fields that require a coordinated mobile + backend change; no breaking changes to existing vehicle data (all new fields are nullable/optional)

---

# § 4 Pencil Frame Reference

| Frame ID | Name | File |
|---|---|---|
| `EqnMm` | Agregar / Editar Moto | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` |

**Frame structure (top → bottom):**

1. **Status Bar + Nav Header** — back button (left), title "Agregar moto" / "Editar moto" (center), optional delete link (right on edit)
2. **Cover Section** — 160px tall cover photo placeholder with camera icon, "Agregar foto de portada" text, two buttons: "Subir foto" + "Tomar foto"
3. **Scan Card Banner** (accent-subtle, accent border) — scan icon, "Escanear tarjeta de propiedad", chevron-right; tapping opens camera to auto-fill fields
4. **INFORMACIÓN BÁSICA section**
   - Marca field — searchable dropdown with brand color dots (Honda red, Yamaha blue, Kawasaki green, BMW blue, KTM orange). Shows open dropdown in design.
   - Modelo field — plain text input
   - Año field — text input with calendar icon on right
   - Color field — text input with color swatch circle on left (live preview of entered hex/name)
5. **Divider**
6. **IDENTIFICACIÓN section**
   - Placa field — monospace font (Space Mono), "Obligatorio" badge chip, uppercase placeholder "ABC-123"
   - VIN / No. de Serie field — monospace font (Space Mono), "Opcional" label, uppercase placeholder
7. **ESPECIFICACIONES section** ← new
   - Section header: "ESPECIFICACIONES" + "Opcional" badge + "Buscar" AI button (accent-subtle, sparkles icon)
   - Card with 4 inline editable rows separated by dividers:
     - Motor: label left, value right (e.g. "689cc · Paralelo 2 cil."), pencil icon
     - Potencia: label left, value right ("73 hp"), pencil icon
     - Torque: label left, value right ("68 Nm"), pencil icon
     - Peso: label left, value right ("179 kg"), pencil icon
   - Each row taps to open an inline text input replacing the value
8. **Docs Section**
   - Section header: "DOCUMENTOS"
   - SOAT slot card (already exists)
   - Revisión Técnica slot card ← new (same style as SOAT, but for tech review)
   - "Agregar documento" slot (dashed border, text-tertiary)
9. **CTA Area**
   - "Guardar moto" primary button (accent, 56px height, cornerRadius 28)
   - "Eliminar moto" destructive link (error color, only shown in edit mode)

---

# § 5 New Fields (Backend + Mobile)

## 5.1 Backend — `rideglory-api`

Repo path: `/Users/cami/Developer/Personal/rideglory-api`

Add the following nullable optional columns to the `Vehicle` entity and DTO:

| Field | Type | Description |
|---|---|---|
| `engine` | `String \| null` | Engine displacement + config (e.g. "689cc · Paralelo 2 cil.") |
| `horsepower` | `String \| null` | Power output (e.g. "73 hp") |
| `torque` | `String \| null` | Torque output (e.g. "68 Nm") |
| `weight` | `String \| null` | Dry weight (e.g. "179 kg") |

All stored as `varchar` / `text`, nullable, no default. No migration data backfill needed.

**Files to modify in rideglory-api:**
- `src/vehicles/entities/vehicle.entity.ts` — add 4 nullable `@Column` fields
- `src/vehicles/dto/create-vehicle.dto.ts` — add optional fields with `@IsOptional() @IsString()`
- `src/vehicles/dto/update-vehicle.dto.ts` — same (or inherits via PartialType)
- TypeORM migration: `npx typeorm migration:generate` after entity change
- `src/vehicles/vehicles.service.ts` — include new fields in create/update mapping

## 5.2 Mobile — Flutter

**Domain model** `lib/features/vehicles/domain/models/vehicle_model.dart`:
- Add 4 nullable `String?` fields: `engine`, `horsepower`, `torque`, `weight`
- Update `copyWith()`

**DTO** `lib/features/vehicles/data/dto/vehicle_dto.dart`:
- Add 4 nullable `@JsonKey` fields matching backend field names
- Regenerate with `dart run build_runner build --delete-conflicting-outputs`

**Form fields** `lib/features/vehicles/constants/vehicle_form_fields.dart`:
- Add constants: `engine`, `horsepower`, `torque`, `weight`

**Form cubit** `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart`:
- Include new fields in form state mapping and submit payload

---

# § 6 Affected Flutter Files

| File | Change |
|---|---|
| `lib/features/vehicles/domain/models/vehicle_model.dart` | Add 4 spec fields + copyWith |
| `lib/features/vehicles/data/dto/vehicle_dto.dart` | Add 4 nullable JSON fields |
| `lib/features/vehicles/constants/vehicle_form_fields.dart` | Add 4 field name constants |
| `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | Map new fields on load + submit |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Full redesign to Pencil frame |
| New widgets under `lib/features/vehicles/presentation/form/widgets/` | New section widgets per coding standards (1 widget per file) |
| `lib/l10n/app_es.arb` | Add l10n keys for new labels/placeholders |

---

# § 7 NOT in Scope

- Scan card banner actual OCR/camera functionality (show as tappable UI placeholder — `onTap: () {}`)
- "AI search" button on specs section (show as tappable placeholder)
- "Revisión Técnica" document slot actual upload/storage logic (show slot UI only, no backend endpoint)
- "Agregar documento" generic slot (UI only, no action)
- Changes to vehicle list, vehicle detail, or any other vehicle screen
- Changes to `rideglory-api` beyond the 4 new nullable string columns

---

# § 8 Acceptance Criteria

1. `vehicle_form_page.dart` renders visually identical to Pencil frame `EqnMm` — same layout, colors, typography, spacing.
2. The 4 spec fields (engine, horsepower, torque, weight) are sent to and retrieved from the backend.
3. Spec fields are optional — form submits successfully when left empty.
4. Placa field uses monospace font (Space Mono) and shows "Obligatorio" chip.
5. VIN field uses monospace font (Space Mono) and shows "Opcional" text.
6. Brand field shows searchable dropdown with brand color dots matching the design.
7. `dart analyze` passes with 0 errors after all changes.
8. `dart run build_runner build` runs cleanly with no conflicts.
9. Existing vehicle form submit (create + edit) continues to work end-to-end.
10. All new user-visible strings are in `lib/l10n/app_es.arb`.

---

# § 9 Regression Guardrails

| Area | Guardrail |
|---|---|
| Vehicle form submit | Create and edit vehicle both complete without crash |
| Vehicle list / detail | Vehicles already saved without spec fields still display correctly (null-safe) |
| SOAT slot | Existing SOAT document slot remains functional |
| Build runner | `vehicle_dto.dart` regenerates without conflicts |

---

# § 10 Open Questions

1. **Brand dropdown data source**: Should the brand list be hardcoded (Honda, Yamaha, Kawasaki, BMW, KTM, Suzuki, Ducati, Royal Enfield, etc.) or fetched from an API endpoint? Recommend hardcoded list for this iteration.
2. **Color swatch**: The design shows a circle that previews the color as the user types. Should this be a live HEX preview, or just a static grey swatch? Recommend static grey swatch for now.
3. **Spec row inline edit**: The design shows each spec row as tappable (pencil icon). Should tapping open a modal, an inline text field replacing the value, or navigate to a dedicated edit screen? Recommend inline text field.
