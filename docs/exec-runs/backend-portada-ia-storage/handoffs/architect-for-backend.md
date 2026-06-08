> Slim handoff — lee esto antes de docs/exec-runs/backend-portada-ia-storage/handoffs/architect.md

# Architect → Backend — backend-portada-ia-storage

**Repo:** `/Users/cami/Developer/Personal/rideglory-api`

---

## Precondición verificada

- `ScheduleModule.forRoot()` ya en `AppModule` ✓
- `AiModule` ya en `AppModule.imports` ✓
- `firebase-admin` v13 ya instalado ✓
- `@nestjs/schedule` ya instalado ✓
- `@google/genai` ya instalado ✓
- `FirebaseAuthGuard` es global (APP_GUARD en AuthModule) — no agregar `@UseGuards()` al controller ✓

---

## Orden de implementación

1. `api-gateway/.env.example` — agregar 2 vars
2. Contratos DTOs (ver sección abajo)
3. `api-gateway/src/auth/firebase-auth.service.ts` — agregar `storageBucket`
4. `api-gateway/src/ai/gemini.service.ts` — agregar `generateCover()`
5. `api-gateway/src/ai/storage.service.ts` — crear (gate día 1 primero)
6. `api-gateway/src/ai/storage-cleanup.service.ts` — crear
7. `api-gateway/src/ai/ai.controller.ts` — nuevo handler
8. `api-gateway/src/ai/ai.module.ts` — nuevos providers
9. Tests: `storage.service.spec.ts`, `storage-cleanup.service.spec.ts`

---

## Cambios por archivo

### `api-gateway/.env.example`
```
# Firebase Storage
FIREBASE_STORAGE_BUCKET=your-project.appspot.com

# Gemini image model (required for POST /ai/cover)
GEMINI_IMAGE_MODEL=gemini-2.0-flash-preview-image-generation
```

### `api-gateway/src/auth/firebase-auth.service.ts`
En ambas ramas del `if` dentro de `initializeFirebaseApp()`, agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al objeto que se pasa a `initializeApp()`.

### `rideglory-contracts/src/ai/dto/ai-cover-request.dto.ts` (crear)
```typescript
// Composite DTO: request-only; no 1:1 domain model (Pattern B exception — rideglory-coding-standards §DTOs)
import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class AiCoverRequestDto {
  @IsString()
  @IsNotEmpty()
  prompt!: string;

  @IsUUID()
  draftId!: string;
}
```

### `rideglory-contracts/src/ai/dto/ai-cover-response.dto.ts` (crear)
```typescript
// Composite DTO: control field + domain data; no 1:1 domain model (Pattern B exception — rideglory-coding-standards §DTOs)
export class AiCoverResponseDto {
  imageUrl!: string;
  remainingGenerations!: number; // -1 sentinel; cuota real en Fase 3
}
```

### `rideglory-contracts/src/ai/dto/index.ts`
Agregar al final:
```typescript
export * from './ai-cover-request.dto';
export * from './ai-cover-response.dto';
```

### `api-gateway/src/ai/gemini.service.ts`
Agregar propiedad e inyección del imageModel al constructor, y nuevo método:
```typescript
// En constructor, después de this.model:
this.imageModel = process.env.GEMINI_IMAGE_MODEL ?? '';

async generateCover(prompt: string): Promise<{ buffer: Buffer; mimeType: string }> {
  if (!this.imageModel) {
    throw new Error('GEMINI_IMAGE_MODEL env var not set');
  }
  const response = await this.ai.models.generateContent({
    model: this.imageModel,
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    config: { responseModalities: ['IMAGE'] },
  });
  const part = response.candidates?.[0]?.content?.parts?.[0];
  if (!part?.inlineData?.data || !part.inlineData.mimeType) {
    throw new Error('Gemini did not return image data');
  }
  return {
    buffer: Buffer.from(part.inlineData.data, 'base64'),
    mimeType: part.inlineData.mimeType,
  };
}
```

### `api-gateway/src/ai/storage.service.ts` (crear)
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { getApps } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';

const MIME_TO_EXT: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);

  async uploadCover(
    userId: string,
    draftId: string,
    buffer: Buffer,
    mimeType: string,
  ): Promise<string> {
    const ext = MIME_TO_EXT[mimeType] ?? 'png';
    const filePath = `pending/${userId}/${draftId}.${ext}`;
    const bucket = getStorage(getApps()[0]).bucket();
    const file = bucket.file(filePath);

    await file.save(buffer, { contentType: mimeType });

    // GATE DÍA 1: verificar si makePublic() funciona (sin UBLA).
    // Si el bucket tiene UBLA activo, usar getSignedUrl() en su lugar y documentar aquí.
    await file.makePublic();
    const imageUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

    this.logger.log(`Cover uploaded: ${imageUrl}`);
    return imageUrl;
  }
}
```

**UBLA awareness:** Si `makePublic()` lanza en el gate día 1, cambiar a:
```typescript
const [url] = await file.getSignedUrl({ action: 'read', expires: Date.now() + 7 * 24 * 60 * 60 * 1000 });
return url;
```
Documentar la opción elegida en comentario inline.

### `api-gateway/src/ai/storage-cleanup.service.ts` (crear)
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { getApps } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';

@Injectable()
export class StorageCleanupService {
  private readonly logger = new Logger(StorageCleanupService.name);

  @Cron('0 3 * * 0', { timeZone: 'America/Bogota' })
  async cleanPendingCovers(): Promise<void> {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const bucket = getStorage(getApps()[0]).bucket();
    const [files] = await bucket.getFiles({ prefix: 'pending/' });

    let deleted = 0;
    for (const file of files) {
      const [metadata] = await file.getMetadata();
      if (new Date(metadata.timeCreated as string) < sevenDaysAgo) {
        await file.delete();
        deleted++;
      }
    }
    this.logger.log(`StorageCleanup: deleted ${deleted} stale pending covers`);
  }
}
```

### `api-gateway/src/ai/ai.controller.ts`
Agregar imports: `AiCoverRequestDto`, `AiCoverResponseDto` de `@rideglory/contracts`; `StorageService`; `Req`, `Request` de NestJS/express.

Agregar al constructor: `private readonly storageService: StorageService`.

Agregar handler:
```typescript
@Post('cover')
async generateCover(
  @Body() dto: AiCoverRequestDto,
  @Req() request: AuthenticatedRequest,
): Promise<AiCoverResponseDto> {
  const userId = request.user!.uid;
  const { buffer, mimeType } = await this.geminiService.generateCover(dto.prompt);
  const imageUrl = await this.storageService.uploadCover(userId, dto.draftId, buffer, mimeType);
  return { imageUrl, remainingGenerations: -1 };
}
```

`AuthenticatedRequest` ya está definido en el mismo archivo (el tipo local del controlador).

### `api-gateway/src/ai/ai.module.ts`
```typescript
import { StorageService } from './storage.service';
import { StorageCleanupService } from './storage-cleanup.service';

@Module({
  controllers: [AiController],
  providers: [GeminiService, StorageService, StorageCleanupService],
})
export class AiModule {}
```

---

## Criterios de aceptación a verificar

1. `.env.example` tiene `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL`
2. Gate día 1: el proceso escribe y lee públicamente del bucket
3. `POST /api/ai/cover` con token válido + prompt + draftId UUID → 200 `{ imageUrl, remainingGenerations: -1 }`
4. `imageUrl` apunta a `pending/{uid}/{draftId}.{ext}` y es accesible públicamente
5. `generateCover()` lanza `Error('GEMINI_IMAGE_MODEL env var not set')` si env var falta
6. `POST /api/events/generate-cover` sigue funcionando
7. Cron limpia solo archivos con `timeCreated < sevenDaysAgo`; respeta el límite exacto
8. `npm test -- --testPathPattern=storage` pasa; `ai.controller.spec.ts` existente no roto

> Full detail: docs/exec-runs/backend-portada-ia-storage/handoffs/architect.md
