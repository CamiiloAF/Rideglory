# Tech Lead handoff — app-ai-cover-assistant
_Reviewed: 2026-06-09T03:52:23Z_

## Veredicto

**LISTO PARA COMMIT** — sin blockers. Todos los hallazgos son observaciones de baja severidad o watchlist.

---

## Hallazgos

### 1. `AiCoverErrorBanner` — error `unknown` muestra mensaje de red (cosmético)
**Archivo:** `lib/features/events/presentation/form/widgets/ai_cover_error_banner.dart:67`  
El case `AiCoverError.unknown` reutiliza `ai_error_network` en lugar de un mensaje genérico (ej. "Ocurrió un error inesperado"). No es un bug de comportamiento porque `unknown` solo aparece si `executeService` falla y no está mapeado, pero el mensaje puede confundir al usuario. Watchlist — se puede ajustar sin bloquear.

### 2. `AiCoverResponseDto` — usa `toModel()` (Pattern B exception documentada)
**Archivo:** `lib/features/events/data/dto/ai_cover_response_dto.dart`  
`toModel()` está prohibido por defecto en Pattern B, pero el archivo incluye el comentario `// Pattern B exception — composite DTO` y la justificación es válida: el DTO agrega un campo de control (`remainingGenerations`) sin modelo de dominio 1:1. No es un blocker.

### 3. `AiCoverChatInput` — usa `TextField` crudo (excepción documentada)
**Archivo:** `lib/features/events/presentation/form/widgets/ai_cover_chat_input.dart`  
El widget documenta explícitamente la razón (`FormBuilderTextField` requiere `FormBuilder` ancestor). La excepción está justificada.

### 4. Tests — `AiCoverResult` sin `==` semántico, depende de canonicalización `const`
**Archivo:** `test/features/events/domain/use_cases/get_generate_cover_use_case_test.dart`  
TC-gc-1 funciona porque ambas instancias son `const` (mismo objeto en memoria). Si `AiCoverResult` deja de ser `const` en el futuro, el test falla silenciosamente. Recomendación: agregar `@equatable` o `==` override a `AiCoverResult` en el futuro. No bloquea hoy.

---

## Seguridad

- Sin secretos hardcodeados — API key manejada en backend, no en Flutter.
- `draftId` se genera en el use case (no en la UI), correcto para idempotencia.
- Auth token inyectado automáticamente via `FirebaseAuthInterceptor` — sin manejo manual.
- No hay PII logueado; sin concatenación SQL; sin XSS surface en Flutter.
- Los errores 429 se distinguen correctamente por el campo `body['error']`, no solo por status code.

---

## Arquitectura

- Clean Architecture respetada: dominio sin imports Flutter, datos sin widgets, presentación sin clientes HTTP directos.
- `AiCoverChatCubit` es `@injectable` (transient) con `BlocProvider` scoped en el sheet — correcto, no es singleton.
- `AiCoverRepository` bound via `@Injectable(as: AiCoverRepository)` — DI correcta.
- Route legacy eliminado (`/events/generate-cover`), reemplazado por `/ai/cover` — sin deuda de rutas.
- `EventFormCubit` correctamente aligerado: eliminados `coverGenerationResult`, `generateCover()`, `resetCoverGeneration()`.
- `FormImageCubit.setRemoteImageUrl()` existe y es el canal correcto para pasar la URL generada al form.
- Fallback en `AiCoverRepositoryImpl` via `executeService<AiCoverResult>(function: () => Future.error(dioException))` — patrón válido, reutiliza mapping genérico de Dio.

---

## Tests

- 5 casos en `get_generate_cover_use_case_test.dart`: happy path, UUID v4, 3 error types — pasan todos.
- `event_form_cubit_analytics_test.dart` — 9 casos pasan, mock `MockGetGenerateCoverUseCase` correctamente eliminado.
- `dart analyze lib` — 0 issues.
- Cobertura de presentación (cubit de chat): no hay widget tests de `AiCoverChatCubit`. Aceptable para primer paso; los tests del use case cubren la lógica central.

---

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` en este directorio.
