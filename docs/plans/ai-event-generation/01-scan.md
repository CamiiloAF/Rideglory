# 01 — System Scan

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:18:55Z

---

## Inventario Flutter

### Feature `events`

**Domain**
- `EventCoverRepository` — interfaz con `generateCover({title, eventType, city})` → `Either<DomainException, String>`
- `GetGenerateCoverUseCase` — caso de uso único para portada actual (Unsplash/Claude); a reemplazar
- No existen `GenerateEventDescriptionUseCase` ni `GenerateEventCoverUseCase` (Gemini)

**Data**
- `EventCoverService` — Retrofit, `@POST /events/generate-cover`, retorna `CoverGenerationDto`
- `CoverGenerationDto` — campos: `imageUrl`, `source`, `query`; Pattern B **no** aplicado (extiende `Object`, no un modelo dominio — correcto porque es DTO sin modelo 1:1 en dominio)
- `EventCoverRepositoryImpl` — implementa el repo; extrae `dto.imageUrl`; usa `executeService()`
- No existen DTOs para descripción IA ni para cobertura Gemini; `rideglory-contracts` tampoco los tiene

**Presentation**
- `EventFormCubit` / `EventFormState` — campo `coverGenerationResult: ResultState<String>` presente; sin campo equivalente para descripción IA ni historial de chat
- `CoverPreviewWidget` — muestra portada 16:9, botón "Generar con IA", botón "Regenerar", botón "Subir imagen"; flujo lineal sin burbujas de chat
- `CoverPlaceholderView` — placeholder visual cuando no hay portada
- **`AppRichTextEditor`** (`lib/shared/widgets/form/app_rich_text_editor.dart`) — ya tiene param `onAiSuggest: VoidCallback?` con botón "IA" en la toolbar, comentado como "Not implemented yet"; acepta `initialValue` como JSON delta; expone `onChanged` con JSON delta serializado

**Ruta de API registrada**
- `lib/core/http/api_routes.dart`: `generateEventCover = '/events/generate-cover'`

---

## Dependencias

### pubspec.yaml — clave para este feature

| Paquete | Estado |
|---|---|
| `flutter_quill: ^11.0.0` | Presente — `AppRichTextEditor` ya en uso |
| `firebase_storage: ^13.1.0` | Presente — usado en otros features (vehículos, fotos de perfil) |
| `firebase_remote_config: ^6.4.0` | Presente — usado en `ApiBaseUrlResolver` |
| `google_generative_ai` | **Ausente** — no está en pubspec |
| Paquete markdown→Delta | **Ausente** — ni `markdown_quill` ni `vsc_quill_delta_markdown` ni similar |

`flutter_quill` **no incluye** conversión Markdown→Delta de fábrica; requiere paquete adicional o implementación manual.

---

## Superficie rideglory-api

### api-gateway — endpoints events

| Método | Path | Propósito | Estado |
|---|---|---|---|
| `POST` | `/events/generate-cover` | Genera query con Claude Haiku, busca foto en Unsplash | **Existente — a eliminar** |
| `POST` | `/events` | Crea evento (proxies a events-ms) | Existente |
| `GET` | `/events` | Lista eventos con filtros | Existente |
| `GET` | `/events/my` | Eventos del usuario autenticado | Existente |
| `GET` | `/events/upcoming` | Próximos eventos (limit 5) | Existente |
| `PATCH` | `/events/:id/publish` | Publica borrador | Existente |
| `GET` | `/events/:id` | Detalle de evento | Existente |
| `PATCH` | `/events/:id` | Actualiza evento | Existente |
| `DELETE` | `/events/:id` | Elimina evento | Existente |
| `POST` | `/events/ai/description` | Asistente IA para descripción (Gemini texto) | **No existe** |
| `POST` | `/events/ai/cover` | Asistente IA para portada (Gemini imagen → Storage URL) | **No existe** |

### Servicios existentes relevantes

- **`ClaudeService`** (`api-gateway/src/common/`) — usa `@anthropic-ai/sdk`; a eliminar (solo lo usa `generate-cover`)
- **`UnsplashService`** (`api-gateway/src/common/`) — usa `axios`; a eliminar
- **`@nestjs/schedule`** — ya en `api-gateway/package.json`; disponible para cron de barrido Storage
- **`firebase-admin`** — ya en `api-gateway/package.json`; disponible para Remote Config Admin SDK y Firebase Storage

### rideglory-contracts

Paquete `file:../rideglory-contracts` importado en api-gateway. DTOs de eventos en `src/events/dto/`: `CreateEventDto`, `UpdateEventDto`, `EventFilterDto`, etc. No existen DTOs de IA (`AiDescriptionRequestDto`, `AiCoverRequestDto`, respuestas).

### events-ms / Prisma

Schema actual: modelos `Event` y `EventRegistration`. **Sin tabla `ai_usage_quota`**. La tabla de cuota debe crearse aquí (migración Prisma nueva).

### `@google/genai`

**Ausente** en todos los `package.json` del monorepo. Debe instalarse en `api-gateway`.

---

## Gap analysis

| Componente | Estado |
|---|---|
| `POST /events/generate-cover` (Unsplash+Claude) — backend | **Implemented** (a eliminar en Fase 1) |
| `GetGenerateCoverUseCase` + `EventCoverRepository` + `EventCoverService` — Flutter | **Implemented** (a reemplazar) |
| `CoverPreviewWidget` + `CoverPlaceholderView` | **Partial** — UI lineal, sin burbujas de chat |
| `AppRichTextEditor.onAiSuggest` hook | **Partial** — botón "IA" visible pero callback vacío |
| `EventFormCubit.coverGenerationResult` | **Partial** — estado de portada existe; sin estado de descripción IA ni historial de turnos |
| `GeminiService` (texto + imagen) — backend | **Not started** |
| `AiModule` en api-gateway | **Not started** |
| `POST /events/ai/description` | **Not started** |
| `POST /events/ai/cover` + Firebase Storage | **Not started** |
| Tabla Prisma `ai_usage_quota` + migración | **Not started** |
| Enforcement de cuota + errores tipados backend | **Not started** |
| `firebase-admin` Remote Config para límites | **Not started** (firebase-admin ya instalado) |
| DTOs IA en `rideglory-contracts` | **Not started** |
| `GenerateEventDescriptionUseCase` | **Not started** |
| `GenerateEventCoverUseCase` | **Not started** |
| `AiDescriptionChatCubit` + UI de burbujas | **Not started** |
| `AiCoverChatCubit` + UI de burbujas-imagen + full screen | **Not started** |
| Conversión Markdown → Quill Delta en Flutter | **Not started** (sin paquete) |
| Lectura de `ai_*_daily_limit` desde Remote Config en Flutter | **Not started** |
| Manejo 4 errores tipados (`quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error`) | **Not started** |
| Gestión de huérfanos Storage (`pending/{userId}/{draftId}`) + cron | **Not started** |
| Analytics `ai_*` events (5 nuevos) | **Not started** |
| Strings en `app_es.arb` para flujo IA | **Not started** |
| Tests backend (spec) para endpoints IA | **Not started** |
| `docs/features/events.md` actualizado | **Not started** |
| `@google/genai` package en api-gateway | **Not started** |

---

## Patrones

1. **Retrofit + executeService**: todo acceso HTTP en Flutter pasa por `executeService()` en `rest_client_functions.dart`; los cubits de chat deben seguir el mismo patrón aunque el estado sea más complejo (lista de turnos + `ResultState<String>`).

2. **DTO Pattern B obligatorio**: la nueva `AiCoverResponseDto` y `AiDescriptionResponseDto` deben extender sus modelos dominio si existe relación 1:1. Como los modelos de chat son propios (turno, historial), probablemente sean DTOs compuestos o de solo-request → excepción documentada.

3. **Cubit con estado freezed**: el `AiDescriptionChatCubit` y `AiCoverChatCubit` van a necesitar estado `@freezed` con campos: `List<ChatTurn> history`, `ResultState<String> generationResult`, `int remainingQuota`. No es un `Cubit<ResultState<T>>` simple.

4. **`AppRichTextEditor` ya tiene el punto de entrada**: el `onAiSuggest` callback está construido en el widget compartido; la Fase 4 solo debe conectar el cubit sin modificar el widget base (salvo que se decida abrir un bottom sheet de chat desde ahí).

5. **`@nestjs/schedule` + `firebase-admin` ya disponibles en api-gateway**: no requieren instalación nueva; el cron de barrido Storage y la lectura de Remote Config Admin son adición de servicio, no de dependencia.

6. **Cron en NestJS (`@Cron`)**: el módulo `scheduler` de `api-gateway` ya existe (`api-gateway/src/scheduler/`) con un servicio de notificaciones. El cron de barrido Storage puede vivir ahí o en un nuevo `StorageCleanupService` dentro del `AiModule`.

---

## Implicaciones para el plan

- **Fase 1 (Backend base)** puede arrancar limpio: instalar `@google/genai`, crear `AiModule` en api-gateway, implementar `GeminiService.generateDescription()`, agregar DTOs en `rideglory-contracts`, crear endpoint `POST /events/ai/description`, y eliminar `ClaudeService` + `UnsplashService` + el endpoint legacy. El spec existente `generate-cover.spec.ts` debe suprimirse o refactorizarse.

- **Fase 2 (Backend imagen)** tiene una dependencia oculta: Firebase Storage no está integrado en api-gateway hoy (solo en el cliente Flutter). Hay que agregar el SDK de Storage vía `firebase-admin` (ya instalado) para subir imágenes generadas al bucket. Validar que el bucket esté accesible desde el backend con las credenciales de `firebase-admin`.

- **Fase 3 (Backend cuota)** requiere migración Prisma en `events-ms`, no en api-gateway. La cuota se consulta desde api-gateway (llamada a events-ms via TCP o directamente a Prisma si api-gateway tiene acceso). Aclarar si api-gateway puede leer `events-ms` DB o si la cuota vive en api-gateway.

- **Fase 4 (App descripción)**: el `onAiSuggest` en `AppRichTextEditor` ya existe como punto de entrada. La UI de chat (bottom sheet con burbujas) es nueva. La conversión Markdown→Delta requiere paquete nuevo o implementación manual; evaluar `markdown_quill` o `flutter_quill_markdown` antes de elegir estrategia.

- **Fase 5 (App imagen)**: `CoverPreviewWidget` necesita refactor hacia una UI de chat-imagen. El estado `coverGenerationResult` en `EventFormCubit` puede coexistir con el nuevo `AiCoverChatCubit` (el cubit de chat es scoped al bottom sheet; el FormCubit solo recibe la URL final confirmada).

- **Pregunta abierta crítica para Fase 3**: ¿api-gateway accede a la DB de events-ms directamente o via TCP? Si es solo TCP, la cuota debe ser un microservicio propio dentro de events-ms (nuevo handler `checkAiQuota` / `incrementAiQuota`), no una llamada Prisma directa desde api-gateway.
