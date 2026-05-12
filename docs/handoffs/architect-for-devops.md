# Architect → DevOps Handoff — Iteration 2

No changes required.

The CI/CD pipeline from Iteration 1 (`.github/workflows/ci.yml`) handles iter-2 automatically:
- `dart analyze` and `flutter test` run on push to `iter-2` branch.
- No new environment variables, secrets, or build steps needed for event filters or rider profile.
- `dart run build_runner build` is not part of CI (generated files are committed) — no change.
