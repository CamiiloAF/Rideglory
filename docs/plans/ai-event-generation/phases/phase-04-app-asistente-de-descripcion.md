# Fase 4 — App — Asistente de descripción

**Slug:** ai-event-generation
**Fecha:** 2026-06-05T22:00:09Z
**Nivel rg-exec:** full
**Depende de:** Fase 3

---

## Objetivo

Un organizador puede abrir un chat con un asistente IA desde el formulario de evento, iterar sobre la descripción en lenguaje natural y aplicarla al editor de texto enriquecido con un toque, sin romper ningún flujo existente del formulario.

---

## Alcance (entra / no entra)

### Entra

- Modificación de `AppRichTextEditor` (widget compartido): param `QuillController? externalController` (retrocompatible); el widget NO dispone el controller externo; docstring actualizado (reemplaza "Not implemented yet")
- Conversión de `EventFormBasicInfoSection` de `StatelessWidget` a `StatefulWidget`: crea, inicializa y dispone el `QuillController` externo; lo pasa tanto al editor como al bottom sheet; elimina el param `onAiSuggest` (el section abre el sheet internamente); implementa `_buildEventContext()` con campos reales del FormBuilder
- Modificación de `EventFormContent`: eliminar el callback `onAiSuggest` que abre `InfoDialog 'coming soon'` (líneas 157-163); ya no pasa `onAiSuggest` a `EventFormBasicInfoSection`
- Modelos de dominio puros (sin imports Flutter): `AiChatTurn` + `AiChatRole`, `AiDescriptionResult`, `AiDescriptionRequest`
- 4 subclases tipadas de `DomainException` para errores IA: `AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkErrorException` — en archivo propio `lib/core/exceptions/ai_domain_exceptions.dart`
- Interfaz `AiDescriptionRepository` con retorno `Future<Either<DomainException, AiDescriptionResult>>`
- `GenerateEventDescriptionUseCase` → `Either<DomainException, AiDescriptionResult>`
- `AiDescriptionRepositoryImpl`: captura directa de `DioException` (NO usa `executeService()` — ver Paso 5); Retrofit client `AiDescriptionService` hacia `POST /ai/description`
- DTOs `AiDescriptionRequestDto` / `AiEventContextDto` / `AiDescriptionResponseDto` / `AiChatTurnDto` con `fromDomain` factories; excepción Pattern B documentada con comentario inline
- `MarkdownToDeltaConverter` en `lib/features/events/presentation/utils/` — subconjunto acotado: párrafo, h2, bold, italic, lista sin ordenar; cualquier otro elemento → texto plano sin error
- `AiDescriptionChatCubit` (`@injectable`, scoped al bottom sheet) con estado `@freezed`; cuota inicial desde Remote Config via `fetchAndActivate()`
- UI: `DraggableScrollableSheet` con `ListView` invertida, burbujas, estados idle/loading/data/error tipado/quota=0
- `ConfirmationDialog` si el editor tiene contenido al insertar; inserción directa si está vacío; mecanismo determinista para propagar `onChanged` tras insertar Delta
- Strings de UI en `app_es.arb` (claves `ai_*` de esta fase, incluyendo los 4 keys de error)
- `dart analyze` limpio; `flutter test` pasa al finalizar la fase

### No entra

- Generación de portada IA (Fase 5)
- Analytics / telemetría `ai_*` (Fase 6)
- Actualización de `docs/features/events.md` (Fase 6)
- Retiro de código legacy Unsplash/Claude (Fase 5)

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 0 — Verificar precondición: backend Fases 1-3 desplegado

**Antes de tocar cualquier código Flutter**, verificar que el endpoint `POST /ai/description` existe y el sistema de cuotas (Fase 3) está activo. La verificación es reproducible con el siguiente comando (reemplazar `<API_HOST>` con el host del servidor de staging o `localhost:3000` en local):

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://<API_HOST>/ai/description \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Resultado esperado:** HTTP `401` — el endpoint existe y el guard de autenticación responde.
**Resultado que indica falla:**
- HTTP `404` → el endpoint no existe; backend de Fase 1 no desplegado
- HTTP `503` o ECONNREFUSED → backend caído o no desplegado

Si el resultado no es `401`, **detener e informar al responsable de backend antes de continuar**. No implementar código Flutter dependiente de un contrato no disponible.

---

### Paso 1 — Subclases tipadas de DomainException para errores IA

Crear `lib/core/exceptions/ai_domain_exceptions.dart` con las 4 subclases. Archivo propio (no modificar `domain_exception.dart` con concatenación de clases).

```dart
// lib/core/exceptions/ai_domain_exceptions.dart
//
// Subclases de DomainException para errores específicos de generación IA.
// La UI distingue el tipo con `is` en lugar de comparar strings.
// Los mensajes contienen la clave ARB — el widget lee context.l10n.<key>.

import 'package:rideglory/core/exceptions/domain_exception.dart';

/// HTTP 429 + body { error: 'quota_exceeded_user' }.
/// El usuario agotó su cuota diaria. La UI deshabilita el campo de entrada.
class AiQuotaExceededUserException extends DomainException {
  const AiQuotaExceededUserException()
      : super(message: 'ai_error_quota_exceeded_user');
}

/// HTTP 429 + body { error: 'quota_exceeded_project' }.
/// La cuota del proyecto Gemini está agotada. La UI ofrece "Reintentar".
class AiQuotaExceededProjectException extends DomainException {
  const AiQuotaExceededProjectException()
      : super(message: 'ai_error_quota_exceeded_project');
}

/// HTTP 422 + body { error: 'safety_blocked' }.
/// Gemini rechazó la solicitud por filtro de contenido. La UI ofrece "Reintentar".
class AiSafetyBlockedException extends DomainException {
  const AiSafetyBlockedException()
      : super(message: 'ai_error_safety_blocked');
}

/// HTTP 503 o DioExceptionType.connectionError / timeout.
/// Error de red al llamar a Gemini API. La UI ofrece "Reintentar".
class AiNetworkErrorException extends DomainException {
  const AiNetworkErrorException()
      : super(message: 'ai_error_network');
}
```

---

### Paso 2 — Modelos de dominio (capa domain, cero imports Flutter)

Crear en `lib/features/events/domain/model/`:

**`ai_chat_turn.dart`**
```dart
enum AiChatRole { user, model }

class AiChatTurn {
  const AiChatTurn({required this.role, required this.content});
  final AiChatRole role;
  final String content;
}
```

**`ai_description_result.dart`** — fuente de verdad del cubit para la cuota post-primer-turno; el cubit lee `remainingGenerations` de este objeto, nunca accede al repositorio directamente para leer la cuota.
```dart
/// Resultado de una generación de descripción IA.
/// [remainingGenerations] es la fuente de verdad del cubit para
/// actualizar [AiDescriptionChatState.remainingQuota] a partir del
/// segundo turno; el primer turno usa Firebase Remote Config.
class AiDescriptionResult {
  const AiDescriptionResult({
    required this.markdown,
    required this.remainingGenerations,
  });
  final String markdown;
  final int remainingGenerations;
}
```

**`ai_description_request.dart`**
```dart
class AiDescriptionRequest {
  const AiDescriptionRequest({
    required this.eventContext,
    required this.history,
  });
  /// Contexto del evento para el prompt: title, eventType, city, audience?
  final Map<String, dynamic> eventContext;
  /// Máximo 10 turnos — el use case recorta antes de enviar.
  final List<AiChatTurn> history;
}
```

---

### Paso 3 — Interfaz de repositorio y use case

**`lib/features/events/domain/repository/ai_description_repository.dart`**
```dart
abstract interface class AiDescriptionRepository {
  /// Genera descripción de evento vía Gemini.
  ///
  /// Retorna [AiDescriptionResult] con el Markdown generado y
  /// [remainingGenerations] actualizado desde el backend.
  ///
  /// Errores tipados mapeados (ver [AiDescriptionRepositoryImpl._mapDioException]):
  /// - [AiQuotaExceededUserException]    HTTP 429, error: 'quota_exceeded_user'
  /// - [AiQuotaExceededProjectException] HTTP 429, error: 'quota_exceeded_project'
  /// - [AiSafetyBlockedException]        HTTP 422, error: 'safety_blocked'
  /// - [AiNetworkErrorException]         HTTP 503 o timeout de red
  Future<Either<DomainException, AiDescriptionResult>> generateDescription(
    AiDescriptionRequest request,
  );
}
```

**`lib/features/events/domain/use_cases/generate_event_description_use_case.dart`**
```dart
@injectable
class GenerateEventDescriptionUseCase {
  const GenerateEventDescriptionUseCase(this._repository);
  final AiDescriptionRepository _repository;

  Future<Either<DomainException, AiDescriptionResult>> call(
    AiDescriptionRequest request,
  ) {
    // Recortar historial a los últimos 10 turnos en el cliente para no
    // exceder la ventana de contexto de Gemini.
    final trimmed = request.history.length > 10
        ? request.history.sublist(request.history.length - 10)
        : request.history;
    return _repository.generateDescription(
      AiDescriptionRequest(
        eventContext: request.eventContext,
        history: trimmed,
      ),
    );
  }
}
```

---

### Paso 4 — DTOs y Retrofit service (capa data)

**`lib/features/events/data/dto/ai_chat_turn_dto.dart`**
```dart
// Excepción Pattern B: DTO de serialización sin modelo domain 1:1.
// AiChatTurn es el modelo domain; este DTO solo existe para JSON.
@JsonSerializable()
class AiChatTurnDto {
  const AiChatTurnDto({required this.role, required this.content});

  @JsonKey(name: 'role')
  final String role;   // 'user' | 'model'

  @JsonKey(name: 'content')
  final String content;

  factory AiChatTurnDto.fromJson(Map<String, dynamic> json) =>
      _$AiChatTurnDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiChatTurnDtoToJson(this);

  /// Convierte el modelo domain al DTO de serialización.
  factory AiChatTurnDto.fromDomain(AiChatTurn turn) => AiChatTurnDto(
        role: turn.role.name,   // AiChatRole.user → 'user'; AiChatRole.model → 'model'
        content: turn.content,
      );
}
```

**`lib/features/events/data/dto/ai_event_context_dto.dart`**
```dart
// Excepción Pattern B: DTO auxiliar sin modelo domain 1:1. Es un sub-objeto
// de AiDescriptionRequestDto que lleva el contexto del evento al backend.
// El campo audience siempre se envía null desde el cliente Flutter — no existe
// campo EventFormFields.audience; se reserva para uso futuro del backend.
@JsonSerializable(includeIfNull: false)
class AiEventContextDto {
  const AiEventContextDto({
    required this.title,
    required this.eventType,
    required this.city,
    this.audience,
  });

  final String title;
  final String eventType;
  final String city;
  final String? audience;   // null siempre en v1; no existe en EventFormFields

  factory AiEventContextDto.fromJson(Map<String, dynamic> json) =>
      _$AiEventContextDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiEventContextDtoToJson(this);
}
```

**`lib/features/events/data/dto/ai_description_request_dto.dart`**
```dart
// Excepción Pattern B: DTO de request-only compuesto; no extiende modelo domain.
// La serialización de List<AiChatTurn> → List<AiChatTurnDto> se realiza aquí,
// en el factory fromDomain, no en el use case ni en el repositorio.
@JsonSerializable()
class AiDescriptionRequestDto {
  const AiDescriptionRequestDto({
    required this.eventContext,
    required this.history,
  });

  final AiEventContextDto eventContext;
  final List<AiChatTurnDto> history;

  factory AiDescriptionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AiDescriptionRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AiDescriptionRequestDtoToJson(this);

  /// Convierte el modelo domain [AiDescriptionRequest] al DTO de request.
  /// Lee eventContext como Map<String, dynamic> y extrae los campos definidos.
  /// El campo audience no existe en EventFormFields y se pasa siempre como null.
  factory AiDescriptionRequestDto.fromDomain(AiDescriptionRequest request) {
    final ctx = request.eventContext;
    return AiDescriptionRequestDto(
      eventContext: AiEventContextDto(
        title: ctx['title'] as String? ?? '',
        eventType: ctx['eventType'] as String? ?? '',
        city: ctx['city'] as String? ?? '',
        audience: null,   // no existe EventFormFields.audience en v1
      ),
      history: request.history
          .map(AiChatTurnDto.fromDomain)
          .toList(),
    );
  }
}
```

**`lib/features/events/data/dto/ai_description_response_dto.dart`**
```dart
// Excepción Pattern B: DTO compuesto con campo de control (remainingGenerations)
// que no pertenece al modelo domain AiChatTurn. No extiende modelo domain.
@JsonSerializable()
class AiDescriptionResponseDto {
  const AiDescriptionResponseDto({
    required this.markdown,
    required this.remainingGenerations,
  });

  final String markdown;
  final int remainingGenerations;

  factory AiDescriptionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiDescriptionResponseDtoFromJson(json);
}
```

**`lib/features/events/data/service/ai_description_service.dart`** (Retrofit)
```dart
@RestApi()
abstract class AiDescriptionService {
  factory AiDescriptionService(Dio dio, {String? baseUrl}) =
      _AiDescriptionService;

  @POST('/ai/description')
  Future<AiDescriptionResponseDto> generateDescription(
    @Body() AiDescriptionRequestDto body,
  );
}
```

---

### Paso 5 — AiDescriptionRepositoryImpl con captura directa de DioException

**Decisión arquitectónica crítica y no negociable: este repositorio NO usa `executeService()`.**

`executeService()` → `handlerExceptionHttp()` → `_getDioErrorMessage()` → `_extractResponseMessage()` priorizan el campo `'message'` del body sobre `'error'` y devuelven `DomainException(message: string_de_mensaje)`, perdiendo el `statusCode`. Esto hace imposible distinguir `quota_exceeded_user` (campo deshabilitado) de `quota_exceeded_project` (reintentar), que son comportamientos de UI incompatibles. `_extractResponseMessage` lee `data['error']` solo como fallback de string, nunca como discriminante semántico.

`AiDescriptionRepositoryImpl` captura `DioException` directamente:

**`lib/features/events/data/repository/ai_description_repository_impl.dart`**
```dart
@Injectable(as: AiDescriptionRepository)
class AiDescriptionRepositoryImpl implements AiDescriptionRepository {
  const AiDescriptionRepositoryImpl(this._service);
  final AiDescriptionService _service;

  @override
  Future<Either<DomainException, AiDescriptionResult>> generateDescription(
    AiDescriptionRequest request,
  ) async {
    try {
      final dto = await _service.generateDescription(
        AiDescriptionRequestDto.fromDomain(request),
      );
      return Right(AiDescriptionResult(
        markdown: dto.markdown,
        remainingGenerations: dto.remainingGenerations,
      ));
    } on DioException catch (dioException) {
      return Left(_mapDioException(dioException));
    } catch (e) {
      return Left(
        const DomainException(
          message: 'Error inesperado al generar la descripción.',
        ),
      );
    }
  }

  DomainException _mapDioException(DioException dioException) {
    final statusCode = dioException.response?.statusCode;
    final data = dioException.response?.data;
    final errorCode =
        data is Map<String, dynamic> ? data['error'] as String? : null;

    if (statusCode == 429) {
      if (errorCode == 'quota_exceeded_user') {
        return const AiQuotaExceededUserException();
      }
      // quota_exceeded_project u otro código 429 no esperado
      return const AiQuotaExceededProjectException();
    }
    if (statusCode == 422 && errorCode == 'safety_blocked') {
      return const AiSafetyBlockedException();
    }
    if (statusCode == 503 ||
        dioException.type == DioExceptionType.connectionError ||
        dioException.type == DioExceptionType.connectionTimeout ||
        dioException.type == DioExceptionType.receiveTimeout ||
        dioException.type == DioExceptionType.sendTimeout) {
      return const AiNetworkErrorException();
    }
    // Fallback para errores HTTP no tipados
    return const DomainException(
      message: 'Error al generar la descripción. Intenta de nuevo.',
    );
  }
}
```

---

### Paso 6 — MarkdownToDeltaConverter

Crear `lib/features/events/presentation/utils/markdown_to_delta_converter.dart`.

Clase utilitaria pura, constructor `const`, sin estado, sin imports de BLoC ni de Flutter material. Método principal: `Delta convert(String markdown)`.

**Subconjunto soportado:**

| Markdown | Operación Delta |
|----------|----------------|
| Párrafo ordinario | `insert: texto + '\n'` |
| `## Heading` | `insert: texto + '\n'`, `attributes: {'header': 2}` |
| `**bold**` | `insert: texto`, `attributes: {'bold': true}` |
| `*italic*` o `_italic_` | `insert: texto`, `attributes: {'italic': true}` |
| `- item` | `insert: texto + '\n'`, `attributes: {'list': 'bullet'}` |
| Cualquier otro elemento | `insert: texto_plano + '\n'` — fallback sin error visible |

El Delta resultante siempre termina en `\n` (requisito de flutter_quill).

**Nota R9 (flutter_quill 11.x):** probar en día 1 con un Delta mínimo. Si `Document.fromDelta(convertedDelta)` resulta inestable, usar como alternativa: `Document.fromJson(jsonDecode(jsonEncode(convertedDelta.toJson())))`. Documentar el resultado en los comentarios del implementador.

**Tests unitarios obligatorios** en `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` antes de integrar con el cubit.

---

### Paso 7 — AiDescriptionChatCubit

Crear `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart`.

**Estado `@freezed`:**
```dart
@freezed
abstract class AiDescriptionChatState with _$AiDescriptionChatState {
  const factory AiDescriptionChatState({
    @Default(<AiChatTurn>[]) List<AiChatTurn> history,
    @Default(ResultState<AiDescriptionResult>.initial())
    ResultState<AiDescriptionResult> generationResult,
    @Default(0) int remainingQuota,
    @Default(false) bool quotaInitialized,
  }) = _AiDescriptionChatState;
}
```

**Cubit:**
```dart
@injectable  // NO @singleton, NO @lazySingleton — scoped al bottom sheet
class AiDescriptionChatCubit extends Cubit<AiDescriptionChatState> {
  AiDescriptionChatCubit(
    this._generateDescriptionUseCase,
    this._remoteConfig,
  ) : super(const AiDescriptionChatState());

  final GenerateEventDescriptionUseCase _generateDescriptionUseCase;
  final FirebaseRemoteConfig _remoteConfig;
```

**Inicialización de cuota — alineado con síntesis A1/R6:**

Al abrir el bottom sheet, el caller invoca `initQuota()`:
```dart
/// Inicializa la cuota visible en el chat.
/// Llama fetchAndActivate() para obtener el valor fresco de Remote Config
/// (evita delay de hasta 12h por propagación — ver R6 en plan).
/// El primer turno muestra este valor; los siguientes se actualizan desde
/// AiDescriptionResult.remainingGenerations del response del backend.
Future<void> initQuota() async {
  try {
    await _remoteConfig.fetchAndActivate();
  } catch (_) {
    // fetchAndActivate no debe bloquear la apertura del chat;
    // si falla, usar el valor cacheado o el fallback.
  }
  final limit = _remoteConfig.getInt('ai_description_daily_limit');
  // Si Remote Config retorna 0 (no configurado) o falla, usar fallback conservador.
  final quota = limit > 0 ? limit : 10;
  emit(state.copyWith(remainingQuota: quota, quotaInitialized: true));
}
```

**Método de generación:**
```dart
Future<void> generate({
  required String userMessage,
  required Map<String, dynamic> eventContext,
}) async {
  final userTurn = AiChatTurn(role: AiChatRole.user, content: userMessage);
  final updatedHistory = [...state.history, userTurn];

  emit(state.copyWith(
    history: updatedHistory,
    generationResult: const ResultState.loading(),
  ));

  final result = await _generateDescriptionUseCase(
    AiDescriptionRequest(eventContext: eventContext, history: updatedHistory),
  );

  result.fold(
    (error) => emit(state.copyWith(
      generationResult: ResultState.error(error: error),
    )),
    (data) {
      final modelTurn = AiChatTurn(
        role: AiChatRole.model,
        content: data.markdown,
      );
      emit(state.copyWith(
        history: [...updatedHistory, modelTurn],
        generationResult: ResultState.data(data: data),
        // A partir del segundo turno, la fuente de verdad de la cuota
        // es remainingGenerations del response (no Remote Config).
        remainingQuota: data.remainingGenerations,
      ));
    },
  );
}
```

---

### Paso 8 — Modificar AppRichTextEditor (widget compartido)

Archivo: `lib/shared/widgets/form/app_rich_text_editor.dart`

**Cambios exactos:**

1. Agregar parámetro a la clase widget:
   ```dart
   /// Si se provee, el widget adopta este controller en lugar de crear uno interno.
   /// El OWNER del controller externo es responsable de llamar [QuillController.dispose].
   /// AppRichTextEditor NUNCA dispone un controller externo (_ownsController = false).
   /// Todos los call sites que no pasan este param siguen funcionando sin cambios.
   final QuillController? externalController;
   ```

2. Actualizar el docstring de `onAiSuggest` (línea 18). Reemplazar el texto actual "Not implemented yet" por:
   ```dart
   /// When set, the "IA" toolbar button opens the AI description assistant
   /// bottom sheet. The callback is responsible for opening the sheet and
   /// passing the [externalController] so the sheet can inject generated
   /// content into the editor.
   final VoidCallback? onAiSuggest;
   ```

3. Agregar campo al estado: `late bool _ownsController;`

4. Modificar `initState()`:
   ```dart
   @override
   void initState() {
     super.initState();
     _ownsController = widget.externalController == null;
     _controller = widget.externalController ?? _initializeController();
     _controller.addListener(() {
       final jsonContent = _getJsonContent();
       widget.onChanged?.call(jsonContent);
     });
   }
   ```

5. Modificar `dispose()`:
   ```dart
   @override
   void dispose() {
     // Solo disponer el controller si este widget lo creó internamente.
     // Un controller externo es propiedad del caller y él lo dispone.
     if (_ownsController) _controller.dispose();
     _focusNode.dispose();
     super.dispose();
   }
   ```

6. Agregar `externalController` al constructor `const AppRichTextEditor({...})`.

**Verificación de blast radius previa:** ejecutar `grep -rn "AppRichTextEditor" lib/` para confirmar que el único call site es `event_form_basic_info_section.dart`. Si hay call sites adicionales, ninguno de ellos pasa `externalController` → retrocompatibilidad garantizada por el valor `null` por defecto.

---

### Paso 9 — Convertir EventFormBasicInfoSection a StatefulWidget; eliminar onAiSuggest como parámetro

Archivo: `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart`

El widget actualmente es `StatelessWidget` con parámetro `onAiSuggest: VoidCallback?`. En esta fase se convierte a `StatefulWidget` y se elimina el parámetro `onAiSuggest` — la sección abre el sheet internamente. El parent (`EventFormContent`) ya no necesita pasar el callback.

**Contrato de ownership del controller:**
- `EventFormBasicInfoSection.State` crea el controller en `initState()` — es el **único owner**
- `EventFormBasicInfoSection.State` lo dispone en `dispose()` — única llamada a `dispose()`
- `AppRichTextEditor` lo usa pero NO lo dispone (`_ownsController = false`)
- El bottom sheet `AiDescriptionChatSheet` lo recibe como parámetro de constructor y NO lo dispone

**initState — inicialización con descriptionInitialValue:**
```dart
late QuillController _quillController;

@override
void initState() {
  super.initState();
  _quillController = _buildController(widget.descriptionInitialValue);
}

QuillController _buildController(String? initialValue) {
  if (initialValue != null && initialValue.isNotEmpty) {
    try {
      final doc = Document.fromJson(jsonDecode(initialValue));
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      // Fallback: documento vacío si el JSON es inválido
    }
  }
  return QuillController.basic();
}
```

**dispose:**
```dart
@override
void dispose() {
  _quillController.dispose();
  super.dispose();
}
```

**`_buildEventContext()` — lectura de campos del FormBuilder:**

El método se invoca al abrir el sheet (desde el `onAiSuggest` interno del `build`). Lee los campos del mismo `FormBuilder` en el que vive `EventFormBasicInfoSection` — el `FormBuilder` root lo gestiona `EventFormContent` y el `BuildContext` de `State.build()` tiene acceso.

```dart
Map<String, dynamic> _buildEventContext(BuildContext context) {
  // FormBuilder.of(context) accede al FormBuilder root de EventFormContent.
  // EventFormBasicInfoSection vive dentro de ese árbol, por lo que
  // FormBuilder.of(context) no es null en build().
  //
  // EventFormFields.eventType vive en EventFormEventTypeSection (hermana de
  // EventFormBasicInfoSection), pero ambas comparten el mismo FormBuilder
  // root → el campo es accesible desde cualquier descendiente del FormBuilder.
  final formState = FormBuilder.of(context);

  final title =
      formState?.fields[EventFormFields.name]?.value as String? ?? '';

  final eventType =
      (formState?.fields[EventFormFields.eventType]?.value as EventType?)
          ?.name ??
      '';

  final city =
      formState?.fields[EventFormFields.city]?.value as String? ?? '';

  // No existe EventFormFields.audience — siempre null en v1.
  // El campo se reserva para uso futuro del backend sin impacto en UI.
  const String? audience = null;

  return {
    'title': title,
    'eventType': eventType,
    'city': city,
    if (audience != null) 'audience': audience,
  };
}
```

**Momento de lectura:** `_buildEventContext(context)` se llama dentro del callback que abre el sheet, es decir, cuando el usuario toca el botón "IA". En ese momento el `FormBuilder` tiene los valores actuales — no es necesario guardar un snapshot previo.

**build:** pasar `externalController: _quillController` a `AppRichTextEditor`. El botón IA abre el sheet pasando el controller y el contexto:
```dart
AppRichTextEditor(
  name: EventFormFields.description,
  externalController: _quillController,
  onAiSuggest: () {
    final eventContext = _buildEventContext(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (ctx) => getIt<AiDescriptionChatCubit>()..initQuota(),
        child: AiDescriptionChatSheet(
          quillController: _quillController,
          eventContext: eventContext,
        ),
      ),
    );
  },
  // ... resto de parámetros sin cambios
)
```

---

### Paso 10 — Modificar EventFormContent: eliminar callback coming soon

Archivo: `lib/features/events/presentation/form/widgets/event_form_content.dart`

**Cambio concreto (líneas 154-164 del archivo actual):**

Reemplazar el bloque que pasa `onAiSuggest` con `InfoDialog.show(...)`:
```dart
// ANTES (eliminar)
EventFormBasicInfoSection(
  isEditing: cubit.isEditing,
  descriptionInitialValue: cubit.editingEvent?.description,
  onAiSuggest: () {
    InfoDialog.show(
      context: context,
      title: context.l10n.event_generateWithAI,
      content: context.l10n.event_comingSoon,
    );
  },
),

// DESPUÉS (reemplazar por)
EventFormBasicInfoSection(
  isEditing: cubit.isEditing,
  descriptionInitialValue: cubit.editingEvent?.description,
  // onAiSuggest eliminado: EventFormBasicInfoSection gestiona la
  // apertura del sheet internamente a partir de Fase 4.
),
```

Si `event_coming_soon` o el string "Próximamente" queda sin uso tras este cambio, verificar con `grep -rn "event_comingSoon" lib/` y eliminar la clave de `app_es.arb` solo si no hay otros usos.

---

### Paso 11 — UI: AiDescriptionChatSheet y widgets atómicos

Crear `lib/features/events/presentation/form/widgets/ai_description_chat_sheet.dart`.

Estructura de la jerarquía (un widget por archivo — regla crítica):
- `AiDescriptionChatSheet` — `DraggableScrollableSheet(initialChildSize: 0.65, minChildSize: 0.45, maxChildSize: 0.95)` con `BlocBuilder`
- `AiChatBubbleUser` — burbuja del usuario (alineada a la derecha)
- `AiChatBubbleModel` — burbuja del asistente con texto Markdown renderizado como texto enriquecido o texto plano
- `AiChatLoadingBubble` — animación tres puntos durante generación
- `AiChatInputField` — campo de texto ≥ 48dp de altura de toque + botón enviar
- `AiChatErrorBanner` — banner inline con mensaje localizado + botón "Reintentar" (solo cuando el error es recuperable)
- `AiChatQuotaIndicator` — texto debajo del campo: "X generaciones restantes hoy"
- `AiChatInsertButton` — `AppButton` primary ancho completo "Insertar en descripción"

**Estados visuales obligatorios:**

| Estado `generationResult` | Visual |
|---------------------------|--------|
| `initial` (idle) | Burbuja de bienvenida fija; campo habilitado; sin botón insertar |
| `loading` | `AiChatLoadingBubble` al final de la lista; campo bloqueado; botón enviar deshabilitado |
| `data` | Burbujas normales; `AiChatInsertButton` visible |
| `error` con `AiQuotaExceededUserException` | `AiChatErrorBanner` sin botón "Reintentar"; campo deshabilitado permanentemente |
| `error` con otros tipos | `AiChatErrorBanner` con botón "Reintentar"; campo habilitado |

**Flujo de inserción del Delta — mecanismo determinista para propagar `onChanged`:**

1. Usuario toca "Insertar en descripción"
2. Leer `markdown` del estado (`generationResult.data!.markdown`)
3. Convertir: `final delta = const MarkdownToDeltaConverter().convert(markdown)`
4. Si `quillController.document.length > 1` (tiene contenido previo): mostrar `ConfirmationDialog` existente de `lib/shared/widgets/modals/`
   - Si confirma: continuar
   - Si cancela: retornar sin acción
5. Reemplazar el contenido del documento:
   ```dart
   quillController.document = Document.fromDelta(delta);
   ```
6. **Propagar `onChanged` de forma determinista:** el setter `document =` en flutter_quill 11.x no garantiza disparar el `addListener` del widget. Para asegurar que `AppRichTextEditor.onChanged` propague el nuevo JSON al `EventFormCubit`, invocar `updateSelection` inmediatamente después del setter — `updateSelection` sí llama `notifyListeners()` internamente:
   ```dart
   quillController.document = Document.fromDelta(delta);
   quillController.updateSelection(
     const TextSelection.collapsed(offset: 0),
     ChangeSource.local,
   );
   // El listener en AppRichTextEditor._initState() recibe la notificación,
   // llama _getJsonContent() y dispara widget.onChanged → field.didChange en
   // EventFormBasicInfoSection → EventFormCubit recibe el JSON actualizado.
   ```
   Si R9 aplica y se usa `Document.fromJson(...)` como alternativa, el mismo patrón con `updateSelection` se aplica tras setear el documento.
7. Cerrar el sheet: `Navigator.of(context).pop()`

---

### Paso 12 — Strings en app_es.arb

Agregar en `lib/l10n/app_es.arb`:

```json
"ai_chat_welcome_description": "Hola, soy tu asistente IA. Cuéntame sobre el evento y te ayudo a redactar la descripción.",
"ai_chat_input_hint": "Escribe tu mensaje...",
"ai_chat_send": "Enviar",
"ai_chat_insert_description": "Insertar en descripción",
"ai_chat_quota_remaining": "{count} generaciones restantes hoy",
"@ai_chat_quota_remaining": {
  "placeholders": {
    "count": {"type": "int"}
  }
},
"ai_chat_confirm_replace_title": "¿Reemplazar descripción?",
"ai_chat_confirm_replace_body": "El editor ya tiene contenido. ¿Quieres reemplazarlo con la sugerencia de la IA?",
"ai_error_quota_exceeded_user": "Has alcanzado tu límite diario de generaciones. Vuelve mañana.",
"ai_error_quota_exceeded_project": "El servicio de IA está temporalmente saturado. Inténtalo más tarde.",
"ai_error_safety_blocked": "Tu solicitud fue bloqueada por el filtro de contenido. Intenta reformular.",
"ai_error_network": "Error de conexión. Verifica tu internet e intenta de nuevo."
```

Ejecutar `dart run build_runner build --delete-conflicting-outputs` tras modificar el ARB para regenerar las localizaciones.

---

### Paso 13 — Registrar en DI y regenerar código

1. `AiDescriptionService`: registrar en `lib/core/di/firebase_module.dart` o en un módulo propio `AiModule` con `@module`; inyectar `Dio` del contenedor
2. `AiDescriptionRepositoryImpl`: marcado `@Injectable(as: AiDescriptionRepository)` — el generador lo registra automáticamente
3. `GenerateEventDescriptionUseCase`: marcado `@injectable`
4. `AiDescriptionChatCubit`: marcado `@injectable` (transient); instanciado con `BlocProvider(create: (ctx) => getIt<AiDescriptionChatCubit>()..initQuota())` en el sheet

```bash
dart run build_runner build --delete-conflicting-outputs
```

Verificar en `lib/core/di/injection.config.dart` generado que `AiDescriptionChatCubit` NO aparece como singleton.

---

### Paso 14 — Verificación final

```bash
dart analyze
flutter test
```

Cero errores de análisis. Todos los tests nuevos y existentes pasan.

---

## Archivos a crear/modificar (rutas reales)

### Crear

| Ruta | Qué cambia |
|------|-----------|
| `lib/core/exceptions/ai_domain_exceptions.dart` | 4 subclases tipadas de `DomainException` para errores IA |
| `lib/features/events/domain/model/ai_chat_turn.dart` | Modelo puro: `AiChatRole` enum + `AiChatTurn` |
| `lib/features/events/domain/model/ai_description_result.dart` | Modelo puro: `markdown` + `remainingGenerations`; fuente de verdad del cubit para cuota |
| `lib/features/events/domain/model/ai_description_request.dart` | Modelo puro: `eventContext` + `history` |
| `lib/features/events/domain/repository/ai_description_repository.dart` | Interfaz con retorno `Future<Either<DomainException, AiDescriptionResult>>` |
| `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` | Use case; recorta historial a 10 turnos |
| `lib/features/events/data/dto/ai_chat_turn_dto.dart` | DTO `@JsonSerializable`; factory `fromDomain(AiChatTurn)`; excepción Pattern B documentada |
| `lib/features/events/data/dto/ai_event_context_dto.dart` | DTO sub-objeto con `title/eventType/city/audience?`; audience siempre null en v1 |
| `lib/features/events/data/dto/ai_description_request_dto.dart` | DTO request con factory `fromDomain(AiDescriptionRequest)` que mapea `List<AiChatTurn>→List<AiChatTurnDto>`; excepción Pattern B documentada |
| `lib/features/events/data/dto/ai_description_response_dto.dart` | DTO response con `markdown` y `remainingGenerations`; excepción Pattern B documentada |
| `lib/features/events/data/service/ai_description_service.dart` | Retrofit client `POST /ai/description` |
| `lib/features/events/data/repository/ai_description_repository_impl.dart` | Impl con captura directa de `DioException`; NO usa `executeService()`; `@Injectable(as: AiDescriptionRepository)` |
| `lib/features/events/presentation/utils/markdown_to_delta_converter.dart` | Conversor Markdown → Quill Delta; subconjunto acotado; fallback texto plano |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | Cubit `@injectable` + estado `@freezed`; cuota inicial desde Remote Config |
| `lib/features/events/presentation/form/widgets/ai_description_chat_sheet.dart` | `DraggableScrollableSheet` con `BlocProvider<AiDescriptionChatCubit>` scoped |
| `lib/features/events/presentation/form/widgets/ai_chat_bubble_user.dart` | Burbuja del usuario |
| `lib/features/events/presentation/form/widgets/ai_chat_bubble_model.dart` | Burbuja del asistente |
| `lib/features/events/presentation/form/widgets/ai_chat_loading_bubble.dart` | Animación tres puntos |
| `lib/features/events/presentation/form/widgets/ai_chat_input_field.dart` | Campo de texto + botón enviar |
| `lib/features/events/presentation/form/widgets/ai_chat_error_banner.dart` | Banner de error inline con botón "Reintentar" condicional |
| `lib/features/events/presentation/form/widgets/ai_chat_quota_indicator.dart` | Contador "X generaciones restantes hoy" |
| `lib/features/events/presentation/form/widgets/ai_chat_insert_button.dart` | `AppButton` primary "Insertar en descripción" |
| `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` | Tests unitarios del conversor (obligatorios antes de integrar) |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | Tests del cubit (estados, errores, cuota, historial) |
| `test/shared/widgets/form/app_rich_text_editor_external_controller_test.dart` | Tests de controller externo y no-double-dispose |
| `test/features/events/data/repository/ai_description_repository_impl_test.dart` | Tests de mapeo DioException → subclase tipada (4 criterios testeables) |

### Modificar

| Ruta | Qué cambia |
|------|-----------|
| `lib/shared/widgets/form/app_rich_text_editor.dart` | Agregar `QuillController? externalController`; flag `_ownsController`; dispose condicional; docstring de `onAiSuggest` actualizado (reemplaza "Not implemented yet") |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | `StatelessWidget` → `StatefulWidget`; eliminar param `onAiSuggest`; crear y disponer `QuillController` externo; implementar `_buildEventContext()` con campos reales de `FormBuilder`; abrir sheet internamente |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | Eliminar bloque `onAiSuggest: () { InfoDialog.show(...coming soon...) }` (líneas 157-163); ya no pasa `onAiSuggest` a `EventFormBasicInfoSection` |
| `lib/l10n/app_es.arb` | Agregar ~12 claves `ai_*` (chat y errores) |

### Regenerar (build_runner)

| Archivo generado | Por qué |
|-----------------|---------|
| `lib/features/events/data/dto/ai_chat_turn_dto.g.dart` | `@JsonSerializable` nuevo |
| `lib/features/events/data/dto/ai_event_context_dto.g.dart` | `@JsonSerializable` nuevo |
| `lib/features/events/data/dto/ai_description_request_dto.g.dart` | `@JsonSerializable` nuevo |
| `lib/features/events/data/dto/ai_description_response_dto.g.dart` | `@JsonSerializable` nuevo |
| `lib/features/events/data/service/ai_description_service.g.dart` | Retrofit nuevo |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.freezed.dart` | `@freezed` nuevo |
| `lib/core/di/injection.config.dart` | Nuevos `@injectable` registrados |
| `lib/l10n/app_localizations_es.dart` | Nuevas claves ARB |

---

## Contratos / API rideglory-api

```
POST /ai/description
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

Request Body:
{
  "eventContext": {
    "title": "string",          // EventFormFields.name al abrir el sheet
    "eventType": "string",      // EventType.name (e.g. "tourism", "sport")
    "city": "string",           // EventFormFields.city al abrir el sheet
    "audience": null            // siempre null en v1; no existe en EventFormFields
  },
  "history": [
    { "role": "user" | "model", "content": "string" }
  ]
}

Response 200:
{
  "markdown": "string",
  "remainingGenerations": number   ← fuente de verdad del cubit a partir del segundo turno
}

Response 429 (quota_exceeded_user):
{ "error": "quota_exceeded_user", "remaining": 0 }
→ AiQuotaExceededUserException → campo deshabilitado, sin Reintentar

Response 429 (quota_exceeded_project):
{ "error": "quota_exceeded_project" }
→ AiQuotaExceededProjectException → banner + Reintentar

Response 422:
{ "error": "safety_blocked", "message": "string" }
→ AiSafetyBlockedException → banner + Reintentar

Response 503:
{ "error": "network_error", "message": "string" }
→ AiNetworkErrorException → banner + Reintentar
```

---

## Cambios de datos / migraciones

Ninguno. Esta fase es puramente Flutter. No toca base de datos ni Firestore directamente. La cuota en Firestore la gestiona el backend (Fase 3).

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Markdown→Delta — subconjunto completo:** dado `## Título\n**negrita** *cursiva*\n- ítem`, el `MarkdownToDeltaConverter` produce un Delta con atributos `{header: 2}`, `{bold: true}`, `{italic: true}` y `{list: bullet}`. Verificable con unit test.

2. **Markdown→Delta — fallback sin error:** dado `> blockquote` o `~~tachado~~`, el conversor inserta texto plano sin lanzar excepción. Verificable con unit test.

3. **Inserción en editor — Delta visible:** al tocar "Insertar en descripción", el documento del `QuillController` externo refleja el contenido del Delta convertido y el `QuillEditor` lo muestra correctamente. Verificable con widget test que inspecciona `quillController.document`.

4. **Inserción en editor — onChanged propagado de forma determinista:** tras insertar el Delta mediante `document = Document.fromDelta(delta)` seguido de `updateSelection(TextSelection.collapsed(offset: 0), ChangeSource.local)`, el callback `onChanged` de `AppRichTextEditor` es invocado con el nuevo JSON del documento. Verificable con widget test que espía `onChanged` y confirma que es llamado con contenido no vacío tras la secuencia `document = / updateSelection`.

5. **Retrocompatibilidad de AppRichTextEditor:** el call site existente en `event_form_basic_info_section.dart` compila sin cambios una vez convertido a `StatefulWidget` y funciona idéntico al comportamiento anterior. `dart analyze` limpio. Verificable con test de widget con `externalController: null`.

6. **Sin double dispose del QuillController externo:** `AppRichTextEditor._ownsController == false` cuando se provee `externalController`; `dispose()` del widget no llama `_controller.dispose()`. El controller se dispone exactamente una vez en `EventFormBasicInfoSection.State.dispose()`. Verificable con widget test que usa un `MockQuillController` con contador de llamadas a `dispose()`.

7. **Confirmación al reemplazar contenido:** si el editor tiene contenido al tocar "Insertar", aparece `ConfirmationDialog` y la inserción solo ocurre si el usuario confirma. Verificable con widget test del sheet.

8. **Inserción directa en editor vacío:** si el editor no tiene contenido (`document.length <= 1`), "Insertar" aplica el Delta sin mostrar `ConfirmationDialog`. Verificable con widget test.

9. **Mapeo tipado — quota_exceeded_user:** un mock que lanza `DioException` con `response.statusCode: 429` y `response.data: {'error': 'quota_exceeded_user'}` produce `Left(AiQuotaExceededUserException())`. Unit test en `ai_description_repository_impl_test.dart`.

10. **Mapeo tipado — quota_exceeded_project:** un mock que lanza `DioException` con `response.statusCode: 429` y `response.data: {'error': 'quota_exceeded_project'}` produce `Left(AiQuotaExceededProjectException())`. Unit test.

11. **Mapeo tipado — safety_blocked:** un mock que lanza `DioException` con `response.statusCode: 422` y `response.data: {'error': 'safety_blocked'}` produce `Left(AiSafetyBlockedException())`. Unit test.

12. **Mapeo tipado — network_error:** un mock que lanza `DioException` con `response.statusCode: 503` (o `type: DioExceptionType.connectionError`) produce `Left(AiNetworkErrorException())`. Unit test.

13. **Error quota_exceeded_user — campo deshabilitado:** cuando el cubit emite `ResultState.error(error: AiQuotaExceededUserException())`, el campo de texto queda deshabilitado y no aparece botón "Reintentar". Verificable con widget test del sheet.

14. **Errores recuperables — Reintentar:** ante `AiQuotaExceededProjectException`, `AiSafetyBlockedException` o `AiNetworkErrorException`, el banner muestra el mensaje l10n correcto Y el botón "Reintentar" está presente y habilitado. Verificable con widget test para cada uno de los 3 tipos.

15. **Cuota inicial desde Remote Config:** al llamar `initQuota()`, el cubit llama `fetchAndActivate()` en `FirebaseRemoteConfig` y emite `remainingQuota` igual al valor de `ai_description_daily_limit`. Si Remote Config retorna 0, emite 10 como fallback. Verificable con cubit test con mock de `FirebaseRemoteConfig`.

16. **Cuota actualizada desde response:** tras un turno exitoso, `state.remainingQuota == result.remainingGenerations` (no el valor de Remote Config). Verificable con cubit test.

17. **`EventFormContent` sin callback coming soon:** `InfoDialog.show(content: l10n.event_comingSoon)` ya no se invoca desde `EventFormContent` al tocar el botón IA del editor. `dart analyze` limpio.

18. **`_buildEventContext` con campos reales:** el campo `title` del contexto enviado al backend coincide con el valor actual de `EventFormFields.name` en el `FormBuilder`; `eventType` coincide con `EventFormFields.eventType.name`; `city` coincide con `EventFormFields.city`; `audience` es `null`. Verificable con unit test del método o inspección del body enviado al mock de `AiDescriptionService`.

19. **Análisis limpio:** `dart analyze` no reporta warnings ni errores. `flutter test` pasa.

---

## Pruebas

### Unitarias

| Archivo | Casos |
|---------|-------|
| `test/features/events/presentation/utils/markdown_to_delta_converter_test.dart` | Párrafo, h2, bold, italic, bullet list, elemento no soportado (fallback), string vacía, combinación multi-elemento |
| `test/features/events/data/repository/ai_description_repository_impl_test.dart` | Los 4 mapeos DioException → subclase (criterios 9–12); caso success → `AiDescriptionResult`; fallback genérico para código HTTP no tipado |
| `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | Historial de 12 turnos → use case envía 10; delega al repositorio; propaga `Left` y `Right` |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | `initQuota()` con mock de Remote Config (valor normal, valor 0, fallo de red); `generate()` → estados loading→data, loading→error para cada tipo; `remainingQuota` actualizado desde response; crecimiento del historial |

### Widget

| Archivo | Casos |
|---------|-------|
| `test/shared/widgets/form/app_rich_text_editor_external_controller_test.dart` | `_ownsController == false` con controller externo; no double dispose; `onChanged` disparado al ejecutar `document = / updateSelection` desde controller externo |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | Controller creado en `initState()` con `descriptionInitialValue`; controller dispuesto en `dispose()` de State; `externalController` llega al `AppRichTextEditor`; `_buildEventContext` retorna los valores correctos de los campos del FormBuilder |
| `test/features/events/presentation/form/widgets/ai_description_chat_sheet_test.dart` | Todos los estados visuales (idle, loading, data, 4 errores); inserción directa con editor vacío; `ConfirmationDialog` con editor con contenido; banner correcto para cada error tipado; `onChanged` propagado tras inserción (criterio 4) |

### Lint / análisis

```bash
dart analyze
flutter test
```

---

## Riesgos y mitigaciones

| ID | Riesgo | Prob | Impacto | Mitigación |
|----|--------|------|---------|-----------|
| R3 | `MarkdownToDeltaConverter` — edge cases no cubiertos | Media | Medio | Subconjunto acotado (A4 del Plan Reviewer); fallback texto plano sin error; tests unitarios antes de integrar |
| R6 | Propagación Remote Config (delay hasta 12h) | Baja | Bajo | `fetchAndActivate()` al montar el cubit en `initQuota()`; no depender solo del valor cacheado al inicio |
| R7 | Fase subdimensionada (equivale a 2 features medianas) | Media | Medio | Si el sprint es ajustado, dividir en 4a (domain+data+cubit+AppRichTextEditor mod) y 4b (UI bottom sheet+integración); el plan lo permite |
| R9 | `Document.fromDelta()` inestable en flutter_quill 11.x | Baja | Medio | Probar en día 1 con Delta mínimo; alternativa: serializar Delta → JSON → `Document.fromJson()`; `updateSelection` fuerza la notificación en ambos casos |
| R-D1 | Double dispose del QuillController si EventFormBasicInfoSection se reconstruye | Baja | Bajo | Flag `_ownsController` en AppRichTextEditor; dispose exclusivo en `EventFormBasicInfoSection.State` |
| R-D2 | `executeService()` bypassed en repo IA pierde crash reporting automático | Baja | Bajo | `AiDescriptionRepositoryImpl` es el único repo sin `executeService()`; si se desea paridad de observabilidad, loguear en el catch genérico (fuera del scope de esta fase) |
| R-D3 | Remote Config retorna 0 en primer turno (clave no configurada en Firebase Console) | Media | Bajo | Fallback a 10 si `getInt()` retorna 0; el valor correcto llega del backend a partir del primer response |
| R-D4 | `onChanged` no disparado por `document =` en flutter_quill 11.x | Media | Alto | Mitigado por llamada explícita a `updateSelection(TextSelection.collapsed(offset: 0), ChangeSource.local)` inmediatamente después; este método sí llama `notifyListeners()` en QuillController; criterio 4 y su test widget verifican esto de forma determinista |
| R-D5 | `FormBuilder.of(context)` retorna null si `_buildEventContext` se llama fuera del árbol | Baja | Medio | El método se llama solo dentro del callback de `onAiSuggest` en `build()`, donde el `BuildContext` es descendiente del `FormBuilder` root de `EventFormContent`; si llega null (caso defensivo), retorna strings vacíos que el prompt maneja graciosamente |

---

## Dependencias (fases prerequisito y por qué)

**Fase 3 — Backend: Sistema de cuotas** (prerequisito directo y obligatorio)

Esta fase consume directamente:
- El endpoint `POST /ai/description` desplegado en api-gateway (Fase 1)
- El campo `remainingGenerations` en el response 200 (definido en Fase 1 como ajuste A1 del Plan Reviewer)
- Los 4 errores tipados con sus códigos HTTP y campo `error` en el body (implementados en Fase 3)
- El guard de cuota activo que dispara los 429 (implementado en Fase 3)

Sin Fase 3 desplegada, el repositorio no puede mapear errores de cuota y `remainingGenerations` puede estar ausente en el response. El Paso 0 incluye verificación reproducible con `curl` antes de comenzar.

**Fases 1 y 2** son prerequisitos transitivos de Fase 3 y no agregan dependencias adicionales a esta fase.

---

## Ejecución recomendada (nivel rg-exec: full)

**Nivel: `full`**

**Por qué full:** Cross-cutting multi-capa (domain + data + presentation), modificación del widget compartido `AppRichTextEditor` con blast radius en toda la app, cubit `@freezed` complejo con 4 estados de error tipados y cuota inicializada desde Remote Config, `MarkdownToDeltaConverter` manual sin paquete de apoyo para flutter_quill 11.x, UI de chat en bottom sheet con múltiples estados y 8 widgets atómicos, conversión de `EventFormBasicInfoSection` de `StatelessWidget` a `StatefulWidget` con gestión del lifecycle del `QuillController` y lectura explícita del contexto del `FormBuilder`, y eliminación del callback coming soon en `EventFormContent`. Toca el formulario central de creación de eventos. La modificación del widget compartido es especialmente sensible — difícil de revertir parcialmente si introduce regresión. Full justificado.
