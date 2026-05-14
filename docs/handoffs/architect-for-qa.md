> Slim handoff — read this before docs/handoffs/architect.md

# Architect → QA — Iteration 1

**Iter-1 = presentation-layer redesign across 15 screens. Quality gate is "no regression + no new lint violations + smoke tests green".**

## Test commands

```bash
# Static analysis (must be green per PR and on final feature branch)
dart analyze

# Unit + widget tests (must be green per PR and on final feature branch)
flutter test

# Single test (debugging)
flutter test test/<path>_test.dart

# Format check (advisory)
dart format --output=none lib/
```

No `dart run build_runner` invocation needed — no codegen source changes this iteration.

## Baseline gate (T-1-8) — DO FIRST

Before any iter-1 PR merges:

```bash
git checkout main
flutter pub get
dart analyze 2>&1 | tee /tmp/dart_analyze_main.txt
flutter test 2>&1 | tee /tmp/flutter_test_main.txt
git checkout iter-1
```

Document the **count** of pre-existing `dart analyze` issues from `/tmp/dart_analyze_main.txt` in your QA handoff. Iter-1 acceptance: count must NOT grow on `iter-1` branch after final merge.

Also record the test count baseline (`flutter test --reporter expanded` shows totals). Final `iter-1` test count must be ≥ baseline (the 3 events widget tests are updated, not removed).

## Final gate (T-1-9) — Acceptance criteria traceability

| AC | Criterion | Verification command/check |
|----|-----------|---------------------------|
| US-1-11 / DoD #1 | `dart analyze` zero new violations | `dart analyze` on `iter-1` HEAD; diff against baseline |
| US-1-11 / DoD #2 | All 10 existing `flutter test` cases pass | `flutter test` on `iter-1` HEAD |
| US-1-11 / DoD #3 | No hardcoded color literals in `lib/features/` | `grep -rE "Color\(0x" lib/features/` returns 0 lines; `grep -rE "Colors\.(?!transparent\b\|black\b\|white\b)" lib/features/` returns 0 lines |
| US-1-11 / DoD #4 | All ARB updates committed | `git diff main..iter-1 -- lib/l10n/app_es.arb` non-empty; `lib/l10n/app_localizations*.dart` regenerated and committed |
| US-1-11 / DoD #5 | All 3 events widget tests updated in same PR as widget swap | review PR 3 (events) for paired test+widget changes |
| US-1-11 / DoD #6 | No new backend endpoints / domain models / routes / DI changes | `git diff main..iter-1 -- 'lib/**/domain/' 'lib/**/data/' 'lib/core/di/' 'lib/shared/router/'` returns empty |

## 5 Manual smoke tests (mandatory, log results)

Run on physical device or emulator after PR 5 merges into `iter-1`. Capture screenshot + result for each.

| # | Smoke | Pass criteria |
|---|-------|---------------|
| a | AI cover generation (event form) | Open Create Event → fill required fields → tap "Generar portada IA" → 2×2 grid renders → tap one image → save event → event created with selected cover URL |
| b | Event detail CTA state variants | Verify CTA bar in 4 states: not registered (Inscribirse), pending approval (Pendiente), registered+approved (Inscrito + Cancelar), event closed/full (correct disabled copy) |
| c | Maintenance donut chart rendering | Open Maintenance dashboard → donut chart renders with 3 urgency colors (red/yellow/green); no overflow exceptions in console |
| d | Home bottom nav pill bar matches frame `VMmN0` | Visual verification: pill shape, active item indicator, icon + label sizing, safe-area padding |
| e | Mapbox route preview in event form | Create Event → set start + end city → route preview renders polyline/line layer; no map crash, no missing-token error |

Stop the gate if any smoke test fails — open BUG task and route back to frontend.

## Architectural quality gates QA must enforce in PR review checklist

- No imports of `lib/features/<f>/data/` from any `lib/features/<f>/presentation/` file (except the existing 3 references to `colombia_motos_brands_data.dart` — frozen, do not grow).
- No new file under `lib/features/*/data/` or `lib/features/*/domain/` introduced this iter.
- No edits to `lib/core/di/injection.dart` other than (a) regenerated `injection.config.dart` (which should NOT regenerate this iter — flag if it appears in diff).
- No edits to `lib/shared/router/app_router.dart`.

## Tests NOT required this iteration

- New widget tests for redesigned screens — DO NOT write them (PO scope explicitly defers test infrastructure expansion).
- New BLoC tests — same reason.
- E2E / integration tests — out of scope.

> Full detail: docs/handoffs/architect.md
