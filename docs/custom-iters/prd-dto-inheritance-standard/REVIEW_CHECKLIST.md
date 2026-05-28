# Review checklist — prd-dto-inheritance-standard

**Iter slug:** prd-dto-inheritance-standard
**Type:** refactor
**Verdict:** ready_for_human_review
**Date:** 2026-05-28

---

## Phase chain

| Phase | Agent | At | Summary |
|-------|-------|----|---------|
| po | po | 2026-05-28T15:00:00Z | PO analysis complete: mapped 7 DTO files to migrate, 3 canonical references, 6 documented exceptions, 1 deferred; PRD_NORMALIZED.md and handoff written |
| architect | architect | 2026-05-28T16:00:00Z | Change map: 14 source files (7 DTO/repo edits, 5 repo cleanups, 2 docs) + 7 regenerated .g.dart. Resolved 3 PO decisions: nested VehicleSummaryDto; _buildCreateBody left as-is; SoatDto.expiryDate non-nullable |
| design | orchestrator (skipped) | 2026-05-28T16:30:00Z | SKIPPED — needsDesign=false AND uiChanges=false |
| backend | orchestrator (skipped) | 2026-05-28T16:30:00Z | SKIPPED — backendChanges=false |
| frontend | frontend | 2026-05-28T18:00:00Z | All 7 DTO migrations completed. build_runner: 16 outputs. dart analyze: 0 errors/warnings. flutter test: exit 0. Updated coding standards + CLAUDE.md. |
| qa | qa | 2026-05-28T19:00:00Z | CONDITIONAL GREEN. dart analyze: 0 errors/0 warnings. flutter test: 119/119. All 15 ACs verified. All wire-format spot-checks pass. 8 manual probes required. |
| tech_lead_close | tech_lead | 2026-05-28T18:04:23Z | Verdict: ready_for_human_review. 0 blockers. 0 majors. 2 minors. 2 nits. |

---

## Pre-commit checklist (human actions required)

### Mandatory — must complete before `git commit`

- [ ] **Revert `api_base_url_resolver.dart`** — change `final shouldUseLocalApi = true;` back to `final shouldUseLocalApi = remoteBaseUrl.isEmpty;`. This is a pre-existing developer toggle that was NOT introduced by this iteration but must be reverted for production correctness.
- [ ] Run `dart analyze` — confirm 0 errors, 0 warnings (45 pre-existing info is acceptable)
- [ ] Run `flutter test` — confirm 119/119 pass (or better), exit code 0

### Manual probes — run on simulator or device before committing

- [X] **MP-1** Create a maintenance record for a vehicle — new entry appears in list; no crash
- [X] **MP-2** Edit an existing maintenance record and save — changes persist; no crash
- [X] **MP-3** Register for an event with a vehicle selected — registration saved; vehicle summary displays correctly
- [X] **MP-4** Open "My registrations" list — all rows render without crash
- [X] **MP-5** Open a vehicle with a SOAT — SOAT detail screen loads; expiry date shown correctly (non-nullable path)
- [X] **MP-6** Open a vehicle WITHOUT a SOAT — no crash; graceful empty/not-found state
- [X] **MP-7** Open Home screen — main vehicle and upcoming events render; no crash
- [X] **MP-8** Log out and log back in — user profile data persists (name, email, etc.)

---

## Acceptance criteria sign-off

| AC | Description | QA result | Tech Lead |
|----|-------------|-----------|-----------|
| AC-1 | VehicleDto.toModel() deleted; home_dto.dart + vehicle_repository_impl.dart updated | Pass | Pass |
| AC-2 | UserDto.fromModel() deleted; UserModelExtension.toJson() added | Pass | Pass |
| AC-3 | MaintenanceDto extends MaintenanceModel; @JsonKey remaps; extension added | Pass | Pass |
| AC-4 | maintenance_repository_impl.dart call sites clean | Pass | Pass |
| AC-5 | create_maintenance_response_dto.dart uses List.from() cast | Pass | Pass |
| AC-6 | VehicleSummaryDto extends VehicleSummaryModel; extension added | Pass | Pass |
| AC-7 | EventRegistrationDto extends EventRegistrationModel; birthDate override preserved | Pass | Pass |
| AC-8 | event_registration_repository_impl.dart call sites clean | Pass | Pass |
| AC-9 | soat/SoatDto extends SoatModel; SoatModelToRequest extension preserved | Pass | Pass |
| AC-10 | soat_repository_impl.dart direct assignment | Pass | Pass |
| AC-11 | dart analyze zero new violations | Pass | Pass |
| AC-12 | flutter test 100% | Pass (119/119) | Pass |
| AC-13 | rideglory-coding-standards.mdc updated | Pass | Pass |
| AC-14 | CLAUDE.md updated | Pass | Pass |
| AC-15 | No orphaned .g.dart files | Pass (16 outputs) | Pass |

---

## Files in scope

```
.cursor/rules/rideglory-coding-standards.mdc
CLAUDE.md
lib/core/services/user_storage_service.dart
lib/features/event_registration/data/dto/event_registration_dto.dart
lib/features/event_registration/data/dto/vehicle_summary_dto.dart
lib/features/event_registration/data/repository/event_registration_repository_impl.dart
lib/features/home/data/dto/home_dto.dart
lib/features/maintenance/data/dto/create_maintenance_response_dto.dart
lib/features/maintenance/data/dto/maintenance_dto.dart
lib/features/maintenance/data/repository/maintenance_repository_impl.dart
lib/features/soat/data/dto/soat_dto.dart
lib/features/soat/data/repository/soat_repository_impl.dart
lib/features/users/data/dto/user_dto.dart
lib/features/vehicles/data/dto/vehicle_dto.dart
lib/features/vehicles/data/repository/vehicle_repository_impl.dart
```

## Files out of scope (also modified — human decision required)

```
lib/core/http/api_base_url_resolver.dart   — pre-existing dirty file; MUST revert before merge
docs/iter-7-scope.md                       — planning annotation unrelated to this PRD; commit separately or revert
```

---

## Follow-up tech debt (log for next iteration)

- [ ] Create `CreateMaintenanceRequestDto` to replace `_buildCreateBody` hand-constructed map (architect Decision 2)
- [ ] Migrate `vehicles/data/dto/soat_dto.dart` — requires unifying two `SoatModel` classes first
- [ ] Migrate `notifications/data/dto/notification_dto.dart` — requires extracting `toModel()` business logic to a mapper first
- [ ] Add serialization roundtrip unit tests for `MaintenanceDto`, `EventRegistrationDto`, `SoatDto`, `VehicleSummaryDto`
