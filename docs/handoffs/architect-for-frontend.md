> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Frontend (Flutter) — Iteration 2

**Iter-2 = full-stack.** Two new features in `lib/features/`, FCM init, vehicle-detail SOAT badge wiring, ManageAttendeesPage redesign. Template: copy the Clean Architecture layout of `lib/features/vehicles/`.

## Pre-flight (mandatory before any code)

- `dart run build_runner clean` then `dart run build_runner build --delete-conflicting-outputs`. New SOAT + Notification DTOs/services need codegen. The 4 pre-existing test failures should clear.
- `flutter pub get` after adding packages.

## New packages (pubspec.yaml)

- `firebase_messaging: ^15.x`
- `flutter_local_notifications: ^17.x`/`^18.x`
- `file_picker: ^8.x` — only if SOAT PDF upload is in scope; `image_picker` (already present) handles camera/gallery photos. If PDF descoped to image-only, skip.

## Feature 1 — `lib/features/soat/` (NEW, 3 layers)

| Layer | Files |
|-------|-------|
| domain | `models/soat_model.dart` (+ `SoatStatus` enum + `SoatStatus get status` computed getter from `expiryDate` vs `now`, `int get daysUntilExpiry`); `repository/soat_repository.dart`; `usecases/get_soat_usecase.dart`, `usecases/save_soat_usecase.dart` (`@injectable`) |
| data | `dto/soat_dto.dart` (`@JsonSerializable(converters: apiJsonDateTimeConverters)` extends `SoatModel`, `toModel()`, `toJson()` request extension — mirror `VehicleDto`); `service/soat_service.dart` (`@singleton @RestApi()`); `repository/soat_repository_impl.dart` (`@Injectable(as: SoatRepository)`, Firebase Storage path `soat/{vehicleId}/document.{ext}`, `executeService` wrap) |
| presentation | `cubit/soat_cubit.dart` (`@injectable`, `Cubit<ResultState<SoatModel>>` — single result, NO freezed state class needed); `pages/soat_upload_page.dart`, `pages/soat_manual_form_page.dart`, `pages/soat_status_page.dart` |

`SoatService` endpoints: `@GET('${ApiRoutes.vehicles}/{vehicleId}/soat')`, `@POST('${ApiRoutes.vehicles}/{vehicleId}/soat')`. Add `ApiRoutes.vehicleSoat(vehicleId)` helper to `lib/core/http/api_routes.dart`.

**SoatStatus boundary rules** (client-side, `expiryDate` vs `DateTime.now()`): `> 30 days` → `valid` (Vigente); `<= 30 days && not past` → `expiringSoon` (Por vencer); `past` → `expired` (Vencido); no record → `noSoat` (Sin SOAT). `SoatStatus` maps 1:1 to `DocumentSlotState` from iter-1.

## Feature 2 — `lib/features/notifications/` (REBUILD existing stub)

A stub already exists (`notification_model.dart`, `notifications_cubit.dart`, `notifications_view.dart`, `notification_item.dart`, `notifications_page.dart`). **Rewire, do not discard the UI shell.**

| Layer | Work |
|-------|------|
| domain | extend `NotificationModel` — add `Map<String,dynamic>? payload`; align enum values with backend `type` strings (`SOAT_30D`, `SOAT_7D`, `SOAT_DAY_OF`, `NEW_REGISTRATION`, `REGISTRATION_APPROVED`, `REGISTRATION_REJECTED`). NEW `repository/notifications_repository.dart`; usecases `get_notifications_usecase.dart`, `mark_notification_read_usecase.dart`, `mark_all_notifications_read_usecase.dart`, `register_fcm_token_usecase.dart` |
| data (NEW) | `dto/notification_dto.dart`, `dto/notification_page_dto.dart` (`{ List<NotificationDto> data, String? nextCursor }`); `service/notifications_service.dart` (`@GET` with `@Query('cursor')` + `@Query('limit')`, two `@PATCH` for `:id/read` and `read-all`, `@POST` `/notifications/fcm-token`); `repository/notifications_repository_impl.dart` |
| presentation | **rewrite** `NotificationsCubit` → `@injectable Cubit<NotificationsState>` where `NotificationsState` is `@freezed` (fields: `ResultState<List<NotificationModel>>` initial load, `String? nextCursor`, `int unreadCount`, `bool isLoadingMore`). Methods: `load()`, `loadMore()`, `markRead(id)`, `markAllRead()`. Update `notifications_view.dart` + `notification_item.dart` + `notifications_page.dart` to the new state type in the SAME PR (no test-rot). NEW `NotificationBellButton` widget with unread badge — replaces `HomeNotificationButton` in Home shell. |

Cursor pagination only — `?cursor=<lastId>&limit=20`, response `{ data, nextCursor }`. Offset/limit forbidden.

## FCM init — `lib/core/services/fcm_service.dart` (NEW `@singleton`)

Wraps `firebase_messaging` + `flutter_local_notifications`. Called from `AuthCubit` after `AuthState.authenticated` (keep AuthCubit thin — inject `FcmService` or `RegisterFcmTokenUseCase`, request permission + register token via `POST /api/notifications/fcm-token`).

**Background handler (LOAD-BEARING):** top-level function annotated `@pragma('vm:entry-point')`; inside it call `await Firebase.initializeApp()` then `await configureDependencies()` (DI is not initialized in the background isolate). Register via `FirebaseMessaging.onBackgroundMessage(...)` in `main()` before `runApp`.

Configure: Android notification channel; iOS foreground banner presentation via `flutter_local_notifications`.

## Vehicle detail SOAT badge (US-2-3)

In `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_*.dart`: render the iter-1 `DocumentSlotPill` molecule for the SOAT slot. **Pass localized `stateLabel: context.l10n.soat_status_<state>`** — the molecule has no `BuildContext`, never rely on its hardcoded fallback. `onTap` → `context.pushNamed` to SOAT flow.

## DI & router

- Register `SoatCubit`, `NotificationsCubit`, `FcmService`, repositories, services, use cases — all via `@injectable`/`@singleton` annotations; run `build_runner` to regenerate `injection.config.dart`.
- Add SOAT pages + NotificationCenter route to `lib/shared/router/app_router.dart` + `app_routes.dart`. Use `context.pushNamed()` (back button enabled).
- `NotificationsCubit` — add to root `MultiBlocProvider` in `main.dart` (bell badge is app-wide).

## Story 2.9 — ManageAttendeesPage (presentation-only)

`lib/features/events/presentation/attendees/manage_attendees_page.dart` (or `attendees_management_page.dart`). Redesign per confirmed frame `dUc9h`: `AppButton`/`AppDialog`, no hardcoded colors, loading/empty/error states. Wait for design gate on frame scope (list+edit vs edit-only). No domain/data changes.

## Localization

`lib/l10n/app_es.arb` — add all SOAT (`soat_` prefix) and notification (`notification_` prefix) strings BEFORE use. Run `flutter gen-l10n`, commit generated files. Note: `notification_*` keys already partially exist from iter-1 stub — reuse, don't duplicate.

## Pre-existing non-blockers (address if you touch the file)

`mileage_info_dialog.dart` raw `AlertDialog`; `event_form_multi_brand_section.dart` raw `TextFormField`; `info_chip_tooltip.dart` raw `showDialog()`; `home_view_all_events_button.dart` uses `context.goNamed()`.

> Full detail: docs/handoffs/architect.md
