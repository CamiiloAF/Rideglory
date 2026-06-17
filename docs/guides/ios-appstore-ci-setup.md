# Setup: CI/CD para App Store (TestFlight)

Secrets ya configurados en GitHub. Solo faltan **3 pasos manuales** para que el workflow
`.github/workflows/release-appstore.yml` funcione completamente.

---

## Paso 1 — Registrar la app en App Store Connect

> Omitir si ya existe la app `com.camiloagudelo.rideglory` en App Store Connect.

1. Ir a [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**
2. Plataformas: iOS
3. Bundle ID: `com.camiloagudelo.rideglory`
4. SKU: `rideglory`
5. Guardar.

---

## Paso 2 — Exportar el Distribution Certificate como `.p12`

El certificado `Apple Distribution: Juan Camilo Agudelo Franco (2977ZR336A)` ya está
instalado en tu Keychain. Solo necesitas exportarlo:

1. Abrir **Keychain Access** → buscar `Apple Distribution: Juan Camilo Agudelo Franco`
2. Click derecho sobre el que tiene la llave privada → **Export**
3. Formato: `.p12` → guardar con una contraseña segura
4. Encodear y subir los dos secrets:

```bash
base64 -i ~/Downloads/distribution.p12 | gh secret set DIST_CERT_P12_BASE64
gh secret set DIST_CERT_PASSWORD --body "la-contraseña-que-pusiste"
```

---

## Paso 3 — Obtener el Issuer ID de App Store Connect

1. Ir a App Store Connect → **Users and Access** → pestaña **Integrations** → **App Store Connect API**
2. El **Issuer ID** aparece al tope de la página (formato UUID)
3. Subir el secret:

```bash
gh secret set APPSTORE_API_ISSUER_ID --body "el-uuid-del-issuer"
```

---

## Estado de secrets

| Secret | Estado |
|--------|--------|
| `FIREBASE_IOS_API_KEY` | ✅ |
| `FIREBASE_IOS_APP_ID` | ✅ |
| `FIREBASE_IOS_CLIENT_ID` | ✅ |
| `FIREBASE_IOS_BUNDLE_ID` | ✅ |
| `GOOGLE_SERVICE_INFO_PLIST` | ✅ |
| `APPSTORE_API_KEY_ID` | ✅ |
| `APPSTORE_API_PRIVATE_KEY` | ✅ |
| `PROVISIONING_PROFILE_BASE64` | ✅ |
| `DIST_CERT_P12_BASE64` | ⏳ Paso 2 |
| `DIST_CERT_PASSWORD` | ⏳ Paso 2 |
| `APPSTORE_API_ISSUER_ID` | ⏳ Paso 3 |

---

## Activar el trigger automático

Cuando los 3 pasos estén completos, cambiar el trigger en
`.github/workflows/release-appstore.yml` para que se dispare junto con Android:

```yaml
on:
  push:
    tags:
      - 'release-[0-9]+.[0-9]+.[0-9]+'
```

Un tag `release-X.Y.Z` construirá y subirá Android (Play Store Internal) e iOS (TestFlight) en paralelo.
