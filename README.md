# rideglory

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
