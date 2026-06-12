> Slim handoff — read this before handoffs/architect.md

# Architect → DevOps

**Scope:** CI workflow + nativos iOS/Android (retiro Crashlytics + upload símbolos Sentry)

## GitHub Secrets nuevos

| Secret | Descripción |
|--------|-------------|
| `SENTRY_AUTH_TOKEN` | Token de API Sentry (Settings → Auth Tokens → `project:releases`) |
| `SENTRY_ORG` | Slug de la organización en Sentry |
| `SENTRY_PROJECT` | Slug del proyecto Flutter en Sentry |

## `.github/workflows/ci.yml` — cambios

### Job `analyze-and-test`
Sin cambios de secrets. Solo verificar que `dart analyze` y `flutter test` pasen con `sentry_flutter` añadido.

### Job `build-apk` (y futura build iOS)
Añadir vars de env:
```yaml
env:
  SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
  SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
  SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
```

Añadir paso **después** de `Build APK`:
```yaml
- name: Upload Android mapping to Sentry
  uses: getsentry/action-release@v1
  with:
    environment: production
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
```

O equivalentemente usando `sentry-cli`:
```yaml
- name: Upload ProGuard mapping
  run: |
    curl -sL https://sentry.io/get-cli/ | bash
    sentry-cli upload-proguard \
      --org $SENTRY_ORG \
      --project $SENTRY_PROJECT \
      android/app/build/outputs/mapping/release/mapping.txt
```

### iOS dSYM upload (cuando se active la build iOS en CI)
```yaml
- name: Upload dSYM to Sentry
  run: |
    sentry-cli upload-dif \
      --org $SENTRY_ORG \
      --project $SENTRY_PROJECT \
      build/ios/archive/Runner.xcarchive/dSYMs/
```

## `android/app/build.gradle.kts` — cambios (tras retiro Crashlytics)

Eliminar:
```kotlin
id("com.google.firebase.crashlytics")
```

Eliminar bloque:
```kotlin
firebaseCrashlytics {
    mappingFileUploadEnabled = true
}
```

El mapping lo sube ahora `sentry-cli` (ver CI arriba).

## `android/settings.gradle.kts` — cambios (tras retiro Crashlytics)

Eliminar:
```kotlin
id("com.google.firebase.crashlytics") version "3.0.3" apply false
```

## `ios/Runner.xcodeproj/project.pbxproj` — cambios (tras retiro Crashlytics)

Eliminar el build phase:
```
FC7A1B2C00000000CRASHLYTICS /* Firebase Crashlytics dSYM Upload */
```
y todas sus referencias. El script era: `"${PODS_ROOT}/FirebaseCrashlytics/run"\n`

El upload de dSYM a Sentry se realiza desde CI (ver arriba), no desde Xcode build phase.

## Secuencia recomendada

1. Añadir los 3 GitHub Secrets al repo antes de activar el paso de upload.
2. Añadir paso de upload en el workflow (puede hacerse con Crashlytics aún activo — no hay conflicto).
3. Verificar que el mapping/dSYM de una build real llega a Sentry con stack simbolizado.
4. Asegurarse que `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` existe con evidencia real **antes del paso 5**.
5. Recién entonces retirar los plugins Crashlytics de Gradle/Xcode.

## Nota sobre SENTRY_DSN en CI

Para las builds de prod en CI, el `SENTRY_DSN` se pasa via `--dart-define-from-file=config/prod.json`. Asegurarse de que el archivo `config/prod.json` contiene la clave `SENTRY_DSN` con el valor real antes de activar el build. El CI no usa `@EnviedField` para este valor.

> Full detail: handoffs/architect.md
