# PRD Normalized — Vehicle Form Specs Fields + Full Redesign

## § 1 Title
Vehicle Form — Specs Fields + Full Redesign to Pencil Frame `EqnMm`

## § 2 Goal
Redesign `vehicle_form_page.dart` to be visually identical to Pencil frame `EqnMm` ("Agregar / Editar Moto"), and add four new optional specs fields (engine, horsepower, torque, weight) to both the Flutter data model and the NestJS backend.

## § 3 Type and Severity
- **Type:** feature_addition + redesign
- **Severity:** high — coordinated mobile + backend change; all new fields are nullable/optional; no breaking changes to existing vehicle data

## § 4 Affected Areas

| File | Current State | Change |
|------|--------------|--------|
| `lib/features/vehicles/domain/models/vehicle_model.dart` | 18 fields, no spec fields | Add 4 nullable String? fields + copyWith |
| `lib/features/vehicles/data/dto/vehicle_dto.dart` | Mirrors model, no spec fields | Add 4 nullable @JsonKey fields |
| `lib/features/vehicles/constants/vehicle_form_fields.dart` | 10 constants | Add 4 constants: engine, horsepower, torque, weight |
| `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | buildVehicleToSave() doesn't map spec fields | Add mapping for 4 spec fields in form submit |
| `lib/features/vehicles/presentation/widgets/vehicle_form.dart` | Monolithic widget file with multiple classes | Full redesign; extract per-section widgets to `form/widgets/` per coding standards |
| `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Has Scaffold, AppBar, BlocListener, SingleChildScrollView wrapping VehicleForm | Keep page structure; delete-link for edit mode |
| `lib/l10n/app_es.arb` | Missing: specs section labels, placa badge, VIN label, delete link | Add new l10n keys |
| `rideglory-api/rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts` | No spec fields | Add 4 optional @IsString() fields |
| `rideglory-api/vehicles-ms/prisma/schema.prisma` | No spec fields on Vehicle model | Add 4 nullable String? columns |
| `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.ts` | create/update use spread ...rest | Spread already covers new fields automatically |

## § 5 Decisions Made
1. **Brand dropdown**: Keep existing `AppAutocompleteField` with `ColombiaMotosBrandsData`. Pencil shows colored brand dots — implement as leading colored dot per brand row in existing autocomplete suggestion items.
2. **Color swatch**: Static grey swatch (no live HEX preview). Color field is a plain AppTextField.
3. **Spec row inline edit**: Each spec row in the specs card shows label-left / value-right / pencil icon. Tapping the row replaces the value text with an inline `TextFormField`.
4. **Nav header**: The Pencil design shows "Cancelar" left / "Agregar Moto" center / "Guardar" right — this is a modal navigation pattern. The current page uses `AppAppBar` with back button. Implement the Pencil nav header style using a custom `PreferredSizeWidget` to match the design exactly.
5. **"Eliminar vehículo" link**: Shown in edit mode only. Uses `AppColors.textOnDarkTertiary` (same as Pencil `$text-tertiary`). Wires to existing delete flow.

## § 6 Acceptance Criteria
1. `vehicle_form_page.dart` renders visually identical to Pencil frame `EqnMm` — same layout, colors, typography, spacing.
2. The 4 spec fields (engine, horsepower, torque, weight) are sent to and retrieved from the backend.
3. Spec fields are optional — form submits successfully when left empty.
4. Placa field uses monospace font (Space Mono) with `letterSpacing: 2` and shows "Obligatorio" chip in accent color.
5. VIN field uses monospace font (Space Mono) with `letterSpacing: 0.5` and shows "Opcional" label.
6. Brand field shows searchable dropdown (AppAutocompleteField) with brand color dot prefix per suggestion row.
7. `dart analyze` passes with 0 errors after all changes.
8. `dart run build_runner build --delete-conflicting-outputs` runs cleanly.
9. Existing vehicle form submit (create + edit) continues to work end-to-end.
10. All new user-visible strings are in `lib/l10n/app_es.arb`.

## § 7 Regression Guardrails

| Area | Guardrail | Verification |
|------|-----------|--------------|
| Vehicle form submit | Create and edit vehicle both complete without crash | Test with and without spec fields filled |
| Vehicle list / detail | Vehicles already saved without spec fields still display correctly (null-safe) | Open vehicle detail for an existing vehicle after migration |
| SOAT slot | Existing SOAT document slot remains functional | Tap SOAT upload in form |
| Build runner | `vehicle_dto.dart` regenerates without conflicts | Run `dart run build_runner build --delete-conflicting-outputs` |
| Null safety | Spec fields null in edit mode when vehicle has no values | Open edit form for a vehicle created before this change |
| Backend migration | DB migration applies cleanly | Run Prisma migration; verify no data loss on existing vehicles |

## § 8 New Fields Spec

| Field | Dart Type | TS Type | DB | Validation |
|-------|-----------|---------|-----|------------|
| `engine` | `String?` | `string \| undefined` | `String?` (varchar) | optional, free text |
| `horsepower` | `String?` | `string \| undefined` | `String?` (varchar) | optional, free text |
| `torque` | `String?` | `string \| undefined` | `String?` (varchar) | optional, free text |
| `weight` | `String?` | `string \| undefined` | `String?` (varchar) | optional, free text |

## § 9 Out of Scope
- Scan card banner OCR/camera functionality (UI placeholder only)
- "Buscar" AI button on specs section (UI placeholder only)
- "Revisión Técnica" document upload/storage backend (UI slot only)
- "Agregar documento" generic slot action (UI only)
- Changes to vehicle list, vehicle detail, or any other vehicle screen
- Changes to rideglory-api beyond the 4 new nullable string columns and their DTO

## § 10 Open Questions (Resolved)
1. Brand dropdown data source → **Hardcoded** via existing `ColombiaMotosBrandsData`
2. Color swatch → **Static grey swatch** (no live HEX preview)
3. Spec row inline edit → **Inline text field** replacing value on tap
