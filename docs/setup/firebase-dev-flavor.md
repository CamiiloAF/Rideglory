# Entornos dev / prod — Firebase + flavors

Fecha: 2026-06-06

La app ahora tiene **dos flavors** (`dev` y `prod`), cada uno apuntando a su propio
proyecto Firebase. La config de Firebase se inyecta vía `--dart-define-from-file`.

| | dev | prod |
|---|---|---|
| Firebase project | `rideglory-dev` | `rideglory-f7383` |
| Android applicationId | `com.camiloagudelo.rideglory.dev` | `com.camiloagudelo.rideglory` |
| iOS bundle id | `com.camiloagudelo.rideglory.dev` | `com.camiloagudelo.rideglory` |
| Storage bucket | `rideglory-dev.firebasestorage.app` | `rideglory-f7383.firebasestorage.app` |
| Config dart-define | `config/dev.json` | `config/prod.json` |
| google-services.json | `android/app/src/dev/` | `android/app/src/prod/` |
| GoogleService-Info.plist | `ios/config/dev/` | `ios/config/prod/` |

## Cómo correr

```bash
# dev
flutter run --flavor dev --dart-define-from-file=config/dev.json
# prod
flutter run --flavor prod --dart-define-from-file=config/prod.json

# builds
flutter build apk   --flavor dev  --dart-define-from-file=config/dev.json
flutter build apk   --flavor prod --dart-define-from-file=config/prod.json
flutter build ipa   --flavor prod --dart-define-from-file=config/prod.json
```

En VSCode ya están las configs **Rideglory dev** / **Rideglory prod** en `.vscode/launch.json`.

> El flavor dev instala una app **independiente** (sufijo `.dev` y nombre "Rideglory Dev"),
> así que puedes tener dev y prod a la vez en el mismo dispositivo.

## Arquitectura de config

- `main.dart` inicializa Firebase con `DefaultFirebaseOptions.currentPlatform`.
- Esas opciones se leen con `_value(enviedValue, dartDefineKey) = enviedValue ?? String.fromEnvironment(...)`.
- Las claves Firebase **se sacaron del `.env`** (envied ahora las devuelve `null`) y se pasan
  por `--dart-define-from-file=config/<flavor>.json`. `.env` solo guarda `MAPBOX_ACCESS_TOKEN`
  y `LOCAL_API_BASE_URL`.
- Archivos con secretos (gitignored): `config/dev.json`, `config/prod.json`,
  `android/app/src/*/google-services.json`, `ios/config/*/GoogleService-Info.plist`.
  Versionados: los `*.example`.

---

## PENDIENTES MANUALES (consola / Xcode — no automatizables desde CLI)

### 1. iOS — flavors en Xcode ✅ HECHO (2026-06-08)

Verificado: `flutter build ios --flavor dev --dart-define-from-file=config/dev.json --debug --simulator`
compila `com.camiloagudelo.rideglory.dev` y el Run Script deja el plist de `rideglory-dev`.

Se automatizó con `ios/setup_flavors.rb` (gem `xcodeproj` 1.27, idempotente). Quedó configurado:

1. **6 build configurations**: `Debug/Release/Profile` × `-dev/-prod`, a nivel proyecto y en todos
   los targets.
2. **Bundle id por flavor** en el target Runner: `*-dev → com.camiloagudelo.rideglory.dev`,
   `*-prod → com.camiloagudelo.rideglory`.
3. **Schemes compartidos** `dev` y `prod` (`ios/Runner.xcodeproj/xcshareddata/xcschemes/`).
   Flutter usa el nombre del scheme como flavor.
4. **Run Script phase** "Set Firebase plist (flavor)" ANTES de "Resources", que ejecuta
   `"${PROJECT_DIR}/scripts/set_google_service_plist.sh"` (copia el plist del flavor según
   `$CONFIGURATION`).
5. `pod install` reintegró las 9 configs (xcconfig por flavor en `Pods/Target Support Files/`).

> Para re-generar tras un `flutter clean` agresivo del `.pbxproj` (no debería hacer falta, va
> versionado): `cd ios && PATH="/opt/homebrew/opt/ruby/bin:$PATH" ruby setup_flavors.rb && pod install`.

> Android y iOS ya quedan 100% funcionales y verificados.

### 2. Firebase consola — habilitar servicios en `rideglory-dev`

El proyecto dev se creó vacío. En https://console.firebase.google.com/project/rideglory-dev :

- **Authentication** → habilitar los mismos proveedores que prod (Email/Password, Google, Apple).
- **Google Sign-In en Android**: agregar los **SHA-1 / SHA-256** de tu keystore de debug y de
  release al app Android dev. Tras agregarlos, **re-descargar** `google-services.json` dev y
  reemplazar `android/app/src/dev/google-services.json` (el actual no tiene `oauth_client` aún).
  Obtener SHA-1 debug: `cd android && ./gradlew signingReport`.
- **Apple Sign-In en iOS**: configurar el provider y, si corre en device, registrar el bundle
  `com.camiloagudelo.rideglory.dev` en el Apple Developer portal.
- **Storage** → habilitarlo y desplegar reglas. Si quieres portadas IA públicas, replica las
  reglas/ajustes de prod (ver `docs/exec-runs/backend-portada-ia-storage/`).
- **Firestore** → crear la base y replicar reglas/índices si dev los necesita.
- **Remote Config** → si una build dev NO usa el API local, define ahí el `api_base_url` dev
  (y los flags `ai_image_daily_limit=5`, `ai_description_daily_limit=15`).

### 3. Backend (`rideglory-api/api-gateway`) — service account dev

- Se creó `api-gateway/.env.dev` (gitignored) apuntando al bucket
  `rideglory-dev.firebasestorage.app`. Las claves Gemini/Places/Mapbox se reutilizan de prod.
- **Falta el service account de `rideglory-dev`**: consola → Project settings → Service accounts
  → "Generate new private key" → pegar el JSON (una línea) en
  `FIREBASE_SERVICE_ACCOUNT_JSON` dentro de `.env.dev`.
- Para correr el backend contra dev: `cp .env.dev .env` (o el mecanismo de arranque que uses)
  y levantar normal.

### 4. Notas

- El `.env` de la app tenía la línea `FIREBASE_IOS_BUNDLE_ID` **corrupta** (basura pegada);
  quedó resuelta al migrar a `config/*.json`.
- La app aún no tiene usuarios reales, así que separar dev/prod no rompe nada en producción.
