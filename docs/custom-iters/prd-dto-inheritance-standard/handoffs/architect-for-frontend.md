> Slim handoff for /custom-iter-fast prd-dto-inheritance-standard. Full detail in architect.md (read only if ambiguous).

# Frontend handoff — DTO inheritance refactor

## Goal

Migrate 7 DTOs from Pattern A (parallel class with `toModel()`/`fromModel()`) to Pattern B (`XDto extends XModel` + `XModelExtension.toJson()`). Zero behavior change, zero wire-format change. Update repository call sites, regenerate codegen, update standards docs.

Reference canonical Pattern B: `lib/features/events/data/dto/event_dto.dart`.

## Acceptance criteria (from PRD §6, condensed)

1. `VehicleDto.toModel()` deleted; `home_dto.dart:25` and `vehicle_repository_impl.dart:27` updated.
2. `UserDto.fromModel()` deleted; `UserModelExtension.toJson()` added in same file.
3. `MaintenanceDto extends MaintenanceModel` via `super.*`; `@JsonKey(name: 'createdAt') super.createdDate` + `@JsonKey(name: 'updatedAt') super.updatedDate`; `fromModel()`+`toModel()` deleted; `MaintenanceModelExtension.toJson()` added.
4. `maintenance_repository_impl.dart` has zero `MaintenanceDto.fromModel` or `.toModel()` calls. Line 182 uses `maintenance.toJson()` via new extension. `_buildCreateBody` LEFT AS-IS (see Decision 2).
5. `create_maintenance_response_dto.dart` `toModels()` uses `List<MaintenanceModel>.from(created)`.
6. `VehicleSummaryDto extends VehicleSummaryModel`; `toModel()` deleted; `VehicleSummaryModelExtension.toJson()` added.
7. `EventRegistrationDto extends EventRegistrationModel`; `toModel()` deleted; `EventRegistrationModelToDto.toDto()` extension deleted; `EventRegistrationModelExtension.toJson()` added; `birthDate` override in `toJson()` preserved verbatim; `vehicleSummary` constructor param typed as `VehicleSummaryDto?` (see Decision 1).
8. `event_registration_repository_impl.dart` has zero `.toModel()` or `.toDto()` calls (9 sites).
9. `soat/SoatDto extends SoatModel`; `toModel()` deleted; `SoatModelToRequest.toRequestJson()` preserved verbatim; `expiryDate` non-nullable (`required super.expiryDate`).
10. `soat_repository_impl.dart` has zero `.toModel()` calls (2 sites).
11. `dart analyze` → zero new violations.
12. `flutter test` → 100% pass.
13. `.cursor/rules/rideglory-coding-standards.mdc` updated with DTO Pattern B section + exceptions list (text in source PRD §10 / §9 of original draft).
14. `CLAUDE.md` updated to reflect Pattern B as sole DTO standard.
15. Each migrated DTO has exactly one `.g.dart` companion; no orphans.

## 3 decisions resolved (do not re-litigate)

### Decision 1 — Nested `VehicleSummaryDto?` in `EventRegistrationDto`
Type the constructor parameter as `VehicleSummaryDto?` so codegen generates the nested `fromJson` correctly. Use the `super` form first:
```dart
const EventRegistrationDto({
  ...
  super.vehicleId,
  VehicleSummaryDto? super.vehicleSummary,
  ...
});
```
If build_runner rejects it, fall back to field shadow:
```dart
const EventRegistrationDto({
  ...
  this.vehicleSummaryDto,
  ...
}) : super(vehicleSummary: vehicleSummaryDto);
final VehicleSummaryDto? vehicleSummaryDto;
```
No `@JsonKey(fromJson:)` converter is required either way.

### Decision 2 — `_buildCreateBody` in `maintenance_repository_impl.dart`
**Leave it as-is.** It carries non-model fields (`nextKmInterval`, hand-mapped `mode`) so it is not a 1:1 `model.toJson()`. Cleanest fix is a dedicated request DTO — out of scope here. Capture this as follow-up tech-debt in your final notes.
HOWEVER: line 182 (`MaintenanceDto.fromModel(maintenance).toJson()`) MUST become `maintenance.toJson()` via the new extension.

### Decision 3 — `SoatDto.expiryDate` nullability
Make DTO `expiryDate` **non-nullable**, matching the model:
```dart
class SoatDto extends SoatModel {
  const SoatDto({
    required super.id,
    required super.vehicleId,
    super.policyNumber,
    super.startDate,
    required super.expiryDate, // non-nullable
    super.insurer,
    super.documentUrl,
    super.createdAt,
    super.updatedAt,
  });
  ...
}
```
Add a code comment: backend contract guarantees non-null `expiryDate` when a SOAT exists (404 → no SOAT). Preserve `SoatModelToRequest.toRequestJson()` extension verbatim.

## Implementation order (CRITICAL)

1. `VehicleDto` cleanup → fix `home_dto.dart` + `vehicle_repository_impl.dart` callers.
2. `UserDto` cleanup → add `UserModelExtension.toJson()`.
3. **`VehicleSummaryDto` migration** (BEFORE EventRegistrationDto).
4. `EventRegistrationDto` migration → preserve `birthDate` override; type `vehicleSummary` as `VehicleSummaryDto?`.
5. `event_registration_repository_impl.dart` cleanup (9 sites: drop `.toModel()`, `.toDto()`).
6. `MaintenanceDto` migration → `@JsonKey` remap for `createdAt`/`updatedAt`.
7. `maintenance_repository_impl.dart` cleanup (lines 88, 137 indirectly, 182, 184). LEAVE `_buildCreateBody`.
8. `create_maintenance_response_dto.dart` cleanup.
9. `SoatDto` migration.
10. `soat_repository_impl.dart` cleanup (2 sites).
11. **ALL DTO EDITS DONE → run build_runner ONCE.** Do NOT run mid-migration.
12. `dart analyze` + `flutter test` → fix regressions.
13. Update `.cursor/rules/rideglory-coding-standards.mdc` and `CLAUDE.md`.

## Build runner command

```bash
dart run build_runner build --delete-conflicting-outputs
```
The `--delete-conflicting-outputs` flag is mandatory (otherwise stale `.g.dart` files block regeneration).

## Wire-format invariants (must be preserved EXACTLY)

- `EventRegistrationDto.toJson()`: `birthDate` key set via `apiEncodeRequiredDateTime(birthDate)` override.
- `MaintenanceDto.toJson()`: keys include `createdAt`, `updatedAt` (NOT `createdDate`/`updatedDate`) — `@JsonKey(name:)` mandatory.
- `SoatDto`: same keys as today.
- `VehicleSummaryDto`: same keys as today.
- All `apiJsonDateTimeConverters` formatting preserved (already on `@JsonSerializable`).

## Guardrails

After implementation, these greps MUST return zero results:
- `grep -rn "\.toModel()" lib/features/vehicles/ lib/features/home/`
- `grep -rn "MaintenanceDto\.fromModel\|\.toModel()" lib/features/maintenance/`
- `grep -rn "\.toDto()\|\.toModel()" lib/features/event_registration/`
- `grep -rn "\.toModel()" lib/features/soat/`
- `grep -rn "UserDto\.fromModel\|fromModel" lib/features/users/`

## Out of scope

- `lib/features/vehicles/data/dto/soat_dto.dart` (different SoatModel; deferred).
- `lib/features/notifications/data/dto/notification_dto.dart` (deferred).
- Refactoring `_buildCreateBody` to a request DTO (note as follow-up tech-debt).
- Adding DTO roundtrip unit tests.
