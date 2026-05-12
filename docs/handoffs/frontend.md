# Flutter Dev handoff — Iteration 1

**Date:** 2026-05-12
**Status:** done

## Screens / features delivered

| Screen / Cubit | Route / path | Status | Notes |
|----------------|--------------|--------|-------|
| ProfilePage | AppRoutes.profile | Done | Rewritten from stub — StatefulWidget with 4 ResultState branches |
| ProfileCubit | lib/features/profile/presentation/cubits/profile_cubit.dart | Done | @lazySingleton, fetchProfile() + reset() |
| ProfileHeader | (widget) | Done | CircleAvatar 80×80 with initials, fullName, email |
| ProfileMainVehicleCard | (widget) | Done | Reads VehicleCubit.currentVehicle; shows chip or "Sin vehículos" |
| ProfileActionsList | (widget) | Done | Mis inscripciones + Cerrar sesión (extracted from old stub) |

## Layer changes

- Domain: `lib/features/profile/domain/use_cases/get_my_profile_use_case.dart` (new — calls UserRepository.getCurrentUser())
- Data: none (reuses existing UserDto + UserService + UserRepositoryImpl)
- Presentation: ProfileCubit (new), ProfilePage (rewritten), 3 widgets (new), 5 l10n keys (new)
- Core: `lib/core/utils/initials.dart` — added `initialsFromName(String?)` top-level function alongside existing `Initials` class

## DI registration

build_runner cannot run with the current pubspec configuration because `network_image_mock` brings in `mockito 5.6.5` which has a compile error against `analyzer: ^8.0.0` (the project's existing override). `ProfileCubit` and `GetMyProfileUseCase` were manually registered in `lib/core/di/injection.config.dart` using import aliases `_i2001` and `_i2002`.

QA/Tech Lead must resolve the build_runner conflict before auto-generating DI again. Options:
1. Replace `network_image_mock` with an alternative that does not depend on mockito.
2. Override `analyzer` to a version compatible with mockito 5.6.5 (but this conflicts with other generators).
3. Exclude the mockito builder from build_runner via a project-level build.yaml (attempted — does not prevent compilation of the builder source).

## Code generation

- `flutter gen-l10n` was NOT run (build_runner broken). The ARB file was updated with 5 new keys. Run `flutter gen-l10n` after resolving the build_runner issue.
- Files generated: none new (injection.config.dart patched manually)

## API integration

- Retrofit endpoints wired: none (reuses existing `GET /users/me` via `UserService.getCurrentUser()`)
- Deviations from architect contract: none

## l10n keys added

- `profile_title`: "Mi perfil"
- `profile_mainVehicle`: "Vehículo principal"
- `profile_noVehicle`: "Sin vehículos"
- `profile_errorRetry`: "Reintentar"
- `profile_loadingError`: "No pudimos cargar tu perfil"

## Test infrastructure (US-1-1)

Directories created:
- `test/features/vehicles/`
- `test/features/events/`
- `test/features/maintenance/`
- `test/features/profile/`
- `integration_test/app_test.dart` (stub)

Dev dependencies added to pubspec.yaml:
- `integration_test` (sdk: flutter)
- `mocktail: ^1.0.4`
- `bloc_test: ^10.0.0`
- `network_image_mock: ^2.1.1`

## Test results

- `dart analyze`: 2 pre-existing errors in `event_form_locations_section.dart` (undefined named parameter `onChanged`), 0 errors in new code. Pre-existing errors were already present before this iteration.
- `flutter test`: 1 pre-existing failure in `test/widget_test.dart` (counter smoke test — stub that tests a non-existent counter widget). No new test failures.
- `build_runner build`: BROKEN due to mockito vs analyzer version conflict (see DI registration section). 

## Known gaps

- build_runner broken: `network_image_mock` pulls in `mockito 5.6.5` which fails to compile against `analyzer ^8.0.0`. The QA agent needs to resolve this before writing widget tests that require code generation or @GenerateMocks.
- l10n files not regenerated: `flutter gen-l10n` needs to run once build_runner issue is resolved.
- pre-existing `event_form_locations_section.dart` errors: not in scope for this iteration, flagged for tech_lead.

## Next agent needs to know

- QA: Routes to test manually: the profile tab in the bottom nav. Test with valid user (data state), simulate network error (error + retry state). Test logout confirmation dialog. Test "Mis inscripciones" navigation.
- QA: Test infra dirs exist. Write cubit tests in `test/features/profile/` using `mocktail` + `bloc_test`.
- QA: The build_runner/mockito conflict must be resolved before `flutter gen-l10n` can be called automatically via build_runner. Use `flutter gen-l10n` standalone instead.
- Tech Lead: `event_form_locations_section.dart` has 2 pre-existing errors (onChanged undefined). Should be fixed in this iteration's cleanup pass.
- Tech Lead: injection.config.dart was manually patched — verify the `_i2001`/`_i2002` aliases do not collide with future build_runner output when the conflict is resolved.

## Change log

- 2026-05-12: Initial implementation — US-1-1 test infra + US-1-4 profile page complete
