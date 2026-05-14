# rideglory

A Flutter mobile application for motorcycle riding events and community coordination.

## What's Shipped

| Feature | Status | Iteration | Details |
|---------|--------|-----------|---------|
| **Authentication** | Live | Framework | Email, Google, Apple sign-in via Firebase |
| **Event Discovery** | Live | 1–2 | Browse events, filter by type/city/date, real-time tracking |
| **Vehicle Garage** | Live | Framework | Add/manage/delete motorcycles, maintenance logging |
| **User Profiles** | Live | 1 | Public rider profiles, attendee list navigation |
| **AI Event Covers** | Live | 4 | Auto-generate event cover images via Claude Haiku + Unsplash |
| **Design System** | Complete | 3 | Pencil UI toolkit with tokens, components, all screen flows |

## Deployed Links

- **GitHub:** [Rideglory repository](https://github.com/CamiiloAF/Rideglory)
- **Backend API:** [rideglory-api repository](https://github.com/CamiiloAF/rideglory-api) (NestJS microservices)
- **Product Documentation:** `/docs/` (PRD, architecture, iteration history)
- **Latest Iteration:** [Iteration 1 Summary](/docs/ITERATION_SUMMARY_1.md) (UI/UX Redesign — Design System Baseline)
- **Previous Iterations:** [Iteration History](/docs/ITERATION_HISTORY.md)

## Getting Started

This is a brownfield Flutter project using Clean Architecture (domain/data/presentation layers), BLoC/Cubit for state management, and Firebase for authentication and backend integration.

### Quick Start
```bash
# Install dependencies
flutter pub get

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your Firebase and Maps credentials

# Copy Firebase config files (keep untracked locally)
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Development Commands
```bash
# Run tests
flutter test

# Check code style
dart analyze

# Format code
dart format lib/
```

For detailed architecture and development guide, see [CLAUDE.md](CLAUDE.md).

## Security configuration

Do not commit API keys or access tokens to the repository.

### Dart env variables (Envied)

This project uses `envied` to load Dart-side secrets from a local `.env` file.

1. Copy `.env.example` to `.env`.
2. Fill real values in `.env`.
3. Regenerate env files when keys change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Android Maps API key

Set your local Maps key in `android/local.properties`:

```properties
MAPS_API_KEY=your_google_maps_api_key
```

The app reads this value through Android manifest placeholders.

### Firebase configuration

Firebase options are resolved from Envied (`.env`) values.

For native Firebase SDK files, keep real files local and untracked:

1. Copy `android/app/google-services.json.example` to `android/app/google-services.json`.
2. Copy `ios/Runner/GoogleService-Info.plist.example` to `ios/Runner/GoogleService-Info.plist`.
3. Replace placeholders with your real Firebase project values.

### MCP credentials

`.vscode/mcp.json` is configured to prompt for credentials instead of storing
plain-text tokens in source control.
