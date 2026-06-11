# 00 — Intake

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:16:53Z

---

## Fuente

`docs/prds/prd-ai-event-generation.md` (PRD de 2026-06-04)

---

## Objetivo

Reemplazar el flujo actual de generación de portada (`/events/generate-cover` con Claude + Unsplash) por dos asistentes de IA conversacionales integrados en el formulario de evento: uno para **descripción** (texto enriquecido, Markdown → Quill Delta) y otro para **portada** (imagen 16:9 generada por IA). Ambos usan **Google Gemini Developer API (free tier)** como único proveedor, sin costo para el proyecto. Todo el procesamiento vive en el backend (`rideglory-api` / `api-gateway`); la clave nunca sale al cliente.

---

## Alcance percibido

### Backend (`rideglory-api` / `api-gateway`)
- Nuevo `AiModule` con `GeminiService` (métodos para texto e imagen vía `@google/genai`)
- Dos endpoints: `POST /events/ai/description` (→ Markdown) y `POST /events/ai/cover` (→ URL de imagen en Firebase Storage)
- Prompts con contexto de rider colombiano + `eventContext`; lógica nueva-vs-edición por keywords es-CO
- Cuota por usuario/día (5 img, 15 desc) almacenada en tabla Prisma `ai_usage_quota` en `events-ms`; límites leídos de Firebase Remote Config (Admin SDK)
- Errores tipados: `quota_exceeded_user`, `quota_exceeded_project`, `safety_blocked`, `network_error`
- Gestión de huérfanos en Firebase Storage: ruta `pending/{userId}/{draftId}.jpg`, sobrescritura en cada turno, mover al guardar evento, cron barrido >7 días
- Eliminar `UnsplashService`, `ClaudeService.generateSearchQuery`, secret `UNSPLASH_ACCESS_KEY` y endpoint `generate-cover`
- DTOs nuevos en `rideglory-contracts`

### App (Flutter)
- Capa data: nuevo Retrofit client / ampliar `EventCoverService` para los dos endpoints nuevos; DTOs con Pattern B
- Capa domain: `GenerateEventDescriptionUseCase`, `GenerateEventCoverUseCase` (reemplazan `GetGenerateCoverUseCase`)
- Presentación:
  - `AiDescriptionChatCubit` + UI de chat (burbujas); respuesta inyectada en `AppRichTextEditor` como Quill Delta (conversión Markdown→Delta en cliente); confirmación antes de pisar texto existente
  - `AiCoverChatCubit` + UI de chat (burbujas-imagen); visor full screen; "Usar esta imagen" fija la portada
  - Lectura de `ai_*_daily_limit` desde Remote Config para mostrar restantes y deshabilitar envío
  - Manejo de los 4 errores tipados con mensaje en español
- Telemetría: `ai_description_generated`, `ai_image_generated`, `ai_quota_exceeded`, `ai_generation_failed`, `ai_cover_used`
- Strings en `app_es.arb`; `dart analyze` limpio; `flutter test` al 100%
- Actualizar `docs/features/events.md`

### Fases según PRD (§10)
1. Backend base — AiModule, GeminiService texto, endpoint description, DTOs, eliminar Unsplash/Claude-query
2. Backend imagen — endpoint cover, imagen 16:9 → Storage → URL, lógica nueva-vs-edición, limpieza pending + cron
3. Backend cuota — tabla Prisma, Remote Config Admin, enforcement + errores tipados
4. App descripción — AiDescriptionChatCubit, UI chat, Markdown→Delta, confirmación sobreescritura
5. App imagen — AiCoverChatCubit, UI chat + full screen + "Usar esta imagen", 4 errores, cuota desde Remote Config
6. QA + docs — analytics, strings, tests, docs actualizada, deploy backend

---

## Preguntas abiertas

1. **`rideglory-contracts`**: ¿Ya existe un paquete compartido de DTOs entre api-gateway y la app Flutter, o hay que crearlo? El PRD lo menciona pero no se clarifica si está presente.
2. **Modelo Gemini para imagen**: El PRD indica "Gemini 2.5 Flash Image" (descartando Imagen 4 por su EOL el 2026-06-24). ¿El modelo ya soporta generación nativa de imagen en free tier al momento de implementar, o se usa la API de edición/inpainting de Gemini? Validar nombre exacto del modelo.
3. **`dart_quill_delta` / `markdown`**: ¿Hay ya algún paquete de conversión Markdown→Delta en el `pubspec.yaml`, o es adición nueva? Verificar si `flutter_quill` trae utilidades propias suficientes.
4. **Historial de chat en cliente**: El PRD dice stateless en servidor — el historial lo aporta el cliente en cada request. ¿El `history` en el DTO es ilimitado o se recorta a los últimos N turnos para no exceder tokens/ventana de Gemini?
5. **Pantalla de entrada al chat IA**: ¿El asistente de descripción y el de imagen son dos botones distintos en el formulario de evento, o un único chat combinado? El PRD habla de "dos asistentes" separados.
6. **Cron de barrido Storage**: ¿Se implementa como un scheduled job en NestJS (p. ej. `@Cron`) dentro del api-gateway, o como Cloud Function / Cloud Scheduler separado?
7. **Migración de usuarios existentes**: ¿Los eventos que hoy tienen portada de Unsplash necesitan algún tratamiento especial al eliminar ese servicio?
