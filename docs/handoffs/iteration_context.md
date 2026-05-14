# Iteration Context Bridge — Iter-2 → Iter-3

**Prepared by:** PO (po_close phase)  
**Date:** 2026-05-15  
**For:** Iter-3 planning and architecture phase

---

## Iter-2 Completion Summary

Iteration 2 closed successfully with the following deliverables:

- **SOAT Feature:** Full 3-layer Flutter implementation (domain/data/presentation) + 2 backend endpoints
- **Notification Infrastructure:** Backend table, 6 notification types, FCM triggers on registration events, cron scheduler for SOAT reminders
- **Notification Center:** Flutter UI with cursor pagination, mark-read/mark-all-read, bell badge integration
- **FCM Initialization:** Background handler pattern with @pragma + DI re-init, token registration at login
- **ManageAttendeesPage Redesign:** Design system component swap + state polish (Story 2.9)
- **Quality:** dart analyze 0 violations, flutter test 64 pass/1 pre-existing fail, 21 new test cases, architecture 8/8 gates passed

**PR #14 merged to main on 2026-05-15 (SHA: 847b12365de4851840efc35ecad086c317d5c7c4)**

---

## Key Handoffs for Iter-3

### Architecture & Contracts (From Architect)

**API Gateway Prisma** is now initialized with Notification model and 4 endpoints (list cursor, mark read, mark all read, fcm-token). The schema is production-ready and extends to vehicle-ms and user-ms.

**FCM Backend:** Firebase Admin messaging is already in api-gateway. Iter-3 will add:
- SOS push broadcast (via WebSocket + FCM multicast in tracking service)
- Maintenance reminder cron scheduler (date-based, 30 days before)
- Event reminder cron scheduler (24 hours before)

**Route Polyline Storage:** Must be stored as GeoJSON LineString in events-ms (routeGeoJson Json? field), not as encoded polyline. Backend team must coordinate this with Flutter dev before iter-3 feature work begins.

**Mapbox Migration (Story 3.0):** This is the first story and a hard blocker. No other iter-3 stories may begin until Story 3.0 is merged and dart analyze clean. Route rendering will use GeoJsonSource + LineLayer (not PolylineAnnotationManager).

### Backend Dependencies

**Iter-3 stories 3.1–3.7 depend on:**
1. Story 3.0 complete (Mapbox SDK replacement)
2. TrackingGateway service with WebSocket + FCM integration
3. POST /api/events/:eventId/tracking/start and POST .../tracking/end
4. Route GeoJSON contract (LineString format)
5. SOS deduplication guard (sosTriggeredAt timestamp on event)
6. Maintenance scheduler (date-based, 30 days before, America/Bogota timezone)
7. Event reminder scheduler (24 hours before)

### Frontend Dependencies

**Iter-3 stories depend on:**
1. Mapbox SDK installed, google_maps_flutter completely removed
2. GeoJSON parsing and route rendering (client-side route adherence check via Haversine formula over coordinates)
3. flutter_foreground_task (Android) for background GPS with IsolateNameServer bridge
4. geolocator with AppleSettings(activityType: ActivityType.automotiveNavigation) on iOS
5. VehicleModel extended with soatStatus and soatExpiryDate for Home Dashboard badge
6. SOS button + confirmation dialog UI
7. Organizer control bar (Iniciar/Terminar buttons)
8. Red pulsing SOS marker (mapbox_maps_flutter annotations API)

**Pre-flight must include:**
- Mapbox token configuration (AndroidManifest.xml + Info.plist)
- Physical device testing plan for background GPS (separate Android/iOS procedures)
- FOREGROUND_SERVICE + FOREGROUND_SERVICE_LOCATION permissions review (Play Store policy)

### QA Dependencies

**Manual device testing protocol:**
- US-2-4/2-5/2-6 from iter-2 still pending (SOAT reminders, registration pushes) — execute before iter-3 closes
- Iter-3 physical device tests required from day 1: background GPS on Android (foreground service visible), background GPS on iOS (status bar indicator)
- 7 notification types verified (SOAT 30d/7d/day-of + registration 3 types + follower type) — complete in iter-3 testing phase
- Route adherence indicator (200m Haversine check) + SOS button + marker animations verified on physical device

### Design System & L10n

**New L10n keys needed in iter-3:**
- `soat_*` keys — already added in iter-2
- `notification_*` keys — already added in iter-2
- `event_filter_*` keys — already added in iter-2
- Iter-3 new: `tracking_*`, `sos_*`, `maintenance_*` prefixes for tracking, SOS banner, maintenance cron

**Design gate for Iter-3:**
Frame qonbS must be confirmed in rideglory.pen with SOS button placement, organizer control bar visibility rules, red pulsing marker spec, and 'no phone number' empty state for story 3.2.

---

## State of Codebase Post-Iter-2

### File Counts
- **lib/features/soat/** — 6 files (3-layer: domain, data, presentation with 3 pages)
- **lib/features/notifications/** — 6 files (3-layer: domain, data, presentation + bell button + center page)
- **lib/features/vehicles/** — Extended VehicleSoatSection in vehicle detail
- **lib/core/services/fcm_service.dart** — New singleton with background handler
- **Test files** — 3 new (soat_model_test, soat_cubit_test, notifications_cubit_test)
- **app_es.arb** — ~100 new keys (soat_, notification_ prefixes)
- **app_router.dart** — 3 new GoRoute entries (soatUpload, soatStatus, soatManualForm)

### Architecture Health
- **Clean Architecture:** All 3 layers verified (domain has 0 Flutter/HTTP imports, data has 0 BuildContext, presentation routes through use cases)
- **State Management:** ResultState<T> pattern used throughout; NotificationsCubit is @lazySingleton (global across page transitions)
- **DI:** All new services registered with @injectable/@singleton; NotificationsCubit registered in root MultiBlocProvider
- **Cursor Pagination:** Enforced in NotificationsService + NotificationsCubit (no offset/limit anywhere)
- **Localization:** ~100 new keys added; zero hardcoded Spanish in widget UI
- **Testing:** 64 tests passing (1 pre-existing rider email fail); 21 new tests cover domain boundary logic + cubit state machines

### Known Constraints for Iter-3

**GoRouter DI Assessment (Deferred to Iter-4):**
GoRouter is created as a top-level variable in app_router.dart, NOT registered in GetIt. This means iter-1 NotificationRouteHandler cannot inject GoRouter directly. Iter-4 DoD includes assessing whether refactoring is needed before iter-1 can implement notification tap routing (Story 5.5). If refactoring is needed, it becomes a pre-flight task for iter-1.

**Background GPS Platform Differences:**
- Android: flutter_foreground_task shows persistent "Rideglory — Rodada activa" notification (non-dismissable)
- iOS: System blue location indicator in status bar (Apple manages, no custom notification text)

This is acceptable for MVP but UX will differ between platforms.

**Mapbox Cocoapods Cache:**
After Story 3.0 merges, DevOps must update Cocoapods cache key in GitHub Actions CI. Mapbox iOS binary framework download (~200MB via SPM) adds 5–10 minutes per CI run — cache will help significantly.

---

## Iter-3 Starting Checkpoint

### Pre-flight Checklist
- [ ] Story 3.0 (Mapbox migration) scoped and architecture reviewed
- [ ] Frame qonbS confirmed in rideglory.pen (SOS button, organizer controls, pulsing marker)
- [ ] Backend team ready with Story 3.0 migration (remove google_maps import, add mapbox_maps_flutter)
- [ ] TrackingGateway service architected and API contracts defined (route GeoJSON, tracking start/end, SOS broadcast)
- [ ] Physical device + emulator test harness prepared (separate iOS/Android background GPS procedures)
- [ ] L10n inventory prepared (tracking_, sos_, maintenance_ key prefixes)
- [ ] Build runner run confirmed (no code generation changes required from iter-2)

### Expected Duration
- Story 3.0 (Mapbox): 1–2 days (4 Dart files, 4 native/config files, route preview widget rewrite)
- Stories 3.1–3.4 (Tracking UX + SOS): 3–4 days (UI, WebSocket integration, FCM broadcast)
- Story 3.5 (Background GPS): 2–3 days (platform-specific foreground service + location handler)
- Stories 3.6–3.7 (Maintenance + Event reminders): 1–2 days (cron scheduler, UI integration)

**Total Estimated:** 8–12 days

### Risk Factors (From Plan)
- Story 3.0 is the critical path blocker — maps SDK migration is high-risk (route rendering changes, native config, Cocoapods binary download)
- Background GPS on restricted devices (Xiaomi, Samsung) difficult to test in emulator — physical device testing mandatory from day 1
- Mapbox binary framework adds CI time — cache update required post-Story 3.0

---

## Handoff Completeness

| Document | Status | Path |
|----------|--------|------|
| Iteration Summary | ✅ DONE | docs/ITERATION_SUMMARY_2.md |
| Iteration History | ✅ UPDATED | docs/ITERATION_HISTORY.md (row 2 added) |
| Product Status | ✅ UPDATED | docs/PRODUCT_STATUS.md (SOAT section moved to shipped, notifications expanded) |
| Architecture | ✅ COMPLETE | docs/handoffs/architect.md (full spec for iter-3) |
| Backend | ✅ COMPLETE | docs/handoffs/backend.md (6 endpoints merged, 28 tests) |
| Frontend | ✅ COMPLETE | docs/handoffs/frontend.md (16 new files, 64 tests pass) |
| QA | ✅ COMPLETE | docs/handoffs/qa.md (21 test cases, device testing protocol) |
| DevOps | ✅ COMPLETE | docs/handoffs/devops.md (CI validated, no changes) |
| Tech Lead | ✅ APPROVED | docs/handoffs/tech_lead.md (PR #14 approved, 4 violations fixed) |
| Iteration Context | ✅ THIS FILE | docs/handoffs/iteration_context.md |

---

## Next Steps for Iter-3 Agent

1. **Read this file** (you are here) for context on iter-2 deliverables and iter-3 dependencies
2. **Read ITERATION_SUMMARY_2.md** for full iter-2 closure details
3. **Coordinate with architect:** Review iter-3 architecture, Story 3.0 Mapbox migration spec, API contracts for tracking/SOS
4. **Coordinate with design:** Confirm frame qonbS for SOS/organizer controls; flag any ambiguities before pre-flight
5. **Coordinate with backend:** Finalize route GeoJSON contract, tracking service API, SOS broadcast spec, cron scheduler format
6. **Pre-flight planning:** Build checklist, schedule physical device testing, prepare build runner run if needed
7. **Begin planning document:** Update docs/PLAN.md with iter-3 scope, stories, and task breakdown

---

## Questions for Next Iteration

- **Route GeoJSON Format:** Confirm exact LineString schema (coordinates array format, geometry vs. properties split)
- **SOS Deduplication:** How long should sosTriggeredAt prevent duplicate broadcasts? (Suggested: 30 seconds)
- **Background GPS Accuracy:** Minimum accuracy threshold for location updates? (Suggested: 20m for tracking)
- **Cron Timezone:** Confirm America/Bogota is correct for all event/maintenance schedulers (from iter-2 SOAT pattern)
- **Organizer Control Visibility:** Should Iniciar/Terminar buttons only appear if user == event.organizerId? (Verify in frame qonbS)
- **Route Adherence Threshold:** 200m Haversine check is in spec — confirm this is correct for "Fuera de ruta" warning threshold

---

**Prepared for:** Iteration 3 PO, Architect, Design, Backend, Frontend teams  
**Status:** Ready for next iteration planning session
