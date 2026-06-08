# Architect handoff — backend-portada-ia-storage

**Date:** 2026-06-05T23:14:59Z
**Status:** done
**Repo afectado:** rideglory-api (api-gateway + rideglory-contracts); Flutter sin cambios.

---

## Decisiones

| # | Decisión | Justificación |
|---|----------|---------------|
| D1 | `storageBucket` se agrega en ambas ramas de `initializeApp()` en `firebase-auth.service.ts` | Es el único punto donde se llama `initializeApp`; StorageService usa `getStorage(getApps()[0]).bucket()` sin argumento, que usa el bucket default configurado aquí. Alternativa `bucket(bucketName)` también válida pero menos idiomática con firebase-admin. |
| D2 | `FirebaseAuthGuard` es global (APP_GUARD en AuthModule) — `POST /ai/cover` no necesita `@UseGuards()` explícito | La revisión del AuthModule confirma `APP_GUARD`. El handler usa `@Req() request: AuthenticatedRequest` para extraer `request.user!.uid`. El PRD dice "con FirebaseAuthGuard" — cumplido vía global. |
| D3 | Acceso público al bucket: documentar ambas estrategias (binding IAM `allUsers` vs signed URL), elegir en implementación según estado real de UBLA | No se puede saber desde código si UBLA está activo; la decisión final la toma el implementador en el gate día 1. El handoff `architect-for-backend.md` describe ambas rutas. |
| D4 | `StorageService` y `StorageCleanupService` como `@Injectable()` (no singleton) dentro de AiModule | Ciclo de vida manejado por NestJS; no necesitan estado global; singleton sería overhead innecesario. |
| D5 | `remainingGenerations: -1` como sentinel en `AiCoverResponseDto` | Consistencia con `AiDescriptionResponseDto` existente; cuota real en Fase 3. |
| D6 | Errores de Gemini/Storage propagan como 500 en esta fase | Mapeo tipado (422/503/429) es responsabilidad exclusiva de Fase 3. Sin captura especial en `POST /ai/cover` salvo lo que ya propaga NestJS. |
| D7 | `GEMINI_IMAGE_MODEL` hardcoding prohibido — siempre desde `process.env` | Constraint heredado del PRD; el valor lo decide el operador, no el código. |
| D8 | `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })` — raw string, no `CronExpression.*` | Convención confirmada en el repo; ScheduleModule.forRoot() ya está en AppModule. |

---

## Change map

| Repositorio | Archivo | Acción | Razón | Riesgo |
|-------------|---------|--------|-------|--------|
| rideglory-api | `api-gateway/.env.example` | modify | Agregar `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` | low |
| rideglory-api | `api-gateway/src/auth/firebase-auth.service.ts` | modify | Agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` en ambas ramas de `initializeApp()` | low |
| rideglory-contracts | `rideglory-contracts/src/ai/dto/ai-cover-request.dto.ts` | create | DTO de request para POST /ai/cover | low |
| rideglory-contracts | `rideglory-contracts/src/ai/dto/ai-cover-response.dto.ts` | create | DTO de response para POST /ai/cover | low |
| rideglory-contracts | `rideglory-contracts/src/ai/dto/index.ts` | modify | Re-exportar los 2 nuevos DTOs | low |
| rideglory-api | `api-gateway/src/ai/gemini.service.ts` | modify | Agregar método `generateCover(prompt: string): Promise<{ buffer: Buffer; mimeType: string }>` | low |
| rideglory-api | `api-gateway/src/ai/storage.service.ts` | create | Subir buffer a Firebase Storage bajo `pending/{userId}/{draftId}.{ext}`, devolver URL pública | med |
| rideglory-api | `api-gateway/src/ai/storage-cleanup.service.ts` | create | Cron semanal que borra archivos `pending/` con más de 7 días | low |
| rideglory-api | `api-gateway/src/ai/ai.controller.ts` | modify | Inyectar `StorageService`; agregar handler `POST /ai/cover` con `@Req()` para userId | low |
| rideglory-api | `api-gateway/src/ai/ai.module.ts` | modify | Agregar `StorageService` y `StorageCleanupService` a `providers` | low |
| rideglory-api | `api-gateway/src/ai/storage.service.spec.ts` | create | Tests unitarios de `StorageService` | low |
| rideglory-api | `api-gateway/src/ai/storage-cleanup.service.spec.ts` | create | Tests unitarios de `StorageCleanupService` | low |

---

## Contratos

### POST /ai/cover

- **Auth:** global FirebaseAuthGuard (Bearer token Firebase requerido; no se usa `@Public()`)
- **Path:** `POST /api/ai/cover`
- **Request body:** `AiCoverRequestDto`

```typescript
// rideglory-contracts/src/ai/dto/ai-cover-request.dto.ts
// Composite DTO: request-only; no 1:1 domain model (Pattern B exception)
export class AiCoverRequestDto {
  @IsString()
  @IsNotEmpty()
  prompt!: string;

  @IsUUID()
  draftId!: string;
}
```

- **Success (200):** `AiCoverResponseDto`

```typescript
// rideglory-contracts/src/ai/dto/ai-cover-response.dto.ts
// Composite DTO: control field + domain data; no 1:1 domain model (Pattern B exception)
export class AiCoverResponseDto {
  imageUrl!: string;
  remainingGenerations!: number; // -1 sentinel hasta Fase 3
}
```

- **Errors:**
  - 401 — token ausente o inválido (global guard)
  - 500 — fallo Gemini o fallo Storage (no se mapean en Fase 2)

### Flujo de datos

```
POST /api/ai/cover
  → AiController.generateCover(dto, req)
      userId = req.user!.uid
      { buffer, mimeType } = await geminiService.generateCover(dto.prompt)
      imageUrl = await storageService.uploadCover(userId, dto.draftId, buffer, mimeType)
      return { imageUrl, remainingGenerations: -1 }
```

### GeminiService.generateCover(prompt)

- Lanza `Error('GEMINI_IMAGE_MODEL env var not set')` si env var falta
- Llama `this.ai.models.generateContent({ model, contents, config: { responseModalities: ['IMAGE'] } })`
- Extrae `candidates[0].content.parts[0].inlineData.data` (base64) → `Buffer.from(base64, 'base64')`
- Extrae `candidates[0].content.parts[0].inlineData.mimeType` para determinar extensión
- Retorna `{ buffer: Buffer, mimeType: string }`

### StorageService.uploadCover(userId, draftId, buffer, mimeType)

- Obtiene bucket: `getStorage(getApps()[0]).bucket()` (usa storageBucket default de initializeApp)
- Extensión: `mimeType === 'image/jpeg' ? 'jpg' : 'png'` (extendible)
- Ruta: `pending/${userId}/${draftId}.${ext}`
- Sube con `file.save(buffer, { contentType: mimeType })`
- **Acceso público (elegir en gate día 1):**
  - Opción A (sin UBLA): `await file.makePublic()` → URL = `https://storage.googleapis.com/${bucket.name}/${filePath}`
  - Opción B (con UBLA activo): signed URL de larga duración (7 días) con `file.getSignedUrl({ action: 'read', expires: ... })`
  - Documentar la opción elegida en los comentarios del servicio
- Retorna `imageUrl: string`

---

## Datos / Migraciones

No hay cambios de base de datos. No se requiere `MIGRATION_PLAN.md`.

La única "migración" de estado es el bucket Firebase Storage (debe tener acceso público configurado). Esta configuración es manual en Firebase Console y está fuera del alcance del código.

---

## Env

Ver `analysis/ENV_DELTA.md` para detalle completo.

| Variable | Obligatoria | Ejemplo |
|----------|-------------|---------|
| `FIREBASE_STORAGE_BUCKET` | Sí | `your-project.appspot.com` |
| `GEMINI_IMAGE_MODEL` | Sí (runtime) | `gemini-2.0-flash-preview-image-generation` |

---

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|-----------|
| UBLA activo en bucket → `makePublic()` falla silenciosamente o lanza 403 | Media | Alto | Gate día 1 obligatorio: verificar escritura Y lectura pública antes de implementar lógica de generación; documentar opción elegida (signed URL o IAM binding) |
| `inlineData` ausente en respuesta Gemini imagen | Baja | Medio | Verificar `parts[0]?.inlineData` antes de acceder; lanzar error descriptivo si falta |
| `GEMINI_IMAGE_MODEL` no disponible en el tenant del proyecto | Baja | Alto | Documentar modelo exacto a configurar; el fallo es 500 en Fase 2, tipado en Fase 3 |
| `storageBucket` en `initializeApp()` no coincide con bucket real | Baja | Alto | `.env.example` documenta el valor esperado; validar en gate día 1 |
| Cron `StorageCleanupService` no se registra si `AiModule` no está en AppModule | No aplica | Alto | Verificado: `AiModule` ya está en `imports` de `AppModule` y `ScheduleModule.forRoot()` ya está presente |

---

## Orden de implementación

1. `api-gateway/.env.example` — vars primero
2. `rideglory-contracts/src/ai/dto/ai-cover-request.dto.ts` — crear
3. `rideglory-contracts/src/ai/dto/ai-cover-response.dto.ts` — crear
4. `rideglory-contracts/src/ai/dto/index.ts` — re-exportar
5. `api-gateway/src/auth/firebase-auth.service.ts` — agregar `storageBucket`
6. `api-gateway/src/ai/gemini.service.ts` — agregar `generateCover()`
7. `api-gateway/src/ai/storage.service.ts` — crear (incluye gate día 1 inline)
8. `api-gateway/src/ai/storage-cleanup.service.ts` — crear
9. `api-gateway/src/ai/ai.controller.ts` — agregar handler `POST /ai/cover`
10. `api-gateway/src/ai/ai.module.ts` — agregar providers
11. `api-gateway/src/ai/storage.service.spec.ts` — crear tests
12. `api-gateway/src/ai/storage-cleanup.service.spec.ts` — crear tests

---

## Superficie de regresión

- `POST /ai/description` — NO modificar; tests existentes `ai.controller.spec.ts` deben seguir pasando
- `POST /events/generate-cover` — NO tocar; `events.controller.ts` y sus tests quedan intactos
- `firebase-auth.service.ts` — solo agregar propiedad `storageBucket`; comportamiento de `verifyToken()` invariante
- `GeminiService.generateDescription()` — NO modificar; solo agregar `generateCover()`
- `AiModule` — NO eliminar providers existentes; solo agregar
- `ScheduleModule.forRoot()` — ya está en AppModule; no duplicar
- `AiModule` en AppModule.imports — ya está; no duplicar

---

## Fuera de alcance

- Mapeo tipado de errores Gemini (`safety_blocked → 422`, `quota_exceeded → 429`) — Fase 3
- Cuota por usuario — Fase 3
- Retiro del endpoint legacy `POST /events/generate-cover` — Fase 5
- Eliminación de `ClaudeService`, `UnsplashService`, `@anthropic-ai/sdk`
- Cambios en Flutter (`lib/`, `integration_test/`, `test/`)
- Configuración inicial del bucket Firebase Console
