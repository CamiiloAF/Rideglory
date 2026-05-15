# PO Handoff — Iteration 3

**Date:** 2026-05-15
**Status:** in progress

---

## Iteration goal

Complete the real-time tracking experience with SOS alert, organizer ride controls, background GPS, date-based maintenance reminders, and migrate the maps SDK from `google_maps_flutter` to `mapbox_maps_flutter` as a single unified SDK — leaving riders fully connected during active events.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
|----|-------|---------------------|---------------|
| US-3-0 | As the dev team, the project uses `mapbox_maps_flutter` as the sole maps SDK; `google_maps_flutter` and `geocoding` have been eliminated completely. | `pubspec.yaml` declares `mapbox_maps_flutter ^2.2.0`; `google_maps_flutter` and `geocoding` are absent from `pubspec.yaml` and `pubspec.lock`. `dart analyze` passes with zero errors or warnings in `lib/`. Zero `google_maps_flutter` or `geocoding` imports remain in `lib/`. `live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart`, and `route_map_preview.dart` compile and render correctly on a physical device. `route_map_preview.dart` uses `PlaceService` (Retrofit async) for address lookup; loading and error states handled with `ResultState`. `AndroidManifest.xml` contains Mapbox token meta-data; `Info.plist` contains `MBXAccessToken`; no Google Maps API key remains in native config. iOS CocoaPods install completed; app builds in simulator. This story must be merged and `dart analyze` must be clean **before any other iter-3 story begins**. | frontend |
| US-3-1 | As a rider in an active event, I can press the red SOS button visible on the tracking map, confirm the alert in a dialog, and all other riders in the event receive an emergency push notification with my name and location. | SOS alert processed in under 5 seconds from confirmation tap. The rider's map marker changes to a red pulsing indicator on all other participants' maps. A red banner with the rider's name appears on all other participants' screens. The confirming rider sees a "SOS enviado" confirmation. If the rider's phone number is not registered, only the "Localizar" action appears (not "Llamar"). | frontend, backend |
| US-3-2 | As a rider seeing an SOS alert on the tracking map, I can tap the SOS banner for the rider in crisis and access two actions: Call (native dialer) and Locate (Google Maps / Apple Maps with navigation). | Both actions are functional on iOS and Android. "Llamar" is only shown if the rider has a registered phone number. "Localizar" deep-links to Google Maps (Android) or Apple Maps (iOS) with navigation to the rider's last known coordinates. Actions visible to any participant, not just the organizer. | frontend |
| US-3-3 | As the organizer of a scheduled event, I can start the ride from the event detail screen, transitioning the event to `in_progress` state and enabling live tracking for all approved registrants. | "Iniciar rodada" button is only visible to the event organizer on the event detail page. Tapping it shows a confirmation dialog. On confirmation, the backend transitions the event to `in_progress`; all approved riders immediately see the CTA on the event detail change to "Ver rastreo". | frontend, backend |
| US-3-4 | As the organizer of an active event, I can end the ride from the tracking screen, transitioning the event to `finished` and closing the tracking screen for all connected riders. | "Terminar rodada" button visible only to the organizer on the tracking screen. On confirmation, event transitions to `finished` in the backend; all connected WebSocket clients receive a termination signal and the tracking screen closes for all participants; a push notification "La rodada ha terminado" arrives in under 10 seconds. | frontend, backend |
| US-3-5 | As a rider in an active event with the app in the background, the app continues sending my location to the WebSocket every 5 seconds. On Android, a non-dismissable persistent notification "Rideglory — Rodada activa" is displayed. On iOS, the system location indicator is visible. | Android: location updates continue with app in background; foreground service notification is visible and non-dismissable (verified on physical device). iOS: location updates continue; system blue location indicator is visible (native behavior, verified on physical device). Logs from both platforms attached to the PR. | frontend |
| US-3-6 | As a rider with a scheduled maintenance record (date-based), I receive a push notification 30 days before the scheduled date. | Push is scheduled when the maintenance record is saved with a future date. Notification text includes the service type and motorcycle name in Spanish. Push arrives within a 5-minute window of the scheduled time. Notification appears in the notification center. | backend, frontend |
| US-3-7 | As an approved registrant of a future event, I receive a push reminder notification 24 hours before the event start time. | Push arrives between 23h 55min and 24h 5min before the event's scheduled start time. Notification text includes the event name. Notification appears in the notification center. | backend |
| US-3-8 | As the dev team, `dart analyze` passes with zero violations, all existing tests remain green, and Story 3.0's Mapbox migration passes a widget test before merging. | `dart analyze`: 0 errors, 0 warnings on the final feature branch. `flutter test`: all pre-existing passing tests continue to pass (no new failures). Widget test for `route_map_preview.dart` passes before Story 3.0 PR merges. No hardcoded Spanish strings — all new user-visible text in `app_es.arb`. No `google_maps_flutter` or `geocoding` imports in `lib/`. Location usage descriptions in `Info.plist` written in clear Spanish. Physical device logs for background GPS (Android + iOS) attached to PR. | qa |

---

## Task definitions

| Task ID | Description | Agent | Status |
|---------|-------------|-------|--------|
| T-3-1 | Migrate `google_maps_flutter` → `mapbox_maps_flutter`: update `pubspec.yaml`, native configs (AndroidManifest.xml, Info.plist), refactor `live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart`, `route_map_preview.dart`. Add widget test for `route_map_preview.dart`. Must be merged before T-3-2 begins. | frontend | backlog |
| T-3-2 | Backend: implement `POST /api/events/:eventId/tracking/start` and `POST /api/events/:eventId/tracking/end` in `api-gateway/src/tracking/`. Guard: organizer only. | backend | backlog |
| T-3-3 | Backend: implement SOS handler in `TrackingGateway` — receive `{ type: "sos" }` WS message, broadcast `sos_alert` to all event participants via WebSocket, dispatch FCM multicast push to all approved registrants; deduplicate with `sosTriggeredAt` on events-ms. | backend | backlog |
| T-3-4 | Backend: implement `GET /api/events/:eventId/route` in events-ms returning `routeGeoJson` (GeoJSON LineString, stored as `routeGeoJson Json?` on Event model). | backend | backlog |
| T-3-5 | Backend: add `NotificationSchedulerService` cron entries in api-gateway for maintenance date-based reminder (30d, America/Bogota timezone) and 24h event reminder. Uses `@nestjs/schedule`. | backend | backlog |
| T-3-6 | Flutter: implement SOS button + confirmation dialog on tracking map; SOS banner with Llamar/Localizar actions; red pulsing marker for rider in SOS state using `mapbox_maps_flutter` annotations API. | frontend | backlog |
| T-3-7 | Flutter: implement organizer "Iniciar rodada" / "Terminar rodada" controls in `EventDetailPage` and `EventTrackingPage`; `LiveTrackingCubit` emits `TrackingFinished` on `tracking.event.ended` WebSocket event; tracking screen auto-closes for all riders. | frontend | backlog |
| T-3-8 | Flutter: implement background GPS — `flutter_foreground_task` on Android (foreground service isolate + `IsolateNameServer`; `configureDependencies()` called in `onStart()`); `geolocator` with `AppleSettings(activityType: ActivityType.automotiveNavigation)` on iOS. | frontend | backlog |
| T-3-9 | Flutter: render event route as GeoJSON LineString on tracking map using `GeoJsonSource + LineLayer`; implement route adherence chip ("En ruta ✓" / "Fuera de ruta ⚠") with 200m Haversine check client-side. | frontend | backlog |
| T-3-10 | Flutter: add `soatStatus` and `soatExpiryDate` to `VehicleModel`; display Home Dashboard SOAT badge on main vehicle card (deferred from iter-2). | frontend | backlog |
| T-3-11 | QA: widget test for `route_map_preview.dart` (pre-condition for T-3-1 merge); `dart analyze` + `flutter test` gate; physical device background GPS logs; verify zero `google_maps_flutter`/`geocoding` imports; verify `app_es.arb` updated for all new strings. | qa | backlog |
| T-3-12 | DevOps: update CocoaPods cache key in GitHub Actions CI immediately after Story 3.0 (T-3-1) merges (~200MB Mapbox binary framework). Update `DEPLOY.md` with background GPS device test requirements. | devops | backlog |

---

## Assumptions and open questions

- **Story 3.0 is an absolute blocker (confirmed):** No iter-3 story other than 3.0 may be implemented until the Mapbox migration is merged and `dart analyze` is clean. This is documented in the PLAN.md definition of done and enforced by the iteration checkpoint.
- **GeoJSON LineString format (confirmed by architect):** Route polyline is stored as `routeGeoJson Json?` on the Event model in events-ms, not as a Google-encoded polyline string per PRD §17.2. Prisma migrate reset discards existing event data so no legacy migration is needed. Flutter renders with `GeoJsonSource + LineLayer` — not `PolylineAnnotationManager`.
- **Date-based maintenance reminders only (confirmed):** Story 3.6 covers only date-based reminders (30 days before scheduled date). Km-based reminders (requiring odometer tracking) are deferred post-MVP per PLAN.md deferred items.
- **Android foreground service untestable in emulator (known risk):** Physical device testing is mandatory for US-3-5 on both Android and iOS. CI pipeline cannot substitute for device verification. Logs must be attached to the PR.
- **SOS is send-only in v1 (confirmed):** The SOS sender cannot cancel their own SOS alert in the MVP. Only the WebSocket reconnection or event end will clear SOS state. This is documented as a scope decision.
- **FCM for SOS (confirmed by PLAN.md):** SOS alerts are sent via both WebSocket (in-app, real-time) and FCM push (for riders with app in background). The iter-2 FCM infrastructure is already deployed and can be reused.
- **Home Dashboard SOAT badge (moved from iter-2):** The PLAN.md and iter-2 DoD both explicitly defer the Home Dashboard SOAT badge to iter-3. `VehicleModel.soatStatus` and `VehicleModel.soatExpiryDate` are added in this iteration.
- **iter-2 infrastructure available:** This iteration depends on the FCM infrastructure (iter-2): push dispatch from api-gateway, `notifications` table, `NotificationSchedulerService` skeleton. These are assumed complete per iter-2's definition of done.

---

## Out of scope (this iteration)

- **Km-based maintenance reminders:** Requires automatic odometer tracking system not defined in the PRD. Deferred post-MVP.
- **SOS sender cancel / dismiss:** Organizer SOS dismiss deferred to post-MVP per skill scope boundaries.
- **Followers and social layer:** Iter-4.
- **Deep links (event sharing):** Iter-5.
- **Apple Sign-In:** Iter-5.
- **Notification tap routing (deep navigation from push):** Iter-5 (NotificationRouteHandler).
- **SOAT OCR auto-fill:** Deferred post-MVP per PLAN.md.
- **New vehicle management screens** beyond SOAT badge update: no form changes.

---

## Next agent needs to know

### architect
- Story 3.0 (Mapbox migration) is the highest-risk task. Review the 4 Dart files (`live_map_widget.dart`, `live_map_page.dart`, `initials_marker_icon.dart`, `route_map_preview.dart`) and 4 native/config files. Confirm `PlaceService` (Retrofit async) replaces the synchronous `geocoding` call in `route_map_preview.dart` with proper `ResultState` handling.
- Confirm `GeoJsonSource + LineLayer` API usage pattern for the route polyline (NOT `PolylineAnnotationManager`).
- Confirm `flutter_foreground_task` + `IsolateNameServer` bridge pattern for Android background GPS; `configureDependencies()` must be called in `onStart()`.
- Confirm `VehicleModel` extension: `soatStatus` and `soatExpiryDate` fields added cleanly; `VehicleDto` updates accordingly.
- Document whether `TrackingGateway` SOS handler should sit in api-gateway (WebSocket gateway) or events-ms (where `sosTriggeredAt` deduplication lives). Clear the boundary.

### backend
- **Start with T-3-2** (tracking start/end endpoints) and T-3-4 (route GeoJSON endpoint) before T-3-3 (SOS handler). The SOS handler depends on being able to look up event participants.
- SOS deduplication guard: add `sosTriggeredAt DateTime?` to the Event model in events-ms; SOS WS handler checks if `sosTriggeredAt` is already set — if so, do not re-broadcast or re-send FCM.
- Cron expressions for T-3-5 must use `America/Bogota` timezone. Use `@nestjs/schedule`'s `ScheduleModule` (already configured in api-gateway from iter-2).
- FCM multicast for SOS must target all approved registrant tokens for the event. Reuse the token lookup pattern from iter-2.
- `GET /api/events/:eventId/route` must return GeoJSON LineString (`routeGeoJson` field from events-ms Event model).

### frontend (Flutter Dev)
- **Do not start any story other than 3.0 until T-3-1 is merged and `dart analyze` is clean.**
- For Story 3.0: the sync `geocoding` lookup in `route_map_preview.dart` must become a debounced async `PlaceService` Retrofit call with `ResultState<AddressModel>` state (loading skeleton, error banner, data render).
- For the SOS marker: use `mapbox_maps_flutter` annotations API to add a custom annotation for the rider in SOS state. If pulsing animation is not natively available, use a `AnimationController` with an overlay widget as fallback — document the approach in the PR.
- Background GPS: `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` permissions must be declared in `AndroidManifest.xml`. Include Play Store policy note in PR description.
- Route adherence Haversine check is client-side over GeoJSON coordinate array. No Mapbox decoder library needed.
- `VehicleModel.soatStatus` must use the existing `SoatStatus` enum or equivalent domain value from iter-2. Coordinate with architect.

### qa
- **Widget test for `route_map_preview.dart` is a hard gate for T-3-1 merge.** Write the test before the frontend opens the PR.
- `dart analyze` must pass with zero violations after T-3-1 merges (especially no lingering `google_maps_flutter` imports).
- Background GPS physical device test is mandatory: two platforms, separate test plans (Android foreground service + iOS background location). Logs must be attached to PR as evidence.
- Verify `Info.plist` location usage descriptions are in clear Spanish (required for App Store review).

### devops
- Update CocoaPods cache key in GitHub Actions **immediately after T-3-1 merges**. The Mapbox binary framework is ~200MB and will break CI if the cache key is stale.
- Document background GPS physical device test steps in `DEPLOY.md`.

---

## Change log

- 2026-05-15: Iteration 3 scoped from approved PLAN.md. 8 user stories (US-3-0 through US-3-8). 12 tasks (T-3-1 through T-3-12). Scope decisions: Story 3.0 absolute blocker; GeoJSON LineString format confirmed; date-only maintenance reminders; km reminders deferred; Home Dashboard SOAT badge moved from iter-2; SOS sender-cancel deferred post-MVP; CocoaPods cache update added as devops task.
