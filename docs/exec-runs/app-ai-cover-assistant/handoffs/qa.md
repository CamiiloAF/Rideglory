# QA handoff — app-ai-cover-assistant

**Timestamp:** 2026-06-09T03:49:02Z
**Agent:** QA (rg-exec normal)
**Sign-off:** green

---

## Catálogo de ACs

| AC | Descripción | Tests que lo cubren | Estado |
|----|-------------|---------------------|--------|
| §1 | "Subir imagen" operativo tras refactor | TC-content-1 (tap → `pickImageFromGallery()`), TC-content-2 (sheet IA no se abre) | PASS |
| §2 | Dos puntos de confirmación (burbuja + full-screen) | TC-widget-1/2/3 (AiCoverImageBubble); **TC-fsp-1** (AppButton presente, full-width, SafeArea); **TC-fsp-2** (tap "Usar esta portada" → pop retorna URL) | PASS |
| §3 | `FormImageCubit.setRemoteImageUrl` como único canal | TC-content-3: sheet retorna URL → `setRemoteImageUrl(url)` invocado; `EventFormCubit` ausente del árbol; `context.mounted` en línea 159 | PASS |
| §4 | Cuatro errores tipados (banner + inputEnabled) | TC-aic-3 (quotaExceededUser → `inputEnabled=false`), **TC-aic-8** (quotaExceededProject → `inputEnabled=true`, **nuevo**), TC-aic-4 (safetyBlocked → `inputEnabled=true`), TC-aic-5 (network → `inputEnabled=true`); UI: TC-widget-7/8/9/10 | PASS |
| §5 | Shimmer durante generación | TC-widget-4 (AiCoverShimmerBubble: AspectRatio(16/9) + `LinearProgressIndicator(value:null)`), TC-aic-2 (cubit loading state → `inputEnabled=false`) | PASS |
| §6 | `draftId` generado solo en use case | `grep "Uuid()" lib/` → único match en `generate_event_cover_use_case.dart`; TC-aic-2 verifica flujo completo | PASS |
| §7 | `event_form_cubit.dart` limpio | grep retorna 0 líneas de símbolos legacy; `dart analyze` limpio | PASS |
| §8 | Views limpias de referencias legacy | grep retorna 0 líneas en `event_form_view.dart` y `event_form_content.dart` | PASS |
| §9 | Strings l10n completas (7 claves mínimas) | `app_es.arb` contiene: `ai_cover_placeholder_hint`, `ai_cover_use_this_image`, `ai_cover_use_this_cover`, `ai_cover_generate_button`, `ai_cover_upload_button`, `ai_cover_remaining_quota` (parametrizado), error keys | PASS |
| §10 | Endpoint `POST /events/generate-cover` eliminado | Handler y ruta eliminados del controller; verificación 404 requiere entorno corriendo | MANUAL |
| §11 | Retiro backend completo | grep `ClaudeService\|UnsplashService\|anthropic` en `api-gateway/src/` → 0 líneas | PASS |
| §12 | `dart analyze` limpio + `flutter test` verde | `dart analyze`: No issues found! `flutter test` (machine): 855 passed, 0 failed | PASS |

---

## Matriz de regresión (guardrails §6)

| Guardrail | Mecanismo de verificación | Resultado |
|-----------|--------------------------|-----------|
| Subida manual no afectada | TC-content-1/2: `pickImageFromGallery()` llamado; sheet IA no se abre | OK |
| `EventFormCubit` sin métodos de portada nuevos | grep `setCoverUrl` → 0; TC-content-3 confirma canal exclusivo `FormImageCubit` | OK |
| `AiCoverChatCubit` es transient (`@injectable`, NOT `@singleton`) | `@injectable` en línea 38; ausente de `MultiBlocProvider` en `main.dart` | OK |
| `Uuid().v4()` solo en use case | grep lib/ → único match `generate_event_cover_use_case.dart` | OK |
| `context.mounted` antes de `setRemoteImageUrl` | línea 159 `event_form_content.dart`: `if (url != null && context.mounted)` | OK |
| `generate-cover.spec.ts` gestionado antes del grep de axios | Spec eliminado; grep `axios src/` → 0 líneas | OK |
| Variables EC2 no eliminadas antes de deploy estable | Documentado en backend handoff; instrucción preservada | PENDIENTE post-deploy |
| `dart analyze` limpio tras retiro | Ejecutado post-todo: "No issues found!" | OK |

---

## Ejecución

### Flutter — `dart analyze`
```
No issues found!
```

### Flutter — `flutter test`
```
flutter test --machine → 855 passed, 0 failed
  Baseline previo (frontend agent): 769 → +86 tests totales en la suite
  Tests nuevos de este run (QA): TC-aic-8, TC-fsp-1, TC-fsp-2
```

### Backend — `npm test` (api-gateway)
```
Test Suites: 8 passed, 8 total
Tests:       110 passed, 110 total
  (baseline: 9 suites / 120 tests; −1 suite / −10 tests por retiro de generate-cover.spec.ts)
```

### Verificaciones estáticas

```bash
# AC#6: Uuid() solo en use case
grep -r "Uuid()" lib/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
→ generate_event_cover_use_case.dart:    final draftId = const Uuid().v4();  (1 match)

# AC#7: event_form_cubit limpio
grep "coverGenerationResult|generateCover|resetCoverGeneration|GetGenerateCoverUseCase" event_form_cubit.dart
→ 0 líneas

# AC#8: views limpias
grep "coverGenerationResult|_triggerGenerate|CoverPreviewWidget" event_form_view.dart event_form_content.dart
→ 0 líneas

# AC#11: backend limpio
grep -r "ClaudeService|UnsplashService|anthropic" api-gateway/src/ --include="*.ts"
→ 0 líneas

# Guardrail: context.mounted
grep "context.mounted" event_form_content.dart
→ línea 159: if (url != null && context.mounted) {
```

---

## Bugs

Ningún bug encontrado. No hay regresiones. GAP-QA-1 (cubit test `quotaExceededProject`) fue cerrado con TC-aic-8 agregado en este run.

---

## Pruebas manuales

1. **AC#10 — Endpoint legacy → 404:** `curl -X POST <base_url>/api/events/generate-cover` debe retornar 404 contra servidor dev/prod.
2. **Flujo dual confirmación:** Form → "Generar con IA" → describir → generar → tap en imagen → `AiCoverFullScreenPage` abre → "Usar esta portada" → sheet cierra, portada aplicada al form.
3. **Flujo directo (burbuja):** Tap en "Usar esta imagen" → sheet cierra sin pasar por full-screen.
4. **X en full-screen:** Tap X regresa al sheet sin confirmar la portada.
5. **Error quota user:** Banner rojo sin "Reintentar"; campo deshabilitado; botones "Usar" en burbujas previas activos.
6. **Error quota project / network / safety:** Banner con "Reintentar"; campo habilitado.
7. **Variables EC2:** Confirmar que `UNSPLASH_ACCESS_KEY` y `ANTHROPIC_API_KEY` no se eliminan de EC2 hasta deploy estable.
8. **`integration_test/events_patrol_test.dart`:** Ejecutar en dispositivo para confirmar no regresión del flujo de creación de eventos.

---

## Tests nuevos creados en este run

| ID | Archivo | Descripción | Resultado |
|----|---------|-------------|-----------|
| TC-aic-8 | `test/features/events/presentation/form/cubit/ai_cover_chat_cubit_test.dart` | `AiQuotaExceededProjectException` → `error=quotaExceededProject`, `inputEnabled=true` | PASS |
| TC-fsp-1 | `test/features/events/presentation/ai_cover/ai_cover_full_screen_page_test.dart` | AppButton "Usar esta portada" presente, `isFullWidth=true`, dentro de SafeArea | PASS |
| TC-fsp-2 | `test/features/events/presentation/ai_cover/ai_cover_full_screen_page_test.dart` | Tap "Usar esta portada" → `Navigator.pop` retorna `imageUrl` como `String?` | PASS |

---

## Sign-off

**green** — `dart analyze` limpio, `flutter test` 855 passed / 0 failed, backend 110/110, todos los ACs verificables por automatización pasan incluyendo los tests pendientes TC-aic-8 y TC-fsp-1/2 exigidos por el Auditor. AC#10 requiere verificación manual con curl.
