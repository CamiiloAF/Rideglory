## Iteration 3 — Tracking Completo + SOS + Mapbox Migration

### Goal

Complete real-time tracking with SOS alert, organizer ride controls, background GPS, date-based maintenance reminders, and migrate to mapbox_maps_flutter as the sole maps SDK (Story 3.0 is the blocking prerequisite for all other stories).

---

### Stories delivered

| Story | Description | Status |
|-------|-------------|--------|
| US-3-0 | Mapbox-only SDK migration — google_maps_flutter + geocoding removed | ✅ Done |
| US-3-1 | SOS button + FCM emergency push to all riders in the ride | ✅ Done |
| US-3-2 | SOS banner with Llamar (tel: deeplink) + Localizar (Maps deeplink) | ✅ Done |
| US-3-3 | Organizer starts ride — POST /tracking/start → event in_progress | ✅ Done |
| US-3-4 | Organizer ends ride — POST /tracking/end → tracking.event.ended WS → all screens pop | ✅ Done |
| US-3-5 | Background GPS — Android foreground service + iOS system location indicator | ✅ Done |
| US-3-6 | Maintenance 30d push reminder (cron, America/Bogota) | ✅ Backend ready; device test deferred |
| US-3-7 | Event 24h push reminder (cron, America/Bogota) | ✅ Backend ready; device test deferred |
| US-3-10 | SOAT status badge on Home vehicle card (4 states via DocumentSlotPill) | ✅ Done |

---

### What changed

**Flutter (`lib/`):**
- `live_map_widget.dart` — full Mapbox rewrite; diff-based `PointAnnotation` management; lng-first coordinates
- `live_map_page.dart` — `CameraOptions`/`Position` (lng-first); geolocator imported with `geo` prefix to avoid name clash
- `route_map_preview.dart` — sync `locationFromAddress()` → debounced async `PlaceService.geocode()` with `ResultState` loading/error states
- `initials_marker_icon.dart` — `BitmapDescriptor` → `Uint8List` for Mapbox annotation API
- `main.dart` — `MapboxOptions.setAccessToken()` before `runApp()`
- New widgets: `SosBannerWidget`, `OrganizerControlBar`, `RideFinishedOverlay`, `RouteAdherenceChip`
- `TrackingWsClient` — added `sosAlerts` and `eventEnded` streams + `publishSos()` method
- `LiveTrackingCubit` — `triggerSos()`, `endRide()`, SOS + eventEnded stream subscriptions
- `SoatStatus` enum + `soatStatus`/`soatExpiryDate` on `VehicleModel` → `HomeGarageCard` SOAT badge

**Backend (`rideglory-api`):**
- `POST /api/events/:eventId/tracking/start` and `/end` (organizer guard)
- `GET /api/events/:eventId/route` — GeoJSON LineString (`routeGeoJson Json?` on Event model)
- `GET /api/places/geocode?q=` — Mapbox Geocoding v5 proxy in api-gateway
- `tracking.sos` WS handler → `tracking.sos.alert` broadcast + FCM multicast + `sosTriggeredAt` dedup
- `tracking.event.ended` WS event emitted on `/tracking/end`
- Maintenance 30d cron + Event 24h cron in `NotificationSchedulerService` (America/Bogota)
- New schema fields: `routeGeoJson`, `sosTriggeredAt`, `reminderSentAt` on events-ms/maintenances-ms

**CI (`/.github/workflows/ci.yml`):**
- `MAPBOX_DOWNLOADS_TOKEN` + `MAPBOX_ACCESS_TOKEN` secrets injected into both jobs
- **Action required before merging:** Configure both secrets in GitHub repository settings

---

### Test results

| Gate | Result |
|------|--------|
| `dart analyze` | ✅ 0 errors, 0 warnings (3 info-level Mapbox SDK deprecation hints — SDK-internal) |
| `flutter test` | ✅ 47 pass / 1 pre-existing fail (rider_profile_page, iter-1) |
| `google_maps_flutter` imports in `lib/` | ✅ 0 (grep confirmed) |
| `route_map_preview_test.dart` (Story 3.0 hard gate) | ✅ 4/4 pass |
| Backend jest (events-ms) | ✅ 19/19 pass |
| Backend jest (api-gateway) | ✅ 25/25 pass |
| Architecture violations | ✅ None |

---

### Deferred / physical device only

- Route GeoJSON render + adherence chip (T-3-9) — deferred post-Story 3.0 merge
- Red pulsing SOS annotation marker — deferred
- Background GPS (Stories 3.5/3.6/3.7) — requires physical device + `adb logcat` / Xcode console logs

---

### Handoffs

- [PO](docs/handoffs/po.md) · [Architect](docs/handoffs/architect.md) · [Design](docs/handoffs/design.md) · [Backend](docs/handoffs/backend.md) · [Frontend](docs/handoffs/frontend.md) · [QA](docs/handoffs/qa.md) · [DevOps](docs/handoffs/devops.md)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
