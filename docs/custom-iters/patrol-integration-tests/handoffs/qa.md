# QA Handoff — patrol-integration-tests

## Test catalog
| Test | AC | Status |
|------|----|--------|
| events_patrol_test | Events tab loads after login; title, empty state, or error is visible | PASS (with notes) |
| profile_patrol_test | Profile tab loads; AppBar title "Mi perfil" visible; content or error shown | CONDITIONAL — 1 string bug |
| home_patrol_test | Home screen renders after login; bottom nav + content sections visible | CONDITIONAL — 2 string bugs |

---

## Checklist results per test

### events_patrol_test.dart

| Check | Result | Notes |
|-------|--------|-------|
| Uses `$(TextField)` not `$(TextFormField)` | PASS | Line 40 |
| Handles location permission with `$.native.isPermissionDialogVisible()` | PASS | Lines 34, 45, 64, 77 — four guard points |
| Uses `waitUntilVisible()` before interacting | PASS | `waitUntilVisible` on `TextField` before entering text; `waitUntilVisible` on `calendar_today_outlined` before tapping tab |
| Meaningful assertions (not just `expect(true, isTrue)`) | CONDITIONAL | The `reason:` message is meaningful; however the assertion body is a 4-way OR (`hasPageTitle || hasTabLabel || hasEmpty || hasError`). Since `hasTabLabel = $('EVENTOS').exists` is almost always true after tab navigation, the assertion is structurally weak — any tab navigation lands here. Acceptable for a smoke test; would benefit from requiring `hasPageTitle` specifically. |
| Handles both "has data" and "empty state" | PASS | Accepts title, tab label, empty state text, or error icon |
| Timeout set to `Duration(minutes: 3)` or similar | PASS | Line 28 |
| l10n string accuracy | PASS | `event_events: "Eventos"`, `event_noEvents: "No hay eventos disponibles"` — both correct |
| Imports correct, no unused imports | PASS | Imports: `flutter/material.dart`, `flutter_test`, `patrol`, `rideglory/main.dart` — all used |
| Credentials via `String.fromEnvironment` | PASS | Lines 15–22 |

### profile_patrol_test.dart

| Check | Result | Notes |
|-------|--------|-------|
| Uses `$(TextField)` not `$(TextFormField)` | PASS | Line 40 |
| Handles location permission | PASS | Lines 34, 45, 64, 77 — four guard points |
| Uses `waitUntilVisible()` before interacting | PASS | `waitUntilVisible` on `TextField` before login; `waitUntilVisible` on `person_outline` before tab tap; `waitUntilVisible` on `'Mi perfil'` before assertions |
| Meaningful assertions | PASS | Hard `expect($('Mi perfil'), findsOneWidget)` is a solid anchor assertion |
| Handles both "has data" and "empty/error state" | CONDITIONAL | Error state string is wrong — see Findings |
| Timeout set appropriately | PASS | `Duration(minutes: 3)` at line 28 |
| l10n string accuracy | FAIL | Line 96: `$('Error al cargar el perfil')` — the actual ARB value is `profile_loadingError: "No pudimos cargar tu perfil"`. The hardcoded string does not match. The soft check will never match on a real profile error, silently weakening the error-state branch. |
| Imports correct | PASS | `flutter/material.dart`, `flutter_test`, `patrol`, `rideglory/main.dart` — all used |
| Credentials via `String.fromEnvironment` | PASS | Lines 15–22 |

### home_patrol_test.dart

| Check | Result | Notes |
|-------|--------|-------|
| Uses `$(TextField)` not `$(TextFormField)` | PASS | Line 40 |
| Handles location permission | PASS | Lines 34, 45, 64, 81 — four guard points |
| Uses `waitUntilVisible()` before interacting | PASS | Correct sentinel: `$(Icons.directions_car_outlined).waitUntilVisible()` instead of inactive home icon |
| Meaningful assertions | CONDITIONAL | Two `expect` calls: first checks bottom nav exists (reliable); second checks greeting OR sections. The second could pass purely on `hasActiveHomeTab || hasGarageTab` from first block — see notes. |
| Handles both "has data" and "empty state" | PASS | Accepts greeting OR section headers — both valid post-login outcomes |
| Timeout set appropriately | PASS | `Duration(minutes: 3)` at line 28 |
| l10n string accuracy | FAIL (x2) | Bug 1 — Line 108: `$('Mi garaje')`. The UI renders `context.l10n.home_sectionGarage.toUpperCase()` → "MI GARAJE". The lowercase check will never find the widget. Bug 2 — Line 110: `$('Ver todas')`. The UI renders `context.l10n.home_viewAllLink.toUpperCase()` → "VER TODAS". Same issue. Line 109 `$('PRÓXIMAS RODADAS')` is correct — `home_sectionEvents` is uppercased. |
| Imports correct | PASS | All four imports are used |
| Credentials via `String.fromEnvironment` | PASS | Lines 15–22 |

---

## Findings

### BUG-1 — home_patrol_test.dart:108 — Wrong case for garage section title
- **Severity**: Medium
- **File**: `integration_test/home_patrol_test.dart`, line 108
- **Issue**: `$('Mi garaje').exists` will always be `false`. The widget renders `context.l10n.home_sectionGarage.toUpperCase()` = "MI GARAJE".
- **Fix**: Change to `$('MI GARAJE').exists`

### BUG-2 — home_patrol_test.dart:110 — Wrong case for "Ver todas" button
- **Severity**: Medium
- **File**: `integration_test/home_patrol_test.dart`, line 110
- **Issue**: `$('Ver todas').exists` will always be `false`. The garage section and events section both render their view-all labels via `.toUpperCase()` → "VER TODAS".
- **Fix**: Change to `$('VER TODAS').exists`

### BUG-3 — profile_patrol_test.dart:96 — Wrong error message string
- **Severity**: Low–Medium
- **File**: `integration_test/profile_patrol_test.dart`, line 96
- **Issue**: `$('Error al cargar el perfil').exists` will never match. The ARB key `profile_loadingError` has value `"No pudimos cargar tu perfil"`, not `"Error al cargar el perfil"`.
- **Fix**: Change to `$('No pudimos cargar tu perfil').exists`

### NOTE-1 — events_patrol_test.dart — Assertion is broad (informational)
- **Severity**: Info
- **File**: `integration_test/events_patrol_test.dart`, lines 96–106
- **Issue**: The 4-way OR assertion accepts `hasTabLabel = $('EVENTOS').exists`, which is nearly always true after tapping the Events tab. This means the test cannot distinguish "Events page actually rendered" from "still on another screen". The page title `$('Eventos')` without the tab label would be a stronger anchor.
- **Recommended action**: Consider requiring `hasPageTitle || hasEmpty || hasError` and removing `hasTabLabel` from the OR, or add it only as a fallback with a stronger comment. Non-blocking for merge.

---

## Sign-off

**conditional** — Two bugs in `home_patrol_test` (wrong case for "Mi garaje" and "Ver todas") and one bug in `profile_patrol_test` (wrong error string) must be fixed before the iteration is considered fully green. The fixes are one-line each. All three tests are structurally correct and will pass because the overall OR-assertions still have valid branches; however the broken branches silently reduce coverage.
