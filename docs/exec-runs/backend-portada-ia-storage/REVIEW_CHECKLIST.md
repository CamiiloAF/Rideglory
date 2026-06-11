# REVIEW CHECKLIST — backend-portada-ia-storage

**Generado:** 2026-06-05T23:38:54Z

Pasos manuales antes de commitear. Los unitarios ya pasaron (98/98). Solo quedan los que requieren credenciales reales o servidor vivo.

---

## Antes de commit

- [ ] **Revisar diff completo** en `rideglory-api/api-gateway/src/ai/` y `rideglory-contracts/src/ai/dto/` — confirmar que no hay archivos inesperados.
- [ ] **Verificar `.env.example`** — `GEMINI_IMAGE_MODEL` y `FIREBASE_STORAGE_BUCKET` presentes con valores ejemplo no-producción.

---

## Gate Día 1 (requiere credenciales reales — hacer antes de deploy a EC2)

1. Crear `.env` local en `api-gateway/` con:
   ```
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
   FIREBASE_STORAGE_BUCKET=tu-proyecto.appspot.com
   GEMINI_API_KEY=<clave real>
   GEMINI_IMAGE_MODEL=gemini-2.0-flash-preview-image-generation
   ```

2. Arrancar servidor:
   ```bash
   cd rideglory-api/api-gateway && npm run start:dev
   ```

3. Verificar log de cron en arranque — buscar que NestJS registra el scheduler de `StorageCleanupService` (CA-8).

4. Obtener token Firebase válido y ejecutar:
   ```bash
   curl -X POST http://localhost:3000/api/ai/cover \
     -H "Authorization: Bearer <firebase-token>" \
     -H "Content-Type: application/json" \
     -d '{"prompt": "Ruta nocturna por Medellín", "draftId": "550e8400-e29b-41d4-a716-446655440000"}'
   ```
   Verificar: HTTP 200, body `{ imageUrl, remainingGenerations: -1 }`.

5. Verificar acceso público al archivo:
   ```bash
   curl -I <imageUrl>
   ```
   Esperado: HTTP 200 sin 401/403.

   **Si falla con 403 (UBLA activo):** En `storage.service.ts` reemplazar las líneas `makePublic()` + URL estática por `getSignedUrl()` (ver comentario inline) y re-ejecutar.

6. Verificar que `POST /api/events/generate-cover` sigue respondiendo (guardrail de regresión).

7. Verificar que `POST /api/ai/description` sigue respondiendo (guardrail Fase 1).

---

## Commits

- Commitear solo cuando Gate Día 1 pase o con nota explícita de que se validará en EC2.
- Usar el mensaje de commit sugerido en `SUMMARY.md`.
- Commitear por separado `rideglory-api/` (submodule) y el puntero del submodule en el repo raíz si corresponde.
