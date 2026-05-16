# PO Handoff — vehicle-form-specs

## Goal
Redesign the vehicle form to match Pencil frame `EqnMm` pixel-for-pixel and add 4 optional spec fields (engine, horsepower, torque, weight) end-to-end across Flutter and the NestJS vehicles microservice.

## Source Quote
> "Redesign `vehicle_form_page.dart` to be visually identical to Pencil frame `EqnMm` ("Agregar / Editar Moto"), and add the four new optional specs fields (engine, horsepower, torque, weight) that appear in the design but are missing from the data model and backend."

## Interpretation
This is a combined redesign + feature addition. The Pencil frame `EqnMm` is the authoritative visual spec. The current `vehicle_form.dart` already implements most sections (cover, scan banner, basic info, identification, documents, CTA) but is missing the **ESPECIFICACIONES** section entirely, and has visual differences from the Pencil design (nav header pattern, Placa/VIN monospace fonts, brand dropdown styling, delete link). The backend needs 4 new nullable columns in the Prisma schema.

## Affected Areas — Current State

| Area | File | Current State | Notes |
|------|------|--------------|-------|
| Domain model | `lib/features/vehicles/domain/models/vehicle_model.dart` | 18 fields, no spec fields | Uses sentinel `_unset` pattern for nullable copyWith |
| DTO | `lib/features/vehicles/data/dto/vehicle_dto.dart` | Extends VehicleModel, generated .g.dart | Must re-run build_runner after change |
| Form fields | `lib/features/vehicles/constants/vehicle_form_fields.dart` | 10 string constants | Add 4 more |
| Form cubit | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | `buildVehicleToSave()` maps 9 fields manually | Add 4 spec fields to mapping |
| Form cubit state | `lib/features/vehicles/presentation/cubit/vehicle_form_state.dart` | Freezed state with vehicleResult, vehicle, localImagePath, soatLocalPath, techReviewLocalPath | No spec fields in state (spec fields are form builder state, not cubit state — correct) |
| Vehicle form widget | `lib/features/vehicles/presentation/widgets/vehicle_form.dart` | 400+ LOC, multiple private widget classes in one file | Violates "1 widget per file" rule; full redesign needed |
| Form page | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | Scaffold, AppBar using AppAppBar, BlocListener | Needs Pencil nav header + delete link in edit mode |
| l10n | `lib/l10n/app_es.arb` | Has most vehicle_form_ keys; missing specs section keys | Add ~8 new keys |
| Backend contracts | `rideglory-api/rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts` | No spec fields | Add 4 optional @IsString() fields |
| Backend entity | `rideglory-api/vehicles-ms/src/vehicles/entities/vehicle.entity.ts` | No spec fields | Add 4 optional @IsString() fields |
| Prisma schema | `rideglory-api/vehicles-ms/prisma/schema.prisma` | Vehicle model has 15 fields, no spec fields | Add 4 nullable String? columns; generate migration |
| Vehicles service | `rideglory-api/vehicles-ms/src/vehicles/vehicles.service.ts` | create/update use spread `...rest` after destructuring purchaseDate | New fields automatically included via `...rest` — no logic change needed |

## Acceptance Criteria
1. `vehicle_form_page.dart` renders visually identical to Pencil frame `EqnMm`.
2. 4 spec fields sent to and retrieved from backend.
3. Spec fields optional — form submits with empty specs.
4. Placa: Space Mono, letterSpacing 2, "Obligatorio" accent chip.
5. VIN: Space Mono, letterSpacing 0.5, "Opcional" tertiary label.
6. Brand: AppAutocompleteField with colored brand dot prefix per suggestion row.
7. `dart analyze` passes with 0 errors.
8. `dart run build_runner build --delete-conflicting-outputs` runs cleanly.
9. Existing create + edit vehicle flow works end-to-end.
10. All new strings in `app_es.arb`.

## Regression Guardrails
| Guardrail | Verification Step |
|-----------|------------------|
| Vehicle form create | Fill form, submit → vehicle saved in backend |
| Vehicle form edit | Open existing vehicle, edit, save → updated |
| Spec fields optional | Submit form with empty spec section → no error |
| Null safety for existing vehicles | Edit a vehicle with no spec fields → form opens without crash, spec fields show empty |
| SOAT slot | Tap upload in form → file picker opens |
| Build runner | `dart run build_runner build --delete-conflicting-outputs` → exits 0 |
| Backend migration | `npx prisma migrate dev` in vehicles-ms → applies cleanly |

## Decisions Needed from Downstream Agents
- **Architect**: Confirm that `vehicles.service.ts` `...rest` spread automatically includes new fields and no explicit mapping is needed in `create()` and `update()`.
- **Frontend**: The current `vehicle_form.dart` has multiple private widget classes in one file. The redesign must split them into separate files under `lib/features/vehicles/presentation/form/widgets/`. Confirm the widget split plan before coding.
- **Frontend**: The Pencil nav header is "Cancelar | title | Guardar" — this is different from the current `AppAppBar`. The "Guardar" tap should call `_saveVehicle()`. Confirm this pattern.

## Suggested Phase Plan
- `needsDesign: false` — Pencil frame `EqnMm` is the authoritative design; no new design work needed
- `needsBackend: true` — 4 new DB columns, Prisma migration, DTO updates
- `needsFrontend: true` — full redesign + new fields
- `needsDb: true` — Prisma migration in vehicles-ms

## Open Questions for the Human
All questions from § 10 of the source PRD have been resolved:
1. Brand dropdown → hardcoded via `ColombiaMotosBrandsData` ✓
2. Color swatch → static grey ✓
3. Spec row inline edit → inline text field ✓

No blocking open questions. Proceed with all phases.

## Notes for Orchestrator
- `decisions.needsDesign` = false (Pencil frame is the spec; no Design phase needed)
- `decisions.backendChanges` = true
- `decisions.frontendChanges` = true
- `decisions.dbChanges` = true
- `decisions.uiChanges` = true
- The backend is a Prisma/NestJS microservices monorepo at `/Users/cami/Developer/Personal/rideglory-api`. Backend agent should work in `vehicles-ms/` subdirectory.
- The contracts package (`rideglory-contracts`) is the canonical source for DTOs shared between gateway and microservice. Backend agent must update both `rideglory-contracts/src/vehicles/dto/create-vehicle.dto.ts` AND `vehicles-ms/src/vehicles/entities/vehicle.entity.ts`.
- The `color` field already exists in the domain model but is NOT currently populated in `buildVehicleToSave()` — wait, it IS present on line: `color: (formData[VehicleFormFields.color] as String?)?.isEmpty ?? true ? null : formData[VehicleFormFields.color] as String?`. This is fine.
