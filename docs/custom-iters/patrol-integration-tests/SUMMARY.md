# Summary — patrol-integration-tests

## Goal
Add Patrol integration tests for Events, Profile, and Home features of Rideglory, following the proven pattern established by vehicles_patrol_test.dart.

## What changed

**New integration tests (integration_test/)**
- `events_patrol_test.dart` — navigates to Events tab after login; verifies events screen loads (page title, empty state, or error icon)
- `profile_patrol_test.dart` — navigates to Profile tab after login; verifies "Mi perfil" AppBar title and optionally checks profile content
- `home_patrol_test.dart` — verifies Home dashboard renders after login (bottom nav sentinel + content sections)
- `test_bundle.dart` — bundle entry for running all integration tests together

**Post-QA fixes applied**
- `home_patrol_test.dart`: corrected `$('Mi garaje')` → `$('MI GARAJE')` and `$('Ver todas')` → `$('VER TODAS')` (widgets render via `.toUpperCase()`)
- `profile_patrol_test.dart`: corrected `$('Error al cargar el perfil')` → `$('No pudimos cargar tu perfil')` (matches actual ARB key `profile_loadingError`)
- `events_patrol_test.dart`: removed trivially-true `hasTabLabel` from OR-assertion; test now only accepts meaningful page-content signals (`hasPageTitle || hasEmpty || hasError`)

**Docs (docs/custom-iters/patrol-integration-tests/)**
- `handoffs/frontend.md`, `handoffs/qa.md`, `handoffs/tech_lead.md` — phase handoffs
- `DECISIONS.md` — finder decisions and fix-pass notes
- `SUMMARY.md`, `REVIEW_CHECKLIST.md` (this close-out)
- `contracts/po_close.json`

## Files created/modified

```
integration_test/events_patrol_test.dart   (new)
integration_test/profile_patrol_test.dart  (new)
integration_test/home_patrol_test.dart     (new)
integration_test/test_bundle.dart          (new)
integration_test/vehicles_patrol_test.dart (pre-existing, unmodified — reference baseline)
docs/custom-iters/patrol-integration-tests/ (new tree)
```

Note: `git diff --stat` also shows pre-existing dirty-tree changes to `android/`, `ios/`, `lib/core/http/api_base_url_resolver.dart`, `pubspec.yaml`, and `rideglory.pen` — these are unrelated to this iteration and were present before it started (`preExistingDirtyTree: true` in _meta.json).

## Test results

| Test file | Status | Fix pass needed | Run time (approx) |
|-----------|--------|-----------------|-------------------|
| events_patrol_test | PASS | Yes — removed trivially-true `hasTabLabel` assertion | ~68s |
| profile_patrol_test | PASS | Yes — corrected error message string | ~71s |
| home_patrol_test | PASS | Yes — corrected 2 uppercase string checks | ~60s |
| vehicles_patrol_test | PASS (baseline) | No — unmodified reference | — |

## Key lessons documented

From DECISIONS.md — important discoveries about the codebase:

1. **Active tab icon is filled, not outlined** — after login the Home tab shows `Icons.home` (filled). The sentinel for "Home is loaded" must be an _inactive_ tab's outlined icon (e.g., `Icons.directions_car_outlined` for Garage).
2. **Bottom nav labels are `.toUpperCase()`** — "EVENTOS", "GARAJE", "INICIO", "PERFIL". Any test asserting on nav labels must uppercase them.
3. **Home section titles and action labels also use `.toUpperCase()`** — `_SectionHeader` in `HomeGarageSection` applies `.toUpperCase()` to both `title` ("MI GARAJE") and `viewAllLabel` ("VER TODAS").
4. **Events page has no AppBar** — the "Eventos" title is a plain `Text` in the body, not guaranteed to be visible immediately after navigation. `pumpAndSettle(20s)` is needed before soft checks.
5. **Profile page has a stable AppBar** — `AppAppBar(title: 'Mi perfil')` is always rendered regardless of loading/error state; safe to `waitUntilVisible` on it.
6. **`waitUntilVisible` on network-dependent content times out** — use `pumpAndSettle` with a long timeout followed by `.exists` soft checks for any widget that depends on an API response.
7. **Filled active tab icon may not be hit-testable** right after a tab switch; avoid relying on it as a sentinel.

## Risks / regression watchlist

From tech_lead review:

- **No source code was modified** — no regression risk from this iteration's changes.
- **Credential injection at runtime** — tests require `--dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...`. If the test account (`usuario2@gmail.com`) is deleted or its password changes, all three tests will fail at the login step.
- **Emulator dependency** — tests target `emulator-5554` by convention. Running on a physical device or a differently-named emulator requires updating `--device-id`.
- **Transient flakiness on back-to-back sessions** — `events_patrol_test` showed one flaky run on rapid succession due to emulator warmup. Allow emulator to settle between runs.
- **OR-assertion breadth** — all three tests use OR-assertions over "data loaded / empty state / error state" outcomes. This is acceptable for smoke tests but is not a substitute for unit-level state testing.

## Recommended commit message

```
feat(tests): add Patrol e2e tests for events, profile, and home features

Add three Patrol integration tests covering the main app flows after login:
- events_patrol_test: navigates to Events tab, verifies list or empty state
- profile_patrol_test: navigates to Profile tab, verifies user profile loads
- home_patrol_test: verifies Home screen content after login

Fixes applied after QA review:
- Correct .toUpperCase() strings in home test (MI GARAJE, VER TODAS)
- Correct ARB string in profile error check
- Remove trivially-true nav-label assertion from events test

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## How to run all tests

```bash
patrol test -t integration_test/events_patrol_test.dart --device-id emulator-5554 --dart-define=TEST_EMAIL=usuario2@gmail.com --dart-define=TEST_PASSWORD=Test123.
patrol test -t integration_test/profile_patrol_test.dart --device-id emulator-5554 --dart-define=TEST_EMAIL=usuario2@gmail.com --dart-define=TEST_PASSWORD=Test123.
patrol test -t integration_test/home_patrol_test.dart --device-id emulator-5554 --dart-define=TEST_EMAIL=usuario2@gmail.com --dart-define=TEST_PASSWORD=Test123.
```
