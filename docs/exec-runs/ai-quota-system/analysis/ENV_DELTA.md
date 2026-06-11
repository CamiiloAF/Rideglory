# ENV Delta — ai-quota-system

**Generado:** 2026-06-05T23:44:51Z

## Variables de entorno nuevas

Ninguna. Esta fase no agrega variables `.env` nuevas a `api-gateway`.

## Remote Config (Firebase Console — NO son variables .env)

| Parámetro | Descripción | Formato | Default en código |
|-----------|-------------|---------|-------------------|
| `ai_description_daily_limit` | Límite diario de generaciones de descripción por usuario | String numérico (ej: `"10"`) | `10` |
| `ai_cover_daily_limit` | Límite diario de generaciones de portada por usuario | String numérico (ej: `"5"`) | `5` |

Estos parámetros **deben existir en Remote Config antes del deploy**. El servicio lee via `getRemoteConfig(app).getTemplate()` (Admin SDK, no SDK cliente).

## IAM (GCP)

El service account de `firebase-admin` (configurado en `FIREBASE_SERVICE_ACCOUNT` / `FIREBASE_SERVICE_ACCOUNT_KEY` o equivalente en el entorno de producción) necesita el rol:

```
roles/remoteconfig.viewer
```

Si el rol no está asignado, `getRemoteConfig(app).getTemplate()` falla con 403. En ese caso, `AiQuotaService.getLimits()` debe capturar el error y usar los fallbacks (`10`/`5`) silenciosamente — **sin crashear el servicio**.

## Variables .env existentes (sin cambios)

```
GEMINI_API_KEY        # ya existe — no modificar
GEMINI_TEXT_MODEL     # ya existe — no modificar
GEMINI_IMAGE_MODEL    # ya existe — no modificar
```
