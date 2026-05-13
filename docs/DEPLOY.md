# Deployment & CI/CD — Rideglory Flutter

**Last Updated:** 2026-05-12  
**Status:** Iteration 1 — CI pipeline foundation

---

## Overview

Rideglory uses **GitHub Actions** to run automated CI/CD checks on every push and pull request. The pipeline ensures code quality through linting (`dart analyze`) and test coverage (`flutter test`) before merging.

This document covers:
1. Local development setup
2. GitHub Actions secrets configuration
3. CI/CD pipeline behavior
4. Manual build and release steps

---

## Local Development Setup

### Prerequisites

- Flutter 3.8.1+ (or stable channel)
- Dart 3.8.1+
- Android SDK (API 21+) for APK builds
- Xcode 15+ for iOS builds (future)

### Initial Setup

```bash
# Clone the repository
git clone <repo-url>
cd Rideglory

# Install dependencies
flutter pub get

# Copy and configure environment file
cp .env.example .env
# Edit .env with real Firebase credentials and API base URL

# Generate code (freezed, retrofit, injectable, envied)
dart run build_runner build --delete-conflicting-outputs

# Run the app (dev)
flutter run -d <device_id>
```

### Code Quality Checks

Run these locally before pushing:

```bash
# Analyze code for lint violations
dart analyze

# Run all tests
flutter test

# Format code (check only)
dart format --output=none lib/

# Format code (apply changes)
dart format lib/
```

---

## GitHub Actions Secrets Configuration

All sensitive values (Firebase config, API keys) are stored as **GitHub Actions secrets** and injected at build time. **Never commit `.env` with real values or Firebase config files.**

### Required Secrets

Create these in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

| Secret Name | Purpose | Value Format | Example |
|------------|---------|-------------|---------|
| `FIREBASE_ANDROID_API_KEY` | Firebase Android authentication key | String | `AIz...` |
| `FIREBASE_ANDROID_APP_ID` | Firebase Android app ID | String (app-id format) | `1:123456:android:abc...` |
| `FIREBASE_IOS_API_KEY` | Firebase iOS authentication key | String | `AIz...` |
| `FIREBASE_IOS_APP_ID` | Firebase iOS app ID | String (app-id format) | `1:123456:ios:def...` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID (shared) | Numeric string | `123456789` |
| `FIREBASE_PROJECT_ID` | Firebase project ID (shared) | String | `my-project` |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage bucket (shared) | String | `my-project.appspot.com` |
| `FIREBASE_ANDROID_CLIENT_ID` | OAuth client ID (Android) | String | `123456-abc...mobile.googleusercontent.com` |
| `FIREBASE_IOS_CLIENT_ID` | OAuth client ID (iOS) | String | `123456-def...mobile.googleusercontent.com` |
| `FIREBASE_IOS_BUNDLE_ID` | iOS app bundle ID | String (reverse-domain format) | `com.example.rideglory` |
| `LOCAL_API_BASE_URL` | Backend API URL override (optional) | Full URL with `/api` suffix | `http://api.example.com/api` |
| `UNSPLASH_ACCESS_KEY` | Unsplash API access key for image generation (Iteration 4+) | String (API key) | (see https://unsplash.com/developers) |
| `GOOGLE_SERVICES_JSON` | Firebase Android config (base64-encoded) | Base64 string | (see below) |
| `GOOGLE_SERVICE_INFO_PLIST` | Firebase iOS config (base64-encoded) | Base64 string | (see below) |

### Firebase Config Files (Base64 Encoding)

Firebase requires platform-specific config files that should **never be committed**. Instead, encode them as base64 and store in GitHub secrets:

#### Android (`GOOGLE_SERVICES_JSON`)

1. Obtain your `google-services.json` from Firebase Console
2. Encode as base64:
   ```bash
   cat google-services.json | base64 -w 0 > google-services.json.b64
   cat google-services.json.b64
   ```
3. Copy the output and paste into GitHub secret `GOOGLE_SERVICES_JSON`

#### iOS (`GOOGLE_SERVICE_INFO_PLIST`)

1. Obtain your `GoogleService-Info.plist` from Firebase Console
2. Encode as base64:
   ```bash
   cat GoogleService-Info.plist | base64 -w 0 > GoogleService-Info.plist.b64
   cat GoogleService-Info.plist.b64
   ```
3. Copy the output and paste into GitHub secret `GOOGLE_SERVICE_INFO_PLIST`

### Local Test of Secret Injection

To test that CI secrets are correctly injected, create a local `.env` file with real values:

```bash
FIREBASE_ANDROID_API_KEY=AIz...
FIREBASE_PROJECT_ID=my-project
# ... other values
```

Then run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If successful, the `lib/core/config/app_env.dart` file will be generated with valid values.

---

## CI/CD Pipeline

### Workflow File

**Location:** `.github/workflows/ci.yml`

### Trigger Conditions

| Event | Branch(es) | Action |
|-------|-----------|--------|
| `push` | `iter-*`, `main` | Run `analyze-and-test` job |
| `pull_request` | To `main` | Run `analyze-and-test` job |
| `push` tag | `v*` (e.g., `v1.0.0`) | Run `build-apk` job (in addition to `analyze-and-test`) |

### Jobs

#### 1. analyze-and-test (required gate)

Runs on every push and PR. Must pass before merging to `main`.

**Steps:**
1. Checkout code
2. Setup Flutter (stable channel, with cache)
3. Inject `.env` from secrets
4. Inject Firebase config files from secrets
5. `flutter pub get` — resolve dependencies
6. `dart run build_runner build --delete-conflicting-outputs` — generate code
7. `dart analyze` — lint code (fails on any violation)
8. `flutter test` — run all unit/widget tests (fails on any failure)

**Status:** Red X (failure) if any step fails.

#### 2. build-apk (optional, on version tags)

Runs when a tag matching `v*` is pushed (e.g., `v1.0.0`). Builds a release APK for internal testing.

**Steps:** Same as analyze-and-test, plus:
- `flutter build apk --release` — build optimized APK
- Upload artifact (retained 30 days)

**Artifact:** `build/app/outputs/flutter-apk/app-release.apk`

### Making CI Required

To enforce that the CI pipeline passes before merging:

1. Go to repository **Settings > Branches**
2. Add a rule for `main`:
   - Require status checks to pass before merging
   - Require the `analyze-and-test` job to pass
   - Optionally: require branches to be up to date before merging

---

## Release Process

### Creating a Release

1. **Ensure all tests pass locally:**
   ```bash
   dart analyze && flutter test
   ```

2. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.0.0+2  # Increment build number; update version as needed
   ```

3. **Commit and push:**
   ```bash
   git add pubspec.yaml
   git commit -m "chore: bump version to 1.0.0"
   git push origin iter-1  # or your iteration branch
   ```

4. **Create a GitHub release tag:**
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0 — Iteration 1 complete"
   git push origin v1.0.0
   ```

5. **CI automatically builds APK:**
   - The `build-apk` job triggers when the tag is pushed
   - Monitor the Actions tab for build status
   - Artifact available after job completes

### Downloading APK Artifact

1. Go to repository **Actions** tab
2. Find the run that built the release (matched the version tag)
3. Click the run to view job details
4. Download `rideglory-apk` artifact
5. Extract and use `app-release.apk` for testing or distribution

---

## Troubleshooting

### "Missing environment variable" error in CI

**Cause:** A secret is not set in GitHub Actions settings.

**Fix:**
1. Check `.env.example` for all required variables
2. Verify each secret exists in GitHub: `Settings > Secrets and variables > Actions`
3. Re-run the failed workflow from the Actions tab

### "dart analyze" fails unexpectedly

**Cause:** New lint violation introduced in code, or analyzer version mismatch.

**Fix:**
1. Run `dart analyze` locally to see the violations
2. Fix violations or document deferral in the code (`// ignore: rule_name`)
3. Push and re-run CI

### "flutter test" fails

**Cause:** A test assertion failed or a test file has a syntax error.

**Fix:**
1. Run `flutter test` locally to reproduce
2. Debug and fix the test
3. Push and re-run CI

### Firebase config injection fails

**Cause:** Secret is not base64-encoded correctly or is empty.

**Fix:**
1. Verify the secret is set in GitHub: `Settings > Secrets and variables > Actions`
2. If empty, re-encode Firebase config file:
   ```bash
   cat google-services.json | base64 -w 0
   ```
3. Update the secret and re-run CI

### APK artifact not uploaded

**Cause:** The build failed before reaching the upload step.

**Fix:**
1. Check the `build-apk` job logs in Actions
2. Look for error in `flutter build apk --release`
3. Fix the error and re-tag (or push a new tag)

---

## Code Generation & Build Commands

### Local Development Flow

```bash
# 1. Pull latest changes
git pull origin iter-1

# 2. Install/update dependencies
flutter pub get

# 3. Generate code (always after changing DTOs, cubits, or .env)
dart run build_runner build --delete-conflicting-outputs

# If code generation fails:
dart run build_runner clean  # Reset and retry
dart run build_runner build --delete-conflicting-outputs

# 4. Verify code quality
dart analyze
dart format lib/

# 5. Run tests
flutter test

# 6. Run the app
flutter run -d <device_id>
```

### CI vs. Local

| Step | Local | CI |
|------|-------|-----|
| `flutter pub get` | Yes | Yes |
| `dart run build_runner build` | Yes, if code changed | Always |
| `dart analyze` | Optional (recommended) | **Required — gates merge** |
| `flutter test` | Optional (recommended) | **Required — gates merge** |
| Build APK | `flutter build apk --release` | Only on version tags |

---

## Next Steps

### Before Iteration 2

- [ ] All secrets configured in GitHub (`FIREBASE_*`, `GOOGLE_SERVICES_JSON`, `GOOGLE_SERVICE_INFO_PLIST`)
- [ ] CI pipeline validates with a test push to `iter-1` branch
- [ ] `dart analyze` and `flutter test` pass in CI
- [ ] Main branch protection rule enforces `analyze-and-test` status check

### Deferred to Later Iterations

- **IPA build + App Store submission:** Requires code signing certificate and provisioning profile; deferred until distribution target confirmed (post-Iteration 2).
- **TestFlight distribution:** Deferred; APK-only for Iteration 1.
- **Firebase Remote Config integration:** Already used for base URL resolution; no CI changes needed.

---

## Support & Maintenance

### Updating Flutter Version

1. Edit `subosito/flutter-action@v2` in `.github/workflows/ci.yml` (currently pinned to `stable`)
2. Or manually pin a specific version in the workflow (e.g., `flutter-version: '3.13.0'`)
3. Test locally with the same version before updating CI

### Rotating Firebase Secrets

1. Generate new Firebase config from Firebase Console
2. Base64-encode and update the corresponding GitHub secret
3. Next CI run will use the new config

### Adding a New Secret

1. Add the secret in GitHub: `Settings > Secrets and variables > Actions > New repository secret`
2. Update `.env.example` with placeholder (if applicable)
3. Add the secret to the `.env` file creation step in `.github/workflows/ci.yml`
4. Document in the **Required Secrets** table in this file

---

## Questions?

Refer to:
- [Flutter CLI reference](https://flutter.dev/docs/reference/flutter-cli)
- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Firebase setup guide](https://firebase.flutter.dev/)
