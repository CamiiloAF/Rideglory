# Tech Lead Handoff — backend-portada-ia-storage

**Completado:** 2026-06-05T23:38:54Z
**Revisor:** Tech Lead (claude-sonnet-4-6)

---

## Veredicto

**READY** — Sin blockers. Todos los ACs verificados por tests o verificación estática. Pruebas manuales (Gate Día 1, log cron) documentadas como gaps intencionales que requieren credenciales reales.

---

## Hallazgos

### Watchlist (no bloqueantes)

1. **Sin timeout en `generateCover`** — `generateDescription` usa `Promise.race()` con 30 s; `generateCover` no. Aceptable en Fase 2 (PRD lo excluye); añadir en Fase 3 junto al mapeo de errores tipados.

2. **`FIREBASE_STORAGE_BUCKET` no validada al arranque** — Si la var no está configurada, Firebase inicia sin bucket y el error ocurre solo al primer llamado a `uploadCover`. Fase 3 puede agregar validación explícita en módulo.

3. **`console.error` en `firebase-auth.service.ts` línea 17** — Pre-existente (no introducido en esta fase); debería usar `this.logger.error()`. Candidato a limpieza en próxima iteración que toque ese archivo.

---

## Seguridad

- **Autenticación:** `POST /ai/cover` protegido por `FirebaseAuthGuard` global (`APP_GUARD` en `AuthModule`). El `userId` se extrae del token validado (`request.user!.uid`), nunca del body.
- **Validación de input:** `draftId` validado como UUID vía `@IsUUID()` (class-validator + ValidationPipe global) — mitiga path traversal.
- **Sin secretos en logs:** solo se loguea la URL pública del archivo subido; no se loguea el buffer ni el prompt.
- **Sin SQL concatenado:** usa Firebase Admin SDK (no ORM con raw queries).
- **CORS/UBLA:** `makePublic()` documentado con alternativa `getSignedUrl()` para buckets con UBLA activo. El Gate Día 1 detecta este caso.

---

## Arquitectura

- **Clean Architecture:** `StorageService` y `StorageCleanupService` en capa de infraestructura dentro de `AiModule`. No hay dependencias circulares.
- **firebase-admin singleton:** `getApps()[0]` en ambos servicios — correcto per constraints §7.
- **Env vars nunca hardcodeadas:** `GEMINI_IMAGE_MODEL` leído desde `process.env` en constructor; el método lanza si está vacío. Cron usa string raw + `{ timeZone: 'America/Bogota' }` per convención del repo.
- **Pattern B exception:** `AiCoverRequestDto` y `AiCoverResponseDto` documentan la excepción con comentario inline — correcto.
- **Guardrails respetados:** `POST /events/generate-cover`, `POST /ai/description`, `GeminiService.generateDescription()`, providers Fase 1 en `AiModule` — todos intactos.
- **`ScheduleModule.forRoot()`** confirmado en `app.module.ts`; `AiModule` confirmado en `imports` de `AppModule` — cron se registrará en arranque.

---

## Tests

| Suite | Tests | Estado |
|-------|-------|--------|
| `storage.service.spec.ts` | 7 | PASA |
| `storage-cleanup.service.spec.ts` | 6 | PASA |
| `gemini.service.spec.ts` | 6 | PASA |
| `ai.controller.spec.ts` | 8 (+1 generateCover) | PASA |
| Suites previas | 78 | PASA (sin regresión) |
| **Total** | **98 / 98** | **VERDE** |

Cobertura AC → test:

| AC | Estado |
|----|--------|
| CA-1: vars en `.env.example` | CUBIERTO (verificación estática) |
| CA-2: Gate Día 1 escritura real | GAP INTENCIONAL — requiere credenciales |
| CA-3: `POST /ai/cover` → 200 | CUBIERTO (`ai.controller.spec.ts`) |
| CA-4: ruta y extensión correctas | CUBIERTO (`storage.service.spec.ts`) |
| CA-5: env var faltante lanza error sin llamar SDK | CUBIERTO (`gemini.service.spec.ts` × 2) |
| CA-6: legacy `POST /events/generate-cover` intacto | CUBIERTO (suites pre-existentes) |
| CA-7: cron borra solo elegibles, respeta límite exacto | CUBIERTO (`storage-cleanup.service.spec.ts`) |
| CA-8: cron registrado en arranque | GAP INTENCIONAL — requiere servidor real |
| CA-9: DTOs importables desde `@rideglory/contracts` | CUBIERTO (`npm run build` sin errores) |

---

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` para los pasos completos. Resumen:

1. Gate Día 1: `POST /api/ai/cover` con credenciales reales → HTTP 200 + acceso público a la URL.
2. Log de cron en arranque del servidor.
3. Confirmación de que los endpoints legacy (`/events/generate-cover`, `/ai/description`) siguen respondiendo.
