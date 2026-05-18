# PO Handoff — prd-maintenance

**Date:** 2026-05-16  
**Phase:** po  
**Status:** complete

---

## Goal

Implement the full Maintenance module business logic and UI: proper `MaintenanceMode`/`MaintenanceStatus` enum system, km-based status calculation, auto-creation of a `scheduled` record from a `completed` one, and a correct garage widget dual-card layout — all backed by updated API contracts.

---

## Source quote

> El módulo de mantenimientos permite al usuario registrar servicios realizados a su moto y programar servicios futuros. El objetivo es que el usuario tenga visibilidad clara de qué mantenimientos están vencidos, cuáles se aproximan y cuáles están al día, sin tener que calcular nada manualmente.

---

## Interpretation

The PRD is a complete specification (484 lines) for an existing but incomplete feature. The scaffolding exists in `lib/features/maintenance/` but the critical business logic gaps are:

1. **Model mismatch:** `isScheduled:bool` must become `MaintenanceMode` enum (completed/scheduled). Current `date` field conflates both service date and scheduled date.
2. **Status calculation gap:** `MaintenancesCubit` calculates status from date only (line ~100-125), ignoring `nextMaintenanceMileage`. The PRD requires both km AND date to be evaluated with defined thresholds.
3. **Auto-creation not implemented:** `MaintenanceFormCubit.createFollowUpScheduled()` exists (line ~53) but is never called from the save flow. The PRD requires it to be triggered automatically when a `completed` record has next-service fields.
4. **Garage widget is single-record:** `VehicleMaintenanceHistorySection` shows one `_ServiceCard.last` and one `_ServiceCard.next` from the same `MaintenanceModel.latest`. The PRD wants two independent records: last = most recent completed; next = most urgent scheduled.
5. **API contract delta:** Backend must accept `nextKmInterval` (relative) and return `{created:[...]}` array. Currently returns single `MaintenanceDto`.

---

## Affected areas — current state

| Area | File | Line(s) | Current state | Gap |
|------|------|---------|---------------|-----|
| Domain model | `maintenance_model.dart` | 35-80 | `isScheduled:bool`, `date:DateTime` (required), `maintanceMileage:int` (required), no `workshop`, no mode enum | Missing `MaintenanceMode`, `MaintenanceStatus`, `serviceDate`, `odometerAtService`, `workshop`, `nextOdometer` rename |
| Status calc | `maintenances_cubit.dart` | 100-125 | `next?.isBefore(now)` for overdue; `daysUntil <= 30` for upcoming | No km evaluation; enum names don't match PRD (upcoming vs next) |
| DTO | `maintenance_dto.dart` | 1-70 | Mirrors old model | Must mirror new model fields |
| API service return | `maintenance_service.dart` | 18-28 | `create()` returns `Future<MaintenanceDto>` | Must return `Future<CreateMaintenanceResponseDto>` with `created` list |
| Repository create | `maintenance_repository_impl.dart` | 100-130 | Returns single `MaintenanceModel` | Must return `List<MaintenanceModel>` (1 or 2) |
| Form cubit | `maintenance_form_cubit.dart` | 53-60 | `createFollowUpScheduled()` exists but is not called | Save flow must auto-call when next fields present |
| Garage widget | `vehicle_maintenance_history_section.dart` | 65-120 | Both cards derived from same `latest` record | Need separate `lastCompleted` and `nextScheduled` from `VehicleMaintenancesCubit` |
| Garage cubit | `vehicle_maintenances_cubit.dart` | 15-35 | Sorts all by `date` desc, exposes `list.first` | Must expose separate `lastCompleted:MaintenanceModel?` and `nextScheduled:MaintenanceModel?` |
| l10n | `app_es.arb` | various | Has `maintenance_done`, `maintenance_legend_warning` etc | Missing: workshop, odometerAtService, mode badges, status badges, validation messages |

---

## Acceptance criteria

1. `MaintenanceModel` has `mode:MaintenanceMode` (completed/scheduled), computed `status:MaintenanceStatus?`, `serviceDate:DateTime?`, `odometerAtService:int?`, `workshop:String?`, `nextOdometer:int?`, `nextDate:DateTime?`.
2. `MaintenanceStatus` is computed: overdue if km > nextOdometer OR today > nextDate; next if within 500 km OR 30 days; upToDate otherwise. Completed records get no status.
3. Saving completed with nextKmInterval/nextDate auto-creates scheduled record; both inserted in list without refresh.
4. Form sends relative `nextKmInterval`; backend returns absolute `nextOdometer`; detail shows absolute.
5. List has three sections: ATRASADO / PRÓXIMAMENTE / AL DÍA (completed always in AL DÍA).
6. Status filter affects only scheduled; completed visible only on "Todos" or "Al día".
7. Garage widget shows last completed card (left) and next scheduled card (right) as independent records.
8. Detail shows correct fields per mode (serviceDate/odometerAtService/workshop/cost for completed; nextDate/nextOdometer/status for scheduled).
9. All form validations per PRD §7.6 are enforced.
10. All new UI strings in `app_es.arb`.
11. `dart analyze` passes; `flutter test` passes.

---

## Regression guardrails

| Guardrail | Verification step |
|-----------|------------------|
| Existing maintenances still fetch | Unit test: `MaintenanceRepositoryImpl.getMaintenancesByVehicleId` with updated DTO parses correctly |
| Delete still works | Unit test `MaintenanceDeleteCubit`; manual test delete from detail page |
| Update still works | Unit test `MaintenanceRepositoryImpl.updateMaintenance`; manual test edit flow |
| Form without next fields (completed, optional) | Unit test `buildMaintenanceToSave` with no next fields — no null crash |
| VehicleMaintenancesCubit separation | Unit test: given mixed list, assert `lastCompleted` = most recent completed, `nextScheduled` = most urgent scheduled |
| Status calc edge cases | Unit tests: no date/no km → upToDate; only km overdue → overdue; only date overdue → overdue |
| Filter "Todos" shows both modes | Cubit unit test |
| `dart analyze` clean | Run in CI / pre-commit |
| `flutter test` green | Run full suite |

---

## Decisions needed from downstream agents

**For Architect:**
- How to handle the API backward compatibility: should `isScheduled` be kept as an alias in the DTO for existing records, or is a clean break acceptable?
- Where to locate `MaintenanceStatusCalculator` logic — in domain (use case) or as a pure static/extension in domain/model? (Constraint: no Flutter in domain.)
- Should `MaintenanceRepository.addMaintenance` return `List<MaintenanceModel>` or a new `CreateMaintenanceResult` type?

**For Backend:**
- Confirm DB migration needed for: `isScheduled→mode`, `date→serviceDate`, `maintanceMileage→odometerAtService`, new `workshop` field, new `nextOdometer` (if stored separately from `nextMaintenanceMileage`).
- The API must add `workshop` field; confirm schema allows nullable varchar.

**For Frontend:**
- The `MaintenanceFormCubit.buildMaintenanceToSave` needs to send `nextKmInterval` (relative) not the absolute value. Confirm the cubit computes `nextKmInterval = formValue` and backend converts to `nextOdometer = odometerAtService + nextKmInterval`.
- `MaintenancesCubit._applyClientFiltersAndEmit` needs significant rewrite to group by status sections. Confirm the emitted state type can stay `ResultState<List<MaintenanceModel>>` with ordering (overdue first, then next, then upToDate, completed last) rather than a new `@freezed` grouped state.

---

## Open questions for the human

1. **API backward compatibility:** Current NestJS uses `isScheduled:bool` + `date` + `maintanceMileage`. Is a coordinated backend+frontend deploy acceptable, or must the client maintain backward compatibility?
2. **`workshop` field:** Is `workshop` already in the DB schema, or does it need a migration?
3. **Existing data migration:** How should old `isScheduled=true/false` records be migrated to new `mode` field?
4. **`maintanceMileage` typo:** Rename only in DTO mapping layer, or also in DB column?

---

## Suggested phase plan

```
needsDesign:    no   — Pencil design files already exist per MEMORY.md; PRD is the spec
needsBackend:   yes  — API contract changes (new response shape, workshop field, mode enum, nextKmInterval)
needsFrontend:  yes  — Majority of work is here (model, cubit, widgets, forms, filters, garage widget)
needsDb:        yes  — Migration needed: mode field, workshop field, field renames (handled in backend phase)
```

- Phase 1: PO (this phase) ✓
- Phase 2: Architect
- Phase 3: Design — **SKIP** (PRD is the spec; Pencil designs exist)
- Phase 4: Backend — implement API changes in rideglory-api
- Phase 5: Frontend — implement all Flutter changes
- Phase 6: QA
- Phase 7: Tech Lead
- Phase 8: PO close-out

---

## Notes for orchestrator

1. **Design phase should be skipped** (`needsDesign: false`). The PRD contains the full screen spec. The Pencil file is the design source of truth (see MEMORY.md). The Frontend agent reads the PRD directly.
2. **Backend phase is required** even though this is a Flutter repo. The rideglory-api repo (`/Users/cami/Developer/Personal/rideglory-api`) must be updated to: (a) change `isScheduled:bool` to `mode:string` enum in the entity, (b) add `workshop:string?` field, (c) accept `nextKmInterval` in POST body and compute `nextOdometer` server-side, (d) return `{created:[...]}` array from POST.
3. **Open questions 1-4** above are significant enough that the orchestrator may want to surface them to the human before proceeding to the Architect phase. If the human says to proceed with assumptions, use: API is clean-break (no backward compat needed on isScheduled); workshop is a new field (migration needed); old records migrated by backend data migration; field rename is DTO-layer only (DB column stays).
