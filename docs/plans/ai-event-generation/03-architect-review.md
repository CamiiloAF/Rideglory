# 03 — Architect Review

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:23:01Z
**Veredicto:** ok_con_ajustes

---

## Validación por fase

### Fase 1 — Backend: Base de texto IA
**Complejidad: BAJA**

Viable sin bloqueadores. El `AiModule` es un módulo NestJS nuevo que vive en `api-gateway/src/ai/` sin depender de eventos-ms. El endpoint `POST /events/ai/description` puede implementarse íntegramente en api-gateway: recibe contexto + historial, llama a `GeminiService.generateDescription()`, devuelve Markdown.

Decisiones arquitectónicas confirmadas:
- `AiModule` reside en api-gateway (no en events-ms) — las generaciones IA son preocupación del gateway, no del microservicio de datos.
- `GeminiService` es `@Injectable()` dentro de `AiModule`; `AiController` expone el endpoint HTTP.
- `@anthropic-ai/sdk` y `ClaudeService` permanecen intactos en esta fase (no hay coordinación con Flutter todavía para el retiro seguro).
- Los DTOs de request/response van en `rideglory-contracts/src/ai/` (directorio nuevo; mismo patrón que `events/`, `users/`, etc.).

Ajuste menor: el path del endpoint debe ser `/ai/description`, no `/events/ai/description`. El endpoint no crea ni modifica un evento; es un servicio de generación. Agrupar bajo `/ai/*` evita contaminar el controller de eventos y facilita aplicar un guard de rate-limit propio.

---

### Fase 2 — Backend: Portada IA con Storage
**Complejidad: MEDIA**

Viable con una precondición técnica que debe resolverse al inicio de la fase: `firebase-admin` en api-gateway solo está inicializado con `credential` (o `projectId`) — **sin `storageBucket`**. La llamada a `getStorage(app).bucket()` falla si el bucket no está configurado.

Acción requerida: agregar `storageBucket: process.env.FIREBASE_STORAGE_BUCKET` al `initializeApp()` en `FirebaseAuthService`. Dado que el `App` singleton ya existe al arrancar, esto requiere que el env var esté presente en el proceso desde el inicio (no es lazy-loadable). Se debe agregar `FIREBASE_STORAGE_BUCKET` a las env vars de EC2 y al `.env.example`.

El `StorageCleanupService` (cron semanal `pending/`) puede vivir dentro del `AiModule` como `@Injectable()` con `@Cron(CronExpression.EVERY_WEEK)`, siguiendo el patrón exacto de `notification-scheduler.service.ts`. No es necesario un módulo propio.

Riesgo latente: la generación de imagen nativa en Gemini usa `responseModalities: ['IMAGE']` en la API `@google/genai`. Este parámetro solo está disponible en modelos `gemini-2.0-flash-preview-image-generation` o `imagen-3.0-*` — **no en `gemini-2.5-flash`**. Validar el modelo correcto antes de empezar implementación.

---

### Fase 3 — Backend: Sistema de cuotas
**Complejidad: MEDIA → ver ajuste**

La propuesta de tabla Prisma en events-ms introduce una dependencia cruzada: la cuota es un dato del usuario, no del evento. Si se agrega a events-ms, ese microservicio acumula responsabilidades fuera de su bounded context. Además, cada generación agrega dos round-trips TCP (check + increment) antes de llamar a Gemini.

**Ajuste arquitectónico (ver sección Ajustes):** la cuota debe vivir en Firestore (no en Prisma/events-ms). `firebase-admin` ya inicializado en api-gateway puede leer/escribir Firestore directamente sin TCP. La estructura es:

```
Firestore: ai_usage_quotas/{userId}/days/{YYYY-MM-DD}
  → descriptionCount: number
  → coverCount: number
  → ttl: Timestamp  (para limpieza automática con TTL policy)
```

Esto elimina la migración Prisma, el TCP round-trip, y los dos nuevos MessagePatterns en events-ms. La lectura de límites (`ai_description_daily_limit`, `ai_cover_daily_limit`) desde Remote Config Admin SDK permanece tal como propone el PO.

Si se prefiere mantener Prisma en events-ms (por consistencia de stack), es aceptable pero debe documentarse explícitamente el trade-off de latencia y acoplamiento.

---

### Fase 4 — App: Asistente de descripción
**Complejidad: ALTA**

La complejidad no está en la arquitectura de capas (que es clara) sino en dos puntos técnicos concretos:

**1. Conversión Markdown → Quill Delta.**
No existe paquete maduro para `flutter_quill ^11.0.0`. Los candidatos más recientes (`flutter_quill_markdown`, `markdown_quill`) no tienen releases compatibles con v11. La recomendación es implementar un `MarkdownToDeltaConverter` manual en `lib/features/events/data/` limitado al subconjunto que Gemini produce: párrafos, `## headings`, `**bold**`, `*italic*`, `- unordered lists`. Un parser completo es innecesario y arriesgado.

**2. Estado del `AiDescriptionChatCubit`.**
El estado `@freezed` con `List<AiChatTurn> history` + `ResultState<String> generationResult` + `int remainingQuota` es correcto. El cubit es scoped al bottom sheet (no global), instanciado con `BlocProvider` local en la pantalla que abre el chat — no va en el `MultiBlocProvider` de `main.dart`.

Patrón de datos confirmado:
- `AiDescriptionRequestDto` / `AiDescriptionResponseDto`: Pattern B no aplica (no hay modelo dominio 1:1); son request-only / response-only → excepción documentada en estándares.
- `AiChatTurn` es un modelo dominio puro: `role: AiChatRole (user|model)` + `content: String`.
- `GenerateEventDescriptionUseCase`: recibe `AiDescriptionRequest` (context + history), devuelve `Either<DomainException, String>` (el Markdown).

La conexión `AppRichTextEditor.onAiSuggest` → bottom sheet de chat está arquitectónicamente resuelta: el callback abre el sheet, el sheet tiene su propio `BlocProvider<AiDescriptionChatCubit>`, y al confirmar cierra el sheet y llama a `controller.replaceContent(delta)` en el editor.

---

### Fase 5 — App: Asistente de portada
**Complejidad: MEDIA**

Arquitectónicamente simétrica a Fase 4. `AiCoverChatCubit` es scoped al bottom sheet. La diferencia clave: el estado incluye `List<String> generatedUrls` (historial de imágenes de la sesión) para el visor de burbujas.

El retiro de `GetGenerateCoverUseCase` + `EventCoverService` + `EventCoverRepositoryImpl` debe ser atómico con el despliegue backend que retira `/events/generate-cover`. La coordinación es: Fase 5 Flutter finaliza → deploy backend elimina el endpoint legacy → deploy app.

`CoverPreviewWidget` se refactoriza: el botón "Generar con IA" abre el bottom sheet de chat en lugar de llamar directamente a `coverGenerationResult`. El `EventFormCubit` solo recibe la URL final confirmada vía un callback del sheet.

---

### Fase 6 — QA, analytics y cierre
**Complejidad: BAJA**

Sin bloqueadores arquitectónicos. Los 5 eventos de analytics (`ai_description_generated`, `ai_image_generated`, `ai_quota_exceeded`, `ai_generation_failed`, `ai_cover_used`) deben dispararse desde los cubits de chat (no desde la UI) — esto es correcto para clean architecture. El deploy sigue el workflow EC2 documentado (migraciones local-first, aunque con Firestore para cuota ya no hay migración Prisma).

---

## Contratos

### Endpoints HTTP (api-gateway)

#### POST /ai/description
```
Auth:    Bearer (Firebase ID token — obligatorio)
Request: {
  eventContext: {
    title:     string,           // nombre tentativo del evento
    eventType: EventType,        // enum existente
    city:      string,
    audience?: string            // descripción libre del público objetivo
  },
  history: [                     // turnos previos; máx 10 (recorte en cliente)
    { role: 'user'|'model', content: string }
  ]
}
Response 200: {
  markdown: string               // descripción generada en Markdown
}
Response 429: {
  error: 'quota_exceeded_user' | 'quota_exceeded_project',
  remaining: number
}
Response 422: { error: 'safety_blocked', message: string }
Response 503: { error: 'network_error', message: string }
```

#### POST /ai/cover
```
Auth:    Bearer (Firebase ID token — obligatorio)
Request: {
  prompt:  string,               // instrucción en lenguaje natural
  draftId: string                // UUID generado en cliente; usado como nombre en Storage
}
Response 200: {
  imageUrl: string,              // URL pública Firebase Storage (pending/{userId}/{draftId}.jpg)
  draftId:  string
}
Response 429: { error: 'quota_exceeded_user' | 'quota_exceeded_project', remaining: number }
Response 422: { error: 'safety_blocked', message: string }
Response 503: { error: 'network_error', message: string }
```

### Estructura Firestore (si se adopta el ajuste de cuota)
```
Collection: ai_usage_quotas
Document:   {userId}
  Subcollection: days
  Document: {YYYY-MM-DD}
    descriptionCount: number  (default 0)
    coverCount:       number  (default 0)
    createdAt:        Timestamp
```
TTL policy de Firestore configurable a 2 días para auto-limpieza.

### DTOs en rideglory-contracts
Directorio nuevo: `rideglory-contracts/src/ai/`
- `AiDescriptionRequestDto` — campos: `eventContext`, `history`
- `AiDescriptionResponseDto` — campo: `markdown`
- `AiCoverRequestDto` — campos: `prompt`, `draftId`
- `AiCoverResponseDto` — campos: `imageUrl`, `draftId`
- `AiErrorResponseDto` — campos: `error` (enum `AiErrorCode`), `remaining?`, `message?`
- `AiChatTurnDto` — campos: `role` (enum `AiChatRole`), `content`

Todos exportados en `rideglory-contracts/src/ai/index.ts` y re-exportados desde el `index.ts` raíz.

### Variables de entorno nuevas (api-gateway)
| Variable | Descripción | Ejemplo |
|---|---|---|
| `GEMINI_API_KEY` | Clave Gemini Developer API (free tier) | `AIzaSy...` |
| `FIREBASE_STORAGE_BUCKET` | Bucket de Firebase Storage | `rideglory-prod.appspot.com` |

### Modelos dominio Flutter nuevos
| Nombre | Archivo | Descripción |
|---|---|---|
| `AiChatTurn` | `lib/features/events/domain/model/ai_chat_turn.dart` | `role: AiChatRole`, `content: String` |
| `AiChatRole` | Enum en mismo archivo | `user`, `model` |
| `AiDescriptionRequest` | `lib/features/events/domain/model/ai_description_request.dart` | Payload para usecase |
| `AiCoverRequest` | `lib/features/events/domain/model/ai_cover_request.dart` | Payload para usecase |

---

## Riesgos

### R1 — Modelo de imagen Gemini en preview (ALTO)
`gemini-2.5-flash` no soporta generación de imagen nativa. El modelo correcto al día de hoy es `gemini-2.0-flash-preview-image-generation` (preview, sujeto a cambio de nombre). Si cambia antes de Fase 2, la implementación falla. **Mitigación:** declarar el model ID como constante configurable desde `.env` (`GEMINI_IMAGE_MODEL`); no hardcodear en código.

### R2 — Markdown→Delta sin paquete maduro (ALTO en Fase 4)
No existe paquete compatible con `flutter_quill ^11.0.0`. Una implementación manual puede tener bugs en edge cases. **Mitigación:** limitar el subconjunto de Markdown a lo que Gemini genera en la práctica (h2, párrafos, bold, italic, listas simples); escribir tests unitarios para el converter antes de integrarlo.

### R3 — Firebase Storage desde backend no inicializado (MEDIO en Fase 2)
La instancia firebase-admin actual no tiene `storageBucket`. Añadir el parámetro requiere que `FIREBASE_STORAGE_BUCKET` esté presente en todas las instancias (local dev, EC2). **Mitigación:** validar en Fase 2, día 1, antes de escribir lógica de generación de imagen.

### R4 — Coordinación del retiro del endpoint legacy (MEDIO)
Si Fase 3 elimina `/events/generate-cover` antes de que Fase 5 despliegue el cliente Flutter nuevo, la app existente rompe el flujo de portada. **Mitigación:** el endpoint legacy solo se elimina del backend como parte del deploy de Fase 5 (no en Fase 3). Añadir una nota explícita en el handoff de Fase 3 al backend dev.

### R5 — Latencia TCP de cuota (BAJO si se adopta Firestore)
Si se mantiene Prisma en events-ms, cada generación agrega 2 round-trips TCP (~5–20ms extra por round-trip en red local Docker). Con Firestore directo desde api-gateway el round-trip desaparece. Mitigación si se mantiene TCP: cache en memoria en api-gateway (TTL 60s por userId+date).

### R6 — Propagación de Remote Config en Flutter (BAJO)
Los límites leídos de Remote Config pueden tener hasta 12h de delay si el cliente no fuerza fetch. **Mitigación:** llamar `fetchAndActivate()` al montar el `AiDescriptionChatCubit` y el `AiCoverChatCubit` (no solo al arrancar la app).

---

## Ajustes

### AJ-1 — Renombrar paths de API: `/events/ai/*` → `/ai/*`
Los endpoints de generación IA no son operaciones CRUD de eventos. Ubicarlos bajo `/ai/*` en api-gateway los desacopla del `EventsController` y permite aplicar guards específicos (rate-limit, quota) sin contaminar la lógica de eventos. El `AiModule` tiene su propio controller `AiController`.

### AJ-2 — Cuota en Firestore, no en Prisma/events-ms
Reemplazar la migración Prisma + TCP de Fase 3 por escrituras Firestore directas desde api-gateway usando firebase-admin. Beneficios: sin migración, sin TCP round-trip, sin acoplamiento events-ms, auto-limpieza con TTL policy. La estructura de documento se define en la sección Contratos.

### AJ-3 — `GEMINI_IMAGE_MODEL` como env var
El model ID de imagen Gemini es inestable (preview). Exponerlo como variable de entorno permite cambiar el modelo sin redesplegar código.

### AJ-4 — `MarkdownToDeltaConverter` como clase de dominio, no de data
El converter vive en `lib/features/events/domain/utils/markdown_to_delta_converter.dart` — es lógica de transformación de contenido, no de acceso a datos. Exponer como clase utilitaria pura con tests unitarios. El `AiDescriptionChatCubit` lo invoca al momento de insertar en el editor.

### AJ-5 — `StorageCleanupService` dentro de `AiModule` (no módulo propio)
El cron de barrido de `pending/` es un servicio `@Injectable()` dentro del `AiModule` del api-gateway, siguiendo el patrón de `notification-scheduler.service.ts`. No justifica módulo NestJS independiente.

### AJ-6 — Retiro del endpoint legacy: explícitamente en Fase 5, no en Fase 3
La propuesta del PO menciona que el endpoint legacy podría retirarse en Fase 3 "según coordinación". Este ajuste lo fija: el retiro es parte del deploy de Fase 5 (coordinado con el retiro del cliente Flutter). Fase 3 no toca el endpoint legacy.
