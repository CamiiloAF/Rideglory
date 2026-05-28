# Summary — DTO inheritance standard refactor

**Slug:** prd-dto-inheritance-standard
**Type:** refactor
**Status:** ready_for_human_review
**Date completed:** 2026-05-28

## Goal

Migrate every eligible DTO to Pattern B (XDto extends XModel + XModelExtension.toJson()) and enforce this as the sole DTO standard, leaving Pattern A only for documented exceptions.

## What changed

- VehicleDto: removed redundant toModel() method
- UserDto: removed factory UserDto.fromModel(); added UserModelExtension.toJson(); user_storage_service.dart updated
- VehicleSummaryDto: fully migrated Pattern A → B; extends VehicleSummaryModel; toModel() deleted; extension added
- EventRegistrationDto: fully migrated Pattern A → B; extends EventRegistrationModel; toModel()+toDto() ext deleted; birthDate override preserved; _VehicleSummaryConverter added for nested deserialization
- MaintenanceDto: fully migrated Pattern A → B; extends MaintenanceModel; @JsonKey(name:'createdAt'/'updatedAt') preserves wire format; const removed; MaintenanceModelExtension.toJson() added
- soat/SoatDto: fully migrated Pattern A → B; extends SoatModel; expiryDate non-nullable; SoatModelToRequest.toRequestJson() preserved verbatim
- Repository cleanups: 15 call sites across 6 repository/DTO files
- .cursor/rules/rideglory-coding-standards.mdc: Pattern B section added with canonical example, forbidden list, exceptions table
- CLAUDE.md: data layer DTO description updated
- Code generation: 16 .g.dart outputs regenerated, no orphaned files

## Files modified

```
.cursor/rules/rideglory-coding-standards.mdc       |  44 ++++++++
CLAUDE.md                                          |   4 +-
lib/core/services/user_storage_service.dart        |   2 +-
lib/features/event_registration/data/dto/event_registration_dto.dart           | 113 +++++++---------
lib/features/event_registration/data/dto/vehicle_summary_dto.dart              |  24 ++---
lib/features/event_registration/data/repository/event_registration_repository_impl.dart |  25 +--
lib/features/home/data/dto/home_dto.dart           |   2 +-
lib/features/maintenance/data/dto/create_maintenance_response_dto.dart         |   2 +-
lib/features/maintenance/data/dto/maintenance_dto.dart                         |  77 +++++---------
lib/features/maintenance/data/repository/maintenance_repository_impl.dart      |   6 +-
lib/features/soat/data/dto/soat_dto.dart           |  45 ++------
lib/features/soat/data/repository/soat_repository_impl.dart                    |   4 +-
lib/features/users/data/dto/user_dto.dart          |  38 +++----
lib/features/vehicles/data/dto/vehicle_dto.dart    |  26 -----
lib/features/vehicles/data/repository/vehicle_repository_impl.dart             |   2 +-
```

Out of scope (also modified — human action required):
- lib/core/http/api_base_url_resolver.dart — pre-existing dirty file; MUST revert shouldUseLocalApi = true before merge
- docs/iter-7-scope.md — planning annotation; commit separately or revert

## Tests

- dart analyze: 0 errors, 0 warnings (45 pre-existing info-level issues, unchanged)
- flutter test: 119/119 pass, exit code 0
- 15/15 acceptance criteria verified by QA
- 11 wire-format spot-checks on generated .g.dart files: all pass

## Risks / regression watchlist

- MaintenanceDto @JsonKey remap (createdDate/updatedDate in model, createdAt/updatedAt on wire) — mitigated by .g.dart spot-check
- EventRegistrationDto.birthDate override — confirmed verbatim in code and .g.dart
- SoatDto.expiryDate non-nullable — needs human verify via MP-5 and MP-6
- api_base_url_resolver.dart local toggle active — MUST revert before merge to main (pre-existing, not introduced by this iteration)
- vehicles/soat_dto.dart deferred (still Pattern A) — expected; lines 113/123 in vehicle_repository_impl.dart retain .toModel()
- _buildCreateBody non-DTO map — architect Decision 2; follow-up tech debt
- No serialization roundtrip unit tests — follow-up recommended
- MP-1 through MP-8 manual probes not yet run — human must complete before commit

## Recommended commit message

refactor: migrate all eligible DTOs to Pattern B (XDto extends XModel)

Removes toModel()/fromModel()/toDto() from VehicleDto, UserDto,
MaintenanceDto, VehicleSummaryDto, EventRegistrationDto, and soat/SoatDto.
Adds XModelExtension.toJson() extensions. Updates CLAUDE.md and
rideglory-coding-standards.mdc with the canonical Pattern B standard and
documented exceptions list. dart analyze: 0 errors. flutter test: 119/119.

Note: revert api_base_url_resolver.dart local toggle before merging.

## Workspace files to keep

The entire docs/custom-iters/prd-dto-inheritance-standard/ directory should be committed as an analysis trail alongside the code changes.
