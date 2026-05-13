# Design handoff — Iteration 4

**Date:** 2026-05-13
**Status:** done
**Iteration:** 4 — AI Event Cover Image Generation

---

## Story classification

| Story | Classification | Rationale |
|-------|---------------|-----------|
| US-4-1 | EXTEND | EventFormPage already exists. Adding cover preview container, loading overlay, and AI button wiring. No new screen. |
| US-4-2 | EXTEND | Adds "Regenerar" AppTextButton below preview and coexistence with custom image upload. |
| US-4-3 | Backend only | No frontend UI — backend endpoint design only. |
| US-4-4 | EXTEND | EventFormCubit state refactor. No new screen or route. No design deliverable; architecture only. |

All UI changes are contained within the existing `EventFormPage` / `EventFormContent` widget tree. **No new routes or screens.** The `event_form_page.dart` route (`/crear-evento`) is extended, not replaced.

---

## Screen inventory — Iteration 4

### Modified screen: Crear evento (`EventFormPage`)
**Flutter file:** `lib/features/events/presentation/form/event_form_page.dart`
**Route:** `/crear-evento` (existing go_router route)
**New widget:** `lib/features/events/presentation/form/widgets/cover_preview_widget.dart`

| State | Mockup file | `coverGenerationResult` value |
|-------|------------|-------------------------------|
| Idle (no image) | `iter-4/event-form-idle.html` | `initial()` |
| Generating (loading overlay) | `iter-4/event-form-generating.html` | `loading()` |
| Preview (image + Regenerar) | `iter-4/event-form-preview.html` | `data(imageUrl)` |
| Error (snackbar + idle) | `iter-4/event-form-error.html` | `error(DomainException)` |

---

## Component hierarchy — CoverPreviewWidget

```
CoverPreviewWidget
  └─ Column
      ├─ Text "Portada del evento"     ← section-label style, uppercase, 11px
      ├─ AspectRatio(16/9)
      │   └─ Stack
      │       ├─ [initial] Container (surface-dark bg)
      │       │     └─ Column(icon🖼 + text "Sin portada seleccionada")
      │       ├─ [data] CachedNetworkImage(imageUrl, BoxFit.cover)
      │       └─ [loading] Container(rgba 0,0,0 0.55)     ← overlay
      │             └─ Column
      │                 ├─ CircularProgressIndicator(color: primary-orange)
      │                 └─ Text(l10n.event_coverGeneratingOverlay)
      ├─ [data only] Row(mainAxisAlignment: end)
      │     └─ AppTextButton("Regenerar")   ← calls generateCover() again
      ├─ [initial/data] AppButton(l10n.event_generateWithAI)   ← primary orange
      └─ AppTextButton(l10n.event_uploadImage)   ← always visible
```

**Key rules:**
- "Generar portada con IA" button: visible when `initial()` or `error()`; hidden when `data()` (replaced by "Regenerar"); disabled when `loading()`.
- "Regenerar": visible only when `data()`.
- "Subir imagen propia": ALWAYS visible and enabled (never blocked by AI state).
- Preview container maintains 16:9 `AspectRatio` in all states — no layout shift.
- Loading overlay uses `Stack` + `Positioned.fill` — the existing image (or placeholder) stays visible below. Do NOT blank the preview during regeneration.
- `CachedNetworkImage` with `BoxFit.cover` for the generated image URL.

---

## Shared widgets to reuse

| Widget | Location | Usage in this iteration |
|--------|----------|------------------------|
| `AppButton` | `lib/shared/widgets/form/` | "Generar portada con IA" primary button |
| `AppTextButton` | `lib/shared/widgets/form/` | "Regenerar" and "Subir imagen propia" |
| `FormImageSection` | `lib/shared/widgets/form/form_image_section.dart` | Wraps the cover section; receives `onGenerateWithAITap` |
| `AppImagePicker` | Design system | Extended with `onGenerateWithAITap` callback (already accepts it) |

**New widget to create:**
- `CoverPreviewWidget` — `lib/features/events/presentation/form/widgets/cover_preview_widget.dart`
  - Accepts: `coverGenerationResult`, `imageUrl`, `onGenerateTap`, `onRegenerateTap`
  - Stateless; driven by `EventFormState.coverGenerationResult`

---

## Color tokens used in iteration 4

All from existing `styles.css` / design system tokens — no new colors:

| Usage | Token | Value |
|-------|-------|-------|
| Preview container bg | `surface-dark` / `--color-surface` | `#1C1C1C` |
| Loading overlay | black + 0.55 opacity | `rgba(0,0,0,0.55)` |
| Spinner | `primary-orange` | `#f98c1f` |
| Overlay text | white | `#FFFFFF` |
| Error snackbar bg | `--color-error-bg` | `#2A1218` |
| Error snackbar border | `--color-error` | `#CF6679` |
| Section label | `--color-on-surface-variant` | `#9E9E9E` |

---

## UI copy (Spanish) — Iteration 4 ARB keys

| l10n key | Spanish value | Screen / state |
|----------|--------------|----------------|
| `event_coverGenerating` | `"Generando portada..."` | Form subtitle / status |
| `event_coverGenerated` | `"Portada generada"` | Accessibility label on success |
| `event_coverGenerateError` | `"No pudimos generar la portada. Sube tu propia imagen."` | Error SnackBar text |
| `event_coverRegenerate` | `"Regenerar"` | AppTextButton below preview |
| `event_coverGeneratingOverlay` | `"Generando con IA..."` | Overlay text on loading spinner |

---

## Interaction flows

### Flow A — AI generation (happy path)
```
[EventFormContent]
  User fills: nombre, ciudad, tipo de evento
  → Tap "Generar portada con IA"
  → EventFormCubit.generateCover(title, eventType, city)
  → coverGenerationResult = loading()
     ↳ CoverPreviewWidget shows spinner overlay
     ↳ "Generar portada con IA" button disabled
     ↳ "Publicar evento" remains ENABLED
  → POST /events/generate-cover (backend)
  → success: coverGenerationResult = data(imageUrl)
     ↳ CoverPreviewWidget shows image (CachedNetworkImage)
     ↳ "Regenerar" button appears
     ↳ BlocListener calls FormImageCubit.setRemoteImageUrl(imageUrl)
```

### Flow B — Regeneration
```
[CoverPreviewWidget in data() state]
  → Tap "Regenerar"
  → Same: EventFormCubit.generateCover(...)
  → coverGenerationResult = loading()
     ↳ Spinner overlay on top of EXISTING image (not blank)
  → success/error as above
```

### Flow C — Custom image upload (overrides AI)
```
[Any state of coverGenerationResult]
  → Tap "Subir imagen propia"
  → FormImageCubit.pickImageFromGallery()
  → Local image selected
     ↳ FormImageCubit state = data(FormImageData(localPath))
     ↳ coverGenerationResult in EventFormCubit remains unchanged
     ↳ FormImageSection renders local image over the AI preview
```

### Flow D — Error
```
[loading() state]
  → Backend returns 503
  → coverGenerationResult = error(DomainException)
     ↳ BlocListener shows SnackBar (Spanish error message)
     ↳ coverGenerationResult resets to initial() after display
     ↳ Form data preserved (freezed state separation)
```

---

## HTML mockups

| File | State | Notes |
|------|-------|-------|
| `docs/design/html-mockups/iter-4/event-form-idle.html` | initial() | No image, AI button + upload button |
| `docs/design/html-mockups/iter-4/event-form-generating.html` | loading() | Spinner overlay; second variant shows regeneration |
| `docs/design/html-mockups/iter-4/event-form-preview.html` | data(url) | Generated image, Regenerar button, state flow diagram |
| `docs/design/html-mockups/iter-4/event-form-error.html` | error(e) | SnackBar, form reset to idle, data preserved |

Shared base styles: `docs/design/html-mockups/iter-4/shared/styles.css` (copied from iter-1, extended with iter-4 cover preview classes)

---

## Locked design decisions (Iteration 4)

- Cover preview: 16:9 `AspectRatio` widget — matches event list card ratio for visual consistency. No landscape/portrait toggle.
- Loading overlay: `Stack` + semi-transparent black `Container` (0.55 opacity) + `CircularProgressIndicator` centered. Image never blanked.
- "Regenerar": `AppTextButton` (text style, primary-orange), right-aligned below preview. Never replaces "Subir imagen propia".
- "Generar portada con IA": `AppButton` (full-width primary orange). Hidden (not disabled) when `data()` — replaced by "Regenerar".
- Error feedback: Flutter `SnackBar` (not inline error banner) — transient, non-blocking, Spanish message.
- Form data independence: `coverGenerationResult` is a separate field in `@freezed EventFormState` — form field values are never cleared during generation.
- `CachedNetworkImage`: used for Unsplash URLs. `BoxFit.cover` for the 16:9 container.

---

## Prior iteration inventory (unchanged)

All screens from Iteration 3 remain valid and unmodified. The iteration 4 design touches only `EventFormPage`.

See prior `design.md` for:
- Flow 1–8 screen inventory (Pencil frames)
- SOAT upload flow (6 screens, HTML mockups in `iter-3/`)
- Design token table (Pencil variables)

---

## Change log

- 2026-05-12: Iteration 1 design handoff — Profile page, 4 states, styles.css baseline.
- 2026-05-12 (iter 3): Design System in Pencil — 8 flows documented, SOAT upload flow designed (6 screens + 6 HTML mockups), design tokens set as 9 Pencil variables. Hard gate for iter-3b cleared.
- 2026-05-13 (iter 4): AI Event Cover Image Generation — CoverPreviewWidget designed (4 states: idle, loading, data/preview, error). 4 HTML mockups in `iter-4/`. styles.css extended with cover preview classes. No new screens or routes. All UI within EventFormPage.
