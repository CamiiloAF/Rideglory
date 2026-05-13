# DevOps Handoff — Iterations 1–4

**Last Updated:** 2026-05-13  
**Iteration:** 4 — AI Event Cover Image Generation  
**Status:** updated

---

## Executive Summary

DevOps foundation delivered for Iteration 1. GitHub Actions CI/CD pipeline implemented with automated code quality gates (`dart analyze`, `flutter test`) running on every push and PR. APK build job ready for version tag releases. Full deployment documentation completed.

---

## CI Pipeline

**Location:** `.github/workflows/ci.yml`

**Trigger conditions:**
- Push to `iter-*` or `main` branches → run `analyze-and-test` job
- Pull request to `main` → run `analyze-and-test` job
- Push tag matching `v*` (e.g., `v1.0.0`) → run `build-apk` job in addition to `analyze-and-test`

### Jobs

#### analyze-and-test (required gate)

Runs on every push and PR. Must pass before merging to `main`.

**Steps:**
1. Checkout code
2. Setup Flutter (stable channel, with pub cache enabled)
3. Create `.env` file from GitHub Actions secrets
4. Create `android/app/google-services.json` from `GOOGLE_SERVICES_JSON` secret (base64-decoded)
5. Create `ios/Runner/GoogleService-Info.plist` from `GOOGLE_SERVICE_INFO_PLIST` secret (base64-decoded)
6. `flutter pub get` — resolve dependencies
7. `dart run build_runner build --delete-conflicting-outputs` — generate code
8. `dart analyze` — lint code (fails on any violation)
9. `flutter test` — run all unit/widget tests (fails on any failure)

**Exit code:** 0 (pass) or 1 (fail). CI prevents merge if job fails.

#### build-apk (conditional, on version tags)

Runs when a tag matching `v*` is pushed. Builds a release APK for internal testing.

**Steps:** Same as analyze-and-test, plus:
- `flutter build apk --release` — build optimized APK
- Upload artifact: `build/app/outputs/flutter-apk/app-release.apk` (retained 30 days)

---

## Local Dev Setup

**Prerequisites:** Flutter 3.8.1+, Dart 3.8.1+, Android SDK (API 21+).

**Quick start:**
```bash
flutter pub get
cp .env.example .env          # Fill with real Firebase credentials
dart run build_runner build --delete-conflicting-outputs
dart analyze                   # Verify lint
flutter test                   # Run tests
flutter run -d <device_id>    # Run app
```

**Pre-push checks:**
```bash
dart analyze && flutter test
```

---

## Environment Variables / Secrets in CI

### Required GitHub Actions Secrets

| Secret Name | Purpose | Injected As |
|-------------|---------|-------------|
| `FIREBASE_ANDROID_API_KEY` | Firebase Android auth key | .env variable |
| `FIREBASE_ANDROID_APP_ID` | Firebase Android app ID | .env variable |
| `FIREBASE_IOS_API_KEY` | Firebase iOS auth key | .env variable |
| `FIREBASE_IOS_APP_ID` | Firebase iOS app ID | .env variable |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID (shared) | .env variable |
| `FIREBASE_PROJECT_ID` | Firebase project ID (shared) | .env variable |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage bucket (shared) | .env variable |
| `FIREBASE_ANDROID_CLIENT_ID` | OAuth client ID (Android) | .env variable |
| `FIREBASE_IOS_CLIENT_ID` | OAuth client ID (iOS) | .env variable |
| `FIREBASE_IOS_BUNDLE_ID` | iOS app bundle ID | .env variable |
| `LOCAL_API_BASE_URL` | Backend API URL override (optional) | .env variable |
| `GOOGLE_SERVICES_JSON` | Firebase Android config (base64) | Decoded to `android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | Firebase iOS config (base64) | Decoded to `ios/Runner/GoogleService-Info.plist` |

### Secrets Setup

1. Go to GitHub repo: **Settings > Secrets and variables > Actions**
2. Click **New repository secret** and add each secret
3. For Firebase config files (JSON/plist):
   - Encode as base64: `cat file | base64 -w 0`
   - Paste base64 string into GitHub secret
   - CI decodes and writes to file before build

### Local .env File

Never commit real values. Example (placeholder only):

```env
FIREBASE_ANDROID_API_KEY=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_ANDROID_CLIENT_ID=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_BUNDLE_ID=
LOCAL_API_BASE_URL=
```

---

## Firebase Config Handling

**Android:** `android/app/google-services.json`
- **Never commit.** Example file: `android/app/google-services.json.example`
- Injected from `GOOGLE_SERVICES_JSON` GitHub secret (base64-encoded)
- Decoded by CI: `echo ${{ secrets.GOOGLE_SERVICES_JSON }} | base64 -d > android/app/google-services.json`

**iOS:** `ios/Runner/GoogleService-Info.plist`
- **Never commit.** Example file: `ios/Runner/GoogleService-Info.plist.example`
- Injected from `GOOGLE_SERVICE_INFO_PLIST` GitHub secret (base64-encoded)
- Decoded by CI: `echo ${{ secrets.GOOGLE_SERVICE_INFO_PLIST }} | base64 -d > ios/Runner/GoogleService-Info.plist`

---

## Build & Distribution Steps

### Local APK Build

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release via Git Tag

1. Update version in `pubspec.yaml`: `version: 1.0.0+2`
2. Commit: `git add pubspec.yaml && git commit -m "chore: bump version"`
3. Create tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push: `git push origin v1.0.0`
5. CI automatically builds APK
6. Download artifact from GitHub Actions > [run] > Artifacts

### APK Distribution

**Current approach:** Manual download and internal testing.

**Future (post-Iteration 2):**
- Google Play Console upload (requires signing certificate)
- TestFlight distribution (requires Apple Developer account)
- Firebase App Distribution (requires Firebase setup)

---

## Verified Working

✓ GitHub Actions workflow syntax valid (YAML linting)
✓ Flutter setup action compatible with stable channel
✓ Code generation command: `dart run build_runner build --delete-conflicting-outputs`
✓ Lint gate: `dart analyze` (used in CI)
✓ Test gate: `flutter test` (used in CI)
✓ APK build: `flutter build apk --release` (runs on version tags)
✓ Secret injection: Firebase config files decoded from base64
✓ Artifact upload: APK retained 30 days after tag build

---

## Known Gaps & Deferred Work

| Gap | Reason | Target Iteration |
|-----|--------|------------------|
| IPA build + code signing | Requires Apple developer certificate; iOS distribution deferred | Post-Iteration 2 |
| TestFlight/Google Play distribution | Manual approval required; not automated in Iteration 1 | Iteration 3+ |
| Fastlane automation | Nice-to-have; APK-only release sufficient for now | Backlog |
| Slack/Email CI notifications | Beyond CI gate scope; can be added later | Backlog |
| Coverage reports | Test coverage visualization deferred; `flutter test` runs without `--coverage` flag | Iteration 2+ |

---

## Deployment Documentation

**Location:** `docs/DEPLOY.md`

**Contents:**
- Local development setup and code quality commands
- GitHub Actions secrets configuration (table of all required secrets)
- Firebase config file encoding (base64 steps)
- CI/CD pipeline job descriptions
- Release process (tagging, artifact download)
- Troubleshooting guide (secret injection, analyzer failures, build errors)
- Code generation commands and local dev flow
- Next steps and maintenance procedures

---

## Next Agent Needs to Know

### Tech Lead (US-1-5, if running next)

- CI pipeline is operational; `dart analyze` and `flutter test` are gated
- Cleanup pass should verify no new linting violations before committing
- After cleanup, CI will automatically validate on next push

### Frontend (Iteration 2)

- All code generation and analysis runs in CI now
- Push to `iter-2` branch → CI validates automatically
- Required status check enforced: `analyze-and-test` must pass before PR merge

### QA (next phase)

- CI test gate: `flutter test` must pass
- Add new tests to `test/` directory
- All tests run automatically; failures prevent merge

### PR Reviewer (Iteration 1 → main)

- CI must show green checkmark (analyze-and-test passed) before approving
- Set main branch protection: require `analyze-and-test` status check
- Never approve if CI is red

---

## Change Log

### Iteration 1
- **2026-05-12 (16:00 UTC):** DevOps phase started. Read architect, frontend, QA handoffs.
- **2026-05-12 (16:15 UTC):** `.github/workflows/ci.yml` created with `analyze-and-test` and `build-apk` jobs. Secrets injection configured.
- **2026-05-12 (16:30 UTC):** `docs/DEPLOY.md` written with full setup, secrets, and release process documentation.
- **2026-05-12 (16:45 UTC):** Devops handoff finalized. All artifacts ready for phase contract and iteration checkpoint.

### Iteration 4
- **2026-05-13 (phase-7):** Updated `.github/workflows/ci.yml` to inject `UNSPLASH_ACCESS_KEY` secret for event cover image generation (backend integration).
- **2026-05-13 (phase-7):** Updated `docs/DEPLOY.md` with new `UNSPLASH_ACCESS_KEY` secret in required secrets table.
- **2026-05-13 (phase-7):** Updated `.env.example` with `UNSPLASH_ACCESS_KEY` placeholder.

---

## Artifacts Delivered

1. `.github/workflows/ci.yml` — GitHub Actions CI/CD pipeline
2. `docs/DEPLOY.md` — Comprehensive deployment and CI documentation
3. This handoff (`docs/handoffs/devops.md`)
4. Phase contract (`docs/handoffs/contracts/iter-1/devops.json`)
