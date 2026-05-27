# Existing System Scan — Rideglory (Refactor & Cleanup)

> Generated: 2026-05-27
> Flutter app: /Users/cami/Developer/Personal/Rideglory/lib/
> Backend: /Users/cami/Developer/Personal/rideglory-api
> PRD: docs/prd-refactor-cleanup.md
> Coding standards: .cursor/rules/rideglory-coding-standards.mdc

---

## Flutter Feature Inventory

| Feature | Domain models | Data (DTOs/services) | Presentation (cubits/pages/widgets) | Status |
|---------|--------------|---------------------|-------------------------------------|--------|
| **authentication** | AuthModel | AuthDto, AuthService | AuthCubit, LoginPage, SignupPage, ForgotPasswordPage, misc. pages (9+ widgets) | Core |
| **home** | — | — | HomePageShell, HomeEventCardList, HomeGarageCard, 7+ view widgets | Core |
| **vehicles** | VehicleModel, BrandModel | VehicleDto, VehicleService, BrandService | VehicleCubit, GaragePage, VehicleFormPage, VehicleDetailPage, 16+ widgets in garage_vehicles_content.dart | Core |
| **events** | EventModel, EventRegistrationModel | EventDto, EventService, TrackingWsClient | EventsCubit, EventDetailCubit, EventFormCubit, EventsPage, EventDetailPage, EventFormPage, 9+ widgets per page | Core |
| **maintenance** | MaintenanceModel | MaintenanceDto, MaintenanceService | MaintenanceCubit, MaintenancesPage, MaintenanceDetailPage, MaintenanceFormPage, 12+ widgets in filters_bottom_sheet | Core |
| **event_registration** | EventRegistrationModel | EventRegistrationDto, EventRegistrationService | RegistrationCubit, RegistrationFormPage, RegistrationDetailPage | Feature |
| **notifications** | NotificationModel | NotificationDto, NotificationsService | NotificationsCubit, NotificationCenterPage | Feature |
| **profile** | UserModel | UserDto, UserService | ProfileCubit, ProfilePage, EditProfilePage, 3+ page-level widgets | Feature |
| **users** | UserModel, RiderProfileModel | UserDto, UserService | UsersCubit, RiderProfilePage, RiderProfileContent (4+ widgets) | Feature |
| **soat** | SoatModel | SoatDto, SoatService | SoatCubit, SoatUploadPage, SoatStatusPage, SoatManualFormPage | Feature (new) |
| **splash** | — | — | SplashPage | Core |

---

## Key Dependencies

| Category | Package | Purpose | Version |
|----------|---------|---------|---------|
| **State Management** | flutter_bloc, bloc | Cubit pattern | 9.1.1, 9.1.0 |
| **Code Generation** | freezed, freezed_annotation | Immutable models | 3.2.3, 3.1.0 |
| **JSON Serialization** | json_serializable, json_annotation | DTO serialization | 6.11.2, 4.9.0 |
| **Forms** | flutter_form_builder, form_builder_validators | Form UI & validation | 10.2.0, 11.0.0 |
| **Firebase** | firebase_core, firebase_auth, cloud_firestore, firebase_messaging, firebase_storage, firebase_remote_config | Auth, DB, FCM, Storage, Config | 4.2.1, 6.1.2, 6.1.0, 16.2.0, 13.1.0, 6.4.0 |
| **Notifications** | flutter_local_notifications | Local push handling | 18.0.1 |
| **Social Auth** | google_sign_in | OAuth | 6.2.1 |
| **DI** | get_it, injectable | Service locator | 9.2.0, 2.7.1+2 |
| **Routing** | go_router | Declarative routing | 17.0.0 |
| **Storage** | shared_preferences, flutter_secure_storage | Local persistence | 2.3.5, 10.1.0 |
| **Maps** | mapbox_maps_flutter | Interactive maps | 2.2.0 |
| **Background GPS** | flutter_foreground_task, geolocator | Android foreground service, location | 8.14.0, 14.0.2 |
| **Utilities** | dartz, intl, url_launcher, app_links | FP, i18n, linking | 0.10.1, 0.20.2, 6.3.1, 6.3.2 |
| **UI/UX** | flutter_quill, google_fonts, image_picker, permission_handler, cached_network_image, shimmer, lucide_icons, file_picker | Rich text, fonts, images, icons | 11.0.0, 8.0.2, 1.2.1, 11.3.1, 3.4.1, 3.0.0, —, 11.0.2 |
| **HTTP** | dio, retrofit | HTTP client framework | 5.9.2, 4.9.2 |
| **WebSocket** | web_socket_channel | Real-time tracking | 3.0.3 |
| **Config** | envied | Environment variables | 1.3.3 |
| **Testing** | mocktail, bloc_test, patrol, network_image_mock, integration_test | Test utilities | 1.0.4, 10.0.0, 4.5.0, 2.1.1 |

---

## Violations Inventory

### 3.1 Multiple Widget Classes Per File

| Violation Count | Severity | Impact |
|---|---|---|
| **68 files** with 2+ widget classes | 🔴 Critical | Architecture integrity, maintainability |

**Top 10 most-violating files:**
| File | Widget Count | Category |
|------|---|---|
| `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | **16** | Garage list view with nested cards + filters |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | **13** | Vehicle detail page composition |
| `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_filters_bottom_sheet.dart` | **12** | Maintenance filter UI |
| `lib/features/vehicles/presentation/form/vehicle_form.dart` | **9** | Multi-step vehicle form |
| `lib/features/authentication/login/presentation/forgot_password_view.dart` | **9** | Password recovery flow |
| `lib/features/events/presentation/detail/widgets/event_detail_view.dart` | **9** | Event detail page composition |
| `lib/features/authentication/login/presentation/login_view.dart` | **8** | Login screen |
| `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart` | **8** | Event CTA bar with states |
| `lib/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart` | **7** | Max participants input section |
| `lib/features/authentication/signup/presentation/signup_view.dart` | **6** | Signup screen |

**Additional 4-5 widget files (24 files total):** soat_confirmation_page (4), rider_profile_content (4), live_map_app_bar (4), events_data_view (4), event_route_config_screen (4), event_form_price_section (4), event_detail_owner_lifecycle_bar (4), event_detail_meeting_point_section (4), + 8 more with 2-3 widgets.

---

### 3.2 Widget-Returning Methods

| Method Count | Files Affected |
|---|---|
| **8 violations** | 8 distinct files |

| File | Methods |
|------|---------|
| `lib/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart` | `Widget _buildContainer()`, `Widget _buildPlaceholderIcon()` |
| `lib/features/events/presentation/detail/event_detail_by_id_page.dart` | `Widget _shell(BuildContext context, Widget body)` |
| `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart` | `Widget _buildContent(BuildContext context)` |
| `lib/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart` | `Widget _rightBadge(BuildContext context, int currentMileage)` |
| `lib/features/events/presentation/tracking/participants/participants_placeholder_page.dart` | `Widget _buildEmptyState(BuildContext context)`, `Widget _buildRiderList(BuildContext context)` |
| `lib/features/events/presentation/list/widgets/event_card_header.dart` | `Widget _buildPopupMenu(BuildContext context)` |
| `lib/features/vehicles/presentation/widgets/vehicle_card.dart` | `Widget _buildPlaceholderIcon(BuildContext context)` |

---

### 3.3 Raw Button Usage (ElevatedButton/TextButton/OutlinedButton)

| Violation Count | Files Affected | Risk |
|---|---|---|
| **6 confirmed** (ElevatedButton 1, TextButton 3, OutlinedButton 1, plus more) | 6 feature files | Medium — UX inconsistency |

| File | Instances | Button Type |
|------|---|---|
| `lib/features/users/presentation/widgets/rider_profile_content.dart` | 1 | ElevatedButton + styleFrom |
| `lib/features/events/presentation/form/screens/event_route_config_screen.dart` | 1 | TextButton + styleFrom |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | 3 | TextButton (3×) |
| Other occurrences in list filters, dialogs (sampled, not exhaustive) | — | Mixed |

**Note:** AppTextButton and AppButton are correctly used in most places; raw buttons are legacy remnants.

---

### 3.4 FormBuilderTextField vs AppTextField

| Violation Count | Files Affected |
|---|---|
| **5 occurrences** | 5 files |

| File | Count |
|------|-------|
| `lib/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart` | 1 |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_id_section.dart` | 2 |
| `lib/features/maintenance/presentation/form/widgets/maintenance_next_km_pill.dart` | 1 |
| `lib/features/events/presentation/form/widgets/sections/event_form_price_section.dart` | 1 |

**Mitigation:** AppTextField exists and should replace all 5 uses.

---

### 3.5 Navigation: Navigator.of(context) in Features

| Violation Count | Files Affected | Risk |
|---|---|---|
| **31 occurrences** | Multiple features | Medium — inconsistent with go_router |

**Primary areas:**
- `lib/features/vehicles/presentation/soat/` (entire folder, old implementation)
- `lib/features/maintenance/form/maintenance_form_page.dart`
- `lib/features/event_registration/presentation/widgets/`
- Scattered in various list/detail workflows

---

### 3.6 Navigation: context.goNamed() Instead of pushNamed()

| Violation Count | Files Affected | Risk |
|---|---|---|
| **5 occurrences** | 3 files | Low–Medium — mostly in PopScope |

| File | Usage | Context |
|------|-------|---------|
| `lib/features/profile/presentation/profile_page.dart` | `context.goNamed(AppRoutes.home)` | PopScope (potentially intentional) |
| `lib/features/vehicles/presentation/garage/garage_page.dart` | `context.goNamed(AppRoutes.home)` | PopScope |
| `lib/features/events/presentation/list/events_page.dart` | `context.goNamed(AppRoutes.home)` | PopScope |
| `lib/features/authentication/login/presentation/forgot_password_view.dart` | `context.goNamed(AppRoutes.login)` | 2× (return from password recovery) |

**Recommendation:** Review each usage — PopScope cases may be intentional (clearing stack), but forgot_password navigation should use pushNamed.

---

### 3.7 Hardcoded Colors

| Violation Count | Severity |
|---|---|
| **~10–15 instances** | Medium — inconsistent with design system |

| File | Examples |
|------|----------|
| `lib/features/home/presentation/widgets/home_event_view_details_button.dart` | `Colors.white`, `Colors.black87` |
| `lib/features/home/presentation/widgets/home_view_all_events_button.dart` | `Colors.transparent` |
| `lib/features/home/presentation/widgets/home_vehicle_info_row.dart` | Color literals for SOAT status (should use AppColors) |

**Status:** Most colors are already using AppColors or colorScheme; a small number of legacy Colors.* remain.

---

### 3.8 dart analyze Warnings

| Issue | File | Line | Type |
|---|---|---|---|
| **dead_code** | `lib/core/http/api_base_url_resolver.dart` | 19 | Unreachable code (conditional branch) |
| **prefer_const_declarations** | `lib/core/http/api_base_url_resolver.dart` | 17 | Final variable should be const |

**Status:** Only 2 low-severity issues; easily fixable.

---

### 3.9 Primitive Flags in State (bool isLoadingMore)

| Issue | File | Field | Risk |
|---|---|---|---|
| **Pagination flag** | `lib/features/notifications/data/notifications_state.dart` | `@Default(false) bool isLoadingMore` | Low — acceptable exception for pagination incremental loading |

**Status:** Documented as exception per PRD; technically violates pattern but justified for cursor-based pagination.

---

### 3.10 SOAT Duplication

| Location | Status | Scope |
|---|---|---|
| `lib/features/soat/` | **New** (complete domain/data/presentation) | Full feature with 3 layers |
| `lib/features/vehicles/presentation/soat/` | **Legacy** (presentation only, old impl) | Pages: SoatUploadPage, SoatConfirmationPage, SoatManualCapturePage + cubit + widgets (7+ files) |

**Router:** Both are active:
- `/vehicles/soat` → legacy SoatUploadPage
- `/soat/upload`, `/soat/status` → new SoatUploadPage, SoatStatusPage
- soat_status_view.dart (new) imports SoatManualCapturePage (legacy)

**Action:** Consolidate into `features/soat/`, eliminate `vehicles/presentation/soat/`, update routes.

---

## Code Duplication & Dead Code

| Issue | Files | Impact |
|---|---|---|
| **SOAT implementation duplication** | `features/soat/` + `features/vehicles/presentation/soat/` | Maintenance burden; inconsistent implementations |
| **Unused imports** | Scattered across features | Low impact; cleanup needed during refactoring |
| **api_base_url_resolver.dart dead code** | 1 file | Reachable dead code in conditional branch |

---

## Design Artifacts

| Folder | Iterations | Screens Covered | Status |
|---|---|---|---|
| `docs/design/html-mockups/iter-2/` | Iteration 2 | SOAT registration flow, notification UI, attendees mgmt | Complete |
| `docs/design/html-mockups/iter-3/` | Iteration 3 | Tracking map, SOS flow, organizer controls, maintenance reminders | Complete |

**Note:** No iter-1, iter-4, iter-5 mockup folders present. Pencil design file `rideglory.pen` is the source of truth for visual design.

---

## Planning Implications

1. **Scope is substantial but scoped:** 68 files with widget violations, 5 sub-categories of refactoring. The PRD divides work into 3 sub-iterations (A: bug fix + dead code; B: widget extraction; C: primitives + navigation), reducing risk of regression per sub-iteration.

2. **SOAT consolidation is critical blocker:** Before iter-2 (SOAT feature) can ship, the duplication must be resolved. Both old and new implementations are active in the router — this creates maintenance debt and potential runtime conflicts. Recommend completion in Sub-iter A to unblock downstream work.

3. **Widget extraction effort is the bulk:** Files like `garage_vehicles_content.dart` (16 widgets) and `vehicle_detail_view.dart` (13 widgets) require careful refactoring to preserve StatefulWidget state sharing and callback chains. Sub-iter B estimates are appropriate for experienced Flutter developers.

4. **No functional changes required:** All refactoring is internal architecture; business logic and API contracts remain untouched. This reduces testing burden and allows `flutter test` baseline to remain stable throughout.

5. **Color tokenization is partially done:** ~47 Color(0x...) literals already replaced in iter-1 redesign (PR #13); 10–15 remaining Colors.* hardcodes are mostly in gradients, overlays, or SOAT-specific state colors. Recommend targeting AppColors or colorScheme during Sub-iter C.

6. **Navigation migration is low-risk:** 31 Navigator.of() calls are concentrated in SOAT (legacy folder) and maintenance/registration forms. Systematic replacement with go_router extensions (pushNamed/goAndClearStack) poses minimal regression risk if tested per sub-iter.

7. **Testing gates are clear:** `dart analyze` (0 warnings) and `flutter test` (100% pass) must hold steady across all sub-iterations. BUG-3-1 (route_map_preview widget test from iter-3) is already resolved; no new test debt expected from this refactoring.

8. **Timeline estimates:** Sub-iter A (bug + SOAT + dead code) = 1 day; Sub-iter B (widget extraction, 12+ files) = 2–3 days; Sub-iter C (primitives + colors + navigation) = 1–2 days. Total: 4–6 days for a focused developer or pair.

---

## Next Steps

1. **Run `/solo-plan` or `/iter Refactor-01`** to formalize the 3 sub-iterations into a phased execution plan with stories and acceptance criteria.
2. **Assign Sub-iter A as highest priority** to resolve SOAT duplication and unblock iter-2 feature work.
3. **Use code review checklist** from CLAUDE.md to gate each sub-iter PR: verify no new Color(0x...) literals, AppButton/AppTextField adoption, 1-widget-per-file rule, no Widget _buildXxx methods.
