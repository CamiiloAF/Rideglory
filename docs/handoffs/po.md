# PO handoff — Iteration 1

**Date:** 2026-05-12
**Status:** in progress

---

## Iteration goal

Establish a working test suite for the most critical existing features and complete the profile page stub so the rider experience is coherent end-to-end.

---

## Stories for this iteration

| ID | Story | Acceptance criteria | Primary agent |
|----|-------|---------------------|---------------|
| US-1-1 | As the dev team, I want `mocktail`, `bloc_test`, and `network_image_mock` configured in `dev_dependencies` and a canonical test directory tree created so that all subsequent iterations can write tests with consistent tooling and file structure. | (1) `pubspec.yaml` `dev_dependencies` includes `mocktail: ^1.0.4`, `bloc_test: ^10.0.0`, `network_image_mock: ^2.1.1`. (2) Directory tree exists: `test/features/vehicles/domain/`, `test/features/vehicles/data/`, `test/features/vehicles/presentation/`, `test/features/events/domain/`, `test/features/events/data/`, `test/features/events/presentation/`, `test/features/maintenance/domain/`, `test/features/maintenance/data/`, `test/features/maintenance/presentation/`, `test/core/`. (3) `flutter pub get` runs cleanly with no resolution conflicts. (4) `dart analyze` passes with zero violations after the change. | qa |
| US-1-2 | As the dev team, I want `blocTest` groups covering `VehicleCubit`, `EventsCubit`, `EventDetailCubit`, and `MaintenancesCubit` (initial → loading → data → empty → error) so regressions in state transitions are caught automatically on every PR. | (1) `VehicleCubit` has a `blocTest` group with at minimum 5 cases: initial state, `loading` on fetch start, `data` on success, `empty` when list is empty, `error` when use case returns `Left(DomainException)`. (2) `EventsCubit` and `EventDetailCubit` each have equivalent 5-case groups. (3) `MaintenancesCubit` has a `blocTest` group covering at minimum 4 cases (initial, loading, data, error). (4) All cubit mocks use `mocktail` abstract class pattern (`class MockVehicleRepository extends Mock implements VehicleRepository`). (5) `flutter test` passes 100% green. | qa |
| US-1-3 | As the dev team, I want widget tests for the vehicle garage page, event list page, and event detail page covering all `ResultState` UI branches so that design system components are verified under every condition. | (1) Vehicle garage page widget test covers: loading skeleton (shimmer renders), data state (at least one vehicle card visible), empty state (`EmptyStateWidget` renders), error state (error banner with retry button visible). (2) Event list page widget test covers: loading skeleton, data state (at least one event card), empty state, error state. (3) Event detail page widget test covers: loading skeleton, data state (event title visible), error state. (4) All widget tests use `MockBloc`/`MockCubit` — no real HTTP calls. (5) `network_image_mock`'s `mockNetworkImages()` wraps any test that loads `CachedNetworkImage`. (6) Integration test stub files exist with at least one `group` block each: `integration_test/auth_flow_test.dart`, `integration_test/vehicles_flow_test.dart`, `integration_test/events_flow_test.dart`. (7) `flutter test` passes 100% green. | qa |
| US-1-4 | As a rider, I tap my profile in the bottom navigation and see my name, email, initials avatar, and main vehicle so I feel recognized as a community member. | (1) `ProfileCubit` exists in `lib/features/profile/presentation/cubit/` as `Cubit<ResultState<UserModel>>`, is registered in `injection.dart` as `@lazySingleton`, and is added to the root `MultiBlocProvider` in `main.dart`. (2) `GetMyProfileUseCase` exists in `lib/features/profile/domain/` and calls the existing `UserService.getMe()` — no new backend endpoint. (3) Profile page renders a shimmer skeleton while `ProfileCubit` emits `loading`. (4) Profile page renders the rider's name and email from `UserModel` when `ProfileCubit` emits `data`. (5) Profile page renders an initials-based avatar (two-letter `CircleAvatar`) when `profilePhotoUrl` is null or absent — no broken image widget. (6) Profile page renders the main vehicle name and model from `VehicleCubit` when a main vehicle exists; renders an `EmptyStateWidget` or inline text placeholder ("Sin vehículos") when `VehicleCubit` emits `empty`. (7) Profile page renders an error banner with a retry button when `ProfileCubit` emits `error`. (8) No hardcoded Spanish strings — new profile UI keys are in `app_es.arb` with prefix `profile_` (at minimum: `profile_title`, `profile_noVehicle`, `profile_errorRetry`, `profile_loadingError`, `profile_mainVehicle`). (9) No raw Material widgets where a shared equivalent exists. | frontend |
| US-1-5 | As the dev team, I want a systematic review of the existing codebase to identify and fix dead code, lint violations, architectural smells, and performance issues so the foundation is clean before new features are added. | (1) `dart analyze` passes with zero violations across all of `lib/`. (2) All `print()` calls replaced with proper logging or removed from `lib/`. (3) All unused imports, variables, and dead code removed from `lib/`. (4) No `BuildContext` usage in data layer files — any violations refactored to pass values at call site. (5) No raw Material widgets where a shared design system equivalent exists — non-compliant call sites updated. (6) All `// TODO` and `// FIXME` comments triaged: resolved inline or converted to GitHub issues; none left as stale comments in source. (7) `docs/architecture/code-review-iter1.md` written with a findings table (file, issue, resolution) and items deliberately deferred with rationale. (8) `flutter test` passes 100% green after all changes. | tech_lead |

---

## Assumptions and open questions

- **`GET /users/me` contract:** Assumed to return at minimum `fullName`, `email`, `id`. If the field names differ (e.g., `name` vs `fullName`), the existing `UserModel` mapping in data layer is the source of truth — no backend change is needed for Iteration 1.
- **No profile photo:** `profilePhotoUrl` is not in the current Prisma `User` model. The profile page shows an initials avatar only. Photo upload is deferred to post-6b. No upload affordance is included in the profile UI.
- **`ProfileCubit` DI scope:** Registered as `@lazySingleton` (not `@injectable`) because profile data is user-specific and shared across screens that may display profile details. It belongs in the root `MultiBlocProvider` alongside `AuthCubit`.
- **Existing `widget_test.dart`:** The single empty test file at `test/widget_test.dart` should be replaced (or supplemented) by the new feature-organized test files. It must not be left as a lone empty file.
- **Code review agent:** `tech_lead` runs the code review (HU-REFACTOR-01) first and produces `docs/architecture/code-review-iter1.md`. The `frontend` agent then implements the `ProfileCubit` and profile page. `qa` validates everything at the end. Order matters for clean diffs.

---

## Out of scope (this iteration)

- **Profile photo upload:** `profilePhotoUrl` not in Prisma schema — deferred post-6b.
- **Event discovery filters:** Backend filter wiring is Iteration 2.
- **Attendee profile navigation:** Rider-to-rider profile links are Iteration 2.
- **SOAT/insurance management:** Iteration 3a+.
- **AI features:** Iterations 4–5.
- **Push notifications and SOS:** Iterations 6a+.
- **Pencil design system migration:** Track P (parallel, no code changes).
- **GitHub Actions CI/CD:** Track DevOps (parallel with Iteration 2).
- **Full integration test execution against dev backend:** Stub files are created this iteration; actual end-to-end test logic can be filled incrementally in later iterations as features stabilize.

---

## Next agent needs to know

- **architect:** No new API contracts are needed for Iteration 1. `GET /users/me` already exists in `UserService`. The only architectural decision to document is the `ProfileCubit` DI scope (`@lazySingleton` in root `MultiBlocProvider`) and the ADR confirming no profile photo upload in v1 (ADR-2). The test infrastructure packages (`mocktail`, `bloc_test`, `network_image_mock`) are dev-only — no DI or build_runner changes required. Architect should confirm `UserService.getMe()` returns the fields needed by `UserModel` and flag if the data layer mapping is incorrect.
- **frontend:** Implement `ProfileCubit`, `GetMyProfileUseCase`, and the Profile page UI per US-1-4 acceptance criteria. All new strings must be in `app_es.arb` with `profile_` prefix. Use existing `ResultState<T>` union directly — no new freezed state class needed. Consume `VehicleCubit` (already in `MultiBlocProvider`) for the main vehicle display. Do not add a photo upload affordance.
- **qa:** Set up test infrastructure (US-1-1) before writing cubit and widget tests (US-1-2, US-1-3). Follow the `mocktail` abstract class mock pattern. Wrap `CachedNetworkImage` tests with `mockNetworkImages()`. Create integration test stub files even if the test bodies are empty — the group block must exist. Run `dart analyze` and `flutter test` as the final gate.
- **tech_lead:** Run `dart analyze --no-summary` first and address every violation. Use `dart fix --apply` for auto-fixable issues. Search for `print(` across `lib/`. Review each feature's data layer for `BuildContext` imports. Produce `docs/architecture/code-review-iter1.md` with findings table before frontend closes the iteration.
- **backend:** No changes required in `rideglory-api` for Iteration 1. The `GET /users/me` endpoint is already implemented.

---

## Change log

- 2026-05-12: Initial PO handoff for Iteration 1. Stories US-1-1 through US-1-5 defined from PLAN.md Iteration 1 spec. No changes from plan; full alignment confirmed.
