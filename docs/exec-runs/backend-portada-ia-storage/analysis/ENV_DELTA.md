# ENV Delta — backend-portada-ia-storage

**Date:** 2026-06-05T23:14:59Z

## Variables nuevas — api-gateway/.env.example

| Variable | Obligatoria | Descripción | Ejemplo |
|----------|-------------|-------------|---------|
| `FIREBASE_STORAGE_BUCKET` | Sí | Nombre del bucket Firebase Storage | `your-project.appspot.com` |
| `GEMINI_IMAGE_MODEL` | Sí (runtime) | Model ID de Gemini para generación de imagen | `gemini-2.0-flash-preview-image-generation` |

## Notas

- `FIREBASE_STORAGE_BUCKET`: se pasa como `storageBucket` en ambas ramas de `initializeApp()` dentro de `firebase-auth.service.ts`. Si no está definida, el arranque del servicio no fallará (la variable es opcional en initializeApp), pero `StorageService.uploadCover()` fallará al intentar obtener el bucket default.
- `GEMINI_IMAGE_MODEL`: si no está definida en el entorno, `GeminiService.generateCover()` lanza `Error('GEMINI_IMAGE_MODEL env var not set')` inmediatamente antes de llamar al SDK. El proceso NO falla al arrancar; solo falla en runtime al invocar el endpoint.
- Las variables `GEMINI_API_KEY` y `FIREBASE_SERVICE_ACCOUNT_JSON` / `FIREBASE_PROJECT_ID` ya existen en `.env.example` y no se modifican.

## Documentación para EC2

En el documento de deploy EC2 (o secrets manager), agregar:

```
FIREBASE_STORAGE_BUCKET=<bucket-name-from-firebase-console>
GEMINI_IMAGE_MODEL=gemini-2.0-flash-preview-image-generation
```

El bucket debe tener acceso público habilitado. Ver sección "Acceso público al bucket" en el handoff principal.
