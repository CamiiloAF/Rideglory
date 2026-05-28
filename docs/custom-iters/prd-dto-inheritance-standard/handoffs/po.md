# PO handoff — DTO inheritance standard refactor

**Date:** 2026-05-28
**Status:** done

---

## Goal

Migrate every eligible DTO in the Rideglory Flutter codebase from the old "parallel class with `toModel()`/`fromModel()`" pattern to the canonical "DTO extends domain model + `XModelExtension.toJson()`" pattern, so all future DTO authoring has exactly one unambiguous standard.

---

## Source quote

> El codebase tiene dos patrones coexistentes para los DTOs, lo que genera confusión sobre cuál usar al crear nuevos features. [...] Adoptar el Patrón B como el único patrón válido para todos los DTOs que tienen un modelo de dominio 1:1 correspondiente. Eliminar `toModel()`, `fromModel()`, y extensiones `toDto()` como consecuencia.

(Full source: `/Users/cami/Developer/Personal/Rideglory/docs/prds/prd-dto-inheritance-standard.md`)

---

## Interpretation

This is a pure technical-debt refactor. No user-facing behavior changes, no API contract changes, no new endpoints, no UI changes. The work is entirely within the Flutter `data/` layer of existing features. The canonical pattern (`EventDto extends EventModel`) already exists and is proven; this iteration standardizes it across all remaining DTOs that qualify.

The source PRD is unusually detailed — it specifies every target file, the exact expected code structure, and explicit exceptions. The PO role here is primarily to verify the file map, confirm domain model compatibility (no `@freezed` blockers), and translate AC into verifiable guardrails.

---

## Affected areas — current state

| Feature | DTO file | Current pattern | Notes |
|---------|----------|----------------|-------|
| events | `lib/features/events/data/dto/event_dto.dart` | B (canonical) — inheritance + extension | Reference implementation. Do not touch. |
| events | `lib/features/events/data/dto/rider_tracking_dto.dart` | B (canonical) — inheritance + extension | Includes `_normalizeTrackingJson()`. Do not touch. |
| events | `lib/features/events/data/dto/rider_profile_dto.dart` | B (canonical) — inheritance + extension | Clean. Do not touch. |
| vehicles | `lib/features/vehicles/data/dto/vehicle_dto.dart` | B + noise — has redundant `toModel()` at lines 38–62 | Minor cleanup: delete `toModel()`. Extension already present. |
| home | `lib/features/home/data/dto/home_dto.dart` | Calls `mainVehicle?.toModel()` at line 25 | Update to `mainVehicle` (direct) after `VehicleDto.toModel()` removal. |
| vehicles | `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Calls `.map((vehicle) => vehicle.toModel()).toList()` at line 27 | Remove `.toModel()` since `VehicleDto` IS a `VehicleModel`. |
| users | `lib/features/users/data/dto/user_dto.dart` | B + noise — has `factory UserDto.fromModel()` at lines 31–47 | Minor cleanup: delete `fromModel()`, add `UserModelExtension.toJson()`. No callers of `fromModel()` found in `user_repository_impl.dart`. |
| maintenance | `lib/features/maintenance/data/dto/maintenance_dto.dart` | A — independent class, duplicates all model fields; `fromModel()` + `toModel()` | Full migration to Pattern B. `createdAt`/`updatedAt` in API → `createdDate`/`updatedDate` in model — needs `@JsonKey`. Model is pure Dart (confirmed — no `@freezed`). |
| maintenance | `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` | Calls `dto.toModel()` at line 88, `response.toModels()` at line 137, `MaintenanceDto.fromModel(maintenance).toJson()` at line 180 | 3 call sites to update after DTO migration. |
| maintenance | `lib/features/maintenance/data/dto/create_maintenance_response_dto.dart` | `toModels()` calls `.map((dto) => dto.toModel()).toList()` at line 22 | After migration: `List<MaintenanceModel>.from(created)` or direct return. |
| event_registration | `lib/features/event_registration/data/dto/vehicle_summary_dto.dart` | A — independent class, `toModel()` at line 27 | Simple migration. Must be done BEFORE `EventRegistrationDto`. Model is pure Dart. |
| event_registration | `lib/features/event_registration/data/dto/event_registration_dto.dart` | A — independent class, `toModel()` at line 69; `EventRegistrationModelToDto.toDto()` extension at line 93 | Full migration. `birthDate` override in `toJson()` must be preserved. `vehicleSummary` type becomes `VehicleSummaryModel?`. |
| event_registration | `lib/features/event_registration/data/repository/event_registration_repository_impl.dart` | Uses `.toDto().toJson()` at lines 26, 55; `.toModel()` at lines 29, 57, 78, 90, 99, 102, 113, 122, 132 | 9 call sites to update after DTO migration. |
| soat | `lib/features/soat/data/dto/soat_dto.dart` | A — independent class, `toModel()` at line 36; has `SoatModelToRequest` extension (correct, keep) | Full migration. `expiryDate` type mismatch: DTO has `DateTime?`, model has `DateTime` (non-nullable) — requires `required super.expiryDate`. Repository calls `dto.toModel()` and `soat.toRequestJson()`. |
| soat | `lib/features/soat/data/repository/soat_repository_impl.dart` | `dto.toModel()` at lines 23, 49 | 2 call sites to update after DTO migration. |
| vehicles | `lib/features/vehicles/data/dto/soat_dto.dart` | A — independent class, uses `String` for dates, `DateTime.parse()` in `toModel()` | DEFERRED — diverges from `soat/SoatModel`; requires model unification first. |

---

## Acceptance criteria

1. `VehicleDto.toModel()` deleted; `home_dto.dart` uses `mainVehicle` directly; `vehicle_repository_impl.dart` uses `vehicles` (or `cast<VehicleModel>()`) without `.toModel()`.
2. `UserDto.fromModel()` deleted; `UserModelExtension.toJson()` extension added in same file.
3. `MaintenanceDto extends MaintenanceModel`; uses `super` parameters; `@JsonKey(name: 'createdAt') super.createdDate` and `@JsonKey(name: 'updatedAt') super.updatedDate`; `fromModel()` and `toModel()` deleted; `MaintenanceModelExtension.toJson()` extension added.
4. `maintenance_repository_impl.dart` has zero calls to `MaintenanceDto.fromModel()` or `.toModel()`.
5. `create_maintenance_response_dto.dart` `toModels()` uses `List<MaintenanceModel>.from(created)`.
6. `VehicleSummaryDto extends VehicleSummaryModel`; `toModel()` deleted; `VehicleSummaryModelExtension.toJson()` added.
7. `EventRegistrationDto extends EventRegistrationModel`; `toModel()` deleted; `EventRegistrationModelToDto` extension deleted; `EventRegistrationModelExtension.toJson()` added; `birthDate` override preserved; `vehicleSummary` typed as `VehicleSummaryModel?`.
8. `event_registration_repository_impl.dart` has zero calls to `.toModel()` or `.toDto()`.
9. `soat/SoatDto extends SoatModel`; `toModel()` deleted; `SoatModelToRequest.toRequestJson()` preserved; `soat_repository_impl.dart` has zero calls to `.toModel()`.
10. `dart analyze` passes with zero new violations.
11. `flutter test` passes at 100%.
12. `.cursor/rules/rideglory-coding-standards.mdc` and `CLAUDE.md` updated with Pattern B standard.
13. `dart run build_runner build --delete-conflicting-outputs` completes without errors; no orphaned `.g.dart` files.

---

## Regression guardrails

| Area | Verification step |
|------|-------------------|
| `VehicleDto.toModel()` removal | `grep -rn "toModel()" lib/features/vehicles/ lib/features/home/` → zero results |
| `MaintenanceDto` call sites | `grep -rn "MaintenanceDto.fromModel\|\.toModel()" lib/features/maintenance/` → zero results |
| `EventRegistrationDto` call sites | `grep -rn "\.toDto()\|\.toModel()" lib/features/event_registration/` → zero results |
| `soat/SoatDto` call sites | `grep -rn "\.toModel()" lib/features/soat/` → zero results |
| `UserDto.fromModel()` call sites | `grep -rn "UserDto.fromModel\|fromModel" lib/features/users/` → zero results |
| `birthDate` serialization | Manually inspect `EventRegistrationDto.toJson()` output: `birthDate` key must be present as ISO 8601 string |
| `expiryDate` type | Confirm `SoatDto` constructor uses `required super.expiryDate` matching `SoatModel.expiryDate: DateTime` (non-nullable) |
| Code generation | `dart run build_runner build --delete-conflicting-outputs` runs without errors; each migrated file has exactly one `.g.dart` counterpart |
| Analyzer | `dart analyze` → zero errors, zero new warnings |
| Test suite | `flutter test` → 100% pass |

---

## Decisions needed from downstream agents

**For Architect:**
1. Confirm whether `VehicleSummaryDto` as field in `EventRegistrationDto` requires a `@JsonKey(fromJson: ...)` converter or whether `json_serializable` can infer construction of `VehicleSummaryModel` (the base type) directly from JSON when the DTO extends it. The preferred approach is to type the constructor parameter as `VehicleSummaryDto?` (DTO type) inside the DTO while the model field is `VehicleSummaryModel?` — clarify if a `@JsonKey` annotation or custom converter is needed.
2. Confirm the execution order: `VehicleSummaryDto` migration → `EventRegistrationDto` migration → code generation run in one batch, or two separate generation steps.
3. For `maintenance_repository_impl.dart` `_buildCreateBody()` at line 142: this method manually constructs a JSON map (not using DTO `.toJson()`). After migration, the architect should decide whether this should be refactored to use `maintenance.toJson()` via the new `MaintenanceModelExtension`, or remain as explicit field construction. Both are valid; a decision prevents the frontend agent from making this call autonomously.

**For Frontend (Flutter developer):**
1. The `create_maintenance_response_dto.dart` `toModels()` method: after `MaintenanceDto extends MaintenanceModel`, the method can simply return `List<MaintenanceModel>.from(created)` — however, if `created` is `List<MaintenanceDto>` and Dart generics are invariant at runtime, the developer may prefer `created.cast<MaintenanceModel>()`. Either works; pick one and be consistent.
2. After removing `EventRegistrationDto.toModel()`, the repository currently returns results like `dto.toModel()` — change to `dto` directly (direct assignment, since `EventRegistrationDto` IS an `EventRegistrationModel`). Verify that Dart's type system allows this in every call site without explicit cast.

---

## Open questions for the human

None. The source PRD is complete. The `vehicles/soat_dto.dart` deferred item is explicitly marked out of scope — the human should decide in a future iteration whether to unify the two `SoatModel` variants.

---

## Suggested phase plan

| Phase | Agent | Needed? | Rationale |
|-------|-------|---------|-----------|
| Design | design | No | Pure refactor, zero UI/screen changes, no Pencil work |
| Architect | architect | Yes | Confirm DTO field-type resolution for `VehicleSummaryModel?` deserialization; confirm `_buildCreateBody` decision; confirm execution order |
| Backend | backend | No | No NestJS changes; all work is Flutter-side |
| Frontend | frontend | Yes | Implement all DTO migrations, repository updates, code generation run, and standards file updates |
| QA | qa | Yes | `dart analyze` + `flutter test`; grep-based regression checks from guardrails table |
| Tech Lead | tech_lead | Yes | Clean Architecture compliance review; confirm no layer violations after migration |

**Phase flags:**
- `needsDesign`: false
- `needsBackend`: false
- `needsFrontend`: true
- `needsDb`: false

---

## Notes for orchestrator

1. **Execution order is critical:** `VehicleSummaryDto` must be migrated before `EventRegistrationDto` because the latter's `vehicleSummary` field type depends on the former.
2. **Code generation must run after all DTO files are migrated** — not incrementally. Running `build_runner` mid-migration on partially-migrated files will produce errors. The frontend agent should migrate all DTOs, then run a single `dart run build_runner build --delete-conflicting-outputs` pass.
3. **`vehicles/soat_dto.dart` is explicitly out of scope** — the frontend agent must not touch it.
4. **No playbook path conflicts detected.** The po.md playbook's output paths (`docs/handoffs/po.md`) are overridden here by the workspace paths (`docs/custom-iters/prd-dto-inheritance-standard/handoffs/po.md`) per custom-iter rules.
5. **`_buildCreateBody` in maintenance repository** manually constructs a `Map<String, dynamic>` — this is actually compliant with the `DTO.toJson() rule` in memory (rule says use DTO `.toJson()` for API payloads). After migration, the maintenance create body should ideally use the new `MaintenanceModelExtension.toJson()` or a purpose-built request DTO. The architect should weigh in before frontend implements.
6. **`soat/SoatDto.expiryDate` type mismatch** is a real risk. Current DTO has `DateTime? expiryDate` with a `?? DateTime.now()` fallback in `toModel()`. After migration, the model's `required DateTime expiryDate` must be satisfied by the DTO constructor. The Architect must confirm whether the API can return a null `expiryDate` and if so, how to handle it (default or error).
