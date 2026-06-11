> Slim handoff — read this before docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md

# Frontend handoff — app-ai-cover-assistant

## Contexto rápido

El backend `POST /ai/cover` **ya está implementado** en Fases 1-3. Tu trabajo es:
1. Implementar el nuevo flujo Flutter (dominio → datos → presentación)
2. Retirar el flujo legacy (ClaudeService/Unsplash → `EventCoverRepository`/`GetGenerateCoverUseCase`)

---

## API Contract

```
POST /ai/cover
Auth: Firebase ID token (automático via FirebaseAuthInterceptor)
Body: { "prompt": "string", "draftId": "uuid-v4" }
200: { "imageUrl": "string", "remainingGenerations": int }
429 + { "error": "quota_exceeded_user" }    → AiQuotaExceededUserException
429 + { "error": "quota_exceeded_project" } → AiQuotaExceededProjectException
422 + { "error": "safety_blocked" }         → AiSafetyBlockedException
503 + { "error": "network_error" }          → AiNetworkException
```

**ATENCIÓN:** Los dos 429 se distinguen por el body, no por el status code.

---

## Paso 1: `pubspec.yaml` + `app_es.arb`

```yaml
# pubspec.yaml — dependencies
uuid: ^4.5.1
```

Keys mínimas en `app_es.arb`:
```json
"ai_cover_placeholder_hint": "Describe la portada que quieres generar",
"ai_cover_use_this_image": "Usar esta imagen",
"ai_cover_use_this_cover": "Usar esta portada",
"ai_cover_generate_button": "Generar con IA",
"ai_cover_upload_button": "Subir imagen",
"ai_cover_remaining_quota": "{count} generaciones restantes hoy",
"@ai_cover_remaining_quota": { "placeholders": { "count": { "type": "int" } } },
"ai_error_quota_exceeded_user": "Alcanzaste tu límite de generaciones por hoy",
"ai_error_quota_exceeded_project": "Servicio temporalmente no disponible. Intenta más tarde",
"ai_error_safety_blocked": "El contenido fue bloqueado. Modifica la descripción",
"ai_error_network": "Error de conexión. Verifica tu red"
```

---

## Paso 2: Excepciones tipadas

Crear `lib/core/exceptions/ai_exceptions.dart`:
```dart
class AiQuotaExceededUserException extends DomainException { ... }
class AiQuotaExceededProjectException extends DomainException { ... }
class AiSafetyBlockedException extends DomainException { ... }
class AiNetworkException extends DomainException { ... }
```

---

## Paso 3: Dominio

```
lib/features/events/domain/model/ai_cover_request.dart   — { prompt: String, draftId: String }
lib/features/events/domain/model/ai_cover_result.dart    — { imageUrl: String, remainingGenerations: int }
lib/features/events/domain/repository/ai_cover_repository.dart  — abstract interface
lib/features/events/domain/use_cases/generate_event_cover_use_case.dart
  — genera draftId = Uuid().v4() AQUI; llama AiCoverRepository
  — NO en el cubit, NO en ningún widget
```

---

## Paso 4: Datos

```
lib/features/events/data/dto/ai_cover_request_dto.dart
  // Pattern B exception — request-only DTO; sin modelo de dominio 1:1
  { @JsonKey prompt, @JsonKey draftId }

lib/features/events/data/dto/ai_cover_response_dto.dart
  // Pattern B exception — composite (control field remainingGenerations + domain imageUrl)
  { @JsonKey imageUrl, @JsonKey remainingGenerations }

lib/features/events/data/service/ai_cover_service.dart
  @singleton @RestApi
  @POST('/ai/cover')
  Future<AiCoverResponseDto> generateCover(@Body() AiCoverRequestDto dto)

lib/features/events/data/repository/ai_cover_repository_impl.dart
  @Injectable(as: AiCoverRepository)
  try/catch DioException {
    statusCode 429 + body['error'] == 'quota_exceeded_user'    → AiQuotaExceededUserException
    statusCode 429 + body['error'] == 'quota_exceeded_project' → AiQuotaExceededProjectException
    statusCode 422 + body['error'] == 'safety_blocked'         → AiSafetyBlockedException
    statusCode 503 + body['error'] == 'network_error'          → AiNetworkException
    default → ejecutar executeService() helper
  }
```

---

## Paso 5: Presentación (DESPUÉS de aprobación del diseño Pencil)

### `AiCoverChatCubit`
- `@injectable` (transient) — NO `@singleton`, NO en MultiBlocProvider de main.dart
- Estado: `List<AiCoverBubble> bubbles`, `int? remainingQuota`, `bool inputEnabled`, `AiCoverError? error`
- Método `generateCover(String prompt)`:
  1. Agrega `AiCoverShimmerBubble` a la lista
  2. `emit(loading)` — campo de texto deshabilitado
  3. Llama `GenerateEventCoverUseCase`
  4. Éxito → reemplaza shimmer con `AiCoverImageBubble(imageUrl, remainingQuota)`
  5. `AiQuotaExceededUserException` → banner rojo; campo **permanece deshabilitado**
  6. Otros errores → banner con "Reintentar"; campo se rehabilita

### Widgets atómicos (1 clase por archivo)
- `AiCoverImageBubble` — imagen 16:9 + botón "Usar esta imagen"
- `AiCoverShimmerBubble` — shimmer 16:9 + `LinearProgressIndicator` indeterminado
- `AiCoverChatInput` — `AppTextField` + botón "Generar con IA"; deshabilitar en loading/quota_user
- `AiCoverQuotaIndicator` — muestra `context.l10n.ai_cover_remaining_quota(count)`
- `AiCoverErrorBanner` — banner rojo; "Reintentar" solo si NO es quota_exceeded_user

### `AiCoverChatSheet`
- `DraggableScrollableSheet` como `showModalBottomSheet`
- `BlocProvider(create: (_) => getIt<AiCoverChatCubit>())` scoped aquí
- Retorna `String? imageUrl` cuando el usuario toca "Usar esta imagen"

### `AiCoverFullScreenPage`
- Recibe `imageUrl` como argumento
- `AppButton` ancho completo (label: `ai_cover_use_this_cover`) + `SafeArea` inferior
- Botón X en app bar — cierra sin confirmar

---

## Paso 6: Integración en `event_form_content.dart`

Reemplazar el bloque cover legacy (líneas 95-150) con:
```dart
// Selector: [Generar con IA] | [Subir imagen]
// Al pulsar "Generar con IA":
final url = await showModalBottomSheet<String>(...AiCoverChatSheet...);
if (!context.mounted) return;        // ← OBLIGATORIO
if (url != null) {
  context.read<FormImageCubit>().setRemoteImageUrl(url);
}
// Al pulsar "Subir imagen":
context.read<FormImageCubit>().pickImageFromGallery();
```

**NUNCA** llamar `context.read<EventFormCubit>()` para la portada dentro del sheet ni en el caller.

---

## Paso 7: Retiro legacy

**Eliminar archivos:**
- `lib/features/events/domain/repository/event_cover_repository.dart`
- `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart`
- `lib/features/events/data/dto/cover_generation_dto.dart` + `.g.dart`
- `lib/features/events/data/service/event_cover_service.dart` + `.g.dart`
- `lib/features/events/data/repository/event_cover_repository_impl.dart`
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart`
- `lib/features/events/presentation/form/widgets/cover_placeholder_view.dart`

**Limpiar `event_form_cubit.dart`:**
- Eliminar campo `coverGenerationResult` de `EventFormState`
- Eliminar métodos `generateCover()` y `resetCoverGeneration()`
- Eliminar import y argumento constructor `GetGenerateCoverUseCase`

**Limpiar `event_form_view.dart`:**
- Eliminar `coverGenerationResult` de `listenWhen`
- Eliminar bloque `state.coverGenerationResult.whenOrNull(...)` del listener

**Limpiar `api_routes.dart`:**
- Eliminar `static const generateEventCover = '/events/generate-cover'`
- Agregar `static const aiCover = '/ai/cover'`

---

## Paso 8: Regenerar código

```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
dart analyze
```

> Full detail: docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md
