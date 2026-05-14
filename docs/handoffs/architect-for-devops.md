> Slim handoff — read this before docs/handoffs/architect.md

# Architect → DevOps — Iteration 2

DevOps is active this iteration. No GitHub Actions workflow YAML changes, but several config/native/env items need attention.

## New env vars

| Variable | Where | Notes |
|----------|-------|-------|
| `DATABASE_URL` | `rideglory-api/api-gateway/.env` (+ `.env.example`) | api-gateway gets Prisma for the first time. Must match the Docker Compose Postgres service. Add the new DB to Docker Compose if a separate database per service is the convention. |

No new Flutter `.env` keys — FCM uses existing `google-services.json` / `GoogleService-Info.plist`.

## New packages

- Flutter (`pubspec.yaml`): `firebase_messaging ^15.x`, `flutter_local_notifications ^17.x/^18.x`, optional `file_picker ^8.x`. CI `flutter pub get` picks these up automatically — no workflow change.
- Backend (`api-gateway/package.json`): `@nestjs/schedule`. `firebase-admin` already present.

## iOS native config (APNs — required for iOS push)

- Upload an **APNs Authentication Key** (.p8) to Firebase Console → Project Settings → Cloud Messaging.
- Xcode: enable **Push Notifications** capability + **Background Modes → Remote notifications** on the Runner target.
- `ios/Runner/Info.plist`: `flutter_local_notifications` may need foreground presentation options — frontend handles in code, but verify build.
- Without APNs setup iOS push fails silently. This is a pre-flight gate for stories 2.4/2.5/2.6.

## Android native config

- `android/app/src/main/AndroidManifest.xml`: `flutter_local_notifications` requires a default notification channel + (Android 13+) the `POST_NOTIFICATIONS` runtime permission entry. Frontend wires the channel in Dart; confirm manifest entries build.
- FCM background handler is pure Dart (`@pragma('vm:entry-point')`) — no native service class needed.

## api-gateway Prisma first-time setup (pre-flight, T-2-2)

- This is `prisma init` + `prisma migrate dev`, NOT `migrate reset`.
- Docker Compose: ensure the api-gateway can reach a Postgres instance; configure `DATABASE_URL` accordingly. Watch for port conflicts with the 4 existing per-service databases.
- Document the exact `DATABASE_URL` and any Docker Compose change in the iter-2 pre-flight runbook / `DEPLOY.md`.

## CI/CD

- Existing pipeline (`dart analyze` + `flutter test` + APK/IPA build) stays. No workflow YAML edits.
- `build_runner` runs locally (codegen output is committed); CI does not need a codegen step unless that is already the convention.
- `DEPLOY.md`: add the api-gateway `DATABASE_URL` requirement and the APNs key setup step.

## Pre-flight DevOps checklist

- [ ] `DATABASE_URL` added to api-gateway `.env` + `.env.example`; Docker Compose DB reachable.
- [ ] APNs .p8 key uploaded to Firebase Console; Xcode Push + Remote-notification capabilities enabled.
- [ ] Android notification channel + `POST_NOTIFICATIONS` manifest entry verified after frontend wiring.
- [ ] `@nestjs/schedule` installed in api-gateway.
- [ ] `DEPLOY.md` updated.

> Full detail: docs/handoffs/architect.md
