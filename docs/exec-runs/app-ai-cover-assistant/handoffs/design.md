# Design handoff — app-ai-cover-assistant

**Date:** 2026-06-09T02:42:00Z
**Status:** done

---

## Design system baseline

| Token | Value |
|-------|-------|
| Primary | `#F98C1F` (accent) |
| Dark bg | `#0D0D0F` (bg-primary) |
| Surface | `#1A1A1F` (bg-secondary) |
| Card | `#1E1E24` (bg-card) |
| Tertiary | `#242429` (bg-tertiary) |
| Border | `#2A2A32` |
| Text primary | `#FFFFFF` |
| Text secondary | `#9CA3AF` |
| Error | `#EF4444` |
| Font | Space Grotesk |
| Border radius sheet | 24px top corners |
| Border radius inputs/btns | 8px |

**Changed this iteration:** no new tokens. All new UI uses existing Pencil variables.

---

## Pantallas

| Pantalla | Tipo | Mockup | Estado |
|----------|------|--------|--------|
| AiCoverChatSheet — Empty | NEW | `ai_cover_chat_sheet_empty.html` | done |
| AiCoverChatSheet — Generating | NEW | `ai_cover_chat_sheet_generating.html` | done |
| AiCoverChatSheet — Image Result | NEW | `ai_cover_chat_sheet_result.html` | done |
| AiCoverChatSheet — Multi-result scroll | NEW | `ai_cover_chat_sheet_result.html` (second mockup) | done |
| AiCoverChatSheet — Error: quota_exceeded_user | NEW | `ai_cover_chat_sheet_errors.html` (state 1) | done |
| AiCoverChatSheet — Error: quota_exceeded_project | NEW | `ai_cover_chat_sheet_errors.html` (state 2) | done |
| AiCoverChatSheet — Error: safety_blocked | NEW | `ai_cover_chat_sheet_errors.html` (state 3) | done |
| AiCoverChatSheet — Error: network_error | NEW | `ai_cover_chat_sheet_errors.html` (state 4) | done |
| AiCoverFullScreenPage | NEW | `ai_cover_full_screen.html` | done |

Pencil frame also added for the empty state: `vDsug` in `rideglory.pen`, exported to `analysis/design/vDsug.png`.

---

## Flujos UX

### Flujo principal: generar portada con IA

```
EventFormContent (cover section)
  └── Tap "Generar con IA" (AppImagePicker outline button)
        └── showModalBottomSheet → AiCoverChatSheet opens
              ├── User types prompt → tap "Generar con IA" button
              │     ├── [loading] AiCoverShimmerBubble 16:9 + LinearProgressIndicator
              │     └── [success] AiCoverImageBubble 16:9 + "Usar esta imagen" btn
              │           ├── Tap "Usar esta imagen" → sheet pops with URL
              │           └── Tap bubble area → push AiCoverFullScreenPage
              │                 ├── X button → pop (no confirm) → sheet stays open
              │                 └── "Usar esta portada" → pop page → pop sheet with URL
              └── On pop with URL: context.mounted check → FormImageCubit.setRemoteImageUrl(url)
```

### Flujo subida manual (no cambia)

```
EventFormContent (cover section)
  └── Tap "Subir imagen" → FormImageCubit.pickImageFromGallery()
```

### Estados de error

| Error | Input | Retry btn | Prev bubbles |
|-------|-------|-----------|--------------|
| `quota_exceeded_user` | Disabled | No | "Usar esta imagen" activo |
| `quota_exceeded_project` | Enabled | Sí | "Usar esta imagen" activo |
| `safety_blocked` | Enabled | Sí | "Usar esta imagen" activo |
| `network_error` | Enabled | Sí | "Usar esta imagen" activo |

**"Reintentar"** tap should re-call `AiCoverChatCubit.generateCover()` with the same last prompt; does NOT clear the error banner until a new request starts.

---

## Componentes

### Nuevos widgets (todos `StatelessWidget` en archivo propio)

| Widget | Descripción | Shared base |
|--------|-------------|-------------|
| `AiCoverChatSheet` | `DraggableScrollableSheet` wrapper; provee `BlocProvider<AiCoverChatCubit>`; retorna `String?` URL al pop | — |
| `AiCoverImageBubble` | Burbuja de resultado: 16:9 `CachedNetworkImage` + botón outlined "Usar esta imagen"; tap en imagen navega a `AiCoverFullScreenPage` | `AppButton` secondary |
| `AiCoverShimmerBubble` | 16:9 shimmer (`Shimmer.fromColors`) + `LinearProgressIndicator` indeterminado debajo | `shimmer` package |
| `AiCoverChatInput` | `AppTextField` placeholder + `AppButton` "Generar con IA"; se deshabilita durante loading y `quota_exceeded_user` | `AppTextField`, `AppButton` |
| `AiCoverQuotaIndicator` | Row: ícono ⚡ accent + texto `ai_cover_remaining_quota(count)` | — |
| `AiCoverErrorBanner` | Container rojo (`error-dim` bg + `error` border); texto + `AppButton` "Reintentar" opcional | — |
| `AiCoverFullScreenPage` | `Scaffold` sin AppBar; X button absolute top-right; `AppButton` full-width + `SafeArea` bottom | `AppButton` |

### Componentes reusados (no modificar)

- `AppImagePicker` — la sección de portada en el formulario ya muestra dos botones ("Subir imagen" + "Generar con IA") cuando `showGenerateWithAI: true`. **El bloque `BlocBuilder<EventFormCubit>` que lo envolvía se elimina; la lógica de estado pasa a `FormImageCubit` únicamente.**
- `AppButton` — CTA "Usar esta portada" en `AiCoverFullScreenPage`; label "Generar con IA" en `AiCoverChatInput`
- `FormImageSection` / `AppImagePicker` — no se modifica; el caller cambia `onGenerateWithAITap` de `_triggerGenerate()` a `showModalBottomSheet`

---

## Copy (strings l10n)

Todos van en `lib/l10n/app_es.arb`. Claves con prefijo `ai_cover_*` y `ai_error_*`:

| Key | Texto | Contexto |
|-----|-------|---------|
| `ai_cover_placeholder_hint` | `"Describe la portada que quieres generar"` | Placeholder del input en sheet |
| `ai_cover_generate_button` | `"Generar con IA"` | Botón principal en input area |
| `ai_cover_use_this_image` | `"Usar esta imagen"` | Botón outlined en AiCoverImageBubble |
| `ai_cover_use_this_cover` | `"Usar esta portada"` | CTA primario en AiCoverFullScreenPage |
| `ai_cover_upload_button` | `"Subir imagen"` | Botón secundario en AppImagePicker (ya existe como `event_uploadImage`) |
| `ai_cover_remaining_quota` | `"{count} generaciones restantes hoy"` | AiCoverQuotaIndicator; parametrizado |
| `ai_cover_generating` | `"Generando portada..."` | Label debajo del shimmer |
| `ai_cover_sheet_title` | `"Portada con IA"` | Título del bottom sheet |
| `ai_error_quota_exceeded_user` | `"Alcanzaste el límite diario de generaciones. Vuelve mañana para generar más portadas."` | AiCoverErrorBanner |
| `ai_error_quota_exceeded_project` | `"El servicio de IA está temporalmente ocupado. Intenta de nuevo en unos minutos."` | AiCoverErrorBanner |
| `ai_error_safety_blocked` | `"Tu descripción fue bloqueada por las políticas de seguridad. Intenta con una descripción diferente."` | AiCoverErrorBanner |
| `ai_error_network` | `"No se pudo conectar con el servicio de IA. Verifica tu conexión e intenta de nuevo."` | AiCoverErrorBanner |
| `ai_cover_retry` | `"Reintentar"` | Botón en AiCoverErrorBanner (solo para errores reintentables) |

---

## Accesibilidad

- **Touch targets mínimos:** todos los botones interactivos ≥ 44×44px.
  - `AiCoverImageBubble` botón "Usar esta imagen": `height: 40px` (dentro del bubble, no como acción primaria) — es SECUNDARIO; el tap directo en la imagen abre el fullscreen donde el CTA es 52px.
  - Close button X: 32×32px con área táctil extendida via `GestureDetector` padding o `InkWell` con splash radius ≥ 22.
  - "Usar esta portada" en `AiCoverFullScreenPage`: 52px height, full-width — excelente.

- **Contraste:**
  - Texto blanco (#FFFFFF) sobre bg-card (#1E1E24): ratio ~15:1 ✓
  - Texto accent (#F98C1F) sobre bg-card (#1E1E24): ratio ~5.5:1 ✓ (≥ 4.5:1 AA)
  - Texto en botón `generate-btn` (text-inverse = #0D0D0F sobre accent #F98C1F): ratio ~8:1 ✓
  - Texto error (#EF4444) sobre error-dim background: ratio ~4.5:1 ✓
  - **CRÍTICO:** el label "Generar con IA" y "Usar esta portada" usan `text-inverse` (#0D0D0F), NUNCA blanco, conforme a regla del design system.

- **Semantics Flutter:**
  - `AiCoverImageBubble`: `Semantics(label: 'Portada generada por IA. Toca para ver en pantalla completa.')` sobre la imagen.
  - Botón "Usar esta imagen": semantics label claro.
  - Estado de loading: `ExcludeSemantics` en el shimmer + `Semantics(liveRegion: true)` en un texto oculto "Generando portada...".
  - `AiCoverErrorBanner`: `Semantics(liveRegion: true)` para que screen readers anuncien el error al aparecer.

- **Orientación:** diseño optimizado para portrait. El sheet en landscape se comporta como scroll (DraggableScrollableSheet con initialChildSize adecuado).

---

## Notas para Frontend

### AiCoverChatSheet (alto impacto)

1. **`DraggableScrollableSheet`** con `initialChildSize: 0.72`, `minChildSize: 0.5`, `maxChildSize: 0.95`. El controller se pasa a un `ScrollController` interno para la lista de burbujas. El sheet RETORNA `String?` al `Navigator.pop(context, url)` — el caller en `event_form_content.dart` debe hacer `await showModalBottomSheet(...)` y capturar el resultado.

2. **`BlocProvider` scoped:** `AiCoverChatCubit` es `@injectable` (transient). Se instancia con `BlocProvider(create: (_) => getIt<AiCoverChatCubit>())` dentro de `AiCoverChatSheet.build()`. **Nunca** se agrega al `MultiBlocProvider` de `main.dart`.

3. **Lista de burbujas:** El state del cubit mantiene una `List<AiCoverBubble>` (sealed class con `prompt`, `loading`, `image`, `error`). La lista es inmutable y crece con cada generación (no se reemplaza). Usar `ListView.builder` con `reverse: false` y auto-scroll al fondo tras nueva burbuja.

4. **`context.mounted` guard:** En `event_form_content.dart`:
   ```dart
   final url = await showModalBottomSheet<String?>(
     context: context,
     isScrollControlled: true,
     builder: (_) => const AiCoverChatSheet(),
   );
   if (!context.mounted) return;
   if (url != null) context.read<FormImageCubit>().setRemoteImageUrl(url);
   ```

### AiCoverImageBubble

5. Dimensión: `AspectRatio(aspectRatio: 16/9)` wrapping `CachedNetworkImage`. Shimmer placeholder mientras carga. Tap en la imagen abre `AiCoverFullScreenPage` con `push` (no `go`), pasando la URL como argumento.

6. **"Usar esta imagen"** botón: `AppButton` con `style: AppButtonStyle.outlined`, `variant: AppButtonVariant.primary`. Al tap: `Navigator.pop(context, imageUrl)` — propaga la URL hasta el caller del sheet.

### AiCoverShimmerBubble

7. `Shimmer.fromColors(baseColor: cs.surfaceContainerHighest, highlightColor: cs.primary.withValues(alpha: 0.14))` + `LinearProgressIndicator(value: null)` de Material debajo del shimmer frame.

### AiCoverErrorBanner

8. El banner aparece como el ÚLTIMO elemento visible en la lista de burbujas (no flota sobre la lista). Se incluye como un `AiCoverBubble.error(...)` en la lista del state. Esto garantiza que las burbujas anteriores (con "Usar esta imagen") siguen siendo interactivas arriba en el scroll.

9. **"Reintentar"** NO aparece cuando el error es `AiQuotaExceededUserException`. Para todos los otros 3 errores, sí aparece. El cubit expone `bool get canRetry => state.error is! AiQuotaExceededUserException`.

### AiCoverChatInput

10. Se deshabilita (`enabled: false`) cuando:
    - `state.isLoading == true` (generando)
    - `state.isQuotaExceededUser == true` (cuota diaria agotada)
    Para `quota_exceeded_project`, `safety_blocked`, `network_error`: input HABILITADO.

### AiCoverFullScreenPage

11. `Scaffold(backgroundColor: Colors.black)` sin `AppBar`. El X button es un `IconButton` con `Icons.close` posicionado en `SafeArea` top-right via `Positioned` sobre un `Stack`. Al tap: `Navigator.pop(context)` sin pasar URL (cierra preview, vuelve al sheet).

12. El botón "Usar esta portada" usa `SafeArea(bottom: true)` envolviendo el `AppButton`, con padding bottom: 16px. El botón llama `Navigator.pop(context, imageUrl)` — esto propaga dos pops: uno para la página full-screen, luego el sheet recibe la URL y hace su propio `Navigator.pop(context, imageUrl)`.

    **Alternativa limpia:** la página fullscreen hace `Navigator.pop(context, imageUrl)`. El sheet observa el retorno de `push` y hace `Navigator.pop(context, imageUrl)` cuando la página retorna una URL no nula.

### Retiro legacy en event_form_content.dart

13. El `BlocBuilder<EventFormCubit>` que envuelve la sección de portada se **elimina**. El `FormImageSection` / `AppImagePicker` queda envuelto únicamente en `BlocBuilder<FormImageCubit>` para actualizar `imageUrl` / `localImagePath`. El `onGenerateWithAITap` llama al nuevo flujo:
    ```dart
    onGenerateWithAITap: () async {
      final url = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AiCoverChatSheet(),
      );
      if (!context.mounted) return;
      if (url != null) context.read<FormImageCubit>().setRemoteImageUrl(url);
    },
    ```

---

## Artefactos

- HTML mockups: `docs/exec-runs/app-ai-cover-assistant/analysis/design/`
  - `styles.css` — design system tokens + component styles
  - `ai_cover_chat_sheet_empty.html` — estado vacío
  - `ai_cover_chat_sheet_generating.html` — shimmer + progress
  - `ai_cover_chat_sheet_result.html` — burbuja imagen + multi-resultado
  - `ai_cover_chat_sheet_errors.html` — 4 estados de error
  - `ai_cover_full_screen.html` — página full-screen + SafeArea detail
- Pencil frame `vDsug` (chat sheet empty) en `rideglory.pen`; exportado a `analysis/design/vDsug.png`
