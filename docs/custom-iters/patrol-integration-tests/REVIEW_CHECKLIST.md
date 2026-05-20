# Review Checklist — patrol-integration-tests

## Phase chain
frontend → qa → tech_lead (fix pass) → po_close

## Pre-review
- [ ] Run `git diff --stat` to confirm only `integration_test/` and `docs/custom-iters/patrol-integration-tests/` were modified
- [ ] Confirm no `lib/` source files were changed

## Test verification (run each manually if desired)
- [ ] `events_patrol_test` passes: `patrol test -t integration_test/events_patrol_test.dart --device-id emulator-5554 --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...`
- [ ] `profile_patrol_test` passes: same pattern
- [ ] `home_patrol_test` passes: same pattern
- [ ] `vehicles_patrol_test` still passes (regression): same pattern

## Code review
- [ ] Each test uses `$(TextField)` not `$(TextFormField)` for login fields
- [ ] Each test handles location permissions (four guard points per test)
- [ ] Strings match `lib/l10n/app_es.arb` exactly
  - [ ] `home_patrol_test`: "MI GARAJE" and "VER TODAS" (uppercased)
  - [ ] `profile_patrol_test`: "No pudimos cargar tu perfil" (matches `profile_loadingError`)
  - [ ] `events_patrol_test`: assertion is `hasPageTitle || hasEmpty || hasError` (no `hasTabLabel`)
- [ ] No hardcoded credentials — all use `String.fromEnvironment('TEST_EMAIL')` / `String.fromEnvironment('TEST_PASSWORD')`
- [ ] Default values are non-functional placeholders (`'tu_email@ejemplo.com'` / `'tu_password'`)

## If accepted
```bash
git add integration_test/ docs/custom-iters/patrol-integration-tests/
git commit -m "$(cat <<'EOF'
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
EOF
)"
```

## If rejected
```bash
git restore integration_test/events_patrol_test.dart integration_test/profile_patrol_test.dart integration_test/home_patrol_test.dart integration_test/test_bundle.dart
```
