# PO Handoff — Iteration 2

**Date:** 2026-05-14
**Status:** in progress

---

## Iteration goal

Allow riders to register and track their SOAT (mandatory insurance) per vehicle and receive push notifications for critical lifecycle events, while establishing the FCM infrastructure and persistent notification backend that iter-3, iter-4, and iter-5 depend on. Also completes ManageAttendeesPage redesign (Story 2.9) deferred from iter-1.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
| --- | ----- | ------------------- | ------------- |
| US-2-1 | As a rider, I can upload my SOAT document (photo or PDF from gallery/camera) for a vehicle in my garage and save the policy data (policy number, dates, insurer) in the backend. | Document is saved; vehicle badge changes to "Vigente" or "Por vencer" based on expiry date. All upload errors (network, file-too-large) shown as snackbars in Spanish. | frontend + backend |
| US-2-2 | As a rider, I can manually enter my SOAT data (policy number, start date, expiry date, insurer) when I do not want to upload a document. | Expiry date is required and validated; on save, SOAT state badge reflects the correct validity logic (4 states). Empty or invalid dates show inline validation error. | frontend + backend |
| US-2-3 | As a rider, I see a SOAT status badge (Sin SOAT / Vigente / Por vencer / Vencido) on my vehicle detail page and can tap the badge to navigate to the SOAT flow. | Four states calculated correctly based on expiry date vs. today (>30d → Vigente, ≤30d → Por vencer, past → Vencido, none → Sin SOAT). Badge is tappable and navigates to the correct flow. | frontend + backend |
| US-2-4 | As a rider, I receive a push notification 30 days before, 7 days before, and on the day my SOAT expires, including the affected vehicle's name. | All three notifications arrive at the device on the correct dates and appear in the notification center. (Tap navigation → iter-5.) | backend |
| US-2-5 | As an event organizer, I receive a push notification when a new rider registers for my event. | Notification appears in the notification center; unread badge on the bell icon increments. (Tap navigation → iter-5.) | backend + frontend |
| US-2-6 | As a registered rider, I receive a push notification when my registration is approved or rejected. | Notification arrives within 30 seconds of the organizer's action; the "My Registrations" screen already reflects the updated status when opened. (Tap navigation → iter-5.) | backend + frontend |
| US-2-7 | As a rider, I can open the notification center from the bell icon on Home and view all my notifications, distinguishing unread (orange dot) from read. Tapping a notification or using "Mark all as read" persists the state in the backend. | List loads from backend with cursor pagination (?cursor=<lastId>&limit=20, response { data, nextCursor }); marking read calls PATCH /api/notifications/:id/read; "Mark all" calls PATCH /api/notifications/read-all; bell badge reflects unread count from backend; empty state "Aún no tienes notificaciones" visible. | frontend + backend |
| US-2-8 | As the dev team, the backend persists all notifications in a notifications table in api-gateway and exposes endpoints to list them, mark them as read, and register the FCM token. | GET /api/notifications?cursor=<lastId>&limit=20 returns { data: Notification[], nextCursor: string | null } for the authenticated user ordered by createdAt desc; PATCH /api/notifications/:id/read updates isRead=true; PATCH /api/notifications/read-all updates all unread for the user; POST /api/notifications/fcm-token receives { fcmToken: string } and updates fcmToken String? field on users-ms User model (called from AuthCubit post-login); all four endpoints require Bearer token with Firebase Auth guard; notifications table fields: id, userId, type, payload (JSON), isRead, createdAt. | backend |
| US-2-9 | As an event organizer, the attendees management page (Pencil frame dUc9h) matches the rideglory.pen design — using design system components, correct color tokens, and consistent loading/empty states. | ManageAttendeesPage uses AppButton, AppDialog throughout; no hardcoded color literals; loading, empty, and error states visually correct per confirmed Pencil frame dUc9h. If frame covers list + edit, full layout is implemented; if edit-only, scope is limited to component-swap and color tokenization with no layout rework. | frontend |
| US-2-10 | As the dev team, SOAT and notification features have full automated test coverage — unit tests for business logic, cubit tests for all state transitions, and widget tests for all new pages. | Unit: SOAT badge state logic (4 states, boundary dates); NotificationsCubit — initial load, cursor pagination, markRead, markAllRead (5 BLoC test cases minimum per cubit). Widget: SoatUploadPage, SoatManualFormPage, NotificationCenterPage — loading skeleton, data render, empty state, error banner per page. dart analyze passes with zero violations; flutter test passes with zero new failures. | qa |

---

## Assumptions and open questions

- **Story 2.9 frame scope (assumption):** Frame dUc9h may cover list + edit view or edit-only. Design gate must confirm before implementation. If ambiguous, limit to component-swap and color tokenization without layout rework.
- **FCM background isolate DI (confirmed):** The FCM background message handler runs in a separate Dart isolate. `configureDependencies()` must be re-called inside the handler. The top-level handler function requires `@pragma('vm:entry-point')`.
- **Notification read state is backend-sourced (confirmed):** `SharedPreferences` may be used only as a local badge-count cache for optimization; the source of truth is the `notifications` table in api-gateway.
- **Testing order (confirmed):** Story 2.8 (backend endpoints) must be complete before Story 2.7 (mark as read) can be fully implemented and tested. Order: 2.8 → 2.7 → 2.4/2.5/2.6.
- **Cursor pagination throughout (confirmed):** All notification endpoints use cursor-based pagination (`?cursor=<lastId>&limit=20`). Offset/limit must NOT be used.
- **api-gateway Prisma first-time setup (confirmed):** api-gateway has no existing `prisma/` directory. This is `prisma init` + schema creation + `prisma migrate dev` — NOT `prisma migrate reset`. A full pre-flight day is budgeted.
- **DocumentSlotPill caller contract (from iter-1 tech_lead):** `DocumentSlotPill` has hardcoded Spanish fallback strings. Callers MUST pass a localized `stateLabel` via `context.l10n.<key>`. The SOAT implementation in iter-2 must follow this pattern explicitly.
- **Pre-existing test failures (from iter-1 QA):** 4 test failures caused by stale `.g.dart` files (`user_service.g.dart` missing `getUserById`, `event_service.g.dart` signature mismatch). These will clear during iter-2 pre-flight when `build_runner` regenerates code for new SOAT/notification DTOs.
- **Pre-existing non-blockers from tech_lead (deferred to iter-2):** `mileage_info_dialog.dart` uses raw `AlertDialog`; `event_form_multi_brand_section.dart` uses raw `TextFormField`; `info_chip_tooltip.dart` uses raw `showDialog()`; `home_view_all_events_button.dart` uses `context.goNamed()`. These are not assigned to dedicated iter-2 stories but the frontend agent should address them if files are touched.
- **Home Dashboard SOAT badge NOT in iter-2:** SOAT badge on the Home Dashboard main vehicle card is deferred to iter-3 per PLAN.md.

---

## Out of scope (this iteration)

- **Home Dashboard SOAT badge:** Deferred to iter-3. Vehicle detail SOAT badge IS in scope (US-2-3).
- **Notification tap routing:** Stories 2.4/2.5/2.6/2.7 deliver notification display only. Tapping a notification navigates to the Home screen for now. Full routing (to specific screens) is iter-5 (Story 5.5).
- **OCR auto-fill for SOAT:** Alta complejidad; entrada manual (US-2-2) is sufficient for MVP. Deferred post-iter-5.
- **SOAT push reminders via FCM to the user's own device before Cron runs:** The cron scheduler sends push at 30d/7d/day-of. No on-save immediate reminder.
- **Mandatory documents beyond SOAT:** Tech review (Revisión Técnico-Mecánica) is out of scope for iter-2. DTO is extensible but only SOAT in v1.
- **Maintenance reminders:** Deferred to iter-3 (Story 3.6).
- **Event 24h reminders:** Deferred to iter-3 (Story 3.7).
- **Deep links, Apple Sign-In, notification routing to specific screens:** iter-5.
- **Follow system, complete profiles:** iter-4.
- **Mapbox migration:** Story 3.0 (iter-3).
- **SOS alert feature:** iter-3.

---

## Task definitions

| Task ID | Description | Agent | Status |
|---------|-------------|-------|--------|
| T-2-1 | Design gate: confirm/create Pencil frames for SOAT upload, SOAT manual form, SOAT status detail, notification center, vehicle detail with 4-state SOAT badge, generic notification row template. Confirm frame dUc9h scope for Story 2.9. | design | todo |
| T-2-2 | Pre-flight backend: create seed.ts in vehicles-ms (2+ test vehicles) and events-ms (1 scheduled event + 1 registration); run prisma migrate reset on 4 existing services; prisma init + prisma migrate dev in api-gateway; verify GET /api/vehicles returns 200. | backend | todo |
| T-2-3 | Backend: implement SOAT endpoints in vehicles-ms (POST /api/vehicles/:vehicleId/soat, GET /api/vehicles/:vehicleId/soat) with Soat Prisma model; add soatStatus computed logic. | backend | todo |
| T-2-4 | Backend: add fcmToken String? to users-ms User model (Prisma migration); implement POST /api/notifications/fcm-token in api-gateway; add Firebase Auth guard. | backend | todo |
| T-2-5 | Backend: create notifications table in api-gateway Prisma (id, userId, type, payload JSON, isRead, createdAt); implement GET /api/notifications (cursor), PATCH /:id/read, PATCH /read-all with Firebase Auth guard. | backend | todo |
| T-2-6 | Backend: add FCM push trigger in events-ms registration approval/rejection flow; each push inserts a row in api-gateway notifications table. | backend | todo |
| T-2-7 | Backend: install @nestjs/schedule; implement NotificationSchedulerService with @Cron for SOAT reminders (30d, 7d, day-of); America/Bogota timezone; each push inserts row in notifications table. | backend | todo |
| T-2-8 | Flutter: implement lib/features/soat/ — domain (SoatModel, SoatRepository), data (SoatDto, SoatService Retrofit, SoatRepositoryImpl), presentation (SoatCubit, SoatUploadPage, SoatManualFormPage, SoatStatusPage). | frontend | todo |
| T-2-9 | Flutter: implement lib/features/notifications/ — domain (NotificationModel, NotificationsRepository), data (NotificationsService with cursor pagination), presentation (NotificationsCubit, NotificationCenterPage); bell icon with unread badge on Home shell. | frontend | todo |
| T-2-10 | Flutter: initialize FCM in AuthCubit post-login — permission request, token registration (POST /api/notifications/fcm-token); configure flutter_local_notifications for iOS foreground banners; Android notification channel; top-level background handler with @pragma('vm:entry-point') and DI re-init. | frontend | todo |
| T-2-11 | Flutter: implement Story 2.9 — ManageAttendeesPage redesign per confirmed Pencil frame dUc9h (AppButton, AppDialog, no hardcoded colors, loading/empty/error states). | frontend | todo |
| T-2-12 | QA: run dart analyze + flutter test; write unit tests (SoatCubit 4-state badge logic, NotificationsCubit — initial/pagination/markRead/markAllRead); write widget tests (SoatUploadPage, SoatManualFormPage, NotificationCenterPage); verify 6 notification types on device/emulator. | qa | todo |
| T-2-13 | Tech Lead: review all PRs for Clean Architecture compliance — layer violations, cursor pagination enforcement, FCM background handler pattern, DocumentSlotPill caller pattern, SOAT badge state logic, app_es.arb completeness. | tech_lead | todo |

---

## Next agent needs to know

### architect
- **New features, full stack:** Iter-2 touches domain, data, presentation (Flutter), and backend (NestJS). All layers are in scope.
- **FCM background isolate:** The background message handler must be a top-level Dart function annotated with `@pragma('vm:entry-point')`. `configureDependencies()` must be called inside the handler before any service is used. Document this pattern explicitly — it is the most critical correctness constraint in iter-2.
- **api-gateway Prisma first-time setup:** No `prisma/` directory exists in api-gateway. Must run `npx prisma init`, create `schema.prisma` with Notification model, configure DATABASE_URL, run `npx prisma migrate dev --name init_notifications`. This is categorically different from the `prisma migrate reset` run on the 4 existing microservices.
- **cursor pagination:** All notification list endpoints must use `?cursor=<lastId>&limit=20` pattern with `{ data, nextCursor }` response shape. Offset/limit is explicitly forbidden.
- **DocumentSlotPill contract:** Callers must pass a localized `stateLabel` string — the molecule has no `BuildContext` and cannot self-localize. Enforce this in the architecture handoff to frontend.
- **SOAT badge state logic (boundary rules):** >30 days remaining → Vigente, ≤30 days → Por vencer, past expiry → Vencido, no SOAT record → Sin SOAT.
- **Story 2.9 constraint:** Pure presentation-layer change (same as iter-1 redesign stories). No domain/data changes. Scope depends on Pencil frame dUc9h confirmation.
- **GoRouter DI assessment:** Document whether `app_router.dart` creates GoRouter as a top-level variable or via GetIt. This assessment is needed by iter-4. If the assessment is trivial to do now, note it.

### design
- **Design gate is a hard pre-condition:** No Flutter implementation may begin until all SOAT and notification Pencil frames are confirmed in `rideglory.pen`.
- **Frame dUc9h scope clarification is critical:** If the frame covers list + edit, full layout is implemented. If edit-only, scope is limited. Resolve this ambiguity before Story 2.9 begins.
- **Required frames:** SOAT upload page, SOAT manual form page, SOAT status/detail page, vehicle detail page with 4-state SOAT badge (Sin SOAT / Vigente / Por vencer / Vencido), notification center page, generic notification row template with icon slot per notification type (6 types), ManageAttendeesPage (confirm frame dUc9h).
- **DocumentSlotPill integration:** The `DocumentSlotPill` molecule from iter-1 is the foundation for the SOAT badge in the vehicle detail. Design must show how the DocumentSlotPill's 4 states map to the SOAT badge states.

### frontend (flutter_dev)
- **Build runner required:** `dart run build_runner build --delete-conflicting-outputs` is mandatory in pre-flight. New DTOs for SOAT and notifications require code generation. The 4 pre-existing test failures should clear after this run.
- **DocumentSlotPill caller contract:** When wiring up the SOAT badge in vehicle detail, always pass `stateLabel: context.l10n.vehicle_soat_<state>` — do not rely on the molecule's hardcoded fallback strings.
- **FCM background isolate pattern:** Follow the `@pragma('vm:entry-point')` + `configureDependencies()` pattern exactly. This is a correctness constraint, not a style preference.
- **New l10n keys needed:** All SOAT and notification UI copy must be added to `lib/l10n/app_es.arb` before any string is used in a widget. Key prefix: `soat_` and `notification_`.
- **Scope of Story 2.9:** Wait for design gate confirmation on frame dUc9h scope before beginning ManageAttendeesPage changes. If frame is edit-only, do not add list layout.
- **Feature structure:** `lib/features/soat/` (domain, data, presentation) and `lib/features/notifications/` (domain, data, presentation) — create both from scratch following existing features as reference.

### backend
- **Pre-flight is the first task:** Complete seed.ts setup and prisma operations before writing any feature code. Verify `GET /api/vehicles` returns 200 and `GET /api/notifications` returns 200 empty list before proceeding.
- **Notification table ownership:** The `notifications` table lives in api-gateway's Prisma schema. It is NOT in events-ms or users-ms. api-gateway proxies the FCM push and inserts the notification row after proxying.
- **FCM dispatch:** firebase-admin is already installed in api-gateway. Use it for FCM multicast. No new package required.
- **@nestjs/schedule:** `npm install @nestjs/schedule`. Add `ScheduleModule.forRoot()` to api-gateway AppModule. All cron expressions must use `America/Bogota` timezone.
- **SOAT model in vehicles-ms:** Add `Soat` entity with fields: id, vehicleId, policyNumber, startDate, expiryDate, insurer, documentUrl (nullable), createdAt, updatedAt. One-to-one with Vehicle.
- **Testing order:** Implement in order: T-2-4 (fcm-token endpoint) → T-2-5 (notifications table + endpoints) → T-2-3 (SOAT endpoints) → T-2-6 (FCM triggers) → T-2-7 (cron scheduler).

### qa
- **Build runner pre-flight:** Run `dart run build_runner build --delete-conflicting-outputs` first. Verify the 4 pre-existing test failures now pass (or confirm they clear with the new .g.dart files).
- **Test targets:** Unit: SoatCubit (4-state boundary logic), NotificationsCubit (initial → loading → data → empty → error for each method). Widget: SoatUploadPage, SoatManualFormPage, NotificationCenterPage — 4 test cases each (loading, data, empty, error). dart analyze: must be 0 errors/warnings (no new violations).
- **6 notification types to verify on device/emulator:** SOAT 30d, SOAT 7d, SOAT day-of, new registration (organizer), registration approved, registration rejected. Testing 2.4/2.5/2.6 requires a physical device or emulator with Firebase project configured.
- **ManageAttendeesPage (Story 2.9):** No new cubit tests required (no new state management). Verify no hardcoded colors, correct design system component usage, loading/empty/error states.
- **Scope reduction rule:** If Story 2.7 back-end read persistence is at risk near the end of the iteration, the unread badge may be reset locally (SharedPreferences) as a provisional measure. The backend endpoints (Story 2.8) must be complete regardless.

---

## Change log

- 2026-05-14: Iteration 2 scoped from PLAN.md (approved plan v3, iter-2 section). 10 user stories defined (US-2-1 through US-2-10). 13 tasks defined (T-2-1 through T-2-13). 1 QA task (T-2-12, agent: qa). Design gate is mandatory pre-condition. Pre-existing non-blockers from iter-1 tech_lead noted. Testing order documented (2.8 → 2.7 → 2.4/2.5/2.6). Home Dashboard SOAT badge confirmed out of scope.
