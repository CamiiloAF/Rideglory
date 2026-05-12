# Deployment Guide

## Prerequisites

Copy and configure the environment file:
```bash
cp .env.example .env
# Fill in Firebase and Maps credentials
```

Copy Firebase configuration files:
```bash
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `FIREBASE_API_KEY` | Yes | Firebase Web API key |
| `FIREBASE_APP_ID` | Yes | Firebase App ID |
| `FIREBASE_MESSAGING_SENDER_ID` | Yes | Firebase messaging sender |
| `FIREBASE_PROJECT_ID` | Yes | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | Yes | Firebase storage bucket |
| `GOOGLE_MAPS_API_KEY` | Yes | Google Maps API key |
| `API_BASE_URL` | Dev only | Override backend URL for physical device testing |

## Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## CI/CD

The `.github/workflows/ci.yml` pipeline runs on pushes to `iter-*` and `main`:
- `analyze-and-test`: `dart analyze` + `flutter test`
- `build-apk`: APK build on version tags

All secrets are managed via GitHub Actions repository secrets.
