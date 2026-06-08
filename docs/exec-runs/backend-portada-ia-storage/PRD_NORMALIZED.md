# PRD Normalizado — Backend: Portada IA con Storage

**Slug:** backend-portada-ia-storage
**Fuente:** docs/plans/ai-event-generation/phases/phase-02-backend-portada-ia-con-storage.md
**Normalizado:** 2026-06-05T23:13:02Z
**Nivel rg-exec:** normal

---

## 1 Objetivo

Habilitar al backend (`rideglory-api/api-gateway`) para generar una imagen 16:9 vía Gemini imagen, subirla a Firebase Storage bajo la ruta `pending/{userId}/{draftId}.{ext}`, y devolver la URL pública al cliente mediante el endpoint `POST /ai/cover`. Un cron semanal borra archivos `pending/` con más de 7 días para evitar acumulación de huérfanos.

---

## 2 Por qué

Es el segundo paso del plan `ai-event-generation`: la Fase 1 estableció la base de texto IA (`AiModule`, `GeminiService`, `AiController`, `@google/genai`); esta fase agrega la capacidad de imagen y la persistencia en Storage. Sin esta fase, el cliente Flutter no puede obtener una portada generada por IA; con ella queda lista la mitad del flujo de generación (Fase 3 añade mapeo de errores tipados y cuotas).

---

## 3 Alcance

### Entra
- Agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al `initializeApp()` en `FirebaseAuthService` (ambas ramas).
- Agregar `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` a `.env.example` de api-gateway y documentarlas para EC2.
- **Gate día 1 bloqueante:** verificar escritura al bucket Y lectura pública vía HTTP GET antes de avanzar a lógica de generación.
- `GeminiService.generateCover(prompt)` usando `config.responseModalities: ['IMAGE']` con el SDK `@google/genai`; model ID desde `process.env.GEMINI_IMAGE_MODEL` (nunca hardcodeado); extracción de `inlineData.data` base64 → `Buffer`; lectura de `inlineData.mimeType` para determinar formato real.
- Nuevo endpoint `POST /ai/cover` en `AiController` con `FirebaseAuthGuard`.
- `StorageService` como `@Injectable()` dentro de `AiModule`: `uploadCover(userId, draftId, buffer, mimeType)` → URL pública; extensión y `contentType` determinados por `mimeType` de la respuesta Gemini.
- `StorageCleanupService` como `@Injectable()` dentro de `AiModule` con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })` que borra archivos `pending/` con `new Date(metadata.timeCreated) < sevenDaysAgo`.
- Publicar `AiCoverRequestDto` y `AiCoverResponseDto` en `rideglory-contracts/src/ai/` con comentario de excepción Pattern B.
- Tests unitarios: `storage.service.spec.ts`, `storage-cleanup.service.spec.ts`, ampliación de `gemini.service.spec.ts`.
- Verificación end-to-end local (Paso 9 del plan).

### No entra
- Mapeo HTTP de errores Gemini tipados (`safety_blocked` → 422, `network_error` → 503, `quota_exceeded_project` → 429) — Fase 3.
- Lógica de cuota de usuario — Fase 3.
- Retiro del endpoint legacy `POST /events/generate-cover` — Fase 5.
- Eliminación de `ClaudeService`, `UnsplashService` o `@anthropic-ai/sdk`.
- Cambios en el cliente Flutter.
- Configuración inicial del bucket en Firebase Console (se asume existente).

---

## 4 Áreas afectadas

| Repositorio | Ruta | Tipo de cambio |
|-------------|------|----------------|
| `rideglory-api` | `api-gateway/src/auth/firebase-auth.service.ts` | Modificación: agregar `storageBucket` |
| `rideglory-api` | `api-gateway/.env.example` | Modificación: nuevas vars |
| `rideglory-api` | `api-gateway/src/ai/gemini.service.ts` | Modificación: agregar `generateCover()` |
| `rideglory-api` | `api-gateway/src/ai/storage.service.ts` | Creación |
| `rideglory-api` | `api-gateway/src/ai/storage-cleanup.service.ts` | Creación |
| `rideglory-api` | `api-gateway/src/ai/ai.controller.ts` | Modificación: inyectar `StorageService`, handler `POST /ai/cover` |
| `rideglory-api` | `api-gateway/src/ai/ai.module.ts` | Modificación: agregar providers |
| `rideglory-api` | `api-gateway/src/ai/storage.service.spec.ts` | Creación (tests) |
| `rideglory-api` | `api-gateway/src/ai/storage-cleanup.service.spec.ts` | Creación (tests) |
| `rideglory-contracts` | `rideglory-contracts/src/ai/ai-cover-request.dto.ts` | Creación |
| `rideglory-contracts` | `rideglory-contracts/src/ai/ai-cover-response.dto.ts` | Creación |
| `rideglory-contracts` | `rideglory-contracts/src/ai/index.ts` | Modificación: re-exportar DTOs |
| Flutter (`Rideglory`) | — | Sin cambios en esta fase |

---

## 5 Criterios de aceptación

1. `FIREBASE_STORAGE_BUCKET` y `GEMINI_IMAGE_MODEL` están en `.env.example`; el api-gateway arranca sin error cuando ambas están configuradas.
2. El gate día 1 pasa (escritura): el proceso puede escribir un archivo de prueba en el bucket configurado sin error de permisos.
3. `POST /ai/cover` con un prompt válido, `draftId` UUID y token Firebase válido devuelve HTTP 200 con `imageUrl` apuntando a `pending/{userId}/{draftId}.{ext}` en el bucket correcto, donde `{ext}` coincide con el mimeType devuelto por Gemini (`jpg` para `image/jpeg`, `png` para `image/png`). El `contentType` del archivo en Storage coincide con ese mimeType.
4. El archivo `pending/{userId}/{draftId}.{ext}` es accesible públicamente mediante HTTP GET a la `imageUrl` devuelta (verificado con curl o navegador, sin error 401/403). Si el bucket tiene UBLA activado, el acceso público se logra vía el binding IAM `allUsers → roles/storage.objectViewer` a nivel de bucket, o alternativamente mediante signed URL de larga duración — ambas son aceptables; la elegida debe documentarse en el handoff.
5. Si `GEMINI_IMAGE_MODEL` no está definida en el entorno, el método `generateCover()` lanza `Error('GEMINI_IMAGE_MODEL env var not set')` al inicio, antes de llamar al SDK.
6. El endpoint legacy `POST /events/generate-cover` sigue respondiendo con su comportamiento original (no fue afectado).
7. El cron `StorageCleanupService.cleanPendingCovers()` puede invocarse manualmente y borra solo los archivos en `pending/` cuyo `new Date(metadata.timeCreated) < sevenDaysAgo`; no borra archivos recientes; no borra un archivo cuyo `timeCreated` cae exactamente en el límite de 7 días (`>= sevenDaysAgo`).
8. `StorageCleanupService` está registrado en `providers` de `AiModule` con `@Cron('0 3 * * 0', { timeZone: 'America/Bogota' })`; el scheduler de NestJS detecta y registra el cron — verificable en los logs de arranque del servidor. Para que esto ocurra, se confirma que: (a) `ScheduleModule.forRoot()` está en `app.module.ts` y (b) `AiModule` está en `imports` de `AppModule` (ambas precondiciones establecidas en Fase 1).
9. `AiCoverRequestDto` y `AiCoverResponseDto` están publicados en `rideglory-contracts/src/ai/` y son importables desde api-gateway sin error de compilación TypeScript.

---

## 6 Guardrails de regresión

- El endpoint legacy `POST /events/generate-cover` debe permanecer intacto y funcional tras todos los cambios de esta fase.
- `firebase-auth.service.ts`: solo se agrega la propiedad `storageBucket` al objeto de configuración existente; ningún otro comportamiento de autenticación debe cambiar.
- `GeminiService`: los métodos existentes (de Fase 1) no deben ser modificados ni eliminados; solo se agrega `generateCover()`.
- `AiController`: el handler existente de Fase 1 (`POST /ai/generate` o equivalente) no debe ser removido; solo se agrega el handler de `POST /ai/cover`.
- `AiModule`: no se eliminan providers ni imports ya existentes; solo se agregan `StorageService` y `StorageCleanupService`.
- Los tests unitarios de Fase 1 (`gemini.service.spec.ts` existente) deben seguir pasando tras la ampliación.
- No se modifican archivos Flutter (`lib/`, `integration_test/`, `test/`).
- No se modifican `workflow/state.json`, `docs/PRD.md`, `docs/PLAN.md` ni archivos de handoffs del sistema `/iter`.

---

## 7 Constraints heredados

- **Model ID como env var obligatorio:** nunca hardcodear `gemini-2.0-flash-preview-image-generation` ni ningún otro nombre de modelo; siempre leer de `process.env.GEMINI_IMAGE_MODEL`.
- **UBLA awareness:** no asumir que `file.save({ public: true })` funcionará; el gate día 1 debe detectar si UBLA está activo y elegir la estrategia de acceso público apropiada.
- **firebase-admin singleton:** `getApps()[0]` para obtener la App ya inicializada; no llamar `initializeApp` nuevamente en ningún servicio nuevo.
- **Cron con timezone explícito:** usar raw cron string + `{ timeZone: 'America/Bogota' }`, no `CronExpression.*` — convención del repo.
- **Pattern B exception en DTOs de contratos:** `AiCoverRequestDto` y `AiCoverResponseDto` no extienden modelos domain (son DTOs de request/response compuestos); documentar la excepción con comentario inline en cada archivo.
- **`remainingGenerations: -1` es sentinel:** el cliente Flutter ignora este valor en Fase 2; no implementar lógica de cuota real hasta Fase 3.
- **Errores HTTP como 500 en esta fase:** los errores de Gemini y Storage propagan como 500; el mapeo a 422/503 es responsabilidad exclusiva de Fase 3.
- **Rideglory coding standards** (`rideglory-api`): seguir la estructura de módulos NestJS del repo, convención de nombres de archivos (`kebab-case.service.ts`), inyección de dependencias por constructor, `Logger` de NestJS (no `console.log`).
- **No commitear:** el árbol de trabajo queda sucio; el humano revisa y commitea.
