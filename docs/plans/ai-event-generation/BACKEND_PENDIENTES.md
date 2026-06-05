# Pendientes manuales — Backend AI Event Generation (Fases 1-3)

> Generado: 2026-06-05  
> Ramas: `feature/ai-event-generation` en `rideglory-api` y `rideglory-contracts`  
> Los pasos marcados ⛔ son **bloqueantes** antes del deploy. Los marcados ⚠️ son necesarios pero no críticos para arrancar.

---

## Fase 1 — Base de texto IA (`POST /ai/description`)

### Variables de entorno

| Variable | Dónde agregarla | Valor |
|---|---|---|
| `GEMINI_API_KEY` | `.env` local de `api-gateway` y secrets de EC2/staging | Obtenida en [Google AI Studio](https://aistudio.google.com/app/apikey) |
| `GEMINI_TEXT_MODEL` | `.env` local y EC2 (opcional) | `gemini-2.5-flash` (default si no se define) |

- ⛔ Sin `GEMINI_API_KEY` el api-gateway **no arranca** — el constructor de `GeminiService` lanza `Error('GEMINI_API_KEY is required')` en startup.

### Verificación con servidor local

1. ⛔ Agregar `GEMINI_API_KEY` al `.env` de `api-gateway`.
2. Obtener un **Firebase ID token** de un usuario de prueba (ver sección "Cómo obtener el token" al final).
3. Ejecutar los requests del Postman collection — ver `ai-event-generation.postman_collection.json` en esta carpeta.
4. Verificar:
   - `POST /ai/description` sin `Authorization` → **401**
   - `POST /ai/description` con body sin `eventContext.title` → **400**
   - `POST /ai/description` con body completo válido → **200** con `markdown` en español y `remainingGenerations: -1`
5. ⚠️ Confirmar que `POST /events/generate-cover` sigue respondiendo igual (no regresionó).

---

## Fase 2 — Portada IA con Storage (`POST /ai/cover`)

### Variables de entorno adicionales

| Variable | Dónde agregarla | Valor |
|---|---|---|
| `FIREBASE_STORAGE_BUCKET` | `.env` local y EC2 | `rideglory-prod.appspot.com` (verificar en Firebase Console → Storage) |
| `GEMINI_IMAGE_MODEL` | `.env` local y EC2 | `gemini-2.0-flash-preview-image-generation` (verificar que este nombre sigue activo — modelo preview sujeto a cambio) |

### Gate día 1 — Verificar Storage antes de usar el endpoint ⛔

Antes de llamar `POST /ai/cover` es **obligatorio** verificar que la configuración de Storage funciona:

**a) Verificar escritura:**
```bash
# Con el api-gateway corriendo localmente con FIREBASE_STORAGE_BUCKET configurado,
# ejecutar un script de prueba o llamar temporalmente este endpoint de test:
# El servicio escribirá a pending/{userId}/test-gate.txt
```
Si lanza "No bucket name specified" → `FIREBASE_STORAGE_BUCKET` no está llegando al `initializeApp()`.

**b) Verificar lectura pública (UBLA):**
- Hacer GET a la URL devuelta (`https://storage.googleapis.com/{bucket}/pending/...`) desde un navegador o curl.
- Si responde **403/401** → el bucket tiene **Uniform Bucket-Level Access (UBLA)** activado y las ACLs de objeto no funcionan.
  - **Solución UBLA:** en Firebase Console → Storage → Rules (o GCP Console → IAM): agregar binding `allUsers → roles/storage.objectViewer` a nivel de bucket.
  - Documentar cuál de las dos opciones se usó (ACL de objeto o IAM de bucket) en este archivo.

> **Estado:** [ ] ACL de objeto funciona  [ ] Requirió binding IAM `allUsers → objectViewer`  [ ] Signed URLs (alternativa)

**c) Verificar nombre del modelo Gemini imagen:**
- Confirmar que `gemini-2.0-flash-preview-image-generation` sigue siendo válido en el free tier.
- Si cambió: actualizar solo la env var `GEMINI_IMAGE_MODEL` — no requiere cambios de código.

### Verificación con servidor local

1. ⛔ Completar el Gate día 1 (pasos a, b, c arriba).
2. Llamar `POST /ai/cover` con el Postman collection.
3. Verificar respuesta 200 con `imageUrl` apuntando a `pending/{userId}/{draftId}.jpg` (o `.png`).
4. Hacer HTTP GET a la `imageUrl` → debe devolver la imagen sin error 401/403.
5. Verificar en Firebase Storage Console que el archivo existe en la ruta correcta.

### Cron de limpieza (`StorageCleanupService`)

- ⚠️ El cron se ejecuta domingos a las 03:00 hora Colombia.
- Para verificarlo en logs de arranque: buscar la línea de registro del scheduler mencionando `StorageCleanupService`.
- Si **no aparece** en los logs: verificar que `ScheduleModule.forRoot()` está en `app.module.ts` y que `AiModule` está en sus `imports`.

---

## Fase 3 — Sistema de cuotas (Firestore + Remote Config)

### Remote Config — crear parámetros en Firebase Console ⛔

Antes del deploy de Fase 3, crear estos parámetros en **Firebase Console → Remote Config**:

| Parámetro | Tipo | Valor inicial sugerido | Descripción |
|---|---|---|---|
| `ai_description_daily_limit` | String (número) | `"15"` | Máx. generaciones de descripción por usuario/día |
| `ai_cover_daily_limit` | String (número) | `"5"` | Máx. generaciones de portada por usuario/día |

> ⚠️ Si los parámetros no existen en Remote Config, el servicio aplica el fallback hardcodeado (10 descripciones / 5 portadas) — funciona, pero sin control externo.

### IAM — Remote Config Admin SDK ⛔

El service account de `firebase-admin` necesita el rol **`roles/remoteConfig.viewer`** en GCP IAM para que `getRemoteConfig(app).getTemplate()` funcione.

```
GCP Console → IAM & Admin → IAM → [service account] → Agregar rol: Remote Config Viewer
```

Si falta este rol, `getLimits()` lanzará un error de permisos. El servicio tiene fallback a valores hardcodeados en dev, pero en producción esto debe estar configurado.

### Firestore — TTL policy (una sola vez) ⚠️

Ejecutar **una sola vez** antes del primer deploy de Fase 3:

```bash
gcloud firestore fields ttls update expireAt \
  --collection-group=days \
  --enable-ttl \
  --project=<FIREBASE_PROJECT_ID>
```

Reemplazar `<FIREBASE_PROJECT_ID>` con el ID del proyecto Firebase (ej. `rideglory-prod`).

- Firestore puede tardar **hasta 24 h** en activar la TTL policy — no bloqueante para la funcionalidad.
- Verificar que se aplicó: `gcloud firestore fields ttls describe expireAt --collection-group=days --project=<FIREBASE_PROJECT_ID>`

### Verificación con servidor local

1. ⛔ Crear parámetros en Remote Config y verificar permisos IAM.
2. Llamar `POST /ai/description` N veces (N = `ai_description_daily_limit`) con el mismo usuario → la última debe devolver **429** con `{ "error": "quota_exceeded_user", "remaining": 0 }`.
3. Verificar en **Firestore Console** que el documento `ai_usage_quotas/{userId}/days/{YYYY-MM-DD}` existe con los campos `descriptionCount`, `coverCount`, `createdAt`, `expireAt`.
4. Verificar que `remainingGenerations` en el response 200 disminuye correctamente con cada llamada.

---

## Deploy a EC2 — Checklist consolidado (todas las fases) ⛔

> Ejecutar las migraciones/verificaciones locales antes de desplegar a producción.

```
[ ] GEMINI_API_KEY           → EC2 env (Fase 1)
[ ] GEMINI_TEXT_MODEL        → EC2 env (Fase 1, opcional — default gemini-2.5-flash)
[ ] FIREBASE_STORAGE_BUCKET  → EC2 env (Fase 2)
[ ] GEMINI_IMAGE_MODEL       → EC2 env (Fase 2)
[ ] Remote Config params     → Firebase Console (Fase 3): ai_description_daily_limit, ai_cover_daily_limit
[ ] IAM remoteConfig.viewer  → GCP Console (Fase 3)
[ ] TTL policy Firestore     → gcloud CLI (Fase 3, una sola vez)
[ ] Gate Storage local       → Escritura + lectura pública verificada (Fase 2)
[ ] Verificar generate-cover → POST /events/generate-cover sin regresión (Fase 1)
```

---

## Cómo obtener un Firebase ID token para Postman

**Opción A — desde la app Flutter (más simple):**
1. Iniciar sesión en la app en desarrollo.
2. En un breakpoint o log, agregar: `final token = await FirebaseAuth.instance.currentUser?.getIdToken(); print(token);`
3. Copiar el token y pegarlo en la variable `{{firebase_token}}` del entorno Postman.

**Opción B — con la REST API de Firebase Auth:**
```bash
curl -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={{FIREBASE_WEB_API_KEY}}" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password","returnSecureToken":true}'
# Usar el campo "idToken" del response
```

> Los tokens de Firebase expiran en **1 hora**. Renovar usando `refreshToken` si es necesario.
