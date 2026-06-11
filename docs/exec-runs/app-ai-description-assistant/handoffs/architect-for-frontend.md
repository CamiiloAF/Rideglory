> Slim handoff — read this before docs/exec-runs/app-ai-description-assistant/handoffs/architect.md

# Architect → Frontend

**Slug:** app-ai-description-assistant | **Date:** 2026-06-08T19:10:47Z

---

## Feature path

`lib/features/events/` — domain/model, domain/repository, domain/use_cases, data/dto, data/service, data/repository, presentation/form/cubit, presentation/form/utils, presentation/form/widgets/ai_chat/

## Backend precondición (§7 PRD — verificar PRIMERO)

```bash
curl -X POST http://localhost:3000/api/ai/description \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"eventContext":{"title":"test","eventType":"tourism","city":"Bogotá"},"userMessage":"Hola"}'
# Debe retornar 401. Si retorna 404 o 503, DETENER.
```

---

## Nuevos modelos domain (pure Dart, sin imports Flutter)

```dart
// lib/features/events/domain/model/ai_chat_turn.dart
enum AiChatRole { user, model }
class AiChatTurn { AiChatRole role; String content; }

// lib/features/events/domain/model/ai_description_result.dart
class AiDescriptionResult { String markdown; int remainingGenerations; }

// lib/features/events/domain/model/ai_description_request.dart
class AiDescriptionRequest {
  String title; String eventType; String city;
  String? difficulty; String? startDate;
  List<AiChatTurn> history;  // recortado a 10 turnos en use case
  String userMessage;
}
```

## Core exceptions (`lib/core/exceptions/ai_domain_exceptions.dart`)

```dart
class AiQuotaExceededUserException extends DomainException { ... }
class AiQuotaExceededProjectException extends DomainException { ... }
class AiSafetyBlockedException extends DomainException { ... }
class AiNetworkErrorException extends DomainException { ... }
```

## Retrofit endpoint

```dart
// lib/features/events/data/service/ai_description_service.dart
@RestApi()
abstract class AiDescriptionService {
  @POST('/ai/description')
  Future<AiDescriptionResponseDto> generateDescription(@Body() AiDescriptionRequestDto dto);
}
```

## Repositorio impl — captura DioException DIRECTA (no executeService())

```dart
// En AiDescriptionRepositoryImpl.generateDescription():
try {
  final dto = await _service.generateDescription(requestDto);
  return Right(AiDescriptionResult(markdown: dto.markdown, remainingGenerations: dto.remainingGenerations));
} on DioException catch (e) {
  final errorCode = e.response?.data?['error'] as String?;
  if (e.response?.statusCode == 429 && errorCode == 'quota_exceeded_user')
    return Left(AiQuotaExceededUserException(message: '...'));
  if (e.response?.statusCode == 429 && errorCode == 'quota_exceeded_project')
    return Left(AiQuotaExceededProjectException(message: '...'));
  if (e.response?.statusCode == 422 && errorCode == 'safety_blocked')
    return Left(AiSafetyBlockedException(message: '...'));
  return Left(AiNetworkErrorException(message: '...'));
}
```

## Use case

```dart
// GenerateEventDescriptionUseCase: recorta history a los últimos 10 turnos
final trimmedHistory = request.history.length > 10
    ? request.history.sublist(request.history.length - 10)
    : request.history;
```

## Cubit — transient, @injectable

```dart
@freezed
class AiDescriptionChatState {
  AiDescriptionChatState({
    @Default([]) List<AiChatTurn> history,
    @Default(ResultState.initial()) ResultState<AiDescriptionResult> sendResult,
    @Default(null) int? remainingQuota,
    @Default(false) bool isQuotaInitialized,
  });
}

@injectable  // factory (transient) — NO @singleton
class AiDescriptionChatCubit extends Cubit<AiDescriptionChatState> { ... }
```

`initQuota()`: llama `FirebaseRemoteConfig.instance.fetchAndActivate()` → lee `ai_description_daily_limit`; si 0 → fallback 10.

## AppRichTextEditor — modificación retrocompatible

```dart
// Nuevo param (opcional, default null):
final QuillController? externalController;

// En State.initState():
_ownsController = widget.externalController == null;
_controller = widget.externalController ?? _initializeController();

// En State.dispose():
if (_ownsController) _controller.dispose();
```

**Todos los call sites existentes que no pasan `externalController` funcionan sin cambios.**

## EventFormBasicInfoSection — conversión a StatefulWidget

```dart
class _EventFormBasicInfoSectionState extends State<EventFormBasicInfoSection> {
  late QuillController _quillController;

  @override void initState() {
    super.initState();
    _quillController = ...; // inicializar con descriptionInitialValue
  }

  @override void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  // _buildEventContext() lee FormBuilder.of(context)?.value[EventFormFields.X]
  // audience siempre null (v1)
  AiDescriptionRequest _buildEventContext(String userMessage) { ... }
}
```

La sección abre el sheet con `showModalBottomSheet(context: context, builder: ...)`, pasando `_quillController` al `AiDescriptionChatSheet`.

## EventFormContent — cambio mínimo

Eliminar el bloque:
```dart
onAiSuggest: () {
  InfoDialog.show(context: context, title: ..., content: context.l10n.event_comingSoon);
},
```
Y quitar el parámetro `onAiSuggest` de `EventFormBasicInfoSection`.

## MarkdownToDeltaConverter

Subconjunto soportado: `## H2`, `**bold**`, `*italic*`, `- bullet list`, texto plano.
Cualquier sintaxis no soportada → insertar texto plano sin lanzar excepción.
Advertencia flutter_quill R9: probar `Document.fromDelta(delta)` en día 1; si inestable, usar:
```dart
Document.fromJson(jsonDecode(jsonEncode(convertedDelta.toJson())))
```

## ARB keys (~12 claves con prefijo `ai_`)

```
ai_chatTitle, ai_chatHint, ai_sendButton, ai_insertButton,
ai_quotaRemaining, ai_quotaExhausted,
ai_errorQuotaUser, ai_errorQuotaProject, ai_errorSafetyBlocked, ai_errorNetwork,
ai_retryButton, ai_confirmReplaceTitle, ai_confirmReplaceMessage
```

## DI — 4 nuevos registros

```dart
// En módulo AiModule o directamente en injection.dart:
gh.singleton<AiDescriptionService>(() => AiDescriptionService(gh<Dio>()));
gh.factory<AiDescriptionRepository>(() => AiDescriptionRepositoryImpl(gh<AiDescriptionService>()));
gh.factory<GenerateEventDescriptionUseCase>(() => GenerateEventDescriptionUseCase(gh<AiDescriptionRepository>()));
gh.factory<AiDescriptionChatCubit>(() => AiDescriptionChatCubit(gh<GenerateEventDescriptionUseCase>(), gh<FirebaseRemoteConfig>()));
```

Ejecutar: `dart run build_runner build --delete-conflicting-outputs`

## Widgets del sheet (1 widget por archivo — regla crítica)

Archivos en `lib/features/events/presentation/form/widgets/ai_chat/`:
`ai_description_chat_sheet.dart`, `ai_chat_bubble.dart`, `ai_chat_input_row.dart`,
`ai_chat_loading_indicator.dart`, `ai_chat_error_banner.dart`, `ai_quota_indicator.dart`,
`ai_insert_button.dart`, `ai_chat_empty_state.dart`

## Inserción en editor

```dart
// En AiInsertButton.onPressed():
if (quillController.document.length <= 1) {
  // insertar directamente
  _insertDelta(quillController, delta);
} else {
  final confirmed = await ConfirmationDialog.show(context: context, ...);
  if (confirmed == true) _insertDelta(quillController, delta);
}

void _insertDelta(QuillController controller, Delta delta) {
  controller.document = Document.fromDelta(delta);
  controller.updateSelection(
    const TextSelection.collapsed(offset: 0),
    ChangeSource.local,
  );
}
```

> Full detail: docs/exec-runs/app-ai-description-assistant/handoffs/architect.md
