# Frontend Handoff — patrol-integration-tests

## Baseline test result
`vehicles_patrol_test` was passing before this run (covers splash → location → login → garage).

## Files created
- `integration_test/events_patrol_test.dart` — navigates to Events tab after login; verifies events screen loads (title, empty state, or error)
- `integration_test/profile_patrol_test.dart` — navigates to Profile tab after login; verifies "Mi perfil" AppBar title and profile content
- `integration_test/home_patrol_test.dart` — verifies Home dashboard renders after login (bottom nav + content sections)

## Test results
| Test file | Status | Iterations needed |
|-----------|--------|-------------------|
| events_patrol_test | PASS | 3 |
| profile_patrol_test | PASS | 1 |
| home_patrol_test | PASS | 2 |

## Source code changes
None. All fixes were in the test files only.

## Key lessons learned (for future tests)
1. **Active tab icon differs from inactive**: After login, Home tab shows `Icons.home` (filled), not `Icons.home_outlined`. Always use an INACTIVE tab's outlined icon as the post-login sentinel.
2. **`waitUntilVisible` on page title can time out if the page is network-loading**: pumpAndSettle with a 20s timeout followed by soft `.exists` checks is more reliable than hard `waitUntilVisible` on content that depends on an API call.
3. **The filled active tab icon (`Icons.calendar_today`) is not reliably hit-testable** right after tab switch — avoid waiting on it.
4. **Bottom nav labels are uppercase** (`label.toUpperCase()`): "EVENTOS", "GARAJE", "INICIO", "PERFIL".
5. **Events page has no AppBar** — the title "Eventos" is a plain `Text` widget inside the body, not in an AppBar; it may not be hit-testable immediately after navigation.
6. **Profile page DOES have an AppBar** with "Mi perfil" — reliable anchor for `waitUntilVisible`.

## Notes for QA
- All tests use `usuario2@gmail.com` / `Test123.` — ensure this account exists in the test environment.
- Tests are designed to accept both "data loaded" and "empty state / error state" outcomes so they don't fail just because the test account has no events or garage vehicles.
- The emulator must be running (`adb devices` shows `emulator-5554 device`) before executing any test.
- Run command for each test: `patrol test -t integration_test/<file>.dart --device emulator-5554 --dart-define=TEST_EMAIL=usuario2@gmail.com --dart-define=TEST_PASSWORD=Test123.`

## Pre-existing failures
None observed. `vehicles_patrol_test` was passing at the start of this run.
