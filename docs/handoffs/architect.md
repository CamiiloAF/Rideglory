# Architect handoff — Iteration 1

**Date:** 2026-05-12
**Status:** done

> Iteration 1 is a foundation iteration: test infrastructure + profile page completion + code cleanup. **No backend (rideglory-api) changes.** **No new endpoints, DTOs, or domain models.** Architecture work is constrained to: confirming the existing `GET /users/me` contract is sufficient for the profile page, defining the `ProfileCubit` DI scope (ADR-1), and confirming the no-photo-upload decision (ADR-2).

---

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|----------------|--------------|----------------------|
| profile | New: `GetMyProfileUseCase` in `lib/features/profile/domain/use_cases/get_my_profile_use_case.dart`. Reuses existing `UserRepository` (in `lib/features/users/domain/repository/`). No new repository, no new model — uses existing `UserModel`. | None. `UserService.getCurrentUser()` (Retrofit `GET /users/me`) and `UserRepositoryImpl` already exist and are reused as-is. | New: `ProfileCubit` extends `Cubit<ResultState<UserModel>>` in `lib/features/profile/presentation/cubit/profile_cubit.dart`. Replaces stub `profile_page.dart` with real UI (initials avatar, name, email, main vehicle, logout). Consumes existing `VehicleCubit` for main vehicle. |
| vehicles | None | None | None — feature is read in widget tests only. |
| events | None | None | None — feature is read in widget tests only. |
| maintenance | None | None | None — feature is read in cubit tests only. |
| test infrastructure (cross-cutting) | n/a | n/a | New `test/` tree mirroring `lib/features/` per US-1-1. `dev_dependencies` additions in `pubspec.yaml`. No `build_runner` impact. |

---

## API contracts (rideglory-api changes)

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|--------------|---------|--------|
| — | — | — | — | — | — |

**No backend changes this iteration.** `GET /api/users/me` is pre-existing. Architect confirms the response shape matches the current `UserDto` (`id`, `fullName`, `email`, plus optional rider profile fields). No drift detected.

---

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `GetMyProfileUseCase` | domain | `lib/features/profile/domain/use_cases/get_my_profile_use_case.dart` | `@injectable`. Single method `call()` returning `Future<Either<DomainException, UserModel>>`. Delegates to `UserRepository.getCurrentUser()`. |
| `ProfileCubit` | presentation | `lib/features/profile/presentation/cubit/profile_cubit.dart` | `@lazySingleton`. Extends `Cubit<ResultState<UserModel>>`. Methods: `fetchProfile()`, `reset()`. Registered in root `MultiBlocProvider` in `main.dart` alongside `AuthCubit`, `VehicleCubit`, `MyRegistrationsCubit`. |

No new freezed state class is required — single async result fits `ResultState<UserModel>` directly. The main-vehicle slot in the UI reads from the existing `VehicleCubit` (already global).

---

## ADRs (architectural decisions)

### ADR-1 — ProfileCubit DI scope: `@lazySingleton`
**Status:** Accepted.
**Context:** Profile data (`UserModel` from `/users/me`) is user-scoped and may be needed by future screens (settings, share-profile, organizer view of self).
**Decision:** Register as `@lazySingleton` and add to root `MultiBlocProvider`. Reset state on logout via `AuthCubit` listener (same pattern as `VehicleCubit.clearVehicles()`).
**Consequence:** Profile fetch happens once per session; downstream screens read without re-fetching. Memory cost is negligible (one `UserModel`).

### ADR-2 — No profile photo upload in v1
**Status:** Accepted (echoed from PO).
**Context:** Prisma `User` model in rideglory-api does not include `profilePhotoUrl`. Adding it requires a backend migration not scoped to Iteration 1.
**Decision:** Render an initials-based `CircleAvatar` (two-letter, derived from `fullName`). No upload affordance in profile UI. Revisit post-iteration 6b.
**Consequence:** Profile UI is read-only for photo. Initials computation is a pure helper in presentation layer.

---

## Environment variables

| Variable | Description | Example |
|----------|-------------|---------|
| — | None added this iteration | — |

---

## Localization (l10n keys)

All new strings live in `lib/l10n/app_es.arb` under the `profile_` prefix. Frontend agent must add at minimum:

| Key | Spanish value (suggested) |
|-----|---------------------------|
| `profile_title` | "Mi perfil" |
| `profile_mainVehicle` | "Vehículo principal" |
| `profile_noVehicle` | "Sin vehículos" |
| `profile_errorRetry` | "Reintentar" |
| `profile_loadingError` | "No pudimos cargar tu perfil" |

After editing ARB: `flutter gen-l10n` (or `dart run build_runner build --delete-conflicting-outputs`).

---

## Risks and open questions

- **`UserDto` field drift:** If rideglory-api silently renames `fullName` → `name`, the profile page shows blank. Mitigation: `tech_lead` runs `dart analyze` and `qa` writes a repository test asserting DTO→model mapping (already required by US-1-2 indirectly via existing `UserRepository` coverage).
- **Initials helper duplication:** Other features may need the same logic later (attendee list, organizer view). Frontend should place it under `lib/core/utils/initials.dart` to avoid duplication in Iteration 2.
- **Logout state reset:** `ProfileCubit` must subscribe to `AuthCubit` sign-out events (or expose `reset()` called from `_logout`). Pattern already used by `VehicleCubit.clearVehicles()`.

---

## Next agent needs to know

- **Backend (rideglory-api):** No changes. Skip phase or write a one-liner handoff.
- **Frontend:** Implement `GetMyProfileUseCase` + `ProfileCubit` + redesigned `profile_page.dart` per `docs/handoffs/architect-for-frontend.md`. Add l10n keys. Register cubit in DI and root provider. Hook reset on logout.
- **DevOps:** No CI/env changes required. Track DevOps (CI/CD pipeline) is parallel, not blocking.
- **QA:** Test infrastructure tasks (US-1-1/2/3) gate the iteration. After frontend lands, write `ProfileCubit` blocTest group (5 states) and a `profile_page` widget test for all `ResultState` branches.
- **Tech lead:** Runs code review (US-1-5) first per PO ordering. Architect will not re-review unless tech_lead surfaces an architectural concern.

---

## Change log

- 2026-05-12 (iter-1): Initial architect handoff. Confirmed no backend changes. Defined ProfileCubit scope (ADR-1) and no-photo-upload (ADR-2). No new DTOs / endpoints / env vars.
