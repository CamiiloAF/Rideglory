# Fase 2 — Backend — Portada IA con Storage

**Plan:** ai-event-generation
**Fecha:** 2026-06-05T21:53:07Z
**Nivel rg-exec:** full
**Depende de:** Fase 1

---

## Objetivo

El backend puede producir una imagen 16:9 vía Gemini imagen, subirla a Firebase Storage en la ruta `pending/{userId}/{draftId}.{ext}` y devolver la URL pública al cliente. Un cron semanal borra archivos `pending/` con más de 7 días para evitar acumulación de huérfanos.

---

## Alcance (entra / no entra)

### Entra
- Agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al `initializeApp()` en `FirebaseAuthService`
- Agregar `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` a `.env.example` y variables de EC2
- Gate día 1: verificar escritura al bucket Y lectura pública vía HTTP GET antes de implementar lógica de generación de imagen
- `GeminiService.generateCover()` usando `config.responseModalities: ['IMAGE']` con el SDK `@google/genai`; model ID desde `process.env.GEMINI_IMAGE_MODEL` (no hardcodear); extracción de `inlineData` base64 → `Buffer`; lectura de `inlineData.mimeType` para determinar formato real
- Nuevo endpoint `POST /ai/cover` en `AiController` (ya creado en Fase 1) → imagen → Storage → URL pública
- `StorageService` como `@Injectable()` dentro de `AiModule` para gestionar escritura al bucket con contentType y extensión determinados por el mimeType de la respuesta Gemini
- `StorageCleanupService` como `@Injectable()` dentro de `AiModule` con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })` que borra archivos `pending/` con más de 7 días; `StorageService` y `StorageCleanupService` se registran en `providers` de `AiModule`
- Publicar `AiCoverRequestDto` y `AiCoverResponseDto` en `rideglory-contracts/src/ai/` con comentario inline de excepción Pattern B
- El endpoint legacy `POST /events/generate-cover` permanece intacto

### No entra
- **Mapeo HTTP de errores Gemini tipados (`safety_blocked` → 422, `network_error` → 503, `quota_exceeded_project` → 429):** se difiere íntegramente a Fase 3. En Fase 2, los errores lanzados por `generateCover()` propagarán como HTTP 500 hasta que Fase 3 implemente el filtro/mapeo de excepciones. El endpoint no promete 422 ni 503 hasta entonces.
- Lógica de cuota de usuario (`quota_exceeded_user` → 429) — Fase 3
- Retiro del endpoint legacy `POST /events/generate-cover` — Fase 5
- Eliminación de `ClaudeService`, `UnsplashService` o `@anthropic-ai/sdk`
- Cambios en el cliente Flutter
- Configuración inicial del bucket en Firebase Console (se asume existente; los permisos se verifican en el gate día 1)

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Agregar `storageBucket` a `FirebaseAuthService` y variables de entorno

1. Editar `api-gateway/src/auth/firebase-auth.service.ts`: en ambas ramas del `initializeApp()` (con `cert(serviceAccount)` y con `projectId`), agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al objeto de configuración.
2. Agregar al `.env.example` de api-gateway:
   ```
   FIREBASE_STORAGE_BUCKET=rideglory-prod.appspot.com
   GEMINI_IMAGE_MODEL=gemini-2.0-flash-preview-image-generation
   ```
3. Documentar ambas variables en el handoff de deploy para que se agreguen al entorno de EC2 antes del deploy de esta fase.

### Paso 2 — Gate día 1: verificar escritura Y lectura pública al bucket

Antes de escribir lógica de generación de imagen, verificar que la aplicación puede escribir al bucket y que el archivo resultante es accesible públicamente por HTTP:

**2a. Verificación de escritura:**
- Arrancar el api-gateway localmente con `FIREBASE_STORAGE_BUCKET` configurado.
- Ejecutar un script o test de integración temporal que llame a `getStorage(app).bucket().file('pending/test/gate.txt').save(Buffer.from('ok'))` y confirme que no lanza error.
- Si el bucket no tiene permisos para la credencial firebase-admin local, resolver antes de continuar (IAM: `roles/storage.objectAdmin` o `roles/storage.objectCreator` sobre el bucket para la service account).

**2b. Verificación de lectura pública:**
- Intentar obtener la URL pública del archivo de prueba con `file.publicUrl()` y hacer una petición HTTP GET a esa URL desde fuera del proceso (curl o navegador).
- Si el bucket tiene **Uniform Bucket-Level Access (UBLA)** activado, el método `file.save({ public: true })` fallará silenciosamente o lanzará un error de ACL — ya que UBLA deshabilita las ACLs a nivel de objeto. Verificarlo así:
  - Si `public: true` lanza error de permisos → el bucket tiene UBLA activado.
  - En ese caso, la alternativa es agregar el binding IAM `allUsers → roles/storage.objectViewer` a nivel de bucket en Firebase Console (Settings → Storage → Permissions). Documentar este hallazgo en el handoff.
  - Si no es posible hacer el bucket completamente público (bucket corporativo), la alternativa es generar signed URLs de larga duración (7 días) en lugar de URL pública directa; ajustar `StorageService.uploadCover()` en consecuencia.
- Eliminar el archivo de prueba del bucket tras confirmar.

**Bloqueante:** no avanzar al Paso 3 hasta que tanto la escritura como la lectura pública (o el plan de signed URL) estén confirmados.

### Paso 3 — Publicar DTOs en rideglory-contracts

En `rideglory-contracts/src/ai/` (directorio creado en Fase 1), agregar:

- `ai-cover-request.dto.ts` — exporta `AiCoverRequestDto`
- `ai-cover-response.dto.ts` — exporta `AiCoverResponseDto`
- Actualizar `rideglory-contracts/src/ai/index.ts` para re-exportar los nuevos DTOs
- Confirmar que `rideglory-contracts/src/index.ts` ya re-exporta `./ai` (hecho en Fase 1; solo verificar)

### Paso 4 — Agregar `generateCover()` a `GeminiService`

En `api-gateway/src/ai/gemini.service.ts` (creado en Fase 1), agregar el método. A continuación se muestra la estructura exacta del request y la ruta de extracción del buffer usando el SDK `@google/genai`:

```typescript
async generateCover(prompt: string): Promise<{ buffer: Buffer; mimeType: string }> {
  const model = process.env.GEMINI_IMAGE_MODEL;
  if (!model) {
    throw new Error('GEMINI_IMAGE_MODEL env var not set');
  }

  // Llamada al SDK @google/genai para generación de imagen nativa.
  // responseModalities: ['IMAGE'] solo es válido con modelos de imagen (preview).
  const response = await this.ai.models.generateContent({
    model,
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    config: {
      responseModalities: ['IMAGE'],
    },
  });

  // Extraer la parte de imagen del primer candidato.
  // La propiedad inlineData contiene data (base64) y mimeType ('image/jpeg' | 'image/png').
  const parts = response.candidates?.[0]?.content?.parts ?? [];
  const imagePart = parts.find((p) => p.inlineData?.data);

  if (!imagePart?.inlineData?.data) {
    // Puede ocurrir si el modelo rechaza el prompt por filtro de seguridad.
    // En Fase 3 este error se mapeará a HTTP 422; en Fase 2 propaga como 500.
    throw new Error('No image data in Gemini response');
  }

  const buffer = Buffer.from(imagePart.inlineData.data, 'base64');
  // mimeType puede ser 'image/jpeg' o 'image/png' según lo que Gemini devuelva.
  const mimeType = imagePart.inlineData.mimeType ?? 'image/jpeg';

  return { buffer, mimeType };
}
```

Notas de implementación:
- `this.ai` es la instancia `GoogleGenAI` inyectada o creada en el constructor de `GeminiService` con `new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY })`.
- El campo `config.responseModalities` requiere el tipo `['IMAGE']` o `['TEXT', 'IMAGE']`; con solo `['TEXT']` no devuelve imagen.
- Si `candidates` está vacío o `content.parts` no contiene ninguna parte con `inlineData`, se lanza el error `'No image data in Gemini response'`. Fase 3 añadirá el mapeo de este error a 422 (`safety_blocked`).
- Si hay error de red (timeout, ECONNREFUSED), la excepción propagará como 503 a partir de Fase 3; en Fase 2 llega como 500.

### Paso 5 — Crear `StorageService`

Crear `api-gateway/src/ai/storage.service.ts` como `@Injectable()` dentro de `AiModule`:

```typescript
@Injectable()
export class StorageService {
  // mimeType viene de inlineData.mimeType en la respuesta Gemini.
  // Ejemplos: 'image/jpeg' → ext 'jpg', 'image/png' → ext 'png'.
  // Usar el mimeType real (no asumir JPEG) para que contentType y extensión sean coherentes.
  async uploadCover(
    userId: string,
    draftId: string,
    imageBuffer: Buffer,
    mimeType: string,
  ): Promise<string> {
    const ext = mimeType === 'image/png' ? 'png' : 'jpg';
    const path = `pending/${userId}/${draftId}.${ext}`;
    const bucket = getStorage(getApps()[0]).bucket();
    const file = bucket.file(path);
    // Nota: { public: true } solo funciona si el bucket NO tiene UBLA activado.
    // Si el bucket tiene UBLA, usar binding IAM allUsers->roles/storage.objectViewer
    // a nivel de bucket (ver gate día 1, Paso 2b) en lugar de ACL de objeto.
    await file.save(imageBuffer, { contentType: mimeType, public: true });
    return file.publicUrl();
  }
}
```

- `getApps()[0]` obtiene la instancia `App` ya inicializada sin necesidad de inyectarla explícitamente.
- La URL pública sigue el patrón `https://storage.googleapis.com/{bucket}/{path}`.
- Si el gate día 1 determinó que se usarán signed URLs, reemplazar `public: true` y `file.publicUrl()` con la generación de signed URL de larga duración.

### Paso 6 — Agregar endpoint `POST /ai/cover` a `AiController`

En `api-gateway/src/ai/ai.controller.ts` (creado en Fase 1), inyectar `StorageService` por constructor junto al `GeminiService` existente y agregar el handler:

```typescript
constructor(
  private readonly geminiService: GeminiService,
  private readonly storageService: StorageService,
) {}

@Post('cover')
@UseGuards(FirebaseAuthGuard)
async generateCover(
  @Body() dto: AiCoverRequestDto,
  @Request() req: AuthenticatedRequest,
): Promise<AiCoverResponseDto> {
  const userId = req.user.uid;
  const { buffer, mimeType } = await this.geminiService.generateCover(dto.prompt);
  const imageUrl = await this.storageService.uploadCover(userId, dto.draftId, buffer, mimeType);
  // remainingGenerations: -1 es valor sentinel; cuotas no implementadas hasta Fase 3.
  // El cliente Flutter ignora el valor -1 en esta fase.
  return { imageUrl, draftId: dto.draftId, remainingGenerations: -1 };
}
```

- `FirebaseAuthGuard` ya existe en api-gateway (usado en endpoints de events, vehicles, etc.).
- Los errores lanzados por `generateCover()` o `uploadCover()` propagan como HTTP 500 en esta fase. El mapeo a 422/503 es responsabilidad de Fase 3.

### Paso 7 — Crear `StorageCleanupService`

Crear `api-gateway/src/ai/storage-cleanup.service.ts`:

```typescript
@Injectable()
export class StorageCleanupService {
  private readonly logger = new Logger(StorageCleanupService.name);

  // Cron: domingos a las 03:00 hora Colombia (UTC-5). Raw cron string con timezone
  // explícito, convención del repo (ver otros crons en api-gateway).
  @Cron('0 3 * * 0', { timeZone: 'America/Bogota' })
  async cleanPendingCovers(): Promise<void> {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const bucket = getStorage(getApps()[0]).bucket();
    const [files] = await bucket.getFiles({ prefix: 'pending/' });
    for (const file of files) {
      const [metadata] = await file.getMetadata();
      // metadata.timeCreated llega como string ISO desde firebase-admin getMetadata().
      // La comparación new Date(metadata.timeCreated) < sevenDaysAgo es la condición testeable.
      const created = new Date(metadata.timeCreated as string);
      if (created < sevenDaysAgo) {
        await file.delete();
        this.logger.log(`Deleted orphan cover: ${file.name}`);
      }
    }
  }
}
```

- Usar raw cron string `'0 3 * * 0'` con `{ timeZone: 'America/Bogota' }`, no `CronExpression.EVERY_WEEK` — esto sigue la convención del repo de fijar timezone explícito en todos los crons.
- `@nestjs/schedule` ya está en `api-gateway/package.json`; no requiere instalación adicional.

### Paso 8 — Registrar `StorageService` y `StorageCleanupService` en `AiModule`

En `api-gateway/src/ai/ai.module.ts`, agregar explícitamente ambos servicios al array `providers` del módulo:

```typescript
@Module({
  controllers: [AiController],
  providers: [
    GeminiService,
    StorageService,          // inyectado en AiController
    StorageCleanupService,   // registrado para que @Cron sea detectado por el scheduler
  ],
})
export class AiModule {}
```

**Precondición para que `@Cron` funcione:** el decorador `@Cron` en `StorageCleanupService` es detectado por el scheduler de NestJS únicamente si se cumplen **dos** condiciones simultáneas:

1. `ScheduleModule.forRoot()` está importado en `AppModule` (en `app.module.ts`) — establece el scheduler global. Esto debe haber sido establecido en Fase 1 o verificado antes de Fase 2. Seguir el patrón de `notification-scheduler.service.ts` en el repo: ese servicio vive en su propio módulo que es importado en `AppModule`; el scheduler funciona porque `ScheduleModule.forRoot()` ya estaba en `AppModule`.
2. `AiModule` está en el array `imports` de `AppModule` — para que NestJS instancie los providers de `AiModule`, incluido `StorageCleanupService`. Esto se hace en Fase 1; el implementador debe verificarlo explícitamente.

Si alguna de las dos condiciones falta, el cron no se registrará en los logs de arranque y no ejecutará aunque el código sea correcto. Verificar en los logs de arranque que aparezca la línea de registro del cron de `StorageCleanupService`.

### Paso 9 — Verificación end-to-end local

Antes de marcar la fase completa:
1. Levantar api-gateway localmente con todas las env vars configuradas.
2. Llamar `POST /ai/cover` con `{ "prompt": "Grupo de motos en carretera montañosa al amanecer", "draftId": "test-draft-001" }` y token Firebase válido.
3. Confirmar respuesta 200 con `imageUrl` apuntando al bucket.
4. Hacer HTTP GET a `imageUrl` desde fuera del proceso (curl o navegador) y confirmar que devuelve la imagen sin error 403/401.
5. Verificar que el archivo `pending/{userId}/test-draft-001.jpg` (o `.png` si Gemini devolvió PNG) existe en Firebase Storage Console.
6. Confirmar que el endpoint legacy `POST /events/generate-cover` sigue respondiendo (no fue tocado).

---

## Archivos a crear/modificar (rutas reales)

**rideglory-api/api-gateway**

| Archivo | Acción | Qué cambia |
|---------|--------|-----------|
| `api-gateway/src/auth/firebase-auth.service.ts` | Modificar | Agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` en ambas ramas del `initializeApp()` |
| `api-gateway/.env.example` | Modificar | Agregar `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` |
| `api-gateway/src/ai/gemini.service.ts` | Modificar | Agregar método `generateCover(prompt): Promise<{ buffer, mimeType }>` con `config.responseModalities: ['IMAGE']`, extracción de `inlineData.data` (base64 → Buffer) y `inlineData.mimeType`; error explícito si env var undefined |
| `api-gateway/src/ai/storage.service.ts` | Crear | Nuevo `@Injectable()` con `uploadCover(userId, draftId, buffer, mimeType)` → URL pública; extensión determinada por mimeType; nota inline sobre UBLA |
| `api-gateway/src/ai/storage-cleanup.service.ts` | Crear | Nuevo `@Injectable()` con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })` que borra `pending/` cuyo `metadata.timeCreated` supera 7 días |
| `api-gateway/src/ai/ai.controller.ts` | Modificar | Inyectar `StorageService` por constructor; agregar handler `@Post('cover')` con guard Firebase, destructuring `{ buffer, mimeType }` de `generateCover()`, y `uploadCover(userId, draftId, buffer, mimeType)` |
| `api-gateway/src/ai/ai.module.ts` | Modificar | Agregar `StorageService` y `StorageCleanupService` al array `providers` |

**rideglory-api/rideglory-contracts**

| Archivo | Acción | Qué cambia |
|---------|--------|-----------|
| `rideglory-contracts/src/ai/ai-cover-request.dto.ts` | Crear | `AiCoverRequestDto` con campos `prompt: string`, `draftId: string` y comentario excepción Pattern B |
| `rideglory-contracts/src/ai/ai-cover-response.dto.ts` | Crear | `AiCoverResponseDto` con campos `imageUrl: string`, `draftId: string`, `remainingGenerations: number` y comentario excepción Pattern B |
| `rideglory-contracts/src/ai/index.ts` | Modificar | Re-exportar los dos DTOs nuevos |

---

## Contratos / API rideglory-api

### POST /ai/cover

```
Auth:    Bearer (Firebase ID token — obligatorio)
Request Body:
  {
    "prompt":  string,    // descripción libre de la portada deseada
    "draftId": string     // UUID generado en cliente (Fase 5); usado como nombre del archivo en Storage
  }

Response 200:
  {
    "imageUrl":             string,  // URL pública Firebase Storage
                                     // Patrón: https://storage.googleapis.com/{bucket}/pending/{userId}/{draftId}.{ext}
                                     // donde {ext} = 'jpg' o 'png' según el mimeType devuelto por Gemini
    "draftId":              string,  // eco del draftId enviado
    "remainingGenerations": -1       // sentinel: cuotas no implementadas hasta Fase 3; el cliente Flutter ignora -1
  }

Response 401:
  Unauthorized (token inválido o ausente)

Response 5xx:
  Errores de generación (Gemini) o Storage se propagan como 500 en Fase 2.
  El mapeo explícito a 422 (safety_blocked) y 503 (network_error) se implementa en Fase 3.
```

**Nota:** Los códigos 422 y 503 documentados en el contrato del Architect Review NO son parte del alcance de esta fase. El mapeo de errores tipados de Gemini a HttpException con status 422/503 se implementa en Fase 3 junto con el sistema de cuotas. El contrato final del endpoint incluirá esos códigos a partir del deploy de Fase 3.

### DTOs en rideglory-contracts/src/ai/

```typescript
// ai-cover-request.dto.ts
// Excepción Pattern B: DTO de request sin modelo domain 1:1. No extiende modelo domain.
export class AiCoverRequestDto {
  prompt: string;
  draftId: string;
}

// ai-cover-response.dto.ts
// Excepción Pattern B: DTO compuesto con campos de control (remainingGenerations, draftId)
// que no pertenecen a un modelo domain. No extiende modelo domain.
export class AiCoverResponseDto {
  imageUrl: string;
  draftId: string;
  remainingGenerations: number; // -1 = cuotas no activas (Fase 2); valor real desde Fase 3
}
```

---

## Cambios de datos / migraciones

Ninguno. No hay migración Prisma. No hay cambios en esquema Firestore en esta fase (la colección de cuotas se crea en Fase 3). Firebase Storage no requiere setup de esquema; el bucket ya existe.

---

## Criterios de aceptacion

1. `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` están en `.env.example`; el api-gateway arranca sin error cuando ambas están configuradas.
2. El gate día 1 pasa (escritura): el proceso puede escribir un archivo de prueba en el bucket configurado sin error de permisos.
3. `POST /ai/cover` con un prompt válido, `draftId` UUID y token Firebase válido devuelve HTTP 200 con `imageUrl` apuntando a `pending/{userId}/{draftId}.{ext}` en el bucket correcto, donde `{ext}` coincide con el mimeType devuelto por Gemini (`jpg` para `image/jpeg`, `png` para `image/png`). El `contentType` del archivo en Storage coincide con ese mimeType.
4. El archivo `pending/{userId}/{draftId}.{ext}` es accesible públicamente mediante HTTP GET a la `imageUrl` devuelta (verificado con curl o navegador, sin error 401/403). Si el bucket tiene UBLA activado, el acceso público se logra vía el binding IAM `allUsers → roles/storage.objectViewer` a nivel de bucket (no ACL de objeto), o alternativamente mediante signed URL de larga duración — ambas alternativas son aceptables; la elegida debe documentarse en el handoff.
5. Si `GEMINI_IMAGE_MODEL` no está definida en el entorno, el método `generateCover()` lanza `Error('GEMINI_IMAGE_MODEL env var not set')` al inicio, antes de llamar al SDK.
6. El endpoint legacy `POST /events/generate-cover` sigue respondiendo con su comportamiento original (no fue afectado).
7. El cron `StorageCleanupService.cleanPendingCovers()` puede invocarse manualmente y borra solo los archivos en `pending/` cuyo `new Date(metadata.timeCreated) < sevenDaysAgo`; no borra archivos recientes; no borra un archivo cuyo `timeCreated` cae exactamente en el límite de 7 días (`>= sevenDaysAgo`).
8. `StorageCleanupService` está registrado en `providers` de `AiModule` (no en un módulo propio) con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })`; el scheduler de NestJS detecta y registra el cron — verificable en los logs de arranque del servidor. Para que esto ocurra, se confirma en los logs que: (a) `ScheduleModule.forRoot()` está en `app.module.ts` y (b) `AiModule` está en `imports` de `AppModule` (ambas precondiciones establecidas en Fase 1).
9. `AiCoverRequestDto` y `AiCoverResponseDto` están publicados en `rideglory-contracts/src/ai/` y son importables desde api-gateway sin error de compilación TypeScript.

---

## Pruebas

### Unitarias (api-gateway)

| Archivo | Qué testear |
|---------|------------|
| `api-gateway/src/ai/storage.service.spec.ts` | `uploadCover()`: mockear `getStorage().bucket().file().save()` y `file.publicUrl()`; verificar path `pending/{userId}/{draftId}.jpg` para mimeType `image/jpeg` y `pending/{userId}/{draftId}.png` para `image/png`; verificar que `contentType` en la llamada a `save()` coincide con el mimeType recibido; verificar que la URL devuelta es el resultado de `publicUrl()` |
| `api-gateway/src/ai/storage-cleanup.service.spec.ts` | `cleanPendingCovers()`: mockear `bucket.getFiles({ prefix: 'pending/' })` con lista de archivos con `metadata.timeCreated` como string ISO variado; verificar que solo se eliminan los archivos cuyo `new Date(metadata.timeCreated) < sevenDaysAgo`; verificar que `file.delete()` no se llama para archivos recientes; incluir caso borde: archivo con `timeCreated` exactamente igual a `sevenDaysAgo` (límite exacto de 7 días) NO debe borrarse |
| `api-gateway/src/ai/gemini.service.spec.ts` (ampliar desde Fase 1) | `generateCover()`: mockear `ai.models.generateContent()`; verificar que `config.responseModalities: ['IMAGE']` está en el request; verificar que el model ID proviene de `process.env.GEMINI_IMAGE_MODEL`; verificar que lanza `Error('GEMINI_IMAGE_MODEL env var not set')` cuando la env var no está definida; verificar que el Buffer devuelto es el resultado de `Buffer.from(inlineData.data, 'base64')` y que `mimeType` es el de `inlineData.mimeType` |

### Integración / e2e

| Prueba | Descripción |
|--------|------------|
| Gate día 1 (manual o script) | Escritura de archivo de prueba al bucket real con las credenciales de firebase-admin configuradas en `.env`; confirmar lectura pública vía HTTP GET; confirmar en Firebase Storage Console |
| `POST /ai/cover` e2e (manual) | Llamada con prompt y `draftId` reales; verificar `imageUrl` accesible por HTTP GET externo (fuera del proceso); verificar extensión y contentType del archivo en Storage Console |

### No aplica en esta fase

- Tests de cuota y mapeo de errores HTTP tipados (Fase 3)
- Widget tests Flutter (Fase 5)

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigación |
|----|--------|------|---------|-----------|
| R1 | Modelo Gemini imagen en preview cambia de nombre antes de implementar | Alta | Alto | `GEMINI_IMAGE_MODEL` como env var; validar el nombre correcto al inicio de la fase (no asumir `gemini-2.0-flash-preview-image-generation` sin verificar); si cambió, actualizar solo la env var |
| R2 | `storageBucket` no configurado → `getStorage(app).bucket()` falla con error poco descriptivo "No bucket name specified" | Media | Alto | Gate día 1 bloqueante (Paso 2); no avanzar hasta confirmar escritura al bucket |
| R3 | Permisos IAM insuficientes de la service account para Firebase Storage | Media | Alto | Verificar en gate día 1; la service account necesita `roles/storage.objectAdmin` o `roles/storage.objectCreator`; resolver en Firebase Console antes de continuar |
| R4 | **UBLA (Uniform Bucket-Level Access) activado en el bucket bloquea ACLs de objeto** — `file.save({ public: true })` lanza error o no tiene efecto, impidiendo acceso público por URL | Media | Alto | Detectar en gate día 1 (Paso 2b); si UBLA activo, usar binding IAM `allUsers → roles/storage.objectViewer` a nivel de bucket, o generar signed URLs de larga duración en `StorageService.uploadCover()`; nunca intentar ACL de objeto si UBLA está habilitado |
| R5 | Gemini devuelve PNG en lugar de JPEG — contentType y extensión incorrectos si se asume `.jpg` fijo | Media | Bajo | `StorageService.uploadCover()` recibe `mimeType` de la respuesta Gemini (`inlineData.mimeType`) y lo usa para determinar `contentType` y extensión; no se asume JPEG. El test unitario cubre ambos casos. |
| R6 | Latencia alta de generación de imagen Gemini (~10-15 s) → timeout en Dio/Retrofit del cliente Flutter | Baja | Medio | El timeout de Dio en api-gateway está en 20 s (AppDio); si es insuficiente, considerar aumentarlo solo para `/ai/cover`; documentar en handoff de Fase 5 para que Flutter configure el timeout del cliente |
| R7 | `firebase-admin` singleton ya inicializado en un test runner sin `storageBucket` → `getStorage()` falla en tests | Baja | Bajo | Mockear `getStorage` en tests unitarios de `StorageService`; no llamar a `initializeApp` real en tests |
| R8 | `@Cron` no se registra porque `ScheduleModule.forRoot()` falta en `AppModule` o `AiModule` no está en `imports` de `AppModule` | Baja | Alto | Verificar explícitamente ambas condiciones antes de marcar el AC #8 como cumplido; comprobar en logs de arranque que el scheduler registra el cron de `StorageCleanupService` |
| R9 | Off-by-one en predicado de tiempo del cron borra imágenes recientes o preserva huérfanos excesivamente | Baja | Medio | Especificar condición exacta: `new Date(metadata.timeCreated) < sevenDaysAgo` (estrictamente menor); el spec cubre el caso límite exacto de 7 días |
| R10 | `@Cron` borra imagen activa si el borrador tiene más de 7 días pero aún no fue confirmado | Baja | Bajo | El cron opera sobre `pending/`; las imágenes confirmadas se mueven a ruta permanente (Fase 5 al llamar `setCoverUrl`). Una imagen en `pending/` con más de 7 días se considera huérfana. Sin riesgo si el flujo de confirmación está implementado |

---

## Dependencias

**Fase 1 — Backend: Base de texto IA (prerequisito directo)**

Razones:
- `AiModule` con `AiController` y `GeminiService` deben existir antes de agregar el método `generateCover()` y el handler `POST /ai/cover`
- `@google/genai` debe estar instalado en `api-gateway/package.json` (instalado en Fase 1)
- El directorio `rideglory-contracts/src/ai/` y su `index.ts` deben existir (creados en Fase 1); esta fase solo agrega archivos nuevos al directorio
- `FirebaseAuthGuard` y `AuthenticatedRequest` ya deben estar configurados en `AiModule` (establecido en Fase 1)
- `AiModule` debe estar en `imports` de `AppModule` y `ScheduleModule.forRoot()` en `app.module.ts` (ambos establecidos en Fase 1) para que el cron de `StorageCleanupService` funcione

---

## Ejecucion recomendada (nivel rg-exec: full)

**Nivel: full**

Justificación detallada:

1. **Modelo Gemini imagen en preview (inestable):** `gemini-2.0-flash-preview-image-generation` es un modelo preview sujeto a cambio de nombre sin aviso. El parámetro `config.responseModalities: ['IMAGE']` solo funciona con modelos específicos; `gemini-2.5-flash` no lo soporta. Un auditor Opus debe verificar que el model ID sea válido al inicio de la fase y que el código no asuma un nombre hardcodeado en ningún punto.

2. **Precondición crítica de `storageBucket` en firebase-admin:** La instancia `App` de firebase-admin se inicializa una sola vez al arrancar el proceso. Si `storageBucket` no está en el `initializeApp()`, `getStorage(app).bucket()` lanza "No bucket name specified" — error poco descriptivo que puede parecer un problema de permisos o de red. Esta falla silenciosa en staging/EC2 puede bloquear el deploy sin mensaje claro. El auditor debe verificar que el gate día 1 (Paso 2) se ejecutó y pasó antes de aprobar el avance.

3. **Escritura a Firebase Storage en producción y acceso público:** Es la primera vez que api-gateway escribe a Storage (las escrituras actuales van desde el cliente Flutter directamente). Requiere verificar permisos IAM, el nombre correcto del bucket, que la URL pública sea accesible por HTTP GET externo, y la compatibilidad con UBLA. Errores en este punto no son detectables con tests unitarios; requieren verificación en entorno real.

4. **Nuevas env vars en EC2:** `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` deben estar presentes en el proceso de EC2 antes del deploy; si falta alguna, el api-gateway puede arrancar pero fallar en el primer request a `/ai/cover`. El auditor debe confirmar que ambas están documentadas en el handoff de deploy.

5. **Cron de limpieza de Storage sobre datos reales:** `StorageCleanupService` opera sobre el bucket de producción borrando archivos. Un bug en el predicado de tiempo (comparación de `metadata.timeCreated` como string ISO vs `Date`) podría borrar imágenes recientes. El auditor debe revisar con especial atención la conversión `new Date(metadata.timeCreated)` y el caso límite exacto de 7 días.

El nivel `full` activa el ciclo implementador (Sonnet) → auditor (Opus) iterativo, apropiado para una fase con múltiples puntos de falla silenciosa, precondiciones de infraestructura, operaciones destructivas sobre Storage y un riesgo no trivial de bloqueo por configuración de bucket.
