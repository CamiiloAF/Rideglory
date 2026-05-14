# Frame kAubW — Event Detail

**Flutter file(s):** `lib/features/events/presentation/detail/event_detail_page.dart` + `lib/features/events/presentation/detail/event_detail_view.dart` + `lib/features/events/presentation/detail/widgets/*`  
**Module:** C  
**Screenshot:** ../screenshots/kAubW.png

## Colors
| Role | Hex | Variable |
|------|-----|----------|
| Page background | #0D0D0F | `$bg-primary` |
| Card background | #1E1E24 | `$bg-card` |
| Accent | #F98C1F | `$accent` |
| Text primary | #FFFFFF | `$text-primary` |
| Text secondary | #9CA3AF | `$text-secondary` |
| Border | #2A2A32 | `$border` |
| CTA bar background | #0D0D0F | `$bg-primary` |
| CTA bar top border | #2A2A32 | `$border` |
| Hero image overlay gradient | black → transparent (linear, bottom up) | custom |
| Event type chip | varies by type | (Road=info blue, Turismo=success green, etc.) |
| Difficulty flames | #F98C1F | `$accent` |
| Meeting point map card | #1E1E24 | `$bg-card` |
| Allowed brands section | #1E1E24 | `$bg-card` |

## Typography
| Text role | Family | Size | Weight | Color |
|-----------|--------|------|--------|-------|
| Event title (hero overlay) | Space Grotesk | ~22 | 700 | #FFFFFF |
| Event organizer name (hero overlay) | Space Grotesk | ~13 | 400 | #9CA3AF |
| Section header ("Sobre la rodada") | Space Grotesk | ~15 | 700 | #FFFFFF |
| Body text / description | Space Grotesk | ~13 | 400 | #9CA3AF |
| Info row label (km, tiempo, restricciones) | Space Grotesk | ~12 | 400 | #9CA3AF |
| Info row value | Space Grotesk | ~13 | 600 | #FFFFFF |
| Price in CTA bar | Space Grotesk | ~22 | 700 | #FFFFFF |
| "Inscribirse" button | Space Grotesk | ~15 | 600 | #0D0D0F (text-inverse) |
| Section label chips | Space Grotesk | ~11 | 600 | varies |
| "Inscripciones" heading | Space Grotesk | ~13 | 700 | #FFFFFF |
| Attendee count | Space Grotesk | ~13 | 400 | #9CA3AF |

## Layout & Spacing
- Frame width: 390px, clip=true, vertical layout
- **Status bar:** height 44, padding [0, 24], `space_between`
- **Hero image:** height 219, fill=image, layout=none (absolute children overlay)
  - Back button: top-left, 40×40, bg-card@80%, cornerRadius 20
  - Share button: top-right, 40×40, bg-card@80%, cornerRadius 20
  - Bottom gradient overlay: gradient bottom→transparent
  - Title + organizer: bottom-left of hero, with badge chip above
- **Content scroll area:** padding [0, 20, 32, 20], gap 24
  - Info chips row (km, hours): horizontal, gap 8
  - Difficulty flames row: 5 flame icons, filled/empty
  - "Sobre la rodada" section: section title + body text
  - "Punto de Encuentro" section: map card (Mapbox preview), height ~120
  - "Marcas Permitidas" section: horizontal chip row (Honda, Yamaha, KTM, Honda, + Todas)
  - "Inscripciones" section: avatar list of attendees
- **CTA Bar:** height ~88, bg-primary, border top 1px `$border`, padding [16, 20], `space_between`
  - Price: large text left
  - "Inscribirse" CTA: height 52, cornerRadius 16, bg-accent, fill_container (or fixed)

## CTA Bar State Variants (from PMuA4 reference sheet)
| State | UI |
|-------|----|
| Not registered (default) | Price left + "Inscribirse" orange button right |
| Pending approval | "Pendiente de aprobación" chip + "Cancelar" ghost link |
| Approved (inscrito) | "Inscrito" green chip + "Cancelar Inscripción" ghost |
| Cancelled | "Evento cancelado" message |
| Owner (event not started) | "N inscriptos" count + "Iniciar evento" orange button |
| Owner (event live) | "En vivo" indicator + "Finalizar rodada" red button |
| Registered + event live | "Seguir Rodada en Vivo" orange button (full width) |

## Components used
- `AppEventBadge` — event status badge in hero image (top-left corner of hero)
- Route map preview widget (`route_map_preview.dart`) — meeting point section
- `InitialsAvatar` — attendee list avatars
- `RegistrationStatusChip` — CTA bar state indicator
- Lucide icons: `arrow-left`, `share-2`, `map-pin`, `clock`, `users`, `flame`, `chevron-right`

## States / Variants
All CTA states controlled by `RegistrationStatus` enum — same page, conditional rendering in CTA bar widget.

## Notes for Frontend
- Hero image is 219px tall with absolute-positioned overlays (back btn, badges, title)
- CTA bar has `stroke: { align: inside, fill: $border, thickness: { top: 1 } }` — top border only
- "Inscripciones" section shows user avatars as a horizontal overlapping row with total count
- The event type chip (e.g. "ENDURO") is positioned on the hero image, top-left area
