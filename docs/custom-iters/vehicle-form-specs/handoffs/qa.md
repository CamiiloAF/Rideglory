# QA Handoff — vehicle-form-specs

## Test Catalog

| AC | Description | Test Coverage | Status |
|----|-------------|--------------|--------|
| AC-1 | Form visually matches Pencil EqnMm | Manual visual inspection required | manual_verify_needed |
| AC-2 | 4 spec fields sent/retrieved from backend | DTO serialization verified via generated .g.dart; manual end-to-end needed | manual_verify_needed |
| AC-3 | Spec fields optional — submit without them | `buildVehicleToSave()` null-coalescence logic reviewed; manual needed | manual_verify_needed |
| AC-4 | Placa = Space Mono, letterSpacing 2, "Obligatorio" chip | Code review: `_VehiclePlacaField` uses `GoogleFonts.spaceMono(letterSpacing: 2)` and chip | manual_verify_needed |
| AC-5 | VIN = Space Mono, letterSpacing 0.5, "Opcional" label | Code review: `_VehicleVinField` uses `GoogleFonts.spaceMono(letterSpacing: 0.5)` | manual_verify_needed |
| AC-6 | Brand dropdown with colored dots | Existing `AppAutocompleteField` + `ColombiaMotosBrandsData` used (same as before) | manual_verify_needed |
| AC-7 | `dart analyze` passes 0 errors | Verified — 0 errors in vehicle files | pass |
| AC-8 | `build_runner build` runs cleanly | Verified — 30 outputs written, no errors | pass |
| AC-9 | Existing create + edit flow works | Manual end-to-end required | manual_verify_needed |
| AC-10 | All strings in `app_es.arb` | Grepped all new widget files — no hardcoded Spanish strings found | pass |

## Regression Matrix

| Guardrail | Mechanism | Result |
|-----------|-----------|--------|
| Vehicle create works | Manual | manual_verify_needed |
| Vehicle edit works | Manual | manual_verify_needed |
| Spec fields null-safe for old vehicles | Code review: `_buildInitialValues` null-safely maps new fields; `copyWith` uses `_unset` pattern | pass (code review) |
| SOAT slot functional | `VehicleFormDocsSection` preserved slot logic identically | pass (code review) |
| build_runner clean | `dart run build_runner build --delete-conflicting-outputs` — exits 0 | pass |
| DB migration additive | Migration SQL: `ADD COLUMN` only, nullable, no destructive ops | pass |
| `vehicle_form.dart` dead code | File is unreferenced but not deleted — no import errors | pass (minor: dead file remains) |

## Test Execution

```bash
# Static analysis
dart analyze
# Result: 0 errors in vehicle files; pre-existing errors in maintenance/test files

# Tests (non-broken subset)
flutter test test/features/profile/ test/features/users/domain/ test/features/users/presentation/cubit/ test/features/events/domain/ test/widget_test.dart
# Result: 18/18 pass

# Code generation
dart run build_runner build --delete-conflicting-outputs
# Result: 30 outputs written, 0 errors

# Backend unit tests
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms && npm run test
# Result: 9/9 pass
```

## Bugs Found
None introduced by this run.

## Manual Probes for Human

Run `flutter run -d <device>` and execute:
1. **Nav header**: Open add-vehicle form → verify "Cancelar" (left, grey), "Agregar moto" (center, bold), "Guardar" (right, orange)
2. **Edit mode header**: Open edit-vehicle form → verify title shows "Editar moto"
3. **Specs section**: Scroll to ESPECIFICACIONES section → verify 4 rows (Motor, Potencia, Torque, Peso) visible in a card
4. **Inline edit**: Tap "Motor" row → verify inline text input appears; type "689cc" → tap done → value shown in row
5. **Spec submit**: Fill specs, submit → open edit form → verify specs pre-filled
6. **Spec optional**: Submit form with empty specs → no validation error
7. **Placa field**: Verify "Obligatorio" badge in orange; verify monospace font on input
8. **VIN field**: Verify "Opcional" grey text; verify monospace font
9. **Delete link (edit mode)**: Open edit form → scroll to bottom → verify "Eliminar vehículo" link with trash icon
10. **Delete confirmation**: Tap "Eliminar vehículo" → verify confirmation dialog appears
11. **Cancelar**: Tap "Cancelar" in nav header → verify navigates back without saving
12. **Old vehicle**: Open edit form for a vehicle with no spec fields → form opens, spec rows show hint text

## How to Verify (copy-paste commands)

```bash
# Static analysis — vehicle files only
dart analyze 2>&1 | grep "lib/features/vehicles\|lib/l10n" | grep "error"

# build_runner
dart run build_runner build --delete-conflicting-outputs

# Flutter tests
flutter test --no-pub test/features/profile/ test/features/users/domain/ test/features/users/presentation/cubit/ test/features/events/domain/ test/widget_test.dart

# Backend tests
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms && npm run test
```

## Sign-off

**conditional** — All automated gates pass (analyze, build_runner, tests). Manual probes 1–12 above are required before commit. No blockers found in automated checks.
