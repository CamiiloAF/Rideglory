# Rideglory — Product Plan

> Status: AWAITING HUMAN APPROVAL
> Generated: 2026-05-12
> Run /solo-approve to approve, or edit docs/PLAN_FEEDBACK.md and re-run /solo-plan.

---

## Summary

- **Brownfield app with a solid core.** Authentication, vehicles, events, event registration, maintenance, and live tracking are largely implemented. The 9 feature folders, 17 cubits, 15+ pages, and 40+ API endpoints are operational. Remaining work is high-value additions (SOAT, AI, notifications, SOS) and a critical quality deficit (0% test coverage).
- **Test infrastructure ships first.** The entire plan rests on a working test suite. Iteration 1 establishes `mocktail`, `bloc_test`, and `network_image_mock`; writes unit and widget tests for the most critical existing cubits and pages; and completes the profile feature stub that currently shows riders an empty page.
- **Features are sequenced by full-stack dependency.** Event filters and attendee profile links (Iter 2) complete existing UI. SOAT (Iters 3a/3b) is the largest new full-stack feature and sets the Claude API pattern reused by AI cover generation (Iter 4) and recommendations (Iter 5). Push notifications and SOS (Iters 6a/6b) come last as the highest-integration-risk items.
- **Two large iterations are split for delivery safety.** SOAT is split into 3a (infrastructure) and 3b (full UI). FCM + SOS is split into 6a (push notifications) and 6b (SOS real-time alert). Each half is independently shippable with green CI.
- **Two parallel tracks run without blocking Flutter delivery.** Track P (Pencil design system) must complete before Iteration 3b begins. Track DevOps (GitHub Actions CI) runs alongside Iteration 2 so automated checks are in place from Iteration 3 onward.

---

## Iteration Roadmap

| Iter | Title | Goal | Agents | Complexity | Depends On |
|------|-------|------|--------|-----------|------------|
| 1 | Test Infrastructure + Profile Feature | Working test suite + complete profile page | frontend, qa | M | — |
| 2 | Event Discovery Filters + Attendee Profile Links | Filter events by type/date/city; tap riders into profile | backend, frontend, qa | M | 1 |
| 3a | SOAT Backend + Domain/Data Infrastructure | Backend endpoints, Claude Haiku extraction, Flutter domain + data layers | backend, frontend, qa | L | 1 |
| 3b | SOAT Full Flutter UI | Multi-step upload flow + garage status badges | design, frontend, qa | M | 3a, P |
| 4 | AI Event Cover Image Generation | Wire existing button to Unsplash + Claude Haiku backend | backend, frontend, qa | M | 3a |
| 5 | AI Event Recommendations | Populate dashboard recommendations card from scoring endpoint | backend, frontend, qa | M | 2, 4 |
| 6a | Push Notifications (FCM) | firebase_messaging + device token registration + 5 FCM triggers + deep-link routing | backend, frontend, qa | L | 5 |
| 6b | SOS Real-Time Alert | SOS WebSocket message type + overlay banner + backend broadcast | backend, frontend, qa | M | 6a |
| P | Design System in Pencil | All screen flows in pencil-new.pen with design token variables | design | M | — (parallel) |
| DevOps | CI/CD Pipeline | GitHub Actions: dart analyze + flutter test + APK build | devops | S | — (parallel with 2) |

---

## Parallel Tracks

### Track P — Design System in Pencil (HU-DESIGN-01)

Runs alongside Iterations 1 through 3a. The design agent works independently on `pencil-new.pen`, importing all existing screen flows (8 flows, ~30 screens) and defining design tokens (color `#f98c1f`, dark background `#0D0D0D`, Space Grotesk font, 8px border radius) as Pencil variables. No Flutter code is touched.

**Hard gate:** The SOAT upload flow (file picker entry, upload progress, AI extraction loading, confirmation form, manual entry fallback) must be designed in Pencil before Iteration 3b frontend work begins. The frontend agent must not implement the SOAT UI without Pencil specs.

**Deliverables:** `pencil-new.pen` (all 8 flows), `docs/handoffs/design.md` (variable keys and section names), exported screenshots in `docs/design/screenshots/<flow>.png`.

### Track DevOps — CI/CD Pipeline

Runs in parallel with Iteration 2. Delivers a `.github/workflows/flutter-ci.yml` pipeline that runs `dart analyze` and `flutter test` on every push to any `iter-N` branch and on every PR to `main`. An optional APK build job triggers on version tags. No new Flutter code is required — the pipeline consumes what Iteration 1 delivers.

**Goal:** From Iteration 3 onward, every PR is gated by automated CI. Manual `dart analyze` + `flutter test` execution before each commit is no longer the sole quality gate.

---

## Iteration 1 — Test Infrastructure + Profile Feature Completion

### Goal

Establish a working test suite for the most critical existing features and complete the profile feature so the rider experience is coherent end-to-end.

### Why Now

The codebase has a single empty test file. Without a test suite, every subsequent iteration ships without regression detection and CI cannot pass. Profile is the most visible gap — riders see a blank page when they tap their own name. Both items have no external dependencies and no new backend endpoints.

### User Stories

- **HU-TEST-01a** · Test infrastructure bootstrap · As the dev team, I want `mocktail`, `bloc_test`, and `network_image_mock` configured and a test directory tree established so that subsequent iterations can write tests with consistent tooling.
- **HU-TEST-01b** · Cubit unit tests · As the dev team, I want `blocTest` groups covering `VehicleCubit`, `EventsCubit`, `EventDetailCubit`, and `MaintenancesCubit` (initial → loading → data → empty → error) so regressions in state transitions are caught automatically.
- **HU-TEST-01c** · Widget tests · As the dev team, I want widget tests for the vehicle garage page, event list page, and event detail page covering all `ResultState` UI branches (shimmer skeleton, data render, empty state, error banner) so design system components are verified under every condition.
- **HU-PROFILE-01** · Profile page completion · As a rider, I tap my profile in the bottom navigation and see my name, email, initials avatar, and main vehicle so I feel recognized as a community member.

### Acceptance Criteria

1. `dev_dependencies` in `pubspec.yaml` includes `mocktail: ^1.0.4`, `bloc_test: ^10.0.0`, and `network_image_mock: ^2.1.1`.
2. Test directory tree exists: `test/features/vehicles/domain/`, `test/features/vehicles/data/`, `test/features/vehicles/presentation/`, `test/features/events/domain/`, `test/features/events/data/`, `test/features/events/presentation/`, `test/features/maintenance/domain/`, `test/features/maintenance/data/`, `test/features/maintenance/presentation/`, `test/core/`.
3. `VehicleCubit` has a `blocTest` group with at minimum 5 test cases: initial state, emits `loading` on fetch start, emits `data` on success, emits `empty` when list is empty, emits `error` when use case returns `Left(DomainException)`.
4. `EventsCubit` and `EventDetailCubit` each have equivalent `blocTest` groups (5 cases each covering the same 5 states).
5. `MaintenancesCubit` has a `blocTest` group covering initial, loading, data, and error states (minimum 4 cases).
6. Vehicle garage page widget test covers: loading skeleton renders (shimmer), data state renders vehicle cards, empty state renders `EmptyStateWidget`, error state renders error banner with retry button.
7. Event list page widget test covers: loading skeleton, data state (at least one event card visible), empty state, error state.
8. Event detail page widget test covers: loading skeleton, data state (event title visible), error state.
9. Integration test stub files exist with at least one `group` block each: `integration_test/auth_flow_test.dart`, `integration_test/vehicles_flow_test.dart`, `integration_test/events_flow_test.dart`.
10. `ProfileCubit` exists in `lib/features/profile/presentation/cubit/` as `Cubit<ResultState<UserModel>>`, registered in `injection.dart`, and added to the root `MultiBlocProvider` in `main.dart`.
11. `GetMyProfileUseCase` exists in `lib/features/profile/domain/` and calls `UserService.getMe()` (already exists); no new backend endpoint required.
12. Profile page renders a shimmer skeleton while `ProfileCubit` emits `loading`.
13. Profile page renders the rider's name and email from `UserModel` when `ProfileCubit` emits `data`.
14. Profile page renders an initials-based avatar (two-letter `CircleAvatar`) when `profilePhotoUrl` is null or absent — no broken image widget.
15. Profile page renders the main vehicle name and model from `VehicleCubit` state when a main vehicle exists; renders a "Sin vehículos" placeholder (using `EmptyStateWidget` or inline text) when `VehicleCubit` emits `empty`.
16. Profile page renders an error banner with a retry button when `ProfileCubit` emits `error`.
17. No hardcoded Spanish strings — new profile UI keys are in `app_es.arb` with prefix `profile_` (e.g., `profile_noVehicle`, `profile_errorRetry`).
18. No raw Material widgets where a shared equivalent exists (`AppButton`, `AppTextField`, `EmptyStateWidget`).
19. `dart run build_runner build --delete-conflicting-outputs` runs cleanly with zero new analysis warnings.
20. `dart analyze` passes with zero violations.
21. `flutter test` passes with 100% green tests.

### Technical Notes

- **New packages (dev):** `mocktail: ^1.0.4`, `bloc_test: ^10.0.0`, `network_image_mock: ^2.1.1` — add to `dev_dependencies` in `pubspec.yaml`, then run `flutter pub get` (no build_runner step needed).
- **Mock pattern:** Use `mocktail` with abstract class mocking (`class MockVehicleRepository extends Mock implements VehicleRepository`). Register fallback values for custom types in `setUpAll`.
- **Widget test pattern:** Wrap pages in `BlocProvider<CubitType>.value(value: mockCubit)`. Use `whenListen` from `bloc_test` to emit state sequences. Wrap with `network_image_mock`'s `mockNetworkImages()` to prevent `CachedNetworkImage` from throwing.
- **`ProfileCubit` state:** Use `Cubit<ResultState<UserModel>>` directly (no new freezed class needed; the existing `ResultState<T>` union is sufficient for a single-result cubit).
- **Profile photo decision (ADR-2):** Phase 1 profile shows no photo upload affordance. `profilePhotoUrl` is not in the current Prisma `User` model. The profile page shows an initials avatar only. Photo upload is deferred.
- **DI registration:** `ProfileCubit` must be `@injectable` (not `@singleton`) unless it is a global cubit. Given that profile data is user-specific, add it as a `@lazySingleton` to `injection.dart` and to the root `MultiBlocProvider` alongside `AuthCubit`.
- **ARB keys to add:** `profile_title`, `profile_noVehicle`, `profile_errorRetry`, `profile_loadingError`, `profile_mainVehicle`.

### Agents

frontend, qa

### Estimated Complexity

M

### Dependencies

None (Iteration 0 done)

---

## Iteration 2 — Event Discovery Filters + Attendee Profile Links

### Goal

Make event discovery fully functional by wiring the existing filter bottom sheet to real query parameters, and enable riders to tap into other riders' profiles from the event attendee list.

### Why Now

Event filters exist in the UI but are not connected to the backend — riders see all events with no way to narrow by type, date, or city. The attendee list has no navigation, making community discovery impossible. Both are completions of existing UI with no new architecture. The backend filter gap is the only concrete risk and is addressed in this iteration.

### User Stories

- **HU-EVENT-FILTER-01** · Event list filters · As a rider browsing events, I tap the filter icon on the event list and select event type, date range, and city so I see only the upcoming rides relevant to me.
- **HU-EVENT-FILTER-02** · Clear filters · As a rider, I can clear all active filters with one tap on the filter badge so I return to the full event list without navigating away.
- **HU-ATTENDEE-PROFILE-01** · Attendee profile navigation · As a rider viewing the attendee list of an event, I tap another rider's avatar or name and see their profile page (name, email, vehicles) so I can learn about other community members on the same ride.

### Acceptance Criteria

1. Backend: `GET /events` and `GET /events/upcoming` in `api-gateway` forward optional query params `type`, `dateFrom`, `dateTo`, and `city` to the events-ms `findAllEvents` handler.
2. Backend: events-ms `findAllEvents` Prisma query applies `WHERE` conditions for each filter when the param is present: `eventType == type`, `startDate >= dateFrom`, `startDate <= dateTo`, `city ILIKE city` (case-insensitive prefix match).
3. Backend: events-ms has unit tests covering `findAllEvents` with: type-only filter, date-range-only filter, city-only filter, combined filter, and no filters (returns all).
4. `EventsCubit` state is refactored to a `@freezed` `EventsState` class containing `ResultState<List<EventModel>> eventsResult` and `EventFilter? activeFilter` fields.
5. `EventsCubit.applyFilters({EventType? type, DateTime? dateFrom, DateTime? dateTo, String? city})` method exists and triggers a new fetch with the supplied params.
6. `EventsCubit.clearFilters()` method exists and resets filters to null, triggering a fresh fetch.
7. The filter bottom sheet (`event_filters_bottom_sheet.dart`) is wired to `EventsCubit.applyFilters()`. The date range picker uses `flutter_form_builder`'s `FormBuilderDateRangePicker` or wraps `showDateRangePicker` with the app's `ThemeData` (dark mode — no white Material calendar flash).
8. An active filter is visually indicated by an orange `Badge` widget with the filter count on the filter icon in the event list app bar.
9. Filtered empty state shows "No hay eventos con estos filtros" and a "Limpiar filtros" button; this is distinct from the all-events empty state message.
10. `RiderProfilePage` exists in `lib/features/users/presentation/pages/` and accepts a `String userId` as route extra, fetches the user via `GetUserByIdUseCase` (calls existing `UserService.getUserById()`), and displays name, email, and vehicles.
11. `RiderProfilePage` is read-only: no edit button, no "Set as main vehicle" affordance.
12. Navigation to `RiderProfilePage` from the attendee list uses `context.pushNamed()` (not `goNamed`) so the back button returns to the attendee list.
13. `AppRoutes.riderProfile` route is registered in `app_router.dart`.
14. `EventsCubit` existing tests from Iteration 1 are updated to reflect the new `EventsState` structure.
15. Unit tests for `EventsCubit.applyFilters()` and `clearFilters()` (filter state transitions, param forwarding).
16. Widget test: filtered empty state renders "No hay eventos con estos filtros" when `eventsResult` is `empty` and `activeFilter` is non-null.
17. Widget test: `RiderProfilePage` renders in loading, data, and error states.
18. `GetUserByIdUseCase` exists in `lib/features/users/domain/` (if not already present) and is registered in DI.
19. New ARB keys with prefix `event_` and `rider_` (e.g., `event_noResultsFiltered`, `event_clearFilters`, `rider_profileTitle`).
20. `dart run build_runner build --delete-conflicting-outputs` runs cleanly after `EventsState` freezed class is added.
21. `dart analyze` passes with zero violations.
22. `flutter test` passes with 100% green tests.

### Technical Notes

- **Backend filter gap (Architect Risk 1):** Confirmed gap — neither `GET /events` nor `GET /events/upcoming` forwards filter params today. Backend changes are in scope for this iteration.
- **`EventsState` refactor:** `EventsCubit` goes from `Cubit<ResultState<List<EventModel>>>` to `Cubit<EventsState>` where `EventsState` is a `@freezed` class. Run `dart run build_runner build` after adding the class and its `part` directive.
- **City filter:** Use `city` (the existing `city` field on the `Event` Prisma model), not a free-text `location` string. Case-insensitive prefix match in Prisma: `{ city: { contains: city, mode: 'insensitive' } }`.
- **Date range picker theming:** Confirm the existing `MaterialApp` `ThemeData` propagates dark mode to `showDateRangePicker`. If not, wrap the call with an explicit `Theme(data: Theme.of(context), child: ...)`.
- **`GetUserByIdUseCase`:** Likely already wired in the data layer given `UserService.getUserById()` exists. If the use case class is missing, create it following the standard pattern in `lib/features/users/domain/use_cases/`.
- **ARB keys to add:** `event_filterTitle`, `event_filterType`, `event_filterDateRange`, `event_filterCity`, `event_clearFilters`, `event_noResultsFiltered`, `rider_profileTitle`, `rider_noVehicles`.

### Agents

backend, frontend, qa

### Estimated Complexity

M

### Dependencies

Iteration 1

---

## Iteration 3a — SOAT Backend Infrastructure + Flutter Domain/Data Stub

### Goal

Build the complete backend infrastructure for SOAT document management (Prisma schema, REST endpoints, Claude Haiku AI extraction) and implement the Flutter domain and data layers so that the full UI in Iteration 3b has a stable, tested foundation.

### Why Now

SOAT is the largest new full-stack feature in the PRD. Separating infrastructure from UI allows the backend to be validated independently and gives the design agent (Track P) time to produce Pencil screens before any Flutter widgets are built. This iteration also establishes the Claude API integration pattern in `rideglory-api` that Iteration 4 (AI event cover) will reuse.

### User Stories

- **HU-SOAT-01a** · Insurance document domain model · As the dev team, I want an `InsuranceDocumentModel` in the domain layer and a fully tested `InsuranceDocumentCubit` with all upload-flow states so that the UI in Iteration 3b can be implemented without architectural changes.
- **HU-SOAT-01b** · Backend SOAT endpoint · As a rider, when I upload a SOAT PDF, the backend extracts the expiration date via Claude Haiku and returns it for confirmation so I don't have to read the document myself.
- **HU-SOAT-01c** · Manual entry fallback contract · As a rider, when AI extraction fails (422 response), the Flutter app transitions to a manual date entry state so I can always save the expiration date even if AI cannot read the PDF.

### Acceptance Criteria

1. **Backend — Prisma schema:** `InsuranceDocument` model added to vehicles-ms with fields: `id` (uuid), `vehicleId` (FK → Vehicle, cascade delete), `storageUrl` (String), `expirationDate` (DateTime), `docType` (enum: `SOAT | TECNO | OTHER`), `extractionConfidence` (String?), `createdAt`, `updatedAt`. Unique constraint on `(vehicleId, docType)`.
2. **Backend — Prisma migration:** `npx prisma migrate dev` applied and committed. `npx prisma generate` run.
3. **Backend — `POST /vehicles/my/:vehicleId/insurance`:** Accepts `{ storagePath: string, docType: "soat" | "tecno" | "other" }`. Downloads the PDF from Firebase Storage via Admin SDK using the path. Sends PDF content (base64) to Claude Haiku API for date extraction. Returns 201 with `InsuranceDocumentDto` on success, or 422 with `{ extractionError: true, message: "No se pudo extraer la fecha del PDF. Ingresa la fecha manualmente." }` on extraction failure.
4. **Backend — `PATCH /vehicles/my/:vehicleId/insurance/:documentId`:** Accepts `{ expirationDate: string (ISO 8601) }`. Updates the record. Returns 200 with the updated `InsuranceDocumentDto`.
5. **Backend — Claude Haiku integration:** `ClaudeService` in `api-gateway` uses the Anthropic SDK for Node.js. It sends the PDF as a base64-encoded document block to the Claude Haiku model and extracts the expiration date. Returns `{ expirationDate: string | null, confidence: "high" | "low" }`. If Claude returns null or throws, the extraction is treated as a failure.
6. **Backend — Firebase Storage access:** Backend uses `admin.storage().bucket().file(storagePath).download()` (Firebase Admin SDK) to retrieve the PDF. Flutter sends the storage path `insurance/{userId}/{vehicleId}/{docType}.pdf`, not a signed URL.
7. **Backend unit tests:** `POST /vehicles/my/:vehicleId/insurance` happy path (extraction success) + 422 path (extraction failure). `PATCH` happy path + 404 (document not found).
8. **Flutter — `file_picker: ^8.0.0`** added to `dependencies` in `pubspec.yaml`.
9. **Flutter — `InsuranceDocumentModel`** in `lib/features/vehicles/domain/models/` with fields: `id`, `vehicleId`, `storageUrl`, `expirationDate` (DateTime), `docType` (String), `extractionConfidence` (String?), `status` (enum `InsuranceDocumentStatus { valid, expiringSoon, expired }`). Pure Dart — no Flutter imports.
10. **Flutter — `InsuranceDocumentStatus` computation:** Pure function `computeStatus(DateTime expirationDate)` → `expired` if `daysLeft < 0`, `expiringSoon` if `daysLeft <= 30`, `valid` otherwise.
11. **Flutter — `InsuranceDocumentDto`** in `lib/features/vehicles/data/dto/` with `@JsonSerializable()`. Fields match the backend response shape. `fromJson` factory generated.
12. **Flutter — `InsuranceService`** (Retrofit client) in `lib/features/vehicles/data/service/` with endpoints: `POST /vehicles/my/:vehicleId/insurance` and `PATCH /vehicles/my/:vehicleId/insurance/:documentId`.
13. **Flutter — `InsuranceRepository`** interface in domain and `InsuranceRepositoryImpl` in data, registered in `injection.dart` with `@Injectable(as: InsuranceRepository)`.
14. **Flutter — use cases:** `UploadInsuranceDocumentUseCase` (triggers Firebase Storage upload via a new `PdfStorageService`, then calls `POST` endpoint), `ConfirmInsuranceDateUseCase` (calls `PATCH` endpoint), `GetVehicleInsuranceUseCase` (fetches insurance document for a vehicle).
15. **Flutter — `PdfStorageService`** in `lib/features/vehicles/data/service/` handles file upload to `insurance/{userId}/{vehicleId}/{docType}.pdf` using `firebase_storage`. Returns the storage path (not a URL).
16. **Flutter — `InsuranceDocumentCubit`** in `lib/features/vehicles/presentation/cubit/` with a `@freezed` `InsuranceUploadState` class containing a status enum (`initial | uploading | extracting | confirmation | manualEntry | saving | saved | error`) and nullable fields `extractedDate`, `extractionConfidence`, `extractionError`, `savedDocument`. Cubit registered in DI.
17. **Flutter — stub UI:** A minimal "Subir SOAT" `AppButton` in the vehicle detail page that triggers `InsuranceDocumentCubit.startUpload()`. No multi-step UI yet (that is Iteration 3b).
18. **Flutter — unit tests:** `UploadInsuranceDocumentUseCase` (happy path, extraction-failure path, storage-upload-error path). `ConfirmInsuranceDateUseCase` (happy path, 404 path). `InsuranceRepositoryImpl` (DTO → model mapping for both success and 422 cases). `InsuranceDocumentCubit` `blocTest` groups for all 8 status transitions.
19. `dart run build_runner build --delete-conflicting-outputs` runs cleanly (`InsuranceDocumentDto` json_serializable + `InsuranceUploadState` freezed + `InsuranceService` retrofit).
20. `dart analyze` passes with zero violations.
21. `flutter test` passes with 100% green tests.

### Technical Notes

- **Storage path convention:** `insurance/{userId}/{vehicleId}/{docType}.pdf` — re-uploading the same `docType` for the same vehicle overwrites the previous file in Firebase Storage and upserts the database record (the unique constraint on `(vehicleId, docType)` enforces single-record-per-type).
- **Claude Haiku prompt:** Send the PDF as a base64-encoded document in the Claude API `documents` block (not as a URL). Sample prompt: "Extract the insurance expiration date from this document. Return only a JSON object: `{\"expirationDate\": \"YYYY-MM-DD\", \"confidence\": \"high\"|\"low\"}`. If you cannot find a date, return `{\"expirationDate\": null, \"confidence\": \"low\"}`."
- **Permission handling:** `file_picker` on Android may require `READ_MEDIA_VISUAL_USER_SELECTED` (API 33+) or `READ_EXTERNAL_STORAGE` (API < 33). `permission_handler` is already in the stack. Request permission before opening the picker; if denied, show an explanation dialog.
- **Code generation sequence:** (1) Add `part` directives, (2) run `dart run build_runner build` once for all three generated files in a single pass.
- **ARB keys to add:** `soat_uploadButton`, `soat_uploading`, `soat_extracting`, `soat_extractionError`, `soat_confirmDate`, `soat_manualEntryTitle`, `soat_saved`, `soat_errorRetry`, `soat_permissionDenied`.

### Agents

backend, frontend, qa

### Estimated Complexity

L

### Dependencies

Iteration 1

---

## Iteration 3b — SOAT Full Flutter UI + Garage Status Badges

### Goal

Implement the complete multi-step SOAT upload UI (file picker → upload progress → AI extraction loading → confirmation/edit form → error fallback → success) and the visual expiration status badge on vehicle cards throughout the garage.

### Why Now

With the backend, domain, and data layers from Iteration 3a stable and tested, the UI can be implemented cleanly against real contracts. The Pencil design from Track P is a hard prerequisite — no widget implementation begins until SOAT screens are in Pencil.

### User Stories

- **HU-SOAT-01d** · Upload flow UI · As a rider, I open the vehicle detail page, tap "Subir SOAT", select a PDF from my device, see upload progress and then an AI extraction loading indicator, and finally see the extracted expiration date pre-filled in a confirmation form so I can review and save it.
- **HU-SOAT-01e** · Manual entry fallback UI · As a rider, when AI extraction fails, I see a clear explanation and a date picker to enter the expiration date manually so I can always record the correct date.
- **HU-SOAT-01f** · Garage status badges · As a rider viewing my garage, I see a colored badge on each vehicle card (Vigente / Por vencer / Vencido) for vehicles with an uploaded SOAT so I can spot insurance status at a glance.

### Acceptance Criteria

1. Vehicle detail page has a "Documentos obligatorios" section with an "Subir SOAT" `AppButton` (or equivalent from the Pencil design).
2. Tapping "Subir SOAT" opens the `file_picker` PDF selector. If file access permission is denied, an explanation dialog is shown (using `AppDialog`) and the flow stops gracefully — no crash.
3. After a PDF is selected, a progress indicator (indeterminate `LinearProgressIndicator`) is visible with the text "Subiendo documento..." while the file uploads to Firebase Storage.
4. After upload completes, the loading indicator changes to "Extrayendo fecha con IA..." (a distinct loading state from the upload progress — different copy, same or different widget) while the backend processes the PDF.
5. On successful AI extraction, a confirmation form appears with: the extracted expiration date pre-filled in a `FormBuilderDateTimePicker` (date-only picker, not a free-text field), an optional yellow warning banner if `extractionConfidence == 'low'` ("Verifica que la fecha sea correcta"), and a "Confirmar" `AppButton`.
6. If the extracted date is wrong, the rider edits the date picker value and taps "Confirmar" — the corrected date is sent via `ConfirmInsuranceDateUseCase`.
7. On extraction failure (422 response with `extractionError: true`), the UI transitions directly to a manual entry form with the message "No pudimos extraer la fecha. Ingrésala manualmente." and a `FormBuilderDateTimePicker` for the rider to enter the date.
8. After confirming or manually entering the date, the rider is navigated back to the vehicle detail page automatically, and the vehicle detail shows the saved expiration date and status.
9. Garage vehicle cards show a status badge: green chip "Vigente" when `status == valid`, yellow chip "Por vencer" when `status == expiringSoon`, red chip "Vencido" when `status == expired`. Vehicles with no uploaded document show no badge.
10. Badge computation uses the `computeStatus(DateTime)` pure function from Iteration 3a.
11. Re-uploading a SOAT for the same vehicle replaces the existing document (no duplicate badge; single entry in garage card).
12. Widget tests cover all 6 UI states: (a) file picker idle state with "Subir SOAT" button, (b) upload progress state with progress indicator and "Subiendo documento..." text, (c) AI extraction loading state with "Extrayendo fecha con IA..." text, (d) confirmation form with pre-filled date and "Confirmar" button, (e) `extractionConfidence == 'low'` warning banner visible on confirmation form, (f) manual entry fallback form with "No pudimos extraer la fecha" message.
13. Widget test for garage vehicle card: renders status badge correctly for `valid`, `expiringSoon`, `expired`, and no-document states.
14. Integration test: full happy-path flow (file pick → upload → extraction → confirmation → badge visible in garage) against dev backend.
15. All new Spanish strings in `app_es.arb` with `soat_` prefix (extending the keys from Iteration 3a).
16. All touch targets ≥ 44×44px. All new widgets follow dark-mode design (orange primary, `AppColors` for borders, `Theme.of(context).colorScheme` for semantic colors).
17. Pencil design for the SOAT flow is consulted before implementation begins — the widget layout matches the Pencil spec.
18. `dart analyze` passes with zero violations.
19. `flutter test` passes with 100% green tests.

### Technical Notes

- **Pencil gate:** Hard prerequisite — do not begin widget implementation until `pencil-new.pen` contains SOAT upload flow screens.
- **Upload progress:** Firebase Storage `UploadTask` exposes a `snapshotEvents` stream. Use it to drive an indeterminate indicator (the file size is typically small, so percentage precision is not critical — an indeterminate `LinearProgressIndicator` is sufficient).
- **Date picker:** Use `FormBuilderDateTimePicker` from `flutter_form_builder` with `inputType: InputType.date`. Do not use a free-text field for dates — this prevents invalid date entry.
- **Status badge widget:** Create a reusable `InsuranceStatusBadge` widget in `lib/features/vehicles/presentation/widgets/`. It takes an `InsuranceDocumentStatus?` — when null, renders nothing.
- **State machine:** `InsuranceDocumentCubit` state fields drive the UI. The page uses a single `BlocBuilder` with a `switch` on `state.status` to render the correct step. No separate pages needed — this is a single-page multi-step flow.
- **ARB keys to add:** `soat_uploadTitle`, `soat_sectionTitle`, `soat_uploadingDocument`, `soat_extractingDate`, `soat_confirmTitle`, `soat_lowConfidenceWarning`, `soat_manualEntryTitle`, `soat_manualEntryMessage`, `soat_confirmButton`, `soat_statusValid`, `soat_statusExpiringSoon`, `soat_statusExpired`.

### Agents

design (Pencil gate review), frontend, qa

### Estimated Complexity

M

### Dependencies

Iteration 3a, Track P (Pencil design — SOAT screens must be complete)

---

## Iteration 4 — AI Event Cover Image Generation

### Goal

Wire the existing "Generar portada con IA" button in the event creation form to a backend endpoint that uses Claude Haiku to generate a search query and Unsplash to return a relevant cover image, so organizers can publish visually rich events without manual design work.

### Why Now

The UI entry point (the button) already exists in `EventFormPage`. The Claude API integration pattern from Iteration 3a is reused here. Placing cover generation before recommendations allows the AI backend infrastructure to be validated end-to-end before adding a second AI endpoint.

### User Stories

- **HU-AI-01a** · AI cover generation · As an event organizer filling out the event creation form, I tap "Generar portada con IA" and see a loading overlay while the app fetches a cover image based on the event title, type, and city so my event has an attractive visual without manual design work.
- **HU-AI-01b** · Cover preview and replace · As an organizer, after the cover is generated, I see a preview in the form at the correct aspect ratio and can regenerate, accept it, or upload my own image so I stay in control of the event's visual presentation.

### Acceptance Criteria

1. **Backend — `POST /events/generate-cover`:** Accepts `{ title: string, eventType: string, city: string }`. Uses the existing `ClaudeService` (from Iteration 3a) to generate a 3-5 word English search query (e.g., "mountain motorcycle off-road colombia"). Calls Unsplash API (free developer tier) with the query. Returns 200 with `{ imageUrl: string, source: "unsplash", query: string }` or 503 with `{ message: "No pudimos generar la portada en este momento. Sube tu propia imagen." }`.
2. **Backend — timeout:** The backend sets a 15-second timeout on the Unsplash API call. If exceeded, returns 503.
3. **Backend — Unsplash API key:** Stored as an environment variable (`UNSPLASH_ACCESS_KEY`) in `.env.example` (placeholder) and in the CI/deployment secrets; never committed.
4. **Flutter — `EventFormCubit` state refactor:** The cubit state becomes a `@freezed` `EventFormState` class. It adds a `ResultState<String> coverGenerationResult` field (the `String` is the cover image URL). Existing form fields are preserved.
5. **Flutter — `EventFormCubit.generateCover({required String title, required String eventType, required String city})`** method emits `coverGenerationResult = loading()`, then `data(data: imageUrl)` on success, or `error(error: ...)` on failure.
6. **Flutter — form wiring:** The "Generar portada con IA" button calls `context.read<EventFormCubit>().generateCover(...)`. While `coverGenerationResult` is `loading`, a shimmer/opacity overlay renders on the current preview area (not a blank state — the overlay replaces the current preview content while loading).
7. **Flutter — cover preview:** The image preview container has a fixed 16:9 aspect ratio (matching event list card ratio). Uses `CachedNetworkImage` with `BoxFit.cover`. Renders correctly for both portrait and landscape source images.
8. **Flutter — regenerate:** Tapping "Regenerar" while a preview is shown replaces the preview with a loading overlay (the existing image remains visible beneath the overlay until the new image loads, or use a shimmer pulse). Does not blank the preview.
9. **Flutter — replace with own photo:** Tapping "Subir propia imagen" (existing gallery picker path) after AI generation correctly replaces the AI URL in `EventFormState` with the picked image URL. The two sources do not conflict.
10. **Flutter — non-blocking submit:** The "Publicar" button is never disabled due to in-progress generation. The form can be submitted at any point without a cover image.
11. **Flutter — error handling:** Generation failure shows a Spanish error SnackBar ("No pudimos generar la portada. Sube tu propia imagen.") and returns the form to the idle state (button re-enabled).
12. **Existing `EventFormCubit` widget tests** (if any from Iteration 1) are updated to reflect the new `EventFormState` structure.
13. Unit test: `generateCover` use case — happy path (returns URL) + error path (503 → `DomainException`).
14. Widget tests for form button states: idle (button enabled), loading (overlay on preview, button shows spinner), preview shown (image visible, regenerate button enabled), error (snackbar shown, button re-enabled).
15. Widget test: regenerate while preview visible — loading overlay appears over existing image, not a blank state.
16. Widget test: "Publicar" button remains enabled while `coverGenerationResult` is `loading`.
17. New ARB keys with prefix `event_` (e.g., `event_generateCoverButton`, `event_coverGenerating`, `event_coverRegenerate`, `event_coverReplaceOwn`, `event_coverGenerationError`).
18. `dart run build_runner build --delete-conflicting-outputs` runs cleanly after `EventFormState` refactor.
19. `dart analyze` passes with zero violations.
20. `flutter test` passes with 100% green tests.

### Technical Notes

- **ADR-4 resolved:** Unsplash API (Option A) is the choice for v1. Claude Haiku generates the search query; Unsplash returns the photo. The Unsplash URL is used directly as the event `imageUrl` — no re-upload to Firebase Storage during the preview step. The URL is saved to the event record on `POST /events` submission.
- **Claude search query prompt:** "Given this motorcycle event — title: {title}, type: {eventType}, city: {city} — generate a 3-5 word English phrase to search for a relevant background photo on Unsplash. Return only the phrase, nothing else."
- **Unsplash API:** Use the `GET /search/photos?query={query}&per_page=1&orientation=landscape` endpoint. Return `results[0].urls.regular`.
- **`EventFormState` freezed class:** Add the `part` directive and run `dart run build_runner build`. No new packages needed.
- **Aspect ratio:** Use `AspectRatio(aspectRatio: 16/9, child: ...)` in the cover image preview widget.

### Agents

backend, frontend, qa

### Estimated Complexity

M

### Dependencies

Iteration 3a (Claude API integration pattern in rideglory-api is established and reused)

---

## Iteration 5 — AI Event Recommendations

### Goal

Populate the existing recommendations section on the home dashboard with personalized event suggestions from a new backend scoring endpoint, so riders discover relevant rides without manual browsing.

### Why Now

The UI card exists on the dashboard and is already rendering (but with no data). The backend scoring algorithm is self-contained with no external AI dependency. Placing it after Iteration 4 validates the AI backend pattern end-to-end. Recommendations enrich the user data available before push notification implementation (Iteration 6a).

### User Stories

- **HU-AI-02a** · Personalized recommendations · As a rider opening the app, I see up to 5 recommended upcoming events in the home dashboard's recommendations section, ranked by how well they match my main vehicle type, past registrations, and city so I find rides I'll actually enjoy.
- **HU-AI-02b** · New rider fallback · As a new rider with no registration history, I see the 5 soonest upcoming events in the recommendations section labeled "Próximos eventos" so the dashboard is never empty.

### Acceptance Criteria

1. **Backend — `GET /events/recommendations`:** Authenticated endpoint in `api-gateway`. Fetches the caller's main vehicle type (from vehicles-ms), registration history (last 10 events from events-ms), and upcoming events (from events-ms). Scores each upcoming event: vehicle type match +40 pts, past registration in same event type +40 pts, city match +20 pts. Returns the top 5 scored events. If `residenceCity` is null, the proximity score defaults to 0 (no 500 error). If fewer than 5 scoreable events exist, pads with the next upcoming events by `startDate`.
2. **Backend — fallback flag:** Response shape: `{ recommendations: EventDto[], fallback: boolean }`. `fallback: true` when no personalization data is available (new rider).
3. **Backend unit tests:** Scoring with full data (matched vehicle type, matched history, matched city), new rider fallback (no vehicle, no history), null `residenceCity` case (no 500), fewer than 5 upcoming events case.
4. **Flutter — `RecommendationsCubit`** (new, `@lazySingleton`) in `lib/features/home/presentation/cubit/`. State: `Cubit<RecommendationsState>` where `RecommendationsState` is `@freezed` with `ResultState<List<EventModel>> recommendationsResult` and `bool isFallback` fields.
5. **Flutter — `RecommendationsCubit.load()`** method: (a) if valid cache exists in `SharedPreferences` (< 6 hours old), immediately emit `data(data: cachedEvents)` and then fetch in background; (b) if cache is empty or expired, emit `loading()`, then fetch, emit `data(data: freshEvents)` and update cache; (c) always update cache after a successful network response.
6. **Flutter — stale-while-revalidate:** When cache is expired, emit stale `data()` immediately (not `empty()` or `loading()`), then update with fresh `data()` after the network response. The recommendations card never shows a skeleton when stale data is available.
7. **Flutter — first open (no cache):** `RecommendationsCubit` emits `loading()` (not `empty()`) when cache is absent. The dashboard shows a shimmer skeleton, not a blank card.
8. **Flutter — `RecommendationsCacheService`** (`@singleton`) in `lib/features/home/data/service/` wraps `SharedPreferences` with `recommendations_cache` and `recommendations_cache_expiry` keys. Registered in `injection.dart`.
9. **Flutter — fallback label:** If `isFallback == true`, the recommendations section header reads "Próximos eventos" (from ARB). Otherwise it reads "Recomendados para ti".
10. **Flutter — navigation:** Tapping a recommendation card navigates to `event_detail` via `context.pushNamed('event_detail', extra: event)` — same as event list items.
11. **Flutter — no `HomeCubit` changes:** `HomeCubit`, `HomeService`, and `HomeDto` must not be modified. `RecommendationsCubit` is independent.
12. **Flutter — lazy initialization:** `RecommendationsCubit` is added to the root `MultiBlocProvider` but must not fire a network request until `HomePage` mounts (use lazy initialization or call `load()` in the page's `initState`/`BlocProvider.create`).
13. Unit tests: `RecommendationsCubit` emits cached `data()` from `SharedPreferences` before making a network call. Cache is updated after a successful network response. `loading()` emitted when cache is absent (not `empty()`). `RecommendationsCacheService` reads and writes correctly with the expiry key.
14. Widget test: recommendations section renders shimmer when `recommendationsResult` is `loading`. Renders up to 5 event cards when `data`. Renders error banner when `error`. Header reads "Próximos eventos" when `isFallback == true`, "Recomendados para ti" when false.
15. `GetRecommendationsUseCase` in `lib/features/home/domain/` calls the recommendations endpoint via a new `RecommendationsService` (Retrofit) and returns `Either<DomainException, RecommendationsResult>`.
16. New ARB keys: `home_recommendationsTitle`, `home_recommendationsFallbackTitle`, `home_recommendationsError`, `home_recommendationsEmpty`.
17. `dart run build_runner build --delete-conflicting-outputs` runs cleanly (`RecommendationsState` freezed + `RecommendationsService` retrofit).
18. `dart analyze` passes with zero violations.
19. `flutter test` passes with 100% green tests.

### Technical Notes

- **`RecommendationsState` freezed:** Add `part 'recommendations_state.freezed.dart'` and run build_runner.
- **Cache expiry:** Store `DateTime.now().millisecondsSinceEpoch` as the `recommendations_cache_expiry` value. On load, compare to `DateTime.now().millisecondsSinceEpoch - (6 * 3600 * 1000)`.
- **Scoring algorithm location:** Implemented entirely in `api-gateway` (not events-ms) because it aggregates data from multiple microservices. No new microservice needed.
- **`EventDto` reuse:** The recommendations endpoint returns the same `EventDto` shape — no new DTO.

### Agents

backend, frontend, qa

### Estimated Complexity

M

### Dependencies

Iteration 2 (events data patterns stable), Iteration 4 (AI backend pattern validated)

---

## Iteration 6a — Push Notifications (FCM)

### Goal

Integrate Firebase Cloud Messaging to deliver push notifications for all 5 registration and event-status triggers, with correct deep-link routing for all 3 app states (foreground, background, terminated).

### Why Now

This is the highest-integration-risk iteration. `firebase_messaging` is a new package requiring native platform setup on both Android and iOS. Placing it after all feature iterations are stable ensures that every deep-link target screen exists and is tested. The `NotificationNavigator` deep-link architecture is the primary technical risk and must be implemented carefully.

### User Stories

- **HU-PUSH-01a** · Registration status notifications · As a rider, I receive a push notification when my event registration is approved or rejected, and tapping it takes me directly to the registration detail screen so I don't have to hunt for the update.
- **HU-PUSH-01b** · Organizer new request notification · As an event organizer, I receive a push notification when a new rider requests to join my event so I can approve or reject quickly.
- **HU-PUSH-01c** · Event status notifications · As an approved attendee, I receive a push notification when my event changes to "en curso" (with a link to the live tracking map) or is cancelled, so I always know what's happening.
- **HU-PUSH-01d** · FCM permission prompt · As a rider on iOS, I am prompted to allow notifications after I submit my first event registration so the permission request is contextually meaningful.

### Acceptance Criteria

1. `firebase_messaging: ^15.0.0` added to `dependencies` in `pubspec.yaml`.
2. Android: `AndroidManifest.xml` updated with `RECEIVE_BOOT_COMPLETED` permission and `FirebaseMessagingService` service declaration.
3. iOS: Push notification capability enabled in Xcode; background mode `remote-notification` added to `Info.plist`. APNs Auth Key (p8) uploaded to Firebase Console (operational step — documented in `docs/devops/fcm-setup.md`, not testable by `flutter test`).
4. `FirebaseMessaging.instance.getToken()` is called after successful login. The token and platform (`android` | `ios`) are sent to `POST /users/device-token` via a new `RegisterDeviceTokenUseCase`.
5. `FirebaseMessaging.instance.onTokenRefresh` listener is registered at app startup (in `main()`, not only on login) and re-calls `RegisterDeviceTokenUseCase` when the token rotates.
6. iOS: `requestPermission()` is called after the rider's first successful event registration submission (triggered from `RegistrationFormCubit` on success state), not at app launch. A contextual message is shown before the prompt: `soat_notifPermissionContext` ARB key ("Activa las notificaciones para saber cuándo sea aprobada tu inscripción.").
7. **Foreground notifications:** `FirebaseMessaging.onMessage` handler shows an in-app `SnackBar` with the notification title and body. Does NOT show a system notification banner. Tapping the SnackBar action navigates to the correct screen.
8. **Background notifications:** `FirebaseMessaging.onMessageOpenedApp` handler navigates to the correct screen via `NotificationNavigator` when the user taps the system notification.
9. **Terminated app notifications:** `FirebaseMessaging.getInitialMessage()` is called in `main()`. The result is stored in a `ValueNotifier<RemoteMessage?>`. The root widget observes this `ValueNotifier` and navigates after first mount (not before the widget tree is built).
10. **`NotificationNavigator` service:** Reads `data.route` and `data.registrationId` / `data.eventId` from the FCM payload. Calls the appropriate use case to fetch the full model by ID. Navigates using `context.pushNamed(route, extra: fetchedModel)`. Handles 404 gracefully: shows an error `SnackBar` ("Este contenido ya no está disponible.") and does not crash.
11. **New "by-id" routes:** `RegistrationDetailByIdPage` (`/events/registration-detail-by-id?id=:registrationId`), `LiveMapByIdPage` (`/events/live-map-by-id?eventId=:eventId`), `AttendeesPage` updated to accept `eventId` query param. All fetch the full model before rendering.
12. **FCM payload schema:** All FCM dispatch includes `data: { route: string, registrationId?: string, eventId?: string }` alongside `notification: { title, body }`.
13. **Backend — `POST /users/device-token`:** Upserts `DeviceToken` in users-ms (unique by token; reassigns to current user if token was registered under a different user). Returns `{ success: true }`.
14. **Backend — `NotificationsModule`:** Uses Firebase Admin SDK (`firebase-admin` npm package) to send FCM. `FcmService` has methods: `sendToUser(userId, notification, data)`, `sendToUsers(userIds[], notification, data)`.
15. **Backend — FCM triggers:** Registration approved → FCM to rider. Registration rejected → FCM to rider. New registration (pending) → FCM to organizer. Event status → `IN_PROGRESS` → FCM to all approved registrants. Event status → `CANCELLED` → FCM to all registrants (any status).
16. **Backend — `DeviceToken` Prisma schema:** `id` (uuid), `userId` (FK → User, cascade delete), `token` (String, unique), `platform` (enum: `ANDROID | IOS`), `createdAt`, `updatedAt`. `npx prisma migrate dev` applied.
17. Unit test: `RegisterDeviceTokenUseCase` happy path + error path (backend 500).
18. Widget test: foreground notification shows SnackBar with correct title and body.
19. Widget test: `RegistrationDetailByIdPage` renders error state when registration not found (404).
20. New ARB keys: `push_registrationApproved`, `push_registrationRejected`, `push_newRegistrationRequest`, `push_eventInProgress`, `push_eventCancelled`, `push_notifPermissionContext`, `push_contentUnavailable`.
21. `dart run build_runner build --delete-conflicting-outputs` runs cleanly.
22. `dart analyze` passes with zero violations.
23. `flutter test` passes with 100% green tests.

### Technical Notes

- **Terminated-app race condition:** `getInitialMessage()` returns before the widget tree mounts. Use a `GlobalKey<NavigatorState>` or `ValueNotifier<RemoteMessage?>` pattern: store the message in the notifier, observe it in the root widget's `initState`, and navigate after the first frame (`WidgetsBinding.instance.addPostFrameCallback`).
- **`RegisterDeviceTokenDto`:** `@JsonSerializable()` class with `token: String`, `platform: String`. Add to `lib/features/users/data/dto/`.
- **Token refresh registration:** Register `FirebaseMessaging.instance.onTokenRefresh.listen(...)` in `main()` before `runApp()` (or in `AuthCubit`'s authenticated state observer).
- **APNs setup documentation:** Create `docs/devops/fcm-setup.md` listing the operational steps for APNs key, Firebase Console configuration, and Xcode capabilities. This is referenced by the DevOps track CI checklist.

### Agents

backend, frontend, qa

### Estimated Complexity

L

### Dependencies

Iteration 5 (all feature iterations done and stable)

---

## Iteration 6b — SOS Real-Time Alert

### Goal

Add SOS emergency broadcast to the live tracking session: any rider can trigger an SOS that immediately appears as a persistent red banner overlay on all other riders' maps in the same event session, without interrupting map interactivity.

### Why Now

SOS extends the existing `TrackingWsClient` and `LiveTrackingCubit` with new message types. With FCM in place (Iteration 6a) and the live tracking feature fully stable and tested, the SOS overlay can be added with minimal blast radius.

### User Stories

- **HU-SOS-01a** · SOS trigger · As a rider on the live tracking map, I tap the SOS button (already present in the UI) and all other riders in the same session immediately see a persistent red alert banner with my name and position on their maps so help can be coordinated.
- **HU-SOS-01b** · SOS cancel · As the rider who triggered SOS, I tap "Cancelar SOS" on the overlay and the alert disappears from all riders' maps so the emergency signal is cleared when no longer needed.
- **HU-SOS-01c** · Multiple simultaneous SOS · As a rider on the map, I can see up to all active SOS alerts stacked as separate banners so I know about every ongoing emergency in the session.

### Acceptance Criteria

1. **SOS WebSocket message types:** `TrackingWsClient._onMessage()` handles `type == 'tracking.sos'` (parse into `SosAlertModel`, emit on `sosStream`) and `type == 'tracking.sos_cancel'` (emit cancellation with `riderId` on `sosCancelStream`).
2. **`SosAlertModel`** is a pure Dart immutable class (or `@freezed`) in `lib/features/events/domain/models/` with fields: `riderId` (String), `riderName` (String), `latitude` (double), `longitude` (double), `eventId` (String).
3. **`TrackingWsClient.sendSos({required String eventId, required String riderId, required String riderName, required double lat, required double lng})`** sends `{ type: "tracking.sos", data: { eventId, riderId, riderName, latitude, longitude } }`.
4. **`TrackingWsClient.cancelSos({required String eventId, required String riderId})`** sends `{ type: "tracking.sos_cancel", data: { eventId, riderId } }`.
5. **`LiveTrackingState`** gains an `activeSosAlerts: List<SosAlertModel>` field (not a nullable single field — supports multiple simultaneous alerts). Build_runner regenerates the freezed class.
6. **`LiveTrackingCubit`** subscribes to `TrackingWsClient.sosStream` in `start()`. On SOS received: `emit(state.copyWith(activeSosAlerts: [...state.activeSosAlerts, newAlert]))`. On SOS cancel (matching `riderId`): remove from the list. `sendSos()` and `cancelSos()` methods proxy to `TrackingWsClient`.
7. **`SosButton.onPressed`** (existing widget, currently `() {}`) is wired to `context.read<LiveTrackingCubit>().sendSos(...)`. Button must be ≥ 44×44px touch target (confirm existing widget meets this requirement; fix if not).
8. **`SosOverlay` widget:** `BlocBuilder` listening to `LiveTrackingCubit.state.activeSosAlerts`. When the list is non-empty, renders a **top-anchor column** of red banner widgets (one per active SOS). Each banner shows: red background (`Colors.red`), white text with the rider's name ("¡SOS! {riderName}"), and a map location pin icon. The overlay does NOT cover the full screen — it sits at the top of the `Stack` inside `LiveMapPage`, allowing the map to remain interactive (pan, zoom, tap rider pins all work).
9. **Rider who triggered SOS** sees their own banner plus a "Cancelar SOS" `AppButton` in the banner. Other riders see the banner without the cancel button. Role check: compare `SosAlertModel.riderId` to `AuthCubit.state.currentUser.id`.
10. **SOS overlay persists** across navigation away-and-back: `LiveTrackingCubit` is a global singleton; its `activeSosAlerts` list survives screen transitions.
11. **Organizer dismiss:** Out of scope for v1. Only the rider who triggered SOS can cancel it. The PRD organizer-dismiss requirement is explicitly deferred to a future iteration. This is documented in the acceptance criteria to set expectations.
12. **Backend — `TrackingGateway`:** Handles `tracking.sos` and `tracking.sos_cancel` client messages. Validates that `data.riderId` matches the authenticated `clientMeta.uid` before broadcasting. Broadcasts the message to all clients in the same `eventId` room (same `this.broadcast(meta.eventId, ...)` pattern as `handleLocationUpdate`).
13. **Accessibility:** SOS banner uses white text on red background (`Colors.red` with white text) for sufficient contrast. The rider's name is the primary information carrier — color is a secondary signal, not the only one.
14. Unit test: `SosAlertModel` parsing from WebSocket JSON. `LiveTrackingCubit` `blocTest`: emits updated `activeSosAlerts` list when SOS received; removes alert when SOS cancel received for matching `riderId`.
15. Widget test: `SosOverlay` renders one banner per active SOS alert. "Cancelar SOS" button visible only when `riderId` matches current user. Map area remains interactive when overlay is present.
16. Integration test: full SOS flow against dev backend — rider A sends SOS → rider B's cubit emits the alert → overlay visible → rider A cancels → overlay clears.
17. New ARB keys: `sos_alertTitle`, `sos_cancelButton`, `sos_bannerMessage`.
18. `dart run build_runner build --delete-conflicting-outputs` runs cleanly after `LiveTrackingState` and `SosAlertModel` changes.
19. `dart analyze` passes with zero violations.
20. `flutter test` passes with 100% green tests.

### Technical Notes

- **Multiple SOS alerts:** `activeSosAlerts: List<SosAlertModel>` (ordered by arrival time — no priority sorting in v1). Stacked banners scrollable if more than 3 are active (unlikely in practice but handled gracefully).
- **`LiveTrackingState` freezed regeneration:** Adding `List<SosAlertModel>` to the freezed class requires adding `SosAlertModel` as a recognized type. If `SosAlertModel` is also freezed, both classes must be in separate build passes or the same build pass (build_runner handles this automatically in a single `dart run build_runner build` call).
- **Backend broadcast security:** The riderId in the SOS payload is validated against the authenticated WebSocket connection's `uid` before any broadcast. This prevents a malicious client from spoofing another rider's SOS.
- **SOS button existing widget:** `SosButton` is in `live_map_page.dart`. Confirm its current dimensions before wiring — if < 44×44px, increase the `minSize` or wrap in a `SizedBox`.

### Agents

backend, frontend, qa

### Estimated Complexity

M

### Dependencies

Iteration 6a (FCM in place; live tracking is fully stable and tested)

---

## Assumptions

1. The `GET /users/me` backend endpoint returns at minimum `fullName`, `email`, and the user's ID. If `profilePhotoUrl` is added to the Prisma `User` model in a future iteration, the profile page will automatically display it without Flutter-side changes.
2. The Unsplash free developer tier allows up to 50 requests/hour per API key, which is sufficient for pilot usage. If usage exceeds limits, Unsplash returns 429 — the backend 503 fallback handles this gracefully.
3. The existing `go_router` v17 `AppRoutes` and `extra`-based navigation can be extended with "by-id" route variants without a full router rewrite.
4. `TrackingWsClient` auto-reconnect logic continues to work unchanged after SOS message type additions — no reconnect state is tied to SOS.
5. The Apple Developer account for Rideglory has push notifications enabled for the app bundle ID. APNs key (p8 file) is available before Iteration 6a begins.
6. The `ClaudeService` in `rideglory-api` (created in Iteration 3a) uses the Anthropic SDK for Node.js and is reused in Iteration 4 without modification.
7. Stitch reference images at `/Users/cami/Downloads/stitch_rideglory/` are available on the development machine during Track P. They must be copied to `docs/design/stitch-references/` before Track P begins so they are version-controlled.
8. The rider base in the pilot phase is small enough that Claude Haiku per-request costs for SOAT extraction are acceptable without rate limiting.

---

## Risks

1. **Event filter backend gap (Iteration 2 blocker):** Confirmed — `GET /events` does not pass filter params today. Backend changes are in scope for Iteration 2 and must be completed before filter UI is wired.
2. **go_router `extra` non-serializability from FCM payloads (Iteration 6a):** Current navigation uses in-memory Dart objects as `extra`. FCM terminated-app payloads are JSON-only. The `NotificationNavigator` + "by-id" route pattern mitigates this, but it requires creating new page variants and a fetch-before-render pattern in Iteration 6a.
3. **Claude Haiku PDF extraction reliability (Iteration 3a):** Extraction accuracy varies with PDF quality. Mitigated by: always showing a confirmation step (no auto-save), returning `extractionConfidence: "low"` with a warning banner, and providing a manual entry fallback for all extraction failures.
4. **FCM on iOS APNs configuration (Iteration 6a):** Push notifications on iOS physical devices require APNs key + Xcode capability setup. If the APNs key is not available before Iteration 6a, iOS FCM will fail silently. This must be confirmed as a pre-sprint operational check.
5. **Firebase Storage PDF access from backend (Iteration 3a):** PDFs are private by default. The backend uses Firebase Admin SDK path-based access (ADR-3 Option B). If the Admin SDK service account lacks Storage read permissions, extraction will fail with a 403. Storage IAM permissions must be confirmed before Iteration 3a backend work begins.
6. **`EventFormCubit` state refactor cross-iteration regression (Iteration 4):** Adding `coverGenerationResult` to `EventFormCubit` state requires a `@freezed` class conversion. Any existing `EventFormCubit` tests from earlier iterations must be updated.
7. **Pencil single-machine dependency (Track P):** Stitch reference images are on one machine. If design work moves to another machine, the images are unavailable. Mitigated by copying them to `docs/design/stitch-references/` before Track P begins.

---

## Deferred / Out of Scope

| Item | Reason |
|------|--------|
| **SOAT push reminders (30-day / 7-day)** | PRD marks as "future." Requires FCM infrastructure from Iteration 6a. Scheduled after Iteration 6b. |
| **Profile photo upload** | `User.profilePhotoUrl` not in current Prisma schema. Phase 1 profile shows initials avatar. Deferred to post-6b. |
| **Organizer SOS dismiss** | The PRD mention of "organizer can dismiss" is deferred to v2. Only the SOS sender can cancel in v1 (simplest mechanic; organizer can coordinate verbally in pilot phase). |
| **AI event recommendations — Claude narrative explanations (v2)** | PRD flags as "optional v2." Deterministic scoring is sufficient for launch. |
| **Authentication Clean Architecture refactor** | Auth works via `AuthService`. Refactoring to full domain/data/presentation layers adds risk with no user-visible value. |
| **Mandatory documents beyond SOAT (tecno, other)** | DTO and backend schema are extensible, but only SOAT is implemented in v1. |
| **Web version, admin dashboard, payments, social feed** | Explicitly out of scope per PRD section 10. |
| **Multi-language support (English)** | ARB is Spanish-only. No English translation planned. |
| **CI/CD IPA build + App Store submission** | DevOps track delivers APK build only. IPA build and signing are deferred until a distribution target is confirmed. |
