# Backend → Handoff — backend-portada-ia-storage

**Completado:** 2026-06-05T23:27:50Z (corrección Auditor)
**Repositorio:** `/Users/cami/Developer/Personal/rideglory-api`

---

## Baseline

78 tests pasando antes de empezar (7 suites, 0 fallos).

```
Test Suites: 5 passed, 5 total
Tests:       78 passed, 78 total
```

---

## Archivos cambiados

### Modificados
- `api-gateway/.env.example` — agregadas `GEMINI_IMAGE_MODEL` y `FIREBASE_STORAGE_BUCKET` con comentarios de configuración EC2
- `api-gateway/src/auth/firebase-auth.service.ts` — agregado `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` en ambas ramas de `initializeFirebaseApp()` (rama `cert()` y rama `projectId`)
- `api-gateway/src/ai/gemini.service.ts` — agregada propiedad `imageModel`, inicializada en constructor desde `process.env.GEMINI_IMAGE_MODEL ?? ''`; nuevo método `generateCover(prompt)` que valida env var, llama SDK con `responseModalities: ['IMAGE']`, extrae buffer base64 + mimeType de `inlineData`
- `api-gateway/src/ai/ai.controller.ts` — inyectado `StorageService`; nuevo handler `POST /ai/cover` que extrae `userId` de `request.user!.uid`, delega a `generateCover` + `uploadCover`, retorna `{ imageUrl, remainingGenerations: -1 }`
- `api-gateway/src/ai/ai.module.ts` — agregados `StorageService` y `StorageCleanupService` a `providers`
- `api-gateway/src/ai/ai.controller.spec.ts` — inyectado mock de `StorageService`; agregados tests para `generateCover` handler
- `rideglory-contracts/src/ai/dto/index.ts` — re-exportados `AiCoverRequestDto` y `AiCoverResponseDto`

### Creados
- `rideglory-contracts/src/ai/dto/ai-cover-request.dto.ts` — DTO con `prompt` (string) + `draftId` (UUID); comentario de excepción Pattern B
- `rideglory-contracts/src/ai/dto/ai-cover-response.dto.ts` — DTO con `imageUrl` + `remainingGenerations` (-1 sentinel); comentario de excepción Pattern B
- `api-gateway/src/ai/storage.service.ts` — `StorageService.uploadCover(userId, draftId, buffer, mimeType)`: construye ruta `pending/{userId}/{draftId}.{ext}`, llama `file.save()` + `file.makePublic()`, retorna URL pública estática. Comentario UBLA inline con alternativa signed URL si es necesario.
- `api-gateway/src/ai/storage-cleanup.service.ts` — `StorageCleanupService` con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })`: borra archivos `pending/` cuyo `new Date(metadata.timeCreated) < sevenDaysAgo`
- `api-gateway/src/ai/storage.service.spec.ts` — 7 tests unitarios
- `api-gateway/src/ai/storage-cleanup.service.spec.ts` — 6 tests unitarios
- `api-gateway/src/ai/gemini.service.spec.ts` — 6 tests unitarios (nuevo, requerido por Auditor)

---

## Pruebas nuevas

| Suite | Tests | Qué verifica |
|-------|-------|--------------|
| `storage.service.spec.ts` | 7 | Ruta `pending/{uid}/{draftId}.{ext}`, contentType correcto, extensión por mimeType (jpg/png/webp/fallback), URL de retorno, propagación de errores |
| `storage-cleanup.service.spec.ts` | 6 | Borra solo archivos elegibles (`< sevenDaysAgo`), no borra recientes, no borra el archivo en el límite exacto (>=), query con prefix `pending/`, folder vacío |
| `ai.controller.spec.ts` (ampliado) | +1 | Handler `POST /ai/cover` retorna `imageUrl` y `remainingGenerations: -1`; llama a `generateCover` y `uploadCover` con args correctos |
| `gemini.service.spec.ts` (nuevo) | 6 | AC5: env var faltante lanza error SIN llamar el SDK (2 tests); respuesta sin inlineData lanza `'Gemini did not return image data'` (2 tests); respuesta válida devuelve buffer + mimeType; SDK llamado con modelo y prompt correctos |

**Total final: 98 tests, 8 suites, 0 fallos.**

---

## Resultado final

```
Test Suites: 8 passed, 8 total
Tests:       98 passed, 98 total
Snapshots:   0 total
Time:        0.692 s
```

---

## Verificación manual (Gate Día 1)

Para verificar escritura y acceso público al bucket antes de desplegar:

1. Configurar `.env` local con credenciales reales:
   ```
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
   FIREBASE_STORAGE_BUCKET=your-project.appspot.com
   GEMINI_API_KEY=real-key
   GEMINI_IMAGE_MODEL=gemini-2.0-flash-preview-image-generation
   ```

2. Arrancar el servidor: `npm run start:dev`

3. Obtener un token Firebase válido y ejecutar:
   ```bash
   curl -X POST http://localhost:3000/api/ai/cover \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Ruta nocturna por Medellín", "draftId": "550e8400-e29b-41d4-a716-446655440000"}'
   ```

4. Verificar respuesta `200 { imageUrl, remainingGenerations: -1 }`.

5. Verificar acceso público: `curl -I <imageUrl>` → HTTP 200 sin 401/403.

**Nota UBLA:** Si el bucket tiene Uniform Bucket-Level Access activo, `makePublic()` lanzará un error. En ese caso, cambiar a `getSignedUrl()` en `storage.service.ts` (ver comentario inline) o configurar el IAM binding `allUsers → roles/storage.objectViewer` a nivel de bucket.

---

## Notas Frontend/QA

- **Nuevo endpoint disponible:** `POST /api/ai/cover`
  - Body: `{ prompt: string, draftId: UUID }`
  - Response: `{ imageUrl: string, remainingGenerations: -1 }`
  - Requiere token Firebase válido (FirebaseAuthGuard global)
  - `remainingGenerations: -1` es sentinel; cuota real en Fase 3 — el cliente Flutter debe ignorar este campo en Fase 2

- **Endpoint legacy intacto:** `POST /api/events/generate-cover` no fue modificado.

- **Endpoint Fase 1 intacto:** `POST /api/ai/description` no fue modificado.

- **Manejo de errores en Fase 2:** errores de Gemini y Storage propagan como HTTP 500. Mapeo tipado (422/503) es responsabilidad de Fase 3.

- **`imageUrl` formato:** `https://storage.googleapis.com/{bucket}/pending/{userId}/{draftId}.{ext}` — p.ej. `https://storage.googleapis.com/my-project.appspot.com/pending/user-123/550e8400-e29b-41d4-a716-446655440000.png` — accesible públicamente sin autenticación (suponiendo sin UBLA).

- **Contratos disponibles:** `AiCoverRequestDto` y `AiCoverResponseDto` exportados desde `@rideglory/contracts`.
