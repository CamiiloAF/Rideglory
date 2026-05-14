> Slim handoff — read this before docs/handoffs/architect.md

# Architect → DevOps — Iteration 1

## TL;DR

**No CI/CD changes. No new env vars. No build configuration changes. No native config changes (Android/iOS).**

Iter-1 is presentation-layer-only across the Flutter app. Existing GitHub Actions pipeline (`dart analyze` + `flutter test` + APK/IPA build) is sufficient as-is.

## What does NOT change

- `pubspec.yaml` / `pubspec.lock` — no new packages, no version bumps.
- `.env` / `.env.example` — no new keys.
- `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml` — untouched.
- `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` — untouched.
- `firebase.json`, `google-services.json`, `GoogleService-Info.plist` — untouched.
- Firebase Remote Config keys — no additions.
- `build_runner` — not run this iteration (no codegen sources change).
- GitHub Actions workflow YAMLs — untouched.

## What DOES change

- **Branch protection on `iter-1`:** allow 5 sequential PRs to merge into the `iter-1` feature branch. Reviewers: 1 approval + tech_lead sign-off per PR. `dart analyze` + `flutter test` must be green per PR (already enforced by existing CI).
- **DEPLOY.md:** no edits required this iter — no infra additions.

## Pre-flight DevOps checklist (this iteration)

- [ ] Confirm `iter-1` branch protection allows the 5-PR cadence.
- [ ] Confirm CI runs on every PR into `iter-1` (not only into `main`).
- [ ] No additional steps.

## Looking ahead (iter-2)

DevOps WILL be active in iter-2. Heads-up:
- New Flutter packages: `firebase_messaging ^15.x`, `flutter_local_notifications`.
- iOS: APNs key + Push Notifications capability in Xcode.
- Android: notification channel config; FCM service.
- api-gateway first-time Prisma setup → DATABASE_URL in api-gateway env, Docker Compose network coordination.
- New backend env: none externally exposed yet (Firebase Admin already installed).

> Full detail: docs/handoffs/architect.md
