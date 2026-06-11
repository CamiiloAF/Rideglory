# QA Handoff — backend-portada-ia-storage

**Completado:** 2026-06-05T23:34:46Z
**QA agent:** claude-sonnet-4-6
**Repos analizados:** rideglory-api (api-gateway + rideglory-contracts); Flutter (Rideglory)

---

## Catalogo AC vs Tests

| CA | Descripcion | Test que cubre | Estado |
|----|-------------|----------------|--------|
| CA-1 | `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` en `.env.example` | Verificación manual via grep | CUBIERTO — ambas vars presentes en líneas 42 y 46 con comentarios EC2 |
| CA-2 | Gate día 1: escritura al bucket sin error de permisos | Test manual (requiere credenciales reales) | GAP intencional — no ejecutable en entorno de prueba sin bucket real |
| CA-3 | `POST /ai/cover` → 200 `{ imageUrl, remainingGenerations: -1 }` | `ai.controller.spec.ts` test handler `/ai/cover` | CUBIERTO |
| CA-4 | `imageUrl` apunta a `pending/{uid}/{draftId}.{ext}` con ext correcta | `storage.service.spec.ts` — tests de ruta y extensión | CUBIERTO |
| CA-5 | `GEMINI_IMAGE_MODEL` no definida → lanza `'GEMINI_IMAGE_MODEL env var not set'` | `gemini.service.spec.ts` — 2 tests (undefined y '') | CUBIERTO |
| CA-6 | `POST /events/generate-cover` legacy sigue respondiendo | Tests existentes pre-fase pasan sin cambios | CUBIERTO |
| CA-7 | Cron borra `timeCreated < sevenDaysAgo`, no borra el límite exacto (>=) | `storage-cleanup.service.spec.ts` — tests de límite exacto, recientes, elegibles | CUBIERTO |
| CA-8 | `StorageCleanupService` registra cron en arranque | Verificación manual de logs (requiere servidor real); `@Cron` en código verificado | GAP intencional — solo verificable en entorno de ejecución real |
| CA-9 | `AiCoverRequestDto` y `AiCoverResponseDto` importables desde `@rideglory/contracts` | `npm run build` en rideglory-contracts compila sin error | CUBIERTO |

---

## Matriz de Regresion — Guardrails §6

| Guardrail | Mecanismo de verificacion | Resultado |
|-----------|--------------------------|-----------|
| `POST /events/generate-cover` intacto | Suite de tests pre-existente; archivo no modificado | PASA |
| `firebase-auth.service.ts` — solo agrega `storageBucket` | Grep: solo 2 líneas con `storageBucket` agregadas; comportamiento auth no alterado | PASA |
| `GeminiService` — métodos existentes intactos | `gemini.service.spec.ts` — tests de `generateDescription` siguen pasando; `generateCover` es addición | PASA |
| `AiController` — handler de Fase 1 no removido | `ai.controller.ts` mantiene `@Post('description')`; `@Post('cover')` es adición | PASA |
| `AiModule` — providers existentes no eliminados | `ai.module.ts` contiene todos los providers de Fase 1 + nuevos | PASA |
| Tests Fase 1 (`gemini.service.spec.ts`) siguen pasando | `gemini.service.spec.ts` nuevo cubre tanto tests anteriores como nuevos — 6 tests, todos pasan | PASA |
| Sin modificaciones Flutter (`lib/`, `test/`) | `dart analyze` — 0 issues; 823 tests Flutter pasan; git diff no muestra cambios en lib/ | PASA |
| Sin modificaciones `workflow/state.json` etc. | Fuera del alcance de la fase — no tocados | PASA |

---

## Ejecucion de Suites

### Backend (api-gateway)
```
Test Suites: 8 passed, 8 total
Tests:       98 passed, 98 total (baseline 78, +20 nuevos)
Time:        ~0.7 s
```
- Suites nuevas: `storage.service.spec.ts` (7 tests), `storage-cleanup.service.spec.ts` (6 tests), `gemini.service.spec.ts` (6 tests nuevo)
- Suite ampliada: `ai.controller.spec.ts` (+1 test handler /ai/cover)
- `npm run build` (TypeScript): compila sin errores
- `rideglory-contracts npm run build`: compila sin errores

### Flutter (Rideglory)
```
dart analyze: No issues found!
flutter test:  823 passed, 0 failed
```
- Sin cambios en Flutter — tests pre-existentes todos verdes.

---

## Bugs

Ningún bug encontrado. El árbol de trabajo Flutter no fue modificado por esta fase.

---

## Pruebas Manuales (pendientes de humano)

Las siguientes pruebas requieren credenciales reales y un servidor en ejecución:

1. **Gate Día 1 (CA-2):** Configurar `.env` con credenciales Firebase reales (`FIREBASE_STORAGE_BUCKET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `GEMINI_API_KEY`, `GEMINI_IMAGE_MODEL`). Ejecutar:
   ```bash
   curl -X POST http://localhost:3000/api/ai/cover \
     -H "Authorization: Bearer <firebase-token>" \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Ruta nocturna por Medellín", "draftId": "550e8400-e29b-41d4-a716-446655440000"}'
   ```
   Verificar: HTTP 200, `imageUrl` con ruta `pending/{uid}/{draftId}.{ext}`.

2. **Acceso público (CA-4 end-to-end):** `curl -I <imageUrl>` → HTTP 200 sin 401/403.
   - Si el bucket tiene UBLA activo, `makePublic()` fallará — cambiar a `getSignedUrl()` según comentario en `storage.service.ts`.

3. **Log de cron en arranque (CA-8):** `npm run start:dev` y buscar en logs `StorageCleanup.*registered` o logs del scheduler NestJS que confirmen detección del cron.

4. **Cron manual:** Invocar `cleanPendingCovers()` directamente para verificar que borra solo archivos elegibles en bucket real.

---

## Sign-off

**CONDITIONAL**

- Los 98 tests backend pasan. Los 823 tests Flutter pasan. `dart analyze` sin issues. TypeScript compila sin errores. `rideglory-contracts` compila sin errores.
- CA-1, CA-3, CA-4, CA-5, CA-6, CA-7, CA-9 cubiertos por tests unitarios o verificación estática.
- CA-2 (gate día 1 escritura real) y CA-8 (log cron arranque) son gaps intencionales que requieren verificación manual con credenciales reales antes de hacer merge a producción.
- Ninguna regresión detectada.
