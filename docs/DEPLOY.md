# Deployment Guide — Rideglory Flutter

**Last updated:** 2026-05-14  
**Iteration:** 1

## Overview

Rideglory is built with Flutter (iOS and Android) and backed by a NestJS API (`rideglory-api` repository). This guide covers environment setup, CI/CD configuration, and release procedures.

---

## Environment Variables

### `.env` file (local development and CI injection)

Create a `.env` file in the project root with the following keys. All are required for the app to build and run.

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `FIREBASE_ANDROID_API_KEY` | Firebase Android API key from google-services.json | `AIzaSy...` | Yes |
| `FIREBASE_ANDROID_APP_ID` | Firebase Android app ID | `1:123456789:android:abcdef` | Yes |
| `FIREBASE_IOS_API_KEY` | Firebase iOS API key | `AIzaSy...` | Yes |
| `FIREBASE_IOS_APP_ID` | Firebase iOS app ID | `1:123456789:ios:abcdef` | Yes |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Cloud Messaging sender ID | `123456789` | Yes |
| `FIREBASE_PROJECT_ID` | Firebase project ID | `rideglory-prod` | Yes |
| `FIREBASE_STORAGE_BUCKET` | Firebase Cloud Storage bucket | `rideglory-prod.appspot.com` | Yes |
| `FIREBASE_ANDROID_CLIENT_ID` | Google Sign-In client ID (Android) | `123456789-abcdef.apps.googleusercontent.com` | Yes |
| `FIREBASE_IOS_CLIENT_ID` | Google Sign-In client ID (iOS) | `123456789-xyz.apps.googleusercontent.com` | Yes |
| `FIREBASE_IOS_BUNDLE_ID` | iOS app bundle identifier | `com.rideglory.app` | Yes |
| `LOCAL_API_BASE_URL` | Backend API base URL (dev/testing only) | `http://localhost:3000/api` | Yes |
| `UNSPLASH_ACCESS_KEY` | Unsplash API key for placeholder images (iter-4+) | `Ym9nWV...` | Yes |

### GitHub Actions Secrets

Store all `.env` values in GitHub Actions secrets with **identical names** to the `.env` keys above. The CI workflow injects them at build time.

Additionally, GitHub Actions requires:

| Secret | Purpose | Format | Required |
|--------|---------|--------|----------|
| `GOOGLE_SERVICES_JSON` | Firebase Android config file (`google-services.json`) base64-encoded | base64(google-services.json) | Yes |
| `GOOGLE_SERVICE_INFO_PLIST` | Firebase iOS config file (`GoogleService-Info.plist`) base64-encoded | base64(GoogleService-Info.plist) | Yes |

**To encode config files for GitHub Actions:**

```bash
# Android
cat android/app/google-services.json | base64 | pbcopy  # or xclip on Linux

# iOS
cat ios/Runner/GoogleService-Info.plist | base64 | pbcopy
```

Then paste the encoded string into GitHub Actions as a secret.

---

## Firebase Config Files (Local Development)

**Never commit Firebase config files.** They contain sensitive keys and are project-specific.

### Setup

1. Obtain `google-services.json` and `GoogleService-Info.plist` from your Firebase Console.
2. Place them in the repository:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. These files are in `.gitignore` and will not be committed.

### Example files

Placeholder/example files are committed to show the expected structure:
- `android/app/google-services.json.example`
- `ios/Runner/GoogleService-Info.plist.example`

To set up locally, copy and edit:

```bash
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

Then fill in real values from Firebase Console.

---

## CI/CD Pipeline

### GitHub Actions Workflow

**File:** `.github/workflows/ci.yml`

#### Triggers

- **Push to `iter-*` branches** — runs full CI suite (`dart analyze` + `flutter test`)
- **Push to `main` branch** — runs full CI suite
- **Pull request to `main`** — runs full CI suite (required status check)
- **Version tags** (`v*`) — triggers APK build job

#### Jobs

**1. `analyze-and-test` (required gate)**

Runs on every push to `iter-*` or `main`, and every PR to `main`.

Steps:
1. Checkout code
2. Setup Flutter (stable, cached)
3. Inject `.env` from `ENV_FILE` (not used in iter-1, but ready for future)
4. Inject `google-services.json` from `GOOGLE_SERVICES_JSON` secret (base64-decoded)
5. Inject `GoogleService-Info.plist` from `GOOGLE_SERVICE_INFO_PLIST` secret (base64-decoded)
6. `flutter pub get`
7. `dart run build_runner build --delete-conflicting-outputs` (code generation)
8. `dart analyze` — **fails if violations found**
9. `flutter test` — **fails if tests fail**

#### Exit codes

- Exit 0: All checks pass. PR can merge.
- Exit 1: `dart analyze` violation or `flutter test` failure. PR blocked.

**2. `build-apk` (optional, version tags only)**

Triggers only on tags matching `v*` (e.g., `v1.0.0`).

Steps: Same setup as above, then:
- `flutter build apk --release` — builds optimized APK
- Uploads artifact (retained for 30 days)

---

### Local Development CI Simulation

Before pushing, run the same checks locally to avoid CI failures:

```bash
# Full CI simulation
dart analyze && flutter test && flutter build apk --release

# Or individual steps
dart analyze              # Check for lint violations
flutter test              # Run all unit/widget tests
flutter build apk         # Build debug APK (faster for testing)
```

---

## Release Workflow

### Creating a Release

1. **Increment version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1  # Major.Minor.Patch+Build
   ```

2. **Tag the commit:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **CI automatically builds APK:**
   - GitHub Actions `build-apk` job triggers
   - Produces `app-release.apk`
   - Artifact available in Actions tab for 30 days

4. **Manual distribution (future):**
   - Download APK from Actions artifacts
   - Upload to Google Play Console (internal testing / beta / production)
   - Or distribute via TestFlight (iOS requires manual IPA build and provisioning)

### Version naming convention

- **Major:** Feature releases (e.g., `1.0.0` = first release, `2.0.0` = major redesign)
- **Minor:** Features or significant updates (e.g., `1.1.0` = new event filters)
- **Patch:** Bug fixes (e.g., `1.0.1` = UI fix)
- **Build:** Internal build number (incremented for each test/internal release)

Example: `1.2.3+42` = v1.2.3, build 42

---

## Dependencies & Code Generation

### Build Runner

`dart run build_runner build --delete-conflicting-outputs`

Generates:
- `*.g.dart` files from `json_serializable` (DTOs)
- `*.freezed.dart` files from `freezed` (immutable models)
- `*.config.dart` from `injectable` (DI registration)
- `*.retrofit.dart` from `retrofit` (REST clients)

**When to run:**
- After adding/modifying `.env` keys (re-generates `AppEnv`)
- After modifying Retrofit service interfaces
- After modifying freezed models or serializable DTOs
- After modifying DI configuration

**Typically run by:**
- Flutter developers during feature implementation
- CI pipeline before `dart analyze`
- DevOps in GitHub Actions (see `.github/workflows/ci.yml`)

### Localization

`flutter gen-l10n`

Generates:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_es.dart`

**Source:** `lib/l10n/app_es.arb`

Usually runs automatically with `flutter pub get`, but can be manually triggered.

---

## Secrets Configuration (GitHub Actions)

### Setup Instructions

1. Navigate to repository **Settings** → **Secrets and variables** → **Actions**

2. Add repository secrets:

   - `FIREBASE_ANDROID_API_KEY`
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_IOS_API_KEY`
   - `FIREBASE_IOS_APP_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_STORAGE_BUCKET`
   - `FIREBASE_ANDROID_CLIENT_ID`
   - `FIREBASE_IOS_CLIENT_ID`
   - `FIREBASE_IOS_BUNDLE_ID`
   - `LOCAL_API_BASE_URL`
   - `UNSPLASH_ACCESS_KEY`
   - `GOOGLE_SERVICES_JSON` (base64-encoded)
   - `GOOGLE_SERVICE_INFO_PLIST` (base64-encoded)

3. CI workflow automatically injects them during build.

### Verification

To verify secrets are set correctly:

1. Run a test build: `git push origin <branch>`
2. Open Actions tab on GitHub
3. Check for "missing secret" errors in logs
4. If errors, update secrets and retry

---

## Troubleshooting

### CI Build Fails with "Missing secret"

**Cause:** GitHub Actions secret not configured.  
**Solution:** Add the secret to GitHub Actions settings (see Secrets Configuration above).

### `dart analyze` fails locally but passes in CI

**Cause:** Different Dart SDK versions or cached issues.  
**Solution:** 
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
dart analyze --no-summary
```

### `flutter test` fails with stale `.g.dart`

**Cause:** Code generation files out of sync.  
**Solution:**
```bash
dart run build_runner rebuild --delete-conflicting-outputs
flutter test
```

### Firebase config files missing

**Cause:** `google-services.json` or `GoogleService-Info.plist` not copied locally.  
**Solution:**
```bash
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
# Edit with real values from Firebase Console
```

### APK build hangs or times out

**Cause:** First build takes 3-5 minutes; CI timeout too short.  
**Solution:** Check GitHub Actions job timeout (default 360 minutes for ubuntu-latest is sufficient).

---

## Platform-Specific Notes

### Android

- **Min SDK:** API 21 (Android 5.0)
- **Build tools version:** Configured in `android/app/build.gradle`
- **Keystore:** Not configured in this guide (manual signing required for Play Store)
- **Manifest:** Permissions in `android/app/src/main/AndroidManifest.xml`

### iOS

- **Min OS:** iOS 13
- **Xcode:** Version 14+
- **Provisioning profile:** Required for device testing and distribution (manual setup)
- **Signing:** Handled by Xcode (Debug) or Apple Developer account (Release)

---

## Roadmap: Future Deployments

### Iter-2 (SOAT + Notifications) — ACTIVE

**Status:** CI pipeline confirmed operational. No GitHub Actions workflow changes required. Flutter dependencies (`firebase_messaging`, `flutter_local_notifications`) already declared in pubspec.yaml.

**Backend setup (rideglory-api):**
- New env var: `DATABASE_URL` in `api-gateway/.env` (Prisma connection string, format: `postgresql://user:password@host:port/database`)
- Docker Compose: Verify Postgres service is reachable from api-gateway container; use Docker Compose DB as target or external RDS instance
- `prisma init` + `prisma migrate dev` executed in api-gateway (first-time Prisma setup, distinct from `prisma migrate reset` on 4 existing services)
- Firebase Admin SDK: Already installed; no additional packages needed

**Pre-flight checklist (backend agent):**
- [ ] Docker Compose Postgres service running or external DB configured
- [ ] `DATABASE_URL` set in `api-gateway/.env` and `.env.example`
- [ ] `prisma init` + `prisma migrate dev` completed in api-gateway
- [ ] GET /api/notifications returns 200 (empty list)

**iOS APNs setup (frontend agent pre-flight):**
- Upload APNs Authentication Key (.p8) to Firebase Console → Project Settings → Cloud Messaging
- Xcode: enable Push Notifications capability + Background Modes → Remote notifications on Runner target
- `ios/Runner/Info.plist`: `flutter_local_notifications` foreground options configured (handled in code)

**Android native config (frontend agent pre-flight):**
- `android/app/src/main/AndroidManifest.xml`: default notification channel + `POST_NOTIFICATIONS` runtime permission (Android 13+)
- Verified during build; no CI changes required

**CI notes:**
- No new GitHub Actions secrets needed (Firebase config sufficient)
- `flutter pub get` picks up `firebase_messaging` and `flutter_local_notifications` automatically
- Cocoapods cache not yet busted (iOS notification binaries < 100MB, minimal impact)

### Iter-3 (Mapbox Migration)

- Mapbox token injection: `MAPBOX_ACCESS_TOKEN` secret
- After Story 3.0 merge: Update Cocoapods cache key in CI (~200MB binary framework)
- Native config: AndroidManifest.xml + Info.plist Mapbox meta-data

### Iter-4/5 (Deep Links + Apple Sign-In)

- Deep link domain: assetlinks.json + apple-app-site-association deployment
- Apple Developer Portal: Apple Sign-In entitlement setup
- Firebase Hosting or backend API: serve deep link fallback pages

---

## Support & Questions

For issues related to:
- **Build failures:** See [Troubleshooting](#troubleshooting) or check GitHub Actions logs
- **Secrets configuration:** See [Secrets Configuration](#secrets-configuration-github-actions)
- **Firebase setup:** Consult your Firebase Console project settings
- **Platform-specific:** Refer to Flutter docs for [Android](https://flutter.dev/docs/deployment/android) and [iOS](https://flutter.dev/docs/deployment/ios)
