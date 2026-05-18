## Iteration 2 — SOAT + Notification Foundation

### Goal

Allow riders to register and track their SOAT per vehicle, and receive push notifications for critical lifecycle events. Establishes the FCM infrastructure and the notifications table in the backend that iter-3, iter-4, and iter-5 depend on. Includes Story 2.9 (ManageAttendeesPage redesign) deferred from iter-1.

---

### Stories delivered

| Story | Description | Status |
|-------|-------------|--------|
| US-2-1 | SOAT document upload (photo/PDF) — save policy + badge update | ✅ Done |
| US-2-2 | SOAT manual data entry with validation | ✅ Done |
| US-2-3 | 4-state SOAT badge on vehicle detail (Sin SOAT / Vigente / Por vencer / Vencido) | ✅ Done |
| US-2-4 | SOAT expiry push notifications (30d / 7d / day-of) | ✅ Backend cron ready; device test deferred |
| US-2-5 | New registration push to organizer | ✅ Backend trigger ready; device test deferred |
| US-2-6 | Registration approved/rejected push to rider | ✅ Backend trigger ready; device test deferred |
| US-2-7 | Notification center with cursor pagination, mark-read, unread badge | ✅ Done |
| US-2-8 | Backend: notifications table + 4 endpoints + FCM token registration | ✅ Done |
| US-2-9 | ManageAttendeesPage redesign (component-swap + state polish) | ✅ Done |

---

### What changed

**Flutter (`lib/`):**
- `lib/features/soat/` — new Clean Architecture feature: domain model (4-state computed badge), repository, DTOs, Retrofit service, SoatCubit, SoatUploadPage, SoatManualFormPage, SoatStatusPage
- `lib/features/notifications/` — full rebuild: NotificationModel with payload/type, NotificationsCubit with cursor pagination, NotificationBellButton with live unread badge
- `lib/core/services/fcm_service.dart` — FCM singleton, Android channel, foreground handler, background isolate with `@pragma('vm:entry-point')`
- `lib/features/authentication/` — FCM token registration wired into AuthCubit post-login
- `lib/features/vehicles/` — VehicleSoatSection integrated into VehicleDetailView via DocumentSlotPill

**Backend (`rideglory-api`):**
- `vehicles-ms` — `Soat` Prisma model, `POST/GET /api/vehicles/:vehicleId/soat`, `SoatService` with expiry query for cron
- `users-ms` — `fcmToken String?` field on User, `updateFcmToken` + `getFcmTokenByEmail` patterns
- `api-gateway` — first-time Prisma setup (`Notification` model), `NotificationsModule` with 4 endpoints, `NotificationSchedulerModule` with SOAT `@Cron` (America/Bogota), FCM triggers on registration create/approve/reject

---

### Test results

| Gate | Result |
|------|--------|
| `dart analyze` | ✅ 0 errors, 0 warnings |
| `flutter test` | ✅ 64 pass / 1 pre-existing fail (rider_profile_page, iter-1) |
| Backend jest (api-gateway) | ✅ 19/19 pass |
| Backend jest (vehicles-ms) | ✅ 9/9 pass |
| Architecture violations | ✅ None — no layer violations |
| Hardcoded colors | ✅ None |

New tests: 21 cases (TC-2-20 through TC-2-40) — SOAT model boundaries, SoatCubit states, NotificationsCubit cursor pagination + optimistic updates.

---

### Handoffs

- [PO](docs/handoffs/po.md) · [Architect](docs/handoffs/architect.md) · [Design](docs/handoffs/design.md) · [Backend](docs/handoffs/backend.md) · [Frontend](docs/handoffs/frontend.md) · [QA](docs/handoffs/qa.md) · [DevOps](docs/handoffs/devops.md)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
