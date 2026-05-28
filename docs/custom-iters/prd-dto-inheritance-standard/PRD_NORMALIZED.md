# PRD — Estandarizar el patrón DTO: herencia del modelo de dominio

**Slug:** prd-dto-inheritance-standard
**Type:** refactor
**Severity:** medium — technical debt; zero user-visible behavior change
**Created:** 2026-05-28
**Source note:** /Users/cami/Developer/Personal/Rideglory/docs/prds/prd-dto-inheritance-standard.md

---

## 1. Problem statement

The codebase has two coexisting patterns for DTOs, creating ambiguity when new features are developed:

- **Pattern A (old, inconsistent):** DTO is an independent class that duplicates all domain model fields. Requires `toModel()`, `fromModel()`, and extension-based `toDto()` methods. Every new field must be added in three places: model, DTO, and conversion method. Examples currently in codebase: `MaintenanceDto`, `EventRegistrationDto`, `VehicleSummaryDto`, `soat/SoatDto`.
- **Pattern B (new, canonical):** DTO extends the domain model (`XDto extends XModel`). Zero field duplication. The DTO IS the model via Dart inheritance. A `XModelExtension.toJson()` extension on the model allows serialization without callers knowing the DTO exists. Examples already correct: `EventDto`, `RiderTrackingDto`, `RiderProfileDto`, `VehicleDto` (partial — has redundant `toModel()`), `UserDto` (partial — has `fromModel()` factory instead of extension).

The goal of this refactor is to eliminate Pattern A from every eligible DTO so new developers have exactly one pattern to follow.

---

## 2. Objective (one sentence)

Migrate every eligible DTO to Pattern B (`XDto extends XModel` + `XModelExtension.toJson()`) and enforce this as the sole DTO standard going forward, leaving Pattern A only for documented exceptions.

---

## 3. Improvement type

**refactor** — zero behavior change, zero API contract change, zero UI change.

---

## 4. Affected areas

All files below were opened and verified during PO analysis.

### 4.1 Files already following Pattern B (canonical reference — DO NOT touch)

| File | Pattern | Notes |
|------|---------|-------|
| `lib/features/events/data/dto/event_dto.dart` | B (inheritance + extension) | Canonical reference. `EventDto extends EventModel`. `@JsonKey` for `createdAt`/`updatedAt`. |
| `lib/features/events/data/dto/rider_tracking_dto.dart` | B (inheritance + extension) | Includes `_normalizeTrackingJson()` helper for null safety on WS data. |
| `lib/features/events/data/dto/rider_profile_dto.dart` | B (inheritance + extension) | Clean. No conversion methods. |

### 4.2 Files following Pattern B but with noise — minor cleanup

| File | Problem | Action |
|------|---------|--------|
| `lib/features/vehicles/data/dto/vehicle_dto.dart` (lines 38–62) | Has `toModel()` at line 38 despite already extending `VehicleModel`. Method is redundant and misleading. | Remove `toModel()`. Verify callers. |
| `lib/features/home/data/dto/home_dto.dart` (line 25) | Calls `mainVehicle?.toModel()` — unnecessary since `VehicleDto` IS a `VehicleModel`. | After `VehicleDto.toModel()` removal, change to `mainVehicle` (direct assignment). |
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` (line 27) | Calls `.map((vehicle) => vehicle.toModel()).toList()` — `VehicleDto` IS a `VehicleModel`. | Replace with `vehicles.cast<VehicleModel>()` or direct return. |
| `lib/features/users/data/dto/user_dto.dart` (lines 31–47) | Has `factory UserDto.fromModel(UserModel model)` — exposes the DTO in caller code that needs to serialize a model. | Remove `fromModel()`, add `UserModelExtension.toJson()` extension. |

### 4.3 Files to migrate fully — major refactor

| File | Current pattern | Domain model | Freezed? | Key notes |
|------|----------------|--------------|---------|-----------|
| `lib/features/maintenance/data/dto/maintenance_dto.dart` | A — independent class, `fromModel()` + `toModel()` | `lib/features/maintenance/domain/model/maintenance_model.dart` | No — pure Dart class | API uses `createdAt`/`updatedAt`, model has `createdDate`/`updatedDate` — needs `@JsonKey` |
| `lib/features/event_registration/data/dto/event_registration_dto.dart` | A — independent class, `toModel()` + `EventRegistrationModelToDto.toDto()` extension | `lib/features/event_registration/domain/model/event_registration_model.dart` | No — pure Dart class | `birthDate` override in `toJson()` must be preserved. `vehicleSummary` field type must become `VehicleSummaryModel?` after `VehicleSummaryDto` migration. |
| `lib/features/event_registration/data/dto/vehicle_summary_dto.dart` | A — independent class, `toModel()` | `lib/features/event_registration/domain/model/vehicle_summary_model.dart` | No — pure Dart class | Simple; migrate before `EventRegistrationDto`. `displayName` getter inherited automatically. |
| `lib/features/soat/data/dto/soat_dto.dart` | A — independent class, `toModel()`. Has correct `SoatModelToRequest` extension. | `lib/features/soat/domain/models/soat_model.dart` | No — pure Dart class | `expiryDate` is `DateTime?` in DTO but `DateTime` (required) in model — type mismatch must be resolved. `toRequestJson()` extension must be preserved. |

### 4.4 Files deferred (pending additional analysis — out of scope this iteration)

| File | Reason |
|------|--------|
| `lib/features/vehicles/data/dto/soat_dto.dart` | Uses `String` for `startDate`/`expiryDate`; `vehicles/SoatModel` is a different class than `soat/SoatModel` (different field types and nullability). Unify models first. |

### 4.5 Files that must remain Pattern A (documented exceptions)

| File | Reason |
|------|--------|
| `lib/features/home/data/dto/home_dto.dart` | Composite response: wraps `VehicleDto?` + `List<EventDto>`. No single domain model. |
| `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart` | Composite response with `List<MaintenanceDto>`. Not a 1:1 model. |
| `lib/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart` (+ `MaintenanceListSummaryDto`) | Wrapper/sub-DTO with no domain model equivalent. |
| `lib/features/users/data/dto/create_user_dto.dart` | Request-only DTO (2 fields). No domain model. |
| `lib/features/notifications/data/dto/notification_dto.dart` | `toModel()` contains business logic (switch on notification type, title/body construction). Migrate in a future iteration after extracting logic to mapper. |
| `lib/features/events/data/dto/cover_generation_dto.dart` | AI cover generation request/response — no domain model equivalent. |

---

## 5. Constraints inherited from docs/PRD.md

- No user-visible behavior change.
- No backend API contract change.
- No new routes or UI screens.
- Clean Architecture layering: domain must not import Flutter or do I/O.
- All domain models that serve as DTO base classes must remain pure Dart (no `@freezed`). Confirmed: none of the target models use `@freezed` (grep returned zero results).
- `dart analyze` must pass with zero new violations.
- All existing tests must pass.

---

## 6. Acceptance criteria

1. `VehicleDto.toModel()` (lines 38–62 of `vehicle_dto.dart`) is deleted; `home_dto.dart` line 25 is updated; `vehicle_repository_impl.dart` line 27 no longer calls `.toModel()`.
2. `UserDto.fromModel()` (lines 31–47 of `user_dto.dart`) is deleted; a `UserModelExtension.toJson()` extension is added in the same file.
3. `MaintenanceDto` extends `MaintenanceModel`; all fields use `super` parameters; `@JsonKey(name: 'createdAt')` maps to `super.createdDate` and `@JsonKey(name: 'updatedAt')` maps to `super.updatedDate`; `fromModel()` and `toModel()` are deleted; `MaintenanceModelExtension.toJson()` extension exists in the file.
4. `maintenance_repository_impl.dart` no longer calls `.map((dto) => dto.toModel()).toList()` or `MaintenanceDto.fromModel()`.
5. `create_maintenance_response_dto.dart` `toModels()` uses direct cast (`List<MaintenanceModel>.from(created)`) instead of `.map((dto) => dto.toModel())`.
6. `VehicleSummaryDto` extends `VehicleSummaryModel`; `toModel()` is deleted; `VehicleSummaryModelExtension.toJson()` extension exists.
7. `EventRegistrationDto` extends `EventRegistrationModel`; `toModel()` is deleted; `EventRegistrationModelToDto.toDto()` extension is deleted; `EventRegistrationModelExtension.toJson()` extension exists; `birthDate` override in `toJson()` is preserved; `vehicleSummary` field is typed as `VehicleSummaryModel?` in the constructor.
8. `event_registration_repository_impl.dart` no longer calls `.toModel()` or `.toDto().toJson()`; uses direct assignment and model-level `.toJson()` instead.
9. `soat/SoatDto` extends `soat/SoatModel`; `toModel()` is deleted; `SoatModelToRequest.toRequestJson()` extension is preserved with identical behavior; `soat_repository_impl.dart` no longer calls `.toModel()`.
10. `soat_repository_impl.dart` uses direct DTO assignment where possible (DTO IS the model via inheritance).
11. `dart analyze` passes with zero new violations after all changes.
12. `flutter test` passes at 100% — no existing test broken.
13. `.cursor/rules/rideglory-coding-standards.mdc` is updated with the DTO Pattern B standard and exceptions list.
14. `CLAUDE.md` is updated to reflect Pattern B as the sole DTO standard.
15. Each migrated DTO file has a single `.g.dart` file generated; no orphaned `.g.dart` files remain.

---

## 7. Regression guardrails

| Area | Risk | Guardrail |
|------|------|-----------|
| `VehicleDto.toModel()` removal | `home_dto.dart` and `vehicle_repository_impl.dart` may still reference `.toModel()` | `grep -rn "toModel()" lib/features/vehicles/ lib/features/home/` must return zero results post-change |
| `MaintenanceDto` migration | `maintenance_repository_impl.dart` uses `MaintenanceDto.fromModel()` and `.toModel()` in two call sites | Run `grep -rn "MaintenanceDto.fromModel\|\.toModel()" lib/features/maintenance/` — must return zero results |
| `create_maintenance_response_dto.dart` | `toModels()` iterates over `created` list | After migration, `created` is `List<MaintenanceDto>` which IS `List<MaintenanceModel>` — verify cast compiles and no runtime ClassCast errors |
| `EventRegistrationDto` — `vehicleSummary` field | Field changes type from `VehicleSummaryDto?` to `VehicleSummaryModel?`; json_serializable must generate correct deserialization | Run `dart run build_runner build` and confirm no errors; inspect generated `.g.dart` |
| `EventRegistrationDto.toJson()` — `birthDate` override | Custom `birthDate` override must be preserved exactly; if removed, birth date format changes silently | Verify `toJson()` output for a test registration includes `birthDate` in the expected ISO 8601 format |
| `soat/SoatDto` — `expiryDate` type change | Current model has `DateTime expiryDate` (non-nullable); DTO has `DateTime?` — migration must reconcile | Confirm `SoatModel.expiryDate` is `DateTime` (non-nullable) before DTO migration; DTO constructor must use `required super.expiryDate` |
| Code generation | Each DTO file has a `part '..._dto.g.dart'` file; after migration the generated file must match the new class structure | `dart run build_runner build --delete-conflicting-outputs` must complete without errors; check for orphaned `.g.dart` files |
| `dart analyze` | Any missed `.toModel()` or incorrect super-parameter type causes analyzer errors | CI gate: `dart analyze` must pass with zero errors |
| Existing tests | No test may call `.toModel()` or `.toDto()` on migrated DTOs | `flutter test` must pass 100% before merge |

---

## 8. Out of scope

- `vehicles/data/dto/soat_dto.dart` — deferred. Requires unifying two divergent `SoatModel` classes across features first.
- `notifications/data/dto/notification_dto.dart` — deferred. `toModel()` contains business logic that must be extracted to a mapper before DTO inherits the model.
- Any new UI, new routes, new backend endpoints.
- Design changes (no Pencil work required).

---

## 9. Open questions for the human

None identified from the source PRD. The source note provides a complete migration plan with explicit file targets, patterns, and exception criteria. All models confirmed as pure Dart (non-freezed). The only pending decision is the `vehicles/soat_dto.dart` deferred item — whether to treat the two `SoatModel` variants as an unification task in a follow-up iteration.

---

## 10. Coding standards updated

Upon completion, update:
- `.cursor/rules/rideglory-coding-standards.mdc` — add DTO Pattern B section (see source PRD §9 for exact text)
- `CLAUDE.md` — update DTO description in the Architecture section to reflect Pattern B as sole standard
