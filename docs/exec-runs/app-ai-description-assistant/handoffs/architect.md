# Architect handoff — app-ai-description-assistant

**Date:** 2026-06-08T19:10:47Z
**Status:** done
**Slug:** app-ai-description-assistant

---

## Decisiones

| # | Decisión | Justificación |
|---|----------|---------------|
| ADR-A1 | **Backend stand-down** — cero cambios en rideglory-api | `POST /ai/description` ya está implementado y activo en `api-gateway/src/ai/ai.controller.ts`; contratos en `rideglory-contracts/src/ai/` incluyen `AiDescriptionRequestDto`, `AiDescriptionResponseDto`, `AiChatTurnDto`, `AiDescriptionEventContext`. Sistema de cuotas (`AiQuotaService`) operativo vía Firestore. |
| ADR-A2 | **Dominio en `lib/features/events/domain/`** — models + repo + use case junto al resto de features de eventos | Sigue la convención existente; no se crea un feature `ai/` separado. |
| ADR-A3 | **`AiDescriptionChatCubit` — `@injectable` factory (transient), NO singleton** | Se instancia una vez por apertura del sheet y se destruye con él. Guardrail explícito del PRD. |
| ADR-A4 | **`AiDescriptionRepositoryImpl` captura `DioException` directamente** — no usa `executeService()` | Los 4 códigos de error tipados (quota_exceeded_user, quota_exceeded_project, safety_blocked, network_error) requieren inspección del body de la respuesta HTTP; `executeService()` los homologaría a `DomainException` plano. |
| ADR-A5 | **`AppRichTextEditor` retrocompatible** — parámetro `QuillController? externalController` opcional | Todos los call sites existentes distintos de `EventFormBasicInfoSection` pasan a no pasar el parámetro → comportamiento idéntico. Flag `_ownsController` evita double-dispose. |
| ADR-A6 | **`EventFormBasicInfoSection` convertida a `StatefulWidget`** | Necesita crear, inicializar y disponer el `QuillController` externo; imposible en `StatelessWidget`. |
| ADR-A7 | **`MarkdownToDeltaConverter` en `presentation/form/utils/`** — subconjunto: párrafo, h2, bold, italic, bullet list; fallback texto plano | Subconjunto mínimo para output del LLM; no requiere librería externa. |
| ADR-A8 | **DTOs Pattern B excepción** — 4 DTOs de IA no extienden modelos domain | Son DTOs auxiliares/compuestos/request-only sin 1:1 con domain model; comentario inline `// Excepción Pattern B: ...` obligatorio en cada uno. |
| ADR-A9 | **Cuota inicial vía `FirebaseRemoteConfig.instance`** (ya registrado en DI como singleton) | No crear nueva instancia; inyectar `FirebaseRemoteConfig` en `AiDescriptionChatCubit` igual que en `SplashCubit`. Fallback: si `getInt('ai_description_daily_limit') == 0` → usar `10`. |
| ADR-A10 | **`EventFormContent.onAiSuggest` eliminado** — se reemplaza con apertura directa del sheet desde `EventFormBasicInfoSection.State` | Elimina la cadena de callback `EventFormContent → EventFormBasicInfoSection → AppRichTextEditor` que sólo servía para mostrar `InfoDialog 'coming soon'`. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/shared/widgets/form/app_rich_text_editor.dart` | modify | Add `externalController`, `_ownsController`, conditional dispose; update docstring de `onAiSuggest` | med |
| `lib/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart` | modify | Convertir a `StatefulWidget`; crear/inicializar/disponer `QuillController`; abrir sheet internamente; eliminar param `onAiSuggest`; implementar `_buildEventContext()` | med |
| `lib/features/events/presentation/form/widgets/event_form_content.dart` | modify | Eliminar `onAiSuggest:` callback con `InfoDialog`; `EventFormBasicInfoSection` sin ese param | low |
| `lib/features/events/domain/model/ai_chat_turn.dart` | create | Modelos `AiChatTurn` + `AiChatRole` enum (pure Dart, no imports Flutter) | low |
| `lib/features/events/domain/model/ai_description_result.dart` | create | `AiDescriptionResult` — markdown + remainingGenerations | low |
| `lib/features/events/domain/model/ai_description_request.dart` | create | `AiDescriptionRequest` — eventContext fields + history + userMessage | low |
| `lib/core/exceptions/ai_domain_exceptions.dart` | create | 4 subclases: `AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkErrorException` — todas extienden `DomainException` | low |
| `lib/features/events/domain/repository/ai_description_repository.dart` | create | Interfaz `AiDescriptionRepository` con `Future<Either<DomainException, AiDescriptionResult>>` | low |
| `lib/features/events/domain/use_cases/generate_event_description_use_case.dart` | create | `GenerateEventDescriptionUseCase` — recorta historial a 10 turnos | low |
| `lib/features/events/data/dto/ai_description_request_dto.dart` | create | DTO request con `AiEventContextDto` + `List<AiChatTurnDto>` + `userMessage`; factory `fromDomain`; excepción Pattern B | low |
| `lib/features/events/data/dto/ai_event_context_dto.dart` | create | DTO del contexto del evento; excepción Pattern B | low |
| `lib/features/events/data/dto/ai_description_response_dto.dart` | create | DTO respuesta; excepción Pattern B | low |
| `lib/features/events/data/dto/ai_chat_turn_dto.dart` | create | DTO turno de chat; factory `fromDomain`; excepción Pattern B | low |
| `lib/features/events/data/service/ai_description_service.dart` | create | Retrofit client `@POST('/ai/description')` | low |
| `lib/features/events/data/repository/ai_description_repository_impl.dart` | create | Impl con captura directa `DioException`; mapeo a 4 tipos tipados; `@Injectable(as: AiDescriptionRepository)` | med |
| `lib/features/events/presentation/form/cubit/ai_description_chat_cubit.dart` | create | Cubit transient `@injectable`; estado `@freezed AiDescriptionChatState`; `initQuota()`, `sendMessage()` | low |
| `lib/features/events/presentation/form/utils/markdown_to_delta_converter.dart` | create | `MarkdownToDeltaConverter` — subconjunto md→Delta; fallback texto plano | med |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet.dart` | create | `DraggableScrollableSheet` entry point; `BlocProvider` de `AiDescriptionChatCubit`; invierte `ListView` | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_chat_bubble.dart` | create | Burbuja de chat (user/model) | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_chat_input_row.dart` | create | Campo de texto + botón enviar; deshabilitado en estado quota_exceeded_user | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_chat_loading_indicator.dart` | create | Indicador de carga (dots o shimmer) | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_chat_error_banner.dart` | create | Banner de error con mensaje l10n; botón "Reintentar" condicional | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_quota_indicator.dart` | create | Indicador de cuota restante | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_insert_button.dart` | create | Botón "Insertar en descripción"; dispara `ConfirmationDialog` si hay contenido | low |
| `lib/features/events/presentation/form/widgets/ai_chat/ai_chat_empty_state.dart` | create | Estado idle/vacío con hint de uso | low |
| `lib/l10n/app_es.arb` | modify | Agregar ~12 claves `ai_*` (chat, errores, quota, insertar) | low |
| `lib/core/di/injection.config.dart` | modify | Regenerado por `build_runner`; auto tras registrar nuevos servicios/repositorios | low |
| `test/features/events/domain/use_cases/generate_event_description_use_case_test.dart` | create | Unit test del use case (historial trim, delegación al repo) | low |
| `test/features/events/data/repository/ai_description_repository_impl_test.dart` | create | Unit test de mapeos DioException → 4 tipos tipados (AC 9-12) | low |
| `test/features/events/presentation/form/utils/markdown_to_delta_converter_test.dart` | create | Unit test subconjunto completo + fallback (AC 1-2) | low |
| `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` | create | Cubit test: initQuota, sendMessage, mapeo error, quota desde response (AC 15-16) | low |
| `test/shared/widgets/form/app_rich_text_editor_external_controller_test.dart` | create | Widget test: externalController, _ownsController, no double dispose (AC 3-6) | med |
| `test/features/events/presentation/form/widgets/sections/event_form_basic_info_section_test.dart` | create | Widget test de la sección convertida | low |
| `test/features/events/presentation/form/widgets/ai_chat/ai_description_chat_sheet_test.dart` | create | Widget test: 5 estados, insert, confirmación, cuota (AC 7-8, 13-14, 17-18) | med |

---

## Contratos rideglory-api

**Backend 100% implementado — ningún cambio requerido.**

### `POST /ai/description`

```
Auth:   Bearer Firebase ID token (FirebaseAuthGuard)
Path:   /ai/description

Request body (AiDescriptionRequestDto):
{
  "eventContext": {
    "title":      string,          // EventFormFields.name
    "eventType":  EventType (enum string, e.g. "tourism"),
    "city":       string,
    "difficulty": string?,         // EventDifficulty.name (e.g. "one")
    "startDate":  string? (ISO)    // DateTimeRange.start.toIso8601String()
  },
  "history": [
    { "role": "user"|"model", "content": string }
  ]?,
  "userMessage": string
}

Success 200:
{
  "markdown":             string,   // Markdown generado por Gemini
  "remainingGenerations": number
}

Errors:
  429 { "error": "quota_exceeded_user" }    → AiQuotaExceededUserException
  429 { "error": "quota_exceeded_project" } → AiQuotaExceededProjectException
  422 { "error": "safety_blocked" }         → AiSafetyBlockedException
  503 { "error": "network_error" }          → AiNetworkErrorException
```

**Precondición (§7 PRD):** verificar que `curl -X POST .../ai/description -H 'Authorization: Bearer <token>' -d '{...}'` retorne `401` (guard activo) antes de tocar código Flutter. Si retorna `404` o `503`, detener.

---

## Datos / migraciones

**Sin migraciones.** El sistema de cuotas usa Firestore (`ai_usage_quotas/{userId}/days/{YYYY-MM-DD}`), ya en producción desde Fases 1-3 del backend.

---

## Env

**Sin nuevas variables de entorno en Flutter ni en el backend.**

La clave Gemini API (`GEMINI_API_KEY`) ya está configurada en `api-gateway/.env` desde fases anteriores. Firebase Remote Config key `ai_description_daily_limit` ya existe.

---

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| `Document.fromDelta()` inestable en flutter_quill 11.x | Inserción puede fallar silenciosamente | ADR-R9: probar en día 1 con Delta mínimo; fallback `Document.fromJson(jsonDecode(jsonEncode(delta.toJson())))` documentado en comentarios |
| Double-dispose de `QuillController` | Crash en dispose del form | `_ownsController` flag + test AC6 con `MockQuillController` |
| Blast radius de `AppRichTextEditor` | Todos los forms con rich text (SOAT, mantenimiento, etc.) se ven afectados por la modificación | El nuevo param `externalController` es opcional con default `null` → comportamiento idéntico al actual para todos los call sites no modificados |
| `EventFormBasicInfoSection` convertida a `StatefulWidget` | Riesgo de rebuild innecesario | `StatefulWidget` es la forma correcta para ownership de controller; no cambia el contrato público |
| `AiDescriptionChatCubit` registrado como singleton por error | Memory leak + estado compartido entre sesiones | `@injectable` (factory), NO `@singleton`; guardrail en code review |
| `_buildEventContext()` lee `EventFormFields` del `FormBuilder` que puede no estar inicializado | NullPointerException | Usar null-safe `.value?[EventFormFields.X] as T?` con fallback a string vacío; el form siempre existe en contexto |

---

## Orden de implementación

1. **Core exceptions** — `lib/core/exceptions/ai_domain_exceptions.dart`
2. **Domain models** — 3 archivos en `lib/features/events/domain/model/`
3. **Domain repo + use case** — interfaz + `GenerateEventDescriptionUseCase`
4. **Data layer** — 4 DTOs + `AiDescriptionService` (Retrofit) + `AiDescriptionRepositoryImpl`
5. **`MarkdownToDeltaConverter`** — utilitario de presentación (base para UI)
6. **`AiDescriptionChatCubit`** — estado + lógica; registrar en DI
7. **`AppRichTextEditor`** — modificación retrocompatible (riesgo de blast radius — validar con tests)
8. **`EventFormBasicInfoSection`** — conversión a `StatefulWidget`
9. **`EventFormContent`** — eliminar callback coming soon
10. **8 widgets atómicos del sheet** + `AiDescriptionChatSheet`
11. **ARB strings** — 12 claves `ai_*`
12. **DI** — `dart run build_runner build --delete-conflicting-outputs`
13. **Tests** — 7 archivos (unit + widget)
14. **`dart analyze`** + **`flutter test`**

---

## Superficie de regresión

- **`AppRichTextEditor`** (blast radius alto): todos los formularios que usan rich text — `EventFormBasicInfoSection`, formularios de mantenimiento, y cualquier otro call site. Verificar con `grep -rn "AppRichTextEditor" lib/`. El param `externalController: null` (default) no cambia comportamiento.
- **`EventFormBasicInfoSection`** → conversión a `StatefulWidget`; el único call site es `EventFormContent`. Widget tests de la sección deben pasar.
- **`EventFormContent`** → eliminación de `onAiSuggest` callback. Confirmar que no hay otros lugares que pasen ese parámetro a `EventFormBasicInfoSection`.
- **DI regeneration** → `injection.config.dart` se regenera; confirmar que ningún servicio existente queda desregistrado.
- **`flutter_quill` Document API** → `document =` setter + `updateSelection` deben propagar `onChanged` en 11.x; confirmar en día 1.

---

## Fuera de alcance

- Generación de portada IA (Fase 5)
- Analytics / telemetría `ai_*` (Fase 6)
- Actualización de `docs/features/events.md` (Fase 6)
- Retiro de código legacy Unsplash/Claude
- Campo `audience` en `EventFormFields` (reservado v2)
- Endpoint backend (ya implementado)
- Cualquier cambio en `rideglory-api`
