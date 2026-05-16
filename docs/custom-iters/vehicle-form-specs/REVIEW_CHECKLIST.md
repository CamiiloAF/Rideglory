# Review Checklist — vehicle-form-specs

**Run**: 2026-05-16  
**Workspace**: `docs/custom-iters/vehicle-form-specs/`  
**Scope**: Vehicle form redesign (Pencil frame EqnMm) + 4 spec fields (engine, horsepower, torque, weight) end-to-end  
**Tech Lead verdict**: ready_for_human_review  
**QA sign-off**: conditional (manual probes required)

---

## Step 1 — Review the diff

```bash
cd /Users/cami/Developer/Personal/Rideglory
git diff --stat
git diff lib/features/vehicles/
git diff lib/l10n/app_es.arb
```

**Vehicle files changed:**
- `lib/features/vehicles/domain/models/vehicle_model.dart` — 4 new fields
- `lib/features/vehicles/data/dto/vehicle_dto.dart` — 4 new fields + toModel()
- `lib/features/vehicles/constants/vehicle_form_fields.dart` — 4 new constants
- `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` — `_vehicleRequest()` updated
- `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` — `buildVehicleToSave()` updated
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart` — full redesign

**New files created:**
- `lib/features/vehicles/presentation/form/vehicle_form_body.dart`
- `lib/features/vehicles/presentation/form/widgets/` (10 widget files)

**Backend (separate repo):**
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
git diff --stat
git status
```
Changed: `prisma/schema.prisma`, `src/vehicles/entities/vehicle.entity.ts`  
New: `prisma/migrations/20260516060904_add_vehicle_specs/migration.sql`  
Changed in contracts: `rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts`

---

## Step 2 — Run automated checks

```bash
cd /Users/cami/Developer/Personal/Rideglory

# Static analysis (expect 0 errors in vehicle files)
dart analyze 2>&1 | grep "lib/features/vehicles\|lib/l10n" | grep "error"

# Build runner (expect clean)
dart run build_runner build --delete-conflicting-outputs

# Tests (expect 18 pass)
flutter test --no-pub test/features/profile/ test/features/users/domain/ test/features/users/presentation/cubit/ test/features/events/domain/ test/widget_test.dart
```

```bash
# Backend tests
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npm run test
# Expect: 9/9 pass
```

---

## Step 3 — Check Tech Lead findings

From `docs/custom-iters/vehicle-form-specs/handoffs/tech_lead.md`:

- [ ] **nit**: Delete `lib/features/vehicles/presentation/widgets/vehicle_form.dart` (dead file, unreferenced)
- [ ] **nit**: Replace hardcoded `'Opcional'` string in `vehicle_form_specs_section.dart:43` with `context.l10n` key
- [ ] **nit**: Replace hardcoded `'Opcional'` string in `vehicle_form_docs_section.dart:29` with `context.l10n` key

These are nits — your call whether to fix before committing.

---

## Step 4 — Visual review in Pencil

Open `rideglory.pen` in Pencil and compare frame `EqnMm` against the running app:

```bash
# Open app on simulator
flutter run -d <simulator_id>
```

Key comparison points:
- Nav header height/padding/fonts
- ESPECIFICACIONES card with 4 rows
- Placa/VIN monospace fonts and labels
- CTA button (56px, cornerRadius 28, orange)
- Delete link (edit mode only, trash icon)

---

## Step 5 — Manual probes (run on device/simulator)

Priority order:

| # | Probe | Expected |
|---|-------|---------|
| 1 | Open add-vehicle form | Nav: "Cancelar" / "Agregar moto" / "Guardar" visible |
| 2 | Open edit-vehicle form | Title shows "Editar moto" |
| 3 | Scroll to ESPECIFICACIONES | 4 rows in a card: Motor, Potencia, Torque, Peso |
| 4 | Tap "Motor" row | Inline text input appears |
| 5 | Type "689cc" in Motor, tap Done | Value shown in row as "689cc" |
| 6 | Submit form with all spec fields filled | Vehicle saved; no error |
| 7 | Open edit form for vehicle just created | Spec fields pre-filled with "689cc" etc. |
| 8 | Submit form with empty specs | No validation error; vehicle saved |
| 9 | Verify Placa field | "Obligatorio" orange chip + monospace font |
| 10 | Verify VIN field | "Opcional" grey label + monospace font |
| 11 | Open edit form | "Eliminar vehículo" link with trash icon at bottom |
| 12 | Tap "Eliminar vehículo" | Confirmation dialog appears |
| 13 | Tap "Cancelar" in nav | Navigates back without saving |
| 14 | Open edit form for old vehicle (no specs) | Form opens without crash; spec rows show hint text |

---

## Step 6 — Commit (if accepted)

**Before committing**, optionally fix the 3 nit items above.

Then commit with:
```bash
cd /Users/cami/Developer/Personal/Rideglory
git add lib/features/vehicles/ lib/l10n/ docs/custom-iters/vehicle-form-specs/
git commit -m "$(cat <<'EOF'
feat: redesign vehicle form to Pencil frame + add spec fields (engine/hp/torque/weight)

- Vehicle form fully redesigned to match Pencil frame EqnMm: Pencil nav header
  (Cancelar/Title/Guardar), ESPECIFICACIONES section with 4 inline-editable rows,
  Placa/VIN monospace fonts (Space Mono), delete link in edit mode
- Add engine, horsepower, torque, weight optional string fields end-to-end:
  Prisma schema migration, NestJS contracts DTO, Flutter domain model, DTO,
  form cubit, repository request builder
- Split monolithic vehicle_form.dart into 10 single-responsibility widget files
  per coding standards (1 widget per file rule)
- Add 15 new l10n keys for specs section, nav header, Placa badge, VIN label

Backend: rideglory-api/vehicles-ms Prisma migration 20260516060904_add_vehicle_specs

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

For the backend:
```bash
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
git add prisma/schema.prisma prisma/migrations/20260516060904_add_vehicle_specs/ src/vehicles/entities/vehicle.entity.ts

cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
git add src/vehicles/dto/create-vehicle.dto.ts
```

---

## Step 7 — Reject (if not accepted)

```bash
# Discard all Flutter changes
cd /Users/cami/Developer/Personal/Rideglory
git restore lib/features/vehicles/ lib/l10n/
rm -rf lib/features/vehicles/presentation/form/widgets/ lib/features/vehicles/presentation/form/vehicle_form_body.dart

# Discard backend changes
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
git restore prisma/schema.prisma src/vehicles/entities/vehicle.entity.ts

cd /Users/cami/Developer/Personal/rideglory-api/rideglory-contracts
git restore src/vehicles/dto/create-vehicle.dto.ts

# Remove workspace (optional)
# rm -rf /Users/cami/Developer/Personal/Rideglory/docs/custom-iters/vehicle-form-specs/
```

---

## Optional Follow-ups

From Tech Lead and Architect handoffs — NOT in this run's scope:

1. **Add widget tests for `VehicleFormPage`** — Currently zero widget tests for the form; recommended for next iteration
2. **Fix `vehicle_form.dart` dead file** — Delete if not already done at commit time
3. **`VehicleSpecsRow` edge case** — Two rows simultaneously in edit mode (minor UX quirk, not a bug)
4. **Brand dropdown colored dots** — The PRD spec shows colored dots per brand in the dropdown. The current `AppAutocompleteField` renders text-only suggestions. Enhancing the suggestion row with a brand color dot is a UI polish improvement for a future iteration
5. **Color swatch preview** — PRD recommended static grey; live hex preview deferred
6. **Scan card OCR** — UI placeholder only in this run; implement in future
7. **AI "Buscar" button** — UI placeholder only; implement in future
