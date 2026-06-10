# Architect handoff — app-ai-cover-assistant

**Date:** 2026-06-09T02:21:08Z
**Status:** done

---

## Decisiones

| # | Decisión | Razonamiento |
|---|----------|-------------|
| 1 | Nuevo feature slice `ai_cover` dentro de `lib/features/events/` (no feature folder separado) | El flujo es parte del event form; misma jerarquía que domain/data ya existente. Mantiene cohesión. |
| 2 | 4 excepciones tipadas en `lib/core/exceptions/ai_exceptions.dart` | Las excepciones son transversales a cualquier flujo IA (description + cover); pertenecen al core, no al feature. |
| 3 | `AiCoverChatCubit` es `@injectable` (transient), instanciado via `BlocProvider` en `AiCoverChatSheet` | Scoped al bottom sheet, no singleton. PRD lo especifica explícitamente. |
| 4 | `draftId` generado exclusivamente en `GenerateEventCoverUseCase` con `Uuid().v4()` | Cumple criterio AC §6. Cubit nunca llama `Uuid()`. |
| 5 | `FormImageCubit.setRemoteImageUrl(url)` es el único canal para aplicar portada | Refactor limpio: EventFormCubit pierde toda referencia a cover. AiCoverChatSheet retorna `String?` al pop; `event_form_content.dart` lo aplica con verificación `context.mounted`. |
| 6 | `AiCoverRequestDto` / `AiCoverResponseDto` son Pattern B exception (request-only + composite) | `AiCoverRequestDto` no tiene 1:1 con modelo de dominio; `AiCoverResponseDto` tiene campo de control `remainingGenerations` + `imageUrl`. Documentar inline. |
| 7 | `generate-cover.spec.ts` se elimina (no se convierte a spec negativo 404) | El controlador queda limpio; el test negativo de 404 es trivial y sin valor en un codebase que ya tiene e2e manual. Conforme con PRD §6 guardrail. |
| 8 | `axios` se elimina de `package.json` | Confirmado cero usos en `api-gateway/src/` fuera de `unsplash.service.ts` y `generate-cover.spec.ts`. Ambos se eliminan. |
| 9 | `cover_placeholder_view.dart` se elimina junto con `cover_preview_widget.dart` | Solo es usado por `CoverPreviewWidget`. Ningún otro widget lo importa. |
| 10 | `needsDesign: true` — el Design agent debe crear mockups en `rideglory.pen` ANTES de implementar la UI | Regla de proyecto (MEMORY: "UI: diseñar antes de implementar"). `AiCoverChatSheet`, `AiCoverFullScreenPage` y todos los widgets atómicos deben tener frame aprobado. |

---

## Change map

### Flutter — archivos nuevos

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/core/exceptions/ai_exceptions.dart` | create | 4 typed exceptions (AiQuotaExceededUser, AiQuotaExceededProject, AiSafetyBlocked, AiNetwork) que extienden DomainException | low |
| `lib/features/events/domain/model/ai_cover_request.dart` | create | Modelo de dominio puro (prompt, draftId) | low |
| `lib/features/events/domain/model/ai_cover_result.dart` | create | Modelo de dominio puro (imageUrl, remainingGenerations) | low |
| `lib/features/events/domain/repository/ai_cover_repository.dart` | create | Interfaz de dominio — contrato para la capa de datos | low |
| `lib/features/events/domain/use_cases/generate_event_cover_use_case.dart` | create | Genera draftId con Uuid().v4() internamente; llama AiCoverRepository | low |
| `lib/features/events/data/dto/ai_cover_request_dto.dart` | create | Pattern B exception — request-only DTO; sin modelo 1:1; commentario inline obligatorio | low |
| `lib/features/events/data/dto/ai_cover_response_dto.dart` | create | Pattern B exception — composite DTO; commentario inline obligatorio | low |
| `lib/features/events/data/service/ai_cover_service.dart` | create | Retrofit client @POST('/ai/cover') con AiCoverRequestDto → AiCoverResponseDto | low |
| `lib/features/events/data/repository/ai_cover_repository_impl.dart` | create | try/catch DioException; mapea 4 error codes a typed exceptions; fallback a executeService | med |
| `lib/features/events/presentation/form/cubit/ai_cover_chat_cubit.dart` | create | @injectable transient; estado: lista de burbujas + quota + error banner + input enabled | low |
| `lib/features/events/presentation/form/widgets/ai_cover_chat_sheet.dart` | create | DraggableScrollableSheet con lista de burbujas; retorna String? URL al pop | med |
| `lib/features/events/presentation/form/widgets/ai_cover_image_bubble.dart` | create | Burbuja 16:9 con botón secondary "Usar esta imagen" | low |
| `lib/features/events/presentation/form/widgets/ai_cover_shimmer_bubble.dart` | create | Shimmer 16:9 + LinearProgressIndicator indeterminado durante generación | low |
| `lib/features/events/presentation/form/widgets/ai_cover_chat_input.dart` | create | TextField + botón Generar; se deshabilita en loading y en quota_exceeded_user | low |
| `lib/features/events/presentation/form/widgets/ai_cover_quota_indicator.dart` | create | Muestra "{count} generaciones restantes hoy" | low |
| `lib/features/events/presentation/form/widgets/ai_cover_error_banner.dart` | create | Banner rojo con mensaje y opcionalmente botón "Reintentar" | low |
| `lib/features/events/presentation/ai_cover/ai_cover_full_screen_page.dart` | create | Página full-screen; CTA primario AppButton ancho completo + SafeArea inferior; botón X | low |

### Flutter — archivos modificados

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | modify | Eliminar: campo coverGenerationResult, métodos generateCover()/resetCoverGeneration(), import/inyección GetGenerateCoverUseCase | med |
| `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` | modify | Regenerar via build_runner (consecuencia del cambio en EventFormState) | med |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | modify | Eliminar coverGenerationResult de listenWhen y del listener | low |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | modify | Reemplazar bloque cover legacy (BlocBuilder coverGenerationResult + CoverPreviewWidget + _triggerGenerate) con selector [Generar con IA] \| [Subir imagen] + showModalBottomSheet + context.mounted guard + FormImageCubit.setRemoteImageUrl() | high |
| `lib/core/http/api_routes.dart` | modify | Eliminar generateEventCover; agregar static const aiCover = '/ai/cover' | low |
| `lib/l10n/app_es.arb` | modify | Agregar 7+ keys: ai_cover_placeholder_hint, ai_cover_use_this_image, ai_cover_use_this_cover, ai_cover_generate_button, ai_cover_upload_button, ai_cover_remaining_quota (parametrizado), ai_error_quota_exceeded_user, ai_error_quota_exceeded_project, ai_error_safety_blocked, ai_error_network | low |
| `pubspec.yaml` | modify | Agregar uuid: ^4.5.1 | low |
| `lib/core/di/injection.config.dart` | modify | Regenerar via build_runner (nuevo AiCoverService + AiCoverRepositoryImpl; eliminados EventCoverService + EventCoverRepositoryImpl + GetGenerateCoverUseCase + EventFormCubit constructor change) | med |

### Flutter — archivos eliminados

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/events/domain/repository/event_cover_repository.dart` | delete | Reemplazado por AiCoverRepository | low |
| `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` | delete | Reemplazado por GenerateEventCoverUseCase | low |
| `lib/features/events/data/dto/cover_generation_dto.dart` | delete | Reemplazado por ai_cover_request_dto.dart + ai_cover_response_dto.dart | low |
| `lib/features/events/data/dto/cover_generation_dto.g.dart` | delete | Generado; se elimina con su fuente | low |
| `lib/features/events/data/service/event_cover_service.dart` | delete | Reemplazado por ai_cover_service.dart | low |
| `lib/features/events/data/service/event_cover_service.g.dart` | delete | Generado; se elimina con su fuente | low |
| `lib/features/events/data/repository/event_cover_repository_impl.dart` | delete | Reemplazado por ai_cover_repository_impl.dart | low |
| `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` | delete | Reemplazado por AiCoverChatSheet + AiCoverImageBubble | low |
| `lib/features/events/presentation/form/widgets/cover_placeholder_view.dart` | delete | Solo usado por CoverPreviewWidget; sin otros consumidores | low |

### Backend (rideglory-api/api-gateway) — modificados

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `api-gateway/src/events/events.controller.ts` | modify | Eliminar @Post('generate-cover'), ClaudeService/UnsplashService de constructor e imports | low |
| `api-gateway/src/events/events.module.ts` | modify | Eliminar ClaudeService y UnsplashService de providers[] e imports | low |
| `api-gateway/package.json` | modify | Eliminar @anthropic-ai/sdk; eliminar axios | low |
| `api-gateway/.env.example` | modify | Eliminar ANTHROPIC_API_KEY y UNSPLASH_ACCESS_KEY (líneas 30 y 33) | low |

### Backend (rideglory-api/api-gateway) — eliminados

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `api-gateway/src/events/generate-cover.spec.ts` | delete | Tests del endpoint legacy; eliminar ANTES del grep de axios | low |
| `api-gateway/src/events/dto/generate-cover.dto.ts` | delete | DTO del endpoint legacy | low |
| `api-gateway/src/common/claude.service.ts` | delete | Servicio legacy; no usado por ningún otro módulo | low |
| `api-gateway/src/common/unsplash.service.ts` | delete | Servicio legacy; no usado por ningún otro módulo | low |

---

## Contratos API

### `POST /ai/cover` (YA IMPLEMENTADO en Fases 1-3)

| Campo | Valor |
|-------|-------|
| Auth | Firebase ID token (FirebaseAuthInterceptor — automático) |
| Request body | `{ "prompt": "string", "draftId": "uuid-v4" }` |
| Success 200 | `{ "imageUrl": "string", "remainingGenerations": number }` |
| Error 429 + `{ "error": "quota_exceeded_user" }` | → `AiQuotaExceededUserException` |
| Error 429 + `{ "error": "quota_exceeded_project" }` | → `AiQuotaExceededProjectException` |
| Error 422 + `{ "error": "safety_blocked" }` | → `AiSafetyBlockedException` |
| Error 503 + `{ "error": "network_error" }` | → `AiNetworkException` |

**Mapeo en `AiCoverRepositoryImpl`:** el `try/catch` inspeciona `DioException.response?.statusCode` y `DioException.response?.data['error']` antes de delegar al helper `executeService`.

**Notar:** Los 429 de quota_exceeded_user y quota_exceeded_project se distinguen por el campo `error` en el cuerpo, NO por el status code (ambos son 429). La lógica de mapeo debe leer el body.

### Endpoint eliminado

`POST /events/generate-cover` — después del retiro backend devuelve 404. No reemplazar con redirección.

---

## Datos / Migraciones

No hay migraciones de base de datos. El sistema de cuotas ya opera en Firestore (`ai_usage_quotas/{userId}/days/{YYYY-MM-DD}`) implementado en Fase 3. No se modifica.

---

## Env

| Variable | Acción | Razón |
|----------|--------|-------|
| `ANTHROPIC_API_KEY` | Eliminar de `.env.example` | ClaudeService eliminado |
| `UNSPLASH_ACCESS_KEY` | Eliminar de `.env.example` | UnsplashService eliminado |
| Variables EC2 (`ANTHROPIC_API_KEY`, `UNSPLASH_ACCESS_KEY`) | Eliminar de EC2 DESPUÉS de confirmar estabilidad del deploy | Guardrail del PRD §6 |

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| Los 429 de `quota_exceeded_user` y `quota_exceeded_project` tienen el mismo HTTP status — distinción por cuerpo | `AiCoverRepositoryImpl` inspecciona `response.data['error']` explícitamente antes de crear la excepción tipada |
| `context.mounted` no verificado en `event_form_content.dart` tras `await showModalBottomSheet` | QA debe verificar este check como blocker (criterio AC §6 guardrail) |
| `build_runner` puede fallar en worktrees frescos por build hooks de `objective_c` | Usar `--force-jit` o tener `pubspec.lock` copiado de main |
| `event_form_view.dart` aún tiene el listener para `coverGenerationResult` → si no se limpia, `FormImageCubit.setRemoteImageUrl` se llama desde dos lugares | Verificar que `coverGenerationResult` se elimina completamente del state antes de regenerar freezed |
| `generate-cover.spec.ts` usa `axios` directamente (unit test de UnsplashService) — debe eliminarse ANTES del grep de axios | El backend agent debe eliminar el spec como primer paso del retiro |

---

## Orden de implementación

```
1. Backend agent  → Retiro legacy completo (spec, dto, services, controller, module, packages, env.example)
2. Frontend agent → pubspec.yaml + app_es.arb (uuid + l10n keys)
3. Frontend agent → lib/core/exceptions/ai_exceptions.dart (4 typed exceptions)
4. Frontend agent → Domain layer (AiCoverRequest, AiCoverResult, AiCoverRepository, GenerateEventCoverUseCase)
5. Frontend agent → Data layer (DTOs, AiCoverService Retrofit, AiCoverRepositoryImpl con typed error mapping)
6. Design agent   → Mockups Pencil: AiCoverChatSheet + AiCoverFullScreenPage + widgets atómicos
   [esperar aprobación humana del diseño]
7. Frontend agent → Presentation layer (AiCoverChatCubit + todos los widgets nuevos)
8. Frontend agent → Integración en event_form_content.dart (selector IA|upload + sheet + context.mounted)
9. Frontend agent → Retiro legacy Flutter (delete archivos + limpiar EventFormCubit + EventFormView)
10. Frontend agent → dart run build_runner build --delete-conflicting-outputs --force-jit
11. QA agent      → dart analyze + flutter test + widget/cubit tests
```

---

## Superficie de regresión

- **Flujo de subida manual de imagen:** `FormImageCubit.pickImageFromGallery()` en `event_form_content.dart` — debe seguir funcionando idéntico tras el refactor del bloque cover.
- **EventFormCubit.saveEvent()** con `remoteCoverImageUrl` (recibe la URL desde `FormImageCubit`) — lógica intacta, no se modifica.
- **`event_form_view.dart` listener de `saveResult`** — no se toca; solo se elimina el listener de `coverGenerationResult`.
- **DI de EventFormCubit** — pierde 1 argumento del constructor (`GetGenerateCoverUseCase`); `injection.config.dart` debe regenerarse; cualquier test de cubit que mockee el constructor falla si no se actualiza.
- **`cover_placeholder_view.dart`** — confirmado sin otros consumidores; deleción segura.
- **`generate-cover.spec.ts`** tiene test de `UnsplashService` que usa `axios.get` spy — si no se elimina antes del grep, el grep de `axios` dará falso positivo y `axios` no se quitará de `package.json`.

---

## Fuera de alcance

- `AppRichTextEditor`, `AiDescriptionChatCubit`, `MarkdownToDeltaConverter` (Fase 4)
- Analytics `ai_*` events (Fase 6)
- Specs NestJS de `POST /ai/cover` (Fase 6)
- Cambios en `events-ms`, Firestore schema, Remote Config
- Eliminación de variables de entorno de EC2 (post-deploy estable)
