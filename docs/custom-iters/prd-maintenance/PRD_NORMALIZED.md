# PRD NORMALIZED — Módulo de Mantenimientos (prd-maintenance)

**Slug:** prd-maintenance  
**Source:** docs/custom-iters/maintenances-logic/PRD_maintenance.md  
**Date:** 2026-05-16  
**Normalized by:** PO phase

---

## 1. Goal

Implement the full Maintenance module business logic and UI: replace the current `isScheduled:bool` model with a proper `MaintenanceMode`/`MaintenanceStatus` enum system, add km-based status calculation, implement auto-creation of a `scheduled` record from a `completed` one when next-service fields are filled, add the garage widget dual-card layout (last service + next service by separate records), and implement the full detail/list/form/filter screens per the PRD specification.

---

## 2. Improvement type & severity

- **Type:** feature_addition + refactor (new domain logic + UI implementation on top of existing scaffolding)
- **Severity:** high — affects the core data model, all existing screens, the garage widget, and the API contract

---

## 3. Core ask

The maintenance module has scaffolding (domain model, DTOs, service, repository, cubit, pages) but the business logic is incomplete: the `MaintenanceModel` uses a simple `isScheduled:bool` instead of a `MaintenanceMode` enum; status calculation ignores km/odometer data; there is no auto-creation of a `programado` record from a `completado` one; and the garage widget shows only the latest single record instead of two separate cards (last completed + next scheduled). The PRD specifies all of this in detail. This run implements it fully.

---

## 4. Affected areas

| Area | Current file(s) | Current state | Required change |
|------|----------------|---------------|-----------------|
| Domain model | `lib/features/maintenance/domain/model/maintenance_model.dart` | `isScheduled:bool`, single `date:DateTime` field, no `MaintenanceMode`/`MaintenanceStatus` enums | Add `MaintenanceMode` enum (completed/scheduled), add `MaintenanceStatus` computed enum, rename `date`→`serviceDate`, rename `maintanceMileage`→`odometerAtService`, add `nextOdometer:int?`, keep `nextMaintenanceDate`→`nextDate`, add `workshop:String?` |
| Status calculation | `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart` lines 100-125 | Status calc based on `nextMaintenanceDate` date only; no km logic | Implement full status calc: overdue if km or date exceeded; next if within UMBRAL_KM=500 or UMBRAL_DIAS=30; completed records never participate in status sections |
| DTO | `lib/features/maintenance/data/dto/maintenance_dto.dart` | Mirrors old model: `isScheduled:bool`, `date`, `maintanceMileage` | Update to mirror new model: `mode:String`, `serviceDate`, `odometerAtService`, `nextOdometer`, `nextDate`, `workshop`, keep `cost`, `notes` |
| API response shape | `lib/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart` | Returns `{items, summary}` with `items: MaintenanceDto[]` | Response shape stays same; summary DTO fields unchanged |
| Repository impl — create | `lib/features/maintenance/data/repository/maintenance_repository_impl.dart` method `addMaintenance` | Creates single record, returns `MaintenanceDto` (single) | Update to send `nextKmInterval` (relative) instead of absolute `nextOdometer`; handle response `{created:[...]}` array (1 or 2 records); return both via new method signature |
| Auto-creation logic | No current implementation | Does not exist | After successful `addMaintenance` when mode==completed AND (nextOdometer or nextDate provided): parse second record from `created[1]` if present; cubit inserts both locally |
| Form cubit | `lib/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart` | `buildMaintenanceToSave(isScheduled:bool)` — uses old fields | Update `buildMaintenanceToSave` to use new fields; handle relative→absolute km conversion; trigger local insertion of both records on success |
| Form page/view | `lib/features/maintenance/presentation/form/maintenance_form_page.dart` + `lib/features/maintenance/presentation/form/widgets/maintenance_form_view.dart` | Has toggle for scheduled/completed but uses old field names | Wire to new `MaintenanceMode` enum; validate per PRD §7.6 rules |
| MaintenancesCubit — list grouping | `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart` | Sorts by `nextMaintenanceDate` or `date`; no grouped sections by status | Emit grouped structure: OVERDUE section → NEXT section → UP-TO-DATE+COMPLETED section; use new `MaintenanceStatus` calc |
| List page widgets | `lib/features/maintenance/presentation/list/maintenances/widgets/` | `MaintenancesDataWidget`, `MaintenanceSectionGroup`, `MaintenanceGroupedListItem` exist | Adapt `MaintenanceGroupedListItem` to use new model fields for display text; sections driven by grouped cubit state |
| Filter logic | `lib/features/maintenance/presentation/widgets/maintenance_filters.dart` | `MaintenanceStatusFilter` enum uses `overdue/upcoming/onTrack` | Rename to match new: `overdue/next/upToDate` (or add alias); status filter only applies to `scheduled` records (completed always shows when `all`) |
| Detail page | `lib/features/maintenance/presentation/detail/maintenance_detail_page.dart` | Shows basic info; uses `maintenance.date`, `maintenance.maintanceMileage` | Update field references to `serviceDate`, `odometerAtService`, `workshop`; show mode badge (Realizado/Programado) |
| Detail widgets | `lib/features/maintenance/presentation/detail/widgets/` | Multiple widgets referencing old fields | Update all field references |
| Garage widget | `lib/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart` | Shows single latest maintenance; `_ServiceCard.last` uses `maintenance.date` / `maintanceMileage`; `_ServiceCard.next` uses `nextMaintenanceDate`/`nextMaintenanceMileage` | Split into two separate records: last = most recent `mode==completed`; next = most urgent `mode==scheduled`; show status badge on next card; tap each card navigates to detail |
| Garage cubit | `lib/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart` | Sorts all by `date` desc, exposes `list.first` | Separate into `lastCompleted` and `nextScheduled` results; sort scheduled by urgency |
| l10n strings | `lib/l10n/app_es.arb` | Some maintenance strings exist; missing new ones | Add strings for new UI states: mode badges, status labels, workshop field, km fields, validation messages per PRD |
| API service | `lib/features/maintenance/data/service/maintenance_service.dart` | `create()` returns `MaintenanceDto` (single) | Change `create()` return type to `CreateMaintenanceResponseDto` (new DTO with `created: List<MaintenanceDto>`) |

---

## 5. Constraints inherited from PRD.md

- Flutter Clean Architecture: domain has no Flutter imports; data has no widgets; presentation uses only domain models
- One widget per file; no methods returning widgets
- All user-visible strings in `app_es.arb` via `context.l10n`
- State management: `Cubit<ResultState<T>>` or `@freezed` state for complex state
- HTTP via Retrofit + DTOs (`.toJson()` for request bodies, never manual `Map<String, dynamic>`)
- Firebase Auth token injected via interceptor
- No hardcoded URLs
- `dart analyze` must pass before completion
- `flutter test` must pass before completion

---

## 6. Acceptance criteria

1. **AC-1 — Model:** `MaintenanceModel` has `mode:MaintenanceMode` (completed/scheduled), `status` is a computed getter using vehicle's `currentMileage`, `serviceDate:DateTime?` (only for completed), `odometerAtService:int?` (only for completed), `workshop:String?`, `nextOdometer:int?` (absolute), `nextDate:DateTime?`.
2. **AC-2 — Status calc:** `MaintenanceStatus` is computed correctly: overdue if `currentMileage > nextOdometer` OR `today > nextDate`; next if within 500 km OR 30 days; upToDate otherwise. Completed records never get a status badge.
3. **AC-3 — Auto-creation:** Saving a `completed` maintenance with `nextKmInterval` and/or `nextDate` creates a second `scheduled` record server-side. Both records appear in the list immediately without pull-to-refresh.
4. **AC-4 — Relative km conversion:** Form sends `nextKmInterval` (relative interval); backend converts to absolute `nextOdometer`. Detail screen shows absolute `nextOdometer`.
5. **AC-5 — List grouping:** List shows three sections: ATRASADO (overdue scheduled), PRÓXIMAMENTE (next scheduled), AL DÍA (upToDate scheduled + all completed). Sections only appear if they have items.
6. **AC-6 — Filter status:** Status filter only affects `scheduled` records. Completed records appear only when filter is "Todos" or "Al día".
7. **AC-7 — Garage widget:** Shows two cards: left = most recent `completed` record (date + km); right = most urgent `scheduled` record (date or km + status badge). Tapping a card navigates to that record's detail screen.
8. **AC-8 — Detail screen:** Shows `serviceDate`, `odometerAtService`, `workshop`, `cost` for completed records; shows `nextDate`, `nextOdometer`, status badge for scheduled records.
9. **AC-9 — Form validation:** All validations per PRD §7.6 implemented: required fields enforce button state; `nextDate` must be future; scheduled requires at least one of nextOdometer/nextDate.
10. **AC-10 — l10n:** All new strings are in `app_es.arb`; no hardcoded UI text.
11. **AC-11 — dart analyze:** `dart analyze` passes with 0 errors.

---

## 7. Regression guardrails

| Guardrail | Verification |
|-----------|-------------|
| Existing maintenance records can still be fetched from API | `flutter test` — unit test `MaintenanceRepositoryImpl.getMaintenancesByVehicleId` still works with updated DTO |
| Delete maintenance still works end-to-end | `MaintenanceDeleteCubit` test; manual: open detail → delete → list updates |
| Update maintenance still works | `MaintenanceRepositoryImpl.updateMaintenance` test; manual: edit record, save, confirm list updates |
| Form submission does not break when `nextDate`/`nextKmInterval` are absent (completed mode, optional) | Unit test `MaintenanceFormCubit.buildMaintenanceToSave` without next fields |
| VehicleMaintenanceCubit correctly separates completed/scheduled | Unit test with mixed list; assert `lastCompleted` and `nextScheduled` are correct |
| Status calc edge cases: programado with no date AND no km → upToDate no badge | Unit test `MaintenanceStatusCalculator` (or static method) |
| Filter "Todos" shows both completed and scheduled | Widget/cubit test |
| `dart analyze` clean | Run `dart analyze` in CI |
| `flutter test` green | Run full test suite |

---

## 8. Out of scope (from PRD §14)

- Recordatorios por intervalo de tiempo configurable
- Sincronización automática de odómetro desde GPS
- Fotos adjuntas al mantenimiento
- Exportación del historial en PDF
- Mantenimientos compartidos entre usuarios del mismo vehículo
- Integración con talleres (booking)
- FCM push notifications (backend-only concern per PRD §11; not implemented in this Flutter run)

---

## 9. Open questions for the human

1. **API backward compatibility:** The current backend uses `isScheduled:bool` + `date` + `maintanceMileage`. Does the NestJS API need to be updated in the same run, or is the client-side model change expected to go out with a coordinated backend deploy? (The backend phase assumes yes — it will update rideglory-api as well.)
2. **`workshop` field:** The current `MaintenanceDto` does not have `workshop`. Is this a new field that needs a database migration in the API, or is it already in the DB schema?
3. **Existing data migration:** Existing records in the DB have `isScheduled:bool`. After the API update, how should old records be migrated to the new `mode` field? (Assumed: `isScheduled=true → mode='scheduled'`, `isScheduled=false → mode='completed'`.)
4. **`maintanceMileage` typo:** The current DB likely has a column named `maintanceMileage` (typo). Should the rename to `odometerAtService` happen at the DB level (migration needed) or only in the Flutter/API DTO mapping layer?
