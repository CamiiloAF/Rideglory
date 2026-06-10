> Slim handoff — read this before docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md

# QA handoff — app-ai-cover-assistant

## Comandos base

```bash
dart analyze                                             # 0 errors/warnings requerido
flutter test                                            # todos los tests existentes en verde
```

---

## Tests nuevos requeridos (widget + unit)

### AC §1 — Subida manual sigue funcionando
Widget test en `event_form_content_test.dart`:
- Tap en "Subir imagen" → `FormImageCubit.pickImageFromGallery()` invocado
- El bottom sheet de IA NO se abre

### AC §2 — Dos puntos de confirmación
Widget test:
- `AiCoverImageBubble` con URL inyectada → botón "Usar esta imagen" visible
- `AiCoverFullScreenPage` con URL inyectada → `AppButton` "Usar esta portada" visible y ancho completo

### AC §3 — Canal único: `FormImageCubit.setRemoteImageUrl`
Widget test en `event_form_content_test.dart`:
- Pop del sheet con URL → `FormImageCubit.setRemoteImageUrl(url)` invocado
- `EventFormCubit` NO invocado para portada
- `context.mounted` verificado antes del call (inspección directa)

### AC §4 — 4 errores tipados
Cubit tests con mocks (mocktail):
- `AiQuotaExceededUserException` → banner rojo; `inputEnabled == false`; burbujas previas con botón "Usar" siguen activos
- `AiQuotaExceededProjectException` → banner con "Reintentar"; `inputEnabled == true`
- `AiSafetyBlockedException` → banner con "Reintentar"; `inputEnabled == true`
- `AiNetworkException` → banner con "Reintentar"; `inputEnabled == true`

### AC §5 — Shimmer durante generación
Widget test con cubit mockeado en estado `loading`:
- `AiCoverShimmerBubble` visible con `LinearProgressIndicator` indeterminado
- Campo de entrada deshabilitado

### AC §6 — `draftId` solo en use case
```bash
grep -r "Uuid()" lib/ --include="*.dart"
# Debe aparecer ÚNICAMENTE en generate_event_cover_use_case.dart
```
Unit test de `GenerateEventCoverUseCase`: verificar que el `draftId` en el request tiene formato UUID v4.

### AC §7 — `event_form_cubit.dart` limpio
Inspección directa:
```bash
grep -n "coverGenerationResult\|generateCover\|resetCoverGeneration\|GetGenerateCoverUseCase" \
  lib/features/events/presentation/form/cubit/event_form_cubit.dart
# Esperado: 0 líneas
```
`dart analyze` limpio.

### AC §8 — Views limpias
```bash
grep -n "coverGenerationResult\|_triggerGenerate\|CoverPreviewWidget" \
  lib/features/events/presentation/form/widgets/event_form_view.dart \
  lib/features/events/presentation/form/widgets/event_form_content.dart
# Esperado: 0 líneas
```

### AC §9 — L10n completo
```bash
grep -n "ai_cover_placeholder_hint\|ai_cover_use_this_image\|ai_cover_use_this_cover\
         \|ai_cover_generate_button\|ai_cover_upload_button\|ai_cover_remaining_quota" \
  lib/l10n/app_es.arb
# Esperado: todos presentes, parametrizado el de quota
```
Ningún string de UI hardcodeado en Dart dentro de los nuevos widgets.

### AC §10 — Endpoint legacy → 404
```bash
curl -X POST https://<base_url>/events/generate-cover \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"title":"x","eventType":"ride","city":"Bogota"}'
# Esperado: 404
```

### AC §11 — Retiro backend completo
```bash
grep -r "ClaudeService\|UnsplashService\|anthropic-ai/sdk\|anthropic" \
  rideglory-api/api-gateway/src/ --include="*.ts"
# Esperado: 0 líneas
```

### AC §12 — dart analyze limpio + flutter test verde
Blocker: `dart analyze` con 0 errores. `flutter test` sin nuevas regresiones.

---

## Regresiones a verificar

- `EventFormCubit.saveEvent()` con `remoteCoverImageUrl` — probar en tests existentes que siguen pasando
- `FormImageCubit.pickImageFromGallery()` — no bloqueado por ningún cambio
- `event_form_view.dart` listener de `saveResult` — sigue funcionando (no tocado)

> Full detail: docs/exec-runs/app-ai-cover-assistant/handoffs/architect.md
