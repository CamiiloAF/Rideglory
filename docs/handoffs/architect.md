# Architect handoff — Iteration 2

**Date:** 2026-05-14
**Status:** done
**Iteration goal:** SOAT registration per vehicle + FCM push notification foundation + notifications backend (api-gateway first-time Prisma) + ManageAttendeesPage redesign (Story 2.9).

---

## Iteration 2 architectural scope (LOAD-BEARING)

> **Iter-2 is full-stack.** Touches Flutter `domain/data/presentation` (two NEW features) and `rideglory-api` (vehicles-ms, users-ms, api-gateway). This is the inverse of iter-1.

Two new Flutter features created from scratch following the Clean Architecture template of `lib/features/vehicles/`:
- `lib/features/soat/` — full 3-layer feature.
- `lib/features/notifications/` — **stub already exists** (model, cubit, page, view, item widget) but is mock-only. It must be **rebuilt** into a real 3-layer feature with backend wiring. Do not delete the existing UI shell (`notifications_view.dart`, `notification_item.dart`) — rewire it.

Backend: api-gateway gets its **first-ever Prisma schema** (`prisma init` + `migrate dev`, NOT reset). vehicles-ms gets a `Soat` model. users-ms `User` gets `fcmToken String?`.

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|----------------|--------------|----------------------|
| **soat** (NEW) | `SoatModel` (pure Dart, with `SoatStatus` enum + `status` computed getter), `SoatRepository` interface, use cases `GetSoatUseCase` / `SaveSoatUseCase` | `SoatDto` (json_serializable, `toModel()`), `SoatService` (Retrofit, `@GET`/`@POST` on `/vehicles/{vehicleId}/soat`), `SoatRepositoryImpl` (`@Injectable(as: SoatRepository)`, Firebase Storage upload for document, `executeService` wrap) | `SoatCubit` (`Cubit<ResultState<SoatModel>>` — single result), `SoatUploadPage`, `SoatManualFormPage`, `SoatStatusPage` |
| **notifications** (REBUILD stub) | `NotificationModel` (keep enum, **add** `payload Map<String,dynamic>?`), `NotificationsRepository` interface, use cases `GetNotificationsUseCase` / `MarkNotificationReadUseCase` / `MarkAllNotificationsReadUseCase` / `RegisterFcmTokenUseCase` | `NotificationDto`, `NotificationPageDto` (`{ data, nextCursor }`), `NotificationsService` (Retrofit cursor pagination), `NotificationsRepositoryImpl` | `NotificationsCubit` → rewrite to `Cubit<NotificationsState>` (`@freezed` — needs list + nextCursor + unreadCount + pagination-loading flag, so a freezed state class, NOT bare `ResultState<T>`). `NotificationCenterPage` rewires existing `NotificationsView`. New `NotificationBellButton` (replaces `HomeNotificationButton`) with unread badge. |
| **vehicles** | none | none | `vehicle_detail_view.dart` / `vehicle_detail_header.dart`: wire `DocumentSlotPill` (iter-1 molecule) for SOAT slot — tappable → `context.pushNamed(soat...)`. Pass localized `stateLabel`. |
| **authentication** | none | none | `AuthCubit`: after `authenticated`, call `RegisterFcmTokenUseCase` (request permission + register token). FCM init is a `core/services/` concern invoked from AuthCubit — keep AuthCubit thin. |
| **events / event_registration** | none | none | `manage_attendees_page.dart` (Story 2.9) — presentation-only redesign per frame `dUc9h`: `AppButton`/`AppDialog`, no hardcoded colors, loading/empty/error states. Scope confirmed by design gate. |
| **core** | new `core/services/fcm_service.dart` (`@singleton`), top-level background handler in `lib/main.dart` or `core/services/fcm_background_handler.dart` | — | — |

---

## API contracts (rideglory-api changes)

All endpoints require Firebase Auth ID token (`Authorization: Bearer <token>`) via existing guard. Error shape: `{ message, statusCode, error }`.

| Method | Path | Auth | Request body | Success (200/201) | Errors |
|--------|------|------|--------------|-------------------|--------|
| POST | `/api/vehicles/:vehicleId/soat` | Bearer | `{ policyNumber: string, startDate: ISO8601, expiryDate: ISO8601, insurer: string, documentUrl?: string }` | `SoatResponse` (see below) | 400 invalid dates / 404 vehicle not found / 403 not owner |
| GET | `/api/vehicles/:vehicleId/soat` | Bearer | — | `SoatResponse` or `204 No Content` if none | 404 vehicle not found / 403 not owner |
| POST | `/api/notifications/fcm-token` | Bearer | `{ fcmToken: string }` | `204 No Content` | 400 missing token / 401 |
| GET | `/api/notifications?cursor=<lastId>&limit=20` | Bearer | — | `{ data: Notification[], nextCursor: string \| null }` ordered `createdAt desc` | 401 |
| PATCH | `/api/notifications/:id/read` | Bearer | — | `204 No Content` | 404 / 403 not owner |
| PATCH | `/api/notifications/read-all` | Bearer | — | `204 No Content` | 401 |

**`SoatResponse`:** `{ id, vehicleId, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt }`. Backend does NOT return `status` — the 4-state badge is computed **client-side** in `SoatModel.status` from `expiryDate` vs. `DateTime.now()`. Boundary rules: `> 30 days` → Vigente, `<= 30 days && not past` → Por vencer, `past expiry` → Vencido, `no record` → Sin SOAT.

**`Notification`:** `{ id, userId, type: string, payload: object, isRead: boolean, createdAt: ISO8601 }`. `type` is one of: `SOAT_30D`, `SOAT_7D`, `SOAT_DAY_OF`, `NEW_REGISTRATION`, `REGISTRATION_APPROVED`, `REGISTRATION_REJECTED`. `payload` carries scalar IDs only (`vehicleId`, `eventId`, `registrationId`, `vehicleName`) — never nested objects (FCM/deep-link convention, ADR-5).

**FCM push triggers (no new HTTP endpoint — internal):** events-ms registration approve/reject/create flow → api-gateway proxies → api-gateway sends FCM multicast via `firebase-admin` + inserts a row in `notifications` table. Cron (`@nestjs/schedule`, `America/Bogota`) for SOAT 30d/7d/day-of → same insert+push path.

---

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `SoatModel` | domain | `lib/features/soat/domain/models/soat_model.dart` | Pure Dart, `copyWith`, `==`/`hashCode`. Has `SoatStatus get status` computed getter + `int get daysUntilExpiry`. |
| `SoatStatus` | domain (enum) | same file | `noSoat`, `valid`, `expiringSoon`, `expired`. Maps 1:1 to `DocumentSlotState` from iter-1 molecule. |
| `SoatRepository` | domain | `lib/features/soat/domain/repository/soat_repository.dart` | `getSoat(vehicleId)`, `saveSoat(SoatModel, {localDocumentPath})`, `uploadSoatDocument(...)`. |
| `GetSoatUseCase`, `SaveSoatUseCase` | domain | `lib/features/soat/domain/usecases/` | One file each, `@injectable`. |
| `SoatDto` | data | `lib/features/soat/data/dto/soat_dto.dart` | `@JsonSerializable(converters: apiJsonDateTimeConverters)`, extends `SoatModel`, `toModel()` + `toJson()` request extension (mirror `VehicleDto` pattern). |
| `SoatService` | data | `lib/features/soat/data/service/soat_service.dart` | `@singleton @RestApi()`, Retrofit. |
| `SoatRepositoryImpl` | data | `lib/features/soat/data/repository/soat_repository_impl.dart` | `@Injectable(as: SoatRepository)`, Firebase Storage path `soat/{vehicleId}/document.{ext}`. |
| `SoatCubit` | presentation | `lib/features/soat/presentation/cubit/soat_cubit.dart` | `@injectable`, `Cubit<ResultState<SoatModel>>`. |
| `NotificationModel` (extend) | domain | `lib/features/notifications/domain/model/notification_model.dart` | Keep existing enum + fields; **add** `Map<String,dynamic>? payload`. Add missing enum values to align with backend `type` strings. |
| `NotificationsRepository` | domain | `lib/features/notifications/domain/repository/notifications_repository.dart` | NEW. |
| `NotificationDto`, `NotificationPageDto` | data | `lib/features/notifications/data/dto/` | NEW. `NotificationPageDto` = `{ List<NotificationDto> data, String? nextCursor }`. |
| `NotificationsService` | data | `lib/features/notifications/data/service/notifications_service.dart` | NEW. `@GET` with `@Query('cursor')`/`@Query('limit')`, `@PATCH`. |
| `NotificationsRepositoryImpl` | data | `lib/features/notifications/data/repository/notifications_repository_impl.dart` | NEW. |
| `NotificationsCubit` (rewrite) | presentation | existing path | `@freezed NotificationsState` (list + `nextCursor` + `unreadCount` + `isLoadingMore` + `ResultState` for initial load). |
| `FcmService` | core | `lib/core/services/fcm_service.dart` | `@singleton`. Wraps `firebase_messaging` + `flutter_local_notifications`. |

### Backend (rideglory-api)

| Name | Service | File | Notes |
|------|---------|------|-------|
| `Soat` Prisma model | vehicles-ms | `vehicles-ms/prisma/schema.prisma` | `id, vehicleId @unique, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt`. One-to-one with `Vehicle`. |
| `Notification` Prisma model | api-gateway (NEW schema) | `api-gateway/prisma/schema.prisma` | `id, userId, type, payload Json, isRead @default(false), createdAt @default(now())`. Index on `(userId, createdAt)`. |
| `fcmToken` field | users-ms | `users-ms/prisma/schema.prisma` | `fcmToken String?` on `User`. |
| `NotificationsModule` + controller + service | api-gateway | `api-gateway/src/notifications/` | NEW module. Owns `notifications` table, FCM dispatch (`firebase-admin`), cursor pagination. |
| `NotificationSchedulerService` | api-gateway | `api-gateway/src/notifications/` | `@nestjs/schedule` `@Cron`, `America/Bogota`. |
| `SoatModule` additions | vehicles-ms + api-gateway | `vehicles-ms/src/vehicles/`, `api-gateway/src/vehicles/` | Soat controller routes added to existing vehicles module on both sides. |

---

## Environment variables

| Variable | Where | Description | Example |
|----------|-------|-------------|---------|
| `DATABASE_URL` | api-gateway `.env` | First-time Prisma DB connection for api-gateway. Must match Docker Compose Postgres. | `postgresql://user:pass@localhost:5432/rideglory_gateway` |

No new Flutter `.env` keys. FCM uses existing `google-services.json` / `GoogleService-Info.plist`. `firebase-admin` already installed in api-gateway (no new backend package except `@nestjs/schedule`).

---

## New Flutter packages (pubspec.yaml)

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_messaging` | `^15.x` | FCM token + foreground/background messages |
| `flutter_local_notifications` | `^17.x`/`^18.x` | iOS foreground banners + Android notification channel |
| `file_picker` *(optional)* | `^8.x` | PDF picking for SOAT upload (camera/gallery via existing `image_picker`; PDF needs `file_picker`). Frontend confirms during impl; if PDF deferred to image-only, skip. |

`firebase_messaging` requires the Android background handler entry-point and iOS APNs. APNs key + Xcode push capability is a DevOps/pre-flight item (see architect-for-devops.md).

---

## FCM background isolate pattern (most critical correctness constraint)

The background message handler runs in a **separate Dart isolate** — GetIt is not initialized there.

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await configureDependencies(); // MUST re-init DI in the isolate
  // ... handle message (e.g. show local notification)
}
```

Registered in `main()` via `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` **before** `runApp`. Failure to re-init DI causes silent missed notifications on some devices. Tech Lead must verify `@pragma('vm:entry-point')` + `configureDependencies()` in review.

---

## GoRouter DI assessment (requested by PO for iter-4)

`lib/shared/router/app_router.dart` declares `AppRouter.appRouter` as a **static top-level `GoRouter` instance** — it is **NOT registered in GetIt**. Confirmed by reading the file head.

**Implication for iter-4/iter-5:** `NotificationRouteHandler` (iter-5) needs an injectable `GoRouter`. A refactor is required — register `GoRouter` in a DI module and inject it. This is **not in iter-2 scope**; documented here so iter-4 can plan it as Story 4.0 / iter-5 Story 5.0. No action this iteration.

---

## Risks and open questions

- **api-gateway first-time Prisma setup:** Docker Compose DB networking + `DATABASE_URL` + potential port conflict. Mitigation: full pre-flight day (T-2-2); verify `GET /api/notifications` returns 200 empty before feature code.
- **FCM background isolate DI:** silent missed notifications if `configureDependencies()` omitted. Mitigation: documented pattern above; tech_lead checklist item.
- **APNs not configured:** iOS push will silently fail. Mitigation: DevOps pre-flight — APNs auth key uploaded to Firebase Console + Push Notifications capability in Xcode.
- **`NotificationsCubit` rewrite breaks existing stub:** existing `NotificationsCubit` is `Cubit<NotificationsState>` with sealed-class states and is created inline in `NotificationsPage`. Rewriting to `@freezed` + DI singleton breaks `notifications_view.dart` `BlocBuilder` type refs. Mitigation: frontend updates view + page + item in the same PR; no test-rot.
- **Cursor pagination drift:** offset/limit is forbidden. Backend response MUST be `{ data, nextCursor }`. DTO field names must match exactly.
- **Story 2.9 scope ambiguity (frame dUc9h):** resolved by design gate. If edit-only, limit to component-swap + color tokenization.
- **SOAT document type:** PDF picking needs `file_picker` (image_picker is image-only). Frontend confirms; if scope-reduced to image-only, drop the package.

## Next agent needs to know

- **Backend (rideglory-api):** read `docs/handoffs/architect-for-backend.md`. Testing order T-2-4 (fcm-token) → T-2-5 (notifications table+endpoints) → T-2-3 (SOAT) → T-2-6 (FCM triggers) → T-2-7 (cron). api-gateway Prisma is `init` + `migrate dev`, NOT reset.
- **Design:** read `docs/handoffs/architect-for-frontend.md` §SOAT model so frame annotations map `SoatStatus` ↔ `DocumentSlotState`. Confirm frame `dUc9h` scope.
- **Frontend (Flutter dev):** read `docs/handoffs/architect-for-frontend.md` — full feature structure, DTO/Retrofit/cubit patterns, FCM isolate pattern, l10n keys, `DocumentSlotPill` caller contract.
- **DevOps:** read `docs/handoffs/architect-for-devops.md` — `DATABASE_URL` env var, APNs setup, `@nestjs/schedule` install, no CI pipeline change needed.
- **QA:** read `docs/handoffs/architect-for-qa.md` — test commands + acceptance traceability for SOAT 4-state logic and `NotificationsCubit` pagination.

## Change log

- 2026-05-14 (iter-2): Architect phase complete. Full-stack SOAT + FCM notification foundation. Two Flutter features (`soat/` new, `notifications/` rebuilt from stub). 6 new API contracts (2 SOAT, 4 notifications). Backend: api-gateway first-time Prisma (`Notification` model), vehicles-ms `Soat` model, users-ms `fcmToken`. 2-3 new Flutter packages (`firebase_messaging`, `flutter_local_notifications`, optional `file_picker`). FCM background isolate `@pragma('vm:entry-point')` + `configureDependencies()` pattern documented as load-bearing. GoRouter DI assessment: top-level static, NOT in GetIt — refactor needed for iter-5, planned not done. SOAT status computed client-side (4 states). Cursor pagination enforced. DIAGRAMS.md updated with ERD + FCM/SOAT sequence diagrams.
