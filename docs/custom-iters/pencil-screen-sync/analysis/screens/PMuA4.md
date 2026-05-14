# Frame PMuA4 — CTA Action States (Design Reference Sheet)

**Flutter file(s):** This is NOT a screen. It is a **design reference sheet** for `EventDetail` CTA bar variants.  
Maps to: `lib/features/events/presentation/detail/widgets/event_detail_cta_bar.dart` (and related `no_registration_content.dart`, `registration_status_content.dart`, `cancelled_registration_content.dart`)  
**Module:** C  
**Screenshot:** ../screenshots/PMuA4.png

## Architect Open Question — Q2 (PMuA4 vs zbCa0)

**Answer:** `PMuA4` is **NOT the Create Event form**. It is an 860px-wide design reference document labelled "CTA Action States — Bottom bar variations per registration status." It documents all state variants of the `EventDetail` CTA bar in a 2-column grid. The actual Create Event form is `zbCa0` (390px, a real mobile screen).

There is **one `EventFormPage`** (mapped to `zbCa0`), not two. `PMuA4` serves only as documentation of CTA bar states — Frontend should use it as a reference for `event_detail_cta_bar.dart` variants, not as a screen to implement separately.

## CTA Bar State Variants (from reference sheet)

### State 1: DEFAULT — User not registered
- Left: price (e.g. "45.00€"), Space Grotesk 22 700 white
- Right: "Inscribirse" orange button, height 52, cornerRadius 16, bg-accent, padding [0,20]
- Button text: Space Grotesk 15 600, color `$text-inverse` (#0D0D0F)

### State 2: PENDING — Waiting for organizer approval
- "Pendiente de aprobación" chip (warning/orange outline), left
- "Cancelar" ghost text link, right, text-secondary
- No price shown

### State 3: APPROVED (Inscrito)
- "Inscrito" chip: green (#22C55E fill bg + green text), left with checkmark icon
- "Cancelar Inscripción" text link, red/destructive, right

### State 4: REJECTED — Registration rejected by organizer
- "Inscripción rechazada" chip: error red, left
- Optional retry? (unclear from frame — treat as error state display only)

### State 5: CANCELLED — Event cancelled
- "Evento cancelado" message, full-width, muted
- No CTA button

### State 6: OWNER — Event not started
- Left: "N inscriptos" count with users icon
- Right: "Iniciar evento" orange button

### State 7: OWNER — Event live (in progress)
- Left: "En vivo" pulsing indicator
- Right: "Finalizar rodada" RED button (bg `$error` #EF4444)

### State 8: REGISTERED USER — Event live
- Full-width "Seguir Rodada en Viva" orange button (fills entire CTA bar width)

## Notes for Frontend
- All 8 states render from `event_detail_cta_bar.dart` via conditional rendering on `RegistrationStatus` enum + `eventStatus`
- CTA bar height: padding [16, 20], top border 1px `$border`, bg `$bg-primary`
- "Inscribirse" button: cornerRadius 16, height 52, text = `$text-inverse`
- The "Finalizar rodada" button (state 7) uses `$error` (#EF4444) NOT `$accent`
