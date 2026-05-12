> Slim handoff — read this before docs/handoffs/architect.md

# Architect → QA — Iteration 1

QA owns the majority of this iteration (US-1-1, US-1-2, US-1-3, plus the QA gate T-1-6).

## Test commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only if mocks/freezed touched
dart analyze --no-summary                                    # must be zero violations
flutter test                                                 # must be 100% green
flutter test test/features/profile/                          # focused run after frontend lands
```

## Acceptance criteria → test traceability

### US-1-1 — Test infra bootstrap
- Verify `pubspec.yaml` dev_dependencies: `mocktail: ^1.0.4`, `bloc_test: ^10.0.0`, `network_image_mock: ^2.1.1`.
- Verify directory tree per PO handoff (10 dirs minimum).
- `flutter pub get` resolves cleanly.
- `dart analyze` zero violations.

### US-1-2 — Cubit blocTest groups
- `VehicleCubit`: 5 cases — initial, loading, data, empty, error.
- `EventsCubit`, `EventDetailCubit`: same 5 cases each.
- `MaintenancesCubit`: 4 cases — initial, loading, data, error.
- Mock pattern: `class MockXRepository extends Mock implements XRepository`.
- Use `bloc_test`'s `blocTest<Cubit, State>` with `seed`, `act`, `expect`.

### US-1-3 — Widget tests + integration stubs
- Vehicle garage page: shimmer, data (vehicle card), empty (`EmptyStateWidget`), error+retry.
- Event list page: shimmer, data (event card), empty, error.
- Event detail page: shimmer, data (event title), error.
- Wrap any test that uses `CachedNetworkImage` with `mockNetworkImages()`.
- Use `MockBloc`/`MockCubit` from `bloc_test`; never real HTTP.
- Create stub integration files (one `group` each):
  - `integration_test/auth_flow_test.dart`
  - `integration_test/vehicles_flow_test.dart`
  - `integration_test/events_flow_test.dart`

### US-1-4 — ProfileCubit + Profile page (validates after frontend)
- `ProfileCubit` blocTest group: initial, loading, data (UserModel), error (DomainException).
- Profile page widget test: loading shimmer, data (name + email + initials avatar visible), main-vehicle slot reads `VehicleCubit` (data + empty paths), error banner + retry tap calls `fetchProfile()` again.
- Verify no hardcoded Spanish — every visible string maps to a `profile_*` key in `app_es.arb`.

### US-1-5 — Code review gate (validates after tech_lead)
- Re-run `dart analyze` after tech_lead's commit — must be zero violations.
- Spot-check `lib/` for `print(` — must be zero in non-test code.
- Confirm `docs/architecture/code-review-iter1.md` exists with the findings table.

## QA gate (T-1-6) final check
1. `dart analyze --no-summary` → zero.
2. `flutter test` → 100% pass.
3. All `ResultState` branches covered by widget tests for vehicles/events/profile.
4. No hardcoded strings in any new UI (grep `lib/features/profile/` for raw Spanish literals).

## Mock conventions (carry forward)
- Repository mocks live in `test/features/<feature>/_mocks/` if reused; one-shot mocks inline.
- Register fallback values for `mocktail` with `registerFallbackValue` for any complex argument type.

> Full detail: docs/handoffs/architect.md
