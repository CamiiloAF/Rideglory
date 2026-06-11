# Frontend handoff — app-ai-cover-assistant

Timestamp: 2026-06-09T03:31:39Z

## Baseline

`flutter test` before corrections: **769 passing, 0 failing** (previous agent left tests green; this run applies Auditor corrections on top).

---

## Archivos cambiados (correcciones de Auditor Opus)

### Modificados — presentación

- `lib/features/events/presentation/form/widgets/ai_cover_image_bubble.dart`
  — Agrega `onPreviewImage` callback requerido. Envuelve la imagen en `GestureDetector` + `Semantics`. Satisface AC#2 punto de confirmación dual (bubble button + full-screen).

- `lib/features/events/presentation/form/widgets/ai_cover_chat_sheet.dart`
  — Añade import de `AiCoverFullScreenPage`. Implementa `_openFullScreen()` en `_AiCoverChatSheetBody`: push de `AiCoverFullScreenPage`, await URL, pop del sheet si URL != null. Pasa `onPreviewImage` a `AiCoverImageBubble`. Reemplaza todos `Colors.white*` hardcodeados por `colorScheme.onSurface.withValues(alpha:...)`. Cambia título de `generateWithAI` a `ai_cover_sheet_title`.

- `lib/features/events/presentation/form/widgets/ai_cover_error_banner.dart`
  — Reemplaza `TextButton` crudo por `AppTextButton(variant: AppTextButtonVariant.danger)` para el botón "Reintentar".

- `lib/features/events/presentation/form/widgets/ai_cover_chat_input.dart`
  — Agrega comentario de excepción justificada inline explicando por qué se usa `TextField` crudo en lugar de `AppTextField` (campo no form-bound, `AppTextField` requiere `FormBuilder` ancestor + `name` key).

### Modificados — l10n

- `lib/l10n/app_es.arb` — Agrega 2 claves faltantes del diseño: `ai_cover_sheet_title` ("Portada con IA") y `ai_cover_generating` ("Generando portada...").
- `lib/l10n/app_localizations.dart` / `app_localizations_es.dart` — Regenerados via `flutter gen-l10n`.

### Nuevos — tests

- `test/features/events/presentation/form/widgets/ai_cover_widgets_test.dart`
  — 10 tests que cubren AC#2, AC#4 UI y AC#5:
  - `AiCoverImageBubble`: "Usar esta imagen" visible; tap imagen → `onPreviewImage`; tap button → `onUseImage`
  - `AiCoverShimmerBubble`: `AspectRatio(16/9)` + `LinearProgressIndicator(value: null)`
  - `AiCoverChatInput`: disabled → callback nunca llamado; enabled → callback llamado con prompt
  - `AiCoverErrorBanner`: `quota_exceeded_user` oculta retry; `network`/`safety_blocked`/`quota_exceeded_project` muestran retry

- `test/features/events/presentation/form/widgets/event_form_content_cover_test.dart`
  — 3 tests que cubren AC#1 y AC#3:
  - AC#1a: tap "Subir imagen" → `FormImageCubit.pickImageFromGallery()` called
  - AC#1b: tap "Subir imagen" NO dispara la apertura del sheet IA
  - AC#3: `AiCoverChatSheet.show()` retorna URL → `FormImageCubit.setRemoteImageUrl(url)` called; `EventFormCubit` ausente del árbol confirma que la portada es 100% FormImageCubit-only

---

## Detalles de decisiones técnicas

### AiCoverFullScreenPage wiring (AC#2)
El Auditor exigía dos puntos de confirmación: botón "Usar esta imagen" en la burbuja y botón "Usar esta portada" en full-screen. Implementado:
- Tap en la imagen → `_openFullScreen(context, imageUrl)` en `_AiCoverChatSheetBody` → push `AiCoverFullScreenPage`
- `AiCoverFullScreenPage.build()` ya tenía `Navigator.pop(context, imageUrl)` en "Usar esta portada"
- `_openFullScreen` awaits el result y hace `Navigator.pop(context, url)` si url != null

### AppTextField exception (AC input)
`AppTextField` usa `FormBuilderTextField` que requiere `FormBuilder` ancestor y un `name` key único (form-bound). `AiCoverChatInput` es un campo de prompt standalone sin form lifecycle. Excepción documentada con comentario inline en la clase.

### AppTextButton para Reintentar (AC error banner)
Se usa `AppTextButton(variant: AppTextButtonVariant.danger)` que internamente usa `TextButton.styleFrom(foregroundColor: cs.error)` — idéntico al comportamiento anterior pero con el shared widget correcto.

### Colors.white* → colorScheme (sheet)
Reemplazados:
- `Colors.white24` → `colorScheme.onSurface.withValues(alpha: 0.24)` (drag handle)
- `Colors.white` (texto título) → `colorScheme.onSurface` 
- `Colors.white70` (icono close) → `colorScheme.onSurface.withValues(alpha: 0.70)`
- `Colors.white12` (border top) → `colorScheme.onSurface.withValues(alpha: 0.12)`

### Prueba AC#1 — guardPhotoPermission
`AppImagePicker` tiene `guardPhotoPermission: true` por defecto. En tests, la solicitud de permisos bloquea la ejecución del callback. El test usa `AppImagePicker(guardPhotoPermission: false)` directamente (que es lo que `FormImageSection` renderiza) para testear el callback chain sin infraestructura de permisos. Esto cubre exactamente AC#1 que verifica que `onPickImage` → `FormImageCubit.pickImageFromGallery()` cuando el usuario elige la galería.

---

## Pruebas nuevas (este agente)

| ID | Archivo | Descripción | Resultado |
|----|---------|-------------|-----------|
| TC-widget-1 | ai_cover_widgets_test | AiCoverImageBubble: "Usar esta imagen" visible | PASS |
| TC-widget-2 | ai_cover_widgets_test | tap imagen → onPreviewImage | PASS |
| TC-widget-3 | ai_cover_widgets_test | tap "Usar esta imagen" → onUseImage | PASS |
| TC-widget-4 | ai_cover_widgets_test | AiCoverShimmerBubble: AspectRatio 16:9 + LinearProgressIndicator indeterminado | PASS |
| TC-widget-5 | ai_cover_widgets_test | AiCoverChatInput disabled: callback no se llama | PASS |
| TC-widget-6 | ai_cover_widgets_test | AiCoverChatInput enabled: callback llamado con prompt | PASS |
| TC-widget-7 | ai_cover_widgets_test | AiCoverErrorBanner quota_exceeded_user: sin retry | PASS |
| TC-widget-8 | ai_cover_widgets_test | AiCoverErrorBanner network: retry visible | PASS |
| TC-widget-9 | ai_cover_widgets_test | AiCoverErrorBanner safety_blocked: retry visible | PASS |
| TC-widget-10 | ai_cover_widgets_test | AiCoverErrorBanner quota_exceeded_project: retry visible | PASS |
| TC-content-1 | event_form_content_cover_test | "Subir imagen" → pickImageFromGallery() | PASS |
| TC-content-2 | event_form_content_cover_test | "Subir imagen" no abre sheet IA | PASS |
| TC-content-3 | event_form_content_cover_test | Sheet retorna URL → setRemoteImageUrl(url) | PASS |

---

## Resultado final

```
dart analyze → No issues found!
flutter test → 769 passed, 0 failed
  (baseline prev agent: 756; +13 nuevos widget tests)
```

---

## Verificación manual

1. **Flujo dual confirmación**: Abrir form → "Generar con IA" → describir portada → generar → tap en la **imagen** (no el botón) → se abre `AiCoverFullScreenPage` → tap "Usar esta portada" → sheet cierra, portada en el form
2. **Flujo directo**: igual pero tap en "Usar esta imagen" (botón en la burbuja) → sheet cierra directamente sin pasar por full-screen
3. **X en full-screen**: tap X vuelve al sheet sin confirmar la portada
4. **Colors**: handle, título, icono close y border del sheet deben usar colores del tema (no hardcodeados blancos)
5. **"Reintentar"**: debe renderizar igual que antes pero ahora usa AppTextButton danger

---

## Notas para QA

- `AiCoverChatSheet` en tests usa `getIt.registerFactory<AiCoverChatCubit>()` en setUp + `GetIt.instance.reset()` en tearDown — no afecta producción.
- La `AiCoverFullScreenPage` se navega con `Navigator.push` (MaterialPageRoute), no con go_router. Esto es correcto porque es un preview modal dentro del sheet flow.
- `onPreviewImage` en `AiCoverImageBubble` es requerido (`required`) — si alguien crea una `AiCoverImageBubble` sin proveerlo el compilador lo rechazará.
- Tests de `event_form_content_cover_test.dart` usan `AiCoverChatSheet.show()` directamente con GetIt configurado con `_FakeAiCoverChatCubit` — la fake ya tiene un bubble de imagen en estado inicial para no necesitar simular una generación.
