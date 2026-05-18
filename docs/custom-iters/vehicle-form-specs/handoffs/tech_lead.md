# Tech Lead Review — vehicle-form-specs

## Verdict
**ready_for_human_review**

Minor findings below (no blockers or majors). One dead file to remove on commit.

## Files Reviewed (vehicle-form-specs scope)

**Flutter (modified):**
- `lib/features/vehicles/domain/models/vehicle_model.dart`
- `lib/features/vehicles/data/dto/vehicle_dto.dart`
- `lib/features/vehicles/data/dto/vehicle_dto.g.dart`
- `lib/features/vehicles/constants/vehicle_form_fields.dart`
- `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`
- `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart`
- `lib/features/vehicles/presentation/form/vehicle_form_page.dart`
- `lib/l10n/app_es.arb`

**Flutter (new):**
- `lib/features/vehicles/presentation/form/vehicle_form_body.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_nav_header.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cover_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_scan_banner.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_basic_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_specs_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart`
- `lib/features/vehicles/presentation/form/widgets/vehicle_form_cta.dart`

**Backend (modified):**
- `rideglory-api/vehicles-ms/prisma/schema.prisma`
- `rideglory-api/vehicles-ms/prisma/migrations/20260516060904_add_vehicle_specs/migration.sql`
- `rideglory-api/rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts`
- `rideglory-api/vehicles-ms/src/vehicles/entities/vehicle.entity.ts`

**Not in vehicle-form-specs scope (pre-existing from maintenance-logic custom-iter):**
- All `maintenance` files in `lib/features/maintenance/`
- `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart`
- `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart`
- `lib/design_system/foundation/theme/app_colors*.dart`
- `lib/features/events/` modified files

## Findings

| File:Line | Severity | Issue | Required Fix |
|-----------|----------|-------|-------------|
| `lib/features/vehicles/presentation/widgets/vehicle_form.dart` | nit | Unreferenced file left in place | Delete before commit |
| `vehicle_form_specs_section.dart:43` | nit | Hardcoded `'Opcional'` string in spec section header badge | Add `vehicle_form_specs_optional` key to ARB and use `context.l10n` |
| `vehicle_form_docs_section.dart:29` | nit | Hardcoded `'Opcional'` string in docs section header badge | Same: already has `vehicle_form_vin_optional_label` — reuse or add generic |
| `vehicle_specs_row.dart:61` | minor | `FormBuilderField<String>` used as read-only display — this is slightly unusual but valid | Acceptable: no fix required, document rationale |

## Security Findings
- No secrets committed
- No SQL string concatenation (Prisma ORM used)
- No hardcoded URLs (API base URL resolved by existing DI pattern)
- Firebase Auth token injected by interceptor (no changes to auth flow)
- New spec fields are free-text strings — no injection risk (stored as text in Postgres)
- `engine/horsepower/torque/weight` have no length limits in DB or DTO; acceptable for optional metadata fields

## Architecture Adherence

| Check | Status | Note |
|-------|--------|------|
| Domain layer clean | pass | `vehicle_model.dart` has no Flutter/HTTP imports |
| Data layer clean | pass | No UI code in DTO/repository |
| Presentation clean | pass | No direct HTTP calls; only cubit/use case usage |
| 1 widget per file | pass | All new widget files contain exactly 1 exported widget class; `State<T>` co-located correctly |
| No `Widget _buildXxx()` methods | pass | Zero such methods in any new widget file |
| Shared widgets used | pass | `AppAutocompleteField`, `AppTextField`, `AppMileageField`, `AppDatePicker`, `AppButton` used where applicable |
| `FormBuilderTextField` direct use | acceptable | ID section uses direct `FormBuilderTextField` for `style` parameter (Space Mono font) — `AppTextField` doesn't expose `style` |
| l10n all strings | partial | 2 hardcoded "Opcional" strings (nit-level, see Findings) |
| `_vehicleRequest()` updated | pass | All 4 new fields added to API request map |
| `buildVehicleToSave()` updated | pass | All 4 new fields mapped from form data |
| Spec fields in `_buildInitialValues()` | pass | All 4 spec fields added to initial values for edit mode |
| `Object.hashAll` for 21-field hash | pass | Correctly uses `Object.hashAll` instead of `Object.hash` (max 20) |

## Test Adequacy

| AC | Coverage | Verdict |
|----|---------|---------|
| AC-7: dart analyze | `dart analyze` — 0 errors in vehicle files | pass |
| AC-8: build_runner | Verified — 30 outputs, 0 errors | pass |
| AC-10: l10n strings | Grepped — 2 hardcoded "Opcional" strings (nit) | minor gap |
| AC-1 through AC-9 | No widget tests for vehicle form exist; requires manual verification | needs_human_verify |

## Regression Risk Summary
**needs_human_verify** — The form is a fully rewritten UI with 11 new widget files. The automated test coverage for vehicle form is zero (no widget tests). The manual probes in `qa.md` must be run before commit.

Key risk: `VehicleSpecsRow` uses `FormBuilderField<String>` in read-only display mode — this is an unusual usage. Verify that the value is correctly preserved when toggling between edit and display modes.

## Manual Probes the Human Must Run Before Commit

From QA handoff § Manual Probes (execute in priority order):
1. Spec inline edit → submit → reopen edit mode → specs pre-filled (AC-2, AC-9)
2. Submit form with empty specs → no error (AC-3)
3. Placa: "Obligatorio" chip visible; monospace font (AC-4)
4. VIN: "Opcional" label visible; monospace font (AC-5)
5. Nav header: Cancelar/Title/Guardar pattern (AC-1)
6. ESPECIFICACIONES section visible with 4 rows in a card (AC-1)
7. Edit mode: "Eliminar vehículo" link visible at bottom

## Limitations / Known Edge Cases
1. **Space Mono font via google_fonts**: The font is downloaded at runtime. On first run without internet, the field will fall back to the default font. Not a bug for this iteration.
2. **`VehicleSpecsRow` focus**: When multiple spec rows are edited in sequence, the `onFocusChanged` listener dismisses inline edit on focus loss. Edge case: if user taps another spec row while one is open, both may be in edit mode briefly. Acceptable for this iteration.
3. **`vehicle_form.dart` dead file**: The old monolithic widget file remains in `lib/features/vehicles/presentation/widgets/`. It is unreferenced and doesn't cause errors, but should be deleted when committing.
4. **Pre-existing maintenance errors**: These are from the `maintenances-logic` custom-iter run and are not related to this feature. They will need to be committed separately.

## Recommended Commit Message

```
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
```
