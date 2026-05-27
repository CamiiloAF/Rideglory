> Slim handoff — read this before docs/handoffs/architect.md

# Architect → DevOps — Iteration 6 (refactor-01)

**Date:** 2026-05-27

---

## CI changes required this iteration: NONE

Iteration 6 is a pure Flutter internal refactor. The CI pipeline is unchanged.

- No new packages in `pubspec.yaml` — no new native SDK downloads
- No new environment variables
- No new build steps
- No new Xcode entitlements
- No new Android manifest entries
- No backend deployment

---

## Required CI gates (unchanged — reaffirmed)

The following gates must remain green throughout the iteration:

```yaml
# Step 1: analysis
- run: dart analyze lib/
  # Expected: 2 warnings in api_base_url_resolver.dart (accepted — do NOT fail on these)
  # 0 errors, 0 other warnings

# Step 2: tests
- run: flutter test
  # Expected: same pass count as pre-refactor baseline
  # TC-2-28 is a pre-existing failure — acceptable, do not fail CI on it
```

If CI is configured to fail on any `dart analyze` warning, an exception for `api_base_url_resolver.dart` lines 17–19 must be documented or the `--no-fatal-warnings` flag used specifically for those warnings. These 2 warnings are intentional out-of-scope artifacts.

---

## DevOps task: T-6-19

Verify CI passes on `iter-6` branch after frontend completes:
1. `dart analyze lib/` — 0 errors; 2 warnings in `api_base_url_resolver.dart` only (acceptable)
2. `flutter test` — no new failures vs. pre-refactor baseline
3. Confirm `pubspec.yaml` unchanged (no new packages, no version bumps)
4. Confirm no new build steps introduced

> Full detail: docs/handoffs/architect.md
