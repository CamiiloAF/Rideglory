# Fase 5 — App — Asistente de portada + retiro completo del flujo legacy

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T21:58:55Z
**Nivel rg-exec recomendado:** full

---

## Objetivo

Un organizador puede generar portadas IA en un chat visual, previsualizar en pantalla completa y confirmar la que le guste. El flujo Unsplash/Claude desaparece totalmente — código Flutter, código backend y variables de entorno — en esta única fase, coordinada como un deploy atómico.

---

## Alcance (entra / no entra)

### Entra

**Flutter — nuevo dominio y data (simétrico a Fase 4):**
- Modelo de dominio `AiCoverRequest` (`prompt: String`, `draftId: String`) — pure Dart
- Modelo de dominio `AiCoverResult` (`imageUrl: String`, `remainingGenerations: int`) — retorno del use case
- Interfaz `AiCoverRepository` con `Future<Either<DomainException, AiCoverResult>> generateCover(AiCoverRequest request)`
- `AiCoverRepositoryImpl` (`@Injectable(as: AiCoverRepository)`) con mapeo de los 4 errores tipados vía try/catch directo sobre `DioException`
- `GenerateEventCoverUseCase` → `Either<DomainException, AiCoverResult>`; genera `draftId = const Uuid().v4()` dentro del use case
- Agregar paquete `uuid` a `pubspec.yaml` (verificar primero — actualmente ausente)
- DTOs `AiCoverRequestDto` / `AiCoverResponseDto` con excepción Pattern B documentada
- Retrofit service `AiCoverService` hacia `POST /ai/cover`

**Flutter — presentación:**
- `AiCoverChatCubit` (`@injectable`, scoped al bottom sheet) con estado `@freezed`
- Bottom sheet `AiCoverChatSheet` con `DraggableScrollableSheet` — burbujas-imagen 16:9
- `AiCoverShimmerBubble` con `LinearProgressIndicator` indeterminado durante generación (~10-15 s)
- `CachedNetworkImage` en `AiCoverImageBubble` para imágenes confirmadas
- `AiCoverFullScreenPage` con CTA "Usar esta portada" (`AppButton` ancho completo + `SafeArea`) y botón X
- Botón "Usar esta imagen" accesible en burbuja (secondary) Y como CTA en visor full-screen (primary)
- Integración en `event_form_content.dart`: `onGenerateWithAITap` abre el sheet; al hacer `pop` con URL llama `FormImageCubit.setRemoteImageUrl(url)` — sin pasar por `EventFormCubit`
- Selector [Generar con IA] | [Subir imagen] en la sección de portada; el botón "Subir imagen" permanece
- Mapeo de los 4 errores tipados backend → subclases de `DomainException` definidas en Paso 1 → UI

**Flutter — retiro legacy (atómico):**
- Eliminar `GetGenerateCoverUseCase`, interfaz `EventCoverRepository`, `EventCoverRepositoryImpl`
- Eliminar `EventCoverService` (Retrofit client) y `CoverGenerationDto`
- Eliminar `ApiRoutes.generateEventCover` de `api_routes.dart`
- Limpiar `event_form_cubit.dart` completamente: campo `coverGenerationResult` en `EventFormState`, método `generateCover()`, método `resetCoverGeneration()`, inyección `GetGenerateCoverUseCase _getGenerateCoverUseCase`, y su import — no agregar método `setCoverUrl()`
- Limpiar `event_form_view.dart`: remover `coverGenerationResult` de `listenWhen` y su bloque `whenOrNull`
- Limpiar `event_form_content.dart`: remover `BlocBuilder<EventFormCubit>` sobre `coverGenerationResult`, eliminar lógica de switch `FormImageSection`/`CoverPreviewWidget`, eliminar `_triggerGenerate()`
- Eliminar `CoverPreviewWidget` (`cover_preview_widget.dart`) — reemplazado por el sheet + `FormImageSection`

**Backend (api-gateway) — retiro legacy (atómico con deploy Flutter):**
- Eliminar `ClaudeService` (`api-gateway/src/common/claude.service.ts`) y todos sus usos
- Eliminar `UnsplashService` (`api-gateway/src/common/unsplash.service.ts`) y todos sus usos
- Eliminar el handler `@Post('generate-cover')` + sus imports de `events.controller.ts`
- Eliminar o convertir en spec negativo `generate-cover.spec.ts` **antes** de verificar usos de `axios`
- Eliminar `@anthropic-ai/sdk` de `api-gateway/package.json`; eliminar `axios` si no tiene otros usos (verificar con grep después de eliminar el spec)
- Eliminar de `api-gateway/.env.example` y documentar retiro de EC2: `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY`

**Strings l10n del flujo de portada IA en `app_es.arb`** (claves mínimas requeridas — ver criterio 9)

### No entra

- Modificación de `AppRichTextEditor` (artefacto de Fase 4)
- `AiDescriptionChatCubit` ni ningún componente del asistente de descripción (Fase 4)
- `MarkdownToDeltaConverter` (Fase 4)
- Analytics `ai_*` (Fase 6)
- Specs NestJS de `POST /ai/cover` (Fase 6)
- Cambios en `events-ms`, Firestore ni Remote Config (Fases 1-3)

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificar precondición de Fases 1-3

Confirmar que `POST /ai/cover` responde con `{ imageUrl, draftId, remainingGenerations }` y que los 4 errores tipados retornan el campo `error` esperado. Si el backend no está desplegado, detener y reportar.

---

### Paso 1 — Verificar / crear artefactos de dominio compartidos de Fase 4

Si Fase 4 ya fue ejecutada, los artefactos de este paso ya existen; solo verificar su presencia. Si no, crearlos ahora como precondición de compilación.

**1a. Modelo de dominio `AiChatTurn` y enum `AiChatRole`**

Archivo: `lib/features/events/domain/model/ai_chat_turn.dart`

```dart
// Clase pura Dart — sin imports Flutter.
// Nombre canónico para todo el proyecto; simetría con AiChatTurnDto en rideglory-contracts.
enum AiChatRole { user, model }

class AiChatTurn {
  const AiChatTurn({required this.role, required this.content});
  final AiChatRole role;
  final String content;
}
```

Sin este archivo, `AiCoverChatState` (que contiene `List<AiChatTurn>`) no compila en una ejecución standalone de esta fase.

**1b. Subclases de `DomainException` para errores IA**

Si Fase 4 ya fue ejecutada, las siguientes subclases existen en `lib/core/exceptions/domain_exception.dart`. Verificar su presencia. Si no existen, crearlas ahora:

```dart
class AiQuotaExceededUserException extends DomainException {
  const AiQuotaExceededUserException()
      : super(message: 'Has alcanzado tu límite diario de generaciones.');
}
class AiQuotaExceededProjectException extends DomainException {
  const AiQuotaExceededProjectException()
      : super(message: 'El servicio de IA está temporalmente saturado. Inténtalo más tarde.');
}
class AiSafetyBlockedException extends DomainException {
  const AiSafetyBlockedException()
      : super(message: 'Tu solicitud fue bloqueada por el filtro de contenido. Intenta reformular.');
}
class AiNetworkException extends DomainException {
  const AiNetworkException()
      : super(message: 'Error de conexión. Verifica tu internet e intenta de nuevo.');
}
```

Estas subclases permiten distinguir el tipo de error con `error is AiQuotaExceededUserException` sin comparar strings. Los mensajes son placeholders en español; las keys ARB definitivas se agregan en Fase 6.

---

### Paso 2 — Verificar dependencia `uuid` en Flutter

Revisar `pubspec.yaml`. El paquete `uuid` NO está presente actualmente. Agregarlo:
```yaml
uuid: ^4.5.1   # verificar versión estable más reciente en pub.dev
```
Ejecutar `flutter pub get`.

---

### Paso 3 — Domain — modelos, repositorio e interfaz

**3a. Crear `AiCoverRequest`**
- Archivo: `lib/features/events/domain/model/ai_cover_request.dart`
- Clase Dart pura (sin imports Flutter): campos `prompt: String`, `draftId: String`, constructor `const`

**3b. Crear `AiCoverResult`**
- Archivo: `lib/features/events/domain/model/ai_cover_result.dart`
- Clase Dart pura: campos `imageUrl: String`, `remainingGenerations: int`, constructor `const`
- Razón de existencia: el use case necesita devolver tanto la URL como la cuota restante sin exponer el DTO

**3c. Crear interfaz `AiCoverRepository`**
- Archivo: `lib/features/events/domain/repository/ai_cover_repository.dart`
- Método único:
  ```dart
  abstract interface class AiCoverRepository {
    Future<Either<DomainException, AiCoverResult>> generateCover(AiCoverRequest request);
  }
  ```

**3d. Crear `GenerateEventCoverUseCase`**
- Archivo: `lib/features/events/domain/use_cases/generate_event_cover_use_case.dart`
- Inyecta `AiCoverRepository`; anotación `@injectable`
- **Genera el `draftId` dentro del use case** — el cubit recibe solo el `prompt`:
  ```dart
  Future<Either<DomainException, AiCoverResult>> call(String prompt) {
    final draftId = const Uuid().v4();
    final request = AiCoverRequest(prompt: prompt, draftId: draftId);
    return _repository.generateCover(request);
  }
  ```
- No existe `Uuid().v4()` en ningún otro lugar (cubit ni widget)

---

### Paso 4 — Data — DTOs, Retrofit service, repositorio

**4a. Crear `AiCoverRequestDto`**
- Archivo: `lib/features/events/data/dto/ai_cover_request_dto.dart`
- Campos: `prompt: String`, `draftId: String`; `@JsonSerializable`
- Comentario inline obligatorio:
  ```dart
  // Excepción Pattern B: DTO de request puro — no existe modelo dominio 1:1
  // con campos idénticos que justifique herencia. Ver rideglory-coding-standards.mdc §DTOs.
  ```

**4b. Crear `AiCoverResponseDto`**
- Archivo: `lib/features/events/data/dto/ai_cover_response_dto.dart`
- Campos: `imageUrl: String`, `draftId: String`, `remainingGenerations: int`; `@JsonSerializable`
- Comentario inline obligatorio:
  ```dart
  // Excepción Pattern B: DTO compuesto con campos de control (remainingGenerations, draftId)
  // que no pertenecen al modelo domain AiCoverResult. No extiende modelo domain.
  ```

**4c. Crear `AiCoverService`**
- Archivo: `lib/features/events/data/service/ai_cover_service.dart`
- Retrofit client; `@RestApi()`:
  ```dart
  @POST('/ai/cover')
  Future<AiCoverResponseDto> generateCover(@Body() AiCoverRequestDto request);
  ```

**4d. Crear `AiCoverRepositoryImpl`**
- Archivo: `lib/features/events/data/repository/ai_cover_repository_impl.dart`
- `@Injectable(as: AiCoverRepository)`
- Para el path happy, delegar en `executeService()` de `rest_client_functions.dart`
- Para el mapeo de los 4 errores tipados, envolver la llamada en un `try/catch` directo sobre `DioException` **antes** de llamar a `executeService`, de modo que los errores semánticos de la IA se conviertan en subclases de `DomainException` específicas:

  ```dart
  @override
  Future<Either<DomainException, AiCoverResult>> generateCover(
    AiCoverRequest request,
  ) async {
    try {
      final dto = await _service.generateCover(
        AiCoverRequestDto(prompt: request.prompt, draftId: request.draftId),
      );
      return Right(
        AiCoverResult(
          imageUrl: dto.imageUrl,
          remainingGenerations: dto.remainingGenerations,
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final errorCode = e.response?.data is Map
          ? (e.response!.data as Map<String, dynamic>)['error'] as String?
          : null;

      if (status == 429 && errorCode == 'quota_exceeded_user') {
        return const Left(AiQuotaExceededUserException());
      }
      if (status == 429 && errorCode == 'quota_exceeded_project') {
        return const Left(AiQuotaExceededProjectException());
      }
      if (status == 422 && errorCode == 'safety_blocked') {
        return const Left(AiSafetyBlockedException());
      }
      if (status == 503 && errorCode == 'network_error') {
        return const Left(AiNetworkException());
      }
      // Cualquier otro DioException se mapea con el helper genérico
      return executeService(() async => dto); // re-usa lógica genérica para errores inesperados
    }
  }
  ```

  > **Nota de implementación:** El bloque final `executeService(() async => dto)` es inalcanzable si la variable `dto` no está en scope; en la práctica, para el fallback genérico se debe relanzar la excepción o duplicar el mapeo de `DioException` a `DomainException.unknown` siguiendo el patrón existente en `rest_client_functions.dart`. Elegir la variante más consistente con ese helper en el momento de la implementación; lo importante es que los 4 errores específicos **siempre** se mapean antes del fallback.

  Tabla de mapeo para referencia:

  | HTTP status | campo `error` | `DomainException` subclass |
  |-------------|---------------|---------------------------|
  | 429 | `quota_exceeded_user` | `AiQuotaExceededUserException` |
  | 429 | `quota_exceeded_project` | `AiQuotaExceededProjectException` |
  | 422 | `safety_blocked` | `AiSafetyBlockedException` |
  | 503 | `network_error` | `AiNetworkException` |

---

### Paso 5 — Presentation — cubit

**5a. Crear estado `AiCoverChatState`**
- En `lib/features/events/presentation/form/cubit/ai_cover_chat_cubit.dart`
- `@freezed`:
  ```dart
  @freezed
  abstract class AiCoverChatState with _$AiCoverChatState {
    const factory AiCoverChatState({
      @Default(<AiChatTurn>[]) List<AiChatTurn> history,
      @Default(<String>[]) List<String> generatedUrls,
      @Default(ResultState<AiCoverResult>.initial()) ResultState<AiCoverResult> currentGeneration,
      @Default(0) int remainingQuota,
    }) = _AiCoverChatState;
  }
  ```
- `currentGeneration` tipado como `ResultState<AiCoverResult>` para que el cubit pueda actualizar `remainingQuota` desde el resultado sin acceder directamente al DTO

**5b. Crear `AiCoverChatCubit`**
- `@injectable`; **NO** `@singleton`; **NO** va en el `MultiBlocProvider` de `main.dart`
- Comentario de contrato obligatorio al inicio de la clase:
  ```dart
  // Comunicación con la sección del formulario: al confirmar imagen, el sheet hace
  // Navigator.of(context).pop(selectedImageUrl) como String?.
  // El caller (event_form_content.dart) recibe la URL y llama
  // context.read<FormImageCubit>().setRemoteImageUrl(url).
  // No usar EventFormCubit directamente. No usar estado global.
  ```
- Llama `fetchAndActivate()` de `FirebaseRemoteConfig` en el constructor o al primer `generateCover` para leer `ai_cover_daily_limit`
- Método `generateCover(String prompt)`:
  1. Agrega turno `user` al historial
  2. Emite `currentGeneration: ResultState.loading()`
  3. Llama `GenerateEventCoverUseCase(prompt)` → `Either<DomainException, AiCoverResult>`
  4. En `Right(result)`: agrega burbuja a historial, actualiza `generatedUrls`, actualiza `remainingQuota = result.remainingGenerations`, emite `currentGeneration: ResultState.data(data: result)`
  5. En `Left(AiQuotaExceededUserException)`: `remainingQuota = 0`, emite `currentGeneration: ResultState.error(...)`
  6. En `Left(otro error)`: emite `currentGeneration: ResultState.error(...)` sin cambiar `remainingQuota`

---

### Paso 6 — Presentation — UI bottom sheet

**6a. Crear `AiCoverChatSheet`**
- Archivo: `lib/features/events/presentation/form/widgets/ai_cover_chat_sheet.dart`
- `StatelessWidget`; envuelve un `DraggableScrollableSheet(initialChildSize: 0.65, minChildSize: 0.45, maxChildSize: 0.95)`
- Se monta siempre con `BlocProvider<AiCoverChatCubit>` local (scoped) en el caller

**6b. Crear widgets atómicos (un archivo por widget — regla crítica):**

- `lib/features/events/presentation/form/widgets/ai_cover_image_bubble.dart` — burbuja 16:9 (ancho sheet − 32dp); `CachedNetworkImage`; botón "Usar esta imagen" secondary; ícono expand que navega a `AiCoverFullScreenPage` y retorna `String?`; si el full-screen retorna una URL, el widget la pasa al callback `onUseImage(url)` del sheet parent
- `lib/features/events/presentation/form/widgets/ai_cover_shimmer_bubble.dart` — shimmer 16:9 (`shimmer` package — ya en `pubspec.yaml`) + `LinearProgressIndicator` indeterminado debajo; visible durante `currentGeneration is Loading`
- `lib/features/events/presentation/form/widgets/ai_cover_chat_input.dart` — campo de texto (mínimo 48dp); botón enviar; deshabilitado cuando `currentGeneration is Loading` o `remainingQuota == 0`
- `lib/features/events/presentation/form/widgets/ai_cover_quota_indicator.dart` — "X generaciones restantes hoy" debajo del campo
- Reutilizar `AiChatErrorBanner` de Fase 4 si ya existe; si no, crear `lib/features/events/presentation/form/widgets/ai_cover_error_banner.dart`

**6c. Estados de UI obligatorios:**

| Estado | Comportamiento visual |
|--------|-----------------------|
| `initial` | Placeholder 16:9 con ícono cámara; campo habilitado |
| `currentGeneration is Loading` | `AiCoverShimmerBubble` 16:9 + `LinearProgressIndicator`; campo bloqueado |
| `currentGeneration is Data` | `AiCoverImageBubble` con `CachedNetworkImage`; botón "Usar esta imagen" secondary |
| `error AiQuotaExceededUserException` | Banner rojo; campo deshabilitado; botones "Usar" en burbujas previas siguen activos |
| `error AiQuotaExceededProjectException` | Banner con "Reintentar"; campo habilitado |
| `error AiSafetyBlockedException` | Banner con "Reintentar"; campo habilitado |
| `error AiNetworkException` | Banner con "Reintentar"; campo habilitado |

---

### Paso 7 — Presentation — visor full-screen

**7a. Crear `AiCoverFullScreenPage`**
- Archivo: `lib/features/events/presentation/form/screens/ai_cover_full_screen_page.dart`
- Recibe `imageUrl: String` como parámetro de constructor
- `CachedNetworkImage` a pantalla completa (`BoxFit.cover`)
- Botón X en `SafeArea` top-right: `Navigator.of(context).pop()` sin URL (descartar vista)
- CTA primario en `SafeArea` inferior: `AppButton` ancho completo "Usar esta portada" → `Navigator.of(context).pop(imageUrl)`
- La URL retornada por el `pop` la recibe `AiCoverImageBubble` y la pasa al sheet via `onUseImage`

---

### Paso 8 — Integración en `event_form_content.dart`

Este paso recablea la sección de portada del formulario para usar el nuevo flujo IA en lugar del legacy.

**Eliminar:**
- El `BlocBuilder<EventFormCubit, EventFormState>` externo con `buildWhen: previous.coverGenerationResult != current.coverGenerationResult` (líneas ~95-98 del archivo actual)
- Toda la lógica condicional que mostraba `CoverPreviewWidget` vs `FormImageSection` según `coverGenerationResult`
- El método `_triggerGenerate(BuildContext context)` (líneas ~192-201)
- El import de `CoverPreviewWidget` (ya que el widget se elimina en el paso 10)

**Reemplazar** la sección de portada con un único `BlocBuilder<FormImageCubit, ResultState<FormImageData>>`.
Las etiquetas de los botones usan las keys `ai_cover_generate_button` y `ai_cover_upload_button` definidas en `app_es.arb` (Paso 12) — las mismas keys que referencia el criterio 9:

```dart
BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
  builder: (context, imageState) {
    final imageData = imageState.whenOrNull(data: (d) => d);
    return FormImageSection(
      imageUrl: imageData?.hasLocalImage == true ? null : imageData?.displayImageUrl,
      localImagePath: imageData?.hasLocalImage == true ? imageData?.displayImageUrl : null,
      onPickImage: () => context.read<FormImageCubit>().pickImageFromGallery(),
      onClearTap: imageData?.hasLocalImage == true
          ? context.read<FormImageCubit>().clearLocalImage
          : null,
      title: context.l10n.event_addEventCover,
      hint: context.l10n.event_addEventCoverHint,
      uploadButtonLabel: context.l10n.ai_cover_upload_button,
      showGenerateWithAI: true,
      generateWithAILabel: context.l10n.ai_cover_generate_button,
      onGenerateWithAITap: () async {
        final url = await showModalBottomSheet<String?>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BlocProvider(
            create: (_) => getIt<AiCoverChatCubit>(),
            child: const AiCoverChatSheet(),
          ),
        );
        if (url != null && context.mounted) {
          context.read<FormImageCubit>().setRemoteImageUrl(url);
        }
      },
    );
  },
),
```

Esto elimina por completo la dependencia de `event_form_content.dart` en `EventFormCubit` para la gestión de portada.

---

### Paso 9 — Limpieza de `event_form_view.dart`

Actualizar el `BlocConsumer<EventFormCubit, EventFormState>`:

**`listenWhen`:** quitar la condición `previous.coverGenerationResult != current.coverGenerationResult`; dejar solo:
```dart
listenWhen: (previous, current) => previous.saveResult != current.saveResult,
```

**`listener`:** eliminar el bloque completo de `state.coverGenerationResult.whenOrNull(...)` (líneas ~55-67 del archivo actual). Este listener ya no es necesario porque la URL llega directamente al `FormImageCubit` via `pop` del sheet.

---

### Paso 10 — Retiro legacy Flutter

**10a. Limpiar `event_form_cubit.dart` completamente:**

Eliminar de `EventFormState`:
- Campo `coverGenerationResult: ResultState<String>` y su `@Default`

Eliminar del constructor de `EventFormCubit`:
- Parámetro `GetGenerateCoverUseCase _getGenerateCoverUseCase` (línea ~58 del archivo actual, después línea 49 en la lista de parámetros del constructor)
- El campo privado `final GetGenerateCoverUseCase _getGenerateCoverUseCase;`

Eliminar métodos:
- `generateCover({required String title, required String eventType, required String city})` (líneas ~249-268)
- `resetCoverGeneration()` (líneas ~270-272)

Eliminar import:
- `import 'package:rideglory/features/events/domain/use_cases/get_generate_cover_use_case.dart';` (línea ~16)

**No agregar** ningún método `setCoverUrl()` a `EventFormCubit` — la URL se aplica via `FormImageCubit.setRemoteImageUrl()`.

Tras estos cambios, regenerar `event_form_cubit.freezed.dart` con `dart run build_runner build`.

**10b. Eliminar archivos legacy Flutter completos:**
- `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart`
- `lib/features/events/domain/repository/event_cover_repository.dart`
- `lib/features/events/data/repository/event_cover_repository_impl.dart`
- `lib/features/events/data/service/event_cover_service.dart`
- `lib/features/events/data/service/event_cover_service.g.dart`
- `lib/features/events/data/dto/cover_generation_dto.dart`
- `lib/features/events/data/dto/cover_generation_dto.g.dart`
- `lib/features/events/presentation/form/widgets/cover_preview_widget.dart`

**10c. Modificar `lib/core/http/api_routes.dart`:**
- Eliminar la línea: `static const generateEventCover = '/events/generate-cover';`

**10d. Regenerar DI:**
```bash
dart run build_runner build --delete-conflicting-outputs
```
Verificar que `lib/core/di/injection.config.dart` no tiene referencias a `GetGenerateCoverUseCase`, `EventCoverRepository`, `EventCoverRepositoryImpl`, ni `EventCoverService`.

---

### Paso 11 — Retiro legacy backend (api-gateway)

En el repositorio `rideglory-api`:

**11a. Eliminar servicios huérfanos:**
- Eliminar `api-gateway/src/common/claude.service.ts` completo
- Eliminar `api-gateway/src/common/unsplash.service.ts` completo
- Actualizar barrel `api-gateway/src/common/index.ts` si existe

**11b. Limpiar `events.controller.ts`:**
- Eliminar el handler `@Post('generate-cover')` y su método `generateCover()`
- Eliminar imports: `ClaudeService`, `UnsplashService`, `GenerateCoverDto`
- Eliminar inyecciones del constructor del controller: `private readonly claudeService: ClaudeService`, `private readonly unsplashService: UnsplashService`
- Verificar que no queden imports huérfanos en el archivo; ejecutar lint

**11c. Gestionar `generate-cover.spec.ts` — ANTES de verificar `axios`:**

  Este archivo importa tanto `ClaudeService` como `UnsplashService`, y también puede importar `axios` directamente o via los servicios. Debe gestionarse antes de correr el grep de verificación de `axios`, de lo contrario el grep arrojará hits residuales del spec y la verificación será falsa.

  - Convertir en spec negativo que verifica que `POST /events/generate-cover` devuelve 404; O eliminar completamente si no aporta valor
  - El CI no debe fallar por un spec que importe código eliminado

**11d. Limpiar `package.json`:**
- Eliminar `@anthropic-ai/sdk` de `dependencies` en `api-gateway/package.json`
- Verificar usos de `axios` **después de haber eliminado el spec en 11c**: ejecutar
  ```bash
  grep -r "from 'axios'\|require('axios')" api-gateway/src/ --include="*.ts"
  ```
  Con `UnsplashService` y `generate-cover.spec.ts` ya eliminados, el resultado esperado es cero líneas. Si aparecen hits en otros módulos, no eliminar `axios` del `package.json`.
- Si la verificación es cero: eliminar `axios` de `package.json`
- Ejecutar `npm install` en `api-gateway/` para actualizar `package-lock.json`

**11e. Limpiar variables de entorno:**
- Eliminar de `api-gateway/.env.example`: `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY`
- Documentar en handoff de deploy: eliminar estas variables de EC2 **después** de confirmar que el deploy de Fase 5 es estable

---

### Paso 12 — Strings l10n

Agregar a `lib/l10n/app_es.arb` las claves del flujo de portada IA. Las 4 claves de error de Fase 4 (`ai_error_*`) reutilizarlas si ya existen. Las claves de los botones del selector son exclusivas de esta fase y se agregan aquí:

```json
"ai_cover_placeholder_hint": "Describe la portada que quieres generar",
"ai_cover_use_this_image": "Usar esta imagen",
"ai_cover_use_this_cover": "Usar esta portada",
"ai_cover_generate_button": "Generar con IA",
"ai_cover_upload_button": "Subir imagen",
"ai_cover_remaining_quota": "{count} generaciones restantes hoy",
"@ai_cover_remaining_quota": {
  "placeholders": { "count": { "type": "int" } }
}
```

Las keys `ai_cover_generate_button` / `ai_cover_upload_button` son las mismas que usa el Paso 8 en `context.l10n.ai_cover_generate_button` y `context.l10n.ai_cover_upload_button`. No existe ambigüedad con keys preexistentes: si `event_generateWithAI` existía con valor `"Generar"`, no se modifica; simplemente no se reutiliza en este flujo.

---

### Paso 13 — Generación de código, lint y tests

```bash
# Flutter
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test
```

Resolver todos los errores antes de marcar la fase como completa.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

### Flutter — nuevos

| Ruta | Que cambia |
|------|-----------|
| `lib/features/events/domain/model/ai_chat_turn.dart` | Nuevo modelo `AiChatTurn` + enum `AiChatRole` (pure Dart, sin imports Flutter) — requerido si Fase 4 no fue ejecutada |
| `lib/features/events/domain/model/ai_cover_request.dart` | Nuevo modelo dominio `AiCoverRequest` (`prompt`, `draftId`) — pure Dart |
| `lib/features/events/domain/model/ai_cover_result.dart` | Nuevo modelo dominio `AiCoverResult` (`imageUrl`, `remainingGenerations`) — retorno del use case |
| `lib/features/events/domain/repository/ai_cover_repository.dart` | Nueva interfaz `AiCoverRepository` → `Either<DomainException, AiCoverResult>` |
| `lib/features/events/domain/use_cases/generate_event_cover_use_case.dart` | Nuevo use case; genera `draftId` con `const Uuid().v4()` internamente |
| `lib/features/events/data/dto/ai_cover_request_dto.dart` | Nuevo DTO de request; excepción Pattern B documentada |
| `lib/features/events/data/dto/ai_cover_request_dto.g.dart` | Generado por build_runner |
| `lib/features/events/data/dto/ai_cover_response_dto.dart` | Nuevo DTO de response con `remainingGenerations`; excepción Pattern B documentada |
| `lib/features/events/data/dto/ai_cover_response_dto.g.dart` | Generado por build_runner |
| `lib/features/events/data/service/ai_cover_service.dart` | Nuevo Retrofit client `POST /ai/cover` |
| `lib/features/events/data/service/ai_cover_service.g.dart` | Generado por build_runner |
| `lib/features/events/data/repository/ai_cover_repository_impl.dart` | Implementación con try/catch sobre `DioException` para mapeo de 4 subclases `DomainException`; `@Injectable(as: AiCoverRepository)` |
| `lib/features/events/presentation/form/cubit/ai_cover_chat_cubit.dart` | Nuevo cubit `@injectable` scoped + estado `@freezed`; comentario de contrato de comunicación |
| `lib/features/events/presentation/form/cubit/ai_cover_chat_cubit.freezed.dart` | Generado por build_runner |
| `lib/features/events/presentation/form/widgets/ai_cover_chat_sheet.dart` | Bottom sheet con `DraggableScrollableSheet` + `BlocProvider<AiCoverChatCubit>` local |
| `lib/features/events/presentation/form/widgets/ai_cover_image_bubble.dart` | Burbuja 16:9 con `CachedNetworkImage`, botón "Usar esta imagen" (secondary) e ícono expand |
| `lib/features/events/presentation/form/widgets/ai_cover_shimmer_bubble.dart` | Shimmer 16:9 + `LinearProgressIndicator` indeterminado |
| `lib/features/events/presentation/form/widgets/ai_cover_chat_input.dart` | Campo de texto (≥ 48dp) + botón enviar; se deshabilita en loading y quota=0 |
| `lib/features/events/presentation/form/widgets/ai_cover_quota_indicator.dart` | Texto "X generaciones restantes hoy" |
| `lib/features/events/presentation/form/widgets/ai_cover_error_banner.dart` | Banner inline con mensaje tipado y botón "Reintentar" (o reutilizar `AiChatErrorBanner` de Fase 4) |
| `lib/features/events/presentation/form/screens/ai_cover_full_screen_page.dart` | Visor full-screen; CTA `AppButton` "Usar esta portada" ancho completo + `SafeArea`; botón X top-right |
| `test/features/events/domain/use_cases/generate_event_cover_use_case_test.dart` | Tests unitarios del use case: UUID generado, path `Right(result)`, path `Left(error)` |
| `test/features/events/presentation/form/cubit/ai_cover_chat_cubit_test.dart` | Tests del cubit: estado inicial, `generateCover` → loading → data, los 4 errores tipados |
| `test/features/events/presentation/form/widgets/ai_cover_chat_sheet_test.dart` | Widget tests del sheet: estados, tap "Usar esta imagen", pop con URL |

### Flutter — modificados

| Ruta | Que cambia |
|------|-----------|
| `pubspec.yaml` | Agregar `uuid: ^4.5.1` |
| `lib/l10n/app_es.arb` | Agregar strings del flujo portada IA (ver criterio 9) |
| `lib/core/http/api_routes.dart` | Eliminar constante `generateEventCover` |
| `lib/core/exceptions/domain_exception.dart` | Agregar (o verificar) 4 subclases de `DomainException` para errores IA (si Fase 4 no las creó) |
| `lib/features/events/presentation/form/cubit/event_form_cubit.dart` | Eliminar campo `coverGenerationResult`, métodos `generateCover()`/`resetCoverGeneration()`, inyección `GetGenerateCoverUseCase _getGenerateCoverUseCase` y su import; NO agregar `setCoverUrl()` |
| `lib/features/events/presentation/form/cubit/event_form_cubit.freezed.dart` | Regenerado por build_runner tras limpiar el estado |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Eliminar `BlocBuilder<EventFormCubit>` sobre `coverGenerationResult`; eliminar `CoverPreviewWidget`; eliminar `_triggerGenerate()`; reemplazar sección portada con `BlocBuilder<FormImageCubit>` + `onGenerateWithAITap` que abre el sheet y aplica URL via `FormImageCubit.setRemoteImageUrl(url)`; usar keys `ai_cover_generate_button`/`ai_cover_upload_button` |
| `lib/features/events/presentation/form/widgets/event_form_view.dart` | Eliminar `coverGenerationResult` de `listenWhen`; eliminar bloque `state.coverGenerationResult.whenOrNull(...)` del listener |

### Flutter — eliminados

| Ruta | Razon |
|------|-------|
| `lib/features/events/domain/use_cases/get_generate_cover_use_case.dart` | Reemplazado por `GenerateEventCoverUseCase` (Gemini) |
| `lib/features/events/domain/repository/event_cover_repository.dart` | Reemplazado por `AiCoverRepository` |
| `lib/features/events/data/repository/event_cover_repository_impl.dart` | Reemplazado por `AiCoverRepositoryImpl` |
| `lib/features/events/data/service/event_cover_service.dart` | Reemplazado por `AiCoverService` |
| `lib/features/events/data/service/event_cover_service.g.dart` | Generado eliminado con su fuente |
| `lib/features/events/data/dto/cover_generation_dto.dart` | Reemplazado por `AiCoverResponseDto` |
| `lib/features/events/data/dto/cover_generation_dto.g.dart` | Generado eliminado con su fuente |
| `lib/features/events/presentation/form/widgets/cover_preview_widget.dart` | Eliminado: el nuevo flujo no necesita este widget; la sección usa `FormImageSection` + sheet |

### Backend (rideglory-api) — modificados/eliminados

| Ruta | Que cambia |
|------|-----------|
| `api-gateway/src/events/events.controller.ts` | Eliminar handler `@Post('generate-cover')`, método `generateCover()`, imports de `ClaudeService`/`UnsplashService`/`GenerateCoverDto`, inyecciones del constructor |
| `api-gateway/src/common/claude.service.ts` | Eliminar archivo completo |
| `api-gateway/src/common/unsplash.service.ts` | Eliminar archivo completo |
| `api-gateway/src/events/generate-cover.spec.ts` | Convertir en spec negativo (verifica 404) o eliminar — gestionar **antes** de verificar usos de `axios` |
| `api-gateway/src/events/dto/generate-cover.dto.ts` | Eliminar — solo lo usa el handler eliminado |
| `api-gateway/package.json` | Eliminar `@anthropic-ai/sdk`; eliminar `axios` si grep post-spec confirma cero usos restantes |
| `api-gateway/package-lock.json` | Actualizado tras `npm install` |
| `api-gateway/.env.example` | Eliminar `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY` |

---

## Contratos / API rideglory-api

La Fase 5 Flutter consume el endpoint `POST /ai/cover` implementado en Fase 2:

```
POST /ai/cover
Auth: Bearer (Firebase ID token)
Request:  { "prompt": string, "draftId": string }

Response 200: {
  "imageUrl": string,   // URL pública Firebase Storage (pending/{userId}/{draftId}.jpg)
  "draftId": string,
  "remainingGenerations": number
}
Response 429: { "error": "quota_exceeded_user" | "quota_exceeded_project", "remaining": number }
Response 422: { "error": "safety_blocked", "message": string }
Response 503: { "error": "network_error", "message": string }
```

No se crean endpoints nuevos en esta fase. El endpoint `POST /events/generate-cover` se elimina del backend como parte del retiro legacy atómico (visible en `events.controller.ts`).

---

## Cambios de datos / migraciones

Ninguno. La Fase 5 no introduce ni elimina modelos Prisma, documentos Firestore ni esquemas de base de datos. El retiro de `.env.example` y las variables EC2 (`UNSPLASH_ACCESS_KEY`, `ANTHROPIC_API_KEY`) es configuración de entorno, no migración de datos.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **Botón "Subir imagen" operativo tras refactor.** El flujo de subida manual de imagen funciona exactamente igual que antes de la Fase 5: tap en "Subir imagen" → se abre el picker de galería → `FormImageCubit.pickImageFromGallery()` se invoca. Verificable en widget test que simula el tap y confirma la llamada al método.

2. **Botón "Usar esta imagen" en dos puntos de confirmación.** La burbuja del chat (`AiCoverImageBubble`) muestra el botón secondary "Usar esta imagen" visible. Al abrir el visor full-screen (`AiCoverFullScreenPage`), el CTA primario "Usar esta portada" es un `AppButton` ancho completo con `SafeArea` inferior. Ambos cierran el flujo retornando la URL como `String?`.

3. **`FormImageCubit.setRemoteImageUrl(url)` como único canal de aplicación de portada.** Tras el pop del sheet con una URL, el caller (`event_form_content.dart`) llama `context.read<FormImageCubit>().setRemoteImageUrl(url)`. No existe `EventFormCubit.setCoverUrl()` ni ningún otro mecanismo alternativo. No existe `context.read<EventFormCubit>()` dentro de `AiCoverChatCubit` ni en los widgets del sheet. Verificable por widget test de `event_form_content.dart`: (a) tap "Subir imagen" → `FormImageCubit.pickImageFromGallery()` invocado, sheet de IA no se abre; (b) pop del sheet con URL → `FormImageCubit.setRemoteImageUrl(url)` invocado, `EventFormCubit` no invocado para portada.

4. **Cuatro errores tipados con mensaje y comportamiento correcto.** Los comportamientos se verifican en cubit tests usando mocks que lanzan cada subclase:
   - `AiQuotaExceededUserException`: banner rojo; campo de texto deshabilitado; botones "Usar" en burbujas previas siguen activos.
   - `AiQuotaExceededProjectException`: banner con "Reintentar"; campo habilitado.
   - `AiSafetyBlockedException`: banner con "Reintentar"; campo habilitado.
   - `AiNetworkException`: banner con "Reintentar"; campo habilitado.

5. **Shimmer durante generación.** Al llamar a `generateCover`, la UI muestra `AiCoverShimmerBubble` 16:9 con `LinearProgressIndicator` indeterminado inmediatamente; el campo de entrada queda deshabilitado. Verificable en widget test con cubit mockeado en estado `loading`.

6. **`draftId` generado exclusivamente en el use case.** No existe ninguna llamada a `Uuid().v4()` en `AiCoverChatCubit` ni en ningún widget. Verificable por inspección (grep `Uuid()` en la codebase Flutter: debe aparecer solo en `generate_event_cover_use_case.dart`) y por test unitario del use case que verifica que el `draftId` tiene formato UUID v4.

7. **`event_form_cubit.dart` limpio de referencias legacy.** El archivo no contiene: campo `coverGenerationResult`, métodos `generateCover()`/`resetCoverGeneration()`, inyección `GetGenerateCoverUseCase`, ni su import. `dart analyze` limpio. Verificable por inspección directa y compilación sin errores.

8. **`event_form_view.dart` y `event_form_content.dart` limpios.** `event_form_view.dart` no tiene `coverGenerationResult` en `listenWhen` ni en el listener. `event_form_content.dart` no tiene `BlocBuilder<EventFormCubit>` para el `coverGenerationResult`, no tiene `_triggerGenerate()` ni referencia a `CoverPreviewWidget`. Verificable por `dart analyze` sin imports huérfanos.

9. **Strings l10n completas con keys unívocas.** Los textos del flujo de portada IA están en `app_es.arb` con `context.l10n.<key>` en todos los widgets. Ningún string de UI hardcodeado en Dart. Claves mínimas requeridas (todas exclusivas de esta fase — no dependen de keys preexistentes como `event_generateWithAI`):
   - `ai_cover_placeholder_hint` ("Describe la portada que quieres generar")
   - `ai_cover_use_this_image` ("Usar esta imagen")
   - `ai_cover_use_this_cover` ("Usar esta portada")
   - `ai_cover_generate_button` ("Generar con IA")
   - `ai_cover_upload_button` ("Subir imagen")
   - `ai_cover_remaining_quota` ("{count} generaciones restantes hoy" — parametrizado)
   - Los 4 keys de error reutilizados si ya existen: `ai_error_quota_exceeded_user`, `ai_error_quota_exceeded_project`, `ai_error_safety_blocked`, `ai_error_network`

10. **Endpoint `POST /events/generate-cover` eliminado.** Una llamada HTTP `POST /events/generate-cover` al api-gateway desplegado devuelve 404. Verificable con `curl` o en el spec negativo de `generate-cover.spec.ts`.

11. **Retiro de servicios backend completo y sin imports huérfanos.** `ClaudeService` y `UnsplashService` no existen como archivos en `api-gateway/src/`. Ningún módulo NestJS importa estos servicios ni `@anthropic-ai/sdk`. Verificable con:
    ```bash
    grep -r "ClaudeService\|UnsplashService\|anthropic-ai/sdk\|anthropic" api-gateway/src/ --include="*.ts"
    # Resultado esperado: cero líneas
    ```

12. **`dart analyze` limpio y `flutter test` verde.** Sin nuevos warnings ni errores de lint tras el retiro de código legacy y la adición del nuevo flujo. Ningún import apunta a archivos eliminados.

---

## Pruebas (unitarias/widget/integracion)

### Unitarias (obligatorias)

**`GenerateEventCoverUseCase` — test unitario:**
- `call("mi prompt")` → construye `AiCoverRequest` con `draftId` no vacío que coincide con regex UUID v4 (`[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`)
- Cuando el repositorio retorna `Right(AiCoverResult(imageUrl: 'http://...', remainingGenerations: 5))` → use case retorna `Right` con el mismo `AiCoverResult`
- Cuando el repositorio retorna `Left(AiQuotaExceededUserException())` → use case propaga el `Left`
- Los 4 errores tipados se propagan correctamente: `AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkException`

**`AiCoverChatCubit` — cubit tests:**
- Estado inicial: `history` vacía, `generatedUrls` vacía, `remainingQuota == 0`, `currentGeneration is Initial`
- `generateCover("prompt")` → emite `loading`, luego `data`; `history` crece con turno user y burbuja imagen; `generatedUrls` agrega la URL; `remainingQuota` se actualiza con `result.remainingGenerations`
- `AiQuotaExceededUserException` → `remainingQuota == 0`, `currentGeneration is Error`
- `AiQuotaExceededProjectException` → `currentGeneration is Error`, `remainingQuota` sin cambiar
- `AiSafetyBlockedException` y `AiNetworkException` → mismo comportamiento que `AiQuotaExceededProjectException`

### Widget (obligatorios)

**`AiCoverChatSheet` — widget test:**
- Campo de texto deshabilitado en estado `loading`; `AiCoverShimmerBubble` visible
- En estado `data`, `AiCoverImageBubble` aparece con botón "Usar esta imagen" visible
- Banner de error con texto localizado al recibir cada tipo de `DomainException` tipado
- Tap en "Usar esta imagen" hace `Navigator.pop` con la URL correcta
- Banner de `AiQuotaExceededUserException` no muestra "Reintentar"; otros errores sí

**`event_form_content.dart` — widget test (regresión y nuevo flujo):**
- Tap en "Subir imagen" → `FormImageCubit.pickImageFromGallery()` se invoca; el sheet de IA NO se abre
- Tap en "Generar con IA" → `AiCoverChatSheet` se abre como `ModalBottomSheet`
- Cuando el sheet retorna una URL via `pop` → `FormImageCubit.setRemoteImageUrl(url)` se llama; `EventFormCubit` no se invoca directamente para la portada

### Integración

Los tests del bundle de integración existentes (`integration_test/events_patrol_test.dart`) deben pasar sin regresión tras el retiro del flujo legacy.

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigación |
|----|--------|------|---------|-----------|
| R4 | Latencia imagen Gemini (~10-15 s) — UX percibida de app colgada | Alta | Medio | `AiCoverShimmerBubble` 16:9 + `LinearProgressIndicator` indeterminado obligatorio; campo bloqueado pero el shimmer da feedback inmediato |
| R7 | Retiro legacy rompe referencias en DI (GetIt + injectable) | Media | Alto | Regenerar código con `build_runner build --delete-conflicting-outputs` tras cada eliminación; resolver errores de compilación antes de continuar al siguiente paso |
| R8 | `generate-cover.spec.ts` huérfano falla en CI si no se suprime | Media | Bajo | Gestionar en Paso 11c, **antes** de correr el grep de verificación de `axios`; convertir en spec negativo (verifica 404) o eliminar completamente |
| R9 | `axios` con usos residuales no detectados por el grep | Baja | Bajo | El grep de `axios` se corre **después** de gestionar `generate-cover.spec.ts` (Paso 11c), porque el spec también importa `axios` (vía servicios) y contaminaría el resultado. Con spec eliminado primero, el grep en cero líneas confirma que solo `UnsplashService` lo usaba |
| R10 | `event_form_content.dart` mantiene referencia a `CoverPreviewWidget` eliminado | Media | Medio | El paso 8 es explícito; el `dart analyze` post-retiro detecta el import huérfano inmediatamente |
| R11 | `AiCoverChatCubit` marcado `@singleton` por error | Baja | Alto | El cubit es `@injectable` (transient); instanciado via `getIt<AiCoverChatCubit>()` en el `BlocProvider` local — verificar en `injection.config.dart` generado |
| R12 | Variables de entorno EC2 eliminadas antes del deploy de Fase 5 | Baja | Alto | Eliminar `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY` de EC2 **después** de confirmar que el deploy de Fase 5 es estable; el `.env.example` se actualiza en el PR pero EC2 se actualiza post-validación |
| R13 | `context.mounted` no verificado tras `await showModalBottomSheet` | Media | Bajo | El callback `onGenerateWithAITap` en `event_form_content.dart` debe verificar `context.mounted` antes de llamar `context.read<FormImageCubit>()` |

---

## Dependencias (fases prerequisito y por que)

| Fase | Titulo | Por que es prerequisito |
|------|--------|------------------------|
| Fase 3 | Backend — Sistema de cuotas | El endpoint `POST /ai/cover` devuelve `remainingGenerations` y los 4 errores tipados que esta fase consume. Sin cuotas activas, los errores tipados no se disparan y los criterios 3-4 no son verificables. |
| Fase 4 | App — Asistente de descripción | Define las 4 subclases de `DomainException` (`AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkException`) en `domain_exception.dart` que esta fase reutiliza. Define el modelo `AiChatTurn` / `AiChatRole` en `lib/features/events/domain/model/ai_chat_turn.dart` que el estado `List<AiChatTurn>` del `AiCoverChatCubit` reutiliza — sin este modelo el cubit no compila. Si Fase 4 no fue completada, el implementador debe crear estos artefactos de dominio como parte del Paso 1 de esta fase. |

---

## Ejecucion recomendada (nivel rg-exec: full)

**Por que full es obligatorio:**

1. **Retiro atómico en dos repositorios.** La eliminación del endpoint `POST /events/generate-cover` en `api-gateway` y la eliminación del cliente Flutter (`EventCoverService`, `GetGenerateCoverUseCase`, `EventCoverRepositoryImpl`) deben coordinarse en el mismo deploy. Una regresión parcial — backend eliminado sin Flutter actualizado, o Flutter actualizado sin backend eliminado — rompe el flujo de portada para todos los organizadores.

2. **Mecanismo de aplicación de URL reconciliado con el código real.** El canal `Navigator.of(context).pop(selectedImageUrl)` → `FormImageCubit.setRemoteImageUrl(url)` es exactamente el patrón ya implementado en `event_form_view.dart:57` para el flujo legacy. El auditor Opus debe verificar que no se introduce `EventFormCubit.setCoverUrl()` (inexistente y no necesario) ni ningún otro canal alternativo.

3. **UI nueva de chat con visor full-screen.** Bottom sheet de burbujas-imagen 16:9, shimmer animado, visor full-screen y lógica de confirmación en dos puntos requieren múltiples widgets nuevos, cada uno en su propio archivo (regla crítica). La coordinación entre widgets y cubit es alta; el nivel full garantiza iteración auditor→implementador hasta que todos los criterios pasen.

4. **`draftId` generado en use case — no en cubit.** Requisito explícito de Clean Architecture. El auditor debe verificar que `Uuid().v4()` aparece únicamente en `GenerateEventCoverUseCase`.

5. **Coordina cambios en dos repositorios.** El implementador trabaja simultáneamente en `Rideglory` (Flutter) y `rideglory-api` (NestJS). La sincronización del retiro requiere que ambos repositorios queden en estado coherente antes del deploy.
