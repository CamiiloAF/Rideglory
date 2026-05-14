# Frontend Handoff — Iter-2: SOAT + Notifications + FCM

**Agent:** Flutter Developer
**Iteration:** 2
**Phase:** frontend
**Status:** pass
**Completed at:** 2026-05-14

---

## Scope

Story 2.6 (SOAT Registration), Story 2.11 (Notification Center + FCM), Story 2.9 (ManageAttendeesPage — confirmed already implemented; no scope change needed).

---

## Features Delivered

### SOAT Feature (`lib/features/soat/`)

Full Clean Architecture implementation across 3 layers:

**Domain**
- `soat_model.dart` — `SoatModel` with computed `status` (4-state: `noSoat`, `valid`, `expiringSoon`, `expired`) and `daysUntilExpiry` (day-aligned, no time component leakage)
- `soat_repository.dart` — abstract `SoatRepository` interface
- `get_soat_usecase.dart`, `save_soat_usecase.dart` — `@injectable` use cases

**Data**
- `soat_dto.dart` — `@JsonSerializable(converters: apiJsonDateTimeConverters)` DTO; `toModel()` + `toRequestJson()` extension
- `soat_service.dart` — `@singleton @RestApi()` Retrofit client for `GET/POST /api/vehicles/:vehicleId/soat`
- `soat_repository_impl.dart` — `@Injectable(as: SoatRepository)`; 404 mapped to `Right(null)` (no SOAT = empty, not error)

**Presentation**
- `SoatCubit` — `@injectable Cubit<ResultState<SoatModel>>` with `load()` and `save()` methods
- `SoatUploadPage` — 2×2 grid source picker (camera/gallery/pdf/manual); non-manual options defer to manual
- `SoatManualFormPage` — `FormBuilder` with policy number, insurer, start date, expiry date; date validated via `DateFormat('dd/MM/yyyy').parseStrict()`; navigator stored before async gap to fix `use_build_context_synchronously`
- `SoatStatusPage` — hero status card with 4-state display; warning callout for expiringSoon/expired; details card; edit button navigates to manual form

**Vehicle Integration**
- `VehicleSoatSection` — `StatefulWidget` using `FutureBuilder` + `GetSoatUseCase` directly; maps `SoatStatus` to `DocumentSlotPill` `DocumentSlotState`; tap routes to soatUpload (null) or soatStatus (existing)
- Added to `VehicleDetailView` between `_SpecsCard` and `VehicleMaintenanceHistorySection`

### Notifications Rebuild (`lib/features/notifications/`)

**Domain**
- `NotificationModel` — new `NotificationType` enum: `soat30d`, `soat7d`, `soatDayOf`, `newRegistration`, `registrationApproved`, `registrationRejected`, `general`; added `payload?: Map<String, dynamic>?`
- `NotificationsRepository` — new abstract with `getNotifications({cursor, limit})`, `markRead()`, `markAllRead()`, `registerFcmToken()`; `NotificationsPage` value class
- 4 `@injectable` use cases: `GetNotificationsUseCase`, `MarkNotificationReadUseCase`, `MarkAllNotificationsReadUseCase`, `RegisterFcmTokenUseCase`

**Data**
- `NotificationDto` — maps backend type strings (`SOAT_30D`, `NEW_REGISTRATION`, etc.) to enum
- `NotificationsService` — `@singleton @RestApi()` Retrofit client; cursor-based pagination via `?cursor=&limit=`; `markRead` uses `@PATCH('{notificationId}/read')`
- `NotificationsRepositoryImpl` — `@Injectable(as: NotificationsRepository)`

**Presentation**
- `NotificationsState` — `@freezed abstract class` with `listResult`, `nextCursor`, `unreadCount`, `isLoadingMore`
- `NotificationsCubit` — `@lazySingleton`; `load()` (full reload), `loadMore()` (cursor append), `markRead()` (optimistic), `markAllRead()` (optimistic)
- `NotificationsPage` / `NotificationsView` — rewritten with real state; uses if/else `is` type checks (non-exhaustive switch avoided)
- `NotificationBellButton` — `BlocBuilder<NotificationsCubit, NotificationsState>` badge overlay; 16×16 circle; "99+" overflow; navigates to notifications on tap

### FCM Initialization (`lib/core/services/fcm_service.dart`)

- `@singleton FcmService` — requests permission, sets up `flutter_local_notifications` Android channel, foreground handler, token registration via `RegisterFcmTokenUseCase`
- `firebaseMessagingBackgroundHandler` — `@pragma('vm:entry-point')` top-level function registered in `main.dart`
- `AuthCubit` — wired `FcmService.initialize()` after every successful auth state emission

### Routing

New routes in `app_routes.dart` + `app_router.dart`:
- `AppRoutes.soatUpload` — extra: `VehicleModel`
- `AppRoutes.soatStatus` — extra: `VehicleModel`

### Dependencies Added (`pubspec.yaml`)

- `firebase_messaging: ^16.2.0`
- `flutter_local_notifications: ^18.0.1`

### L10n Keys Added (`lib/l10n/app_es.arb`)

~100+ new keys with prefixes: `soat_*`, `notification_*`, `event_filter_*`.

---

## Tests

| File | Cases | Result |
|------|-------|--------|
| `test/features/soat/domain/models/soat_model_test.dart` | 7 (TC-2-20 – TC-2-26) | PASS |
| `test/features/soat/presentation/cubit/soat_cubit_test.dart` | 5 (TC-2-27 – TC-2-31) | PASS |
| `test/features/notifications/presentation/cubit/notifications_cubit_test.dart` | 9 (TC-2-32 – TC-2-40) | PASS |

Full suite: 64 pass / 1 pre-existing fail (TC-2-28 rider email display — unchanged from before iter-2).

```
dart analyze → No issues found!
flutter test  → 64 pass / 1 pre-existing fail
```

---

## Architecture Notes

- Domain layer has zero Flutter/HTTP imports (verified by `dart analyze`)
- Data layer has zero `BuildContext` usage
- Presentation never calls Retrofit directly; routes through use cases
- `SoatRepositoryImpl.getSoat()` handles 404 as `Right(null)` — not an error — matching backend contract
- `NotificationsCubit` uses `@lazySingleton` so bell badge stays live across page transitions
- BuildContext async gap fixed with `navigator = Navigator.of(context)` before `await` + `if (!mounted) return` pattern

---

## Handoff to QA

QA should verify:
- SOAT badge displays correct status in vehicle detail for all 4 states
- Manual SOAT form validates expiry date correctly (required + format dd/MM/yyyy)
- Notification bell badge increments/decrements correctly with real backend data
- markAllRead sets badge to 0
- FCM token registers on login (check backend logs)
- Cursor pagination loads more notifications on scroll
