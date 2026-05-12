# PO Proposal — Rideglory Iteration Plan

> **Author:** Product Owner agent
> **Generated:** 2026-05-12
> **Input:** `docs/PRD.md` v1.0, `docs/handoffs/planning/00-existing-system-scan.md`
> **Status:** Draft — awaiting Architect and Plan Reviewer sign-off

---

## Executive Summary

- **Brownfield app with solid core.** Authentication, vehicles, events, event registration, maintenance, and live tracking are largely implemented. The system scan confirms 9 feature folders, 17 cubits, 15+ pages, and 40+ API endpoints operational. Remaining gaps are high-value additions (SOAT, AI, notifications, SOS) plus a critical quality deficit (0% test coverage).
- **Test coverage is the highest-urgency risk.** The codebase has a single empty test file. Without a working test suite, CI cannot pass and regression detection is impossible. Rather than a dedicated test-only sprint, each feature iteration will carry a `HU-TEST` slice for the features introduced that iteration, and Iteration 1 will establish the test infrastructure and backfill critical existing features.
- **Profile feature is an immediate gap.** The profile page exists as a UI stub with no data binding. This blocks a complete rider experience and should be resolved early (Iteration 2), alongside user display in the attendee and detail pages.
- **Design (HU-DESIGN-01) is parallel, not blocking.** No Flutter code changes are involved; the Pencil work can start at Iteration 1 and continue across iterations. It is flagged as a parallel design-only track and does not hold up development timelines.
- **Advanced features ordered by dependency and risk:** SOAT (full-stack, AI extraction) → AI event cover generation (backend + wiring existing UI) → AI recommendations (backend + wiring existing UI) → Push notifications + SOS (FCM infra + WebSocket extension). AI and notification features come last because they have external service dependencies and the highest integration risk.

---

## Iteration Proposals

---

### Iteration 1 — Test Infrastructure + Profile Feature Completion

**Goal:** Establish a working test suite for the most critical existing features and complete the profile feature stub so the rider experience is coherent end-to-end.

**Why now:** Without tests, every subsequent iteration ships blind. Profile is the most visible stub gap — riders see an empty page after tapping their own name. Both items have no external dependencies (no new backend endpoints, no new packages) and unlock confidence for everything that follows.

**User stories:**
- HU-TEST-01a: As the dev team, we have unit tests for VehicleCubit, EventsCubit, EventDetailCubit, and MaintenancesCubit covering initial/loading/data/empty/error states so regressions are caught automatically.
- HU-TEST-01b: As the dev team, we have widget tests for the vehicle garage page, event list page, and event detail page covering all `ResultState` UI branches so the design system renders correctly under every condition.
- HU-PROFILE-01: As a rider, I tap my profile in the bottom navigation and see my name, photo, and main vehicle so I feel recognized as a community member.

**Acceptance criteria (summary):**
- `flutter test` passes with at least 20 test cases across unit and widget layers for the covered cubits and pages.
- `dart analyze` passes with zero violations.
- Profile page displays the logged-in rider's name, profile photo (or placeholder), and their main vehicle pulled from the existing `UserService` and `VehicleCubit`.
- No hardcoded strings — all new UI text is in `app_es.arb`.
- Integration test stub files created for authentication, vehicles, and events (`integration_test/` `group` blocks defined, not necessarily running against backend).

**Agents:** frontend | qa

**Estimated complexity:** M

**Dependencies:** Iteration 0 (done)

---

### Iteration 2 — Event Discovery Filters + Attendee Profile Links

**Goal:** Make event discovery fully functional by wiring the existing filter UI and enabling riders to tap into other riders' profiles from the event attendee list.

**Why now:** Event discovery filters exist in the form but are not wired — riders see all events with no way to narrow by type, date, or location. The attendees page has no profile navigation, making community discovery impossible. These are low-risk completions of existing UI (no new architecture, no new backend endpoints needed beyond what the existing `GET /events` already supports via query params).

**User stories:**
- HU-EVENT-FILTER-01: As a rider browsing events, I tap the filter icon on the event list and select event type, date range, and location so I see only relevant upcoming rides.
- HU-EVENT-FILTER-02: As a rider, I can clear active filters with one tap so I return to the full event list without navigating away.
- HU-ATTENDEE-PROFILE-01: As a rider viewing the attendee list of an event, I tap another rider's name or photo and see their profile page (name, vehicles) so I can learn about the community members joining the same ride.

**Acceptance criteria (summary):**
- Filter sheet passes `type`, `dateFrom`, `dateTo`, and `location` query params to `GET /events` (or `/events/upcoming`).
- Active filters are visually indicated (badge or chip) on the list header.
- Tapping a rider in the attendee list navigates to a read-only rider profile page populated from `GET /users/:id`.
- Unit tests for filter parameter construction and `EventsCubit` filter state transitions.
- Widget test for filtered empty state ("No hay eventos con estos filtros").
- `dart analyze` + `flutter test` pass.

**Agents:** backend | frontend | qa

**Estimated complexity:** M

**Dependencies:** Iteration 1

---

### Iteration 3 — SOAT & Mandatory Insurance Documents

**Goal:** Allow riders to upload their SOAT insurance PDF per vehicle, have the backend extract the expiration date via AI (Claude Haiku), confirm or correct it, and see a visual validity indicator on their garage.

**Why now:** This is the largest new full-stack feature in the PRD. It touches all three Clean Architecture layers plus a new backend service and a Claude API integration. Placing it after test infrastructure and before AI/notification features allows it to be developed against a stable, partially-tested codebase and sets the pattern for Claude API usage that HU-AI-01 and HU-AI-02 will reuse.

**User stories:**
- HU-SOAT-01a: As a rider, I open a vehicle's detail page, tap "Documentos obligatorios", and upload my SOAT PDF from my phone so I can keep my insurance records in the app.
- HU-SOAT-01b: As a rider, after uploading my SOAT PDF, I see the extracted expiration date pre-filled in a confirmation form, edit it if it's wrong, and save it so the correct date is stored.
- HU-SOAT-01c: As a rider viewing my garage, I see a colored badge on each vehicle card (Vigente / Por vencer / Vencido) based on the saved expiration date so I can spot an expired SOAT at a glance.

**Acceptance criteria (summary):**
- `POST /vehicles/my/:vehicleId/insurance` backend endpoint accepts a PDF upload and returns `{ expirationDate: string, docType: string }`.
- Claude Haiku extracts the expiration date from the PDF; if extraction fails, the endpoint returns a 422 with a clear error so the Flutter app shows a manual entry form.
- PDF stored in Firebase Storage at `insurance/{userId}/{vehicleId}/soat.pdf`.
- `InsuranceDocumentModel` lives in the domain layer with no Flutter imports.
- `InsuranceDocumentDto` is generated via `json_serializable`.
- Garage vehicle cards show expiration status badge; vehicles with no uploaded document show no badge.
- Unit tests for `InsuranceDocumentCubit` (initial/loading/data/error states) and the AI extraction use case (happy path + extraction-failure path).
- Widget tests for the upload form (loading state, success, AI failure → manual entry fallback).
- `dart analyze` + `flutter test` pass.

**Agents:** design | backend | frontend | qa

**Estimated complexity:** L

**Dependencies:** Iteration 1

---

### Iteration 4 — AI Event Cover Image Generation

**Goal:** Wire the existing "Generar portada con IA" button in the event creation form to a backend endpoint that generates a cover image, so organizers can publish visually rich events without manual design work.

**Why now:** The UI entry point already exists (button in `EventFormPage`). The backend is the only blocker. After Iteration 3 establishes the Claude API integration pattern in rideglory-api, this iteration can reuse that infrastructure for image generation. Placing it before recommendations avoids building AI infra twice.

**User stories:**
- HU-AI-01a: As an event organizer filling out the event creation form, I tap "Generar portada con IA" and see a loading indicator while the app generates a cover image based on the event title, type, and location.
- HU-AI-01b: As an organizer, after the cover image is generated, I see a preview in the form and can either accept it, regenerate, or replace it with my own photo so I stay in control of the event's visual presentation.

**Acceptance criteria (summary):**
- `POST /events/generate-cover` backend endpoint accepts `{ title, type, location }` and returns `{ imageUrl }`.
- Image is stored in Firebase Storage and the URL is returned; the Flutter form populates the cover image field with it.
- The organizer can regenerate (calls the endpoint again) or clear and pick from gallery.
- If generation fails, a Spanish error snackbar is shown and the form remains usable.
- Image generation is non-blocking — the form can be submitted without a cover image.
- Unit test for the generate-cover use case (happy + error path).
- Widget test for the form button states (idle, loading, preview-shown, error).
- `dart analyze` + `flutter test` pass.

**Agents:** backend | frontend | qa

**Estimated complexity:** M

**Dependencies:** Iteration 3 (for Claude API integration pattern in rideglory-api)

---

### Iteration 5 — AI Event Recommendations

**Goal:** Populate the existing recommendations section on the home dashboard with personalized event suggestions, so riders discover relevant rides without manual browsing.

**Why now:** The UI card already exists on the dashboard (per scan). The backend logic is a standalone scoring service with no dependency on image generation. Placing it after Iteration 4 allows the team to validate the AI backend pattern end-to-end before adding another AI endpoint. It comes before push notifications because recommendation data enriches the notification payloads for event-status changes.

**User stories:**
- HU-AI-02a: As a rider opening the app, I see up to 5 recommended upcoming events in the home dashboard's recommendations section, ranked by how well they match my main vehicle type, past registrations, and location so I find rides I'll actually enjoy.
- HU-AI-02b: As a new rider with no history, I see the 5 soonest upcoming events in the recommendations section so the dashboard is never empty.

**Acceptance criteria (summary):**
- `GET /events/recommendations` backend endpoint returns up to 5 `EventModel`-compatible objects, authenticated with Firebase ID token.
- Scoring logic: vehicle type match (weight 40%), registration history (weight 40%), geographic proximity (weight 20%). New riders fall back to `upcoming` sorted by date.
- Recommendations are cached in `SharedPreferences` (key: `recommendations_cache`) and refreshed on app open.
- HomeCubit (or a dedicated `RecommendationsCubit`) emits `ResultState<List<EventModel>>` for the section.
- Tapping a recommendation navigates to the event detail page.
- Unit tests for the scoring use case (matched rider, new rider fallback) and cubit state transitions.
- Widget test for the recommendations section (loading skeleton, 5-card data state, empty state).
- `dart analyze` + `flutter test` pass.

**Agents:** backend | frontend | qa

**Estimated complexity:** M

**Dependencies:** Iteration 2 (events data patterns), Iteration 4 (AI backend pattern)

---

### Iteration 6 — Push Notifications (FCM) + SOS Alert

**Goal:** Deliver push notifications for all registration and event-status changes, and add a real-time SOS alert overlay on the live tracking map so riders and organizers are always informed, even with the app in the background.

**Why now:** This is the highest-integration-risk iteration: it requires `firebase_messaging` (a new package), device token management, FCM Admin SDK on the backend, deep link configuration in go_router, and a new WebSocket message type — all at once. Placing it last minimizes blast radius if any of these integrations has surprises, and ensures all upstream features (events, registrations, live tracking) are stable and tested.

**User stories:**
- HU-PUSH-01a: As a rider, I receive a push notification when my event registration is approved or rejected, and tapping it takes me directly to the registration detail screen so I don't have to hunt for the update.
- HU-PUSH-01b: As an event organizer, I receive a push notification when a new rider requests to join my event so I can approve or reject quickly from my registrations management screen.
- HU-PUSH-01c: As an approved attendee, I receive a push notification when my event changes to "en curso" (with a link to the live tracking map) or is cancelled, so I know exactly what's happening without opening the app.
- HU-SOS-01: As a rider on the live tracking map, I tap the SOS button and all other riders in the same session immediately see a persistent red overlay with my name and position so help can be coordinated in real time.

**Acceptance criteria (summary):**
- `firebase_messaging` added to `pubspec.yaml`; FCM token retrieved on login and sent to `POST /users/device-token` (new backend endpoint).
- Token refreshed via `onTokenRefresh` listener and re-sent to backend.
- FCM notifications dispatched by backend via Firebase Admin SDK on: registration approved, registration rejected, new registration received (organizer), event status → in_progress, event cancelled.
- Foreground, background, and terminated app states all handled (foreground: in-app snackbar + navigation; background/terminated: system notification → deep link on tap).
- Deep links use go_router named routes: `registration_detail`, `event_registrations`, `live_tracking`, `event_detail`.
- SOS WebSocket message type `{ type: "sos", riderId, riderName, lat, lng, eventId }` broadcast by server to all clients in the same event session.
- SOS button visible on `LiveTrackingPage`; tapping it sends SOS message; a persistent red overlay appears on all riders' maps showing the initiating rider's name and position marker.
- SOS overlay dismissed when the initiating rider sends `{ type: "sos_cancel" }` or the event session ends.
- Unit tests: FCM token registration use case, SOS message parsing in `TrackingWsClient`.
- Widget tests: SOS overlay renders with rider name; overlay dismissed on cancel.
- Integration test: full FCM flow is stubbed (Firebase Admin SDK mocked); SOS flow tested end-to-end against dev backend.
- `dart analyze` + `flutter test` pass.

**Agents:** design | backend | frontend | qa

**Estimated complexity:** XL

**Dependencies:** Iteration 2 (events/registrations stable), Iteration 5 (all feature iterations done)

---

### Iteration 1 (Parallel) — Design System in Pencil (HU-DESIGN-01)

> **This iteration runs in parallel with Iterations 1–3.** No Flutter code changes. The design agent works independently on the `.pen` file. Frontend agents pull specs from Pencil before implementing any new UI from Iteration 3 onward.

**Goal:** Establish Pencil as the source of truth for all Rideglory UI by migrating all existing screen flows into a single `.pen` file with design tokens defined as variables.

**Why now:** Design work has zero Flutter dependency and can start immediately. From Iteration 3 onward (SOAT UI), all new screens should be designed in Pencil first. Completing this by the end of Iteration 2 ensures the design handoff is in place before the first greenfield UI (SOAT documents) is built.

**User stories:**
- HU-DESIGN-01a: As a designer, I open `pencil-new.pen` and find each screen flow (onboarding, home, events, inscripciones, vehículos, mantenimiento, rastreo, perfil) in its own labeled section so I can navigate to any screen without searching.
- HU-DESIGN-01b: As a designer, I define color (`#f98c1f`, `#0D0D0D`), typography (Space Grotesk), and spacing (8px border radius) as Pencil variables so all components share a single source of truth.
- HU-DESIGN-01c: As a developer, before implementing any new screen from Iteration 3 onward, I open Pencil and find the canonical design with component specs so there is no guesswork about spacing, color, or layout.

**Acceptance criteria (summary):**
- `pencil-new.pen` file exists and opens without errors.
- 8 labeled flow sections, each containing the canonical reference screens for that flow (imported as images or native Pencil frames).
- Design tokens (`#f98c1f`, `#0D0D0D`, Space Grotesk, 8px) defined as Pencil variables.
- A brief design handoff note in `docs/handoffs/design.md` documents how developers should read specs from the file.
- No Flutter code changes.

**Agents:** design

**Estimated complexity:** M

**Dependencies:** None (purely design; runs in parallel)

---

## Risks and Assumptions

1. **Claude API cost and rate limits for SOAT extraction.** The AI extraction uses Claude Haiku per PDF upload. If many riders upload documents simultaneously, API costs could spike. Assumption: the rider base is small enough in v1 that per-request cost is acceptable. Mitigation: cache extraction results in the backend; never re-extract an unchanged document.

2. **FCM deep-link routing complexity.** go_router v17 uses a specific pattern for handling notification payloads when the app is terminated. If the existing route structure uses `extra` objects (not serializable from a notification payload), deep links may require route redesign. This is the primary technical risk in Iteration 6.

3. **Profile feature data completeness.** The `GET /users/me` endpoint exists, but the scan shows the backend `UserModel` may lack fields (bio, social links, ride count) that a complete profile page would display. Assumption: Phase 1 profile shows only what the API currently returns (name, photo, main vehicle). Expansion deferred.

4. **Event filter query parameter alignment.** The existing `GET /events` and `GET /events/upcoming` endpoints must already accept `type`, `dateFrom`, `dateTo`, and `location` query parameters for Iteration 2's filter UI to work without backend changes. If not, a small backend task is needed. This should be confirmed by the Architect before Iteration 2 planning is finalized.

5. **Pencil file availability.** HU-DESIGN-01 references `pencil-new.pen` as the target file, but the scan confirms it does not yet exist. The design agent must create it. The Stitch reference images are on a local path (`/Users/cami/Downloads/stitch_rideglory/`) outside the repo — this is a single-machine dependency that could block collaboration if design work moves to another machine.

---

## Deferred / Out of Scope

| Item | Reason for deferral |
|------|---------------------|
| **SOAT push reminders (30-day / 7-day)** | PRD marks as "future" (section 10). Infrastructure from HU-PUSH-01 must exist first. Scheduled after Iteration 6. |
| **Event recommendations — Claude API narrative explanations (v2)** | PRD flags as "optional v2". Scoring endpoint (v1) is sufficient for launch. Add when recommendation quality data is available. |
| **Authentication Clean Architecture refactor** | Auth works correctly via `AuthService`. Refactoring to full domain/data/presentation layers adds risk with no user-visible value. Defer unless test coverage work exposes a concrete pain point. |
| **CI/CD pipeline (GitHub Actions)** | No `.github/workflows/` exists. Setting up `dart analyze` + `flutter test` + APK/IPA build pipeline is important for long-term health but does not block feature delivery. Recommend addressing after Iteration 2 in a DevOps track. |
| **Web version, admin dashboard, payments, social feed** | Explicitly out of scope per PRD section 10. |
| **Multi-language support (English)** | ARB file is Spanish-only. No English translation planned. All UI strings remain in Spanish. |
| **Mandatory documents beyond SOAT** | PRD mentions extensibility to `tecno` and `other` doc types. DTO is designed for extensibility but only SOAT is implemented in v1. |
