# 02-po-proposal.md

**Slug:** event-tracking-fixes
**Timestamp:** 2026-06-20T00:06:55Z

---

## Fases propuestas

| # | Title | Goal | Summary |
|---|-------|------|---------|
| 1 | WS Cleanup on Event End (Flutter) | When a live ride ends remotely, a rider's GPS and WebSocket stop automatically — no leaked connections or battery drain. | Modify `LiveTrackingCubit._subscribeToEventEnded()` to cancel `_positionSubscription`, call `StopTrackingUseCase`, and call `TrackingWsClient.leaveSession()` before emitting `isFinished: true`. Add a unit test covering this cleanup path. The app remains functional: the tracking screen already handles `isFinished` to exit the tracking view. |
| 2 | Event List Date Filter (Flutter) | Riders browsing events see only today's and future events by default — no stale past events in the list. | In `EventsCubit.fetchEvents()`, pass `dateFrom = startOfToday` as a floor when the user has not applied a manual date filter. The backend already supports the `dateFrom` query param. No backend changes needed. Home screen is already correct via `findUpcoming`. |
| 3 | Auto-End Events After 24 Hours (Backend) | Rides that the organizer forgot to end are automatically closed after 24 hours — participants receive an FCM notification and WebSocket clients disconnect cleanly. | Add a cron job in `api-gateway` (where `@nestjs/schedule` is already installed) inside `NotificationSchedulerService`. The job runs hourly, finds `IN_PROGRESS` events whose `startDate` is ≥ 24 h in the past, and for each: (a) calls a new `forceEndTracking(eventId)` method on `events-ms` (bypasses the owner check), (b) broadcasts `tracking.event.ended` via `TrackingBroadcaster`, (c) sends FCM to approved registrants via the existing notifications path. `events-ms` gets two additions: `findActiveEventsOlderThan(cutoffDate)` query and `forceEndTracking(eventId)` method + MessagePattern. |

---

## Supuestos

- `EventState.IN_PROGRESS` is the only state for active/live rides; events in `SCHEDULED`, `DRAFT`, `CANCELLED`, or `FINISHED` are never touched by the auto-end cron.
- The 24-hour window is a fixed product decision for v1; no env-var configurability required in this plan.
- All events are single-day (no multi-day rides that should survive past 24 h of their `startDate`).
- The home screen `GET /home → findUpcoming` already filters to future events and does NOT need to be changed.
- The backend `GET /api/events?dateFrom=` already applies the filter server-side and is stable; no contract change needed for Phase 2.
- `TrackingWsClient.leaveSession()` already sets `_manualDisconnect = true` and closes the channel correctly — confirmed in scan.
- FCM notifications reach riders via the existing `sendEventEndedNotifications` path; the cron replicates (not replaces) this logic.
- Phases 1 and 2 are Flutter-only and fully independent of Phase 3 (backend). They can be executed in any order, though the ordering 1 → 2 → 3 goes from lowest to highest complexity.

---

## Riesgos

- **Owner-check bypass (Phase 3):** `events-ms.endTracking()` enforces `authUserId === ownerId`. A new `forceEndTracking()` method sidesteps this. If not carefully scoped (internal-only MessagePattern, no HTTP route), it becomes a privilege-escalation vector.
- **TrackingService in-memory rooms (Phase 3):** `TrackingService` keeps rider rooms in memory. When the cron auto-ends an event, connected riders receive `tracking.event.ended` via WS broadcast, but the in-memory room is not cleaned up unless `TrackingService.removeRoom(eventId)` is called. Stale rooms waste memory on a live server.
- **Duplicate FCM path (Phase 3):** `sendEventEndedNotifications()` is a private method on `TrackingHttpController`. The cron either needs to extract it to a shared service or duplicate the logic. Duplication risks drift; extraction adds scope.
- **Test coverage gap (Phase 1):** The existing `live_tracking_cubit_analytics_test.dart` does not cover the `eventEnded → cleanup` path. Without a new test, a regression in this critical flow could go undetected.
- **`dateFrom` timezone handling (Phase 2):** "Start of today" depends on the user's local timezone vs. UTC. If computed as UTC midnight, riders in UTC-5 see events from 5 hours in the past. Should use local midnight converted to UTC, or filter with a small buffer.
- **Cron concurrency (Phase 3):** If the hourly cron takes longer than 1 hour (unlikely but possible with many events), a second invocation could start before the first finishes, causing double-processing. The existing reminder cron has no guard against this; a simple try/catch-and-log is the minimum mitigation.

---

## Criterios de éxito globales

1. **Phase 1 — WS Cleanup:** After receiving `tracking.event.ended`, `LiveTrackingCubit` emits `isFinished: true` AND the GPS subscription is cancelled AND the WS connection is closed with no auto-reconnect. A new unit test verifies this in CI (`flutter test` passes).
2. **Phase 2 — Date Filter:** Opening the events list without any manual filter shows zero events whose `startDate` is before the start of today in the device's local timezone. `dart analyze` reports no new violations.
3. **Phase 3 — Auto-End Cron:** An event left `IN_PROGRESS` for 25 hours is automatically moved to `FINISHED` by the next hourly cron run. Approved registrants receive an FCM push. Connected WS clients receive `tracking.event.ended` and disconnect cleanly (thanks to Phase 1). No event is processed twice. Backend tests pass.
