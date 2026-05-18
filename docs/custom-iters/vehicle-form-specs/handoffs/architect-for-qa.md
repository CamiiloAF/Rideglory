> Slim handoff for /custom-iter vehicle-form-specs. Full detail in architect.md (read only if ambiguous).

# QA Handoff — vehicle-form-specs

## What to verify

### Acceptance Criteria Coverage
| AC | Test Mechanism |
|----|---------------|
| AC-1: Form visually matches Pencil EqnMm | Manual visual inspection |
| AC-2: Spec fields sent/retrieved from backend | API call inspection + manual form test |
| AC-3: Spec fields optional — submit without them | Manual form test (leave spec section empty) |
| AC-4: Placa = Space Mono, letterSpacing 2, "Obligatorio" chip | Widget inspection + visual |
| AC-5: VIN = Space Mono, letterSpacing 0.5, "Opcional" label | Widget inspection + visual |
| AC-6: Brand shows colored dot dropdown | Manual interaction |
| AC-7: dart analyze passes 0 errors | `dart analyze` command |
| AC-8: build_runner runs cleanly | `dart run build_runner build --delete-conflicting-outputs` |
| AC-9: Existing create + edit flow works | Manual end-to-end test |
| AC-10: All strings in app_es.arb | Grep for hardcoded strings |

### Regression Guardrails
| Guardrail | How to verify |
|-----------|--------------|
| Vehicle create works | Create new vehicle with no spec fields → saved |
| Vehicle edit works | Edit existing vehicle → saved |
| Spec fields null-safe | Edit old vehicle (no spec fields in DB) → form opens without crash |
| SOAT slot functional | Tap upload SOAT → file picker opens |
| build_runner clean | Command exits 0 |
| Backend migration | Migration SQL has only ADD COLUMN statements (no destructive ops) |

### Commands to run
```bash
# Static analysis
cd /Users/cami/Developer/Personal/Rideglory
dart analyze

# Tests
flutter test

# Code generation check
dart run build_runner build --delete-conflicting-outputs

# Backend e2e (if backend agent ran)
cd /Users/cami/Developer/Personal/rideglory-api/vehicles-ms
npm run test:e2e
```

### Manual verification steps
1. Run `flutter run` on the app
2. Navigate to Vehicles → Add vehicle
3. Verify nav header shows "Cancelar" / "Agregar moto" / "Guardar"
4. Verify ESPECIFICACIONES section is visible with 4 rows
5. Tap a spec row → inline edit opens
6. Fill engine, horsepower, torque, weight
7. Submit form → vehicle created
8. Reopen vehicle in edit mode → spec fields pre-filled
9. Clear all spec fields → submit → no error (optional fields)
10. Verify Placa field shows "Obligatorio" chip and uses monospace font
11. Verify VIN field shows "Opcional" label and uses monospace font
