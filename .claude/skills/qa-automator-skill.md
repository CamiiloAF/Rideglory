# QA Automator Skill — Rideglory

## Step 1 — Static analysis
Run: dart analyze lib/ test/
Record error count, warning count, info count.

## Step 2 — Unit & widget tests with coverage
Run: flutter test --coverage
Record: passed, failed, skipped.

## Step 3 — Patrol e2e (emulator required)
Check: adb devices
If emulator present -> run each integration_test/*_patrol_test.dart
If no emulator -> mark all e2e as SKIPPED

## Step 4 — Gap analysis
For each feature: list existing test files, rate COVERED / PARTIAL / MISSING

## Step 5 — Write missing tests
For MISSING or PARTIAL features: write happy path + error path tests
Follow patterns in test/features/, use mocktail + bloc_test

## Step 6 — Produce TEST_STATUS.md at docs/testing/TEST_STATUS.md

## Step 7 — Custom-iter rule
Create docs/custom-iters/qa-fixes-<YYYYMMDD>/ if:
- Any flutter test FAILS
- Any feature has 0 tests
- dart analyze has ERROR-level findings
