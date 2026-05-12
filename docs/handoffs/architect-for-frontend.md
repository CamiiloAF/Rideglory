> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Frontend — Iteration 1

**Focus:** US-1-4 only (Profile page completion). All other US-1-* are QA or tech_lead owned.

## Feature path
`lib/features/profile/`

```
profile/
  domain/
    use_cases/get_my_profile_use_case.dart      ← NEW
  presentation/
    cubit/profile_cubit.dart                    ← NEW
    profile_page.dart                           ← REWRITE (current is stub)
    widgets/                                    ← NEW dir (one widget per file)
      profile_header.dart                       ← name + email + initials avatar
      profile_main_vehicle_card.dart            ← reads VehicleCubit
      profile_actions_list.dart                 ← extracted from existing stub (registrations + logout)
```

## Models / DTOs
- **No new models.** Reuse `UserModel` from `lib/features/users/domain/model/user_model.dart`.
- **No new DTOs.** `UserDto` + `UserService.getCurrentUser()` already wired.
- **No Retrofit changes.**

## Cubit pattern
```dart
@lazySingleton
class ProfileCubit extends Cubit<ResultState<UserModel>> {
  ProfileCubit(this._getMyProfile) : super(const ResultState.initial());
  final GetMyProfileUseCase _getMyProfile;

  Future<void> fetchProfile() async {
    emit(const ResultState.loading());
    final result = await _getMyProfile();
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (user) => emit(ResultState.data(data: user)),
    );
  }

  void reset() => emit(const ResultState.initial());
}
```

- `GetMyProfileUseCase` returns `Future<Either<DomainException, UserModel>>` and delegates to `UserRepository.getCurrentUser()`.
- Trigger `fetchProfile()` in `initState` of a `StatefulWidget` wrapping `ProfilePage`, or via `BlocProvider.value` + `.fetchProfile()` on first build.

## DI registration
- Run `dart run build_runner build --delete-conflicting-outputs` after adding `@injectable` / `@lazySingleton` annotations.
- Add `ProfileCubit` to the root `MultiBlocProvider` in `main.dart`, beside `AuthCubit` and `VehicleCubit`.
- On logout (`_logout` in `profile_page.dart`), call `context.read<ProfileCubit>().reset()` before navigating away.

## UI requirements (acceptance criteria recap)
- Initial state on entry: trigger `fetchProfile()` → shimmer skeleton while `loading`.
- `data`: show `fullName`, `email`, initials avatar (two-letter `CircleAvatar` derived from `fullName`; fallback to `?` if null).
- Main vehicle: read from existing `VehicleCubit`; if main vehicle present show name+model; if `empty` show `EmptyStateWidget` or inline `Sin vehículos`.
- `error`: error banner + retry button calling `fetchProfile()`.
- No raw `Material` widgets where a shared equivalent exists (`AppButton`, `AppTextField`, `AppAppBar`, `EmptyStateWidget`).

## l10n keys to add to `lib/l10n/app_es.arb`
| Key | Suggested Spanish |
|-----|--------------------|
| `profile_title` | "Mi perfil" |
| `profile_mainVehicle` | "Vehículo principal" |
| `profile_noVehicle` | "Sin vehículos" |
| `profile_errorRetry` | "Reintentar" |
| `profile_loadingError` | "No pudimos cargar tu perfil" |

Run `flutter gen-l10n` after editing the ARB.

## Initials helper
Place at `lib/core/utils/initials.dart` (so it can be reused in Iteration 2 attendee list):

```dart
String initialsFromName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '?';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}
```

## Gates before pushing
- `dart analyze` zero violations.
- `flutter test` green (QA writes the profile widget test post-frontend).
- No hardcoded Spanish in any new widget.

> Full detail: docs/handoffs/architect.md
