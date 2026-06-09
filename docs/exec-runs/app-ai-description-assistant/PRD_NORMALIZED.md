# PRD Normalizado — App: Asistente de Descripción IA

**Slug:** app-ai-description-assistant
**Generado:** 2026-06-08T19:07:12Z
**Fuente:** docs/plans/ai-event-generation/phases/phase-04-app-asistente-de-descripcion.md
**Nivel rg-exec:** normal

---

## 1 Objetivo

Permitir que un organizador abra un chat con un asistente IA desde el formulario de evento, itere sobre la descripción del evento en lenguaje natural y aplique la sugerencia al editor de texto enriquecido con un solo toque — sin romper ningún flujo existente del formulario de creación/edición de eventos.

---

## 2 Por qué

El formulario de creación de eventos ya tiene un botón "IA" en el editor `AppRichTextEditor` que actualmente muestra un `InfoDialog` de "Próximamente". Esta fase elimina ese placeholder y lo reemplaza con un flujo funcional completo: backend Gemini ya disponible (Fases 1-3), sistema de cuotas activo, contrato `POST /ai/description` definido. El campo de descripción es uno de los más complejos de rellenar para un organizador; un asistente conversacional reduce la fricción y aumenta la calidad del contenido generado.

---

## 3 Alcance

### Entra

- Modificación de `AppRichTextEditor` (widget compartido): parámetro `QuillController? externalController` retrocompatible; flag `_ownsController`; dispose condicional; docstring de `onAiSuggest` actualizado
- Conversión de `EventFormBasicInfoSection` de `StatelessWidget` a `StatefulWidget`: crea, inicializa y dispone el `QuillController` externo; lo pasa al editor y al bottom sheet; abre el sheet internamente; elimina el param `onAiSuggest`; implementa `_buildEventContext()` con campos reales del `FormBuilder`
- Modificación de `EventFormContent`: eliminar el callback `onAiSuggest` que mostraba `InfoDialog 'coming soon'`
- Modelos de dominio puros (sin imports Flutter): `AiChatTurn` + `AiChatRole`, `AiDescriptionResult`, `AiDescriptionRequest`
- 4 subclases tipadas de `DomainException` en `lib/core/exceptions/ai_domain_exceptions.dart`: `AiQuotaExceededUserException`, `AiQuotaExceededProjectException`, `AiSafetyBlockedException`, `AiNetworkErrorException`
- Interfaz `AiDescriptionRepository` con retorno `Future<Either<DomainException, AiDescriptionResult>>`
- `GenerateEventDescriptionUseCase` con recorte de historial a 10 turnos
- `AiDescriptionRepositoryImpl`: captura directa de `DioException` (NO usa `executeService()`); Retrofit client `AiDescriptionService` hacia `POST /ai/description`
- DTOs: `AiDescriptionRequestDto`, `AiEventContextDto`, `AiDescriptionResponseDto`, `AiChatTurnDto` con factories `fromDomain`; excepciones Pattern B documentadas con comentario inline
- `MarkdownToDeltaConverter` en `lib/features/events/presentation/utils/`: subconjunto acotado (párrafo, h2, bold, italic, bullet list); fallback texto plano sin error
- `AiDescriptionChatCubit` (`@injectable`, transient — scoped al bottom sheet) con estado `@freezed`; cuota inicial desde Remote Config via `fetchAndActivate()`
- UI: `DraggableScrollableSheet` con `ListView` invertida, 8 widgets atómicos (burbujas, loading, input, error banner, quota indicator, insert button), 5 estados visuales (idle, loading, data, error cuota usuario, error recuperable)
- `ConfirmationDialog` si el editor tiene contenido al insertar; inserción directa si está vacío; propagación determinista de `onChanged` vía `updateSelection` tras `document =`
- Strings en `lib/l10n/app_es.arb`: ~12 claves `ai_*` (chat + errores)
- Registros DI: `AiDescriptionService`, `AiDescriptionRepositoryImpl`, `GenerateEventDescriptionUseCase`, `AiDescriptionChatCubit`
- Tests unitarios y de widget: conversor Markdown→Delta, mapeos DioException, cubit, AppRichTextEditor con controller externo, secciones del formulario, sheet completo
- `dart analyze` limpio; `flutter test` pasa

### No entra

- Generación de portada IA (Fase 5)
- Analytics / telemetría `ai_*` (Fase 6)
- Actualización de `docs/features/events.md` (Fase 6)
- Retiro de código legacy Unsplash/Claude (Fase 5)
- Campo `audience` en `EventFormFields` (reservado para v2)

---

## 4 Áreas afectadas

| Capa | Archivos / módulos |
|------|--------------------|
| **Shared widget** | `lib/shared/widgets/form/app_rich_text_editor.dart` (blast radius: todos los formularios con rich text) |
| **Domain — eventos** | `lib/features/events/domain/model/` (3 modelos nuevos), `lib/features/events/domain/repository/` (1 interfaz nueva), `lib/features/events/domain/use_cases/` (1 use case nuevo) |
| **Data — eventos** | `lib/features/events/data/dto/` (4 DTOs nuevos), `lib/features/events/data/service/` (1 Retrofit client nuevo), `lib/features/events/data/repository/` (1 impl nueva) |
| **Core exceptions** | `lib/core/exceptions/ai_domain_exceptions.dart` (nuevo) |
| **Presentation — formulario** | `lib/features/events/presentation/form/` (cubit, sheet, 7 widgets atómicos, utils/conversor); modificaciones en `EventFormBasicInfoSection` y `EventFormContent` |
| **Localización** | `lib/l10n/app_es.arb` |
| **DI** | `lib/core/di/injection.config.dart` (regenerado); posiblemente módulo `AiModule` nuevo |
| **Tests** | 4 archivos de tests unitarios + 3 archivos de tests de widget (nuevos) |

---

## 5 Criterios de aceptación

1. **Markdown→Delta — subconjunto completo:** dado `## Título\n**negrita** *cursiva*\n- ítem`, el `MarkdownToDeltaConverter` produce un Delta con atributos `{header: 2}`, `{bold: true}`, `{italic: true}` y `{list: bullet}`. Verificable con unit test.

2. **Markdown→Delta — fallback sin error:** dado `> blockquote` o `~~tachado~~`, el conversor inserta texto plano sin lanzar excepción. Verificable con unit test.

3. **Inserción en editor — Delta visible:** al tocar "Insertar en descripción", el documento del `QuillController` externo refleja el contenido del Delta convertido y el `QuillEditor` lo muestra correctamente. Verificable con widget test que inspecciona `quillController.document`.

4. **Inserción en editor — onChanged propagado de forma determinista:** tras insertar el Delta mediante `document = Document.fromDelta(delta)` seguido de `updateSelection(TextSelection.collapsed(offset: 0), ChangeSource.local)`, el callback `onChanged` de `AppRichTextEditor` es invocado con el nuevo JSON del documento. Verificable con widget test que espía `onChanged` y confirma que es llamado con contenido no vacío.

5. **Retrocompatibilidad de AppRichTextEditor:** el call site existente en `event_form_basic_info_section.dart` compila sin cambios una vez convertido a `StatefulWidget` y funciona idéntico al comportamiento anterior. `dart analyze` limpio. Verificable con widget test con `externalController: null`.

6. **Sin double dispose del QuillController externo:** `AppRichTextEditor._ownsController == false` cuando se provee `externalController`; `dispose()` del widget no llama `_controller.dispose()`. El controller se dispone exactamente una vez en `EventFormBasicInfoSection.State.dispose()`. Verificable con widget test usando un `MockQuillController` con contador de llamadas a `dispose()`.

7. **Confirmación al reemplazar contenido:** si el editor tiene contenido al tocar "Insertar", aparece `ConfirmationDialog` y la inserción solo ocurre si el usuario confirma. Verificable con widget test del sheet.

8. **Inserción directa en editor vacío:** si el editor no tiene contenido (`document.length <= 1`), "Insertar" aplica el Delta sin mostrar `ConfirmationDialog`. Verificable con widget test.

9. **Mapeo tipado — quota_exceeded_user:** un mock que lanza `DioException` con `response.statusCode: 429` y `response.data: {'error': 'quota_exceeded_user'}` produce `Left(AiQuotaExceededUserException())`. Unit test.

10. **Mapeo tipado — quota_exceeded_project:** un mock que lanza `DioException` con `response.statusCode: 429` y `response.data: {'error': 'quota_exceeded_project'}` produce `Left(AiQuotaExceededProjectException())`. Unit test.

11. **Mapeo tipado — safety_blocked:** un mock que lanza `DioException` con `response.statusCode: 422` y `response.data: {'error': 'safety_blocked'}` produce `Left(AiSafetyBlockedException())`. Unit test.

12. **Mapeo tipado — network_error:** un mock que lanza `DioException` con `response.statusCode: 503` (o `type: DioExceptionType.connectionError`) produce `Left(AiNetworkErrorException())`. Unit test.

13. **Error quota_exceeded_user — campo deshabilitado:** cuando el cubit emite `ResultState.error(error: AiQuotaExceededUserException())`, el campo de texto queda deshabilitado y no aparece botón "Reintentar". Verificable con widget test del sheet.

14. **Errores recuperables — Reintentar:** ante `AiQuotaExceededProjectException`, `AiSafetyBlockedException` o `AiNetworkErrorException`, el banner muestra el mensaje l10n correcto Y el botón "Reintentar" está presente y habilitado. Verificable con widget test para cada uno de los 3 tipos.

15. **Cuota inicial desde Remote Config:** al llamar `initQuota()`, el cubit llama `fetchAndActivate()` en `FirebaseRemoteConfig` y emite `remainingQuota` igual al valor de `ai_description_daily_limit`. Si Remote Config retorna 0, emite 10 como fallback. Verificable con cubit test con mock de `FirebaseRemoteConfig`.

16. **Cuota actualizada desde response:** tras un turno exitoso, `state.remainingQuota == result.remainingGenerations` (no el valor de Remote Config). Verificable con cubit test.

17. **`EventFormContent` sin callback coming soon:** `InfoDialog.show(content: l10n.event_comingSoon)` ya no se invoca desde `EventFormContent` al tocar el botón IA del editor. `dart analyze` limpio.

18. **`_buildEventContext` con campos reales:** el campo `title` del contexto enviado al backend coincide con el valor actual de `EventFormFields.name` en el `FormBuilder`; `eventType` coincide con `EventFormFields.eventType.name`; `city` coincide con `EventFormFields.city`; `audience` es `null`. Verificable con unit test o inspección del body enviado al mock de `AiDescriptionService`.

19. **Análisis limpio:** `dart analyze` no reporta warnings ni errores. `flutter test` pasa.

---

## 6 Guardrails de regresión

- `AppRichTextEditor` sin `externalController` (todos los call sites existentes excepto `EventFormBasicInfoSection`) debe compilar y funcionar sin ningún cambio de comportamiento.
- El formulario de creación/edición de eventos (`EventFormContent`, `EventFormBasicInfoSection`) debe funcionar correctamente cuando el backend IA no está disponible (Paso 0 falla) — el botón IA simplemente no debería presentar el sheet o el sheet muestra error de red; nunca crashea.
- `dart analyze` sin warnings al finalizar la fase.
- `flutter test` sin tests rotos al finalizar la fase.
- El `QuillController` externo NO es dispuesto por `AppRichTextEditor` ni por el sheet — solo por `EventFormBasicInfoSection.State`.
- `AiDescriptionChatCubit` NO debe registrarse como `@singleton` ni `@lazySingleton` en el contenedor DI — debe ser transient.
- `executeService()` NO debe usarse en `AiDescriptionRepositoryImpl`; la captura directa de `DioException` es la única forma de distinguir los 4 errores tipados de cuota/seguridad.

---

## 7 Constraints heredados

- **Precondición de backend:** el endpoint `POST /ai/description` debe retornar HTTP `401` (guard activo) antes de tocar cualquier código Flutter. Verificación con `curl` (Paso 0). Si retorna `404` o `503`, detener e informar al responsable de backend.
- **Nivel rg-exec fuente: full** — la fase original fue diseñada para ejecución full; esta corrida usa nivel normal. Priorizar la implementación correcta del dominio, el repositorio y la integración del cubit; los 8 widgets atómicos del sheet pueden tener menor detalle visual pero deben cubrir los 5 estados funcionales.
- **Un widget por archivo** (regla crítica de coding standards): `AiDescriptionChatSheet` y cada widget atómico van en archivos separados.
- **Pattern B excepción documentada:** los 4 DTOs de IA no extienden modelos domain (DTOs auxiliares/compuestos/request-only); cada uno debe tener un comentario inline `// Excepción Pattern B: ...` explicando por qué.
- **Strings en ARB:** todo texto visible en UI va en `lib/l10n/app_es.arb` con prefijo `ai_`; nunca strings hardcodeados en widgets.
- **Cuota fallback:** si `FirebaseRemoteConfig.getInt('ai_description_daily_limit')` retorna `0`, usar `10` como fallback conservador.
- **flutter_quill 11.x (R9):** probar `Document.fromDelta()` en día 1 con Delta mínimo; si resulta inestable, usar `Document.fromJson(jsonDecode(jsonEncode(convertedDelta.toJson())))` como alternativa; documentar en comentarios del implementador.
- **Historial máximo:** `GenerateEventDescriptionUseCase` recorta el historial a los últimos 10 turnos antes de enviar al repositorio.
- **`audience` siempre null:** no existe `EventFormFields.audience` en v1; el campo se reserva en el DTO para uso futuro del backend.
