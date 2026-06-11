> Slim handoff — lee esto antes de docs/exec-runs/backend-portada-ia-storage/handoffs/architect.md

# Architect → QA — backend-portada-ia-storage

**Repo afectado:** rideglory-api (api-gateway + rideglory-contracts); Flutter sin cambios.

---

## Comandos de verificación

```bash
# Desde api-gateway/
npm run build        # TypeScript debe compilar sin error
npm test             # Todos los tests deben pasar

# Tests específicos nuevos
npm test -- --testPathPattern=storage.service
npm test -- --testPathPattern=storage-cleanup.service
npm test -- --testPathPattern=ai.controller   # Tests existentes no deben romperse

# Desde rideglory-contracts/
npm run build        # Contratos nuevos deben compilar
```

---

## Criterios de aceptación con traceabilidad

| CA | Qué verificar | Cómo |
|----|---------------|------|
| CA-1 | `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` en `.env.example` | `grep FIREBASE_STORAGE_BUCKET api-gateway/.env.example` y `grep GEMINI_IMAGE_MODEL` |
| CA-2 | Gate día 1: escritura al bucket sin error de permisos | Ejecutar script de prueba o invocar `uploadCover()` en test de integración local |
| CA-3 | `POST /api/ai/cover` con payload válido → 200 `{ imageUrl, remainingGenerations: -1 }` | Test unitario mock en `ai.controller.spec.ts` ampliado |
| CA-4 | `imageUrl` apunta a `pending/{uid}/{draftId}.{ext}` y ext coincide con mimeType | Assert en test de `storage.service.spec.ts` |
| CA-5 | Si `GEMINI_IMAGE_MODEL` no definida → `generateCover()` lanza `'GEMINI_IMAGE_MODEL env var not set'` | Test en `gemini.service.spec.ts` ampliado |
| CA-6 | `POST /api/events/generate-cover` sigue respondiendo (legacy intacto) | Test existente `generate-cover.spec.ts` debe pasar sin cambios |
| CA-7 | Cron borra archivos con `timeCreated < sevenDaysAgo`, no borra los del límite exacto | Test unitario en `storage-cleanup.service.spec.ts` con fechas mockeadas |
| CA-8 | `StorageCleanupService` registra cron en logs de arranque | Arranque local y grep en logs: `StorageCleanup.*registered` o similar de NestJS |
| CA-9 | `AiCoverRequestDto` y `AiCoverResponseDto` importables desde `@rideglory/contracts` | `import { AiCoverRequestDto, AiCoverResponseDto } from '@rideglory/contracts'` compila sin error |

---

## Guardrails de regresión a vigilar

- `ai.controller.spec.ts` existente: todos los tests del handler `POST /ai/description` deben pasar intactos
- `generate-cover.spec.ts` en events/: no debe ser tocado ni romperse
- Flutter: no hay cambios; `flutter test` y `dart analyze` deben pasar igual que antes

---

## Tests nuevos requeridos

### `storage.service.spec.ts`
- `uploadCover()` llama a `bucket.file()` con ruta `pending/{userId}/{draftId}.{ext}` correcta
- `uploadCover()` usa `contentType` correcto al llamar `save()`
- Extensión: `image/jpeg` → `jpg`, `image/png` → `png`, `image/webp` → `webp`
- Retorna la URL pública en el formato esperado

### `storage-cleanup.service.spec.ts`
- `cleanPendingCovers()` borra archivos con `timeCreated` estrictamente anterior a 7 días
- NO borra archivos con `timeCreated` igual al límite (>= sevenDaysAgo)
- NO borra archivos recientes
- Llama a `file.delete()` exactamente N veces para N archivos elegibles

### Ampliación de `gemini.service.spec.ts`
- `generateCover()` lanza `Error('GEMINI_IMAGE_MODEL env var not set')` cuando env var es `undefined` o `''`
- `generateCover()` extrae correctamente `buffer` y `mimeType` de la respuesta mockeada

> Full detail: docs/exec-runs/backend-portada-ia-storage/handoffs/architect.md
