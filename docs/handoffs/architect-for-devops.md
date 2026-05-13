> Slim handoff — read this before docs/handoffs/architect.md

# Architect → DevOps — Iteration 1

**Status:** No CI/env changes required by Iteration 1 product scope.

## Env vars
None added. `.env.example` unchanged.

## CI changes
Iteration 1 is a foundation iteration. The DevOps track (CI/CD pipeline with GitHub Actions) is a **parallel track** scheduled to run alongside Iteration 2 — not a blocker for Iteration 1.

If the DevOps agent runs anyway during this iteration, deliver:
- `.github/workflows/flutter-ci.yml` running on `push` to `iter-*` and `pull_request` to `main`.
- Steps: `actions/checkout`, `subosito/flutter-action`, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `dart analyze`, `flutter test`.
- Secrets needed (placeholders only this iter): `FIREBASE_OPTIONS_DEV`, `GOOGLE_SERVICES_JSON`, `GOOGLE_SERVICE_INFO_PLIST`, `ENV_DEV`. Files written from secrets before the build step.
- Cache Flutter SDK and pub cache.

## Build steps the project already needs
```bash
cp .env.example .env             # then fill values
dart run build_runner build --delete-conflicting-outputs
flutter pub get
dart analyze
flutter test
```

## Dev dependencies added this iteration (informational)
- `mocktail: ^1.0.4`
- `bloc_test: ^10.0.0`
- `network_image_mock: ^2.1.1`

These are dev-only; CI must run `flutter pub get` after the pubspec change but no extra steps.

## Coordination
- Iteration 3a will add `file_picker` (prod) — IPA/APK size implications minor; no CI change required.
- Iteration 6a adds `firebase_messaging` (prod) — APNs key + iOS push capability must be ready in CI secrets before that iteration.

> Full detail: docs/handoffs/architect.md
