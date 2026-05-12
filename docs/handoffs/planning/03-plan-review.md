# Plan Review — Rideglory Iteration Plan

> **Author:** Plan Reviewer agent (UX complexity + quality gates / tech lead)
> **Generated:** 2026-05-12
> **Input:** `docs/PRD.md` v1.0, `docs/handoffs/planning/00-existing-system-scan.md`, `docs/handoffs/planning/01-po-proposal.md`, `docs/handoffs/planning/02-architect-review.md`
> **Status:** Draft — awaiting PO final decision and plan merge

---

## 1. Executive Review Summary

- **Overall plan health is GOOD with two critical adjustments required.** The ordering is sound (tests first, profile second, AI features in the middle, notifications last), the PO's rationale for sequencing is defensible, and the Architect's technical review is thorough. No fundamental rethinking is needed. Two targeted changes are required: (1) split Iteration 3 (SOAT) into 3a/3b and (2) split Iteration 6 (FCM + SOS) into 6a/6b. Without these splits, both iterations carry a level of UX and integration complexity that makes single-sprint delivery unrealistic and regression-prone.

- **Iteration 6 is the highest-risk item in the entire plan.** It simultaneously introduces a new package (`firebase_messaging`), native platform configuration on two OSes, a new WebSocket message type, a deep-link routing architecture change, a new `NotificationNavigator` service, and a real-time UI overlay. The Architect already flagged it as XL. This review confirms it must be split (see Section 3).

- **SOAT (Iteration 3) has an underestimated UX surface.** The multi-step flow (file pick → upload progress → AI loading → confirmation or fallback → status indicator) contains at least 6 distinct UI states. These are not all captured in the current acceptance criteria. The iteration is at risk of shipping without empty/error states on the upload form, which would be a regression given the quality standards in the PRD.

- **Quality gate coverage is uneven.** Iterations 4 and 5 have lean test requirements relative to the complexity of the new cubits they introduce. The acceptance criteria for widget tests on `EventFormCubit` state changes (loading → preview → error) need to be more explicit. Iteration 5's caching path is unverified by any specified test.

- **Three open UX gaps require PO decisions before coding begins on Iterations 3, 5, and 6.** These are not blockers for Iterations 1 and 2, but they must be resolved before their respective iteration planning sessions.

---

## 2. Per-Iteration Review

---

### Iteration 1 — Test Infrastructure + Profile Feature Completion

#### UX Complexity Review

**Feasibility:** Yes — this is achievable in a single iteration. Profile is a read-only data-display page with no complex interactions.

**Hidden UX risks:**

- **Profile empty states are not specified.** The acceptance criteria say the page shows "name, photo, and main vehicle." But: what renders if the rider has no vehicles yet (the cubit emits `Empty`)? What if the profile photo URL is null (no photo uploaded)? The garage page already handles the empty-vehicle state via `EmptyStateWidget` — the profile page must do the same.
- **Profile photo placeholder.** The system scan confirms that `User.profilePhotoUrl` does not exist in the Prisma schema today (ADR-2 in the Architect review). The PO and Architect recommend showing no photo in Phase 1. This is acceptable — but the profile page must render a visible placeholder avatar (initials or a generic icon) instead of a broken image widget, and this must be in the acceptance criteria, not assumed.
- **Loading state.** `ProfileCubit` will emit `ResultState.loading()` during the `GetMyProfileUseCase` call. The page must show a shimmer skeleton (consistent with other pages). This is not mentioned in the current acceptance criteria.

**Missing acceptance criteria:**
- Profile page renders a shimmer skeleton while `ProfileCubit` is in `loading` state.
- Profile page shows a `EmptyStateWidget` or placeholder avatar when `profilePhotoUrl` is null.
- Profile page shows an error banner with a retry button when `ProfileCubit` emits `error`.
- If `VehicleCubit` is in `empty` state, profile page shows "Sin vehículos" placeholder in the vehicle slot.

#### Quality Gate Review

- **20 test case minimum is insufficiently specified.** The acceptance criterion says "at least 20 test cases across unit and widget layers." This is a count, not a structure. A developer could write 20 trivial assertions to pass. Recommend replacing with structural coverage requirements: one `blocTest` group per cubit (5 state transitions each), one widget test class per page (4 states each).
- **Integration test stubs are correct.** Creating empty `group` blocks in `integration_test/` is the right first step — ensures the test infrastructure runs without failures on CI even before real integration tests are written.
- **DI wiring for `ProfileCubit`.** `ProfileCubit` must be registered in `injection.dart` and added to the root `MultiBlocProvider` in `main.dart` (alongside `AuthCubit` and `VehicleCubit`). If it is forgotten, the profile page will throw a `StateError` at runtime. This is an easy miss with no test that catches it directly — add a note in the acceptance criteria.
- **`dart analyze` must pass after build_runner.** The profile cubit state (if it becomes a `@freezed` class) requires a build_runner pass. The acceptance criteria must explicitly include: "run `dart run build_runner build` and confirm zero new analysis warnings."

**Risk level: LOW** — straightforward iteration. The primary risks are missing empty/error states on the profile page and underspecified test coverage structure.

---

### Iteration 2 — Event Discovery Filters + Attendee Profile Links

#### UX Complexity Review

**Feasibility:** Yes — both stories are completions of existing UI, not greenfield screens.

**Hidden UX risks:**

- **Filter bottom sheet UX — date range picker.** The filter includes `dateFrom` and `dateTo`. Flutter's `DateRangePickerDialog` (or `showDateRangePicker`) is a Material widget. If the app's design system does not yet have a custom date picker molecule, this will render a default Material dialog that breaks dark-mode consistency (`ThemeData` must be configured correctly or it shows a white calendar on a dark page). This is a known "linting time bomb" for design system coherence. Recommendation: confirm whether the codebase has a custom date picker or wraps `showDateRangePicker` with the app's theme before implementing.
- **Active filter badge visibility.** The PO proposal says "active filters are visually indicated (badge or chip)." On a dark background with the orange primary, the distinction between "no filters" and "1 filter active" must be obvious. Recommend specifying the badge component explicitly: use a `Badge` widget with count on the filter icon, consistent with the `AppColors.primary` orange.
- **Filtered empty state.** The acceptance criteria mention a widget test for "No hay eventos con estos filtros" — good. But the empty state must be differentiated from the "No hay eventos" state (no events at all). These are two different messages and two different CTAs (clear filters vs. check back later).
- **Attendee profile — back navigation.** When a rider taps a profile from the attendee list and then goes back, they should return to the attendee list, not the event detail. The `context.pushNamed()` convention handles this correctly, but the route must be wired as a push, not a go. Confirm in the acceptance criteria that `RiderProfilePage` is reached via `pushNamed`.
- **Rider profile read-only scope.** The new `RiderProfilePage` (for other riders, reached from the attendee list) must be clearly scoped as read-only: no edit button, no "Set as main vehicle" affordance. This is obvious to the implementer but must be in the acceptance criteria to prevent any widget reuse confusion with `ProfilePage` (own profile).

**Backend gap (Architect Risk 1):** The Architect confirmed that the `GET /events` endpoint does NOT pass filter params to events-ms today. This is a **Iteration 2 blocker** — the filter UI cannot be wired without backend changes. The acceptance criteria must explicitly include: "Backend: `GET /events` gateway forwards `type`, `dateFrom`, `dateTo`, and `city` query params to events-ms `findAllEvents` handler."

**Missing acceptance criteria:**
- Filtered empty state message is distinct from the all-events empty state.
- Date range picker matches app dark theme (no white Material calendar flash).
- `RiderProfilePage` is push-navigated (not `goNamed`) to preserve back button.
- `RiderProfilePage` has no edit controls — read-only.

#### Quality Gate Review

- **`EventsCubit` filter state refactor carries Clean Architecture risk.** The Architect correctly notes that adding `activeFilters` to the cubit state requires converting `Cubit<ResultState<List<EventModel>>>` to a `@freezed` state class. This is a non-trivial change. The cubit's existing tests (from Iteration 1) will break and must be updated. Acceptance criteria must explicitly require updating Iteration 1 tests after this refactor.
- **Backend test coverage gap.** Iteration 2 is the first iteration with backend changes (filter params in events-ms). The acceptance criteria include unit/widget tests for Flutter but say nothing about backend unit tests for the filter logic in events-ms. If the filter Prisma query has a bug (e.g., `dateFrom` and `dateTo` are inclusive/exclusive in unexpected ways), no test catches it. Recommend adding: "Backend: events-ms has unit tests for the `findAllEvents` filter combinations (type only, date range only, city only, combined)."
- **Code generation must be re-run.** After `EventFilterState` becomes a freezed class, `dart run build_runner build` is required. The build step must be in the definition of done for this iteration.

**Risk level: LOW-MEDIUM.** The backend filter gap is the concrete risk. Everything else is UI completion work. Manageable if the backend task is confirmed before sprint planning.

---

### Iteration 3 — SOAT & Mandatory Insurance Documents

#### UX Complexity Review

**Feasibility: BORDERLINE — this iteration contains 6 distinct UI states across two sequential screens.** The full upload-and-confirm flow is:

1. **Entry point:** Rider opens vehicle detail → "Documentos obligatorios" section → button "Subir SOAT".
2. **File picker:** `file_picker` opens → rider selects PDF → file is picked and a loading indicator begins.
3. **Upload progress state:** PDF is uploaded to Firebase Storage. There is no explicit upload progress bar in the acceptance criteria. For large files (multi-MB scans), a progress indicator is essential — without it the UI appears frozen.
4. **AI extraction loading state:** After upload, the app calls `POST /vehicles/my/:vehicleId/insurance`. Claude Haiku is processing the PDF. This could take 2-5 seconds. The UI must show a distinct "Extrayendo fecha del documento..." loading state — not the same shimmer as a list load.
5. **Confirmation screen (happy path):** Extracted date is shown pre-filled in an editable date field. `extractionConfidence == 'low'` shows a warning banner. Rider confirms or edits and taps Save.
6. **Manual entry fallback (extraction error):** Backend returns 422. UI immediately transitions to a manual date entry form with a clear explanation ("No pudimos extraer la fecha. Ingresala manualmente.").
7. **Success state:** After save, rider is returned to vehicle detail. The status badge (Vigente/Por vencer/Vencido) is now visible.
8. **Garage status badge:** All vehicle cards in the garage now show the status badge for vehicles with uploaded documents. Vehicles without a document show no badge.

**None of states 3, 4, 5, 6, and 7 are explicitly called out in the acceptance criteria.** This is an underspecified iteration. The widget tests for "upload form (loading state, success, AI failure → manual entry fallback)" are in the acceptance criteria, but the actual UX of each state is not described, which means the implementer must invent the design. Given that HU-DESIGN-01 (Pencil) should be the source of truth for new screens from Iteration 3 onward, **the SOAT upload flow must be designed in Pencil before the Flutter implementation begins.**

**Recommended split:**

**Iteration 3a — SOAT Backend + PDF Upload Infrastructure**
- Backend: Prisma schema, `POST /vehicles/my/:vehicleId/insurance` endpoint, Claude Haiku extraction, `PATCH /vehicles/my/:vehicleId/insurance/:documentId`.
- Flutter: `InsuranceDocumentModel`, `InsuranceDocumentDto`, `InsuranceService` (Retrofit), `InsuranceRepository`, `UploadInsuranceDocumentUseCase`, `ConfirmInsuranceDateUseCase`.
- Flutter: `InsuranceDocumentCubit` with states (initial, uploading, extracting, confirmation, manualEntry, saved, error).
- `file_picker` added to `pubspec.yaml`.
- Unit tests for all use cases and cubit state transitions.
- No UI beyond a minimal proof-of-concept upload button in vehicle detail.

**Iteration 3b — SOAT UI + Garage Status Badges**
- Flutter: Full upload form UI (file picker trigger, upload progress, extraction loading, confirmation form with date picker, manual entry fallback, success return).
- Flutter: Garage vehicle card status badge widget.
- Widget tests for all 6 UI states.
- Integration test: full upload → extraction → confirmation → badge update flow.
- Pencil design must be complete before this iteration starts.

**If the PO decides NOT to split:** The iteration must explicitly add the following to acceptance criteria:
- Upload progress indicator (percentage or indeterminate) during Firebase Storage upload.
- Distinct loading message "Extrayendo fecha con IA..." during the backend AI extraction call (separate from the upload progress).
- `extractionConfidence == 'low'` shows a yellow warning banner on the confirmation form.
- After confirmation, rider is navigated back to vehicle detail automatically.
- Vehicles in the garage with no insurance document show no badge (not a placeholder badge).
- Widget test for the `extractionConfidence == 'low'` warning banner.
- Widget test for the navigation flow: confirm date → back to vehicle detail.

**Additional UX concern — date picker for manual/override entry.** The date field on the confirmation form must use a date picker dialog (not a free-text field) to prevent invalid date entry. The existing `flutter_form_builder` package supports `FormBuilderDateTimePicker`. This must be specified in the acceptance criteria.

**`file_picker` permission handling.** On Android, `file_picker` for PDFs may require `READ_EXTERNAL_STORAGE` or `READ_MEDIA_VISUAL_USER_SELECTED` depending on API level. `permission_handler` is already in the stack. The acceptance criteria must include: "If the user denies file access permission, the app shows an explanation dialog and does not crash." This is not in the current acceptance criteria.

#### Quality Gate Review

- **`InsuranceDocumentCubit` state machine is the most complex cubit added so far.** It has more states than any existing cubit (uploading → extracting → confirmation/manualEntry → saving → saved). These must be modeled as a `@freezed` state class, not a `ResultState<T>` union — the PO acceptance criteria say `ResultState` but the Architect review models the data class. This needs to be reconciled. Recommend: use a `@freezed InsuranceUploadState` class with a status enum and nullable fields for the intermediate data (e.g., `extractedDate`, `storageUrl`, `extractionError`).
- **Code generation sequence is non-trivial.** Three separate build steps are needed: (1) `InsuranceDocumentDto` (json_serializable), (2) `InsuranceUploadState` (freezed), (3) `InsuranceService` (retrofit). Each has a `part` directive dependency. If any file is added without its `part` directive, build_runner will silently skip it. Acceptance criteria must include the explicit build_runner command.
- **Backend: Prisma migration.** `npx prisma migrate dev` must run before any integration test can hit the new endpoint. If the dev environment migration is not applied, all integration tests will fail with a Prisma schema mismatch error. This is a common miss — add it explicitly to the definition of done.
- **Firebase Storage path collision.** The path `insurance/{userId}/{vehicleId}/soat.pdf` overwrites the previous file silently when a rider re-uploads a SOAT. This is probably the desired behavior (replace with the newest document), but it must be documented in the acceptance criteria to confirm intent, and the test must verify that re-uploading replaces (not duplicates) the document in both Firebase Storage and the Prisma table.

**Risk level: HIGH (as a single iteration). MEDIUM if split into 3a/3b.**

---

### Iteration 4 — AI Event Cover Image Generation

#### UX Complexity Review

**Feasibility:** Yes — this is achievable in a single iteration. The UI entry point (button) already exists. The UX surface is limited to a single state machine within the existing `EventFormPage`.

**Hidden UX risks:**

- **Image preview dimensions.** The event cover image in the `EventFormPage` likely has a fixed aspect ratio (e.g., 16:9 or 4:3). Unsplash images return in various orientations. The preview widget must use `BoxFit.cover` with a fixed aspect ratio container to prevent layout reflow when the image loads. If the generated image is portrait and the preview area is landscape, the UI will break. Acceptance criteria must specify the preview container's aspect ratio.
- **Regenerate UX — loading while a preview is visible.** When the organizer taps "Regenerar", the current preview should show a loading overlay (shimmer or opacity pulse) rather than disappearing, so the organizer knows what is being replaced. If the preview disappears entirely during regeneration, the UX is confusing. This state transition is not in the acceptance criteria.
- **"Pick your own photo" interaction after AI generation.** If the organizer taps "Subir propia imagen" after an AI-generated image is already in the preview, the form should clear the AI-generated URL and replace it with the picked image. The form state must handle this transition explicitly — otherwise the event is saved with both the AI URL (from the state) and the gallery image (from a second field).
- **Generation latency expectation.** If using Unsplash (Architect Option A), response time should be < 2s. If using Replicate (Option B), it can be 10-20s. The loading state copy ("Generando portada...") and any timeout handling (what happens at 30s?) must be designed. Recommendation: add a 15s timeout on the backend; if exceeded, return a 503 and show the error snackbar.
- **Non-blocking form submission.** The PO correctly notes that image generation is non-blocking. The acceptance criteria must also state: the form's "Publicar" button is never disabled while image generation is in progress — the organizer can submit without a cover at any time.

**Missing acceptance criteria:**
- Preview container has a fixed aspect ratio (specify which ratio — must match existing event list card ratio).
- Regenerate taps show a loading overlay on the existing preview (not a blank state).
- "Subir propia imagen" after AI generation correctly replaces the AI URL with the picked image URL in the form state.
- Generation request times out at 15 seconds with a Spanish error snackbar.
- "Publicar" button is never disabled due to in-progress generation.

#### Quality Gate Review

- **`EventFormCubit` state refactor has regression risk.** Adding `ResultState<String> coverGenerationResult` to `EventFormCubit`'s state requires converting the cubit state to a `@freezed` class (if not already). Any Iteration 1 widget tests that test `EventFormPage` against `EventFormCubit` will need to be updated. This is a cross-iteration test regression risk. Acceptance criteria must include: "Update any existing `EventFormCubit` widget tests after state class refactor."
- **Test coverage for form state transitions is underspecified.** The current acceptance criteria say "Widget test for the form button states (idle, loading, preview-shown, error)." This must also include: "Widget test for regenerate while preview is shown," "Widget test for replace AI image with gallery pick," and "Widget test that submit button remains enabled during generation." Without these, the UX risks above go undetected.
- **ADR-4 (Unsplash vs Replicate) must be decided before backend coding begins.** The backend implementation differs significantly between the two options (no external service vs. Replicate SDK + Firebase Storage upload). If this decision is deferred until the sprint starts, the backend agent will block.

**Risk level: LOW-MEDIUM.** The core integration is straightforward. The risks are in the UX edge cases of the image preview and form state machine.

---

### Iteration 5 — AI Event Recommendations

#### UX Complexity Review

**Feasibility:** Yes — the UI card already exists on the dashboard. This is a data-wiring iteration.

**Hidden UX risks:**

- **Stale cache on first open after install.** On a fresh install, the `SharedPreferences` cache is empty. The `RecommendationsCubit` should immediately show a loading skeleton while the first fetch runs — not an empty state. If the cache miss falls through to `ResultState.empty()` before the network response arrives, the home dashboard card will flash empty and then fill in. This is a jarring experience. The cubit's `load()` method must emit `loading()` when the cache is empty, then `data()` when the response arrives.
- **Cache expiry UX.** The Architect proposes a 6-hour cache expiry. If the rider opens the app exactly when the cache has expired, they will see a loading skeleton where the recommendations were. This is acceptable but must be defined: does the cubit show the stale cached data while refreshing in the background (preferred), or does it show a skeleton? Recommendation: show stale data while refreshing (emit `data` from cache immediately, then update with fresh `data`).
- **New rider fallback — "no recommendations" vs. "upcoming events".**The PRD acceptance criterion says new riders see "the 5 soonest upcoming events." The UX must distinguish this from the personalized recommendations — if the same `EventModel` cards render identically whether personalized or fallback, the rider has no way to know they are new. Recommend: if `fallback: true` is in the response, show a subtle label "Próximos eventos" instead of "Recomendados para ti".
- **Navigation from recommendation card to event detail.** The PO says "tapping a recommendation navigates to the event detail page." This must use the same `EventDetailPage` (via `pushNamed` with the `EventModel` as `extra`) that event list items use — not a new page. Confirm that the existing `EventModel` can be passed from the `RecommendationsCubit`'s state to `context.pushNamed('event_detail', extra: event)`.
- **Dashboard layout impact.** The existing dashboard `HomeCubit` manages the home section. Adding a new `RecommendationsCubit` as a second provider on `HomePage` means `HomePage` now depends on two cubits. Confirm that the BlocProvider tree (in `main.dart` or the route builder) supplies both cubits to `HomePage` without causing a double-build. The `RecommendationsCubit` should be lazily initialized — it must not make a network request until `HomePage` actually mounts.

**Missing acceptance criteria:**
- `RecommendationsCubit` emits `loading()` (not `empty()`) on first open when cache is empty.
- When cache is valid but expired, emit stale `data()` immediately and update with fresh `data()` after the network response arrives.
- If `fallback: true` in the response, the recommendation section header reads "Próximos eventos" instead of "Recomendados para ti".
- Recommendation card taps navigate via `pushNamed` with the `EventModel` as `extra` (same as event list items).
- `RecommendationsCubit` does not fire a network request until `HomePage` mounts.

#### Quality Gate Review

- **Caching is not covered by any specified test.** The acceptance criteria include unit tests for the scoring use case and cubit state transitions — but no test verifies that the cache is written on fetch and read on the next load. This is a material omission for a feature where caching is a key acceptance criterion. Recommend adding: "Unit test: `RecommendationsCubit` emits cached data from `SharedPreferences` before making a network call; unit test: cache is updated after a successful network response."
- **`RecommendationsCacheService` is a new service.** It must be registered in `injection.dart` as a `@singleton`. If it is omitted from DI registration, `GetIt` will throw at runtime with no obvious connection to the cache. Acceptance criteria must include confirming DI registration.
- **`HomeCubit` must not be modified.** The Architect explicitly states `HomeDto` must not change and `HomeService` must not change. Acceptance criteria must include: "No changes to `HomeCubit`, `HomeService`, or `HomeDto`." This protects against an implementer merging the recommendation data into the home cubit and breaking existing home tests.
- **Backend scoring algorithm — edge case coverage.** The scoring uses vehicle type match, registration history, and geographic proximity. If a rider's `residenceCity` is null (not set in profile), the proximity score component breaks. The backend endpoint must handle null `residenceCity` gracefully (score 0 for proximity, not a 500 error). The backend unit tests must cover this case.

**Risk level: LOW.** The main risk is the underspecified caching behavior and the stale-cache UX. Both are fixable with clearer acceptance criteria.

---

### Iteration 6 — Push Notifications (FCM) + SOS Alert

#### UX Complexity Review

**This iteration is too large for a single sprint. See Section 3 for the recommended split.**

**FCM UX risks:**

- **Three app-state notification handlers have three different UX behaviors.** Foreground notifications must show an in-app SnackBar (not a system banner) and optionally navigate. Background notifications use the system notification tray; tapping opens the app. Terminated app notifications must cold-start the app and navigate immediately. Each of these three paths requires a different implementation and a different test scenario. The acceptance criteria collapse all three into one bullet ("Foreground, background, and terminated app states all handled") — this is not testable as written.
- **Deep-link navigation in terminated state.** `FirebaseMessaging.getInitialMessage()` is called in `main()` *before* the router is fully initialized. The `NotificationNavigator` service that the Architect proposes must handle the case where the route it needs to navigate to does not exist yet (the widget tree has not mounted). A common pattern is to store the initial notification route in a `ValueNotifier` and have the root widget navigate after first mount. If this race condition is not handled, the app cold-starts and lands on the home screen instead of the notification target.
- **"Registration detail by id" page fetch on notification tap.** The Architect proposes `RegistrationDetailByIdPage` that fetches the `RegistrationModel` from the backend before rendering. If the registration has been deleted or the event cancelled between the notification send and the tap, the page must handle a 404 gracefully (show an error message and a back button, not a crash).
- **FCM permission prompt (iOS).** On iOS, `firebase_messaging` must call `requestPermission()` to show the native "Allow Notifications?" dialog. This prompt must appear at a contextually appropriate moment (e.g., after the rider first registers for an event, not at app launch). If it fires on first launch, conversion is lower. The acceptance criteria must specify when `requestPermission()` is called.
- **Token refresh during long sessions.** FCM tokens can be invalidated and refreshed while the app is running. The `onTokenRefresh` listener must be registered at app startup (not just on login), or a long-running session without a logout/login will miss a token rotation and stop receiving notifications. The acceptance criteria mention `onTokenRefresh` but must specify that the listener is registered in `main()` (or the `AuthCubit` observer), not in the login flow only.

**SOS UX risks:**

- **SOS overlay persistent visibility.** The PRD says "The overlay remains visible until the rider who activated it cancels it or the organizer dismisses it." This requires the SOS state to survive screen navigation changes. If a rider on the live map taps the SOS button and then navigates away and back, the overlay must still be visible. The `LiveTrackingCubit` is a global singleton — this likely works if the cubit holds the `activeSosAlert` field, but this must be confirmed in the acceptance criteria.
- **SOS dismiss affordance.** The rider who activated SOS must have a "Cancelar SOS" button visible on the overlay. Other riders see the overlay but no dismiss control — they see only the name and position. The organizer dismiss path ("the organizer can dismiss it") is mentioned in the PRD but is not in the acceptance criteria at all. How does the organizer dismiss it? Is there a separate organizer control panel? This is a missing UX decision.
- **SOS overlay and map interaction.** A full-screen red overlay that is "persistent" risks blocking the map controls (zoom, pan, rider location pins). The overlay must be implemented as a top-anchor banner (not a full-screen cover) that allows the map to remain interactive. Acceptance criteria must specify the overlay placement.
- **Multiple simultaneous SOS alerts.** The PRD and acceptance criteria assume a single SOS at a time. What happens if two riders trigger SOS simultaneously? The `activeSosAlert: SosAlertModel?` field in `LiveTrackingState` holds only one alert. The acceptance criteria must either scope to "single SOS at a time" explicitly or specify a `List<SosAlertModel>`.
- **Touch target on SOS button.** The SOS button must be at minimum 44×44px (PRD/mobile-first requirement). It already exists in `live_map_page.dart` with an empty `onPressed`. Confirm the existing widget meets the touch target requirement before wiring.
- **Accessibility concern on red overlay.** Red is the primary visual signal for the SOS alert. For color-blind riders (red-green color blindness), a red overlay with no secondary signal (text label, icon, haptic) is inaccessible. The overlay must include high-contrast text (white text on red) and the rider's name as the primary information carrier, not color alone.

**Missing acceptance criteria (FCM):**
- Foreground notification shows in-app SnackBar; does NOT show system banner.
- Terminated app initial notification stored in `ValueNotifier` and navigated after first mount.
- `RegistrationDetailByIdPage` handles 404 (registration not found) with a graceful error message.
- `requestPermission()` is called after the rider first registers for an event (not at app launch).
- `onTokenRefresh` listener is registered at app startup, independent of login.

**Missing acceptance criteria (SOS):**
- SOS overlay survives navigation away-and-back (cubit state persists).
- Organizer dismiss path is defined: specify the UX mechanic (button on overlay? separate screen?).
- SOS overlay is a top-anchor banner (not full-screen) — map remains interactive.
- Scope for simultaneous SOS alerts: either "only one SOS at a time" or "list of SOS alerts."
- SOS button is at minimum 44×44px touch target.

#### Quality Gate Review

- **FCM integration tests cannot mock Firebase Admin SDK fully.** The acceptance criteria say "FCM flow is stubbed (Firebase Admin SDK mocked)" — but verifying that the correct users receive the correct notification requires either a real FCM dispatch or a deep mock of the Admin SDK. The integration test scope must be: Flutter side only (mock the notification handler, verify navigation), not end-to-end FCM dispatch. Backend FCM dispatch must be tested with backend-specific integration tests.
- **Native platform setup is not testable by `flutter test`.** APNs key, `AndroidManifest.xml` changes, Xcode background modes — these are operational configurations, not code. They must be in a DevOps checklist item, not in the acceptance criteria for `flutter test`. The acceptance criteria as written imply that `flutter test` verifies these, which it cannot.
- **SOS `LiveTrackingState` freezed regeneration.** Adding `activeSosAlert: SosAlertModel?` to `LiveTrackingState` requires a build_runner pass. `SosAlertModel` itself must be a freezed class or a simple immutable Dart class. If it is freezed, another build pass is needed. The acceptance criteria must include the build sequence.
- **Cross-feature regression risk.** Iteration 6 modifies `TrackingWsClient` (new message types), `LiveTrackingCubit` (new state field), `LiveMapPage` (new overlay and button wiring), `AppRouter` (new by-id routes), and `main.dart` (FCM initialization). This is the largest single-iteration surface area in the plan. Without Iteration 1–5 tests in place, regressions in live tracking (the existing flow) will not be caught. The existing `LiveTrackingCubit` tests added in earlier iterations are the safety net — they must be passing before Iteration 6 starts.

**Risk level: VERY HIGH (as a single iteration). HIGH even if split.**

---

### Iteration P (Parallel) — Design System in Pencil (HU-DESIGN-01)

#### UX Complexity Review

**Feasibility:** Yes — this is design-only work with no Flutter code changes.

**Risks:**

- **Single-machine dependency.** The Stitch reference images are at `/Users/cami/Downloads/stitch_rideglory/` — an absolute path on one machine. If the design session moves to a different machine, these images are unavailable. This is a real risk for a tool like Pencil that opens `.pen` files. The reference images should be copied into the repo at `docs/design/stitch-references/` before HU-DESIGN-01 begins, so they are version-controlled alongside the Pencil file.
- **Design handoff timing is critical for Iteration 3.** The PO proposal says "Complete HU-DESIGN-01 before Iteration 3 frontend work begins." This must be enforced as a hard gate: the Iteration 3 frontend agent must not begin widget implementation until the SOAT upload flow screens are in Pencil. If this gate is skipped, the implementer will invent the UX (multi-step states, confirmation form layout, error fallback) and it will differ from the final design.
- **Pencil file not yet created.** The scan confirms `pencil-new.pen` does not exist. The acceptance criteria correctly include creating it. But there is no verification step — how does the team confirm the file opens correctly and the variables are defined? Recommendation: add to the acceptance criteria that a screenshot of each labeled section is exported as `docs/design/screenshots/<flow>.png` so the design can be reviewed without opening Pencil.

**Missing acceptance criteria:**
- Stitch reference images are copied to `docs/design/stitch-references/` before the session.
- Exported screenshots of each Pencil section are saved to `docs/design/screenshots/`.
- The SOAT upload flow (at minimum: entry point, upload progress, extraction loading, confirmation form, manual entry) is designed in Pencil before Iteration 3 frontend begins.

#### Quality Gate Review

- No code — no `dart analyze` / `flutter test` required.
- The `docs/handoffs/design.md` handoff file should list the specific Pencil section names and variable keys, so developers have a lookup reference.
- **Risk level: LOW.**

---

## 3. Recommended Iteration Structure Changes

### Change 1: Split Iteration 3 into 3a and 3b (REQUIRED)

**Reason:** The SOAT feature has 6+ distinct UI states across a multi-step flow, requires a new package (`file_picker`), backend Prisma migration, Claude API integration, and a status badge system. As a single iteration it is scope-equivalent to an XL.

| Iteration | Scope | Complexity |
|-----------|-------|------------|
| **3a — SOAT Infrastructure** | Backend (Prisma schema, API endpoints, Claude Haiku extraction), Flutter domain + data layers (`InsuranceDocumentModel`, `InsuranceDocumentDto`, `InsuranceService`, repository, use cases), `InsuranceDocumentCubit` (all states), unit tests | L |
| **3b — SOAT UI + Garage Badges** | Flutter presentation layer only (upload form with all 6 states, confirmation form, date picker, manual entry fallback, garage status badge widget), widget tests (all states), integration test | M |

**Gate between 3a and 3b:** Pencil design for the SOAT flow must be complete (from Iteration P) and `dart analyze` + `flutter test` must pass on Iteration 3a before 3b begins.

### Change 2: Split Iteration 6 into 6a (FCM) and 6b (SOS) (REQUIRED)

**Reason:** The Architect already flagged this as XL. This review confirms that FCM alone (package installation, platform setup, 3 app-state handlers, `NotificationNavigator`, deep-link routes, backend `NotificationsModule`, FCM dispatch triggers) is a full sprint. SOS (new WebSocket message types, `SosAlertModel`, cubit state extension, overlay widget, backend broadcast) is a second full sprint. Combining them is not feasible without sacrificing test coverage or UX quality.

| Iteration | Scope | Complexity |
|-----------|-------|------------|
| **6a — FCM Push Notifications** | `firebase_messaging` package, FCM token registration + refresh, 3 app-state handlers, `NotificationNavigator`, by-id deep-link routes (`RegistrationDetailByIdPage`, `LiveMapByIdPage`), backend `NotificationsModule` + FCM dispatch triggers, unit + widget tests | L |
| **6b — SOS Real-Time Alert** | `SosAlertModel`, `TrackingWsClient` SOS message types, `LiveTrackingCubit.activeSosAlert` state field, `SosButton` wiring, `SosOverlay` widget, backend `TrackingGateway` SOS broadcast handlers, widget + integration tests | M |

**Gate between 6a and 6b:** FCM notifications must be working end-to-end (verified on a physical device or device farm) before SOS begins. `dart analyze` + `flutter test` must pass.

### Change 3: Enforce the Pencil gate before Iteration 3b (REQUIRED)

The design agent (Iteration P) must deliver Pencil screens for the SOAT upload flow before Iteration 3b frontend work begins. This must be a hard dependency, not a soft one. Add to `workflow/state.json` (when it is updated) that 3b's `dependsOn` includes the Pencil design delivery for the SOAT screens.

### Change 4: Move the CI/CD pipeline (no iteration number assigned) — RECOMMENDED

The PO deferred CI/CD to "after Iteration 2." Given that the quality gate for every iteration is `dart analyze` + `flutter test` passing, and given that the codebase currently has 0% test coverage, a CI/CD pipeline running `dart analyze` and `flutter test` on every PR is essential by Iteration 2. Recommend scheduling a short DevOps iteration (call it **Iteration D — DevOps**) to run in parallel with Iteration 2, delivering:
- `.github/workflows/flutter-ci.yml` with `dart analyze` + `flutter test`
- Optional: APK build job triggered on tags

### Revised Iteration Sequence

| # | Iteration | Complexity | Parallel |
|---|-----------|------------|---------|
| 1 | Test Infrastructure + Profile Feature | M | |
| P | Design System in Pencil | M | Runs with 1–3a |
| D | CI/CD Pipeline | S | Runs with 2 |
| 2 | Event Discovery Filters + Attendee Profile Links | M | |
| 3a | SOAT Infrastructure (backend + domain + data + cubit) | L | |
| 3b | SOAT UI + Garage Status Badges | M | Requires P complete |
| 4 | AI Event Cover Image Generation | M | |
| 5 | AI Event Recommendations | M | |
| 6a | Push Notifications (FCM) | L | |
| 6b | SOS Real-Time Alert | M | |

---

## 4. Quality Gate Checklist

The following must be satisfied at the end of **every** iteration before it is marked complete:

### Code quality
- [ ] `dart analyze` passes with **zero violations** (no warnings, no lints suppressed with `// ignore:` without a written justification).
- [ ] `dart run build_runner build --delete-conflicting-outputs` runs cleanly (no orphaned generated files, no conflicting outputs).
- [ ] `dart format lib/ test/` applied — no unformatted files.

### Test coverage
- [ ] `flutter test` passes with **100% green** (zero failing tests, zero skipped tests without a written justification).
- [ ] Every new Cubit has a `blocTest` group covering: `initial`, `loading`, `data`, `empty`, `error` states.
- [ ] Every new Page has a widget test class covering: loading skeleton, data render, empty state, and error banner.
- [ ] Every new use case has a unit test covering: happy path and at least one error/exception path.
- [ ] Every new repository implementation has a unit test covering: DTO → model mapping and error propagation.
- [ ] No real HTTP calls in unit or widget tests (all services mocked via `mocktail`).

### Architecture compliance
- [ ] No Flutter imports in the `domain/` layer.
- [ ] No `BuildContext` usage in the `data/` layer.
- [ ] No Retrofit service calls in the `presentation/` layer (only via use cases through the repository interface).
- [ ] No DTO types exposed in the `presentation/` layer (use domain models only).
- [ ] All new services and repositories registered in `injection.dart` with the correct scope (`@injectable`, `@singleton`, or `@lazySingleton`).
- [ ] All new cubits added to `MultiBlocProvider` in `main.dart` if they are global singletons.

### Localization
- [ ] No hardcoded Spanish strings in any widget — all via `context.l10n.<key>`.
- [ ] All new ARB keys follow the feature-prefix naming convention (e.g., `soat_uploadTitle`, `push_approvedBody`).
- [ ] `flutter gen-l10n` runs without errors after ARB changes.

### Design system compliance
- [ ] No raw Material widgets where a shared equivalent exists (`AppButton` over `ElevatedButton`, `AppTextField` over `TextField`, `AppDialog` over `AlertDialog`, `EmptyStateWidget` over custom empty state).
- [ ] Colors use `Theme.of(context).colorScheme.<property>` first; fallback to `AppColors` constants only for colors not in the color scheme.
- [ ] All touch targets ≥ 44×44px.
- [ ] All new widgets have both a loading state and an error state — no widget renders nothing silently while data is unavailable.

### Backend (for iterations with backend changes)
- [ ] `npx prisma migrate dev` applied and committed for any schema changes.
- [ ] `npx prisma generate` run after schema changes.
- [ ] Backend unit tests cover any new endpoint's happy path and at least one error path.

---

## 5. Open Questions for the PO

The following items require a PO decision before the affected iteration can be finalized. They are ordered by the iteration they block.

---

**Q1 — Profile photo in Iteration 1 (blocks Iteration 1 planning)**

The Architect recommends Option A (no profile photo in Phase 1 — show placeholder). The `User` Prisma model lacks a `profilePhotoUrl` field. Does the PO accept that the profile page in Iteration 1 shows only name, email, and main vehicle with an initials-based avatar placeholder, and defers photo upload to a later iteration?

*Default if no response:* Follow Architect ADR-2 recommendation (Option A — no photo upload in Iteration 1).

---

**Q2 — CI/CD priority (blocks Iteration D)**

The PO deferred CI/CD pipeline setup to after Iteration 2. Given that every iteration's quality gate requires `dart analyze` + `flutter test` passing, should the DevOps pipeline be built in parallel with Iteration 2 (so the CI gate is automated from Iteration 3 onward), or is manual execution of these checks by the developer sufficient through the full plan?

*Recommendation:* Build CI/CD in parallel with Iteration 2. A pipeline that catches lint violations before a PR merge is worth 2-4 hours of setup.

---

**Q3 — SOAT iteration split approval (blocks Iteration 3 planning)**

This review recommends splitting Iteration 3 into 3a (infrastructure) and 3b (UI + badges). Does the PO approve this split? If the PO declines the split, the additional acceptance criteria listed in Section 2 (Iteration 3 review) must be explicitly added to the single iteration's definition of done before it begins.

*Recommendation:* Approve the split.

---

**Q4 — Organizer SOS dismiss mechanic (blocks Iteration 6b UX design)**

The PRD states: "The overlay is dismissed... when the organizer dismisses it." The current acceptance criteria and architecture do not define how the organizer triggers this dismissal. Options:
- A) Organizer sees the same SOS overlay as all riders, with an additional "Desestimar" button (visible only to the organizer, based on a role check).
- B) Organizer has a separate "SOS active" notification in their event management screen that they can dismiss from there.
- C) Only the rider who activated SOS can cancel it — organizer dismiss is deferred to a future iteration.

Which mechanic does the PO want in v1?

*Recommendation:* Option C (rider-only cancel in v1) — simplest to implement, and the organizer can coordinate verbally/via other channels in the pilot phase. Organizer dismiss can be added when the organizer management screen is more fully built.

---

**Q5 — Simultaneous SOS alerts scope (blocks Iteration 6b acceptance criteria)**

The current design holds a single `activeSosAlert: SosAlertModel?` in `LiveTrackingState`. If two riders trigger SOS simultaneously:
- A) Accept only one SOS at a time: the second SOS overwrites the first in the overlay.
- B) Show a list of active SOS alerts in the overlay.

Which behavior does the PO want in v1?

*Recommendation:* Option A (single SOS at a time) for v1 simplicity. Document the limitation in the acceptance criteria so it is explicit.

---

**Q6 — FCM permission prompt timing (blocks Iteration 6a UX)**

iOS requires an explicit `requestPermission()` call to show the native "Allow Notifications?" prompt. The prompt timing affects conversion. Options:
- A) On first app launch (most common, but lowest conversion — riders don't know why they need notifications yet).
- B) After the rider first registers for an event (contextual — they just took an action that will trigger a notification).
- C) On the first login only.

When should the app request FCM notification permission?

*Recommendation:* Option B — contextual prompt after first registration. The permission dialog is shown after the "¡Inscripción enviada!" confirmation, with a copy like "Activa las notificaciones para saber cuando sea aprobada."

---

**Q7 — ADR-4 decision (blocks Iteration 4 backend planning)**

The Architect presents two options for AI cover image generation:
- Option A: Unsplash API (free, fast, AI-assisted search via Claude Haiku for the query).
- Option B: Replicate/Stability AI (truly generated, unique image, $0.01–$0.05/image, 10-20s latency).

Which option does the PO approve for v1?

*Recommendation:* Option A. The distinction between "AI-assisted search" and "AI-generated" is invisible to most users at this stage, and the cost and latency advantages of Unsplash are significant for a pilot.
