# Frame zbCa0 — Crear Evento (Create/Edit Event Form)

**Flutter file(s):** `lib/features/events/presentation/form/event_form_page.dart` + `lib/features/events/presentation/form/widgets/*` + `lib/features/events/presentation/form/widgets/sections/*`  
**Module:** C  
**Screenshot:** ../screenshots/zbCa0.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Page background | #0D0D0F | `$bg-primary` |
| Card/section background | #1E1E24 | `$bg-card` |
| Accent | #F98C1F | `$accent` |
| Section card border | #2A2A32 | `$border` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| Field background | #1A1A1F | `$bg-secondary` |
| Field border | #2A2A32 | `$border` |
| Active toggle fill | #F98C1F | `$accent` |
| Inactive toggle background | #242429 | `$bg-tertiary` |
| Difficulty dot active | #F98C1F | `$accent` |
| Difficulty dot inactive | #242429 | `$bg-tertiary` |
| "Publicar Evento" button | #F98C1F | `$accent` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Screen title ("Nueva Evento") | Space Grotesk | ~18 | 700 | #FFFFFF |
| "Publicar" / "Guardar" nav right | Space Grotesk | ~14 | 600 | #F98C1F |
| Back button label | Space Grotesk | ~13 | 400 | #9CA3AF |
| Section card header | Space Grotesk | ~13 | 700 | #FFFFFF (uppercase) |
| Field label | Space Grotesk | ~12 | 600 | #9CA3AF |
| Field input text | Space Grotesk | ~14 | 400 | #FFFFFF |
| Field placeholder | Space Grotesk | ~14 | 400 | #6B7280 |
| "Publicar Evento" CTA | Space Grotesk | ~15 | 600 | #0D0D0F |

## Layout & Spacing
- Frame is 390px wide, 1931px tall (two-section long scroll: TopSection 832px + BottomSection 883px)
- **Status bar:** height 62, padding [0, 24, 0, 20]
- **Header/nav bar:** padding [12, 20, 16, 20], `space_between`
  - Left: back button (text link with chevron)
  - Center: screen title
  - Right: "Publicar" / "Guardar" link
- **Content area:** padding [4, 20, 32, 20], gap 24, vertical layout
  - AI cover preview card: full-width, cornerRadius `$radius-lg` (16), overflow image + "Generar portada" button overlay — **PROTECTED: do not alter**
  - Form sections as expandable/collapsible cards: cornerRadius `$radius-md` (12), bg-card, border 1px `$border`, padding 16
- **CTA bar:** "Publicar Evento" — full-width, height 52, bg-accent, cornerRadius `$radius-md` (12), padding [16, 20, 32, 20]

## Form Sections (from screenshot and BottomSection structure)
1. **Información Básica:** Title, description text area
2. **Fecha y Hora:** Date picker fields, start/end time
3. **Detalles:** Distance (km), duration, max participants
4. **Nivel de Dificultad:** 5-dot selector (1=beginner → 5=expert), each dot 20×20
5. **Tipo de Evento:** toggle chips (Road, Enduro, Turismo, Trail, Aventura)
6. **Ubicaciones:** Punto de encuentro + Ruta (with route map preview — PROTECTED)
7. **Marcas Permitidas:** multi-select toggle (Honda, Yamaha, KTM, etc.) + "Todas" option

## Components used
- `CoverPreviewWidget` (`AIEventCoverWidget`) — PROTECTED, do not touch
- `RouteMapPreview` inside `event_form_locations_section.dart` — PROTECTED
- `AppTextField` — all text inputs
- Lucide icons: `arrow-left`, `image`, `calendar`, `clock`, `map-pin`, `route`

## States / Variants
- **Create mode:** title = "Nueva Evento", CTA = "Publicar Evento"
- **Edit mode:** title = "Editar Evento", CTA = "Guardar Cambios"

## Architect Open Question — Q2 (PMuA4 vs zbCa0)
`zbCa0` is the **only** Create Event form screen (390px). `PMuA4` is a design reference sheet, not a second form state. Frontend implements one `EventFormPage` from `zbCa0`. See `PMuA4.md` for CTA bar state details.

## Notes for Frontend
- Section cards use collapsible/accordion pattern (visible from screenshot — sections can be expanded)
- The cover area at the top shows the AI-generated image preview with overlay buttons ("Generar portada" / "Cambiar imagen")
- Difficulty selector uses filled/unfilled circle dots, NOT icons or sliders
- "Todas" brand chip deselects individual brand chips when selected
- CTA bar bottom padding: 32px (safe area)
