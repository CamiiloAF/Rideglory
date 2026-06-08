# SUMMARY — backend-portada-ia-storage

**Generado:** 2026-06-05T23:38:54Z
**Revisor:** Tech Lead (claude-sonnet-4-6)

---

## Objetivo

Habilitar `api-gateway` para generar una imagen de portada 16:9 vía Gemini imagen, subirla a Firebase Storage bajo `pending/{userId}/{draftId}.{ext}`, y exponerla al cliente Flutter mediante `POST /ai/cover`. Un cron semanal borra archivos `pending/` con más de 7 días.

---

## Qué cambió por área

### rideglory-api/api-gateway

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `src/auth/firebase-auth.service.ts` | Modificado | `storageBucket` en ambas ramas de `initializeFirebaseApp()` |
| `.env.example` | Modificado | `GEMINI_IMAGE_MODEL` + `FIREBASE_STORAGE_BUCKET` con comentarios EC2 |
| `src/ai/gemini.service.ts` | Modificado | `imageModel` property + `generateCover()` con validación env var |
| `src/ai/ai.controller.ts` | Modificado | `StorageService` inyectado; handler `POST /ai/cover` |
| `src/ai/ai.module.ts` | Modificado | `StorageService` + `StorageCleanupService` en providers |
| `src/ai/storage.service.ts` | Creado | `uploadCover()`: ruta `pending/{uid}/{draftId}.{ext}`, makePublic, URL pública |
| `src/ai/storage-cleanup.service.ts` | Creado | `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })` borra pending/ > 7 días |
| `src/ai/storage.service.spec.ts` | Creado | 7 tests |
| `src/ai/storage-cleanup.service.spec.ts` | Creado | 6 tests |
| `src/ai/gemini.service.spec.ts` | Creado | 6 tests |
| `src/ai/ai.controller.spec.ts` | Modificado | +1 test generateCover handler |

### rideglory-api/rideglory-contracts

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `src/ai/dto/ai-cover-request.dto.ts` | Creado | `prompt` + `draftId: UUID`; excepción Pattern B documentada |
| `src/ai/dto/ai-cover-response.dto.ts` | Creado | `imageUrl` + `remainingGenerations` (sentinel -1) |
| `src/ai/dto/index.ts` | Modificado | Re-exporta ambos DTOs nuevos |

### Flutter (Rideglory)
Sin cambios. `dart analyze`: 0 issues. Tests: 823 pasando.

---

## Archivos

```
rideglory-api/api-gateway/
  .env.example
  src/auth/firebase-auth.service.ts
  src/ai/gemini.service.ts
  src/ai/ai.controller.ts
  src/ai/ai.module.ts
  src/ai/storage.service.ts              (NUEVO)
  src/ai/storage-cleanup.service.ts      (NUEVO)
  src/ai/storage.service.spec.ts         (NUEVO)
  src/ai/storage-cleanup.service.spec.ts (NUEVO)
  src/ai/gemini.service.spec.ts          (NUEVO)
  src/ai/ai.controller.spec.ts
rideglory-api/rideglory-contracts/
  src/ai/dto/ai-cover-request.dto.ts     (NUEVO)
  src/ai/dto/ai-cover-response.dto.ts    (NUEVO)
  src/ai/dto/index.ts
```

---

## Pruebas

| Suite | Tests | Resultado |
|-------|-------|-----------|
| `storage.service.spec.ts` | 7 | PASA |
| `storage-cleanup.service.spec.ts` | 6 | PASA |
| `gemini.service.spec.ts` | 6 | PASA |
| `ai.controller.spec.ts` | 8 (+1) | PASA |
| Suites previas Phase 1 | 71 | PASA |
| **Total backend** | **98 / 98** | **VERDE** |
| Flutter | 823 | PASA |
| rideglory-contracts build | 0 errores | VERDE |

---

## Riesgos / Watchlist

1. **UBLA sin verificar en prod:** Gate Día 1 debe ejecutarse antes de merge. Ver REVIEW_CHECKLIST.md.
2. **Sin timeout en `generateCover`:** `generateDescription` tiene 30 s timeout; `generateCover` no. Candidato Fase 3.
3. **Errores de Gemini/Storage como 500:** Por diseño en Fase 2. Cliente Flutter debe manejar con mensaje genérico.
4. **`FIREBASE_STORAGE_BUCKET` no validada al arranque:** Error solo ocurre al primer `uploadCover`. Candidato Fase 3.

---

## Mensaje de commit sugerido

```
feat(ai): endpoint POST /ai/cover — portada IA con Gemini imagen y Firebase Storage

- StorageService: sube portada a pending/{userId}/{draftId}.{ext}
- StorageCleanupService: cron dominical (3 AM Bogotá) purga pending/ > 7 días
- GeminiService.generateCover(): genera imagen vía GEMINI_IMAGE_MODEL env var
- AiController: handler POST /ai/cover con guard global FirebaseAuthGuard
- AiCoverRequestDto / AiCoverResponseDto en rideglory-contracts
- firebase-auth.service: storageBucket en ambas ramas de initializeApp()
- .env.example: +GEMINI_IMAGE_MODEL +FIREBASE_STORAGE_BUCKET (docs EC2)
- 20 tests nuevos (98 total, 0 fallos)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```
