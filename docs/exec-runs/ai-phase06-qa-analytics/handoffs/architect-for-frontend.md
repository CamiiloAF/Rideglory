> Slim handoff — read this before docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md

# Architect → Frontend (Flutter) — ai-phase06-qa-analytics (rev 2)

## Objetivo de esta fase
Solo analytics, tests y docs. NO se crea código productivo nuevo.

---

## 1. Constantes de analytics a agregar

### `lib/core/services/analytics/analytics_events.dart`
Agregar sección `// AI — Asistentes IA (Fase 6)` con:
```dart
static const String aiDescriptionGenerated = 'ai_description_generated'; // 24 chars ✓
static const String aiQuotaExceeded        = 'ai_quota_exceeded';         // 17 chars ✓
static const String aiGenerationFailed     = 'ai_generation_failed';      // 20 chars ✓
```

### `lib/core/services/analytics/analytics_params.dart`
Agregar sección `// AI — Asistentes IA (Fase 6)` con:
```dart
static const String aiTurnIndex            = 'ai_turn_index';     // índice del turno (int, 1-based)
static const String aiGenerationType       = 'ai_generation_type'; // 'description' | 'cover'
static const String aiErrorCode            = 'ai_error_code';     // string del error code
// Valores canónicos
static const String aiGenerationTypeDescription = 'description';
static const String aiGenerationTypeCover       = 'cover';         // placeholder — cubit de portada no existe aún
```

---

## 2. Modificar `AiDescriptionChatCubit`

**Archivo:** `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart`

**Constructor — agregar 3er parámetro:**
```dart
@injectable
class AiDescriptionChatCubit extends Cubit<AiDescriptionChatState> {
  AiDescriptionChatCubit(
    this._generateDescriptionUseCase,
    this._getDescriptionQuotaUseCase,
    this._analyticsService,
  ) : super(const AiDescriptionChatState());

  final GenerateEventDescriptionUseCase _generateDescriptionUseCase;
  final GetDescriptionQuotaUseCase _getDescriptionQuotaUseCase;
  final AnalyticsService _analyticsService;
```

**Patrón de logging — rama de éxito:**

Usar `newHistory` como variable local para calcular el turn index de forma idéntica en ambos métodos:

```dart
// En sendMessage — rama de éxito (dentro del result.fold onRight):
final newHistory = [...updatedHistory, modelTurn];
_analyticsService.logEvent(
  AnalyticsEvents.aiDescriptionGenerated,
  {AnalyticsParams.aiTurnIndex: newHistory.length},
);
emit(
  state.copyWith(
    history: newHistory,
    sendResult: ResultState.data(data: descriptionResult),
    remainingQuota: descriptionResult.remainingGenerations,
  ),
);

// En retryLastMessage — rama de éxito (dentro del result.fold onRight):
// NOTA: retryLastMessage NO tiene variable `updatedHistory` — usar `state.history`
final newHistory = [...state.history, modelTurn];
_analyticsService.logEvent(
  AnalyticsEvents.aiDescriptionGenerated,
  {AnalyticsParams.aiTurnIndex: newHistory.length},
);
emit(
  state.copyWith(
    history: newHistory,
    sendResult: ResultState.data(data: descriptionResult),
    remainingQuota: descriptionResult.remainingGenerations,
  ),
);
```

> `newHistory.length` en ambos métodos es el índice 1-based del turno modelo en la historia final. En `sendMessage`: `updatedHistory.length + 1`. En `retryLastMessage`: `state.history.length + 1`. Consistentes por construcción.

**Patrón de logging — rama de error** (igual en ambos métodos):
```dart
if (exception is AiQuotaExceededUserException ||
    exception is AiQuotaExceededProjectException) {
  _analyticsService.logEvent(
    AnalyticsEvents.aiQuotaExceeded,
    {
      AnalyticsParams.aiGenerationType: AnalyticsParams.aiGenerationTypeDescription,
      AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
    },
  );
} else {
  _analyticsService.logEvent(
    AnalyticsEvents.aiGenerationFailed,
    {
      AnalyticsParams.aiGenerationType: AnalyticsParams.aiGenerationTypeDescription,
      AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
    },
  );
}
emit(state.copyWith(sendResult: ResultState.error(error: exception)));
```

> Usar las subclases ya existentes en `lib/core/exceptions/ai_domain_exceptions.dart` (`AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkErrorException`).

**Gate bloqueante:** verificar con:
```bash
grep -rn "logEvent.*ai_" lib/ --include="*.dart"
```
Solo deben aparecer líneas en `*_cubit.dart`.

---

## 3. Tests a modificar

### `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart`

- Agregar `class MockAnalyticsService extends Mock implements AnalyticsService {}`
- Actualizar todas las instancias `AiDescriptionChatCubit(mock..., mock...)` → `AiDescriptionChatCubit(mock..., mock..., mockAnalyticsService)`
- Agregar 4 grupos de test que verifiquen `verify(() => mockAnalyticsService.logEvent(...)).called(1)`:
  1. Happy path → `aiDescriptionGenerated` con `aiTurnIndex` igual a `newHistory.length` (longitud de la historia final tras agregar el turno del modelo)
  2. `AiQuotaExceededUserException` → `aiQuotaExceeded` con `aiGenerationTypeDescription`
  3. `AiSafetyBlockedException` → `aiGenerationFailed` con `aiGenerationTypeDescription`
  4. `AiNetworkErrorException` → `aiGenerationFailed` con `aiGenerationTypeDescription`

### `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart`

Agregar 2 tests al grupo existente:
1. `bold+italic combo`: `'**bold** y *italic*'` → ops con `bold:true` e `italic:true` en ops distintos, sin throw
2. `empty input`: `converter.convert('')` → retorna normalmente, ops no vacíos (al menos el trailing newline)

### `test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart`

Revisar si instancia `AiDescriptionChatCubit` directamente. Si sí, actualizar el constructor al nuevo de 3 parámetros. Si usa `MockAiDescriptionChatCubit extends Mock`, no hay cambio.

---

## 4. Localización

**No modificar `app_es.arb`.** Los 4 keys de error tipado ya existen (líneas 1173-1176). Confirmado.

---

## 5. Docs

**`docs/features/events.md`** — actualizar sección "API endpoints":
- Marcar `POST /events/generate-cover` como `~~ELIMINADO (Fase 5)~~`
- Documentar `POST /ai/description` (request/response/errores incluyendo history ≤ 10 turnos)
- Agregar sección "Asistentes IA" con el flujo: `AiDescriptionChatCubit` → `GenerateEventDescriptionUseCase` → `AiDescriptionRepository` → `POST /ai/description`; mencionar `MarkdownToDeltaConverter`

---

## 6. Verificación final

```bash
dart analyze              # debe retornar 0 errores, 0 warnings
flutter test              # debe pasar 100%
grep -rn "logEvent.*ai_" lib/ --include="*.dart"   # solo en *_cubit.dart
```

> Full detail: docs/exec-runs/ai-phase06-qa-analytics/handoffs/architect.md
